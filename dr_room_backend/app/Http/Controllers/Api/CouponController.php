<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Coupon;
use Illuminate\Http\Request;

class CouponController extends Controller
{
    /**
     * Check whether at least one usable discount coupon is currently active.
     */
    public function availability()
    {
        $now = now();

        $hasActive = Coupon::query()
            ->where('is_active', true)
            ->where(function ($q) use ($now) {
                $q->whereNull('starts_at')->orWhere('starts_at', '<=', $now);
            })
            ->where(function ($q) use ($now) {
                $q->whereNull('expires_at')->orWhere('expires_at', '>=', $now);
            })
            ->where(function ($q) {
                $q->whereNull('usage_limit')->orWhereColumn('used_count', '<', 'usage_limit');
            })
            ->exists();

        return response()->json([
            'success' => true,
            'has_active_coupons' => $hasActive,
        ]);
    }

    /**
     * Validate a promo code against an order amount
     */
    public function validateCoupon(Request $request)
    {
        $request->validate([
            'code' => 'required|string',
            'order_amount' => 'required|numeric|min:0',
        ]);

        $code = trim(strtoupper($request->code));
        $orderAmount = (float) $request->order_amount;

        $coupon = Coupon::where('code', $code)->first();

        if (!$coupon) {
            return response()->json([
                'success' => false,
                'message' => 'کۆدی داشکاندن نادروستە یان بوونی نییە',
            ], 422);
        }

        $check = $coupon->isValidFor($orderAmount);

        if (!$check['valid']) {
            return response()->json([
                'success' => false,
                'message' => $check['message'],
            ], 422);
        }

        return response()->json([
            'success' => true,
            'message' => 'کۆدی داشکاندن بە سەرکەوتوویی جێبەجێکرا',
            'data' => [
                'code' => $coupon->code,
                'title' => $coupon->title,
                'discount_type' => $coupon->discount_type,
                'discount_value' => $coupon->discount_value,
                'discount_amount' => $check['discount'],
                'final_amount' => $check['final_amount'],
            ]
        ]);
    }
}

