<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Order;
use App\Models\User;
use App\Services\OrderNotificationService;

class AdminOrderController extends Controller
{
    /**
     * Display a listing of all orders for Admin.
     */
    public function index()
    {
        $orders = Order::with(['items', 'patient', 'assignedNurse.nurse', 'assignedPharmacy.pharmacy', 'assignedLab.lab', 'assignedDriver.driver'])
            ->orderBy('created_at', 'desc')
            ->get();
            
        return response()->json([
            'success' => true,
            'orders' => $orders,
            'data' => $orders
        ]);
    }

    /**
     * Assign a nurse to an order and update its status.
     */
    public function assignNurse(Request $request, $id)
    {
        $request->validate([
            'nurse_id' => 'required|exists:users,id',
        ]);

        $order = Order::findOrFail($id);

        // Make sure the user is actually a nurse
        $nurse = User::where('id', $request->nurse_id)->where('role', 'nurse')->first();
        if (!$nurse) {
            return response()->json(['message' => 'The selected user is not a valid nurse.'], 400);
        }

        $order->assigned_nurse_id = $nurse->id;
        $order->status = 'processing';
        $order->save();

        OrderNotificationService::notifyStatusChanged($order, 'processing');

        return response()->json([
            'message' => 'Nurse assigned successfully',
            'order' => $order->load(['items', 'patient', 'assignedNurse'])
        ]);
    }

    /**
     * Assign a pharmacy to an order.
     */
    public function assignPharmacy(Request $request, $id)
    {
        $request->validate([
            'pharmacy_id' => 'required|exists:users,id',
        ]);

        $order = Order::findOrFail($id);
        $pharmacy = User::where('id', $request->pharmacy_id)->where('role', 'pharmacy')->first();
        if (!$pharmacy) {
            return response()->json(['message' => 'The selected user is not a valid pharmacy.'], 400);
        }

        $order->assigned_pharmacy_id = $pharmacy->id;
        $order->status = 'processing';
        $order->save();

        OrderNotificationService::notifyStatusChanged($order, 'processing');

        return response()->json([
            'message' => 'Pharmacy assigned successfully',
            'order' => $order->load(['items', 'patient', 'assignedNurse'])
        ]);
    }

    /**
     * Assign a delivery driver to an order (pharmacy delivery or lab sample transport).
     */
    public function assignDriver(Request $request, $id)
    {
        $request->validate([
            'driver_id' => 'required|exists:users,id',
            'delivery_fee' => 'nullable|numeric|min:0',
        ]);

        $order = Order::findOrFail($id);
        $driverUser = User::where('id', $request->driver_id)
            ->where('role', 'driver')
            ->where('status', 'approved')
            ->with('driver')
            ->first();

        if (!$driverUser) {
            return response()->json(['message' => 'شۆفێری دیاریکراو پەسەندکراو نییە یان نەدۆزرایەوە.'], 400);
        }

        $previousDriverId = $order->assigned_driver_id;

        $order->assigned_driver_id = $driverUser->id;
        $order->delivery_status = 'assigned';
        $order->driver_assigned_at = now();
        if ($request->filled('delivery_fee')) {
            $order->delivery_fee = (float) $request->delivery_fee;
        } elseif ($order->delivery_fee <= 0) {
            $order->delivery_fee = $order->resolveDeliveryFee();
        }
        if ($order->status === 'pending') {
            $order->status = 'processing';
        }
        $order->save();

        if ($driverUser->driver) {
            $driverUser->driver->update(['duty_status' => 'busy']);
        }
        if ($previousDriverId && (int) $previousDriverId !== (int) $driverUser->id) {
            \App\Models\Driver::syncDutyStatusForUser((int) $previousDriverId);
        }

        OrderNotificationService::notifyDriverAssigned($order, $driverUser);

        return response()->json([
            'message' => 'کارمەندی گەیاندن بە سەرکەوتوویی دیاریکرا',
            'order' => $order->load(['items', 'patient', 'assignedNurse.nurse', 'assignedPharmacy.pharmacy', 'assignedLab.lab', 'assignedDriver.driver']),
        ]);
    }

    /**
     * Update order status generally (e.g. pending, processing, completed, cancelled)
     */
    public function updateStatus(Request $request, $id)
    {
        $request->validate([
            'status' => 'required|string|in:pending,processing,completed,cancelled',
        ]);

        $order = Order::findOrFail($id);
        $order->status = $request->status;

        if ($request->status === 'completed') {
            $order->payment_status = 'paid';
            if ($order->assigned_driver_id && $order->delivery_status !== 'delivered') {
                $order->delivery_status = 'delivered';
                $order->driver_delivered_at = $order->driver_delivered_at ?? now();
                $fee = $order->resolveDeliveryFee();
                $order->delivery_fee = $fee;

                $drv = \App\Models\Driver::firstOrCreate(['user_id' => $order->assigned_driver_id]);
                $drv->increment('completed_deliveries');
                $drv->increment('total_earnings', $fee);
            }

            \App\Models\Transaction::where('payable_type', Order::class)
                ->where('payable_id', $order->id)
                ->where('status', 'pending')
                ->update([
                    'status' => 'completed',
                    'paid_at' => now(),
                ]);

            // Award loyalty points to patient if enabled and not already awarded
            if (($order->loyalty_points_earned ?? 0) <= 0 && $order->patient) {
                $enabled = \App\Models\AppSetting::get('loyalty_enabled', true);
                if ($enabled) {
                    $ptsPer1000 = (float) \App\Models\AppSetting::get('loyalty_points_per_1000_iqd', 1);
                    $earned = (int) floor(($order->total_price / 1000) * $ptsPer1000);
                    if ($earned > 0) {
                        $order->loyalty_points_earned = $earned;
                        $order->patient->increment('loyalty_points', $earned);
                        \App\Models\LoyaltyTransaction::create([
                            'user_id' => $order->patient_id,
                            'points' => $earned,
                            'type' => 'earned_order',
                            'description' => "پاداشتی خاڵەکان بۆ داواکاری #{$order->id}",
                            'order_id' => $order->id,
                        ]);
                    }
                }
            }
        } elseif ($request->status === 'cancelled') {
            if ($order->assigned_driver_id && $order->delivery_status !== 'delivered') {
                $order->delivery_status = 'cancelled';
            }
            \App\Models\Transaction::where('payable_type', Order::class)
                ->where('payable_id', $order->id)
                ->where('status', 'pending')
                ->update([
                    'status' => 'failed',
                ]);
        }

        $order->save();

        if ($order->assigned_driver_id && in_array($request->status, ['completed', 'cancelled'], true)) {
            \App\Models\Driver::syncDutyStatusForUser((int) $order->assigned_driver_id);
        }

        OrderNotificationService::notifyStatusChanged($order, $request->status);

        return response()->json([
            'message' => 'Order status updated successfully',
            'order' => $order->load(['items', 'patient', 'assignedNurse'])
        ]);
    }

    /**
     * Delete an order
     */
    public function destroy($id)
    {
        $order = Order::findOrFail($id);
        $order->items()->delete();
        $order->delete();

        return response()->json(null, 204);
    }
}
