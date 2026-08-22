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
        $orders = Order::with(['items', 'patient', 'assignedNurse', 'assignedPharmacy', 'assignedLab'])
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
     * Update order status generally (e.g. pending, processing, completed, cancelled)
     */
    public function updateStatus(Request $request, $id)
    {
        $request->validate([
            'status' => 'required|string|in:pending,processing,completed,cancelled',
        ]);

        $order = Order::findOrFail($id);
        $order->status = $request->status;
        $order->save();

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
