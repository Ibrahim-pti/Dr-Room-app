<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use App\Models\Coupon;
use App\Models\LoyaltyTransaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Str;

class LoyaltyController extends Controller
{
    public function balance()
    {
        $user = Auth::user();
        $points = $user->loyalty_points ?? 0;

        // Ratio: e.g. 100 points = 1,000 IQD (1 point = 10 IQD)
        $pointValueIqd = AppSetting::get('loyalty_point_iqd_value', 10);
        $monetaryValue = $points * $pointValueIqd;

        // Determine tier
        $tier = 'Silver';
        if ($points >= 5000) {
            $tier = 'Platinum';
        } elseif ($points >= 1500) {
            $tier = 'Gold';
        }

        return response()->json([
            'success' => true,
            'data' => [
                'points' => $points,
                'monetary_value_iqd' => $monetaryValue,
                'tier' => $tier,
                'min_redeem_points' => 200,
            ]
        ]);
    }

    public function history()
    {
        $transactions = LoyaltyTransaction::where('user_id', Auth::id())
            ->latest()
            ->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $transactions,
        ]);
    }

    public function redeem(Request $request)
    {
        $user = Auth::user();
        $pointsAvailable = $user->loyalty_points ?? 0;

        $request->validate([
            'points' => 'required|integer|min:200|max:' . $pointsAvailable,
        ], [
            'points.max' => 'خاڵی پێویستت نییە بۆ ئەم گۆڕینەوەیە',
            'points.min' => 'کەمترین بڕی خاڵ بۆ گۆڕینەوە ٢٠٠ خاڵە',
        ]);

        $pointsToRedeem = (int) $request->points;
        $pointValueIqd = AppSetting::get('loyalty_point_iqd_value', 10);
        $discountAmount = $pointsToRedeem * $pointValueIqd;

        // Deduct points
        $user->loyalty_points -= $pointsToRedeem;
        $user->save();

        // Generate unique coupon code for user
        $couponCode = 'LOYAL-' . strtoupper(Str::random(6));

        $coupon = Coupon::create([
            'code' => $couponCode,
            'title' => 'داشکاندنی خاڵەکانی دڵسۆزی (' . number_format($discountAmount) . ' د.ع)',
            'description' => 'بە سەرکەوتوویی لە خاڵەکانتەوە گۆڕدرا بە داشکاندن',
            'discount_type' => 'fixed',
            'discount_value' => $discountAmount,
            'min_order_amount' => $discountAmount,
            'usage_limit' => 1,
            'used_count' => 0,
            'expires_at' => now()->addDays(30),
            'is_active' => true,
        ]);

        // Record transaction
        LoyaltyTransaction::create([
            'user_id' => $user->id,
            'points' => -$pointsToRedeem,
            'type' => 'redeemed_coupon',
            'description' => 'گۆڕینەوەی ' . $pointsToRedeem . ' خاڵ بۆ کۆدی ' . $couponCode,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'خاڵەکانت بە سەرکەوتوویی کران بە کۆدی داشکاندن!',
            'data' => [
                'coupon_code' => $couponCode,
                'discount_amount' => $discountAmount,
                'remaining_points' => $user->loyalty_points,
                'expires_at' => $coupon->expires_at->toDateString(),
            ]
        ]);
    }
}
