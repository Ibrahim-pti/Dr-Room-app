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
        $lang = $request->header('Accept-Language', $request->query('lang', 'ckb'));
        $orders = Order::where('patient_id', Auth::id())
            ->with(['items', 'assignedNurse.nurse', 'assignedPharmacy.pharmacy', 'assignedLab.lab', 'assignedDriver.driver'])
            ->orderBy('created_at', 'desc')
            ->get();
            
        return response()->json([
            'data' => $orders->map(fn($o) => $this->formatOrder($o, $lang))
        ]);
    }

    public function show(Request $request, $id)
    {
        $lang = $request->header('Accept-Language', $request->query('lang', 'ckb'));
        $order = Order::where('patient_id', Auth::id())
            ->with(['items', 'assignedNurse.nurse', 'assignedPharmacy.pharmacy', 'assignedLab.lab', 'assignedDriver.driver'])
            ->findOrFail($id);

        return response()->json([
            'data' => $this->formatOrder($order, $lang)
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'service_type' => 'required|string',
            'subtotal' => 'required|numeric|min:0',
            'extra_fee' => 'required|numeric|min:0',
            'service_fee' => 'nullable|numeric|min:0',
            'total_price' => 'required|numeric|min:0',
            'payment_method' => 'required|string',
            'items' => 'required|array|min:1',
            'items.*.name' => 'required|string',
            'items.*.price' => 'required|numeric|min:0',
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

            // Resolve & verify assigned provider IDs safely
            if ($assignedPharmacyId) {
                if (!\App\Models\User::where('id', $assignedPharmacyId)->where('role', 'pharmacy')->where('status', 'approved')->exists()) {
                    $pharmacyRecord = \App\Models\Pharmacy::find($assignedPharmacyId);
                    $assignedPharmacyId = ($pharmacyRecord && $pharmacyRecord->user_id && \App\Models\User::where('id', $pharmacyRecord->user_id)->where('role', 'pharmacy')->where('status', 'approved')->exists())
                        ? $pharmacyRecord->user_id
                        : null;
                }
                if (!$assignedPharmacyId) {
                    DB::rollBack();
                    return response()->json(['message' => 'دەرمانخانەی دیاریکراو بەردەست نییە یان پەسەند نەکراوە'], 422);
                }
            }

            if ($assignedLabId) {
                if (!\App\Models\User::where('id', $assignedLabId)->where('role', 'lab')->where('status', 'approved')->exists()) {
                    $labRecord = \App\Models\Lab::find($assignedLabId);
                    $assignedLabId = ($labRecord && $labRecord->user_id && \App\Models\User::where('id', $labRecord->user_id)->where('role', 'lab')->where('status', 'approved')->exists())
                        ? $labRecord->user_id
                        : null;
                }
                if (!$assignedLabId) {
                    DB::rollBack();
                    return response()->json(['message' => 'تاقیگەی دیاریکراو بەردەست نییە یان پەسەند نەکراوە'], 422);
                }
            }

            if ($assignedNurseId) {
                if (!\App\Models\User::where('id', $assignedNurseId)->where('role', 'nurse')->where('status', 'approved')->exists()) {
                    $nurseRecord = \App\Models\Nurse::find($assignedNurseId);
                    $assignedNurseId = ($nurseRecord && $nurseRecord->user_id && \App\Models\User::where('id', $nurseRecord->user_id)->where('role', 'nurse')->where('status', 'approved')->exists())
                        ? $nurseRecord->user_id
                        : null;
                }
                if (!$assignedNurseId) {
                    DB::rollBack();
                    return response()->json(['message' => 'پەرستاری دیاریکراو بەردەست نییە یان پەسەند نەکراوە'], 422);
                }
            }

            $patientDetails = $request->patient_details ?? [];
            if ($prescriptionImage) {
                $patientDetails['prescription_image'] = $prescriptionImage;
                $patientDetails['prescription_url'] = $prescriptionImage;
                $patientDetails['is_prescription'] = true;
            }

            $serviceFee = max(0.0, (float) ($request->input('service_fee') ?? ($patientDetails['service_fee'] ?? 0)));
            if ($serviceFee > 0) {
                $patientDetails['service_fee'] = $serviceFee;
            }

            // Coupon & Commission Calculations (with row lock to prevent usage_limit race)
            $couponCode = $request->coupon_code ? strtoupper(trim($request->coupon_code)) : null;
            $discountAmount = max(0.0, (float) ($request->discount_amount ?? 0));
            $effectiveTotal = max(0.0, round((float) $request->total_price, 2));
            if ($couponCode) {
                $coupon = \App\Models\Coupon::where('code', $couponCode)->lockForUpdate()->first();
                if (!$coupon) {
                    DB::rollBack();
                    return response()->json(['message' => 'کۆدی داشکاندن نادروستە یان بوونی نییە'], 422);
                }
                $couponCheck = $coupon->isValidFor((float) $request->subtotal);
                if (!$couponCheck['valid']) {
                    DB::rollBack();
                    return response()->json(['message' => $couponCheck['message']], 422);
                }
                $discountAmount = (float) $couponCheck['discount'];
                $effectiveTotal = max(0.0, round((float) $request->subtotal + (float) $request->extra_fee + $serviceFee - $discountAmount, 2));
                $coupon->increment('used_count');
            }

            // Scheduled slot check (lab & nursing). Rejects when the slot is already full.
            $scheduledAt = null;
            $rawScheduledAt = $request->input('scheduled_at') ?? ($patientDetails['scheduled_at'] ?? null);
            if (!empty($rawScheduledAt)) {
                try {
                    $scheduledAt = \App\Services\ProviderSlotService::parseWallClock($rawScheduledAt);
                } catch (\Throwable) {
                    DB::rollBack();
                    return response()->json(['message' => 'فۆرماتی کاتی دیاریکراو نادروستە'], 422);
                }
                $patientDetails['scheduled_at'] = $scheduledAt->format('Y-m-d H:i');

                $slotType = \App\Services\ProviderSlotService::typeForService($request->service_type);
                if ($slotType !== null) {
                    $providerUserId = $slotType === 'lab' ? $assignedLabId : $assignedNurseId;
                    if (!\App\Services\ProviderSlotService::isBookable($slotType, $providerUserId ? (int) $providerUserId : null, $scheduledAt)) {
                        DB::rollBack();
                        return response()->json([
                            'message' => 'ئەم کاتە پڕبووەتەوە (گیراوە) یان لە دەرەوەی کاتی دەوامە، تکایە کاتێکی تر هەڵبژێرە',
                        ], 422);
                    }
                }
            }

            // Commission uses the current month's rate (nursing / lab only).
            $commRate = \App\Services\CommissionService::rateForService($request->service_type);
            [$commAmount, $providerNetAmount] = \App\Services\CommissionService::split($effectiveTotal, $commRate);

            $orderData = [
                'patient_id' => Auth::id(),
                'service_type' => $request->service_type,
                'subtotal' => $request->subtotal,
                'extra_fee' => $request->extra_fee,
                'total_price' => $effectiveTotal,
                'coupon_code' => $couponCode,
                'discount_amount' => $discountAmount,
                'commission_rate' => $commRate,
                'commission_amount' => $commAmount,
                'provider_net_amount' => $providerNetAmount,
                'status' => 'pending',
                'scheduled_at' => $scheduledAt,
                'payment_method' => $request->payment_method,
                'assigned_pharmacy_id' => $assignedPharmacyId,
                'assigned_nurse_id' => $assignedNurseId,
                'assigned_lab_id' => $assignedLabId,
                'patient_details' => $patientDetails,
                'location_details' => $request->location_details ?? [],
            ];
            if (\Illuminate\Support\Facades\Schema::hasColumn('orders', 'service_fee')) {
                $orderData['service_fee'] = $serviceFee;
            }
            $order = Order::create($orderData);

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

            // Notify patient, admins/staff, and any pre-assigned provider
            \App\Services\OrderNotificationService::notifyOrderCreated($order);

            // Automatically dispatch eligible orders (Pharmacy / unassigned Lab pickup)
            // directly to the nearest available delivery driver without admin bottleneck.
            if ($order->needsDeliveryDriver()) {
                try {
                    app(\App\Services\DriverDispatchService::class)->dispatchNearest($order);
                } catch (\Throwable $dispatchErr) {
                    \Illuminate\Support\Facades\Log::warning('Auto-dispatch skipped: ' . $dispatchErr->getMessage());
                }
            }

            $lang = $request->header('Accept-Language', $request->query('lang', 'ckb'));
            $order->load(['items', 'assignedNurse.nurse', 'assignedPharmacy.pharmacy', 'assignedLab.lab', 'assignedDriver.driver']);

            return response()->json([
                'message' => 'Order created successfully',
                'order' => $this->formatOrder($order, $lang),
                'data' => $this->formatOrder($order, $lang),
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Failed to create order: ' . $e->getMessage()], 500);
        }
    }

    /**
     * Format Order with full translations and resolved media URLs.
     */
    public function formatOrder($order, string $lang = 'ckb'): array
    {
        $langCode = strtolower(substr($lang, 0, 3));
        if ($langCode === 'kur' || $langCode === 'ku') $langCode = 'ckb';
        if (!in_array($langCode, ['ckb', 'kmr', 'ar', 'en'])) $langCode = 'ckb';

        $serviceTitles = $this->getServiceTitles($order->service_type ?? '');
        $statusLabels = $this->getStatusLabels($order->status ?? 'pending');

        // Format Assigned Nurse
        $assignedNurse = null;
        if ($order->assignedNurse) {
            $u = $order->assignedNurse;
            $n = $u->nurse;
            $rawImg = $u->profile_image ?? ($n->image_path ?? null);
            $imgUrl = $this->resolveImageUrl($rawImg);

            $nameEn = $u->name_en ?: $u->name;
            $nameAr = $u->name_ar ?: ($u->name_en ?: $u->name);
            $nameKmr = $u->name_kmr ?: ($u->name_ckb ?: $u->name);
            $nameCkb = $u->name ?: ($u->name_en ?: '');

            $chosenName = match($langCode) {
                'en' => $nameEn,
                'ar' => $nameAr,
                'kmr' => $nameKmr,
                default => $nameCkb,
            };

            $assignedNurse = [
                'id' => $u->id,
                'nurse_id' => $n->id ?? null,
                'name' => $chosenName,
                'name_en' => $nameEn,
                'name_ar' => $nameAr,
                'name_kmr' => $nameKmr,
                'name_ckb' => $nameCkb,
                'avatar' => $imgUrl,
                'image_url' => $imgUrl,
                'profile_image' => $imgUrl,
                'phone' => $u->phone ?? ($n->phone ?? null),
                'specialty' => $n->specialty ?? null,
                'specialty_en' => $n->specialty_en ?? ($n->specialty ?? null),
                'specialty_ar' => $n->specialty_ar ?? ($n->specialty ?? null),
                'specialty_kmr' => $n->specialty_kmr ?? ($n->specialty ?? null),
            ];
        }

        // Format Assigned Pharmacy
        $assignedPharmacy = null;
        if ($order->assignedPharmacy) {
            $u = $order->assignedPharmacy;
            $p = $u->pharmacy;
            $rawImg = $u->profile_image ?? ($p->image_path ?? null);
            $imgUrl = $this->resolveImageUrl($rawImg);

            $nameEn = $u->name_en ?: $u->name;
            $nameAr = $u->name_ar ?: ($u->name_en ?: $u->name);
            $nameKmr = $u->name_kmr ?: ($u->name_ckb ?: $u->name);
            $nameCkb = $u->name ?: ($u->name_en ?: '');

            $chosenName = match($langCode) {
                'en' => $nameEn,
                'ar' => $nameAr,
                'kmr' => $nameKmr,
                default => $nameCkb,
            };

            $assignedPharmacy = [
                'id' => $u->id,
                'pharmacy_id' => $p->id ?? null,
                'name' => $chosenName,
                'name_en' => $nameEn,
                'name_ar' => $nameAr,
                'name_kmr' => $nameKmr,
                'name_ckb' => $nameCkb,
                'avatar' => $imgUrl,
                'image_url' => $imgUrl,
                'phone' => $u->phone ?? ($p->phone ?? null),
                'location' => $p?->location,
                'latitude' => $p && $p->latitude !== null ? (float) $p->latitude : null,
                'longitude' => $p && $p->longitude !== null ? (float) $p->longitude : null,
            ];
        }

        // Format Assigned Lab
        $assignedLab = null;
        if ($order->assignedLab) {
            $u = $order->assignedLab;
            $l = $u->lab;
            $rawImg = $u->profile_image ?? ($l->image_path ?? null);
            $imgUrl = $this->resolveImageUrl($rawImg);

            $nameEn = $u->name_en ?: $u->name;
            $nameAr = $u->name_ar ?: ($u->name_en ?: $u->name);
            $nameKmr = $u->name_kmr ?: ($u->name_ckb ?: $u->name);
            $nameCkb = $u->name ?: ($u->name_en ?: '');

            $chosenName = match($langCode) {
                'en' => $nameEn,
                'ar' => $nameAr,
                'kmr' => $nameKmr,
                default => $nameCkb,
            };

            $assignedLab = [
                'id' => $u->id,
                'lab_id' => $l->id ?? null,
                'name' => $chosenName,
                'name_en' => $nameEn,
                'name_ar' => $nameAr,
                'name_kmr' => $nameKmr,
                'name_ckb' => $nameCkb,
                'avatar' => $imgUrl,
                'image_url' => $imgUrl,
                'phone' => $u->phone ?? ($l->phone ?? null),
                'location' => $l?->location,
                'latitude' => $l && $l->latitude !== null ? (float) $l->latitude : null,
                'longitude' => $l && $l->longitude !== null ? (float) $l->longitude : null,
            ];
        }

        $patientDetails = $order->patient_details ?? [];
        if (is_string($patientDetails)) {
            $patientDetails = json_decode($patientDetails, true) ?? [];
        }
        $prescriptionImg = $patientDetails['prescription_image'] ?? $patientDetails['prescription_url'] ?? null;
        if (!$prescriptionImg && !empty($order->items)) {
            foreach ($order->items as $item) {
                $extra = is_array($item->extra_data) ? $item->extra_data : (is_string($item->extra_data) ? json_decode($item->extra_data, true) : []);
                if (!empty($extra['prescription_url'])) { $prescriptionImg = $extra['prescription_url']; break; }
                if (!empty($extra['prescription_image'])) { $prescriptionImg = $extra['prescription_image']; break; }
                if (!empty($extra['prescription_path'])) { $prescriptionImg = $extra['prescription_path']; break; }
            }
        }
        $prescriptionImgUrl = $prescriptionImg ? $this->resolveImageUrl($prescriptionImg) : null;

        // Format Assigned Driver (Live Courier & Delivery Tracking)
        $assignedDriver = null;
        if ($order->assignedDriver) {
            $u = $order->assignedDriver;
            $d = $u->driver;
            $assignedDriver = [
                'id' => $u->id,
                'name' => $u->name,
                'phone' => $u->phone,
                'avatar' => $u->avatar_url,
                'vehicle_type' => $d?->vehicle_type ?? 'motorcycle',
                'plate_number' => $d?->plate_number,
                'duty_status' => $d?->duty_status ?? 'offline',
                'current_lat' => $d?->current_lat,
                'current_lng' => $d?->current_lng,
                'last_location_at' => $d?->last_location_at?->toIso8601String(),
            ];
        }

        $estimatedLabels = $order->estimatedDurationLabels();
        $isTerminalOrder = in_array(strtolower((string) $order->status), ['completed', 'delivered', 'done', 'cancelled', 'rejected'], true);
        $estimatedRemainingSeconds = (!$isTerminalOrder && $order->estimated_ready_at !== null)
            ? max(0, (int) round(now()->diffInSeconds($order->estimated_ready_at, false)))
            : null;

        return [
            'id' => $order->id,
            'patient_id' => $order->patient_id,
            'service_type' => $order->service_type,
            'title' => $serviceTitles[$langCode] ?? $serviceTitles['ckb'],
            'title_ckb' => $serviceTitles['ckb'],
            'title_kmr' => $serviceTitles['kmr'],
            'title_ar' => $serviceTitles['ar'],
            'title_en' => $serviceTitles['en'],
            'subtotal' => $order->subtotal,
            'extra_fee' => $order->extra_fee,
            'service_fee' => (float) ($order->service_fee ?? ($patientDetails['service_fee'] ?? 0)),
            'total_price' => $order->total_price,
            'status' => $order->status,
            'scheduled_at' => $order->scheduled_at?->format('Y-m-d H:i'),
            'scheduled_at_iso' => $order->scheduled_at
                ? \App\Services\ProviderSlotService::parseWallClock($order->scheduled_at)->toIso8601String()
                : null,
            'delivery_status' => $order->delivery_status ?? 'unassigned',
            'delivery_fee' => (float) ($order->delivery_fee ?? 0),
            'driver_assigned_at' => $order->driver_assigned_at?->toIso8601String(),
            'driver_picked_up_at' => $order->driver_picked_up_at?->toIso8601String(),
            'driver_delivered_at' => $order->driver_delivered_at?->toIso8601String(),
            'status_label' => $statusLabels[$langCode] ?? $statusLabels['ckb'],
            'status_labels' => $statusLabels,
            'estimated_duration_minutes' => $order->estimated_duration_minutes,
            'estimated_ready_at' => $order->estimated_ready_at?->toIso8601String(),
            'estimated_remaining_seconds' => $estimatedRemainingSeconds,
            'estimated_duration_label' => $estimatedLabels[$langCode] ?? $estimatedLabels['ckb'],
            'estimated_duration_labels' => $estimatedLabels,
            'payment_method' => $order->payment_method,
            'assigned_nurse_id' => $order->assigned_nurse_id,
            'assigned_pharmacy_id' => $order->assigned_pharmacy_id,
            'assigned_lab_id' => $order->assigned_lab_id,
            'assigned_driver_id' => $order->assigned_driver_id,
            'patient_details' => $order->patient_details,
            'location_details' => $order->location_details,
            'created_at' => $order->created_at?->toIso8601String(),
            'updated_at' => $order->updated_at?->toIso8601String(),
            'items' => $order->items,
            'assigned_nurse' => $assignedNurse,
            'assigned_pharmacy' => $assignedPharmacy,
            'assigned_lab' => $assignedLab,
            'assigned_driver' => $assignedDriver,
            'prescription_image' => $prescriptionImgUrl,
        ];
    }

    private function resolveImageUrl(?string $raw): ?string
    {
        if (empty($raw)) return null;
        if (str_starts_with($raw, 'http://') || str_starts_with($raw, 'https://')) {
            return $raw;
        }
        $clean = ltrim($raw, '/');
        if (str_starts_with($clean, 'storage/')) {
            return asset($clean);
        }
        return asset('storage/' . $clean);
    }

    private function getServiceTitles(string $serviceType): array
    {
        $lower = strtolower(trim($serviceType));
        if (str_contains($lower, 'nurs')) {
            return [
                'ckb' => 'خزمەتگوزاری پەرستاری',
                'kmr' => 'خزمەتگوزارییێن پەرستاریێ',
                'ar'  => 'خدمات التمريض',
                'en'  => 'Nursing Services',
            ];
        }
        if (str_contains($lower, 'lab')) {
            return [
                'ckb' => 'پشکنینی تاقیگە',
                'kmr' => 'پشکنینێن تاقیگەهێ',
                'ar'  => 'تحاليل المختبر',
                'en'  => 'Lab Tests',
            ];
        }
        if (str_contains($lower, 'pharmac') || str_contains($lower, 'medic')) {
            return [
                'ckb' => 'دەرمانخانە',
                'kmr' => 'دەرمانخانە',
                'ar'  => 'صيدلية',
                'en'  => 'Pharmacy',
            ];
        }
        if (str_contains($lower, 'xray') || str_contains($lower, 'x-ray') || str_contains($lower, 'radiolog')) {
            return [
                'ckb' => 'تیشک و سۆنار',
                'kmr' => 'تیشک و سۆنار',
                'ar'  => 'الأشعة والسونار',
                'en'  => 'X-Ray & Scan',
            ];
        }
        return [
            'ckb' => $serviceType,
            'kmr' => $serviceType,
            'ar'  => $serviceType,
            'en'  => $serviceType,
        ];
    }

    private function getStatusLabels(string $status): array
    {
        return match(strtolower(trim($status))) {
            'pending' => [
                'ckb' => 'چاوەڕوانی پشتڕاستکردنەوەیە',
                'kmr' => 'چاڤەڕێی پشتڕاستکرنێیە',
                'ar'  => 'قيد الانتظار',
                'en'  => 'Pending Confirmation',
            ],
            'on_the_way' => [
                'ckb' => 'لە ڕێگادایە',
                'kmr' => 'د ڕێکێ دایە',
                'ar'  => 'في الطريق إليك',
                'en'  => 'On the Way',
            ],
            'processing', 'in_progress', 'accepted', 'approved' => [
                'ckb' => 'لە قۆناغی جێبەجێکردندایە',
                'kmr' => 'د بجهئینانێ دایە',
                'ar'  => 'قيد التنفيذ',
                'en'  => 'Processing',
            ],
            'completed', 'delivered', 'done' => [
                'ckb' => 'تەواوکراوە',
                'kmr' => 'تمامکری',
                'ar'  => 'مكتمل',
                'en'  => 'Completed',
            ],
            'cancelled', 'rejected' => [
                'ckb' => 'هەڵوەشێنراوەتەوە',
                'kmr' => 'هاتیە هەلوەشاندن',
                'ar'  => 'ملغي',
                'en'  => 'Cancelled',
            ],
            default => [
                'ckb' => 'چاوەڕوانی',
                'kmr' => 'چاڤەڕێ',
                'ar'  => 'قيد الانتظار',
                'en'  => 'Pending',
            ],
        };
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
