@extends('pharmacy.layouts.app')

@section('content')
<div class="fade-up">
    <div style="margin-bottom: 24px; display: flex; justify-content: space-between; align-items: center;">
        <div>
            <h2 style="font-size: 1.5rem; font-weight: 700; color: #0f172a;">وردەکاری داواکاری #{{ $order->id }}</h2>
            <p style="color: #64748b; font-size: 0.95rem;">کات: {{ $order->created_at->format('Y-m-d H:i') }}</p>
        </div>
        <a href="{{ route('pharmacy.orders.index') }}" style="background: #f1f5f9; color: #64748b; padding: 10px 20px; border-radius: 8px; font-weight: 600; text-decoration: none;">
            گەڕانەوە
        </a>
    </div>

    @if(session('success'))
        <div style="background: #d1fae5; color: #065f46; padding: 12px; border-radius: 8px; margin-bottom: 20px;">
            {{ session('success') }}
        </div>
    @endif
    @if($errors->any())
        <div style="background: #fef2f2; color: #991b1b; padding: 12px; border-radius: 8px; margin-bottom: 20px;">
            {{ $errors->first() }}
        </div>
    @endif

    <div style="display: grid; grid-template-columns: 2fr 1fr; gap: 24px;">
        <!-- Left Side: Order Items -->
        <div>
            <div style="background: white; border-radius: 16px; border: 1px solid #f1f5f9; padding: 24px; margin-bottom: 24px;">
                <h3 style="font-size: 1.1rem; font-weight: 700; color: #0f172a; margin-bottom: 16px;">دەرمانە داواکراوەکان</h3>
                
                <table style="width: 100%; border-collapse: collapse; text-align: right;">
                    <thead style="background: #f8fafc; border-bottom: 1px solid #f1f5f9;">
                        <tr>
                            <th style="padding: 12px; color: #64748b; font-weight: 600;">دەرمان</th>
                            <th style="padding: 12px; color: #64748b; font-weight: 600;">نرخی دانە</th>
                            <th style="padding: 12px; color: #64748b; font-weight: 600;">بڕ</th>
                            <th style="padding: 12px; color: #64748b; font-weight: 600;">کۆی نرخ</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach($order->items as $item)
                        <tr style="border-bottom: 1px solid #f1f5f9;">
                            <td style="padding: 12px; font-weight: 600; color: #1e293b;">{{ $item->item_name }}</td>
                            <td style="padding: 12px; color: #64748b;">IQD {{ number_format($item->price) }}</td>
                            <td style="padding: 12px; font-weight: 600;">{{ $item->quantity }}</td>
                            <td style="padding: 12px; color: #0d9488; font-weight: 600;">IQD {{ number_format($item->price * $item->quantity) }}</td>
                        </tr>
                        @endforeach
                    </tbody>
                </table>
                
                <div style="margin-top: 24px; border-top: 1px dashed #cbd5e1; padding-top: 16px;">
                    <div style="display: flex; justify-content: space-between; margin-bottom: 8px; color: #64748b;">
                        <span>نرخی کاڵاکان:</span>
                        <span>IQD {{ number_format($order->subtotal) }}</span>
                    </div>
                    <div style="display: flex; justify-content: space-between; margin-bottom: 8px; color: #64748b;">
                        <span>کرێی گەیاندن:</span>
                        <span>IQD {{ number_format($order->extra_fee) }}</span>
                    </div>
                    <div style="display: flex; justify-content: space-between; margin-top: 12px; font-size: 1.2rem; font-weight: 700; color: #0f172a;">
                        <span>کۆی گشتی:</span>
                        <span style="color: #0d9488;">IQD {{ number_format($order->total_price) }}</span>
                    </div>
                </div>
            </div>
        </div>

        <!-- Right Side: Details and Actions -->
        <div>
            <!-- Patient Details -->
            <div style="background: white; border-radius: 16px; border: 1px solid #f1f5f9; padding: 24px; margin-bottom: 24px;">
                <h3 style="font-size: 1.1rem; font-weight: 700; color: #0f172a; margin-bottom: 16px;">زانیاری کڕیار</h3>
                @php
                    $details = json_decode($order->patient_details, true) ?? [];
                @endphp
                <div style="margin-bottom: 12px;">
                    <span style="color: #64748b; font-size: 0.9rem;">ناو:</span>
                    <div style="font-weight: 600; color: #1e293b;">{{ $details['name'] ?? 'نەزانراو' }}</div>
                </div>
                <div style="margin-bottom: 12px;">
                    <span style="color: #64748b; font-size: 0.9rem;">مۆبایل:</span>
                    <div style="font-weight: 600; color: #1e293b;" dir="ltr" style="text-align: right;">{{ $details['phone'] ?? 'نەزانراو' }}</div>
                </div>
                <div style="margin-bottom: 12px;">
                    <span style="color: #64748b; font-size: 0.9rem;">ناونیشان:</span>
                    <div style="font-weight: 600; color: #1e293b;">{{ $order->location_details ?? 'دانەنراوە' }}</div>
                </div>
                <div style="margin-bottom: 12px;">
                    <span style="color: #64748b; font-size: 0.9rem;">شێوازی پارەدان:</span>
                    <div style="font-weight: 600; color: #1e293b;">{{ $order->payment_method }}</div>
                </div>
            </div>

            <!-- Actions -->
            <div style="background: white; border-radius: 16px; border: 1px solid #f1f5f9; padding: 24px;">
                <h3 style="font-size: 1.1rem; font-weight: 700; color: #0f172a; margin-bottom: 16px;">کردارەکان</h3>
                
                @if($order->status === 'pending')
                    <form action="{{ route('pharmacy.orders.status', $order->id) }}" method="POST">
                        @csrf
                        <input type="hidden" name="status" value="accepted">
                        <button type="submit" style="width: 100%; background: #2563eb; color: white; padding: 12px; border-radius: 8px; font-weight: 600; border: none; cursor: pointer; margin-bottom: 12px;">
                            وەرگرتنی داواکاری (قبوڵکردن)
                        </button>
                    </form>
                @elseif($order->status === 'accepted')
                    <form action="{{ route('pharmacy.orders.status', $order->id) }}" method="POST">
                        @csrf
                        <input type="hidden" name="status" value="completed">
                        <button type="submit" style="width: 100%; background: #166534; color: white; padding: 12px; border-radius: 8px; font-weight: 600; border: none; cursor: pointer; margin-bottom: 12px;">
                            تەواوکردنی داواکاری (گەیەنرا)
                        </button>
                    </form>
                    <form action="{{ route('pharmacy.orders.status', $order->id) }}" method="POST">
                        @csrf
                        <input type="hidden" name="status" value="cancelled">
                        <button type="submit" style="width: 100%; background: white; color: #ef4444; border: 1px solid #ef4444; padding: 12px; border-radius: 8px; font-weight: 600; cursor: pointer;">
                            ڕەتکردنەوەی داواکاری
                        </button>
                    </form>
                @else
                    <div style="text-align: center; padding: 16px; background: #f8fafc; border-radius: 8px; color: #64748b; font-weight: 600;">
                        ئەم داواکارییە داخراوە ({{ $order->status }})
                    </div>
                @endif
            </div>
        </div>
    </div>
</div>
@endsection
