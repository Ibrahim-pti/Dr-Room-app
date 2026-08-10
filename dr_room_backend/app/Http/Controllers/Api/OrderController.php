<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Order;
use App\Models\OrderItem;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class OrderController extends Controller
{
    public function index(Request $request)
    {
        $orders = Order::where('patient_id', Auth::id())
            ->with(['items', 'assignedNurse'])
            ->orderBy('created_at', 'desc')
            ->get();
            
        return response()->json([
            'data' => $orders
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'service_type' => 'required|string',
            'subtotal' => 'required|numeric',
            'extra_fee' => 'required|numeric',
            'total_price' => 'required|numeric',
            'payment_method' => 'required|string',
            'items' => 'required|array',
            'items.*.name' => 'required|string',
            'items.*.price' => 'required|numeric',
            'items.*.quantity' => 'required|integer|min:1',
        ]);

        try {
            DB::beginTransaction();

            $order = Order::create([
                'patient_id' => Auth::id() ?? 1, // Fallback if auth is incomplete in flutter app for now
                'service_type' => $request->service_type,
                'subtotal' => $request->subtotal,
                'extra_fee' => $request->extra_fee,
                'total_price' => $request->total_price,
                'status' => 'pending',
                'payment_method' => $request->payment_method,
                'patient_details' => $request->patient_details ?? [],
                'location_details' => $request->location_details ?? [],
            ]);

            foreach ($request->items as $item) {
                OrderItem::create([
                    'order_id' => $order->id,
                    'item_id' => $item['id'] ?? null,
                    'item_name' => $item['name'],
                    'price' => $item['price'],
                    'quantity' => $item['quantity'] ?? 1,
                    'extra_data' => $item['extra_data'] ?? [],
                ]);
            }

            DB::commit();

            return response()->json([
                'message' => 'Order created successfully',
                'order' => $order->load('items')
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Failed to create order: ' . $e->getMessage()], 500);
        }
    }
}
