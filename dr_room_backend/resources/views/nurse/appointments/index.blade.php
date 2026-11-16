@extends('nurse.layouts.app')

@section('content')
@php
    $statusLabelsMap = [
        'pending' => 'چاوەڕوانە',
        'on_the_way' => 'لە ڕێگادایە',
        'processing' => 'قبوڵکرا / لە کاردایە',
        'in_progress' => 'قبوڵکرا / لە کاردایە',
        'approved' => 'قبوڵکرا / لە کاردایە',
        'confirmed' => 'قبوڵکرا / لە کاردایە',
        'completed' => 'تەواوکراوە',
        'cancelled' => 'ڕەتکرایەوە',
        'rejected' => 'ڕەتکرایەوە',
    ];

    $buildNurseOrderPayload = function ($order) use ($statusLabelsMap) {
        $details = is_array($order->patient_details)
            ? $order->patient_details
            : (json_decode($order->patient_details, true) ?? []);
        $loc = is_array($order->location_details)
            ? $order->location_details
            : (json_decode($order->location_details, true) ?? []);

        $patientName = !empty($details['full_name'])
            ? $details['full_name']
            : (!empty($details['name']) ? $details['name'] : ($order->patient?->name ?? 'نەخۆش'));
        $patientPhone = !empty($details['phone']) ? $details['phone'] : ($order->patient?->phone ?? 'نەزانراو');
        $patientAge = !empty($details['age']) ? $details['age'] : (!empty($details['patient_age']) ? $details['patient_age'] : null);

        $rawGender = strtolower(trim((string) ($details['patient_gender'] ?? $details['gender'] ?? $order->patient?->gender ?? '')));
        if (in_array($rawGender, ['male', 'نێر', 'm', 'پیاو'], true)) {
            $patientGender = 'male';
        } elseif (in_array($rawGender, ['female', 'مێ', 'f', 'ئافرەت', 'ژن'], true)) {
            $patientGender = 'female';
        } else {
            $patientGender = null;
        }

        $address = !empty($details['location'])
            ? $details['location']
            : (!empty($details['address'])
                ? $details['address']
                : (!empty($details['location_name'])
                    ? $details['location_name']
                    : (!empty($loc['address']) ? $loc['address'] : 'ناونیشان دیارینەکراوە')));

        $notes = !empty($details['notes'])
            ? $details['notes']
            : (!empty($details['description']) ? $details['description'] : 'هیچ تێبینییەک نەنوسراوە');

        $rawLat = $details['lat'] ?? $details['latitude'] ?? $loc['latitude'] ?? null;
        $rawLng = $details['lng'] ?? $details['longitude'] ?? $loc['longitude'] ?? null;
        $hasCoords = is_numeric($rawLat) && is_numeric($rawLng);
        $lat = $hasCoords ? (float) $rawLat : 36.1911;
        $lng = $hasCoords ? (float) $rawLng : 44.0092;

        $rawPayment = strtolower((string) ($order->payment_method ?? 'cash'));
        if (str_contains($rawPayment, 'delivery') || str_contains($rawPayment, 'cash') || str_contains($rawPayment, 'کاش')) {
            $paymentMethodKurdish = 'کاش لەکاتی وەرگرتن';
        } elseif (str_contains($rawPayment, 'fastpay')) {
            $paymentMethodKurdish = 'FastPay';
        } elseif (str_contains($rawPayment, 'fib')) {
            $paymentMethodKurdish = 'FIB بانکی یەکەمی عێراق';
        } elseif (str_contains($rawPayment, 'zain')) {
            $paymentMethodKurdish = 'Zain Cash';
        } else {
            $paymentMethodKurdish = $order->payment_method ?? 'کاش لەکاتی وەرگرتن';
        }

        $prescriptionImage = $details['prescription_image'] ?? $details['prescription_url'] ?? null;
        if (!$prescriptionImage && $order->items) {
            foreach ($order->items as $it) {
                $extra = is_array($it->extra_data) ? $it->extra_data : (json_decode($it->extra_data, true) ?? []);
                if (!empty($extra['prescription_url'])) {
                    $prescriptionImage = $extra['prescription_url'];
                    break;
                }
                if (!empty($extra['prescription_image'])) {
                    $prescriptionImage = $extra['prescription_image'];
                    break;
                }
                if (!empty($extra['prescription_path'])) {
                    $prescriptionImage = $extra['prescription_path'];
                    break;
                }
            }
        }

        $fullPrescUrl = null;
        if ($prescriptionImage) {
            if (str_starts_with($prescriptionImage, 'http://') || str_starts_with($prescriptionImage, 'https://')) {
                $fullPrescUrl = $prescriptionImage;
            } elseif (str_starts_with($prescriptionImage, 'storage/')) {
                $fullPrescUrl = asset($prescriptionImage);
            } else {
                $fullPrescUrl = asset('storage/' . ltrim($prescriptionImage, '/'));
            }
        }

        $estLabels = $order->estimatedDurationLabels();
        $localCreatedAt = $order->created_at?->timezone('Asia/Baghdad');

        return [
            'id' => $order->id,
            'date' => $localCreatedAt?->format('Y-m-d h:i A') ?? '',
            'name' => $patientName,
            'phone' => $patientPhone,
            'age' => $patientAge,
            'gender' => $patientGender,
            'address' => $address,
            'notes' => $notes,
            'payment_method' => $paymentMethodKurdish,
            'total_price' => number_format((float) $order->total_price, 0),
            'status' => $statusLabelsMap[$order->status] ?? $order->status,
            'estimated_duration_label' => $estLabels['ckb'] ?? null,
            'lat' => $lat,
            'lng' => $lng,
            'has_coords' => $hasCoords,
            'prescription_image' => $fullPrescUrl,
            'items' => ($order->items ?? collect())->map(fn ($it) => [
                'item_name' => $it->item_name,
                'price' => (float) ($it->price ?? 0),
                'quantity' => (int) ($it->quantity ?? 1),
            ])->values()->all(),
        ];
    };
@endphp

