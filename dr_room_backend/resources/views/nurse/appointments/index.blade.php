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
            <div style="overflow-x:auto;">
                <table style="width:100%;border-collapse:collapse;text-align:right;">
                    <thead>
                        <tr style="background:#f8fafc;border-bottom:1px solid #e2e8f0;">
                            <th style="padding:16px 24px;font-size:0.8rem;font-weight:700;color:#64748b;white-space:nowrap;">نەخۆش</th>
                            <th style="padding:16px 24px;font-size:0.8rem;font-weight:700;color:#64748b;white-space:nowrap;">خزمەتگوزارییەکان</th>
                            <th style="padding:16px 24px;font-size:0.8rem;font-weight:700;color:#64748b;white-space:nowrap;">کات و بەروار</th>
                            <th style="padding:16px 24px;font-size:0.8rem;font-weight:700;color:#64748b;white-space:nowrap;">ناونیشان / ژ.مۆبایل</th>
                            <th style="padding:16px 24px;font-size:0.8rem;font-weight:700;color:#64748b;white-space:nowrap;">نرخ</th>
                            <th style="padding:16px 24px;font-size:0.8rem;font-weight:700;color:#64748b;white-space:nowrap;">دۆخ و کاتی چاوەڕوانی</th>
                        </tr>
                    </thead>
                    <tbody>
                    @foreach($appointments as $app)
                        <tr style="border-bottom:1px solid #f1f5f9;transition:background 0.2s;" onmouseover="this.style.background='#f8fafc'" onmouseout="this.style.background='transparent'">
                            <td style="padding:16px 24px;">
                                <div style="display:flex;align-items:center;gap:12px;">
                                    <div style="width:40px;height:40px;border-radius:50%;background:#e0f2fe;color:#0284c7;display:flex;align-items:center;justify-content:center;font-weight:bold;">
                                        {{ mb_substr($app->patient->name ?? 'ن', 0, 1) }}
                                    </div>
                                    <div>
                                        <div style="font-size:0.9rem;font-weight:700;color:#0f172a;">{{ $app->patient->name ?? 'نەخۆش' }}</div>
                                    </div>
                                </div>
                            </td>
                            <td style="padding:16px 24px;">
                                <div style="display:flex;flex-wrap:wrap;gap:6px;">
                                    @if($app->items && $app->items->count() > 0)
                                        @foreach($app->items as $item)
                                            <span style="background:#f1f5f9;color:#475569;padding:4px 10px;border-radius:6px;font-size:0.75rem;font-weight:600;">
                                                {{ $item->item_name }}
                                            </span>
                                        @endforeach
                                    @else
                                        <span style="color:#94a3b8;font-size:0.8rem;">دیارینەکراوە</span>
                                    @endif
                                </div>
                            </td>
                            <td style="padding:16px 24px;white-space:nowrap;">
                                @php $localAppCreatedAt = $app->created_at?->timezone('Asia/Baghdad'); @endphp
                                <div style="font-size:0.85rem;color:#334155;font-weight:600;text-align:right;white-space:nowrap;" dir="ltr">{{ $localAppCreatedAt?->format('Y-m-d') }}</div>
                                <div style="font-size:0.75rem;color:#94a3b8;text-align:right;white-space:nowrap;" dir="ltr">{{ $localAppCreatedAt?->format('h:i A') }}</div>
                            </td>
                            <td style="padding:16px 24px;">
                                @php
                                    $patientDetails = is_string($app->patient_details) ? json_decode($app->patient_details, true) : $app->patient_details;
                                    $prescriptionImg = $patientDetails['prescription_image'] ?? $patientDetails['prescription_url'] ?? null;
                                @endphp
                                <div style="font-size:0.85rem;color:#334155;">{{ $patientDetails['location'] ?? 'ناونیشان دیارینەکراوە' }}</div>
                                <div style="font-size:0.75rem;color:#64748b;direction:ltr;text-align:right;white-space:nowrap;">{{ $patientDetails['phone'] ?? '' }}</div>
                                @if($prescriptionImg)
                                    @php
                                        $fullPrescUrl = (str_starts_with($prescriptionImg, 'http://') || str_starts_with($prescriptionImg, 'https://'))
                                            ? $prescriptionImg
                                            : (str_starts_with($prescriptionImg, 'storage/') ? asset($prescriptionImg) : asset('storage/' . ltrim($prescriptionImg, '/')));
                                    @endphp
                                    <div style="margin-top: 6px;">
                                        <a href="{{ $fullPrescUrl }}" target="_blank" style="display:inline-flex;align-items:center;gap:4px;background:#ecfdf5;color:#0d9488;padding:3px 8px;border-radius:6px;font-size:0.75rem;font-weight:700;text-decoration:none;border:1px solid #a7f3d0;">
                                            <svg width="12" height="12" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                                            وێنەی ڕەچەتە
                                        </a>
                                    </div>
                                @endif
                            </td>
                            <td style="padding:16px 24px;white-space:nowrap;">
                                <div style="font-size:0.9rem;font-weight:700;color:#059669;white-space:nowrap;">{{ number_format($app->total_price, 0) }} د.ع</div>
                            </td>
                            <td style="padding:16px 24px;">
                                @php
                                    $estPresets = [15, 30, 45, 60, 90, 120, 180, 240, 360, 720, 1440, 2880];
                                    $currentEst = $app->estimated_duration_minutes;
                                    $isCustomEst = $currentEst !== null && !in_array((int) $currentEst, $estPresets, true);
                                @endphp
                                <form id="nurse-order-status-form-{{ $app->id }}" action="{{ route('nurse.appointments.update_status', $app->id) }}" method="POST" style="margin:0;display:flex;flex-direction:column;gap:6px;min-width:205px;">
                                    @csrf
                                    @method('PATCH')
                                    <select name="status" onchange="this.form.submit()"
                                            class="status-select @if($app->status == 'pending') status-pending @elseif(in_array($app->status, ['approved', 'confirmed', 'processing', 'in_progress'])) status-progress @elseif($app->status == 'completed') status-completed @else status-cancelled @endif">
                                        <option value="pending" {{ $app->status == 'pending' ? 'selected' : '' }}>⏳ چاوەڕوانە</option>
                                        <option value="processing" {{ in_array($app->status, ['processing', 'in_progress', 'approved', 'confirmed']) ? 'selected' : '' }}>🩺 قبوڵکرا / لە کاردایە</option>
                                        <option value="completed" {{ $app->status == 'completed' ? 'selected' : '' }}>✅ تەواوکراوە</option>
                                        <option value="cancelled" {{ $app->status == 'cancelled' ? 'selected' : '' }}>❌ ڕەتکرایەوە</option>
                                    </select>

                                    <select id="nurse-est-preset-{{ $app->id }}"
                                            onchange="handleNurseEstPresetChange({{ $app->id }}, this)"
                                            style="font-size:0.76rem;font-weight:700;padding:6px 10px;border-radius:10px;border:1px solid #cbd5e1;background:#f8fafc;color:#334155;cursor:pointer;outline:none;">
                                        <option value="" {{ $currentEst === null ? 'selected' : '' }}>⏱ دیاریکردنی کات (چەند کاتی دەوێ)...</option>
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
                                               placeholder="خولەک (نم: 90)"
                                               style="width:100%;font-size:0.76rem;font-weight:700;padding:5px 8px;border-radius:8px;border:1px solid #94a3b8;background:#ffffff;color:#0f172a;outline:none;" />
                                        <button type="submit"
                                                style="background:#0f172a;color:#ffffff;border:none;padding:5px 10px;border-radius:8px;font-size:0.72rem;font-weight:800;cursor:pointer;white-space:nowrap;">
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
        
        <div style="overflow-x:auto;">
            <table style="width:100%;border-collapse:collapse;text-align:right;">
                <thead>
                    <tr style="background:#fefce8;border-bottom:1px solid #fde68a;">
                        <th style="padding:16px 24px;font-size:0.8rem;font-weight:700;color:#92400e;text-transform:uppercase;">نەخۆش</th>
                        <th style="padding:16px 24px;font-size:0.8rem;font-weight:700;color:#92400e;text-transform:uppercase;">خزمەتگوزارییەکان</th>
                        <th style="padding:16px 24px;font-size:0.8rem;font-weight:700;color:#92400e;text-transform:uppercase;">کات و بەروار</th>
                        <th style="padding:16px 24px;font-size:0.8rem;font-weight:700;color:#92400e;text-transform:uppercase;">ناونیشان</th>
                        <th style="padding:16px 24px;font-size:0.8rem;font-weight:700;color:#92400e;text-transform:uppercase;">نرخ</th>
                        <th style="padding:16px 24px;font-size:0.8rem;font-weight:700;color:#92400e;text-transform:uppercase;">کردارەکان</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach($unassignedRequests as $req)
                    <tr style="border-bottom:1px solid #fef3c7;background:#fff;">
                        <td style="padding:16px 24px;">
                            <div style="font-size:0.9rem;font-weight:700;color:#0f172a;">{{ $req->patient->name ?? 'نەخۆش' }}</div>
                        </td>
                        <td style="padding:16px 24px;">
                            <div style="display:flex;flex-wrap:wrap;gap:6px;">
                                @if($req->items && $req->items->count() > 0)
                                    @foreach($req->items as $item)
                                        <span style="background:#fef3c7;color:#b45309;padding:4px 10px;border-radius:6px;font-size:0.75rem;font-weight:600;">
                                            {{ $item->item_name }}
                                        </span>
                                    @endforeach
                                @endif
                            </div>
                        </td>
                        <td style="padding:16px 24px;white-space:nowrap;">
                            @php $localReqCreatedAt = $req->created_at?->timezone('Asia/Baghdad'); @endphp
                            <div style="font-size:0.85rem;color:#334155;font-weight:600;text-align:right;white-space:nowrap;" dir="ltr">{{ $localReqCreatedAt?->format('Y-m-d') }}</div>
                            <div style="font-size:0.75rem;color:#94a3b8;text-align:right;white-space:nowrap;" dir="ltr">{{ $localReqCreatedAt?->format('h:i A') }}</div>
                        </td>
                        <td style="padding:16px 24px;">
                            @php
                                $patientDetails = is_string($req->patient_details) ? json_decode($req->patient_details, true) : $req->patient_details;
                                $reqPrescriptionImg = $patientDetails['prescription_image'] ?? $patientDetails['prescription_url'] ?? null;
                            @endphp
                            <div style="font-size:0.85rem;color:#334155;">{{ $patientDetails['location'] ?? 'ناونیشان دیارینەکراوە' }}</div>
                            @if($reqPrescriptionImg)
                                @php
                                    $fullReqPrescUrl = (str_starts_with($reqPrescriptionImg, 'http://') || str_starts_with($reqPrescriptionImg, 'https://'))
                                        ? $reqPrescriptionImg
                                        : (str_starts_with($reqPrescriptionImg, 'storage/') ? asset($reqPrescriptionImg) : asset('storage/' . ltrim($reqPrescriptionImg, '/')));
                                @endphp
                                <div style="margin-top: 6px;">
                                    <a href="{{ $fullReqPrescUrl }}" target="_blank" style="display:inline-flex;align-items:center;gap:4px;background:#fef3c7;color:#b45309;padding:3px 8px;border-radius:6px;font-size:0.75rem;font-weight:700;text-decoration:none;border:1px solid #fde68a;">
                                        <svg width="12" height="12" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                                        وێنەی ڕەچەتە
                                    </a>
                                </div>
                            @endif
                        </td>
                        <td style="padding:16px 24px;white-space:nowrap;">
                            <div style="font-size:0.9rem;font-weight:700;color:#b45309;white-space:nowrap;">{{ number_format($req->total_price, 0) }} د.ع</div>
                        </td>
                        <td style="padding:16px 24px;">
                            <form action="{{ route('nurse.appointments.accept', $req->id) }}" method="POST" style="display:flex;flex-wrap:wrap;align-items:center;gap:6px;">
                                @csrf
                                <select name="estimated_duration_minutes" style="font-size:0.76rem;font-weight:700;padding:7px 10px;border-radius:8px;border:1px solid #fde68a;background:#fffbeb;color:#92400e;cursor:pointer;outline:none;">
                                    <option value="">⏱ کاتی گەیشتن (ئارەزوومەندانە)</option>
                                    <option value="15">⏱ ١٥ خولەک</option>
                                    <option value="30">⏱ ٣٠ خولەک</option>
                                    <option value="45">⏱ ٤٥ خولەک</option>
                                    <option value="60">⏱ ١ کاتژمێر</option>
                                    <option value="90">⏱ ١ کاتژمێر و ٣٠ خولەک</option>
                                    <option value="120">⏱ ٢ کاتژمێر</option>
                                </select>
                                <button type="submit" style="background:#f59e0b;color:#fff;border:none;padding:8px 16px;border-radius:8px;font-size:0.8rem;font-weight:bold;cursor:pointer;transition:background 0.2s;display:inline-flex;align-items:center;gap:6px;white-space:nowrap;" onmouseover="this.style.background='#d97706'" onmouseout="this.style.background='#f59e0b'">
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
function handleNurseEstPresetChange(orderId, selectEl) {
    const val = selectEl.value;
    const customBox = document.getElementById(`nurse-est-custom-box-${orderId}`);
    const inputEl = document.getElementById(`nurse-est-minutes-${orderId}`);
    const formEl = document.getElementById(`nurse-order-status-form-${orderId}`);
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
