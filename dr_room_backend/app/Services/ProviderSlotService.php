<?php

namespace App\Services;

use App\Models\Driver;
use App\Models\Lab;
use App\Models\Nurse;
use App\Models\Order;
use App\Models\ProviderSchedule;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Collection;

/**
 * Working hours + bookable time slots for field staff (nurses, labs, drivers).
 *
 * The admin weekly schedule, the patient slot picker, the booking validation
 * and the driver app all read from here, so "taken" means the same thing
 * everywhere: a slot is taken once the provider's capacity for it is used up
 * (or their daily maximum is reached).
 */
class ProviderSlotService
{
    public const HORIZON_DAYS = 14;

    public const DAYS = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

    /** Order statuses that no longer hold a slot. */
    private const RELEASED_STATUSES = ['cancelled', 'rejected'];

    private const TYPES = [
        'nurse' => ['role' => 'nurse', 'column' => 'assigned_nurse_id', 'model' => Nurse::class],
        'lab' => ['role' => 'lab', 'column' => 'assigned_lab_id', 'model' => Lab::class],
        'driver' => ['role' => 'driver', 'column' => 'assigned_driver_id', 'model' => Driver::class],
    ];

    private const DEFAULTS = [
        'nurse' => ['start_time' => '08:00:00', 'end_time' => '20:00:00', 'slot_minutes' => 60, 'slot_capacity' => 1, 'max_daily_orders' => 6],
        'lab' => ['start_time' => '08:00:00', 'end_time' => '20:00:00', 'slot_minutes' => 30, 'slot_capacity' => 2, 'max_daily_orders' => 30],
        'driver' => ['start_time' => '08:00:00', 'end_time' => '23:00:00', 'slot_minutes' => 60, 'slot_capacity' => 2, 'max_daily_orders' => 20],
    ];

    public static function isValidType(?string $type): bool
    {
        return isset(self::TYPES[$type]);
    }

    /** nursing / lab service_type → nurse / lab provider type. */
    public static function typeForService(?string $serviceType): ?string
    {
        return match (CommissionService::categoryFor($serviceType)) {
            'nursing' => 'nurse',
            'lab' => 'lab',
            default => null,
        };
    }

    public static function orderColumn(string $type): string
    {
        return self::TYPES[$type]['column'];
    }

    /** Accept users.id or the profile model id (nurses.id, labs.id, drivers.id). */
    public static function resolveUserId(string $type, $id): ?int
    {
        if (!$id) {
            return null;
        }
        $role = self::TYPES[$type]['role'];
        if (User::where('id', $id)->where('role', $role)->exists()) {
            return (int) $id;
        }
        $model = self::TYPES[$type]['model'];
        $userId = $model::where('id', $id)->value('user_id');
        return $userId ? (int) $userId : null;
    }

    /** Approved users of a provider type, for pickers. */
    public static function providers(string $type): Collection
    {
        $query = User::where('role', self::TYPES[$type]['role'])
            ->where(fn ($q) => $q->where('status', 'approved')->orWhereNull('status'))
            ->orderBy('name');

        if ($type === 'driver') {
            $query->with('driver');
        }

        return $query->get(['id', 'name', 'phone']);
    }

    /** Whether a driver profile handles the requested category ('nurse' | 'lab' | 'all' | null). */
    public static function driverMatchesCategory(?Driver $driver, ?string $category): bool
    {
        if (!$category || $category === 'all') {
            return true;
        }
        $profile = $driver?->resolvedFieldProfile() ?? [];
        $role = strtolower((string) ($profile['applicant_role'] ?? 'phlebotomist'));
        $scope = strtolower((string) ($driver?->service_scope ?? 'both'));

        if ($category === 'nurse') {
            return in_array($role, ['mobile_nurse', 'both'], true);
        }
        if ($category === 'lab') {
            return in_array($role, ['phlebotomist', 'both'], true) || $scope === 'lab_sample';
        }
        return true;
    }

