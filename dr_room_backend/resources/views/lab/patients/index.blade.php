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
        font-size: 0.8rem;
        font-weight: 800;
        padding: 16px 18px;
        border-bottom: 2px solid #e2e8f0;
        white-space: nowrap;
    }
    .order-card-table td {
        padding: 16px 18px;
        border-bottom: 1px solid #f1f5f9;
        vertical-align: middle;
        background: #ffffff;
        font-size: 0.85rem;
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
        padding: 4px 10px;
        border-radius: 8px;
        display: inline-block;
        letter-spacing: 0.5px;
    }
    .badge-pill {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        padding: 5px 12px;
        border-radius: 12px;
        font-size: 0.78rem;
        font-weight: 800;
        white-space: nowrap;
    }
    .badge-home {
        background: #faf5ff;
        color: #7e22ce;
        border: 1px solid #e9d5ff;
    }
    .badge-lab {
        background: #ecfeff;
        color: #0e7490;
        border: 1px solid #cffafe;
    }
    .map-btn {
        display: inline-flex;
        align-items: center;
        gap: 4px;
        background: #fef2f2;
        color: #dc2626;
        border: 1px solid #fecaca;
        padding: 4px 10px;
        border-radius: 8px;
        font-size: 0.75rem;
        font-weight: 700;
        text-decoration: none;
        transition: all 0.2s;
    }
    .map-btn:hover {
        background: #dc2626;
        color: #ffffff;
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
    
    .test-item-chip {
        display: inline-flex;
        align-items: center;
        justify-content: space-between;
        background: #f8fafc;
        border: 1px solid #e2e8f0;
        padding: 4px 10px;
        border-radius: 8px;
        font-size: 0.78rem;
        font-weight: 700;
        color: #1e293b;
        margin: 2px 0;
        width: 100%;
        box-sizing: border-box;
    }
    .btn-detail {
        background: #eff6ff;
        color: #2563eb;
        border: 1px solid #dbeafe;
        padding: 7px 14px;
        border-radius: 10px;
        font-weight: 800;
        font-size: 0.78rem;
        cursor: pointer;
        display: inline-flex;
        align-items: center;
        gap: 6px;
        transition: all 0.2s;
    }
    .btn-detail:hover {
        background: #2563eb;
        color: #ffffff;
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
            <p style="font-size: 0.85rem; color: #64748b; margin: 4px 0 0 0;">سەرجەم داواکارییە نێردراوەکانی نەخۆش لە ڕێگەی ئەپڵیکەیشنەوە بە تەواوی زانیارییەکان.</p>
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

    <!-- Orders Table Container -->
    <div style="background: #ffffff; border-radius: 18px; border: 1px solid #e2e8f0; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.03);">
        <div style="overflow-x: auto;">
            <table class="order-card-table">
                <thead>
                    <tr>
                        <th style="width: 14%;">ژمارەی داواکاری</th>
                        <th style="width: 14%;">بەروار و کات</th>
                        <th style="width: 20%;">زانیاری نەخۆش</th>
                        <th style="width: 18%;">وەرگرتنی نموونە & نەخشە</th>
                        <th style="width: 18%;">پشکنینەکان</th>
                        <th style="width: 16%;">پارەدان & کۆی گشتی</th>
                        <th style="width: 14%;">بارودۆخ</th>
                        <th style="width: 8%; text-align: center;">وردەکاری</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($orders as $order)
                        @php
                            $details = is_array($order->patient_details) ? $order->patient_details : (json_decode($order->patient_details, true) ?? []);
                            $loc = is_array($order->location_details) ? $order->location_details : (json_decode($order->location_details, true) ?? []);
                            $patientName = $details['full_name'] ?? $details['name'] ?? $order->patient?->name ?? 'نەخۆش';
                            $patientPhone = $details['phone'] ?? $order->patient?->phone ?? 'نەزانراو';
                            $patientAge = $details['age'] ?? $details['patient_age'] ?? null;
                            $patientGender = $details['gender'] ?? null;
                            $collectionMethod = $details['sample_collection_method'] ?? ($order->extra_fee > 0 ? 'home' : 'lab');
                            $address = $details['address'] ?? $details['location_name'] ?? $loc['address'] ?? 'هەولێر';
                            
                            $lat = $loc['latitude'] ?? $details['latitude'] ?? null;
                            $lng = $loc['longitude'] ?? $details['longitude'] ?? null;
                            if ($lat && $lng) {
                                $mapUrl = "https://www.google.com/maps?q={$lat},{$lng}";
                            } else {
                                $mapUrl = "https://www.google.com/maps/search/?api=1&query=" . urlencode($address);
                            }

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
                                $paymentMethodKurdish = $order->payment_method ?? 'کاش';
                            }
                        @endphp
                        <tr>
                            <!-- Order ID -->
                            <td>
                                <div class="badge-ord">#ORD-{{ $order->id }}</div>
                            </td>

                            <!-- Date & Time (Clean Kurdish formatted) -->
                            <td>
                                <div style="font-weight: 700; color: #1e293b; font-size: 0.82rem;" dir="ltr">
                                    {{ $order->created_at->format('Y/m/d') }}
                                </div>
                                <div style="font-size: 0.75rem; color: #64748b; margin-top: 3px; font-weight: 600;" dir="ltr">
                                    🕒 {{ $order->created_at->format('h:i A') }}
                                </div>
                            </td>

                            <!-- Patient Info -->
                            <td>
                                <div style="font-weight: 800; color: #0f172a; font-size: 0.92rem; display: flex; align-items: center; gap: 6px;">
                                    <span>{{ $patientName }}</span>
                                    @if($patientGender)
                                        <span style="font-size: 0.68rem; padding: 1px 6px; border-radius: 6px; font-weight: 700; background: {{ $patientGender == 'female' ? '#fdf2f8; color: #db2777' : '#eff6ff; color: #2563eb' }};">
                                            {{ $patientGender == 'female' ? 'مێ' : 'نێر' }}
                                        </span>
                                    @endif
                                </div>
                                <div style="font-size: 0.8rem; color: #334155; margin-top: 4px; font-weight: 700;">
                                    <span style="color: #64748b; font-weight: 500;">مۆبایل:</span>
                                    <span style="color: #0f172a;" dir="ltr">{{ $patientPhone }}</span>
                                    @if($patientAge)
                                        <span style="color: #94a3b8; margin: 0 4px;">•</span>
                                        <span style="color: #64748b; font-weight: 600;">{{ $patientAge }} ساڵ</span>
                                    @endif
                                </div>
                            </td>

                            <!-- Sample Collection & Map -->
                            <td>
                                <div>
                                    @if($collectionMethod == 'home')
                                        <span class="badge-pill badge-home">
                                            🏠 لە ماڵەوە (Home)
                                        </span>
                                    @else
                                        <span class="badge-pill badge-lab">
                                            🏢 لە تاقیگە (Lab)
                                        </span>
                                    @endif
                                </div>
                                <div style="margin-top: 6px; display: flex; align-items: center; gap: 6px; flex-wrap: wrap;">
                                    <span style="font-size: 0.78rem; color: #475569; font-weight: 600; max-width: 120px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;" title="{{ $address }}">
                                        📍 {{ $address }}
                                    </span>
                                    <a href="{{ $mapUrl }}" target="_blank" class="map-btn" title="کردنەوەی نەخشەی گووگڵ">
                                        <svg style="width: 12px; height: 12px;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"/></svg>
                                        نەخشە
                                    </a>
                                </div>
                            </td>

                            <!-- Tests List -->
                            <td>
                                <div style="max-width: 200px;">
                                    @forelse($order->items as $item)
                                        <div class="test-item-chip">
                                            <span>{{ $item->item_name }}</span>
                                            <span style="color: #2563eb; font-size: 0.72rem; margin-right: 4px;" dir="ltr">{{ number_format($item->price) }}</span>
                                        </div>
                                    @empty
                                        <span style="font-size: 0.75rem; color: #94a3b8;">پشکنینی گشتی</span>
                                    @endforelse
                                </div>
                            </td>

                            <!-- Total Price & Translated Payment -->
                            <td>
                                <div style="font-weight: 900; color: #0f172a; font-size: 0.95rem;" dir="ltr">
                                    {{ number_format($order->total_price) }} IQD
                                </div>
                                <div style="font-size: 0.76rem; color: #059669; font-weight: 700; margin-top: 3px; background: #ecfdf5; display: inline-block; padding: 2px 8px; border-radius: 6px; border: 1px solid #a7f3d0;">
                                    💵 {{ $paymentMethodKurdish }}
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

                            <!-- View Form Modal -->
                            <td style="text-align: center;">
                                <button type="button" onclick="openOrderModal({{ json_encode($order) }}, {{ json_encode($details) }}, {{ json_encode($loc) }}, {{ json_encode($order->items) }})" 
                                        class="btn-detail">
                                    <svg style="width: 14px; height: 14px;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                                    بینین
                                </button>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="8" style="text-align: center; padding: 48px; color: #94a3b8;">
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

<!-- Detailed Form Modal -->
<div id="orderModal" style="position: fixed; inset: 0; z-index: 999; background: rgba(15,23,42,0.6); backdrop-filter: blur(4px); display: none; align-items: center; justify-content: center; padding: 16px;">
    <div style="background: #ffffff; border-radius: 20px; max-width: 640px; width: 100%; max-height: 90vh; overflow-y: auto; box-shadow: 0 20px 25px -5px rgba(0,0,0,0.2); padding: 24px; direction: rtl; text-align: right;">
        <div style="display: flex; align-items: center; justify-content: space-between; border-bottom: 1px solid #f1f5f9; padding-bottom: 14px;">
            <div>
                <h3 style="font-size: 1.1rem; font-weight: 800; color: #0f172a; margin: 0;" id="modalTitle">وردەکاری تەواوی داواکاری</h3>
                <p style="font-size: 0.75rem; color: #94a3b8; margin: 2px 0 0 0;" id="modalSubtitle">فۆڕمی پڕکراوە لەلایەن نەخۆشەوە</p>
            </div>
            <button type="button" onclick="closeOrderModal()" style="width: 32px; height: 32px; border-radius: 50%; background: #f1f5f9; border: none; color: #64748b; font-weight: 700; cursor: pointer; display: flex; align-items: center; justify-content: center;">
                ✕
            </button>
        </div>

        <div id="modalContent" style="display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 14px; margin-top: 16px; font-size: 0.85rem;">
            <!-- Dynamic JS injection -->
        </div>

        <div style="border-top: 1px solid #f1f5f9; margin-top: 20px; padding-top: 14px; display: flex; justify-content: flex-end;">
            <button type="button" onclick="closeOrderModal()" style="padding: 8px 20px; background: #f1f5f9; color: #334155; font-weight: 700; border-radius: 10px; border: none; cursor: pointer; font-size: 0.8rem;">
                داخستن
            </button>
        </div>
    </div>
</div>
@endsection

@section('scripts')
<script>
function openOrderModal(order, details, loc, items) {
    const modal = document.getElementById('orderModal');
    const content = document.getElementById('modalContent');
    const title = document.getElementById('modalTitle');
    const subtitle = document.getElementById('modalSubtitle');

    title.textContent = `داواکاری #ORD-${order.id}`;
    subtitle.textContent = `بەرواری تۆمارکردن: ${order.created_at}`;

    const patientName = details.full_name || details.name || (order.patient ? order.patient.name : 'نەخۆش');
    const patientPhone = details.phone || (order.patient ? order.patient.phone : 'نەزانراو');
    const patientAge = details.age || details.patient_age || 'دیارینەکراو';
    const gender = details.gender === 'female' ? 'مێ (Female)' : (details.gender === 'male' ? 'نێر (Male)' : 'دیارینەکراو');
    const collectionMethod = details.sample_collection_method === 'home' ? 'لە ماڵەوە (Home Sample)' : 'لە تاقیگە (Lab Visit)';
    const address = details.address || details.location_name || (loc ? loc.address : 'هەولێر');
    const notes = details.notes || details.description || 'تێبینی نییە';

    const lat = (loc && loc.latitude) || details.latitude || null;
    const lng = (loc && loc.longitude) || details.longitude || null;
    const mapLink = (lat && lng) 
        ? `https://www.google.com/maps?q=${lat},${lng}`
        : `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(address)}`;

    let itemsHtml = '';
    if (items && items.length > 0) {
        itemsHtml = items.map(it => `
            <div style="display: flex; align-items: center; justify-content: space-between; padding: 8px 12px; background: #f8fafc; border-radius: 10px; border: 1px solid #e2e8f0; font-size: 0.78rem; margin-bottom: 6px;">
                <span style="font-weight: 700; color: #1e293b;">${it.item_name}</span>
                <span style="font-weight: 700; color: #2563eb;" dir="ltr">${Number(it.price).toLocaleString()} IQD</span>
            </div>
        `).join('');
    } else {
        itemsHtml = '<div style="font-size: 0.78rem; color: #94a3b8; padding: 8px;">پشکنینی گشتی</div>';
    }

    content.innerHTML = `
        <div style="background: #eff6ff; padding: 14px; border-radius: 14px; border: 1px solid #dbeafe; grid-column: 1 / -1;">
            <div style="font-size: 0.75rem; font-weight: 800; color: #1e40af; text-transform: uppercase;">👤 زانیارییەکانی نەخۆش</div>
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(130px, 1fr)); gap: 10px; margin-top: 8px;">
                <div>
                    <span style="font-size: 0.7rem; color: #64748b; display: block;">ناوی نەخۆش:</span>
                    <strong style="color: #0f172a;">${patientName}</strong>
                </div>
                <div>
                    <span style="font-size: 0.7rem; color: #64748b; display: block;">ژمارەی مۆبایل:</span>
                    <span style="color: #0f172a; font-weight: 800;" dir="ltr">${patientPhone}</span>
                </div>
                <div>
                    <span style="font-size: 0.7rem; color: #64748b; display: block;">تەمەن:</span>
                    <strong style="color: #0f172a;">${patientAge} ساڵ</strong>
                </div>
                <div>
                    <span style="font-size: 0.7rem; color: #64748b; display: block;">ڕەگەز:</span>
                    <strong style="color: #0f172a;">${gender}</strong>
                </div>
            </div>
        </div>

        <div style="background: #f8fafc; padding: 14px; border-radius: 14px; border: 1px solid #e2e8f0;">
            <div style="font-size: 0.75rem; font-weight: 800; color: #334155; margin-bottom: 6px; display: flex; align-items: center; justify-content: space-between;">
                <span>📍 شوێن و نەخشە</span>
                <a href="${mapLink}" target="_blank" style="color: #dc2626; font-size: 0.72rem; font-weight: 700; text-decoration: none;">کردنەوەی نەخشە ↗</a>
            </div>
            <div style="font-size: 0.78rem; color: #475569; line-height: 1.6;">
                <div><strong>شێواز:</strong> <span style="color: #7e22ce; font-weight: 700;">${collectionMethod}</span></div>
                <div><strong>ناونیشان:</strong> ${address}</div>
                <div><strong>تێبینی نەخۆش:</strong> ${notes}</div>
            </div>
        </div>

        <div style="background: #f8fafc; padding: 14px; border-radius: 14px; border: 1px solid #e2e8f0;">
            <div style="font-size: 0.75rem; font-weight: 800; color: #334155; margin-bottom: 6px;">💳 پارەدان و کۆی گشتی</div>
            <div style="font-size: 0.78rem; color: #475569; line-height: 1.6;">
                <div><strong>شێوازی پارەدان:</strong> ${order.payment_method || 'کاش لەکاتی وەرگرتن'}</div>
                <div><strong>کۆی گشتی:</strong> <strong style="color: #059669; font-size: 0.95rem;" dir="ltr">${Number(order.total_price).toLocaleString()} IQD</strong></div>
                <div><strong>بارودۆخ:</strong> <span style="color: #2563eb; font-weight: 700;">${order.status}</span></div>
            </div>
        </div>

        <div style="grid-column: 1 / -1; margin-top: 4px;">
            <div style="font-size: 0.75rem; font-weight: 800; color: #334155; margin-bottom: 8px;">🧪 لیستی پشکنینە هەڵبژێردراوەکان</div>
            ${itemsHtml}
        </div>
    `;

    modal.style.display = 'flex';
}

function closeOrderModal() {
    document.getElementById('orderModal').style.display = 'none';
}
</script>
@endsection
