@extends('pharmacy.layouts.app')

@section('content')
<div class="fade-up">
    <div style="margin-bottom: 24px;">
        <h2 style="font-size: 1.5rem; font-weight: 700; color: #0f172a;">ڕاپۆرتی داهات</h2>
        <p style="color: #64748b; font-size: 0.95rem;">داهاتی دەرمانخانەکەت لێرە ببینە.</p>
    </div>

    <!-- Earnings Cards -->
    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 24px; margin-bottom: 32px;">
        <div style="background: white; border-radius: 16px; padding: 24px; border: 1px solid #f1f5f9; display: flex; align-items: center; gap: 16px;">
            <div style="width: 60px; height: 60px; border-radius: 16px; background: #f0fdfa; color: #0d9488; display: flex; align-items: center; justify-content: center;">
                <svg width="32" height="32" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
            </div>
            <div>
                <p style="color: #64748b; font-size: 0.9rem; font-weight: 600;">داهاتی ئەمڕۆ</p>
                <h3 style="font-size: 1.6rem; font-weight: 700; color: #1e293b; margin-top: 4px;">IQD {{ number_format($todayEarnings) }}</h3>
            </div>
        </div>
        
        <div style="background: white; border-radius: 16px; padding: 24px; border: 1px solid #f1f5f9; display: flex; align-items: center; gap: 16px;">
            <div style="width: 60px; height: 60px; border-radius: 16px; background: #eff6ff; color: #2563eb; display: flex; align-items: center; justify-content: center;">
                <svg width="32" height="32" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"/></svg>
            </div>
            <div>
                <p style="color: #64748b; font-size: 0.9rem; font-weight: 600;">داهاتی ئەم مانگە</p>
                <h3 style="font-size: 1.6rem; font-weight: 700; color: #1e293b; margin-top: 4px;">IQD {{ number_format($monthEarnings) }}</h3>
            </div>
        </div>
        
        <div style="background: white; border-radius: 16px; padding: 24px; border: 1px solid #f1f5f9; display: flex; align-items: center; gap: 16px;">
            <div style="width: 60px; height: 60px; border-radius: 16px; background: #fdf4ff; color: #c026d3; display: flex; align-items: center; justify-content: center;">
                <svg width="32" height="32" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
            </div>
            <div>
                <p style="color: #64748b; font-size: 0.9rem; font-weight: 600;">کۆی گشتی داهات</p>
                <h3 style="font-size: 1.6rem; font-weight: 700; color: #1e293b; margin-top: 4px;">IQD {{ number_format($totalEarnings) }}</h3>
            </div>
        </div>
    </div>

    <!-- Recent Earning History -->
    <div style="background: white; border-radius: 16px; border: 1px solid #f1f5f9; overflow: hidden;">
        <div style="padding: 20px 24px; border-bottom: 1px solid #f1f5f9;">
            <h3 style="font-size: 1.1rem; font-weight: 700; color: #0f172a;">مێژووی دوایین داهاتەکان</h3>
        </div>
        <table style="width: 100%; border-collapse: collapse; text-align: right;">
            <thead style="background: #f8fafc; border-bottom: 1px solid #f1f5f9;">
                <tr>
                    <th style="padding: 16px; color: #64748b; font-weight: 600; font-size: 0.9rem;">ژمارەی داواکاری</th>
                    <th style="padding: 16px; color: #64748b; font-weight: 600; font-size: 0.9rem;">کات</th>
                    <th style="padding: 16px; color: #64748b; font-weight: 600; font-size: 0.9rem;">بڕی پارە</th>
                </tr>
            </thead>
            <tbody>
                @forelse($recentOrders as $order)
                <tr style="border-bottom: 1px solid #f1f5f9;">
                    <td style="padding: 16px; font-weight: 600; color: #1e293b;">#{{ $order->id }}</td>
                    <td style="padding: 16px; color: #64748b; font-size: 0.95rem;">{{ $order->created_at->format('Y-m-d H:i') }}</td>
                    <td style="padding: 16px; color: #0d9488; font-weight: 700;">+ IQD {{ number_format($order->total_price) }}</td>
                </tr>
                @empty
                <tr>
                    <td colspan="3" style="padding: 32px; text-align: center; color: #94a3b8;">هیچ داهاتێک بوونی نییە.</td>
                </tr>
                @endforelse
            </tbody>
        </table>
    </div>
</div>
@endsection
