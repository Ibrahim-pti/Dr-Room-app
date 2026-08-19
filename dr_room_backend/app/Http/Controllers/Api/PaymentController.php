<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\Order;
use App\Models\Appointment;
use Illuminate\Support\Str;

class PaymentController extends Controller
{
    /**
     * Create payment intent
     */
    public function createIntent(Request $request)
    {
        $request->validate([
            'amount' => 'required|numeric',
            'currency' => 'nullable|string',
            'description' => 'nullable|string',
        ]);

        $id = 'pi_' . Str::random(20);
        $clientSecret = 'seti_' . Str::random(24);

        return response()->json([
            'id' => $id,
            'clientSecret' => $clientSecret,
            'amount' => (float)$request->amount,
            'currency' => $request->currency ?? 'IQD',
            'status' => 'requires_payment_method',
            'created' => now()->toIso8601String(),
        ], 201);
    }

    /**
     * Confirm payment
     */
    public function confirm(Request $request)
    {
        $request->validate([
            'paymentIntentId' => 'required|string',
            'paymentMethodId' => 'nullable|string',
        ]);

        $user = Auth::user();
        $id = 'txn_' . Str::random(16);

        $transaction = [
            'id' => $id,
            'amount' => $request->amount ?? 25000,
            'currency' => 'IQD',
            'status' => 'completed',
            'description' => 'Medical Service Payment',
            'date' => now()->toIso8601String(),
            'paymentMethod' => [
                'id' => $request->paymentMethodId ?? 'pm_cash',
                'type' => 'card',
                'last4' => '4242',
                'brand' => 'visa',
            ],
            'receiptUrl' => url('/api/payments/receipt/' . $id),
        ];

        return response()->json($transaction);
    }

    /**
     * Get transaction history (Orders + Appointments)
     */
    public function history(Request $request)
    {
        $user = Auth::user();
        $orders = Order::where('patient_id', $user ? $user->id : 1)
            ->orderBy('created_at', 'desc')
            ->get();

        $transactions = $orders->map(function($order) {
            return [
                'id' => 'txn_ord_' . $order->id,
                'amount' => (float)$order->total_price,
                'currency' => 'IQD',
                'status' => $order->status === 'cancelled' ? 'failed' : 'completed',
                'description' => ucfirst($order->service_type) . ' Order #' . $order->id,
                'date' => $order->created_at ? $order->created_at->toIso8601String() : now()->toIso8601String(),
                'paymentMethod' => [
                    'id' => 'pm_' . $order->payment_method,
                    'type' => $order->payment_method,
                    'last4' => 'COD',
                    'brand' => $order->payment_method,
                ],
                'receiptUrl' => url('/api/payments/receipt/txn_ord_' . $order->id),
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $transactions
        ]);
    }

    /**
     * Get single transaction
     */
    public function show($id)
    {
        return response()->json([
            'id' => $id,
            'amount' => 25000.0,
            'currency' => 'IQD',
            'status' => 'completed',
            'description' => 'Medical Service',
            'date' => now()->toIso8601String(),
            'paymentMethod' => [
                'id' => 'pm_card',
                'type' => 'card',
                'last4' => '4242',
                'brand' => 'visa',
            ],
            'receiptUrl' => url('/api/payments/receipt/' . $id),
        ]);
    }

    /**
     * Get saved payment methods
     */
    public function methods(Request $request)
    {
        return response()->json([
            'success' => true,
            'data' => [
                [
                    'id' => 'pm_cash',
                    'type' => 'cash',
                    'title' => 'Cash on Delivery',
                    'isDefault' => true,
                ],
                [
                    'id' => 'pm_fib',
                    'type' => 'fib',
                    'title' => 'First Iraqi Bank (FIB)',
                    'isDefault' => false,
                ],
                [
                    'id' => 'pm_fastpay',
                    'type' => 'fastpay',
                    'title' => 'FastPay',
                    'isDefault' => false,
                ],
                [
                    'id' => 'pm_zaincash',
                    'type' => 'zaincash',
                    'title' => 'ZainCash',
                    'isDefault' => false,
                ],
            ]
        ]);
    }

    /**
     * Store payment method
     */
    public function storeMethod(Request $request)
    {
        return response()->json([
            'success' => true,
            'message' => 'Payment method saved successfully',
            'data' => [
                'id' => 'pm_' . Str::random(10),
                'type' => $request->type ?? 'card',
                'title' => $request->title ?? 'New Payment Method',
            ]
        ], 201);
    }

    /**
     * Delete payment method
     */
    public function deleteMethod($id)
    {
        return response()->json([
            'success' => true,
            'message' => 'Payment method deleted successfully'
        ]);
    }

    /**
     * Get payment receipt
     */
    public function receipt($id)
    {
        return response()->json([
            'receiptId' => $id,
            'date' => now()->toIso8601String(),
            'status' => 'Paid',
            'issuedTo' => Auth::user() ? Auth::user()->name : 'Patient',
        ]);
    }
}
