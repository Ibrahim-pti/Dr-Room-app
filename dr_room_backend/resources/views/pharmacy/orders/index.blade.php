@extends('pharmacy.layouts.app')

@section('content')
<div class="fade-up">
    <div style="margin-bottom: 24px;">
        <h2 style="font-size: 1.5rem; font-weight: 700; color: #0f172a;">داواکارییەکان</h2>
        <p style="color: #64748b; font-size: 0.95rem;">داواکارییەکانی کڕیاران لێرە دەردەکەون.</p>
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

    <div style="background: white; border-radius: 16px; border: 1px solid #f1f5f9; overflow: hidden;">
        <table style="width: 100%; border-collapse: collapse; text-align: right;">
            <thead style="background: #f8fafc; border-bottom: 1px solid #f1f5f9;">
                <tr>
                    <th style="padding: 16px; color: #64748b; font-weight: 600; font-size: 0.9rem;">ژمارە</th>
                    <th style="padding: 16px; color: #64748b; font-weight: 600; font-size: 0.9rem;">کڕیار</th>
                    <th style="padding: 16px; color: #64748b; font-weight: 600; font-size: 0.9rem;">بڕی پارە</th>
                    <th style="padding: 16px; color: #64748b; font-weight: 600; font-size: 0.9rem;">دۆخ</th>
                    <th style="padding: 16px; color: #64748b; font-weight: 600; font-size: 0.9rem;">کات</th>
                    <th style="padding: 16px; color: #64748b; font-weight: 600; font-size: 0.9rem; text-align: left;">کردارەکان</th>
                </tr>
            </thead>
            <tbody>
                @forelse($orders as $order)
                @php
                    $details = json_decode($order->patient_details, true) ?? [];
                    $name = $details['name'] ?? 'نەزانراو';
                @endphp
                <tr style="border-bottom: 1px solid #f1f5f9;">
                    <td style="padding: 16px; font-weight: 600; color: #1e293b;">#{{ $order->id }}</td>
                    <td style="padding: 16px; font-weight: 500; color: #334155;">{{ $name }}</td>
                    <td style="padding: 16px; color: #0d9488; font-weight: 600;">IQD {{ number_format($order->total_price) }}</td>
                    <td style="padding: 16px;">
                        @if($order->status === 'pending')
                            <span style="background: #fffbeb; color: #d97706; padding: 4px 12px; border-radius: 12px; font-size: 0.85rem; font-weight: 600;">چاوەڕێکراو</span>
                        @elseif($order->status === 'accepted')
                            <span style="background: #eff6ff; color: #2563eb; padding: 4px 12px; border-radius: 12px; font-size: 0.85rem; font-weight: 600;">لە ئامادەکردندایە</span>
                        @elseif($order->status === 'completed')
                            <span style="background: #dcfce7; color: #166534; padding: 4px 12px; border-radius: 12px; font-size: 0.85rem; font-weight: 600;">تەواوبوو</span>
                        @else
                            <span style="background: #fef2f2; color: #dc2626; padding: 4px 12px; border-radius: 12px; font-size: 0.85rem; font-weight: 600;">ڕەتکرایەوە</span>
                        @endif
                    </td>
                    <td style="padding: 16px; color: #64748b; font-size: 0.9rem;">{{ $order->created_at->diffForHumans() }}</td>
                    <td style="padding: 16px; text-align: left;">
                        <a href="{{ route('pharmacy.orders.show', $order->id) }}" style="color: white; background: #0d9488; padding: 6px 12px; border-radius: 6px; text-decoration: none; display: inline-flex; align-items: center; gap: 4px; font-size: 0.85rem; font-weight: 600;">
                            بینین
                        </a>
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="6" style="padding: 32px; text-align: center; color: #94a3b8;">هیچ داواکارییەک نییە.</td>
                </tr>
                @endforelse
            </tbody>
        </table>
        
        <div style="padding: 16px; border-top: 1px solid #f1f5f9;">
            {{ $orders->links() }}
        </div>
    </div>
</div>
@endsection
