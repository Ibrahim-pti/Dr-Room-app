<?php

namespace App\Services;

use App\Models\AppSetting;
use App\Models\Order;
use Carbon\Carbon;

/**
 * Single source of truth for commission rates and commission maths.
 *
 * Rates are stored per month (commission_{type}_rate_YYYY_MM). A month without
 * its own rates inherits the global default (commission_{type}_rate), so a new
 * month automatically starts with the last saved rates and the admin can
 * change them for that month only.
 */
class CommissionService
{
    public const TYPES = ['nursing', 'lab'];

    private const DEFAULTS = ['nursing' => 10.0, 'lab' => 15.0];

    /** Map an order service_type onto a commission category (or null = no commission category). */
    public static function categoryFor(?string $serviceType): ?string
    {
        $s = strtolower((string) $serviceType);
        if (str_contains($s, 'lab')) {
            return 'lab';
        }
        if (str_contains($s, 'nurs')) {
            return 'nursing';
        }
        return null;
    }

    private static function monthKey(string $type, int $year, int $month): string
    {
        return sprintf('commission_%s_rate_%04d_%02d', $type, $year, $month);
    }

    public static function defaultRate(string $type): float
    {
        return (float) AppSetting::get("commission_{$type}_rate", self::DEFAULTS[$type] ?? 10.0);
    }

    public static function rateFor(string $type, int $year, int $month): float
    {
        $monthly = AppSetting::get(self::monthKey($type, $year, $month));
        return $monthly !== null && $monthly !== '' ? (float) $monthly : self::defaultRate($type);
    }

    /** @return array{nursing_rate: float, lab_rate: float, is_custom: bool} */
    public static function ratesFor(int $year, int $month): array
    {
        $isCustom = false;
        foreach (self::TYPES as $t) {
            if (AppSetting::get(self::monthKey($t, $year, $month)) !== null) {
                $isCustom = true;
            }
        }

        return [
            'nursing_rate' => self::rateFor('nursing', $year, $month),
            'lab_rate' => self::rateFor('lab', $year, $month),
            'is_custom' => $isCustom,
        ];
    }

    /** Rate for a service type at a given moment (used when a new order is created). */
    public static function rateForService(?string $serviceType, ?Carbon $at = null): float
    {
        $at ??= now();
        $cat = self::categoryFor($serviceType);
        return $cat ? self::rateFor($cat, (int) $at->year, (int) $at->month) : 0.0;
    }

    /**
     * Save rates for a month. Also updates the global default when saving the
     * current (or a future) month, so following months inherit them.
     * Returns the number of orders whose commission was recalculated.
     */
    public static function saveRates(int $year, int $month, float $nursing, float $lab): int
    {
        $rates = ['nursing' => $nursing, 'lab' => $lab];
        foreach ($rates as $type => $rate) {
            AppSetting::set(self::monthKey($type, $year, $month), $rate, 'commission');
        }

        $selected = Carbon::create($year, $month, 1)->startOfMonth();
        if ($selected->greaterThanOrEqualTo(now()->startOfMonth())) {
            foreach ($rates as $type => $rate) {
                AppSetting::set("commission_{$type}_rate", $rate, 'commission');
            }
        }

        return self::recalculateMonth($year, $month);
    }

    /** Re-apply the month's rates to every non-cancelled order of that month. */
    public static function recalculateMonth(int $year, int $month): int
    {
        $start = Carbon::create($year, $month, 1)->startOfMonth();
        $end = (clone $start)->endOfMonth();
        $rates = self::ratesFor($year, $month);

        $count = 0;
        Order::whereBetween('created_at', [$start, $end])
            ->whereNotIn('status', ['cancelled', 'rejected'])
            ->chunkById(200, function ($orders) use ($rates, &$count) {
                foreach ($orders as $order) {
                    $cat = self::categoryFor($order->service_type);
                    $rate = $cat ? (float) $rates["{$cat}_rate"] : 0.0;
                    [$comm, $net] = self::split((float) $order->total_price, $rate);
                    $order->forceFill([
                        'commission_rate' => $rate,
                        'commission_amount' => $comm,
                        'provider_net_amount' => $net,
                    ])->saveQuietly();
                    $count++;
                }
            });

        return $count;
    }

    /** @return array{0: float, 1: float} [commission, provider net] — always sum to total. */
    public static function split(float $total, float $rate): array
    {
        $total = max(0.0, $total);
        $comm = round($total * $rate / 100, 2);
        return [$comm, round($total - $comm, 2)];
    }

    /** Commission of an existing order, falling back to the month rate if it was never stored. */
    public static function commissionOf(Order $order): float
    {
        $total = (float) $order->total_price;
        if ((float) ($order->commission_rate ?? 0) > 0 || (float) ($order->commission_amount ?? 0) > 0) {
            return (float) $order->commission_amount > 0
                ? min($total, (float) $order->commission_amount)
                : self::split($total, (float) $order->commission_rate)[0];
        }
        $at = $order->created_at ? Carbon::parse($order->created_at) : now();
        return self::split($total, self::rateForService($order->service_type, $at))[0];
    }
}
