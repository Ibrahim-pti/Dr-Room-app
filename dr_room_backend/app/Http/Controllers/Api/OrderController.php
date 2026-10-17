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
            $assignedLabId = $request->assigned_lab_id ?? $request->lab_id;

            $prescriptionImage = $request->prescription_url ?? $request->prescription_image ?? null;

            // Auto detect assigned pharmacy, nurse, or lab from item extra_data if not directly specified
            if (!empty($request->items)) {
                foreach ($request->items as $item) {
                    if (!$assignedPharmacyId && !empty($item['extra_data']['pharmacy_id'])) {
                        $assignedPharmacyId = $item['extra_data']['pharmacy_id'];
                    }
                    if (!$assignedNurseId && !empty($item['extra_data']['nurse_id'])) {
                        $assignedNurseId = $item['extra_data']['nurse_id'];
                    }
                    if (!$assignedLabId && !empty($item['extra_data']['lab_id'])) {
                        $assignedLabId = $item['extra_data']['lab_id'];
                    }
                    if (!$prescriptionImage && !empty($item['extra_data']['prescription_url'])) {
                        $prescriptionImage = $item['extra_data']['prescription_url'];
                    }
                    if (!$prescriptionImage && !empty($item['extra_data']['prescription_image'])) {
                        $prescriptionImage = $item['extra_data']['prescription_image'];
                    }
                    if (!$prescriptionImage && !empty($item['extra_data']['prescription_path'])) {
                        $prescriptionImage = $item['extra_data']['prescription_path'];
                    }
                }
            }

            if (!$assignedNurseId && !empty($request->patient_details['nurse_id'])) {
                $assignedNurseId = $request->patient_details['nurse_id'];
            }
            if (!$assignedNurseId && !empty($request->patient_details['staff_id'])) {
                $assignedNurseId = $request->patient_details['staff_id'];
            }
            if (!$assignedLabId && !empty($request->patient_details['lab_id'])) {
                $assignedLabId = $request->patient_details['lab_id'];
            }

            // If it's a lab service and assignedLabId corresponds to a Lab model ID instead of User ID, resolve user_id
            if ($assignedLabId) {
                $labRecord = \App\Models\Lab::find($assignedLabId);
                if ($labRecord && $labRecord->user_id) {
                    $assignedLabId = $labRecord->user_id;
                }
            }

            // The app sends the Nurse model ID (from /nurses or /labs/staff), but
            // orders.assigned_nurse_id references users.id — resolve it here.
            if ($assignedNurseId) {
                $nurseRecord = \App\Models\Nurse::find($assignedNurseId);
                if ($nurseRecord && $nurseRecord->user_id) {
                    $assignedNurseId = $nurseRecord->user_id;
                }
            }

            $patientDetails = $request->patient_details ?? [];
            if ($prescriptionImage) {
                $patientDetails['prescription_image'] = $prescriptionImage;
                $patientDetails['prescription_url'] = $prescriptionImage;
                $patientDetails['is_prescription'] = true;
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
                'assigned_lab_id' => $assignedLabId,
                'patient_details' => $patientDetails,
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

            // Normalize payment method
            $rawMethod = strtolower($request->payment_method ?? 'cash');
            $normMethod = 'cash';
            if (str_contains($rawMethod, 'fib')) {
                $normMethod = 'fib';
            } elseif (str_contains($rawMethod, 'fastpay')) {
                $normMethod = 'fastpay';
            } elseif (str_contains($rawMethod, 'zain')) {
                $normMethod = 'zaincash';
            } elseif (str_contains($rawMethod, 'qi')) {
                $normMethod = 'qi_card';
            } elseif (str_contains($rawMethod, 'card')) {
                $normMethod = 'card';
            } elseif (str_contains($rawMethod, 'wallet')) {
                $normMethod = 'wallet';
            }

            $isOnline = $request->filled('transaction_reference') || ($normMethod !== 'cash');
            $txStatus = $isOnline ? 'completed' : ($order->status === 'completed' ? 'completed' : 'pending');
            $txRef = $request->transaction_reference 
                ?? (($normMethod === 'cash' ? 'CSH-' : 'ONL-') . date('Ymd') . '-' . strtoupper(\Illuminate\Support\Str::random(5)) . '-' . $order->id);

            \App\Models\Transaction::create([
                'reference'    => $txRef,
                'user_id'      => Auth::id(),
                'amount'       => (float)$order->total_price,
                'currency'     => 'IQD',
                'status'       => $txStatus,
                'method'       => $normMethod,
                'description'  => ucfirst($order->service_type ?? 'Medical') . ' Order #' . $order->id . ' (' . ($normMethod === 'cash' ? 'کاش' : \App\Models\Transaction::METHOD_LABELS[$normMethod] ?? $normMethod) . ')',
                'payable_type' => \App\Models\Order::class,
                'payable_id'   => $order->id,
                'paid_at'      => $txStatus === 'completed' ? now() : null,
                'meta'         => [
                    'gateway'          => $request->payment_method ?? $normMethod,
                    'rasedi_reference' => $request->transaction_reference,
                    'is_online'        => $isOnline,
                ],
            ]);

            DB::commit();

            return response()->json([
                'message' => 'Order created successfully',
                'order' => $order->load(['items', 'assignedNurse', 'assignedPharmacy', 'assignedLab'])
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Failed to create order: ' . $e->getMessage()], 500);
        }
    }

    /**
     * Upload prescription file (camera / gallery photo)
     */
    public function uploadPrescription(Request $request)
    {
        $request->validate([
            'image' => 'required|file|mimes:jpeg,png,jpg,webp,pdf|max:20480',
        ]);

        if ($request->hasFile('image')) {
            $file = $request->file('image');
            $filename = 'prescription_' . time() . '_' . uniqid() . '.' . $file->getClientOriginalExtension();
            $path = $file->storeAs('prescriptions', $filename, 'public');

            return response()->json([
                'success' => true,
                'path' => 'storage/' . $path,
                'url' => asset('storage/' . $path),
            ]);
        }

        return response()->json(['success' => false, 'message' => 'No image uploaded'], 400);
    }
}
