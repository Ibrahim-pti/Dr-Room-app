<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Order;
use App\Models\User;

class AdminOrderController extends Controller
{
    /**
     * Display a listing of all orders for Admin.
     */
    public function index()
    {
        $orders = Order::with(['items', 'patient'])->orderBy('created_at', 'desc')->get();
        return response()->json([
            'orders' => $orders
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

        return response()->json([
            'message' => 'Nurse assigned successfully',
            'order' => $order
        ]);
    }

    /**
     * Update order status generally (e.g. completed, cancelled)
     */
    public function updateStatus(Request $request, $id)
    {
        $request->validate([
            'status' => 'required|string|in:pending,processing,completed,cancelled',
        ]);

        $order = Order::findOrFail($id);
        $order->status = $request->status;
        $order->save();

        return response()->json([
            'message' => 'Order status updated successfully',
            'order' => $order
        ]);
    }
}
