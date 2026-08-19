@extends('lab.layouts.app')
@section('header_title', 'داواکارییەکانی پشکنین و نەخۆشەکان')

@section('content')
<style>
    .order-card-table {
        width: 100%;
        border-collapse: separate;
        border-spacing: 0;
        text-align: right;
    }
    .order-card-table th {
        background: #f8fafc;
        color: #475569;
        font-size: 0.82rem;
        font-weight: 800;
        padding: 16px 20px;
        border-bottom: 2px solid #e2e8f0;
        white-space: nowrap;
    }
    .order-card-table td {
        padding: 16px 20px;
        border-bottom: 1px solid #f1f5f9;
        vertical-align: middle;
        background: #ffffff;
        font-size: 0.88rem;
    }
    .order-card-table tr:hover td {
        background: #f8fafc;
    }
    .badge-ord {
        background: #0f172a;
        color: #ffffff;
        font-weight: 800;
        font-family: monospace;
        font-size: 0.85rem;
        padding: 5px 12px;
        border-radius: 10px;
        display: inline-block;
        letter-spacing: 0.5px;
    }
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
        background: #2563eb;
        color: #ffffff;
        border: none;
        padding: 8px 18px;
        border-radius: 12px;
        font-weight: 800;
        font-size: 0.82rem;
        cursor: pointer;
        display: inline-flex;
        align-items: center;
        gap: 6px;
        transition: all 0.2s;
        box-shadow: 0 2px 6px rgba(37,99,235,0.25);
    }
    .btn-view-details:hover {
        background: #1d4ed8;
        transform: translateY(-1px);
    }
    #orderModalMap {
        width: 100%;
        height: 220px;
        border-radius: 14px;
        border: 1px solid #e2e8f0;
        z-index: 10;
    }
</style>