    /** Providers with quick schedule + upcoming order counts for the admin screen. */
    public static function providerSummaries(string $type, ?string $category = null): Collection
    {
        $providers = self::providers($type);
        if ($type === 'driver' && $category && $category !== 'all') {
            $providers = $providers->filter(fn ($u) => self::driverMatchesCategory($u->driver, $category))->values();
        }
        if ($providers->isEmpty()) {
            return collect();
        }

        $ids = $providers->pluck('id')->all();
        $scheduleCounts = ProviderSchedule::whereIn('user_id', $ids)
            ->where('provider_type', $type)
            ->selectRaw('user_id, SUM(CASE WHEN is_available = 1 THEN 1 ELSE 0 END) as active_days, COUNT(*) as saved_days')
            ->groupBy('user_id')
            ->get()
            ->keyBy('user_id');

        $col = self::orderColumn($type);
        $upcomingCounts = Order::whereIn($col, $ids)
            ->whereNotNull('scheduled_at')
            ->where('scheduled_at', '>=', Carbon::now()->subHours(1))
            ->whereNotIn('status', array_merge(self::RELEASED_STATUSES, ['completed']))
            ->selectRaw("$col as provider_id, COUNT(*) as cnt")
            ->groupBy($col)
            ->pluck('cnt', 'provider_id');

        return $providers->map(function ($u) use ($scheduleCounts, $upcomingCounts, $type) {
            $sc = $scheduleCounts->get($u->id);
            $item = [
                'id' => $u->id,
                'name' => $u->name,
                'phone' => $u->phone,
                'has_custom_schedule' => $sc !== null && (int) $sc->saved_days > 0,
                'active_days' => $sc ? (int) $sc->active_days : 7,
                'upcoming_count' => (int) ($upcomingCounts->get($u->id) ?? 0),
            ];
            if ($type === 'driver') {
                $profile = $u->driver?->resolvedFieldProfile() ?? [];
                $item['applicant_role'] = $profile['applicant_role'] ?? 'phlebotomist';
                $item['service_scope'] = $u->driver?->service_scope ?? 'both';
            }
            return $item;
        })->values();
    }

    // ─── Weekly schedule ────────────────────────────────────────────────────

    /** The 7-day week for a provider, filling missing days with defaults. */
    public static function week(int $userId, string $type): array
    {
        $existing = ProviderSchedule::where('user_id', $userId)->get()->keyBy('day_of_week');

        return array_map(function (string $day) use ($existing, $userId, $type) {
            $row = $existing->get($day);
            return self::normalizeRow($row ? $row->toArray() : null, $day, $userId, $type);
        }, self::DAYS);
    }

    private static function normalizeRow(?array $row, string $day, int $userId, string $type): array
    {
        $d = self::DEFAULTS[$type];
        return [
            'user_id' => $userId,
            'provider_type' => $type,
            'day_of_week' => $day,
            'start_time' => substr((string) ($row['start_time'] ?? $d['start_time']), 0, 5),
            'end_time' => substr((string) ($row['end_time'] ?? $d['end_time']), 0, 5),
            'is_available' => (bool) ($row['is_available'] ?? true),
            'slot_minutes' => (int) ($row['slot_minutes'] ?? $d['slot_minutes']),
            'slot_capacity' => (int) ($row['slot_capacity'] ?? $d['slot_capacity']),
            'max_daily_orders' => (int) ($row['max_daily_orders'] ?? $d['max_daily_orders']),
            'is_default' => $row === null,
        ];
    }

    public static function saveWeek(int $userId, string $type, array $days): void
    {
        foreach ($days as $item) {
            if (!in_array($item['day_of_week'] ?? null, self::DAYS, true)) {
                continue;
            }
            ProviderSchedule::updateOrCreate(
                ['user_id' => $userId, 'day_of_week' => $item['day_of_week']],
                [
                    'provider_type' => $type,
                    'start_time' => self::normalizeTime($item['start_time'] ?? '08:00'),
                    'end_time' => self::normalizeTime($item['end_time'] ?? '20:00'),
                    'is_available' => filter_var($item['is_available'] ?? true, FILTER_VALIDATE_BOOLEAN),
                    'slot_minutes' => max(10, min(240, (int) ($item['slot_minutes'] ?? 60))),
                    'slot_capacity' => max(1, min(50, (int) ($item['slot_capacity'] ?? 1))),
                    'max_daily_orders' => max(1, min(200, (int) ($item['max_daily_orders'] ?? 6))),
                ]
            );
        }
    }

