<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use App\Models\Driver;
use App\Models\Order;
use App\Models\User;
use App\Services\DriverDispatchService;
use App\Services\FcmService;
use App\Services\OrderNotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class DriverController extends Controller
{
    public function __construct(private readonly DriverDispatchService $dispatch) {}

    public function dashboard(Request $request)
    {
        $user = $request->user() ?: Auth::user();
        $driver = Driver::firstOrCreate(['user_id' => $user->id]);

        $withRelations = ['items', 'patient', 'assignedPharmacy.pharmacy', 'assignedLab.lab', 'assignedNurse.nurse'];

        $activeOrders = Order::where('assigned_driver_id', $user->id)
            ->whereNotIn('status', ['completed', 'cancelled'])
            ->where(function ($q) {
                $q->whereNull('delivery_status')
                  ->orWhere('delivery_status', '!=', 'delivered');
            })
            ->with($withRelations)
            ->orderByRaw("CASE WHEN delivery_status = 'assigned' THEN 0 ELSE 1 END")
            ->orderByDesc('driver_assigned_at')
            ->orderByDesc('id')
            ->get()
            ->map(fn ($o) => $this->formatDriverOrder($o, $driver))
            ->values();

        $completedOrders = Order::where('assigned_driver_id', $user->id)
            ->where(function ($q) {
                $q->where('status', 'completed')
                  ->orWhere('delivery_status', 'delivered');
            })
            ->with($withRelations)
            ->orderByDesc('driver_delivered_at')
            ->orderByDesc('id')
            ->take(25)
            ->get()
            ->map(fn ($o) => $this->formatDriverOrder($o, $driver))
            ->values();

        // Fallback unassigned delivery pool sorted nearest-first for eligible orders
        $poolQuery = Order::whereNull('assigned_driver_id')
            ->whereIn('status', ['pending', 'processing', 'accepted', 'confirmed', 'approved', 'in_progress'])
            ->with($withRelations)
            ->orderByDesc('id');

        if ($driver->service_scope === 'pharmacy') {
            $poolQuery->where(function ($q) {
                $q->where('service_type', 'like', '%pharmac%')
                  ->orWhere('service_type', 'like', '%medic%')
                  ->orWhere('service_type', 'like', '%دەرمان%');
            });
        } elseif ($driver->service_scope === 'lab_sample') {
            $poolQuery->where(function ($q) {
                $q->where('service_type', 'like', '%lab%')
                  ->orWhere('service_type', 'like', '%تاقیگە%');
            });
        } else {
            $poolQuery->where(function ($q) {
                $q->where('service_type', 'like', '%pharmac%')
                  ->orWhere('service_type', 'like', '%lab%')
                  ->orWhere('service_type', 'like', '%medic%')
                  ->orWhere('service_type', 'like', '%تاقیگە%')
                  ->orWhere('service_type', 'like', '%دەرمان%');
            });
        }

        $availableOrders = $poolQuery->take(50)->get()
            ->filter(fn ($o) => $o->needsDeliveryDriver() && !in_array((int) $user->id, $this->dispatch->getDeclinedDriverIds($o), true))
            ->sortBy(fn ($o) => $this->dispatch->distanceForDriver($o, $driver) ?? 999999.0)
            ->take(25)
            ->map(fn ($o) => $this->formatDriverOrder($o, $driver))
            ->values();

        $todayDelivered = Order::where('assigned_driver_id', $user->id)
            ->where(function ($q) {
                $q->where('status', 'completed')
                  ->orWhere('delivery_status', 'delivered');
            })
            ->whereDate('driver_delivered_at', today())
            ->count();

        $monthDelivered = Order::where('assigned_driver_id', $user->id)
            ->where(function ($q) {
                $q->where('status', 'completed')
                  ->orWhere('delivery_status', 'delivered');
            })
            ->whereMonth('driver_delivered_at', now()->month)
            ->whereYear('driver_delivered_at', now()->year)
            ->count();

        $todayEarnings = (float) Order::where('assigned_driver_id', $user->id)
            ->where(function ($q) {
                $q->where('status', 'completed')
                  ->orWhere('delivery_status', 'delivered');
            })
            ->whereDate('driver_delivered_at', today())
            ->sum('delivery_fee');

        $unreadNotifications = AppNotification::where('user_id', $user->id)
            ->where('is_read', false)
            ->count();

        return response()->json([
            'data' => [
                'driver' => array_merge([
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
                ], $driver->resolvedFieldProfile()),
                'stats' => [
                    'active_count' => $activeOrders->count(),
                    'available_count' => $availableOrders->count(),
                    'today_deliveries' => $todayDelivered,
                    'month_deliveries' => $monthDelivered,
                    'today_earnings' => $todayEarnings,
                    'total_deliveries' => (int) $driver->completed_deliveries,
                    'total_earnings' => (float) $driver->total_earnings,
                    'unread_notifications' => $unreadNotifications,
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
            $activeAccepted = Order::where('assigned_driver_id', $user->id)
                ->whereNotIn('status', ['completed', 'cancelled'])
                ->whereIn('delivery_status', ['accepted', 'picked_up', 'on_the_way', 'arrived'])
                ->count();

            if ($activeAccepted > 0) {
                return response()->json([
                    'message' => 'تکایە سەرەتا گەیاندنە چالاکەکان تەواو بکە پێش ئەوەی ئۆفلاین بیت.',
                ], 422);
            }

            // Release any pending unaccepted offers and immediately pass to next nearest driver
            $pendingOffers = Order::where('assigned_driver_id', $user->id)
                ->whereNotIn('status', ['completed', 'cancelled'])
                ->where('delivery_status', 'assigned')
                ->get();

            $driver->duty_status = 'offline';
            $driver->save();

            foreach ($pendingOffers as $offered) {
                $this->dispatch->recordDeclinedDriver($offered, $user->id);
                $offered->assigned_driver_id = null;
                $offered->delivery_status = 'unassigned';
                $offered->driver_assigned_at = null;
                $offered->save();
                $this->dispatch->dispatchNearest($offered);
            }
        } else {
            $driver->duty_status = $request->duty_status;
            $driver->save();
            $this->dispatch->autoAssignWaitingOrdersForDriver($user, $driver);
        }

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
            'speed' => 'nullable|numeric|min:0',
            'heading' => 'nullable|numeric|between:0,360',
        ]);

        $user = $request->user();
        $driver = Driver::firstOrCreate(['user_id' => $user->id]);

        $prevLat = $driver->current_lat !== null ? (float) $driver->current_lat : null;
        $prevLng = $driver->current_lng !== null ? (float) $driver->current_lng : null;
        $newLat = (float) $request->lat;
        $newLng = (float) $request->lng;

        $movedMeters = ($prevLat !== null && $prevLng !== null)
            ? DriverDispatchService::distanceKm($prevLat, $prevLng, $newLat, $newLng) * 1000.0
            : null;
        $speedMps = is_numeric($request->input('speed')) ? (float) $request->input('speed') : 0.0;
        $isMoving = $speedMps >= 1.4 || ($movedMeters !== null && $movedMeters >= 45.0);

        $driver->update([
            'current_lat' => $newLat,
            'current_lng' => $newLng,
            'last_location_at' => now(),
        ]);

        if ($driver->duty_status === 'available') {
            $this->dispatch->autoAssignWaitingOrdersForDriver($user, $driver);
        }

        $autoUpdates = $this->evaluateAutoGeofences($user, $newLat, $newLng, $isMoving);

        return response()->json([
            'success' => true,
            'last_location_at' => $driver->last_location_at?->toIso8601String(),
            'auto_updates' => $autoUpdates,
        ]);
    }

    /**
     * Talabat-style automatic proximity state transitions when the courier/staff
     * moves along the route and approaches pickup or the patient's destination.
     */
    private function evaluateAutoGeofences(User $user, float $dLat, float $dLng, bool $isMoving): array
    {
        $orders = Order::where('assigned_driver_id', $user->id)
            ->whereNotIn('status', ['completed', 'cancelled'])
            ->whereIn('delivery_status', ['accepted', 'picked_up', 'on_the_way'])
            ->with(['assignedPharmacy.pharmacy', 'assignedLab.lab'])
            ->get();

        $updates = [];

        foreach ($orders as $order) {
            $oldStage = (string) $order->delivery_status;
            $isLab = str_contains(strtolower((string) $order->service_type), 'lab');

            $pickupLat = null;
            $pickupLng = null;
            if ($isLab && $order->assignedLab?->lab) {
                $l = $order->assignedLab->lab;
                $pickupLat = is_numeric($l->latitude) ? (float) $l->latitude : null;
                $pickupLng = is_numeric($l->longitude) ? (float) $l->longitude : null;
            } elseif ($order->assignedPharmacy?->pharmacy) {
                $p = $order->assignedPharmacy->pharmacy;
                $pickupLat = is_numeric($p->latitude) ? (float) $p->latitude : null;
                $pickupLng = is_numeric($p->longitude) ? (float) $p->longitude : null;
            }

            $patientLoc = $order->resolvePatientLocation();
            $patientLat = $patientLoc['lat'];
            $patientLng = $patientLoc['lng'];

            $distToPickupM = ($pickupLat !== null && $pickupLng !== null)
                ? DriverDispatchService::distanceKm($dLat, $dLng, $pickupLat, $pickupLng) * 1000.0
                : null;
            $distToPatientM = ($patientLat !== null && $patientLng !== null)
                ? DriverDispatchService::distanceKm($dLat, $dLng, $patientLat, $patientLng) * 1000.0
                : null;

            $nextStage = null;

            if ($isLab) {
                if ($order->driver_picked_up_at === null) {
                    if (in_array($oldStage, ['accepted', 'on_the_way'], true) && $distToPatientM !== null && $distToPatientM <= 150.0) {
                        $nextStage = 'arrived';
                    } elseif ($oldStage === 'accepted' && $isMoving && ($distToPatientM === null || $distToPatientM > 150.0)) {
                        $nextStage = 'on_the_way';
                    }
                } elseif ($oldStage === 'picked_up' && (($distToPatientM === null && $isMoving) || ($distToPatientM !== null && $distToPatientM > 200.0))) {
                    $nextStage = 'on_the_way';
                }
            } else {
                if ($oldStage === 'accepted') {
                    if ($distToPickupM !== null) {
                        if ($distToPickupM <= 150.0 && ($distToPatientM === null || $distToPatientM > 150.0)) {
                            $nextStage = 'picked_up';
                        } elseif ($distToPatientM !== null && $distToPatientM <= 150.0) {
                            $nextStage = 'arrived';
                        }
                    } else {
                        if ($distToPatientM !== null && $distToPatientM <= 150.0) {
                            $nextStage = 'arrived';
                        } elseif ($isMoving && $distToPatientM !== null && $distToPatientM > 150.0) {
                            $nextStage = 'on_the_way';
                        }
                    }
                } elseif ($oldStage === 'picked_up') {
                    if ($distToPatientM !== null && $distToPatientM <= 150.0) {
                        $nextStage = 'arrived';
                    } elseif (($distToPickupM !== null && $distToPickupM > 200.0) || ($distToPickupM === null && $isMoving)) {
                        $nextStage = 'on_the_way';
                    }
                } elseif ($oldStage === 'on_the_way') {
                    if ($distToPatientM !== null && $distToPatientM <= 150.0) {
                        $nextStage = 'arrived';
                    }
                }
            }

            if ($nextStage !== null && $nextStage !== $oldStage) {
                $order->delivery_status = $nextStage;
                if ($nextStage === 'picked_up' && $order->driver_picked_up_at === null) {
                    $order->driver_picked_up_at = now();
                }
                if ($order->status === 'pending') {
                    $order->status = 'processing';
                }
                $order->save();

                OrderNotificationService::notifyDeliveryStage($order->fresh(), $nextStage);

                $updates[] = [
                    'order_id' => $order->id,
                    'from' => $oldStage,
                    'to' => $nextStage,
                ];
            }
        }

        return $updates;
    }

    public function claimOrder(Request $request, $id)
    {
        $user = $request->user();
        $driver = Driver::firstOrCreate(['user_id' => $user->id]);

        if ($driver->duty_status === 'offline') {
            return response()->json([
                'message' => 'تکایە سەرەتا دۆخەکەت بکەرە ئۆنلاین (ئامادە) پێش وەرگرتنی داواکاری.',
            ], 422);
        }

        $claimed = DB::transaction(function () use ($id, $user, $driver) {
            $order = Order::where('id', $id)->lockForUpdate()->firstOrFail();

            if ($order->assigned_driver_id !== null && (int) $order->assigned_driver_id !== (int) $user->id) {
                return null;
            }
            if (in_array($order->status, ['completed', 'cancelled'], true) || !$order->needsDeliveryDriver()) {
                return false;
            }

            $order->assigned_driver_id = $user->id;
            $order->delivery_status = 'accepted';
            $order->driver_assigned_at = $order->driver_assigned_at ?? now();
            if ($order->delivery_fee <= 0) {
                $order->delivery_fee = $order->resolveDeliveryFee();
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
            return response()->json(['message' => 'ئەم داواکارییە چیتر بەردەست نییە یان بۆ دلیڤەری نییە.'], 422);
        }

        OrderNotificationService::notifyDeliveryStage($claimed, 'accepted');

        return response()->json([
            'message' => 'داواکارییەکە بە سەرکەوتوویی وەرگیرا',
            'order' => $this->formatDriverOrder($claimed->fresh(['items', 'patient', 'assignedPharmacy.pharmacy', 'assignedLab.lab', 'assignedNurse.nurse']), $driver),
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

        if (in_array($order->status, ['completed', 'cancelled'], true) || $order->delivery_status === 'delivered') {
            return response()->json(['message' => 'ئەم داواکارییە پێشتر داخراوە.'], 422);
        }

        $next = $request->delivery_status;

        if ($next === 'rejected') {
            if (in_array($order->delivery_status, ['picked_up', 'on_the_way', 'arrived', 'delivered'], true)) {
                return response()->json(['message' => 'ناتوانرێت داواکارییەک ڕەتبکرێتەوە دوای وەرگرتنی.'], 422);
            }

            $this->dispatch->recordDeclinedDriver($order, $user->id);

            $order->assigned_driver_id = null;
            $order->delivery_status = 'unassigned';
            $order->driver_assigned_at = null;
            $order->driver_notes = $request->notes;
            $order->save();

            Driver::syncDutyStatusForUser($user->id);

            // Automatically forward the declined order to the next nearest online driver
            $nextDriver = $this->dispatch->dispatchNearest($order);

            return response()->json([
                'message' => $nextDriver
                    ? 'داواکارییەکە ئاڕاستەی نزیکترین شۆفێری داهاتوو کرا'
                    : 'داواکارییەکە گەڕێندرایەوە بۆ لیستە بەردەستەکان',
            ]);
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
                $fee = $order->resolveDeliveryFee();
                $order->delivery_fee = $fee;

                // Lab sample delivery ends the courier leg, while the lab order
                // remains in_progress until the lab publishes results.
                if ($order->isLabService()) {
                    if (in_array($order->status, ['pending', 'accepted', 'confirmed', 'processing'], true)) {
                        $order->status = 'in_progress';
                    }
                } else {
                    $order->markCompletedWithFinancials();
                }

                $driver->increment('completed_deliveries');
                $driver->increment('total_earnings', $fee);
            }

            $order->save();

            Driver::syncDutyStatusForUser($user->id);
        });

        OrderNotificationService::notifyDeliveryStage($order->fresh(), $next);

        return response()->json([
            'message' => 'دۆخی گەیاندن نوێکرایەوە',
            'order' => $this->formatDriverOrder($order->fresh(['items', 'patient', 'assignedPharmacy.pharmacy', 'assignedLab.lab', 'assignedNurse.nurse']), $driver),
        ]);
    }

    private function formatDriverOrder(Order $order, ?Driver $viewerDriver = null): array
    {
        $patientDetails = is_array($order->patient_details)
            ? $order->patient_details
            : (json_decode((string) $order->patient_details, true) ?: []);

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

        $loc = $order->resolvePatientLocation();

        return [
            'id' => $order->id,
            'order_number' => '#' . $order->id,
            'service_type' => $order->service_type,
            'is_lab' => $isLab,
            'distance_km' => $this->dispatch->distanceForDriver($order, $viewerDriver),
            'status' => $order->status,
            'delivery_status' => $order->delivery_status ?? 'unassigned',
            'total_price' => (float) $order->total_price,
            'delivery_fee' => $order->resolveDeliveryFee(),
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
                'address' => $loc['address'],
                'lat' => $loc['lat'],
                'lng' => $loc['lng'],
                'notes' => $loc['notes'],
            ],
            'items' => collect($order->items ?? [])->map(fn ($it) => [
                'name' => $it->item_name ?? $it->name ?? 'خزمەتگوزاری',
                'quantity' => (int) ($it->quantity ?? 1),
                'price' => (float) ($it->price ?? 0),
            ])->values(),
        ];
    }
}