<div class="space-y-6">
    <!-- Header with Dropdown Filter -->
    <div style="background: #ffffff; padding: 20px 24px; border-radius: 18px; border: 1px solid #e2e8f0; box-shadow: 0 1px 3px rgba(0,0,0,0.03); display: flex; flex-wrap: wrap; align-items: center; justify-content: space-between; gap: 16px;">
        <div>
            <div style="display: flex; align-items: center; gap: 10px;">
                <h2 style="font-size: 1.25rem; font-weight: 800; color: #0f172a; margin: 0;">داواکارییەکانی پشکنینی تاقیگە</h2>
                <span style="background: #eff6ff; color: #2563eb; font-size: 0.75rem; font-weight: 800; padding: 3px 10px; border-radius: 20px; border: 1px solid #dbeafe;">
                    کۆی گشتی: {{ $counts['all'] ?? $orders->total() ?? 0 }} داواکاری
                </span>
            </div>
            <p style="font-size: 0.85rem; color: #64748b; margin: 4px 0 0 0;">سەرجەم داواکارییە نێردراوەکانی نەخۆش لە ڕێگەی ئەپڵیکەیشنەوە.</p>
        </div>

        <div style="display: flex; align-items: center; gap: 10px;">
            <select onchange="location = this.value;" style="background: #f8fafc; border: 1px solid #cbd5e1; color: #334155; font-size: 0.82rem; font-weight: 700; padding: 8px 16px; border-radius: 12px; cursor: pointer; outline: none;">
                <option value="{{ route('lab.patients.index') }}" {{ !$status || $status == 'all' ? 'selected' : '' }}>
                    🔍 هەموو داواکارییەکان ({{ $counts['all'] ?? 0 }})
                </option>
                <option value="{{ route('lab.patients.index', ['status' => 'pending']) }}" {{ $status == 'pending' ? 'selected' : '' }}>
                    ⏳ لە چاوەڕوانیدا ({{ $counts['pending'] ?? 0 }})
                </option>
                <option value="{{ route('lab.patients.index', ['status' => 'approved']) }}" {{ $status == 'approved' ? 'selected' : '' }}>
                    🔬 نموونە وەرگیرا / لە کاردایە ({{ $counts['approved'] ?? 0 }})
                </option>
                <option value="{{ route('lab.patients.index', ['status' => 'completed']) }}" {{ $status == 'completed' ? 'selected' : '' }}>
                    ✅ تەواوکراو و ئەنجام ئامادەیە ({{ $counts['completed'] ?? 0 }})
                </option>
            </select>
        </div>
    </div>

    @if(session('success'))
        <div style="padding: 12px 18px; background: #ecfdf5; border: 1px solid #a7f3d0; color: #047857; border-radius: 14px; font-weight: 700; font-size: 0.85rem; display: flex; align-items: center; gap: 8px;">
            <svg style="width: 18px; height: 18px;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
            <span>{{ session('success') }}</span>
        </div>
    @endif

    <!-- Simple, Clean Orders Table -->
    <div style="background: #ffffff; border-radius: 18px; border: 1px solid #e2e8f0; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.03);">
        <div style="overflow-x: auto;">
            <table class="order-card-table">
                <thead>
                    <tr>
                        <th style="width: 18%;">ژمارەی داواکاری</th>
                        <th style="width: 22%;">بەروار و کات</th>
                        <th style="width: 26%;">ناوی نەخۆش</th>
                        <th style="width: 18%;">بارودۆخ</th>
                        <th style="width: 16%; text-align: center;">کردار</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($orders as $order)
                        @php
                            $details = is_array($order->patient_details) ? $order->patient_details : (json_decode($order->patient_details, true) ?? []);
                            $loc = is_array($order->location_details) ? $order->location_details : (json_decode($order->location_details, true) ?? []);
                            $patientName = !empty($details['full_name']) ? $details['full_name'] : (!empty($details['name']) ? $details['name'] : ($order->patient?->name ?? 'نەخۆش'));
                            $patientPhone = !empty($details['phone']) ? $details['phone'] : ($order->patient?->phone ?? 'نەزانراو');
                            $patientAge = !empty($details['age']) ? $details['age'] : (!empty($details['patient_age']) ? $details['patient_age'] : null);
                            $patientGender = !empty($details['gender']) ? $details['gender'] : null;
                            $collectionMethodRaw = $details['sample_collection_method'] ?? ($order->extra_fee > 0 ? 'home' : 'lab');
                            $collectionMethodText = ($collectionMethodRaw === 'home') ? '🏠 لە ماڵەوە (Home Sample)' : '🏢 لە تاقیگە (Lab Visit)';
                            
                            $address = !empty($details['address']) 
                                ? $details['address'] 
                                : (!empty($details['location_name']) 
                                    ? $details['location_name'] 
                                    : (!empty($loc['address']) ? $loc['address'] : 'هەولێر'));
                            
                            $notes = !empty($details['notes']) ? $details['notes'] : (!empty($details['description']) ? $details['description'] : 'هیچ تێبینییەک نەنوسراوە');

                            $lat = $loc['latitude'] ?? $details['latitude'] ?? 36.1911;
                            $lng = $loc['longitude'] ?? $details['longitude'] ?? 44.0092;

                            // Payment Method Kurdish Translation
                            $rawPayment = strtolower((string)($order->payment_method ?? 'cash'));
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

                            $orderPayload = [
                                'id' => $order->id,
                                'patient_id' => $order->patient_id ?? $order->user_id,
                                'date' => $order->created_at->format('Y/m/d h:i A'),
                                'name' => $patientName,
                                'phone' => $patientPhone,
                                'age' => $patientAge,
                                'gender' => $patientGender,
                                'collection_method' => $collectionMethodText,
                                'address' => $address,
                                'notes' => $notes,
                                'payment_method' => $paymentMethodKurdish,
                                'total_price' => number_format($order->total_price),
                                'status' => $order->status,
                                'lat' => (float)$lat,
                                'lng' => (float)$lng,
                                'items' => $order->items ?? [],
                            ];
                        @endphp
                        <tr>
                            <!-- Order ID -->
                            <td>
                                <span class="badge-ord">#ORD-{{ $order->id }}</span>
                            </td>

                            <!-- Date & Time -->
                            <td>
                                <div style="font-weight: 700; color: #1e293b; font-size: 0.85rem;" dir="ltr">
                                    {{ $order->created_at->format('Y/m/d') }}
                                </div>
                                <div style="font-size: 0.75rem; color: #64748b; margin-top: 3px; font-weight: 600;" dir="ltr">
                                    🕒 {{ $order->created_at->format('h:i A') }}
                                </div>
                            </td>

                            <!-- Patient Name -->
                            <td>
                                <div style="font-weight: 800; color: #0f172a; font-size: 0.95rem; display: flex; align-items: center; gap: 8px;">
                                    <span>{{ $patientName }}</span>
                                    @if($patientGender)
                                        <span style="font-size: 0.7rem; padding: 2px 7px; border-radius: 6px; font-weight: 700; background: {{ $patientGender == 'female' ? '#fdf2f8; color: #db2777' : '#eff6ff; color: #2563eb' }};">
                                            {{ $patientGender == 'female' ? 'مێ' : 'نێر' }}
                                        </span>
                                    @endif
                                </div>
                                <div style="font-size: 0.78rem; color: #64748b; margin-top: 3px;" dir="ltr">
                                    {{ $patientPhone }}
                                </div>
                            </td>

                            <!-- Status Dropdown -->
                            <td>
                                <form action="{{ route('lab.orders.update_status', $order) }}" method="POST" style="margin: 0;">
                                    @csrf
                                    @method('PATCH')
                                    <select name="status" onchange="this.form.submit()" 
                                            class="status-select @if($order->status == 'pending') status-pending @elseif(in_array($order->status, ['approved', 'confirmed', 'in_progress'])) status-progress @elseif($order->status == 'completed') status-completed @else status-cancelled @endif">
                                        <option value="pending" {{ $order->status == 'pending' ? 'selected' : '' }}>⏳ چاوەڕوانە</option>
                                        <option value="in_progress" {{ in_array($order->status, ['in_progress', 'approved', 'confirmed']) ? 'selected' : '' }}>🔬 نموونە وەرگیرا / لە کاردایە</option>
                                        <option value="completed" {{ $order->status == 'completed' ? 'selected' : '' }}>✅ تەواوکراوە</option>
                                        <option value="cancelled" {{ $order->status == 'cancelled' ? 'selected' : '' }}>❌ ڕەتکرایەوە</option>
                                    </select>
                                </form>
                            </td>

                            <!-- Action: View Full Details Modal -->
                            <td style="text-align: center;">
                                <button type="button" onclick="openOrderModal({{ json_encode($orderPayload) }})" 
                                        class="btn-view-details">
                                    <svg style="width: 15px; height: 15px;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                                    بینینی زانیاری تەواو
                                </button>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="5" style="text-align: center; padding: 48px; color: #94a3b8;">
                                <div style="font-weight: 700; color: #64748b; font-size: 1rem;">هیچ داواکارییەکی پشکنین نەدۆزرایەوە</div>
                                <div style="font-size: 0.8rem; margin-top: 4px;">کاتێک نەخۆش لە ئەپەکەوە داواکاری دەنێرێت لێرە دەردەکەوێت.</div>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        <!-- Pagination Footer -->
        <div style="padding: 14px 20px; background: #f8fafc; border-top: 1px solid #e2e8f0; display: flex; flex-wrap: wrap; align-items: center; justify-content: space-between; gap: 10px; font-size: 0.78rem; color: #64748b;">
            <div>
                پیشاندانی <strong style="color: #0f172a;">{{ $orders->firstItem() ?? 0 }}</strong> بۆ <strong style="color: #0f172a;">{{ $orders->lastItem() ?? 0 }}</strong> لە کۆی <strong style="color: #2563eb;">{{ $orders->total() }}</strong> داواکاری
            </div>

            <div>
                {{ $orders->links() }}
            </div>
        </div>
    </div>