    private static function normalizeTime(string $value): string
    {
        try {
            return Carbon::parse(trim($value))->format('H:i:s');
        } catch (\Throwable) {
            return '08:00:00';
        }
    }

    // ─── Availability ───────────────────────────────────────────────────────

    /**
     * Bookable days with their slots. With a provider id the slots are that
     * provider's; without one they are pooled across every provider of the type.
     *
     * @return array<int, array{date: string, day_of_week: string, closed: bool, slots: array}>
     */
    public static function availability(string $type, ?int $userId = null, ?Carbon $from = null, int $days = self::HORIZON_DAYS): array
    {
        $from = ($from ?? Carbon::today())->copy()->startOfDay();
        $to = $from->copy()->addDays($days)->endOfDay();

        $providerIds = $userId
            ? collect([$userId])
            : self::providers($type)->pluck('id')
                ->when(
                    $type === 'nurse' || $type === 'lab',
                    fn ($c) => $c->merge(self::providerSummaries('driver', $type)->pluck('id'))->unique()->values()
                );
        if ($providerIds->isEmpty()) {
            return [];
        }

        $weeks = $providerIds->mapWithKeys(fn ($id) => [$id => collect(self::week((int) $id, $type))->keyBy('day_of_week')]);
        [$slotBookings, $dayBookings, $poolBookings] = self::bookings($type, $providerIds->all(), $from, $to, !$userId);

        $now = Carbon::now();
        $result = [];

        for ($i = 0; $i < $days; $i++) {
            $date = $from->copy()->addDays($i);
            $dayName = $date->format('l');
            $dateKey = $date->toDateString();
            $slots = [];

            foreach ($providerIds as $pid) {
                $row = $weeks[$pid]->get($dayName);
                if (!$row || !$row['is_available']) {
                    continue;
                }
                $dayFull = ($dayBookings["$pid|$dateKey"] ?? 0) >= $row['max_daily_orders'];

                $cursor = $date->copy()->setTimeFromTimeString($row['start_time']);
                $end = $date->copy()->setTimeFromTimeString($row['end_time']);
                if ($end->lessThanOrEqualTo($cursor)) {
                    $end->addDay();
                }
                $step = max(10, $row['slot_minutes']);

                while ($cursor->copy()->addMinutes($step)->lessThanOrEqualTo($end)) {
                    $key = $cursor->format('H:i');
                    $endLabel = $cursor->copy()->addMinutes($step)->format('H:i');
                    $booked = $slotBookings["$pid|$dateKey $key"] ?? 0;
                    $free = $dayFull ? 0 : max(0, $row['slot_capacity'] - $booked);

                    $slots[$key] ??= [
                        'time' => $key,
                        'end_time' => $endLabel,
                        'capacity' => 0,
                        'booked' => 0,
                        'remaining' => 0,
                        'past' => $cursor->lessThanOrEqualTo($now),
                    ];
                    $slots[$key]['capacity'] += $row['slot_capacity'];
                    $slots[$key]['booked'] += $booked;
                    $slots[$key]['remaining'] += $free;
                    $cursor->addMinutes($step);
                }
            }

            // Pool mode: unassigned bookings still consume shared capacity.
            foreach ($slots as $key => &$s) {
                if (!$userId) {
                    $unassigned = $poolBookings["$dateKey $key"] ?? 0;
                    $s['booked'] += $unassigned;
                    $s['remaining'] = max(0, $s['remaining'] - $unassigned);
                }
                $s['taken'] = $s['past'] || $s['remaining'] <= 0;
                $s['reason'] = $s['past'] ? 'تێپەڕیوە' : ($s['remaining'] <= 0 ? 'گیراوە' : null);
            }
            unset($s);

            ksort($slots);
            $result[] = [
                'date' => $dateKey,
                'day_of_week' => $dayName,
                'closed' => empty($slots),
                'slots' => array_values($slots),
            ];
        }

        return $result;
    }

