<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use App\Models\Driver;
use App\Models\Order;
use App\Models\User;
use App\Services\FcmService;
use App\Services\OrderNotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class DriverController extends Controller
{
    public function dashboard(Request $request)
    {
        $user = $request->user() ?: Auth::user();
        $driver = Driver::firstOrCreate(['user_id' => $user->id]);

        $withRelations = ['items', 'patient', 'assignedPharmacy.pharmacy', 'assignedLab.lab', 'assignedNurse.nurse'];

        $activeOrders = Order::where('assigned_driver_id', $user->id)
            ->whereNotIn('status', ['completed', 'cancelled'])
            ->with($withRelations)
            ->orderByDesc('driver_assigned_at')
            ->orderByDesc('id')
            ->get()
            ->map(fn ($o) => $this->formatDriverOrder($o))
            ->values();

        $completedOrders = Order::where('assigned_driver_id', $user->id)
            ->where('status', 'completed')
            ->with($withRelations)
            ->orderByDesc('driver_delivered_at')
            ->orderByDesc('id')
            ->take(25)
            ->get()
            ->map(fn ($o) => $this->formatDriverOrder($o))
            ->values();

        // Available delivery pool (unassigned pharmacy/lab orders ready for pickup/delivery)
        $poolQuery = Order::whereNull('assigned_driver_id')
            ->whereIn('status', ['pending', 'processing', 'accepted'])
            ->with($withRelations)
            ->orderByDesc('id');

        if ($driver->service_scope === 'pharmacy') {
            $poolQuery->where('service_type', 'like', '%pharmac%');
        } elseif ($driver->service_scope === 'lab_sample') {
            $poolQuery->where('service_type', 'like', '%lab%');
        } else {
            $poolQuery->where(function ($q) {
                $q->where('service_type', 'like', '%pharmac%')
                  ->orWhere('service_type', 'like', '%lab%')
                  ->orWhere('service_type', 'like', '%medic%');
            });
        }

        $availableOrders = $poolQuery->take(25)->get()
            ->map(fn ($o) => $this->formatDriverOrder($o))
            ->values();

        $todayDelivered = Order::where('assigned_driver_id', $user->id)
            ->where('status', 'completed')
            ->whereDate('driver_delivered_at', today())
            ->count();

        $monthDelivered = Order::where('assigned_driver_id', $user->id)
            ->where('status', 'completed')
            ->whereMonth('driver_delivered_at', now()->month)
            ->whereYear('driver_delivered_at', now()->year)
            ->count();

        $todayEarnings = (float) Order::where('assigned_driver_id', $user->id)
            ->where('status', 'completed')
            ->whereDate('driver_delivered_at', today())
            ->sum('delivery_fee');

        return response()->json([
            'data' => [
                'driver' => [
                    'id' => $driver->id,
                    'user_id' => $user->id,
                    'name' => $user->name,
                    'phone' => $user->phone,
                    'avatar_url' => $user->avatar_url,
                    'city' => $driver->city,
                    'vehicle_type' => $driver->vehicle_type,
                    'plate_number' => $driver->plate_number,
                    'service_scope' => $driver->service_scope,
                    'duty_status' => $driver->duty_status,
                    'current_lat' => $driver->current_lat,
                    'current_lng' => $driver->current_lng,
                    'last_location_at' => $driver->last_location_at?->toIso8601String(),
                    'rating' => (float) $driver->rating,
                    'completed_deliveries' => (int) $driver->completed_deliveries,
                    'total_earnings' => (float) $driver->total_earnings,
                ],
                'stats' => [
                    'active_count' => $activeOrders->count(),
                    'available_count' => $availableOrders->count(),
                    'today_deliveries' => $todayDelivered,
                    'month_deliveries' => $monthDelivered,
                    'today_earnings' => $todayEarnings,
                    'total_deliveries' => (int) $driver->completed_deliveries,
                    'total_earnings' => (float) $driver->total_earnings,
                ],
                'active_orders' => $activeOrders,
                'available_orders' => $availableOrders,
                'completed_orders' => $completedOrders,
            ],
        ]);
    }

    public function updateDuty(Request $request)
    {
        $request->validate([
            'duty_status' => 'required|in:available,offline',
        ]);

        $user = $request->user();
        $driver = Driver::firstOrCreate(['user_id' => $user->id]);

        if ($request->duty_status === 'offline') {
            $activeCount = Order::where('assigned_driver_id', $user->id)
                ->whereNotIn('status', ['completed', 'cancelled'])
                ->count();

            if ($activeCount > 0) {
                return response()->json([
                    'message' => 'تکایە سەرەتا گەیاندنە چالاکەکان تەواو بکە پێش ئەوەی ئۆفلاین بیت.',
                ], 422);
            }
        }

        $driver->duty_status = $request->duty_status;
        $driver->save();

        return response()->json([
            'message' => $driver->duty_status === 'available'
                ? 'ئێستا ئامادەیت بۆ وەرگرتنی داواکاری'
                : 'دۆخەکەت گۆڕدرا بۆ ئۆفلاین',
            'duty_status' => $driver->duty_status,
        ]);
    }

    public function updateLocation(Request $request)
    {
        $request->validate([
            'lat' => 'required|numeric|between:-90,90',
            'lng' => 'required|numeric|between:-180,180',
        ]);

        $user = $request->user();
        $driver = Driver::firstOrCreate(['user_id' => $user->id]);

        $driver->update([
            'current_lat' => (float) $request->lat,
            'current_lng' => (float) $request->lng,
            'last_location_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'last_location_at' => $driver->last_location_at?->toIso8601String(),
        ]);
    }

    public function claimOrder(Request $request, $id)
    {
        $user = $request->user();
        $driver = Driver::firstOrCreate(['user_id' => $user->id]);

        $claimed = DB::transaction(function () use ($id, $user, $driver) {
            $order = Order::where('id', $id)->lockForUpdate()->firstOrFail();

            if ($order->assigned_driver_id !== null && (int) $order->assigned_driver_id !== (int) $user->id) {
                return null;
            }
            if (in_array($order->status, ['completed', 'cancelled'], true)) {
                return false;
            }

            $order->assigned_driver_id = $user->id;
            $order->delivery_status = 'accepted';
            $order->driver_assigned_at = $order->driver_assigned_at ?? now();
            if ($order->delivery_fee <= 0) {
                $order->delivery_fee = (float) ($order->extra_fee > 0 ? $order->extra_fee : 2500);
            }
            if ($order->status === 'pending') {
                $order->status = 'processing';
            }
            $order->save();

            $driver->update(['duty_status' => 'busy']);

            return $order;
        });

        if ($claimed === null) {
            return response()->json(['message' => 'ئەم داواکارییە پێشتر لەلایەن شۆفێرێکی ترەوە وەرگیراوە.'], 409);
        }
        if ($claimed === false) {
            return response()->json(['message' => 'ئەم داواکارییە چیتر بەردەست نییە.'], 422);
        }

        OrderNotificationService::notifyDeliveryStage($claimed, 'accepted');

        return response()->json([
            'message' => 'داواکارییەکە بە سەرکەوتوویی وەرگیرا',
            'order' => $this->formatDriverOrder($claimed->fresh(['items', 'patient', 'assignedPharmacy.pharmacy', 'assignedLab.lab', 'assignedNurse.nurse'])),
        ]);
    }

    public function updateOrderStatus(Request $request, $id)
    {
        $request->validate([
            'delivery_status' => 'required|in:accepted,picked_up,on_the_way,arrived,delivered,rejected',
            'notes' => 'nullable|string|max:500',
        ]);

        $user = $request->user();
        $driver = Driver::firstOrCreate(['user_id' => $user->id]);
        $order = Order::where('id', $id)->where('assigned_driver_id', $user->id)->firstOrFail();

        if (in_array($order->status, ['completed', 'cancelled'], true)) {
            return response()->json(['message' => 'ئەم داواکارییە پێشتر داخراوە.'], 422);
        }

        $next = $request->delivery_status;

        if ($next === 'rejected') {
            if (in_array($order->delivery_status, ['picked_up', 'on_the_way', 'arrived', 'delivered'], true)) {
                return response()->json(['message' => 'ناتوانرێت داواکارییەک ڕەتبکرێتەوە دوای وەرگرتنی.'], 422);
            }

            $order->assigned_driver_id = null;
            $order->delivery_status = 'unassigned';
            $order->driver_assigned_at = null;
            $order->driver_notes = $request->notes;
            $order->save();

            $remainingActive = Order::where('assigned_driver_id', $user->id)
                ->whereNotIn('status', ['completed', 'cancelled'])
                ->count();
            $driver->update(['duty_status' => $remainingActive > 0 ? 'busy' : 'available']);

            return response()->json(['message' => 'داواکارییەکە گەڕێندرایەوە بۆ لیستەکە']);
        }

        DB::transaction(function () use ($order, $driver, $user, $next, $request) {
            $order->delivery_status = $next;
            if ($request->filled('notes')) {
                $order->driver_notes = $request->notes;
            }

            if ($next === 'accepted') {
                $order->driver_assigned_at = $order->driver_assigned_at ?? now();
                if ($order->status === 'pending') {
                    $order->status = 'processing';
                }
            } elseif ($next === 'picked_up') {
                $order->driver_picked_up_at = $order->driver_picked_up_at ?? now();
                $order->status = 'processing';
            } elseif (in_array($next, ['on_the_way', 'arrived'], true)) {
                $order->status = 'processing';
            } elseif ($next === 'delivered') {
                $order->driver_delivered_at = now();
                $order->status = 'completed';
                $order->payment_status = 'paid';

                $fee = $order->delivery_fee > 0
                    ? (float) $order->delivery_fee
                    : ((float) $order->extra_fee > 0 ? (float) $order->extra_fee : 2500.0);
                $order->delivery_fee = $fee;

                \App\Models\Transaction::where('payable_type', Order::class)
                    ->where('payable_id', $order->id)
                    ->where('status', 'pending')
                    ->update([
                        'status' => 'completed',
                        'paid_at' => now(),
                    ]);

                // Award loyalty points to patient if enabled and not yet awarded
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

                $driver->increment('completed_deliveries');
                $driver->increment('total_earnings', $fee);
            }

            $order->save();

            $remainingActive = Order::where('assigned_driver_id', $user->id)
                ->whereNotIn('status', ['completed', 'cancelled'])
                ->count();
            $driver->update(['duty_status' => $remainingActive > 0 ? 'busy' : 'available']);
        });

        OrderNotificationService::notifyDeliveryStage($order->fresh(), $next);

        return response()->json([
            'message' => 'دۆخی گەیاندن نوێکرایەوە',
            'order' => $this->formatDriverOrder($order->fresh(['items', 'patient', 'assignedPharmacy.pharmacy', 'assignedLab.lab', 'assignedNurse.nurse'])),
        ]);
    }

    private function formatDriverOrder(Order $order): array
    {
        $patientDetails = is_array($order->patient_details)
            ? $order->patient_details
            : (json_decode((string) $order->patient_details, true) ?: []);
        $locationDetails = is_array($order->location_details)
            ? $order->location_details
            : (json_decode((string) $order->location_details, true) ?: []);

        $serviceType = strtolower((string) $order->service_type);
        $isLab = str_contains($serviceType, 'lab');

        $pickupName = '';
        $pickupPhone = '';
        $pickupAddress = '';
        $pickupLat = null;
        $pickupLng = null;

        if ($isLab && $order->assignedLab) {
            $u = $order->assignedLab;
            $l = $u->lab;
            $pickupName = $u->name ?? 'تاقیگە';
            $pickupPhone = $u->phone ?? ($l->phone ?? '');
            $pickupAddress = $l->location ?? '';
            $pickupLat = $l && $l->latitude !== null ? (float) $l->latitude : null;
            $pickupLng = $l && $l->longitude !== null ? (float) $l->longitude : null;
        } elseif ($order->assignedPharmacy) {
            $u = $order->assignedPharmacy;
            $p = $u->pharmacy;
            $pickupName = $u->name ?? 'دەرمانخانە';
            $pickupPhone = $u->phone ?? ($p->phone ?? '');
            $pickupAddress = $p->location ?? '';
            $pickupLat = $p && $p->latitude !== null ? (float) $p->latitude : null;
            $pickupLng = $p && $p->longitude !== null ? (float) $p->longitude : null;
        } else {
            // Fallback from item extra_data if order not yet accepted by specific provider user
            foreach ($order->items ?? [] as $item) {
                $ex = is_array($item->extra_data) ? $item->extra_data : (json_decode((string) $item->extra_data, true) ?: []);
                if (!empty($ex['pharmacy_name'])) { $pickupName = $ex['pharmacy_name']; break; }
                if (!empty($ex['lab_name'])) { $pickupName = $ex['lab_name']; break; }
            }
            if ($pickupName === '') {
                $pickupName = $isLab ? 'تاقیگەی پزیشکی' : 'دەرمانخانە';
            }
        }

        $patientLat = $locationDetails['latitude'] ?? $locationDetails['lat'] ?? null;
        $patientLng = $locationDetails['longitude'] ?? $locationDetails['lng'] ?? null;

        return [
            'id' => $order->id,
            'order_number' => '#' . $order->id,
            'service_type' => $order->service_type,
            'is_lab' => $isLab,
            'status' => $order->status,
            'delivery_status' => $order->delivery_status ?? 'unassigned',
            'total_price' => (float) $order->total_price,
            'delivery_fee' => (float) ($order->delivery_fee > 0 ? $order->delivery_fee : ($order->extra_fee > 0 ? $order->extra_fee : 2500)),
            'payment_method' => $order->payment_method,
            'payment_status' => $order->payment_status ?? 'pending',
            'driver_assigned_at' => $order->driver_assigned_at?->toIso8601String(),
            'driver_picked_up_at' => $order->driver_picked_up_at?->toIso8601String(),
            'driver_delivered_at' => $order->driver_delivered_at?->toIso8601String(),
            'created_at' => $order->created_at?->toIso8601String(),
            'pickup' => [
                'name' => $pickupName,
                'phone' => $pickupPhone,
                'address' => $pickupAddress,
                'lat' => $pickupLat,
                'lng' => $pickupLng,
            ],
            'patient' => [
                'name' => $patientDetails['name'] ?? ($order->patient?->name ?? 'نەخۆش'),
                'phone' => $patientDetails['phone'] ?? ($order->patient?->phone ?? ''),
                'address' => $locationDetails['address'] ?? ($locationDetails['full_address'] ?? ($locationDetails['city'] ?? '')),
                'lat' => $patientLat !== null ? (float) $patientLat : null,
                'lng' => $patientLng !== null ? (float) $patientLng : null,
                'notes' => $patientDetails['notes'] ?? ($patientDetails['note'] ?? ''),
            ],
            'items' => collect($order->items ?? [])->map(fn ($it) => [
                'name' => $it->item_name ?? $it->name ?? 'خزمەتگوزاری',
                'quantity' => (int) ($it->quantity ?? 1),
                'price' => (float) ($it->price ?? 0),
            ])->values(),
        ];
    }
}
