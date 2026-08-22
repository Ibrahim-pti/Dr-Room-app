@extends('pharmacy.layouts.app')

@section('content')
@php
    // Parse patient details cleanly
    $details = is_string($order->patient_details) ? json_decode($order->patient_details, true) : ($order->patient_details ?? []);
    if (!is_array($details)) $details = [];
    
    $patientName = $details['name'] ?? $details['patient_name'] ?? ($order->patient->name ?? 'کڕیاری DrRoom');
    $patientPhone = $details['phone'] ?? $details['patient_phone'] ?? ($order->patient->phone ?? '-');
    $patientAge = $details['age'] ?? $details['patient_age'] ?? null;
    $patientGender = $details['gender'] ?? $details['patient_gender'] ?? null;

    // Parse location details cleanly
    $loc = is_string($order->location_details) ? json_decode($order->location_details, true) : $order->location_details;
    if (is_array($loc)) {
        $addressText = $loc['address_text'] ?? $loc['address'] ?? ($loc['address_name'] ?? 'هەولێر');
        $lat = !empty($loc['latitude']) ? floatval($loc['latitude']) : 36.1911;
        $lng = !empty($loc['longitude']) ? floatval($loc['longitude']) : 44.0092;
    } else {
        $addressText = !empty($order->location_details) ? $order->location_details : 'هەولێر';
        $lat = 36.1911;
        $lng = 44.0092;
    }
@endphp

