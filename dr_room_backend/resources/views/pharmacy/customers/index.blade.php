@extends('pharmacy.layouts.app')

@section('content')
<div class="fade-up">
    <div style="margin-bottom: 24px;">
        <h2 style="font-size: 1.5rem; font-weight: 700; color: #0f172a;">کڕیارەکان</h2>
        <p style="color: #64748b; font-size: 0.95rem;">لیستی ئەو کڕیارانەی کە پێشتر داواکاریان لای تۆ کردووە.</p>
    </div>

    <div style="background: white; border-radius: 16px; border: 1px solid #f1f5f9; overflow: hidden;">
        <table style="width: 100%; border-collapse: collapse; text-align: right;">
            <thead style="background: #f8fafc; border-bottom: 1px solid #f1f5f9;">
                <tr>
                    <th style="padding: 16px; color: #64748b; font-weight: 600; font-size: 0.9rem;">ناوی کڕیار</th>
                    <th style="padding: 16px; color: #64748b; font-weight: 600; font-size: 0.9rem;">مۆبایل</th>
                    <th style="padding: 16px; color: #64748b; font-weight: 600; font-size: 0.9rem;">کۆی داواکارییەکان</th>
                    <th style="padding: 16px; color: #64748b; font-weight: 600; font-size: 0.9rem;">کۆی پارەی خەرجکراو</th>
                    <th style="padding: 16px; color: #64748b; font-weight: 600; font-size: 0.9rem;">کۆتا داواکاری</th>
                </tr>
            </thead>
            <tbody>
                @forelse($customers as $customer)
                <tr style="border-bottom: 1px solid #f1f5f9;">
                    <td style="padding: 16px; font-weight: 600; color: #1e293b;">
                        <div style="display: flex; align-items: center; gap: 12px;">
                            <div style="width: 40px; height: 40px; border-radius: 50%; background: #f0fdfa; color: #0d9488; display: flex; align-items: center; justify-content: center; font-weight: 700;">
                                {{ mb_substr($customer['name'], 0, 1) }}
                            </div>
                            {{ $customer['name'] }}
                        </div>
                    </td>
                    <td style="padding: 16px; font-weight: 500; color: #334155;" dir="ltr" style="text-align: right;">{{ $customer['phone'] }}</td>
                    <td style="padding: 16px; font-weight: 600; color: #64748b;">{{ $customer['total_orders'] }} داواکاری</td>
                    <td style="padding: 16px; color: #0d9488; font-weight: 600;">IQD {{ number_format($customer['total_spent']) }}</td>
                    <td style="padding: 16px; color: #64748b; font-size: 0.9rem;">{{ \Carbon\Carbon::parse($customer['last_order'])->diffForHumans() }}</td>
                </tr>
                @empty
                <tr>
                    <td colspan="5" style="padding: 32px; text-align: center; color: #94a3b8;">هیچ کڕیارێک نییە کە داواکاری تەواوکراوی هەبێت.</td>
                </tr>
                @endforelse
            </tbody>
        </table>
    </div>
</div>
@endsection
