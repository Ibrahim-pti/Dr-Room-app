<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use App\Models\LoyaltyTransaction;
use App\Models\User;
use Illuminate\Http\Request;

class AdminLoyaltyController extends Controller
{
    public function stats()
    {
        $totalIssued = LoyaltyTransaction::where('points', '>', 0)->sum('points');
        $totalRedeemed = abs(LoyaltyTransaction::where('points', '<', 0)->sum('points'));
        $activeInCirculation = User::sum('loyalty_points');

        $topUsers = User::where('loyalty_points', '>', 0)
            ->orderBy('loyalty_points', 'desc')
            ->take(10)
            ->get(['id', 'name', 'phone', 'loyalty_points', 'profile_image']);

        $settings = [
            'point_iqd_value' => AppSetting::get('loyalty_point_iqd_value', 10),
            'points_per_1000_iqd' => AppSetting::get('loyalty_points_per_1000_iqd', 1),
            'is_enabled' => AppSetting::get('loyalty_enabled', true),
        ];

        return response()->json([
            'success' => true,
            'data' => [
                'total_issued' => (int) $totalIssued,
                'total_redeemed' => (int) $totalRedeemed,
                'active_in_circulation' => (int) $activeInCirculation,
                'top_users' => $topUsers,
                'settings' => $settings,
            ]
        ]);
    }

    public function updateSettings(Request $request)
    {
        $validated = $request->validate([
            'point_iqd_value' => 'required|numeric|min:1',
            'points_per_1000_iqd' => 'required|numeric|min:0.1',
            'is_enabled' => 'nullable|boolean',
        ]);

        AppSetting::set('loyalty_point_iqd_value', $validated['point_iqd_value'], 'loyalty');
        AppSetting::set('loyalty_points_per_1000_iqd', $validated['points_per_1000_iqd'], 'loyalty');
        if (isset($validated['is_enabled'])) {
            AppSetting::set('loyalty_enabled', $validated['is_enabled'], 'loyalty');
        }

        return response()->json([
            'success' => true,
            'message' => 'ڕێکخستنەکانی سیستەمی دڵسۆزی نوێکرانەوە',
            'data' => $validated,
        ]);
    }
}
