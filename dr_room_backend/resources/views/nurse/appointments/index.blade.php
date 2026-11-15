@extends('nurse.layouts.app')

@section('content')
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
                        $patientDetails = is_string($app->patient_details) ? json_decode($app->patient_details, true) : $app->patient_details;
                        $prescriptionImg = $patientDetails['prescription_image'] ?? $patientDetails['prescription_url'] ?? null;
                        $fullPrescUrl = $prescriptionImg
                            ? ((str_starts_with($prescriptionImg, 'http://') || str_starts_with($prescriptionImg, 'https://'))
                                ? $prescriptionImg
                                : (str_starts_with($prescriptionImg, 'storage/') ? asset($prescriptionImg) : asset('storage/' . ltrim($prescriptionImg, '/'))))
                            : null;
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
                                <span>{{ $patientDetails['location'] ?? 'ناونیشان دیارینەکراوە' }}</span>
                                @if(!empty($patientDetails['phone']))
                                    <span class="mx-1 text-slate-300">•</span>
                                    <span dir="ltr" class="inline-block">{{ $patientDetails['phone'] }}</span>
                                @endif
                            </div>
                            @if($fullPrescUrl)
                                <a href="{{ $fullPrescUrl }}" target="_blank" class="inline-flex items-center gap-1 bg-emerald-50 text-teal-700 px-2 py-1 rounded-md font-bold border border-emerald-200">
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
                        </tr>
                    </thead>
                    <tbody>
                    @foreach($appointments as $app)
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
                                @php $localAppCreatedAt = $app->created_at?->timezone('Asia/Baghdad'); @endphp
                                <div class="text-xs text-slate-700 font-semibold whitespace-nowrap" dir="ltr" style="text-align:right;">{{ $localAppCreatedAt?->format('Y-m-d') }}</div>
                                <div class="text-[11px] text-slate-400 whitespace-nowrap" dir="ltr" style="text-align:right;">{{ $localAppCreatedAt?->format('h:i A') }}</div>
                            </td>
                            <td class="px-3 lg:px-4 py-3.5">
                                @php
                                    $patientDetails = is_string($app->patient_details) ? json_decode($app->patient_details, true) : $app->patient_details;
                                    $prescriptionImg = $patientDetails['prescription_image'] ?? $patientDetails['prescription_url'] ?? null;
                                @endphp
                                <div class="text-xs text-slate-700">{{ $patientDetails['location'] ?? 'ناونیشان دیارینەکراوە' }}</div>
                                <div class="text-[11px] text-slate-500 whitespace-nowrap" dir="ltr" style="text-align:right;">{{ $patientDetails['phone'] ?? '' }}</div>
                                @if($prescriptionImg)
                                    @php
                                        $fullPrescUrl = (str_starts_with($prescriptionImg, 'http://') || str_starts_with($prescriptionImg, 'https://'))
                                            ? $prescriptionImg
                                            : (str_starts_with($prescriptionImg, 'storage/') ? asset($prescriptionImg) : asset('storage/' . ltrim($prescriptionImg, '/')));
                                    @endphp
                                    <div class="mt-1.5">
                                        <a href="{{ $fullPrescUrl }}" target="_blank" class="inline-flex items-center gap-1 bg-emerald-50 text-teal-700 px-2 py-0.5 rounded-md text-[11px] font-bold border border-emerald-200">
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
                                @php
                                    $estPresets = [15, 30, 45, 60, 90, 120, 180, 240, 360, 720, 1440, 2880];
                                    $currentEst = $app->estimated_duration_minutes;
                                    $isCustomEst = $currentEst !== null && !in_array((int) $currentEst, $estPresets, true);
                                @endphp
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
                    $patientDetails = is_string($req->patient_details) ? json_decode($req->patient_details, true) : $req->patient_details;
                    $reqPrescriptionImg = $patientDetails['prescription_image'] ?? $patientDetails['prescription_url'] ?? null;
                    $fullReqPrescUrl = $reqPrescriptionImg
                        ? ((str_starts_with($reqPrescriptionImg, 'http://') || str_starts_with($reqPrescriptionImg, 'https://'))
                            ? $reqPrescriptionImg
                            : (str_starts_with($reqPrescriptionImg, 'storage/') ? asset($reqPrescriptionImg) : asset('storage/' . ltrim($reqPrescriptionImg, '/'))))
                        : null;
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
                        <span>{{ $patientDetails['location'] ?? 'ناونیشان دیارینەکراوە' }}</span>
                        @if($fullReqPrescUrl)
                            <a href="{{ $fullReqPrescUrl }}" target="_blank" class="inline-flex items-center gap-1 bg-amber-100 text-amber-800 px-2 py-1 rounded-md font-bold border border-amber-200">
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
                            @php $localReqCreatedAt = $req->created_at?->timezone('Asia/Baghdad'); @endphp
                            <div class="text-xs text-slate-700 font-semibold whitespace-nowrap" dir="ltr" style="text-align:right;">{{ $localReqCreatedAt?->format('Y-m-d') }}</div>
                            <div class="text-[11px] text-slate-400 whitespace-nowrap" dir="ltr" style="text-align:right;">{{ $localReqCreatedAt?->format('h:i A') }}</div>
                        </td>
                        <td class="px-3 lg:px-4 py-3.5">
                            @php
                                $patientDetails = is_string($req->patient_details) ? json_decode($req->patient_details, true) : $req->patient_details;
                                $reqPrescriptionImg = $patientDetails['prescription_image'] ?? $patientDetails['prescription_url'] ?? null;
                            @endphp
                            <div class="text-xs text-slate-700">{{ $patientDetails['location'] ?? 'ناونیشان دیارینەکراوە' }}</div>
                            @if($reqPrescriptionImg)
                                @php
                                    $fullReqPrescUrl = (str_starts_with($reqPrescriptionImg, 'http://') || str_starts_with($reqPrescriptionImg, 'https://'))
                                        ? $reqPrescriptionImg
                                        : (str_starts_with($reqPrescriptionImg, 'storage/') ? asset($reqPrescriptionImg) : asset('storage/' . ltrim($reqPrescriptionImg, '/')));
                                @endphp
                                <div class="mt-1.5">
                                    <a href="{{ $fullReqPrescUrl }}" target="_blank" class="inline-flex items-center gap-1 bg-amber-100 text-amber-800 px-2 py-0.5 rounded-md text-[11px] font-bold border border-amber-200">
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
                            <form action="{{ route('nurse.appointments.accept', $req->id) }}" method="POST" class="flex flex-col gap-1.5 w-full max-w-[180px]">
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
                        </td>
                    </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    </div>
    @endif
</div>

<script>
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
