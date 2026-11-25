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
 * Uses Asia/Baghdad consistently so Admin Staff Schedule, Driver App, Patient
 * checkout slot picker, and Auto-Dispatch agree on shifts and slot capacity.
 */
class ProviderSlotService
{
    public const TIMEZONE = 'Asia/Baghdad';
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
        'driver' => ['start_time' => '08:00:00', 'end_time' => '22:00:00', 'slot_minutes' => 60, 'slot_capacity' => 2, 'max_daily_orders' => 20],
    ];

    public static function nowLocal(): Carbon
    {
        return Carbon::now(self::TIMEZONE);
    }

    public static function todayLocal(): Carbon
    {
        return Carbon::today(self::TIMEZONE);
    }

    public static function parseLocal($dt): Carbon
    {
        if ($dt instanceof Carbon) {
            return self::parseWallClock($dt);
        }
        return self::parseWallClock((string) $dt);
    }

    /**
     * Parse wall-clock scheduled_at values ("Y-m-d H:i[:s]") in Asia/Baghdad without
     * shifting +3h when loaded from a UTC-configured Eloquent datetime cast.
     */
    public static function parseWallClock($dt): Carbon
    {
        if ($dt instanceof Carbon) {
            return Carbon::createFromFormat('Y-m-d H:i:s', $dt->format('Y-m-d H:i:s'), self::TIMEZONE);
        }
        $raw = trim((string) $dt);
        if (preg_match('/(Z|[+-]\d{2}:?\d{2})$/i', $raw)) {
            return Carbon::parse($raw)->timezone(self::TIMEZONE);
        }
        return Carbon::parse($raw, self::TIMEZONE);
    }

    public static function isValidType(?string $type): bool
    {
        return isset(self::TYPES[$type]);
    }

    /** nursing / lab service_type -> nurse / lab provider type. */
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

    /** Map website registration shift + work_days to concrete weekly hours and open days. */
    public static function driverScheduleTemplate(?string $shift, ?string $workDays): array
    {
        [$start, $end] = match ($shift) {
            'morning' => ['08:00:00', '14:00:00'],
            'evening' => ['14:00:00', '22:00:00'],
            default => ['08:00:00', '22:00:00'],
        };

        $openDays = match ($workDays) {
            'weekdays' => ['Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday'],
            'part_time' => ['Thursday', 'Friday', 'Saturday'],
            default => self::DAYS,
        };

        return [
            'start_time' => $start,
            'end_time' => $end,
            'open_days' => $openDays,
        ];
    }

    /** Seed provider_schedules rows for a driver right from their website application. */
    public static function seedFromDriverProfile(int $userId, ?string $shift, ?string $workDays, bool $onlyIfEmpty = false): void
    {
        if ($onlyIfEmpty && ProviderSchedule::where('user_id', $userId)->where('provider_type', 'driver')->exists()) {
            return;
        }

        $tpl = self::driverScheduleTemplate($shift, $workDays);
        $d = self::DEFAULTS['driver'];
        foreach (self::DAYS as $day) {
            ProviderSchedule::updateOrCreate(
                ['user_id' => $userId, 'day_of_week' => $day],
                [
                    'provider_type' => 'driver',
                    'start_time' => $tpl['start_time'],
                    'end_time' => $tpl['end_time'],
                    'is_available' => in_array($day, $tpl['open_days'], true),
                    'slot_minutes' => $d['slot_minutes'],
                    'slot_capacity' => $d['slot_capacity'],
                    'max_daily_orders' => $d['max_daily_orders'],
                ]
            );
        }
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
        $savedRows = ProviderSchedule::whereIn('user_id', $ids)
            ->where('provider_type', $type)
            ->get()
            ->groupBy('user_id');

        $cutoff = self::nowLocal()->subHours(1)->format('Y-m-d H:i:s');
        $col = self::orderColumn($type);

        if ($type === 'driver') {
            $upcomingByDriver = [];
            $upcomingOrders = Order::where(function ($q) use ($ids) {
                $q->whereIn('assigned_driver_id', $ids)
                  ->orWhereIn('assigned_nurse_id', $ids);
            })
                ->whereNotNull('scheduled_at')
                ->where('scheduled_at', '>=', $cutoff)
                ->whereNotIn('status', array_merge(self::RELEASED_STATUSES, ['completed']))
                ->get(['id', 'assigned_driver_id', 'assigned_nurse_id']);

            foreach ($upcomingOrders as $o) {
                $matched = [];
                if ($o->assigned_driver_id && in_array((int) $o->assigned_driver_id, $ids, true)) {
                    $matched[(int) $o->assigned_driver_id] = true;
                }
                if ($o->assigned_nurse_id && in_array((int) $o->assigned_nurse_id, $ids, true)) {
                    $matched[(int) $o->assigned_nurse_id] = true;
                }
                foreach (array_keys($matched) as $uid) {
                    $upcomingByDriver[$uid] = ($upcomingByDriver[$uid] ?? 0) + 1;
                }
            }
            $upcomingCounts = collect($upcomingByDriver);
        } else {
            $upcomingCounts = Order::whereIn($col, $ids)
                ->whereNotNull('scheduled_at')
                ->where('scheduled_at', '>=', $cutoff)
                ->whereNotIn('status', array_merge(self::RELEASED_STATUSES, ['completed']))
                ->selectRaw("$col as provider_id, COUNT(*) as cnt")
                ->groupBy($col)
                ->pluck('cnt', 'provider_id');
        }

        $nowLocal = self::nowLocal();

        return $providers->map(function ($u) use ($savedRows, $upcomingCounts, $type, $nowLocal) {
            $rows = $savedRows->get($u->id);
            $hasCustom = $rows !== null && $rows->isNotEmpty();

            if ($type === 'driver') {
                $profile = $u->driver?->resolvedFieldProfile() ?? [];
                $shift = $profile['availability_shift'] ?? 'full_flex';
                $workDays = $profile['work_days'] ?? 'daily';
                $tpl = self::driverScheduleTemplate($shift, $workDays);
                $tplStart = substr($tpl['start_time'], 0, 5);
                $tplEnd = substr($tpl['end_time'], 0, 5);

                $week = self::week($u->id, 'driver', $u->driver);
                $openRows = array_values(array_filter($week, fn ($r) => $r['is_available']));
                $firstOpen = $openRows[0] ?? ($week[0] ?? null);

                // Detect if admin/driver customized hours or active days away from website template
                $matchesWebsite = true;
                foreach ($week as $r) {
                    $expectedOpen = in_array($r['day_of_week'], $tpl['open_days'], true);
                    if ((bool) $r['is_available'] !== $expectedOpen) {
                        $matchesWebsite = false;
                        break;
                    }
                    if ($r['is_available'] && ($r['start_time'] !== $tplStart || $r['end_time'] !== $tplEnd)) {
                        $matchesWebsite = false;
                        break;
                    }
                }

                return [
                    'id' => $u->id,
                    'name' => $u->name,
                    'phone' => $u->phone,
                    'city' => $u->driver?->city ?? 'هەولێر',
                    'duty_status' => $u->driver?->duty_status ?? 'offline',
                    'is_on_shift_now' => self::isOnShift($u->id, $nowLocal),
                    'applicant_role' => $profile['applicant_role'] ?? 'phlebotomist',
                    'service_scope' => $u->driver?->service_scope ?? 'both',
                    'availability_shift' => $shift,
                    'work_days' => $workDays,
                    'schedule_matches_website' => $matchesWebsite,
                    'service_areas' => $profile['service_areas'] ?? null,
                    'start_time' => $firstOpen['start_time'] ?? '08:00',
                    'end_time' => $firstOpen['end_time'] ?? '22:00',
                    'slot_minutes' => $firstOpen['slot_minutes'] ?? 60,
                    'slot_capacity' => $firstOpen['slot_capacity'] ?? 2,
                    'max_daily_orders' => $firstOpen['max_daily_orders'] ?? 20,
                    'active_days' => count($openRows),
                    'days_summary' => array_map(fn ($r) => [
                        'day_of_week' => $r['day_of_week'],
                        'is_available' => $r['is_available'],
                        'start_time' => $r['start_time'],
                        'end_time' => $r['end_time'],
                    ], $week),
                    'has_custom_schedule' => $hasCustom,
                    'upcoming_count' => (int) ($upcomingCounts->get($u->id) ?? 0),
                ];
            }

            $activeDays = $hasCustom ? $rows->where('is_available', true)->count() : 7;
            return [
                'id' => $u->id,
                'name' => $u->name,
                'phone' => $u->phone,
                'has_custom_schedule' => $hasCustom,
                'active_days' => $activeDays,
                'upcoming_count' => (int) ($upcomingCounts->get($u->id) ?? 0),
            ];
        })->values();
    }

    // ─── Weekly schedule ────────────────────────────────────────────────────

    /** The 7-day week for a provider, filling missing days from website profile / defaults. */
    public static function week(int $userId, string $type, ?Driver $driver = null): array
    {
        $existing = ProviderSchedule::where('user_id', $userId)
            ->where('provider_type', $type)
            ->get()
            ->keyBy('day_of_week');

        if ($existing->isEmpty()) {
            $existing = ProviderSchedule::where('user_id', $userId)->get()->keyBy('day_of_week');
        }

        $driverTemplate = null;
        if ($type === 'driver') {
            $driver ??= Driver::where('user_id', $userId)->first();
            if ($driver) {
                $profile = $driver->resolvedFieldProfile();
                $driverTemplate = self::driverScheduleTemplate(
                    $profile['availability_shift'] ?? null,
                    $profile['work_days'] ?? null
                );
            }
        }

        return array_map(function (string $day) use ($existing, $userId, $type, $driverTemplate) {
            $row = $existing->get($day);
            return self::normalizeRow($row ? $row->toArray() : null, $day, $userId, $type, $driverTemplate);
        }, self::DAYS);
    }

    private static function normalizeRow(?array $row, string $day, int $userId, string $type, ?array $driverTemplate = null): array
    {
        $d = self::DEFAULTS[$type];
        $defaultStart = $driverTemplate['start_time'] ?? $d['start_time'];
        $defaultEnd = $driverTemplate['end_time'] ?? $d['end_time'];
        $defaultAvail = $driverTemplate ? in_array($day, $driverTemplate['open_days'], true) : true;

        return [
            'user_id' => $userId,
            'provider_type' => $type,
            'day_of_week' => $day,
            'start_time' => substr((string) ($row['start_time'] ?? $defaultStart), 0, 5),
            'end_time' => substr((string) ($row['end_time'] ?? $defaultEnd), 0, 5),
            'is_available' => (bool) ($row['is_available'] ?? $defaultAvail),
            'slot_minutes' => (int) ($row['slot_minutes'] ?? $d['slot_minutes']),
            'slot_capacity' => (int) ($row['slot_capacity'] ?? $d['slot_capacity']),
            'max_daily_orders' => (int) ($row['max_daily_orders'] ?? $d['max_daily_orders']),
            'is_default' => $row === null,
        ];
    }

    public static function saveWeek(int $userId, string $type, array $days): void
    {
        $d = self::DEFAULTS[$type] ?? self::DEFAULTS['driver'];
        foreach ($days as $item) {
            if (!in_array($item['day_of_week'] ?? null, self::DAYS, true)) {
                continue;
            }
            ProviderSchedule::updateOrCreate(
                ['user_id' => $userId, 'day_of_week' => $item['day_of_week']],
                [
                    'provider_type' => $type,
                    'start_time' => self::normalizeTime($item['start_time'] ?? $d['start_time']),
                    'end_time' => self::normalizeTime($item['end_time'] ?? $d['end_time']),
                    'is_available' => filter_var($item['is_available'] ?? true, FILTER_VALIDATE_BOOLEAN),
                    'slot_minutes' => max(10, min(240, (int) ($item['slot_minutes'] ?? $d['slot_minutes']))),
                    'slot_capacity' => max(1, min(50, (int) ($item['slot_capacity'] ?? $d['slot_capacity']))),
                    'max_daily_orders' => max(1, min(200, (int) ($item['max_daily_orders'] ?? $d['max_daily_orders']))),
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
     * provider's; without one they are pooled across every provider of the type
     * plus approved field staff handling that category.
     *
     * @return array<int, array{date: string, day_of_week: string, closed: bool, slots: array}>
     */
    public static function availability(string $type, ?int $userId = null, ?Carbon $from = null, int $days = self::HORIZON_DAYS): array
    {
        $from = ($from ? self::parseLocal($from) : self::todayLocal())->copy()->startOfDay();
        $to = $from->copy()->addDays($days)->endOfDay();

        $baseIds = $userId
            ? collect([(int) $userId])
            : self::providers($type)->pluck('id')->map(fn ($id) => (int) $id);

        $driverPoolIds = collect();
        if (!$userId && ($type === 'nurse' || $type === 'lab')) {
            $driverPoolIds = self::providerSummaries('driver', $type)
                ->pluck('id')
                ->map(fn ($id) => (int) $id);
        }

        $providerIds = $baseIds->merge($driverPoolIds)->unique()->values();
        if ($providerIds->isEmpty()) {
            return [];
        }

        $baseIdLookup = array_flip($baseIds->all());
        $weeks = $providerIds->mapWithKeys(function ($id) use ($type, $baseIdLookup) {
            $weekType = isset($baseIdLookup[(int) $id]) ? $type : 'driver';
            return [(int) $id => collect(self::week((int) $id, $weekType))->keyBy('day_of_week')];
        });

        [$slotBookings, $dayBookings, $poolBookings] = self::bookings($type, $providerIds->all(), $from, $to, !$userId);

        $now = self::nowLocal();
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

    /** True when $at is a real, still-free slot in Asia/Baghdad time. */
    public static function isBookable(string $type, ?int $userId, Carbon $at): bool
    {
        $localAt = self::parseLocal($at);
        $now = self::nowLocal();
        $horizon = self::todayLocal()->addDays(self::HORIZON_DAYS + 1)->endOfDay();

        if ($localAt->lessThanOrEqualTo($now) || $localAt->greaterThan($horizon)) {
            return false;
        }
        $day = self::availability($type, $userId, $localAt->copy()->startOfDay(), 1)[0] ?? null;
        if (!$day) {
            return false;
        }
        $targetHm = $localAt->format('H:i');
        foreach ($day['slots'] as $slot) {
            if ($slot['time'] === $targetHm) {
                return !$slot['taken'];
            }
        }
        return false;
    }

    /**
     * Check whether a driver can handle an order at $at (e.g. during auto-dispatch),
     * matching arbitrary sub-hour scheduled slots (like 14:30) against the driver's
     * hourly window [14:00, 15:00) and checking daily max + slot capacity.
     */
    public static function canDriverHandleAt(int $driverUserId, Carbon $at, ?int $excludeOrderId = null): bool
    {
        $localAt = self::parseLocal($at);
        $week = collect(self::week($driverUserId, 'driver'));
        $row = $week->firstWhere('day_of_week', $localAt->format('l'));
        if (!$row || !$row['is_available']) {
            return false;
        }

        $dayStart = $localAt->copy()->startOfDay()->setTimeFromTimeString($row['start_time']);
        $dayEnd = $localAt->copy()->startOfDay()->setTimeFromTimeString($row['end_time']);
        if ($dayEnd->lessThanOrEqualTo($dayStart)) {
            $dayEnd->addDay();
            if ($localAt->lessThan($dayStart)) {
                $dayStart->subDay();
                $dayEnd->subDay();
            }
        }

        // Handle previous day's overnight shift if needed, otherwise verify within window
        if ($localAt->lessThan($dayStart) || $localAt->greaterThanOrEqualTo($dayEnd)) {
            return false;
        }

        $dateFrom = $localAt->copy()->startOfDay()->format('Y-m-d H:i:s');
        $dateTo = $localAt->copy()->endOfDay()->format('Y-m-d H:i:s');

        $dayOrders = Order::whereNotNull('scheduled_at')
            ->whereBetween('scheduled_at', [$dateFrom, $dateTo])
            ->whereNotIn('status', self::RELEASED_STATUSES)
            ->when($excludeOrderId, fn ($q) => $q->where('id', '!=', $excludeOrderId))
            ->where(function ($q) use ($driverUserId) {
                $q->where('assigned_driver_id', $driverUserId)
                  ->orWhere('assigned_nurse_id', $driverUserId);
            })
            ->get(['scheduled_at']);

        if ($dayOrders->count() >= (int) $row['max_daily_orders']) {
            return false;
        }

        // Find the containing slot window [slotStart, slotEnd)
        $step = max(10, (int) $row['slot_minutes']);
        $minutesSinceStart = max(0, (int) $dayStart->diffInMinutes($localAt, false));
        $slotIndex = intdiv($minutesSinceStart, $step);
        $slotStart = $dayStart->copy()->addMinutes($slotIndex * $step);
        $slotEnd = $slotStart->copy()->addMinutes($step);

        $inSlotCount = $dayOrders->filter(function (Order $o) use ($slotStart, $slotEnd) {
            $oAt = self::parseLocal($o->scheduled_at);
            return $oAt->greaterThanOrEqualTo($slotStart) && $oAt->lessThan($slotEnd);
        })->count();

        return $inSlotCount < (int) $row['slot_capacity'];
    }

    /** Is the provider working right now? Uses Asia/Baghdad time and saved schedule / website profile. */
    public static function isOnShift(int $userId, ?Carbon $at = null): bool
    {
        $localAt = $at ? self::parseLocal($at) : self::nowLocal();
        $week = collect(self::week($userId, 'driver'));

        $row = $week->firstWhere('day_of_week', $localAt->format('l'));
        if ($row && $row['is_available']) {
            $start = $localAt->copy()->setTimeFromTimeString($row['start_time']);
            $end = $localAt->copy()->setTimeFromTimeString($row['end_time']);
            if ($end->lessThanOrEqualTo($start)) {
                if ($localAt->greaterThanOrEqualTo($start)) {
                    return true;
                }
            } elseif ($localAt->between($start, $end)) {
                return true;
            }
        }

        // Check if previous day's overnight shift spans into early hours of $localAt
        $prevRow = $week->firstWhere('day_of_week', $localAt->copy()->subDay()->format('l'));
        if ($prevRow && $prevRow['is_available']) {
            $prevStart = $localAt->copy()->subDay()->setTimeFromTimeString($prevRow['start_time']);
            $prevEnd = $localAt->copy()->subDay()->setTimeFromTimeString($prevRow['end_time']);
            if ($prevEnd->lessThanOrEqualTo($prevStart)) {
                $prevEnd->addDay();
                if ($localAt->between($prevStart, $prevEnd)) {
                    return true;
                }
            }
        }

        return false;
    }

    /**
     * @return array{0: array<string,int>, 1: array<string,int>, 2: array<string,int>}
     *         [ "pid|Y-m-d H:i" => n ], [ "pid|Y-m-d" => n ], [ "Y-m-d H:i" => n unassigned ]
     */
    private static function bookings(string $type, array $providerIds, Carbon $from, Carbon $to, bool $includePool): array
    {
        $column = self::orderColumn($type);
        $orders = Order::whereNotNull('scheduled_at')
            ->whereBetween('scheduled_at', [$from->format('Y-m-d H:i:s'), $to->format('Y-m-d H:i:s')])
            ->whereNotIn('status', self::RELEASED_STATUSES)
            ->where(function ($q) use ($column, $providerIds, $includePool, $type) {
                $q->whereIn($column, $providerIds);
                if ($type === 'driver') {
                    $q->orWhereIn('assigned_nurse_id', $providerIds);
                }
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
            ->get([$column, 'assigned_driver_id', 'assigned_nurse_id', 'scheduled_at']);

        $slot = [];
        $day = [];
        $pool = [];
        foreach ($orders as $o) {
            $at = self::parseLocal($o->scheduled_at);
            $pid = $o->{$column}
                ?: ($type === 'driver' ? $o->assigned_nurse_id : null)
                ?: ($includePool ? $o->assigned_driver_id : null);
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
        $now = self::nowLocal();
        $col = self::orderColumn($type);

        return Order::where(function ($q) use ($col, $type, $userId) {
            $q->where($col, $userId);
            if ($type === 'driver') {
                $q->orWhere('assigned_nurse_id', $userId);
            }
        })
            ->whereNotNull('scheduled_at')
            ->whereBetween('scheduled_at', [
                $now->copy()->subHours(2)->format('Y-m-d H:i:s'),
                $now->copy()->addDays($days)->endOfDay()->format('Y-m-d H:i:s'),
            ])
            ->whereNotIn('status', array_merge(self::RELEASED_STATUSES, ['completed']))
            ->with('patient:id,name,phone')
            ->orderBy('scheduled_at')
            ->get()
            ->map(fn (Order $o) => [
                'id' => $o->id,
                'service_type' => $o->service_type,
                'status' => $o->status,
                'scheduled_at' => self::parseLocal($o->scheduled_at)->format('Y-m-d H:i'),
                'patient_name' => $o->patient->name ?? null,
                'address' => $o->resolvePatientLocation()['address'] ?: null,
            ]);
    }
}