<style>
    .status-select {
        font-size: 0.8rem;
        font-weight: 800;
        padding: 7px 12px;
        border-radius: 12px;
        cursor: pointer;
        border: 1px solid #e2e8f0;
        background: #ffffff;
        outline: none;
        transition: all 0.2s;
    }
    .status-pending { background: #fffbeb; color: #b45309; border-color: #fde68a; }
    .status-progress { background: #eff6ff; color: #1d4ed8; border-color: #bfdbfe; }
    .status-completed { background: #ecfdf5; color: #047857; border-color: #a7f3d0; }
    .status-cancelled { background: #fef2f2; color: #b91c1c; border-color: #fecaca; }

    .btn-view-details {
        background: #f0fdfa;
        color: #0f766e;
        border: 1px solid #99f6e4;
        padding: 7px 13px;
        border-radius: 10px;
        font-size: 0.76rem;
        font-weight: 800;
        cursor: pointer;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        gap: 6px;
        transition: all 0.2s;
        white-space: nowrap;
    }
    .btn-view-details:hover {
        background: #0d9488;
        color: #ffffff;
        border-color: #0d9488;
    }
    #orderModalMap {
        height: 220px;
        width: 100%;
        border-radius: 14px;
        border: 1px solid #cbd5e1;
        z-index: 1;
    }
</style>

<div class="fade-up">
    <!-- Header -->
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:24px;">
        <div>
            <h1 style="font-size:1.5rem;font-weight:800;color:#0f172a;margin:0 0 4px;">لیستی چاوپێکەوتنەکان</h1>
            <p style="margin:0;color:#64748b;font-size:0.9rem;">بەڕێوەبردنی سەردانەکان، دۆخ و کاتی چاوەڕوانی بۆ نەخۆشەکان</p>
        </div>
    </div>

    @if(session('success'))
        <div style="margin-bottom:16px;padding:12px 18px;background:#ecfdf5;border:1px solid #a7f3d0;color:#047857;border-radius:14px;font-weight:700;font-size:0.85rem;display:flex;align-items:center;gap:8px;">
            <svg style="width:18px;height:18px;flex-shrink:0;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
            <span>{{ session('success') }}</span>
        </div>
    @endif

    @if(session('error'))
        <div style="margin-bottom:16px;padding:12px 18px;background:#fef2f2;border:1px solid #fecaca;color:#b91c1c;border-radius:14px;font-weight:700;font-size:0.85rem;">
            {{ session('error') }}
        </div>
    @endif

    <!-- Active Appointments (Assigned to this nurse) -->
    <div style="background:#fff;border-radius:16px;border:1px solid #e2e8f0;overflow:hidden;margin-bottom:24px;">
        <div style="padding:20px 24px;border-bottom:1px solid #f1f5f9;display:flex;justify-content:space-between;align-items:center;">
            <h3 style="margin:0;font-size:1.1rem;font-weight:700;color:#0f172a;">چاوپێکەوتنەکانی من</h3>
            <span style="background:#f0fdfa;color:#0d9488;padding:4px 12px;border-radius:20px;font-size:0.8rem;font-weight:700;">{{ $appointments->total() }} چاوپێکەوتن</span>
        </div>
        
        @if($appointments->count() > 0)
            <!-- Mobile Cards -->
            <div class="md:hidden divide-y divide-slate-100">
                @foreach($appointments as $app)
                    @php
                        $localAppCreatedAt = $app->created_at?->timezone('Asia/Baghdad');
                        $orderPayload = $buildNurseOrderPayload($app);
                        $estPresets = [15, 30, 45, 60, 90, 120, 180, 240, 360, 720, 1440, 2880];
                        $currentEst = $app->estimated_duration_minutes;
                        $isCustomEst = $currentEst !== null && !in_array((int) $currentEst, $estPresets, true);
                    @endphp
                    <div class="p-4 space-y-3">
                        <div class="flex items-start justify-between gap-3">
                            <div class="flex items-center gap-3 min-w-0">
                                <div class="w-10 h-10 rounded-full bg-sky-100 text-sky-700 flex items-center justify-center font-bold shrink-0">
                                    {{ mb_substr($app->patient->name ?? 'ن', 0, 1) }}
                                </div>
                                <div class="min-w-0">
                                    <div class="text-sm font-bold text-slate-900 truncate">{{ $app->patient->name ?? 'نەخۆش' }}</div>
                                    <div class="text-xs text-slate-500 mt-0.5" dir="ltr" style="text-align:right;">
                                        {{ $localAppCreatedAt?->format('Y-m-d') }} • {{ $localAppCreatedAt?->format('h:i A') }}
                                    </div>
                                </div>
                            </div>
                            <span class="text-sm font-extrabold text-emerald-600 whitespace-nowrap">{{ number_format($app->total_price, 0) }} د.ع</span>
                        </div>

                        @if($app->items && $app->items->count() > 0)
                            <div class="flex flex-wrap gap-1.5">
                                @foreach($app->items as $item)
                                    <span class="bg-slate-100 text-slate-700 px-2.5 py-1 rounded-md text-xs font-semibold">{{ $item->item_name }}</span>
                                @endforeach
                            </div>
                        @endif

                        <div class="flex flex-wrap items-center justify-between gap-2 text-xs text-slate-600">
                            <div>
                                <span>{{ $orderPayload['address'] }}</span>
                                @if(!empty($orderPayload['phone']) && $orderPayload['phone'] !== 'نەزانراو')
                                    <span class="mx-1 text-slate-300">•</span>
                                    <span dir="ltr" class="inline-block">{{ $orderPayload['phone'] }}</span>
                                @endif
                            </div>
                            @if($orderPayload['prescription_image'])
                                <a href="{{ $orderPayload['prescription_image'] }}" target="_blank" class="inline-flex items-center gap-1 bg-emerald-50 text-teal-700 px-2 py-1 rounded-md font-bold border border-emerald-200">
                                    وێنەی ڕەچەتە
                                </a>
                            @endif
                        </div>

                        <form id="mobile-nurse-order-status-form-{{ $app->id }}" action="{{ route('nurse.appointments.update_status', $app->id) }}" method="POST" class="space-y-2 pt-1">
                            @csrf
                            @method('PATCH')
                            <select name="status" onchange="this.form.submit()"
                                    class="status-select w-full @if($app->status == 'pending') status-pending @elseif(in_array($app->status, ['approved', 'confirmed', 'processing', 'in_progress', 'on_the_way'])) status-progress @elseif($app->status == 'completed') status-completed @else status-cancelled @endif">
                                @if($app->status == 'pending')
                                    <option value="pending" selected>⏳ چاوەڕوانە</option>
                                @endif
                                <option value="on_the_way" {{ $app->status == 'on_the_way' ? 'selected' : '' }}>🚗 لە ڕێگادایە</option>
                                <option value="processing" {{ in_array($app->status, ['processing', 'in_progress', 'approved', 'confirmed']) ? 'selected' : '' }}>🩺 قبوڵکرا / لە کاردایە</option>
                                <option value="completed" {{ $app->status == 'completed' ? 'selected' : '' }}>✅ تەواوکراوە</option>
                                <option value="cancelled" {{ $app->status == 'cancelled' ? 'selected' : '' }}>❌ ڕەتکرایەوە</option>
                            </select>

                            <select id="mobile-nurse-est-preset-{{ $app->id }}"
                                    onchange="handleNurseEstPresetChange({{ $app->id }}, this, 'mobile-')"
                                    class="w-full text-xs font-bold px-3 py-2 rounded-xl border border-slate-300 bg-slate-50 text-slate-700 outline-none">
                                <option value="" {{ $currentEst === null ? 'selected' : '' }}>⏱ دیاریکردنی کات...</option>
                                <option value="15" {{ (int)$currentEst === 15 ? 'selected' : '' }}>⏱ ١٥ خولەک</option>
                                <option value="30" {{ (int)$currentEst === 30 ? 'selected' : '' }}>⏱ ٣٠ خولەک</option>
                                <option value="45" {{ (int)$currentEst === 45 ? 'selected' : '' }}>⏱ ٤٥ خولەک</option>
                                <option value="60" {{ (int)$currentEst === 60 ? 'selected' : '' }}>⏱ ١ کاتژمێر</option>
                                <option value="90" {{ (int)$currentEst === 90 ? 'selected' : '' }}>⏱ ١ کاتژمێر و ٣٠ خولەک</option>
                                <option value="120" {{ (int)$currentEst === 120 ? 'selected' : '' }}>⏱ ٢ کاتژمێر</option>
                                <option value="180" {{ (int)$currentEst === 180 ? 'selected' : '' }}>⏱ ٣ کاتژمێر</option>
                                <option value="240" {{ (int)$currentEst === 240 ? 'selected' : '' }}>⏱ ٤ کاتژمێر</option>
                                <option value="360" {{ (int)$currentEst === 360 ? 'selected' : '' }}>⏱ ٦ کاتژمێر</option>
                                <option value="720" {{ (int)$currentEst === 720 ? 'selected' : '' }}>⏱ ١٢ کاتژمێر</option>
                                <option value="1440" {{ (int)$currentEst === 1440 ? 'selected' : '' }}>⏱ ٢٤ کاتژمێر (١ ڕۆژ)</option>
                                <option value="2880" {{ (int)$currentEst === 2880 ? 'selected' : '' }}>⏱ ٤٨ کاتژمێر (٢ ڕۆژ)</option>
                                <option value="custom" {{ $isCustomEst ? 'selected' : '' }}>✏️ کاتی تر (بە خولەک)...</option>
                            </select>

                            <div id="mobile-nurse-est-custom-box-{{ $app->id }}" style="display:{{ $isCustomEst ? 'flex' : 'none' }};align-items:center;gap:6px;">
                                <input type="number"
                                       id="mobile-nurse-est-minutes-{{ $app->id }}"
                                       name="estimated_duration_minutes"
                                       min="1"
                                       max="43200"
                                       value="{{ $currentEst }}"
                                       placeholder="خولەک (نم: 90)"
                                       class="w-full text-xs font-bold px-3 py-2 rounded-lg border border-slate-400 bg-white text-slate-900 outline-none" />
                                <button type="submit"
                                        class="bg-slate-900 text-white px-3 py-2 rounded-lg text-xs font-extrabold whitespace-nowrap">
                                    پاشەکەوت
                                </button>
                            </div>
                        </form>

                        <button type="button" onclick='openNurseOrderModal(@json($orderPayload))' class="btn-view-details w-full">
                            <svg style="width: 15px; height: 15px;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                            بینینی زانیاری تەواو
                        </button>
                    </div>
                @endforeach
            </div>

            <!-- Desktop Table -->
            <div class="hidden md:block overflow-x-auto">
                <table class="w-full border-collapse text-right">
                    <thead>
                        <tr class="bg-slate-50 border-b border-slate-200">
                            <th class="px-3 lg:px-4 py-3.5 text-xs font-bold text-slate-500 whitespace-nowrap">نەخۆش</th>
                            <th class="px-3 lg:px-4 py-3.5 text-xs font-bold text-slate-500 whitespace-nowrap">خزمەتگوزارییەکان</th>
                            <th class="px-3 lg:px-4 py-3.5 text-xs font-bold text-slate-500 whitespace-nowrap">کات و بەروار</th>
                            <th class="px-3 lg:px-4 py-3.5 text-xs font-bold text-slate-500 whitespace-nowrap">ناونیشان / ژ.مۆبایل</th>
                            <th class="px-3 lg:px-4 py-3.5 text-xs font-bold text-slate-500 whitespace-nowrap">نرخ</th>
                            <th class="px-3 lg:px-4 py-3.5 text-xs font-bold text-slate-500 whitespace-nowrap">دۆخ و کاتی چاوەڕوانی</th>
                            <th class="px-3 lg:px-4 py-3.5 text-xs font-bold text-slate-500 whitespace-nowrap text-center">وردەکاری</th>
                        </tr>
                    </thead>
                    <tbody>
                    @foreach($appointments as $app)
                        @php
                            $localAppCreatedAt = $app->created_at?->timezone('Asia/Baghdad');
                            $orderPayload = $buildNurseOrderPayload($app);
                            $estPresets = [15, 30, 45, 60, 90, 120, 180, 240, 360, 720, 1440, 2880];
                            $currentEst = $app->estimated_duration_minutes;
                            $isCustomEst = $currentEst !== null && !in_array((int) $currentEst, $estPresets, true);
                        @endphp
                        <tr class="border-b border-slate-100 hover:bg-slate-50 transition-colors">
                            <td class="px-3 lg:px-4 py-3.5">
                                <div class="flex items-center gap-2.5">
                                    <div class="w-9 h-9 rounded-full bg-sky-100 text-sky-700 flex items-center justify-center font-bold text-sm shrink-0">
                                        {{ mb_substr($app->patient->name ?? 'ن', 0, 1) }}
                                    </div>
                                    <div class="text-sm font-bold text-slate-900">{{ $app->patient->name ?? 'نەخۆش' }}</div>
                                </div>
                            </td>
                            <td class="px-3 lg:px-4 py-3.5">
                                <div class="flex flex-wrap gap-1.5">
                                    @if($app->items && $app->items->count() > 0)
                                        @foreach($app->items as $item)
                                            <span class="bg-slate-100 text-slate-600 px-2 py-1 rounded-md text-xs font-semibold">
                                                {{ $item->item_name }}
                                            </span>
                                        @endforeach
                                    @else
                                        <span class="text-slate-400 text-xs">دیارینەکراوە</span>
                                    @endif
                                </div>
                            </td>
                            <td class="px-3 lg:px-4 py-3.5 whitespace-nowrap">
                                <div class="text-xs text-slate-700 font-semibold whitespace-nowrap" dir="ltr" style="text-align:right;">{{ $localAppCreatedAt?->format('Y-m-d') }}</div>
                                <div class="text-[11px] text-slate-400 whitespace-nowrap" dir="ltr" style="text-align:right;">{{ $localAppCreatedAt?->format('h:i A') }}</div>
                            </td>
                            <td class="px-3 lg:px-4 py-3.5">
                                <div class="text-xs text-slate-700">{{ $orderPayload['address'] }}</div>
                                @if(!empty($orderPayload['phone']) && $orderPayload['phone'] !== 'نەزانراو')
                                    <div class="text-[11px] text-slate-500 whitespace-nowrap" dir="ltr" style="text-align:right;">{{ $orderPayload['phone'] }}</div>
                                @endif
                                @if($orderPayload['prescription_image'])
                                    <div class="mt-1.5">
                                        <a href="{{ $orderPayload['prescription_image'] }}" target="_blank" class="inline-flex items-center gap-1 bg-emerald-50 text-teal-700 px-2 py-0.5 rounded-md text-[11px] font-bold border border-emerald-200">
                                            <svg width="12" height="12" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                                            وێنەی ڕەچەتە
                                        </a>
                                    </div>
                                @endif
                            </td>
                            <td class="px-3 lg:px-4 py-3.5 whitespace-nowrap">
                                <div class="text-sm font-bold text-emerald-600 whitespace-nowrap">{{ number_format($app->total_price, 0) }} د.ع</div>
                            </td>
                            <td class="px-3 lg:px-4 py-3.5">
                                <form id="nurse-order-status-form-{{ $app->id }}" action="{{ route('nurse.appointments.update_status', $app->id) }}" method="POST" class="m-0 flex flex-col gap-1.5 w-full max-w-[190px]">
                                    @csrf
                                    @method('PATCH')
                                    <select name="status" onchange="this.form.submit()"
                                            class="status-select w-full max-w-full @if($app->status == 'pending') status-pending @elseif(in_array($app->status, ['approved', 'confirmed', 'processing', 'in_progress', 'on_the_way'])) status-progress @elseif($app->status == 'completed') status-completed @else status-cancelled @endif">
                                        @if($app->status == 'pending')
                                            <option value="pending" selected>⏳ چاوەڕوانە</option>
                                        @endif
                                        <option value="on_the_way" {{ $app->status == 'on_the_way' ? 'selected' : '' }}>🚗 لە ڕێگادایە</option>
                                        <option value="processing" {{ in_array($app->status, ['processing', 'in_progress', 'approved', 'confirmed']) ? 'selected' : '' }}>🩺 قبوڵکرا / لە کاردایە</option>
                                        <option value="completed" {{ $app->status == 'completed' ? 'selected' : '' }}>✅ تەواوکراوە</option>
                                        <option value="cancelled" {{ $app->status == 'cancelled' ? 'selected' : '' }}>❌ ڕەتکرایەوە</option>
                                    </select>

                                    <select id="nurse-est-preset-{{ $app->id }}"
                                            onchange="handleNurseEstPresetChange({{ $app->id }}, this, '')"
                                            class="w-full max-w-full text-xs font-bold px-2.5 py-1.5 rounded-lg border border-slate-300 bg-slate-50 text-slate-700 cursor-pointer outline-none truncate">
                                        <option value="" {{ $currentEst === null ? 'selected' : '' }}>⏱ دیاریکردنی کات...</option>
                                        <option value="15" {{ (int)$currentEst === 15 ? 'selected' : '' }}>⏱ ١٥ خولەک</option>
                                        <option value="30" {{ (int)$currentEst === 30 ? 'selected' : '' }}>⏱ ٣٠ خولەک</option>
                                        <option value="45" {{ (int)$currentEst === 45 ? 'selected' : '' }}>⏱ ٤٥ خولەک</option>
                                        <option value="60" {{ (int)$currentEst === 60 ? 'selected' : '' }}>⏱ ١ کاتژمێر</option>
                                        <option value="90" {{ (int)$currentEst === 90 ? 'selected' : '' }}>⏱ ١ کاتژمێر و ٣٠ خولەک</option>
                                        <option value="120" {{ (int)$currentEst === 120 ? 'selected' : '' }}>⏱ ٢ کاتژمێر</option>
                                        <option value="180" {{ (int)$currentEst === 180 ? 'selected' : '' }}>⏱ ٣ کاتژمێر</option>
                                        <option value="240" {{ (int)$currentEst === 240 ? 'selected' : '' }}>⏱ ٤ کاتژمێر</option>
                                        <option value="360" {{ (int)$currentEst === 360 ? 'selected' : '' }}>⏱ ٦ کاتژمێر</option>
                                        <option value="720" {{ (int)$currentEst === 720 ? 'selected' : '' }}>⏱ ١٢ کاتژمێر</option>
                                        <option value="1440" {{ (int)$currentEst === 1440 ? 'selected' : '' }}>⏱ ٢٤ کاتژمێر (١ ڕۆژ)</option>
                                        <option value="2880" {{ (int)$currentEst === 2880 ? 'selected' : '' }}>⏱ ٤٨ کاتژمێر (٢ ڕۆژ)</option>
                                        <option value="custom" {{ $isCustomEst ? 'selected' : '' }}>✏️ کاتی تر (بە خولەک)...</option>
                                    </select>

                                    <div id="nurse-est-custom-box-{{ $app->id }}" style="display:{{ $isCustomEst ? 'flex' : 'none' }};align-items:center;gap:4px;">
                                        <input type="number"
                                               id="nurse-est-minutes-{{ $app->id }}"
                                               name="estimated_duration_minutes"
                                               min="1"
                                               max="43200"
                                               value="{{ $currentEst }}"
                                               placeholder="خولەک"
                                               class="w-full min-w-0 text-xs font-bold px-2 py-1 rounded-lg border border-slate-400 bg-white text-slate-900 outline-none" />
                                        <button type="submit"
                                                class="bg-slate-900 text-white px-2.5 py-1 rounded-lg text-[11px] font-extrabold whitespace-nowrap shrink-0">
                                            پاشەکەوت
                                        </button>
                                    </div>
                                </form>
                            </td>
                            <td class="px-3 lg:px-4 py-3.5 text-center">
                                <button type="button" onclick='openNurseOrderModal(@json($orderPayload))' class="btn-view-details">
                                    <svg style="width: 15px; height: 15px;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                                    بینینی زانیاری تەواو
                                </button>
                            </td>
                        </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
            <div style="padding:16px 24px;border-top:1px solid #f1f5f9;">
                {{ $appointments->links() }}
            </div>
        @else
            <div style="padding:40px;text-align:center;">
                <svg width="48" height="48" fill="none" stroke="#94a3b8" viewBox="0 0 24 24" style="margin:0 auto 16px;"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/></svg>
                <h3 style="margin:0 0 8px;font-size:1.1rem;color:#1e293b;font-weight:700;">هیچ چاوپێکەوتنێکت نییە</h3>
                <p style="margin:0;color:#64748b;font-size:0.9rem;">کاتێک داواکارییەک وەردەگریت لێرە دەردەکەوێت.</p>
            </div>
        @endif
    </div>

    <!-- Unassigned Requests (Pending) -->
    @if(isset($unassignedRequests) && $unassignedRequests->count() > 0)
    <div style="background:#fff;border-radius:16px;border:1px solid #fcd34d;overflow:hidden;box-shadow:0 10px 25px -5px rgba(251,191,36,0.1);">
        <div style="padding:20px 24px;background:#fffbeb;border-bottom:1px solid #fde68a;display:flex;justify-content:space-between;align-items:center;">
            <h3 style="margin:0;font-size:1.1rem;font-weight:700;color:#b45309;">داواکارییە نوێیەکان (کە پەرستاریان نییە)</h3>
            <span style="background:#fef3c7;color:#b45309;padding:4px 12px;border-radius:20px;font-size:0.8rem;font-weight:700;">{{ $unassignedRequests->count() }} داواکاری</span>
        </div>
        
        <!-- Mobile Cards (Unassigned Requests) -->
        <div class="md:hidden divide-y divide-amber-100">
            @foreach($unassignedRequests as $req)
                @php
                    $localReqCreatedAt = $req->created_at?->timezone('Asia/Baghdad');
                    $reqPayload = $buildNurseOrderPayload($req);
                @endphp
                <div class="p-4 space-y-3 bg-white">
                    <div class="flex items-start justify-between gap-3">
                        <div class="min-w-0">
                            <div class="text-sm font-bold text-slate-900 truncate">{{ $req->patient->name ?? 'نەخۆش' }}</div>
                            <div class="text-xs text-slate-500 mt-0.5" dir="ltr" style="text-align:right;">
                                {{ $localReqCreatedAt?->format('Y-m-d') }} • {{ $localReqCreatedAt?->format('h:i A') }}
                            </div>
                        </div>
                        <span class="text-sm font-extrabold text-amber-700 whitespace-nowrap">{{ number_format($req->total_price, 0) }} د.ع</span>
                    </div>

                    @if($req->items && $req->items->count() > 0)
                        <div class="flex flex-wrap gap-1.5">
                            @foreach($req->items as $item)
                                <span class="bg-amber-100 text-amber-800 px-2.5 py-1 rounded-md text-xs font-semibold">{{ $item->item_name }}</span>
                            @endforeach
                        </div>
                    @endif

                    <div class="flex flex-wrap items-center justify-between gap-2 text-xs text-slate-600">
                        <span>{{ $reqPayload['address'] }}</span>
                        @if($reqPayload['prescription_image'])
                            <a href="{{ $reqPayload['prescription_image'] }}" target="_blank" class="inline-flex items-center gap-1 bg-amber-100 text-amber-800 px-2 py-1 rounded-md font-bold border border-amber-200">
                                وێنەی ڕەچەتە
                            </a>
                        @endif
                    </div>

                    <form action="{{ route('nurse.appointments.accept', $req->id) }}" method="POST" class="flex flex-col gap-2 pt-1">
                        @csrf
                        <select name="estimated_duration_minutes" class="w-full text-xs font-bold px-3 py-2 rounded-lg border border-amber-200 bg-amber-50 text-amber-900 outline-none">
                            <option value="">⏱ کاتی گەیشتن (ئارەزوومەندانە)</option>
                            <option value="15">⏱ ١٥ خولەک</option>
                            <option value="30">⏱ ٣٠ خولەک</option>
                            <option value="45">⏱ ٤٥ خولەک</option>
                            <option value="60">⏱ ١ کاتژمێر</option>
                            <option value="90">⏱ ١ کاتژمێر و ٣٠ خولەک</option>
                            <option value="120">⏱ ٢ کاتژمێر</option>
                        </select>
                        <button type="submit" class="w-full justify-center bg-amber-500 hover:bg-amber-600 text-white py-2 px-4 rounded-lg text-xs font-bold inline-flex items-center gap-1.5 transition-colors">
                            <svg width="14" height="14" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                            وەرگرتنی سەردان
                        </button>
                    </form>

                    <button type="button" onclick='openNurseOrderModal(@json($reqPayload))' class="btn-view-details w-full">
                        <svg style="width: 15px; height: 15px;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                        بینینی زانیاری تەواو
                    </button>
                </div>
            @endforeach
        </div>

        <!-- Desktop Table (Unassigned Requests) -->
        <div class="hidden md:block overflow-x-auto">
            <table class="w-full border-collapse text-right">
                <thead>
                    <tr class="bg-yellow-50/70 border-b border-amber-200">
                        <th class="px-3 lg:px-4 py-3.5 text-xs font-bold text-amber-900 whitespace-nowrap">نەخۆش</th>
                        <th class="px-3 lg:px-4 py-3.5 text-xs font-bold text-amber-900 whitespace-nowrap">خزمەتگوزارییەکان</th>
                        <th class="px-3 lg:px-4 py-3.5 text-xs font-bold text-amber-900 whitespace-nowrap">کات و بەروار</th>
                        <th class="px-3 lg:px-4 py-3.5 text-xs font-bold text-amber-900 whitespace-nowrap">ناونیشان</th>
                        <th class="px-3 lg:px-4 py-3.5 text-xs font-bold text-amber-900 whitespace-nowrap">نرخ</th>
                        <th class="px-3 lg:px-4 py-3.5 text-xs font-bold text-amber-900 whitespace-nowrap">کردارەکان</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach($unassignedRequests as $req)
                    @php
                        $localReqCreatedAt = $req->created_at?->timezone('Asia/Baghdad');
                        $reqPayload = $buildNurseOrderPayload($req);
                    @endphp
                    <tr class="border-b border-amber-100 bg-white">
                        <td class="px-3 lg:px-4 py-3.5">
                            <div class="text-sm font-bold text-slate-900">{{ $req->patient->name ?? 'نەخۆش' }}</div>
                        </td>
                        <td class="px-3 lg:px-4 py-3.5">
                            <div class="flex flex-wrap gap-1.5">
                                @if($req->items && $req->items->count() > 0)
                                    @foreach($req->items as $item)
                                        <span class="bg-amber-100 text-amber-800 px-2 py-1 rounded-md text-xs font-semibold">
                                            {{ $item->item_name }}
                                        </span>
                                    @endforeach
                                @endif
                            </div>
                        </td>
                        <td class="px-3 lg:px-4 py-3.5 whitespace-nowrap">
                            <div class="text-xs text-slate-700 font-semibold whitespace-nowrap" dir="ltr" style="text-align:right;">{{ $localReqCreatedAt?->format('Y-m-d') }}</div>
                            <div class="text-[11px] text-slate-400 whitespace-nowrap" dir="ltr" style="text-align:right;">{{ $localReqCreatedAt?->format('h:i A') }}</div>
                        </td>
                        <td class="px-3 lg:px-4 py-3.5">
                            <div class="text-xs text-slate-700">{{ $reqPayload['address'] }}</div>
                            @if($reqPayload['prescription_image'])
                                <div class="mt-1.5">
                                    <a href="{{ $reqPayload['prescription_image'] }}" target="_blank" class="inline-flex items-center gap-1 bg-amber-100 text-amber-800 px-2 py-0.5 rounded-md text-[11px] font-bold border border-amber-200">
                                        <svg width="12" height="12" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                                        وێنەی ڕەچەتە
                                    </a>
                                </div>
                            @endif
                        </td>
                        <td class="px-3 lg:px-4 py-3.5 whitespace-nowrap">
                            <div class="text-sm font-bold text-amber-700 whitespace-nowrap">{{ number_format($req->total_price, 0) }} د.ع</div>
                        </td>
                        <td class="px-3 lg:px-4 py-3.5">
                            <div class="flex flex-col gap-1.5 w-full max-w-[190px]">
                                <form action="{{ route('nurse.appointments.accept', $req->id) }}" method="POST" class="flex flex-col gap-1.5">
                                    @csrf
                                    <select name="estimated_duration_minutes" class="w-full max-w-full text-xs font-bold px-2 py-1.5 rounded-lg border border-amber-200 bg-amber-50 text-amber-900 cursor-pointer outline-none truncate">
                                        <option value="">⏱ کاتی گەیشتن...</option>
                                        <option value="15">⏱ ١٥ خولەک</option>
                                        <option value="30">⏱ ٣٠ خولەک</option>
                                        <option value="45">⏱ ٤٥ خولەک</option>
                                        <option value="60">⏱ ١ کاتژمێر</option>
                                        <option value="90">⏱ ١ کاتژمێر و ٣٠ خولەک</option>
                                        <option value="120">⏱ ٢ کاتژمێر</option>
                                    </select>
                                    <button type="submit" class="w-full justify-center bg-amber-500 hover:bg-amber-600 text-white py-1.5 px-3 rounded-lg text-xs font-bold inline-flex items-center gap-1.5 whitespace-nowrap transition-colors">
                                        <svg width="14" height="14" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                                        وەرگرتنی سەردان
                                    </button>
                                </form>
                                <button type="button" onclick='openNurseOrderModal(@json($reqPayload))' class="btn-view-details w-full">
                                    <svg style="width: 15px; height: 15px;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                                    بینینی زانیاری تەواو
                                </button>
                            </div>
                        </td>
                    </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    </div>
    @endif
</div>

<!-- Detailed Appointment Modal with In-App Leaflet Map -->
<div id="orderModal" onclick="if (event.target === this) closeNurseOrderModal()" style="position: fixed; inset: 0; z-index: 999; background: rgba(15,23,42,0.65); backdrop-filter: blur(5px); display: none; align-items: center; justify-content: center; padding: 16px;">
    <div style="background: #ffffff; border-radius: 24px; max-width: 700px; width: 100%; max-height: 90vh; overflow-y: auto; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.25); padding: 26px; direction: rtl; text-align: right; border: 1px solid #e2e8f0;">
        <!-- Modal Header -->
        <div style="display: flex; align-items: center; justify-content: space-between; border-bottom: 1px solid #f1f5f9; padding-bottom: 16px;">
            <div>
                <div style="display: flex; align-items: center; gap: 8px;">
                    <h3 style="font-size: 1.15rem; font-weight: 900; color: #0f172a; margin: 0;">وردەکاری تەواوی سەردان</h3>
                    <span id="modalOrderIdBadge" style="background: #0d9488; color: #ffffff; font-family: monospace; font-size: 0.8rem; font-weight: 800; padding: 3px 8px; border-radius: 6px;"></span>
                </div>
                <p style="font-size: 0.78rem; color: #64748b; margin: 3px 0 0 0;" id="modalSubtitle"></p>
            </div>
            <button type="button" onclick="closeNurseOrderModal()" style="width: 34px; height: 34px; border-radius: 50%; background: #f1f5f9; border: none; color: #64748b; font-weight: 700; cursor: pointer; display: flex; align-items: center; justify-content: center; font-size: 1rem;">
                ✕
            </button>
        </div>

        <!-- Modal Dynamic Content -->
        <div id="modalContent" style="display: flex; flex-direction: column; gap: 14px; margin-top: 18px; font-size: 0.85rem;"></div>

        <!-- Interactive Map Inside Modal -->
        <div style="margin-top: 14px;">
            <div style="font-size: 0.8rem; font-weight: 800; color: #334155; margin-bottom: 8px; display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 6px;">
                <span>🗺️ شوێنی نەخۆش لەسەر نەخشە</span>
                <a id="modalGoogleMapsLink" href="#" target="_blank" style="font-size: 0.75rem; font-weight: 800; color: #0d9488; text-decoration: none;">
                    کردنەوە لە Google Maps ↗
                </a>
            </div>
            <div id="orderModalMap"></div>
        </div>

        <!-- Modal Footer -->
        <div style="border-top: 1px solid #f1f5f9; margin-top: 22px; padding-top: 16px; display: flex; align-items: center; justify-content: flex-end; gap: 12px;">
            <button type="button" onclick="closeNurseOrderModal()" style="padding: 9px 24px; background: #f1f5f9; color: #334155; font-weight: 800; border-radius: 12px; border: none; cursor: pointer; font-size: 0.82rem;">
                داخستن
            </button>
        </div>
    </div>
</div>

<script>
let nurseLeafletMap = null;
let nurseLeafletMarker = null;

function escapeHtml(value) {
    return String(value ?? '')
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
}

function openNurseOrderModal(data) {
    const modal = document.getElementById('orderModal');
    const content = document.getElementById('modalContent');
    const badge = document.getElementById('modalOrderIdBadge');
    const subtitle = document.getElementById('modalSubtitle');
    const gmapsLink = document.getElementById('modalGoogleMapsLink');

    badge.textContent = `#ORD-${data.id}`;
    subtitle.textContent = `بەروار و کاتی تۆمارکردن: ${data.date || '-'}`;

    const genderText = data.gender === 'female' ? 'مێ (Female)' : (data.gender === 'male' ? 'نێر (Male)' : 'دیارینەکراو');
    const ageText = data.age ? `${escapeHtml(data.age)} ساڵ` : 'دیارینەکراو';

    let itemsHtml = '';
    if (data.items && data.items.length > 0) {
        itemsHtml = data.items.map(it => {
            const qty = Number(it.quantity || 1);
            const qtySuffix = qty > 1 ? ` ×${qty}` : '';
            return `
                <div style="display: flex; align-items: center; justify-content: space-between; padding: 10px 14px; background: #ffffff; border-radius: 10px; border: 1px solid #e2e8f0; font-size: 0.82rem; margin-bottom: 8px;">
                    <span style="font-weight: 800; color: #1e293b;">🩺 ${escapeHtml(it.item_name)}${qtySuffix}</span>
                    <span style="font-weight: 800; color: #0d9488;" dir="ltr">${Number(it.price || 0).toLocaleString()} د.ع</span>
                </div>
            `;
        }).join('');
    } else {
        itemsHtml = '<div style="font-size: 0.8rem; color: #94a3b8; padding: 10px;">خزمەتگوزاری پەرستاری گشتی</div>';
    }

    const phoneHtml = (data.phone && data.phone !== 'نەزانراو')
        ? `<a href="tel:${escapeHtml(data.phone)}" style="color: #0d9488; font-weight: 800; text-decoration: none; font-size: 0.9rem;" dir="ltr">📞 ${escapeHtml(data.phone)}</a>`
        : `<strong style="color: #64748b;">نەزانراو</strong>`;

    const prescHtml = data.prescription_image ? `
        <div style="background: #fff1f2; padding: 18px; border-radius: 16px; border: 1.5px solid #fecdd3;">
            <div style="font-size: 0.82rem; font-weight: 900; color: #be123c; margin-bottom: 10px; display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 8px;">
                <span>📸 وێنەی ڕەچەتە / پەڕاوی پزیشکی</span>
                <a href="${escapeHtml(data.prescription_image)}" target="_blank" download style="background: #be123c; color: #ffffff; padding: 5px 12px; border-radius: 8px; font-size: 0.75rem; font-weight: 800; text-decoration: none;">
                    داگرتن / بینین بە تەواوی ↗
                </a>
            </div>
            <div style="text-align: center; background: #ffffff; padding: 12px; border-radius: 12px; border: 1px solid #ffe4e6;">
                <a href="${escapeHtml(data.prescription_image)}" target="_blank">
                    <img src="${escapeHtml(data.prescription_image)}" style="max-height: 260px; width: auto; max-width: 100%; border-radius: 8px; object-fit: contain;" alt="وێنەی ڕەچەتە" />
                </a>
            </div>
        </div>
    ` : '';

    content.innerHTML = `
        <div style="background: #f0fdfa; padding: 16px; border-radius: 16px; border: 1px solid #ccfbf1;">
            <div style="font-size: 0.78rem; font-weight: 800; color: #0f766e; margin-bottom: 8px;">👤 زانیاری تەواوی نەخۆش</div>
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(130px, 1fr)); gap: 12px;">
                <div>
                    <span style="font-size: 0.72rem; color: #64748b; display: block;">ناوی نەخۆش:</span>
                    <strong style="color: #0f172a; font-size: 0.92rem;">${escapeHtml(data.name)}</strong>
                </div>
                <div>
                    <span style="font-size: 0.72rem; color: #64748b; display: block;">ژمارەی مۆبایل:</span>
                    ${phoneHtml}
                </div>
                <div>
                    <span style="font-size: 0.72rem; color: #64748b; display: block;">تەمەن:</span>
                    <strong style="color: #0f172a;">${ageText}</strong>
                </div>
                <div>
                    <span style="font-size: 0.72rem; color: #64748b; display: block;">ڕەگەز:</span>
                    <strong style="color: #0f172a;">${genderText}</strong>
                </div>
            </div>
        </div>

        <div style="background: #f8fafc; padding: 16px; border-radius: 16px; border: 1px solid #e2e8f0;">
            <div style="font-size: 0.78rem; font-weight: 800; color: #334155; margin-bottom: 8px;">📍 ناونیشان و تێبینی نەخۆش</div>
            <div style="font-size: 0.82rem; color: #334155; line-height: 1.7;">
                <div><strong>ناونیشان:</strong> <span style="font-weight: 700; color: #0f172a;">${escapeHtml(data.address)}</span></div>
                <div><strong>تێبینی نەخۆش:</strong> <span style="color: #64748b;">${escapeHtml(data.notes)}</span></div>
            </div>
        </div>

        <div style="background: #f8fafc; padding: 16px; border-radius: 16px; border: 1px solid #e2e8f0;">
            <div style="font-size: 0.78rem; font-weight: 800; color: #334155; margin-bottom: 8px;">💳 پارەدان و دۆخ</div>
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(140px, 1fr)); gap: 12px; font-size: 0.82rem;">
                <div>
                    <span style="font-size: 0.72rem; color: #64748b; display: block;">شێوازی پارەدان:</span>
                    <span style="color: #059669; font-weight: 800;">💵 ${escapeHtml(data.payment_method)}</span>
                </div>
                <div>
                    <span style="font-size: 0.72rem; color: #64748b; display: block;">کۆی گشتی نرخ:</span>
                    <strong style="color: #059669; font-size: 1rem;" dir="ltr">${escapeHtml(data.total_price)} د.ع</strong>
                </div>
                <div>
                    <span style="font-size: 0.72rem; color: #64748b; display: block;">بارودۆخ:</span>
                    <span style="color: #0d9488; font-weight: 800;">${escapeHtml(data.status)}</span>
                </div>
                <div>
                    <span style="font-size: 0.72rem; color: #64748b; display: block;">کاتی چاوەڕوانی:</span>
                    <span style="color: #0369a1; font-weight: 800;">⏱ ${escapeHtml(data.estimated_duration_label || 'دیارینەکراوە')}</span>
                </div>
            </div>
        </div>

        ${prescHtml}

        <div style="background: #f8fafc; padding: 16px; border-radius: 16px; border: 1px solid #e2e8f0;">
            <div style="font-size: 0.78rem; font-weight: 800; color: #334155; margin-bottom: 10px;">🩺 خزمەتگوزارییە داواکراوەکان</div>
            ${itemsHtml}
        </div>
    `;

    const lat = Number(data.lat || 36.1911);
    const lng = Number(data.lng || 44.0092);
    gmapsLink.href = `https://www.google.com/maps/search/?api=1&query=${lat},${lng}`;

    modal.style.display = 'flex';

    if (typeof L !== 'undefined') {
        setTimeout(() => {
            if (!nurseLeafletMap) {
                nurseLeafletMap = L.map('orderModalMap').setView([lat, lng], 14);
                L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                    attribution: '© OpenStreetMap contributors'
                }).addTo(nurseLeafletMap);
            } else {
                nurseLeafletMap.setView([lat, lng], 14);
                nurseLeafletMap.invalidateSize();
            }

            if (nurseLeafletMarker) {
                nurseLeafletMarker.setLatLng([lat, lng]);
            } else {
                nurseLeafletMarker = L.marker([lat, lng]).addTo(nurseLeafletMap);
            }

            nurseLeafletMarker.bindPopup(`<b>${escapeHtml(data.name)}</b><br>${escapeHtml(data.address)}`).openPopup();
            nurseLeafletMap.invalidateSize();
        }, 200);
    }
}

function closeNurseOrderModal() {
    document.getElementById('orderModal').style.display = 'none';
}

function handleNurseEstPresetChange(orderId, selectEl, prefix = '') {
    const val = selectEl.value;
    const customBox = document.getElementById(`${prefix}nurse-est-custom-box-${orderId}`);
    const inputEl = document.getElementById(`${prefix}nurse-est-minutes-${orderId}`);
    const formEl = document.getElementById(`${prefix}nurse-order-status-form-${orderId}`);
    if (!customBox || !inputEl || !formEl) return;

    if (val === 'custom') {
        customBox.style.display = 'flex';
        inputEl.focus();
        return;
    }

    customBox.style.display = 'none';
    inputEl.value = val;
    formEl.submit();
}
</script>
@endsection
