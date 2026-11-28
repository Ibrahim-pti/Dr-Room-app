<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Coupon;
use App\Models\Order;
use Illuminate\Http\Request;

class CouponController extends Controller
{
    public function index()
    {
        $coupons = Coupon::latest()->get();
        return response()->json([
            'success' => true,
            'data' => $coupons,
        ]);
    }

    public function history(Request $request)
    {
        $couponsByCode = Coupon::all()->keyBy(fn ($c) => strtoupper(trim((string) $c->code)));

        $query = Order::with(['patient:id,name,phone'])
            ->where(function ($q) {
                $q->where(function ($sub) {
                    $sub->whereNotNull('coupon_code')->where('coupon_code', '!=', '');
                })->orWhere('discount_amount', '>', 0);
            })
            ->orderByDesc('created_at');

        if ($request->filled('code')) {
            $codeFilter = strtoupper(trim((string) $request->input('code')));
            $query->whereRaw('UPPER(TRIM(coupon_code)) = ?', [$codeFilter]);
        }

        if ($request->filled('from')) {
            $query->whereDate('created_at', '>=', $request->input('from'));
        }

        if ($request->filled('to')) {
            $query->whereDate('created_at', '<=', $request->input('to'));
        }

        $orders = $query->get();

        $activeOrders = $orders->filter(
            fn (Order $o) => !in_array(strtolower((string) $o->status), ['cancelled', 'rejected'], true)
        );

        $history = $orders->map(function (Order $order) use ($couponsByCode) {
            $code = strtoupper(trim((string) ($order->coupon_code ?? '')));
            $coupon = $code !== '' ? $couponsByCode->get($code) : null;

            $patientDetails = is_array($order->patient_details) ? $order->patient_details : [];
            $patientName = $order->patient?->name
                ?? ($patientDetails['name'] ?? null)
                ?? 'نەخۆش';
            $patientPhone = $order->patient?->phone
                ?? ($patientDetails['phone'] ?? null)
                ?? '';

            return [
                'order_id' => $order->id,
                'coupon_code' => $code !== '' ? $code : null,
                'coupon_title' => $coupon?->title,
                'discount_type' => $coupon?->discount_type,
                'discount_value' => $coupon ? (float) $coupon->discount_value : null,
                'discount_amount' => (float) ($order->discount_amount ?? 0),
                'subtotal' => (float) ($order->subtotal ?? 0),
                'extra_fee' => (float) ($order->extra_fee ?? 0),
                'total_price' => (float) ($order->total_price ?? 0),
                'status' => $order->status,
                'service_type' => $order->service_type,
                'patient' => [
                    'id' => $order->patient_id,
                    'name' => $patientName,
                    'phone' => $patientPhone,
                ],
                'created_at' => $order->created_at?->toIso8601String(),
            ];
        })->values();

        $byCode = $activeOrders
            ->filter(fn (Order $o) => trim((string) ($o->coupon_code ?? '')) !== '')
            ->groupBy(fn (Order $o) => strtoupper(trim((string) $o->coupon_code)))
            ->map(function ($group, $code) use ($couponsByCode) {
                $coupon = $couponsByCode->get($code);
                $latest = $group->sortByDesc('created_at')->first();
                return [
                    'code' => $code,
                    'title' => $coupon?->title,
                    'times_used' => $group->count(),
                    'unique_users' => $group->pluck('patient_id')->filter()->unique()->count(),
                    'total_discount' => round((float) $group->sum('discount_amount'), 2),
                    'last_used_at' => $latest?->created_at?->toIso8601String(),
                    'usage_limit' => $coupon?->usage_limit,
                    'is_active' => $coupon ? (bool) $coupon->is_active : null,
                ];
            })
            ->sortByDesc('times_used')
            ->values();

        $summary = [
            'total_coupons' => $couponsByCode->count(),
            'active_coupons' => $couponsByCode->filter(fn ($c) => (bool) $c->is_active)->count(),
            'total_coupon_used_count' => (int) $couponsByCode->sum('used_count'),
            'total_usages' => $activeOrders->count(),
            'all_usages' => $orders->count(),
            'coupon_usages_count' => $activeOrders->filter(
                fn (Order $o) => trim((string) ($o->coupon_code ?? '')) !== ''
            )->count(),
            'unique_codes_used' => $byCode->count(),
            'unique_users_count' => $activeOrders->pluck('patient_id')->filter()->unique()->count(),
            'total_discount_amount' => round((float) $activeOrders->sum('discount_amount'), 2),
        ];

        return response()->json([
            'success' => true,
            'summary' => $summary,
            'by_code' => $byCode,
            'data' => $history,
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'code' => 'required|string|unique:coupons,code|max:50',
            'title' => 'nullable|string|max:255',
            'description' => 'nullable|string',
            'discount_type' => 'required|in:percentage,fixed',
            'discount_value' => 'required|numeric|min:0.01',
            'min_order_amount' => 'nullable|numeric|min:0',
            'max_discount_amount' => 'nullable|numeric|min:0',
            'usage_limit' => 'nullable|integer|min:1',
            'starts_at' => 'nullable|date',
            'expires_at' => 'nullable|date|after_or_equal:starts_at',
            'is_active' => 'boolean',
        ]);

        $validated['code'] = strtoupper(trim($validated['code']));
        $coupon = Coupon::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'کۆدی داشکاندن بە سەرکەوتوویی دروستکرا',
            'data' => $coupon,
        ], 201);
    }

    public function update(Request $request, $id)
    {
        $coupon = Coupon::findOrFail($id);

        $validated = $request->validate([
            'code' => 'required|string|max:50|unique:coupons,code,' . $coupon->id,
            'title' => 'nullable|string|max:255',
            'description' => 'nullable|string',
            'discount_type' => 'required|in:percentage,fixed',
            'discount_value' => 'required|numeric|min:0.01',
            'min_order_amount' => 'nullable|numeric|min:0',
            'max_discount_amount' => 'nullable|numeric|min:0',
            'usage_limit' => 'nullable|integer|min:1',
            'starts_at' => 'nullable|date',
            'expires_at' => 'nullable|date',
            'is_active' => 'boolean',
        ]);

        $validated['code'] = strtoupper(trim($validated['code']));
        $coupon->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'کۆدی داشکاندن نوێکرایەوە',
            'data' => $coupon,
        ]);
    }

    public function toggleStatus($id)
    {
        $coupon = Coupon::findOrFail($id);
        $coupon->is_active = !$coupon->is_active;
        $coupon->save();

        return response()->json([
            'success' => true,
            'message' => 'دۆخی کۆدەکە گۆڕدرا',
            'is_active' => $coupon->is_active,
        ]);
    }

    public function destroy($id)
    {
        $coupon = Coupon::findOrFail($id);
        $coupon->delete();

        return response()->json([
            'success' => true,
            'message' => 'کۆدی داشکاندن سڕایەوە',
        ]);
    }
}