</div>

<!-- Detailed Form Modal with In-App Leaflet Map -->
<div id="orderModal" style="position: fixed; inset: 0; z-index: 999; background: rgba(15,23,42,0.65); backdrop-filter: blur(5px); display: none; align-items: center; justify-content: center; padding: 16px;">
    <div style="background: #ffffff; border-radius: 24px; max-width: 700px; width: 100%; max-height: 90vh; overflow-y: auto; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.25); padding: 26px; direction: rtl; text-align: right; border: 1px solid #e2e8f0;">
        <!-- Modal Header -->
        <div style="display: flex; align-items: center; justify-content: space-between; border-bottom: 1px solid #f1f5f9; padding-bottom: 16px;">
            <div>
                <div style="display: flex; align-items: center; gap: 8px;">
                    <h3 style="font-size: 1.15rem; font-weight: 900; color: #0f172a; margin: 0;" id="modalTitle">وردەکاری تەواوی داواکاری</h3>
                    <span id="modalOrderIdBadge" style="background: #0f172a; color: #ffffff; font-family: monospace; font-size: 0.8rem; font-weight: 800; padding: 3px 8px; border-radius: 6px;"></span>
                </div>
                <p style="font-size: 0.78rem; color: #64748b; margin: 3px 0 0 0;" id="modalSubtitle"></p>
            </div>
            <button type="button" onclick="closeOrderModal()" style="width: 34px; height: 34px; border-radius: 50%; background: #f1f5f9; border: none; color: #64748b; font-weight: 700; cursor: pointer; display: flex; align-items: center; justify-content: center; font-size: 1rem;">
                ✕
            </button>
        </div>

        <!-- Modal Dynamic Content -->
        <div id="modalContent" style="display: flex; flex-direction: column; gap: 14px; margin-top: 18px; font-size: 0.85rem;">
            <!-- Injected by JS -->
        </div>

        <!-- Interactive Map Inside Modal -->
        <div style="margin-top: 14px;">
            <div style="font-size: 0.8rem; font-weight: 800; color: #334155; margin-bottom: 8px; display: flex; align-items: center; justify-content: space-between;">
                <span>🗺️ شوێنی نەخۆش لەسەر نەخشە</span>
                <span style="font-size: 0.72rem; color: #64748b; font-weight: normal;">دەتوانیت نەخشەکە بجوڵێنیت یان زوومی بکەیت</span>
            </div>
            <div id="orderModalMap"></div>
        </div>

        <!-- Modal Footer -->
        <div style="border-top: 1px solid #f1f5f9; margin-top: 22px; padding-top: 16px; display: flex; align-items: center; justify-content: space-between; gap: 12px; flex-wrap: wrap;">
            <a id="modalUploadResultBtn" href="#" style="padding: 9px 20px; background: #059669; color: #ffffff; font-weight: 800; border-radius: 12px; text-decoration: none; font-size: 0.82rem; display: inline-flex; align-items: center; gap: 6px; box-shadow: 0 2px 6px rgba(5,150,105,0.25);">
                <svg style="width: 16px; height: 16px;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                تۆمارکردن و ناردنی ئەنجامی پشکنین (PDF/ڕاپۆرت)
            </a>

            <button type="button" onclick="closeOrderModal()" style="padding: 9px 24px; background: #f1f5f9; color: #334155; font-weight: 800; border-radius: 12px; border: none; cursor: pointer; font-size: 0.82rem;">
                داخستن
            </button>
        </div>
    </div>
