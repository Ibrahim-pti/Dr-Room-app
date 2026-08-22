@extends('pharmacy.layouts.app')

@section('content')
<div class="fade-up space-y-6">
    <!-- Header with Stats -->
    <div style="background: white; padding: 20px 24px; border-radius: 18px; border: 1px solid #e2e8f0; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 16px;">
        <div>
            <div style="display: flex; align-items: center; gap: 10px;">
                <h2 style="font-size: 1.35rem; font-weight: 800; color: #0f172a; margin: 0;">داواکارییەکانی دەرمانخانە</h2>
                <span style="background: #f0fdfa; color: #0d9488; font-size: 0.78rem; font-weight: 800; padding: 3px 10px; border-radius: 20px; border: 1px solid #ccfbf1;">
                    کۆی گشتی: {{ $orders->total() }} داواکاری
                </span>
            </div>
            <p style="color: #64748b; font-size: 0.88rem; margin: 4px 0 0 0;">سەرجەم داواکارییە گەیشتووەکانی کڕیاران لێرە بەڕێوەببە.</p>
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

    <div style="background: white; border-radius: 18px; border: 1px solid #e2e8f0; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.02);">
        <table style="width: 100%; border-collapse: collapse; text-align: right;">
            <thead style="background: #f8fafc; border-bottom: 1px solid #e2e8f0;">
                <tr>
                    <th style="padding: 16px 20px; color: #475569; font-weight: 800; font-size: 0.82rem;">ژمارە</th>
                    <th style="padding: 16px 20px; color: #475569; font-weight: 800; font-size: 0.82rem;">کڕیار / نەخۆش</th>
                    <th style="padding: 16px 20px; color: #475569; font-weight: 800; font-size: 0.82rem;">دەرمانەکان</th>
                    <th style="padding: 16px 20px; color: #475569; font-weight: 800; font-size: 0.82rem;">بڕی پارە</th>
                    <th style="padding: 16px 20px; color: #475569; font-weight: 800; font-size: 0.82rem;">دۆخ</th>
                    <th style="padding: 16px 20px; color: #475569; font-weight: 800; font-size: 0.82rem;">کات</th>
                    <th style="padding: 16px 20px; color: #475569; font-weight: 800; font-size: 0.82rem; text-align: left;">کردار</th>
                </tr>
            </thead>
            <tbody>
                @forelse($orders as $order)
                @php
                    $details = is_string($order->patient_details) ? json_decode($order->patient_details, true) : ($order->patient_details ?? []);
                    $name = $details['name'] ?? $details['patient_name'] ?? ($order->patient->name ?? 'کڕیاری DrRoom');
                    $phone = $details['phone'] ?? $details['patient_phone'] ?? ($order->patient->phone ?? '-');
                @endphp
                <tr style="border-bottom: 1px solid #f1f5f9;">
                    <td style="padding: 16px 20px; font-weight: 800; color: #0f172a;">
                        <span style="background: #f1f5f9; padding: 4px 10px; border-radius: 8px; font-size: 0.85rem;">#{{ $order->id }}</span>
                    </td>
                    <td style="padding: 16px 20px;">
                        <div style="font-weight: 700; color: #1e293b;">{{ $name }}</div>
                        <div style="font-size: 0.78rem; color: #64748b; direction: ltr; text-align: right;">{{ $phone }}</div>
                    </td>
                    <td style="padding: 16px 20px; color: #475569; font-size: 0.85rem; font-weight: 600;">
                        {{ $order->items->pluck('item_name')->take(2)->join('، ') }}
                        @if($order->items->count() > 2)
                            <span style="color: #0d9488; font-weight: 700;">+{{ $order->items->count() - 2 }} تر</span>
                        @endif
                    </td>
                    <td style="padding: 16px 20px; color: #0d9488; font-weight: 800; font-size: 0.95rem;" dir="ltr">
                        IQD {{ number_format($order->total_price) }}
                    </td>
                    <td style="padding: 16px 20px;">
                        @if($order->status === 'pending')
                            <span style="background: #fffbeb; color: #b45309; border: 1px solid #fde68a; padding: 4px 12px; border-radius: 12px; font-size: 0.8rem; font-weight: 800;">لە چاوەڕوانیدا</span>
                        @elseif($order->status === 'accepted')
                            <span style="background: #eff6ff; color: #1d4ed8; border: 1px solid #bfdbfe; padding: 4px 12px; border-radius: 12px; font-size: 0.8rem; font-weight: 800;">لە ئامادەکردندایە</span>
                        @elseif($order->status === 'completed')
                            <span style="background: #ecfdf5; color: #047857; border: 1px solid #a7f3d0; padding: 4px 12px; border-radius: 12px; font-size: 0.8rem; font-weight: 800;">تەواوکراو</span>
                        @else
                            <span style="background: #fef2f2; color: #b91c1c; border: 1px solid #fecaca; padding: 4px 12px; border-radius: 12px; font-size: 0.8rem; font-weight: 800;">ڕەتکرایەوە</span>
                        @endif
                    </td>
                    <td style="padding: 16px 20px; color: #64748b; font-size: 0.85rem; font-weight: 600;">
                        {{ $order->created_at->diffForHumans() }}
                    </td>
                    <td style="padding: 16px 20px; text-align: left;">
                        <a href="{{ route('pharmacy.orders.show', $order->id) }}" style="color: white; background: #0d9488; padding: 8px 16px; border-radius: 10px; text-decoration: none; display: inline-flex; align-items: center; gap: 6px; font-size: 0.82rem; font-weight: 800; box-shadow: 0 2px 6px rgba(13,148,136,0.25); transition: all 0.2s;">
                            بینین و بەڕێوەبردن
                            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" width="16" height="16"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/></svg>
                        </a>
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="7" style="padding: 48px; text-align: center; color: #94a3b8; font-weight: 600;">هیچ داواکارییەک نەدۆزرایەوە.</td>
                </tr>
                @endforelse
            </tbody>
        </table>
        
        <div style="padding: 16px 20px; border-top: 1px solid #f1f5f9;">
            {{ $orders->links() }}
        </div>
    </div>
</div>
@endsection
