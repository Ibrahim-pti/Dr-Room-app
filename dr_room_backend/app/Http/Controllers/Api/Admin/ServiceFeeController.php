<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use Illuminate\Http\Request;

class ServiceFeeController extends Controller
{
    public const SETTING_KEY = 'service_fee_config';

    public static function defaults(): array
    {
        return [
            'is_enabled' => true,
            'is_free' => false,
            'amount' => 1000.0,
            'has_discount' => false,
            'discount_percent' => 0.0,
            'discount_amount' => 0.0,
            'note' => null,
        ];
    }

    public static function current(): array
    {
        $saved = AppSetting::get(self::SETTING_KEY);
        $defaults = self::defaults();
        if (!is_array($saved)) {
            return $defaults;
        }

        return [
            'is_enabled' => (bool) ($saved['is_enabled'] ?? $defaults['is_enabled']),
            'is_free' => (bool) ($saved['is_free'] ?? $defaults['is_free']),
            'amount' => (float) ($saved['amount'] ?? $defaults['amount']),
            'has_discount' => (bool) ($saved['has_discount'] ?? $defaults['has_discount']),
            'discount_percent' => (float) ($saved['discount_percent'] ?? $defaults['discount_percent']),
            'discount_amount' => (float) ($saved['discount_amount'] ?? $defaults['discount_amount']),
            'note' => $saved['note'] ?? $defaults['note'],
        ];
    }

    public function show()
    {
        return response()->json([
            'success' => true,
            'data' => self::current(),
        ]);
    }

    public function update(Request $request)
    {
        $validated = $request->validate([
            'is_enabled' => 'required|boolean',
            'is_free' => 'required|boolean',
            'amount' => 'required|numeric|min:0',
            'has_discount' => 'required|boolean',
            'discount_percent' => 'nullable|numeric|min:0|max:100',
            'discount_amount' => 'nullable|numeric|min:0',
            'note' => 'nullable|string|max:500',
        ]);

        $payload = [
            'is_enabled' => (bool) $validated['is_enabled'],
            'is_free' => (bool) $validated['is_free'],
            'amount' => (float) $validated['amount'],
            'has_discount' => (bool) $validated['has_discount'],
            'discount_percent' => (float) ($validated['discount_percent'] ?? 0.0),
            'discount_amount' => (float) ($validated['discount_amount'] ?? 0.0),
            'note' => $validated['note'] ?? null,
        ];

        AppSetting::set(
            self::SETTING_KEY,
            $payload,
            'pricing',
            'Global platform service fee configuration'
        );

        return response()->json([
            'success' => true,
            'message' => 'ڕێکخستنی کرێی خزمەتگوزاری نوێکرایەوە',
            'data' => $payload,
        ]);
    }
}
