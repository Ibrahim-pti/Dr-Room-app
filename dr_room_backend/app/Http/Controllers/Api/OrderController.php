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
            ->with(['items', 'assignedNurse', 'assignedPharmacy'])
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

            $assignedPharmacyId = $request->assigned_pharmacy_id ?? $request->pharmacy_id;
            $assignedNurseId = $request->assigned_nurse_id ?? $request->nurse_id;

            // Auto detect assigned pharmacy or nurse from item extra_data if not directly specified
            if (!$assignedPharmacyId && !empty($request->items)) {
                foreach ($request->items as $item) {
                    if (!empty($item['extra_data']['pharmacy_id'])) {
                        $assignedPharmacyId = $item['extra_data']['pharmacy_id'];
                        break;
                    }
                }
            }

            if (!$assignedNurseId && !empty($request->items)) {
                foreach ($request->items as $item) {
                    if (!empty($item['extra_data']['nurse_id'])) {
                        $assignedNurseId = $item['extra_data']['nurse_id'];
                        break;
                    }
                }
            }

            $order = Order::create([
                'patient_id' => Auth::id(),
                'service_type' => $request->service_type,
                'subtotal' => $request->subtotal,
                'extra_fee' => $request->extra_fee,
                'total_price' => $request->total_price,
                'status' => 'pending',
                'payment_method' => $request->payment_method,
                'assigned_pharmacy_id' => $assignedPharmacyId,
                'assigned_nurse_id' => $assignedNurseId,
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
                'order' => $order->load(['items', 'assignedNurse', 'assignedPharmacy'])
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Failed to create order: ' . $e->getMessage()], 500);
        }
    }
}