<div class="fade-up space-y-6">
    <!-- Top Header -->
    <div style="background: white; padding: 20px 24px; border-radius: 18px; border: 1px solid #e2e8f0; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 16px;">
        <div style="display: flex; align-items: center; gap: 14px;">
            <div style="width: 48px; height: 48px; border-radius: 14px; background: #f0fdfa; display: flex; align-items: center; justify-content: center; color: #0d9488;">
                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" width="26" height="26"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"/></svg>
            </div>
            <div>
                <div style="display: flex; align-items: center; gap: 10px;">
                    <h2 style="font-size: 1.35rem; font-weight: 800; color: #0f172a; margin: 0;">وردەکاری داواکاری #{{ $order->id }}</h2>
                    @if($order->status === 'pending')
                        <span style="background: #fffbeb; color: #b45309; border: 1px solid #fde68a; padding: 4px 12px; border-radius: 12px; font-size: 0.8rem; font-weight: 800;">لە چاوەڕوانیدا</span>
                    @elseif($order->status === 'accepted')
                        <span style="background: #eff6ff; color: #1d4ed8; border: 1px solid #bfdbfe; padding: 4px 12px; border-radius: 12px; font-size: 0.8rem; font-weight: 800;">لە ئامادەکردندایە</span>
                    @elseif($order->status === 'completed')
                        <span style="background: #ecfdf5; color: #047857; border: 1px solid #a7f3d0; padding: 4px 12px; border-radius: 12px; font-size: 0.8rem; font-weight: 800;">تەواوکراو (گەیەنرا)</span>
                    @else
                        <span style="background: #fef2f2; color: #b91c1c; border: 1px solid #fecaca; padding: 4px 12px; border-radius: 12px; font-size: 0.8rem; font-weight: 800;">ڕەتکرایەوە</span>
                    @endif
                </div>
                <p style="color: #64748b; font-size: 0.88rem; margin: 4px 0 0 0;">کاتی تۆمارکردن: {{ $order->created_at->format('Y-m-d H:i') }} ({{ $order->created_at->diffForHumans() }})</p>
            </div>
        </div>

        <div style="display: flex; align-items: center; gap: 10px;">
            <a href="{{ route('pharmacy.orders.index') }}" style="background: #f8fafc; color: #475569; border: 1px solid #e2e8f0; padding: 10px 20px; border-radius: 12px; font-weight: 700; font-size: 0.88rem; text-decoration: none; display: inline-flex; align-items: center; gap: 6px; transition: all 0.2s;">
                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" width="18" height="18"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 5l7 7m0 0l-7 7m7-7H3"/></svg>
                گەڕانەوە بۆ داواکارییەکان
            </a>
        </div>
    </div>

    @if(session('success'))
        <div style="background: #ecfdf5; border: 1px solid #a7f3d0; color: #047857; padding: 14px 20px; border-radius: 14px; font-weight: 700; font-size: 0.9rem; display: flex; align-items: center; gap: 10px;">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" width="20" height="20"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
            {{ session('success') }}
        </div>
    @endif

    @if($errors->any())
        <div style="background: #fef2f2; border: 1px solid #fecaca; color: #b91c1c; padding: 14px 20px; border-radius: 14px; font-weight: 700; font-size: 0.9rem;">
            {{ $errors->first() }}
        </div>
    @endif

    <div style="display: grid; grid-template-columns: 1.5fr 1fr; gap: 24px;">
        <!-- Left Column: Medications Table -->
        <div class="space-y-6">
            <div style="background: white; border-radius: 18px; border: 1px solid #e2e8f0; padding: 24px; box-shadow: 0 1px 3px rgba(0,0,0,0.02);">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; border-bottom: 1px solid #f1f5f9; padding-bottom: 14px;">
                    <h3 style="font-size: 1.15rem; font-weight: 800; color: #0f172a; margin: 0; display: flex; align-items: center; gap: 8px;">
                        <svg fill="none" stroke="#0d9488" viewBox="0 0 24 24" width="22" height="22"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"/></svg>
                        دەرمانە داواکراوەکان
                    </h3>
                    <span style="background: #f0fdfa; color: #0d9488; font-weight: 800; font-size: 0.8rem; padding: 4px 10px; border-radius: 10px;">
                        {{ count($order->items) }} جۆر دەرمان
                    </span>
                </div>
                
                <table style="width: 100%; border-collapse: collapse; text-align: right;">
                    <thead style="background: #f8fafc; border-radius: 10px;">
                        <tr>
                            <th style="padding: 14px 16px; color: #475569; font-weight: 800; font-size: 0.82rem;">ناوی دەرمان</th>
                            <th style="padding: 14px 16px; color: #475569; font-weight: 800; font-size: 0.82rem; text-align: center;">نرخی تاک</th>
                            <th style="padding: 14px 16px; color: #475569; font-weight: 800; font-size: 0.82rem; text-align: center;">ژمارە</th>
                            <th style="padding: 14px 16px; color: #475569; font-weight: 800; font-size: 0.82rem; text-align: left;">کۆی گشتی</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach($order->items as $item)
                        <tr style="border-bottom: 1px solid #f1f5f9;">
                            <td style="padding: 16px; font-weight: 700; color: #1e293b;">
                                {{ $item->item_name }}
                            </td>
                            <td style="padding: 16px; color: #64748b; font-weight: 600; text-align: center;" dir="ltr">
                                IQD {{ number_format($item->price) }}
                            </td>
                            <td style="padding: 16px; font-weight: 800; text-align: center; color: #0f172a;">
                                <span style="background: #f1f5f9; padding: 4px 12px; border-radius: 8px;">{{ $item->quantity }}</span>
                            </td>
                            <td style="padding: 16px; color: #0d9488; font-weight: 800; text-align: left;" dir="ltr">
                                IQD {{ number_format($item->price * $item->quantity) }}
                            </td>
                        </tr>
                        @endforeach
                    </tbody>
                </table>
                
                <!-- Financial Breakdown -->
                <div style="margin-top: 24px; background: #f8fafc; border-radius: 14px; padding: 18px 20px; border: 1px solid #e2e8f0;">
                    <div style="display: flex; justify-content: space-between; margin-bottom: 10px; color: #64748b; font-size: 0.9rem; font-weight: 600;">
                        <span>نرخی سەرجەم دەرمانەکان:</span>
                        <span style="font-weight: 700; color: #1e293b;" dir="ltr">IQD {{ number_format($order->subtotal) }}</span>
                    </div>
                    <div style="display: flex; justify-content: space-between; margin-bottom: 10px; color: #64748b; font-size: 0.9rem; font-weight: 600;">
                        <span>کرێی گەیاندنی دەرمانخانە:</span>
                        <span style="font-weight: 700; color: #1e293b;" dir="ltr">IQD {{ number_format($order->extra_fee) }}</span>
                    </div>
                    <div style="border-top: 1px dashed #cbd5e1; margin-top: 10px; padding-top: 12px; display: flex; justify-content: space-between; align-items: center;">
                        <span style="font-size: 1.1rem; font-weight: 800; color: #0f172a;">کۆی پارەی داواکراو:</span>
                        <span style="font-size: 1.35rem; font-weight: 800; color: #0d9488;" dir="ltr">IQD {{ number_format($order->total_price) }}</span>
                    </div>
                </div>
            </div>
        </div>

        <!-- Right Column: Customer Info, Location Map & Actions -->
        <div class="space-y-6">
            <!-- Customer Information Card -->
            <div style="background: white; border-radius: 18px; border: 1px solid #e2e8f0; padding: 24px; box-shadow: 0 1px 3px rgba(0,0,0,0.02);">
                <h3 style="font-size: 1.15rem; font-weight: 800; color: #0f172a; margin: 0 0 18px 0; display: flex; align-items: center; gap: 8px; border-bottom: 1px solid #f1f5f9; padding-bottom: 12px;">
                    <svg fill="none" stroke="#2563eb" viewBox="0 0 24 24" width="22" height="22"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/></svg>
                    زانیاری کڕیار و ناونیشان
                </h3>

                <div style="display: flex; flex-direction: column; gap: 14px;">
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                        <span style="color: #64748b; font-size: 0.85rem; font-weight: 600;">ناوی نەخۆش / کڕیار:</span>
                        <span style="font-weight: 800; color: #0f172a; font-size: 0.92rem;">{{ $patientName }}</span>
                    </div>

                    <div style="display: flex; justify-content: space-between; align-items: center;">
                        <span style="color: #64748b; font-size: 0.85rem; font-weight: 600;">ژمارەی مۆبایل:</span>
                        <a href="tel:{{ $patientPhone }}" style="font-weight: 800; color: #2563eb; text-decoration: none; direction: ltr; font-size: 0.95rem;">
                            {{ $patientPhone }}
                        </a>
                    </div>

                    @if($patientGender)
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                        <span style="color: #64748b; font-size: 0.85rem; font-weight: 600;">ڕەگەز:</span>
                        <span style="font-weight: 700; color: #334155;">{{ $patientGender == 'male' ? 'نێر' : ($patientGender == 'female' ? 'مێ' : $patientGender) }}</span>
                    </div>
                    @endif

                    @if($patientAge)
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                        <span style="color: #64748b; font-size: 0.85rem; font-weight: 600;">تەمەن:</span>
                        <span style="font-weight: 700; color: #334155;">{{ $patientAge }} ساڵ</span>
                    </div>
                    @endif

                    <div style="display: flex; justify-content: space-between; align-items: center;">
                        <span style="color: #64748b; font-size: 0.85rem; font-weight: 600;">شێوازی پارەدان:</span>
                        <span style="font-weight: 800; color: #047857; background: #ecfdf5; padding: 3px 10px; border-radius: 8px; font-size: 0.82rem;">
                            {{ $order->payment_method == 'cash' ? 'پارەدانی کاش (دەستبەدەست)' : $order->payment_method }}
                        </span>
                    </div>

                    <div style="margin-top: 4px;">
                        <span style="color: #64748b; font-size: 0.85rem; font-weight: 600; display: block; margin-bottom: 6px;">ناونیشانی گەیاندن:</span>
                        <div style="font-weight: 700; color: #1e293b; background: #f8fafc; padding: 10px 14px; border-radius: 10px; border: 1px solid #e2e8f0; font-size: 0.88rem; line-height: 1.5;">
                            📍 {{ $addressText }}
                        </div>
                    </div>

                    <!-- Interactive Delivery Map -->
                    <div style="margin-top: 8px;">
                        <span style="color: #64748b; font-size: 0.82rem; font-weight: 700; margin-bottom: 6px; display: block;">لۆکەیشنی سەر نەخشە:</span>
                        <div id="deliveryMap" style="width: 100%; height: 200px; border-radius: 14px; border: 1px solid #e2e8f0; z-index: 1;"></div>
                    </div>
                </div>
            </div>

            <!-- Actions Card -->
            <div style="background: white; border-radius: 18px; border: 1px solid #e2e8f0; padding: 24px; box-shadow: 0 1px 3px rgba(0,0,0,0.02);">
                <h3 style="font-size: 1.15rem; font-weight: 800; color: #0f172a; margin: 0 0 16px 0; border-bottom: 1px solid #f1f5f9; padding-bottom: 12px;">
                    کردار و گۆڕینی دۆخ
                </h3>
                
                @if($order->status === 'pending')
                    <form action="{{ route('pharmacy.orders.status', $order->id) }}" method="POST">
                        @csrf
                        <input type="hidden" name="status" value="accepted">
                        <button type="submit" style="width: 100%; background: #0d9488; color: white; padding: 14px; border-radius: 12px; font-weight: 800; font-size: 0.95rem; border: none; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 8px; box-shadow: 0 4px 12px rgba(13,148,136,0.3); transition: all 0.2s;">
                            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" width="20" height="20"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
                            وەرگرتنی داواکاری (قبوڵکردن)
                        </button>
                    </form>
                @elseif($order->status === 'accepted')
                    <div style="display: flex; flex-direction: column; gap: 10px;">
                        <form action="{{ route('pharmacy.orders.status', $order->id) }}" method="POST">
                            @csrf
                            <input type="hidden" name="status" value="completed">
                            <button type="submit" style="width: 100%; background: #059669; color: white; padding: 14px; border-radius: 12px; font-weight: 800; font-size: 0.95rem; border: none; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 8px; box-shadow: 0 4px 12px rgba(5,150,105,0.3); transition: all 0.2s;">
                                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" width="20" height="20"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                                تەواوکردنی داواکاری (گەیەنرا بە سەرکەوتوویی)
                            </button>
                        </form>
                        <form action="{{ route('pharmacy.orders.status', $order->id) }}" method="POST">
                            @csrf
                            <input type="hidden" name="status" value="cancelled">
                            <button type="submit" style="width: 100%; background: white; color: #ef4444; border: 1.5px solid #ef4444; padding: 12px; border-radius: 12px; font-weight: 700; font-size: 0.9rem; cursor: pointer; transition: all 0.2s;">
                                ڕەتکردنەوەی داواکاری
                            </button>
                        </form>
                    </div>
                @else
                    <div style="text-align: center; padding: 16px; background: #f8fafc; border-radius: 12px; color: #64748b; font-weight: 700; border: 1px dashed #cbd5e1;">
                        ئەم داواکارییە داخراوە و کارەکانی تەواو بووە.
                    </div>
                @endif
            </div>
        </div>
    </div>
</div>

<script>
    document.addEventListener('DOMContentLoaded', function() {
        var lat = {{ $lat }};
        var lng = {{ $lng }};
        var map = L.map('deliveryMap').setView([lat, lng], 15);
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 19,
            attribution: '© OpenStreetMap'
        }).addTo(map);

        var marker = L.marker([lat, lng]).addTo(map);
        marker.bindPopup("<div style='font-family:Rabar, sans-serif; font-weight:bold;'>📍 " + {!! json_encode($addressText) !!} + "</div>").openPopup();
    });
</script>
@endsection