    /** True when $at is a real, still-free slot. */
    public static function isBookable(string $type, ?int $userId, Carbon $at): bool
    {
        if ($at->lessThanOrEqualTo(Carbon::now()) || $at->greaterThan(Carbon::today()->addDays(self::HORIZON_DAYS + 1))) {
            return false;
        }
        $day = self::availability($type, $userId, $at->copy()->startOfDay(), 1)[0] ?? null;
        if (!$day) {
            return false;
        }
        foreach ($day['slots'] as $slot) {
            if ($slot['time'] === $at->format('H:i')) {
                return !$slot['taken'];
            }
        }
        return false;
    }

    /** Is the provider working right now? No saved schedule = always on. */
    public static function isOnShift(int $userId, ?Carbon $at = null): bool
    {
        $at ??= Carbon::now();
        $rows = ProviderSchedule::where('user_id', $userId)->get();
        if ($rows->isEmpty()) {
            return true;
        }
        $row = $rows->firstWhere('day_of_week', $at->format('l'));
        if (!$row || !$row->is_available) {
            return false;
        }
        $start = $at->copy()->setTimeFromTimeString($row->start_time);
        $end = $at->copy()->setTimeFromTimeString($row->end_time);
        if ($end->lessThanOrEqualTo($start)) {
            return $at->greaterThanOrEqualTo($start) || $at->lessThan($end);
        }
        return $at->between($start, $end);
    }

    /**
     * @return array{0: array<string,int>, 1: array<string,int>, 2: array<string,int>}
     *         [ "pid|Y-m-d H:i" => n ], [ "pid|Y-m-d" => n ], [ "Y-m-d H:i" => n unassigned ]
     */
    private static function bookings(string $type, array $providerIds, Carbon $from, Carbon $to, bool $includePool): array
    {
        $column = self::orderColumn($type);
        $orders = Order::whereNotNull('scheduled_at')
            ->whereBetween('scheduled_at', [$from, $to])
            ->whereNotIn('status', self::RELEASED_STATUSES)
            ->where(function ($q) use ($column, $providerIds, $includePool, $type) {
                $q->whereIn($column, $providerIds);
                if ($includePool && $type !== 'driver') {
                    $q->orWhereIn('assigned_driver_id', $providerIds);
                    $q->orWhere(function ($q2) use ($column, $type) {
                        $q2->whereNull($column)->whereNull('assigned_driver_id');
                        if ($type === 'lab') {
                            $q2->forLab();
                        } else {
                            $q2->forNursing();
                        }
                    });
                }
            })
            ->get([$column, 'assigned_driver_id', 'scheduled_at']);

        $slot = [];
        $day = [];
        $pool = [];
        foreach ($orders as $o) {
            $at = Carbon::parse($o->scheduled_at);
            $pid = $o->{$column} ?: ($includePool ? $o->assigned_driver_id : null);
            if ($pid) {
                $slot["$pid|" . $at->format('Y-m-d H:i')] = ($slot["$pid|" . $at->format('Y-m-d H:i')] ?? 0) + 1;
                $day["$pid|" . $at->toDateString()] = ($day["$pid|" . $at->toDateString()] ?? 0) + 1;
            } else {
                $pool[$at->format('Y-m-d H:i')] = ($pool[$at->format('Y-m-d H:i')] ?? 0) + 1;
            }
        }

        return [$slot, $day, $pool];
    }

    /** Upcoming scheduled orders of a provider (for admin + driver views). */
    public static function upcoming(int $userId, string $type, int $days = 7): Collection
    {
        return Order::where(self::orderColumn($type), $userId)
            ->whereNotNull('scheduled_at')
            ->whereBetween('scheduled_at', [Carbon::now()->subHours(2), Carbon::now()->addDays($days)->endOfDay()])
            ->whereNotIn('status', array_merge(self::RELEASED_STATUSES, ['completed']))
            ->with('patient:id,name,phone')
            ->orderBy('scheduled_at')
            ->get()
            ->map(fn (Order $o) => [
                'id' => $o->id,
                'service_type' => $o->service_type,
                'status' => $o->status,
                'scheduled_at' => Carbon::parse($o->scheduled_at)->format('Y-m-d H:i'),
                'patient_name' => $o->patient->name ?? null,
                'address' => $o->location_details['address'] ?? null,
            ]);
    }
}
