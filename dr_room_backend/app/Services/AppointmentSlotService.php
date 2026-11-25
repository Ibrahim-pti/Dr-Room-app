<?php

namespace App\Services;

use App\Models\Appointment;
use App\Models\Doctor;
use Carbon\Carbon;
use Illuminate\Support\Collection;

/**
 * Single source of truth for which appointment times exist.
 *
 * Both the availability endpoint the app renders and the booking endpoint that
 * accepts a reservation run through here, so the two can never disagree.
 */
class AppointmentSlotService
{
    public const TIMEZONE = 'Asia/Baghdad';

    /** How many days ahead patients may book. */
    public const HORIZON_DAYS = 14;

    /** Statuses that still occupy a slot. */
    private const BLOCKING_STATUSES = ['pending', 'confirmed'];

    /**
     * Every bookable day in the horizon, each with its generated slots.
     *
     * @return array<int, array{date: string, day_of_week: string, slots: array}>
     */
    public function availability(Doctor $doctor): array
    {
        $schedules = $doctor->relationLoaded('schedules')
            ? $doctor->schedules->groupBy('day_of_week')
            : $doctor->schedules()->get()->groupBy('day_of_week');
        if ($schedules->isEmpty()) {
            return [];
        }

        $taken = $this->takenTimes($doctor);
        $today = Carbon::today(self::TIMEZONE);
        $days = [];

        for ($offset = 0; $offset < self::HORIZON_DAYS; $offset++) {
            $date = $today->copy()->addDays($offset);
            $daySchedules = $schedules->get($date->format('l'));

            if (! $daySchedules) {
                continue;
            }

            $slots = $this->slotsForDate($daySchedules, $date, $taken);

            // A day with nothing left (all past or all booked) is not offered.
            if (empty($slots)) {
                continue;
            }

            $days[] = [
                'date' => $date->toDateString(),
                'day_of_week' => $date->format('l'),
                'slots' => $slots,
            ];
        }

        return $days;
    }

    /**
     * True when [$dateTime] is a real, still-free slot for this doctor.
     */
    public function isBookable(Doctor $doctor, Carbon $dateTime): bool
    {
        $localDt = ProviderSlotService::parseWallClock($dateTime);
        $now = Carbon::now(self::TIMEZONE);
        if ($localDt->lessThanOrEqualTo($now)) {
            return false;
        }
        if ($localDt->greaterThan(Carbon::today(self::TIMEZONE)->addDays(self::HORIZON_DAYS)->endOfDay())) {
            return false;
        }

        $daySchedules = $doctor->schedules()
            ->where('day_of_week', $localDt->format('l'))
            ->get();

        if ($daySchedules->isEmpty()) {
            return false;
        }

        $wanted = $localDt->format('H:i');

        foreach ($this->slotsForDate($daySchedules, $localDt->copy()->startOfDay(), $this->takenTimes($doctor)) as $slot) {
            if ($slot['time'] === $wanted && ! $slot['taken']) {
                return true;
            }
        }

        return false;
    }

    /**
     * Splits a day's opening hours into slots, marking the booked ones and
     * dropping any that have already passed.
     *
     * @return array<int, array{time: string, label: string, taken: bool, reason?: string}>
     */
    private function slotsForDate(Collection $daySchedules, Carbon $date, Collection $taken): array
    {
        $now = Carbon::now(self::TIMEZONE);
        $slots = [];

        foreach ($daySchedules as $schedule) {
            $step = max(5, (int) ($schedule->slot_minutes ?: 30));

            $cursor = $date->copy()->setTimeFromTimeString($schedule->start_time);
            $end = $date->copy()->setTimeFromTimeString($schedule->end_time);

            // An end time before the start means the shift runs past midnight.
            if ($end->lessThanOrEqualTo($cursor)) {
                $end->addDay();
            }

            while ($cursor->lessThan($end)) {
                if ($cursor->greaterThan($now)) {
                    $key = $cursor->format('Y-m-d H:i');
                    
                    if (!$schedule->is_available) {
                        // Mark as taken with a reason
                        $slots[$key] = [
                            'time' => $cursor->format('H:i'),
                            'label' => $cursor->format('h:i A'),
                            'taken' => true,
                            'reason' => $schedule->reason ?: __('بەردەست نییە'),
                        ];
                    } else {
                        // Regular slot
                        $slots[$key] = [
                            'time' => $cursor->format('H:i'),
                            'label' => $cursor->format('h:i A'),
                            'taken' => $taken->contains($key),
                        ];
                    }
                }
                $cursor->addMinutes($step);
            }
        }

        // Overlapping shifts can produce the same slot twice; keys de-duplicate.
        ksort($slots);

        return array_values($slots);
    }

    /** "Y-m-d H:i" of every appointment that still holds a slot. */
    private function takenTimes(Doctor $doctor): Collection
    {
        return Appointment::where('doctor_id', $doctor->id)
            ->whereIn('status', self::BLOCKING_STATUSES)
            ->where('appointment_date', '>=', Carbon::today(self::TIMEZONE)->format('Y-m-d H:i:s'))
            ->pluck('appointment_date')
            ->map(fn ($value) => ProviderSlotService::parseWallClock($value)->format('Y-m-d H:i'));
    }
}
