@extends('pharmacy.layouts.app')
@section('header_title', 'داواکارییەکانی کڕیاران و دەرمان')

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
        background: #0d9488;
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
        box-shadow: 0 2px 6px rgba(13,148,136,0.25);
    }
    .btn-view-details:hover {
        background: #0f766e;
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

<div class="fade-up space-y-6">
    <!-- Header with Dropdown Filter -->
    <div style="background: #ffffff; padding: 20px 24px; border-radius: 18px; border: 1px solid #e2e8f0; box-shadow: 0 1px 3px rgba(0,0,0,0.03); display: flex; flex-wrap: wrap; align-items: center; justify-content: space-between; gap: 16px;">
        <div>
            <div style="display: flex; align-items: center; gap: 10px;">
                <h2 style="font-size: 1.25rem; font-weight: 800; color: #0f172a; margin: 0;">داواکارییەکانی دەرمانخانە</h2>
                <span style="background: #f0fdfa; color: #0d9488; font-size: 0.75rem; font-weight: 800; padding: 3px 10px; border-radius: 20px; border: 1px solid #ccfbf1;">
                    کۆی گشتی: {{ $counts['all'] ?? $orders->total() }} داواکاری
                </span>
            </div>
            <p style="font-size: 0.85rem; color: #64748b; margin: 4px 0 0 0;">سەرجەم داواکارییە نێردراوەکانی کڕیاران لە ڕێگەی ئەپڵیکەیشنەوە.</p>
        </div>

        <div style="display: flex; align-items: center; gap: 10px;">
            <select onchange="location = this.value;" style="background: #f8fafc; border: 1px solid #cbd5e1; color: #334155; font-size: 0.82rem; font-weight: 700; padding: 8px 16px; border-radius: 12px; cursor: pointer; outline: none;">
                <option value="{{ route('pharmacy.orders.index') }}" {{ !$status || $status == 'all' ? 'selected' : '' }}>
                    🔍 هەموو داواکارییەکان ({{ $counts['all'] ?? 0 }})
                </option>
                <option value="{{ route('pharmacy.orders.index', ['status' => 'pending']) }}" {{ $status == 'pending' ? 'selected' : '' }}>
                    ⏳ لە چاوەڕوانیدا ({{ $counts['pending'] ?? 0 }})
                </option>
                <option value="{{ route('pharmacy.orders.index', ['status' => 'accepted']) }}" {{ $status == 'accepted' ? 'selected' : '' }}>
                    📦 لە ئامادەکردندایە ({{ $counts['accepted'] ?? 0 }})
                </option>
                <option value="{{ route('pharmacy.orders.index', ['status' => 'completed']) }}" {{ $status == 'completed' ? 'selected' : '' }}>
                    ✅ تەواوکراو و گەیەنراو ({{ $counts['completed'] ?? 0 }})
                </option>
                <option value="{{ route('pharmacy.orders.index', ['status' => 'cancelled']) }}" {{ $status == 'cancelled' ? 'selected' : '' }}>
                    ❌ ڕەتکراوەکان ({{ $counts['cancelled'] ?? 0 }})
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

    @if($errors->any())
        <div style="padding: 12px 18px; background: #fef2f2; border: 1px solid #fecaca; color: #b91c1c; border-radius: 14px; font-weight: 700; font-size: 0.85rem;">
            <span>{{ $errors->first() }}</span>
        </div>
    @endif

    <!-- Orders Table Card -->
    <div style="background: #ffffff; border-radius: 20px; border: 1px solid #e2e8f0; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.03);">
        <div style="overflow-x: auto;">
            <table class="order-card-table">
                <thead>
                    <tr>
                        <th>ژمارەی داواکاری</th>
                        <th>بەروار & کات</th>
                        <th>کڕیار / نەخۆش</th>
                        <th>دەرمانەکان</th>
                        <th>کۆی نرخ</th>
                        <th>دۆخ</th>
                        <th style="text-align: center;">کردار</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($orders as $order)
                        @php
                            $details = is_string($order->patient_details) ? json_decode($order->patient_details, true) : ($order->patient_details ?? []);
                            if (!is_array($details)) $details = [];

                            $patientName = $details['name'] ?? $details['patient_name'] ?? ($order->patient->name ?? 'کڕیاری DrRoom');
                            $patientPhone = $details['phone'] ?? $details['patient_phone'] ?? ($order->patient->phone ?? '-');
                            $patientAge = $details['age'] ?? $details['patient_age'] ?? null;
                            $patientGender = $details['gender'] ?? $details['patient_gender'] ?? null;

                            $loc = is_string($order->location_details) ? json_decode($order->location_details, true) : $order->location_details;
                            if (is_array($loc)) {
                                $address = $loc['address_text'] ?? $loc['address'] ?? ($loc['address_name'] ?? 'هەولێر');
                                $lat = !empty($loc['latitude']) ? floatval($loc['latitude']) : 36.1911;
                                $lng = !empty($loc['longitude']) ? floatval($loc['longitude']) : 44.0092;
                            } else {
                                $address = !empty($order->location_details) ? $order->location_details : 'هەولێر';
                                $lat = 36.1911;
                                $lng = 44.0092;
                            }

                            // Payment Method
                            $rawPayment = strtolower((string)($order->payment_method ?? 'cash'));
                            if (str_contains($rawPayment, 'delivery') || str_contains($rawPayment, 'cash') || str_contains($rawPayment, 'کاش')) {
                                $paymentMethodKurdish = 'پارەدانی کاش (دەستبەدەست)';
                            } elseif (str_contains($rawPayment, 'fastpay')) {
                                $paymentMethodKurdish = 'FastPay';
                            } elseif (str_contains($rawPayment, 'fib')) {
                                $paymentMethodKurdish = 'FIB بانکی یەکەمی عێراق';
                            } else {
                                $paymentMethodKurdish = $order->payment_method ?? 'کاش';
                            }

                            $orderPayload = [
                                'id' => $order->id,
                                'date' => $order->created_at->format('Y/m/d h:i A'),
                                'name' => $patientName,
                                'phone' => $patientPhone,
                                'age' => $patientAge,
                                'gender' => $patientGender,
                                'address' => $address,
                                'payment_method' => $paymentMethodKurdish,
                                'subtotal' => number_format($order->subtotal),
                                'extra_fee' => number_format($order->extra_fee),
                                'total_price' => number_format($order->total_price),
                                'status' => $order->status,
                                'lat' => (float)$lat,
                                'lng' => (float)$lng,
                                'items' => $order->items ?? [],
                                'show_url' => route('pharmacy.orders.show', $order->id),
                                'update_url' => route('pharmacy.orders.status', $order->id),
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
                                <div style="font-size: 0.78rem; color: #64748b; margin-top: 3px; direction: ltr; text-align: right;">
                                    {{ $patientPhone }}
                                </div>
                            </td>

                            <!-- Medications summary -->
                            <td>
                                <div style="color: #334155; font-size: 0.85rem; font-weight: 700;">
                                    {{ $order->items->pluck('item_name')->take(2)->join('، ') }}
                                    @if($order->items->count() > 2)
                                        <span style="color: #0d9488; font-weight: 800;">+{{ $order->items->count() - 2 }} تر</span>
                                    @endif
                                </div>
                            </td>

                            <!-- Total Price -->
                            <td>
                                <div style="font-weight: 800; color: #0d9488; font-size: 0.95rem;" dir="ltr">
                                    IQD {{ number_format($order->total_price) }}
                                </div>
                            </td>

                            <!-- Status Dropdown -->
                            <td>
                                <form action="{{ route('pharmacy.orders.status', $order->id) }}" method="POST" style="margin: 0;">
                                    @csrf
                                    <select name="status" onchange="this.form.submit()" 
                                            class="status-select @if($order->status == 'pending') status-pending @elseif($order->status == 'accepted') status-progress @elseif($order->status == 'completed') status-completed @else status-cancelled @endif">
                                        <option value="pending" {{ $order->status == 'pending' ? 'selected' : '' }}>⏳ چاوەڕوانە</option>
                                        <option value="accepted" {{ $order->status == 'accepted' ? 'selected' : '' }}>📦 لە ئامادەکردندایە</option>
                                        <option value="completed" {{ $order->status == 'completed' ? 'selected' : '' }}>✅ گەیەنرا / تەواو</option>
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
                            <td colspan="7" style="text-align: center; padding: 48px; color: #94a3b8;">
                                <div style="font-weight: 700; color: #64748b; font-size: 1rem;">هیچ داواکارییەکی دەرمان نەدۆزرایەوە</div>
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
                پیشاندانی <strong style="color: #0f172a;">{{ $orders->firstItem() ?? 0 }}</strong> بۆ <strong style="color: #0f172a;">{{ $orders->lastItem() ?? 0 }}</strong> لە کۆی <strong style="color: #0d9488;">{{ $orders->total() }}</strong> داواکاری
            </div>

            <div>
                {{ $orders->links() }}
            </div>
        </div>
    </div>
</div>

<!-- Detailed Form Modal with In-App Leaflet Map (Lab Style) -->
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
                <span>🗺️ شوێنی گەیاندن لەسەر نەخشە</span>
                <span style="font-size: 0.72rem; color: #64748b; font-weight: normal;">دەتوانیت نەخشەکە بجوڵێنیت یان زوومی بکەیت</span>
            </div>
            <div id="orderModalMap"></div>
        </div>

        <!-- Modal Footer -->
        <div style="border-top: 1px solid #f1f5f9; margin-top: 22px; padding-top: 16px; display: flex; align-items: center; justify-content: flex-end; gap: 12px;">
            <button type="button" onclick="closeOrderModal()" style="padding: 10px 28px; background: #f1f5f9; color: #334155; font-weight: 800; border-radius: 12px; border: none; cursor: pointer; font-size: 0.88rem; transition: all 0.2s;">
                داخستن
            </button>
        </div>
    </div>
</div>

<script>
let leafletMapInstance = null;
let leafletMarkerInstance = null;

function openOrderModal(data) {
    const modal = document.getElementById('orderModal');
    const content = document.getElementById('modalContent');
    const badge = document.getElementById('modalOrderIdBadge');
    const subtitle = document.getElementById('modalSubtitle');

    badge.textContent = `#ORD-${data.id}`;
    subtitle.textContent = `بەروار و کاتی تۆمارکردن: ${data.date}`;

    const genderText = data.gender === 'female' ? 'مێ (Female)' : (data.gender === 'male' ? 'نێر (Male)' : 'دیارینەکراو');
    const ageText = data.age ? `${data.age} ساڵ` : 'دیارینەکراو';

    let itemsHtml = '';
    if (data.items && data.items.length > 0) {
        itemsHtml = data.items.map(it => `
            <div style="display: flex; align-items: center; justify-content: space-between; padding: 10px 14px; background: #ffffff; border-radius: 10px; border: 1px solid #e2e8f0; font-size: 0.85rem; margin-bottom: 8px;">
                <span style="font-weight: 800; color: #1e293b;">💊 ${it.item_name} <span style="font-size:0.75rem; color:#64748b;">(×${it.quantity})</span></span>
                <span style="font-weight: 800; color: #0d9488;" dir="ltr">${Number(it.price * it.quantity).toLocaleString()} IQD</span>
            </div>
        `).join('');
    } else {
        itemsHtml = '<div style="font-size: 0.8rem; color: #94a3b8; padding: 10px;">دەرمانی گشتی</div>';
    }

    content.innerHTML = `
        <!-- Patient Profile Box -->
        <div style="background: #f0fdfa; padding: 16px; border-radius: 16px; border: 1px solid #ccfbf1;">
            <div style="font-size: 0.78rem; font-weight: 800; color: #0f766e; margin-bottom: 8px;">👤 زانیاری کڕیار / نەخۆش</div>
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(130px, 1fr)); gap: 12px;">
                <div>
                    <span style="font-size: 0.72rem; color: #64748b; display: block;">ناوی کڕیار:</span>
                    <strong style="color: #0f172a; font-size: 0.92rem;">${data.name}</strong>
                </div>
                <div>
                    <span style="font-size: 0.72rem; color: #64748b; display: block;">ژمارەی مۆبایل:</span>
                    <a href="tel:${data.phone}" style="color: #0d9488; font-weight: 800; text-decoration: none; font-size: 0.9rem;" dir="ltr">📞 ${data.phone}</a>
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

        <!-- Delivery Address -->
        <div style="background: #f8fafc; padding: 16px; border-radius: 16px; border: 1px solid #e2e8f0;">
            <div style="font-size: 0.78rem; font-weight: 800; color: #334155; margin-bottom: 8px;">📍 ناونیشانی گەیاندن</div>
            <div style="font-size: 0.88rem; color: #0f172a; font-weight: 700; line-height: 1.6;">
                📍 ${data.address}
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
                    <span style="font-size: 0.72rem; color: #64748b; display: block;">نرخی دەرمانەکان:</span>
                    <strong style="color: #1e293b;" dir="ltr">${data.subtotal} IQD</strong>
                </div>
                <div>
                    <span style="font-size: 0.72rem; color: #64748b; display: block;">کرێی گەیاندن:</span>
                    <strong style="color: #1e293b;" dir="ltr">${data.extra_fee} IQD</strong>
                </div>
                <div>
                    <span style="font-size: 0.72rem; color: #64748b; display: block;">کۆی گشتی:</span>
                    <strong style="color: #0d9488; font-size: 1.05rem;" dir="ltr">${data.total_price} IQD</strong>
                </div>
            </div>
        </div>

        <!-- Requested Medications List -->
        <div style="background: #f8fafc; padding: 16px; border-radius: 16px; border: 1px solid #e2e8f0;">
            <div style="font-size: 0.78rem; font-weight: 800; color: #334155; margin-bottom: 10px;">💊 دەرمانە هەڵبژێردراوەکان</div>
            ${itemsHtml}
        </div>
    `;

    modal.style.display = 'flex';

    // Initialize or Update Leaflet Map inside Modal
    setTimeout(() => {
        const lat = data.lat || 36.1911;
        const lng = data.lng || 44.0092;

        if (!leafletMapInstance) {
            leafletMapInstance = L.map('orderModalMap').setView([lat, lng], 15);
            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                attribution: '© OpenStreetMap contributors'
            }).addTo(leafletMapInstance);
        } else {
            leafletMapInstance.setView([lat, lng], 15);
            leafletMapInstance.invalidateSize();
        }

        if (leafletMarkerInstance) {
            leafletMarkerInstance.setLatLng([lat, lng]);
        } else {
            leafletMarkerInstance = L.marker([lat, lng]).addTo(leafletMapInstance);
        }

        leafletMarkerInstance.bindPopup(`<div style="font-family:Rabar, sans-serif; font-weight:bold;"><b>${data.name}</b><br>📍 ${data.address}</div>`).openPopup();
        leafletMapInstance.invalidateSize();
    }, 200);
}

function closeOrderModal() {
    document.getElementById('orderModal').style.display = 'none';
}

// Close when clicking outside
window.addEventListener('click', function(e) {
    const modal = document.getElementById('orderModal');
    if (e.target === modal) {
        closeOrderModal();
    }
});
</script>
@endsection