</div>
@endsection

@section('scripts')
<script>
let leafletMapInstance = null;
let leafletMarkerInstance = null;

function openOrderModal(data) {
    const modal = document.getElementById('orderModal');
    const content = document.getElementById('modalContent');
    const badge = document.getElementById('modalOrderIdBadge');
    const subtitle = document.getElementById('modalSubtitle');
    const uploadBtn = document.getElementById('modalUploadResultBtn');

    badge.textContent = `#ORD-${data.id}`;
    subtitle.textContent = `بەروار و کاتی تۆمارکردن: ${data.date}`;
    uploadBtn.href = `{{ route('lab.results.create') }}?patient_id=${data.patient_id || ''}&order_id=${data.id}`;

    const genderText = data.gender === 'female' ? 'مێ (Female)' : (data.gender === 'male' ? 'نێر (Male)' : 'دیارینەکراو');
    const ageText = data.age ? `${data.age} ساڵ` : 'دیارینەکراو';

    let itemsHtml = '';
    if (data.items && data.items.length > 0) {
        itemsHtml = data.items.map(it => `
            <div style="display: flex; align-items: center; justify-content: space-between; padding: 10px 14px; background: #ffffff; border-radius: 10px; border: 1px solid #e2e8f0; font-size: 0.82rem; margin-bottom: 8px;">
                <span style="font-weight: 800; color: #1e293b;">🔬 ${it.item_name}</span>
                <span style="font-weight: 800; color: #2563eb;" dir="ltr">${Number(it.price).toLocaleString()} IQD</span>
            </div>
        `).join('');
    } else {
        itemsHtml = '<div style="font-size: 0.8rem; color: #94a3b8; padding: 10px;">پشکنینی گشتی</div>';
    }

    content.innerHTML = `
        <!-- Patient Profile Box -->
        <div style="background: #eff6ff; padding: 16px; border-radius: 16px; border: 1px solid #dbeafe;">
            <div style="font-size: 0.78rem; font-weight: 800; color: #1e40af; margin-bottom: 8px;">👤 زانیاری تەواوی نەخۆش</div>
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(130px, 1fr)); gap: 12px;">
                <div>
                    <span style="font-size: 0.72rem; color: #64748b; display: block;">ناوی نەخۆش:</span>
                    <strong style="color: #0f172a; font-size: 0.92rem;">${data.name}</strong>
                </div>
                <div>
                    <span style="font-size: 0.72rem; color: #64748b; display: block;">ژمارەی مۆبایل:</span>
                    <a href="tel:${data.phone}" style="color: #2563eb; font-weight: 800; text-decoration: none; font-size: 0.9rem;" dir="ltr">📞 ${data.phone}</a>
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

        <!-- Sample Collection & Address -->
        <div style="background: #f8fafc; padding: 16px; border-radius: 16px; border: 1px solid #e2e8f0;">
            <div style="font-size: 0.78rem; font-weight: 800; color: #334155; margin-bottom: 8px;">📍 شێوازی وەرگرتن & ناونیشان</div>
            <div style="font-size: 0.82rem; color: #334155; line-height: 1.7;">
                <div><strong>شێواز:</strong> <span style="color: #7e22ce; font-weight: 800;">${data.collection_method}</span></div>
                <div><strong>ناونیشان:</strong> <span style="font-weight: 700; color: #0f172a;">${data.address}</span></div>
                <div><strong>تێبینی نەخۆش:</strong> <span style="color: #64748b;">${data.notes}</span></div>
            </div>
        </div>

        <!-- Price & Payment -->
        <div style="background: #f8fafc; padding: 16px; border-radius: 16px; border: 1px solid #e2e8f0;">
            <div style="font-size: 0.78rem; font-weight: 800; color: #334155; margin-bottom: 8px;">💳 پارەدان & کۆی گشتی</div>
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(140px, 1fr)); gap: 12px; font-size: 0.82rem;">
                <div>
                    <span style="font-size: 0.72rem; color: #64748b; display: block;">شێوازی پارەدان:</span>
                    <span style="color: #059669; font-weight: 800;">💵 ${data.payment_method}</span>
                </div>
                <div>
                    <span style="font-size: 0.72rem; color: #64748b; display: block;">کۆی گشتی نرخ:</span>
                    <strong style="color: #059669; font-size: 1rem;" dir="ltr">${data.total_price} IQD</strong>
                </div>
                <div>
                    <span style="font-size: 0.72rem; color: #64748b; display: block;">بارودۆخ:</span>
                    <span style="color: #2563eb; font-weight: 800;">${data.status}</span>
                </div>
            </div>
        </div>

        <!-- Requested Tests List -->
        <div style="background: #f8fafc; padding: 16px; border-radius: 16px; border: 1px solid #e2e8f0;">
            <div style="font-size: 0.78rem; font-weight: 800; color: #334155; margin-bottom: 10px;">🧪 لیستی پشکنینە هەڵبژێردراوەکان</div>
            ${itemsHtml}
        </div>
    `;

    modal.style.display = 'flex';

    // Initialize or Update Leaflet Map inside Modal
    setTimeout(() => {
        const lat = data.lat || 36.1911;
        const lng = data.lng || 44.0092;

        if (!leafletMapInstance) {
            leafletMapInstance = L.map('orderModalMap').setView([lat, lng], 14);
            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                attribution: '© OpenStreetMap contributors'
            }).addTo(leafletMapInstance);
        } else {
            leafletMapInstance.setView([lat, lng], 14);
            leafletMapInstance.invalidateSize();
        }

        if (leafletMarkerInstance) {
            leafletMarkerInstance.setLatLng([lat, lng]);
        } else {
            leafletMarkerInstance = L.marker([lat, lng]).addTo(leafletMapInstance);
        }

        leafletMarkerInstance.bindPopup(`<b>${data.name}</b><br>${data.address}`).openPopup();
        leafletMapInstance.invalidateSize();
    }, 200);
}

function closeOrderModal() {
    document.getElementById('orderModal').style.display = 'none';
}
</script>
@endsection
