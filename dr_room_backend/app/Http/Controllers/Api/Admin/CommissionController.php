<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use App\Models\Order;
use Illuminate\Http\Request;

class CommissionController extends Controller
{
    public function settings()
    {
        $settings = [
            'nursing_rate' => AppSetting::get('commission_nursing_rate', 10),
            'lab_rate' => AppSetting::get('commission_lab_rate', 15),
            'pharmacy_rate' => AppSetting::get('commission_pharmacy_rate', 5),
            'doctor_rate' => AppSetting::get('commission_doctor_rate', 10),
            'auto_deduct' => AppSetting::get('commission_auto_deduct', true),
        ];

        return response()->json([
            'success' => true,
            'data' => $settings,
        ]);
    }

    public function updateSettings(Request $request)
    {
        $validated = $request->validate([
            'nursing_rate' => 'required|numeric|min:0|max:100',
            'lab_rate' => 'required|numeric|min:0|max:100',
            'pharmacy_rate' => 'required|numeric|min:0|max:100',
            'doctor_rate' => 'required|numeric|min:0|max:100',
            'auto_deduct' => 'nullable|boolean',
        ]);

        AppSetting::set('commission_nursing_rate', $validated['nursing_rate'], 'commission');
        AppSetting::set('commission_lab_rate', $validated['lab_rate'], 'commission');
        AppSetting::set('commission_pharmacy_rate', $validated['pharmacy_rate'], 'commission');
        AppSetting::set('commission_doctor_rate', $validated['doctor_rate'], 'commission');
        if (isset($validated['auto_deduct'])) {
            AppSetting::set('commission_auto_deduct', $validated['auto_deduct'], 'commission');
        }

        return response()->json([
            'success' => true,
            'message' => 'ڕێژەکانی کۆمیشن بە سەرکەوتوویی نوێکرانەوە',
            'data' => $validated,
        ]);
    }

    public function summary()
    {
        $completedOrders = Order::where('status', 'completed');

        $totalRevenue = (clone $completedOrders)->sum('total_price');
        $totalCommission = (clone $completedOrders)->sum('commission_amount');
        $totalProviderPayout = (clone $completedOrders)->sum('provider_net_amount');

        // By service type breakdown
        $breakdown = Order::where('status', 'completed')
            ->selectRaw('service_type, COUNT(*) as total_orders, SUM(total_price) as total_amount, SUM(commission_amount) as total_commission, SUM(provider_net_amount) as provider_net')
            ->groupBy('service_type')
            ->get();

        return response()->json([
            'success' => true,
            'data' => [
                'total_revenue' => (float) $totalRevenue,
                'total_commission' => (float) $totalCommission,
                'total_provider_payout' => (float) $totalProviderPayout,
                'breakdown' => $breakdown,
            ]
        ]);
    }
}
