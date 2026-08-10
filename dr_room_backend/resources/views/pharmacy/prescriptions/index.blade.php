@extends('pharmacy.layouts.app')

@section('content')
<div class="fade-up">
    <div style="margin-bottom: 24px;">
        <h2 style="font-size: 1.5rem; font-weight: 700; color: #0f172a;">ڕەچەتەکان</h2>
        <p style="color: #64748b; font-size: 0.95rem;">ئەو ڕەچەتانەی لەلایەن پزیشکەوە نێردراون لێرە دەردەکەون.</p>
    </div>

    @if(session('success'))
        <div style="background: #d1fae5; color: #065f46; padding: 12px; border-radius: 8px; margin-bottom: 20px;">
            {{ session('success') }}
        </div>
    @endif

    <div style="background: white; border-radius: 16px; border: 1px solid #f1f5f9; overflow: hidden;">
        <table style="width: 100%; border-collapse: collapse; text-align: right;">
            <thead style="background: #f8fafc; border-bottom: 1px solid #f1f5f9;">
                <tr>
                    <th style="padding: 16px; color: #64748b; font-weight: 600; font-size: 0.9rem;">ژمارەی ڕەچەتە</th>
                    <th style="padding: 16px; color: #64748b; font-weight: 600; font-size: 0.9rem;">نەخۆش</th>
                    <th style="padding: 16px; color: #64748b; font-weight: 600; font-size: 0.9rem;">پزیشک</th>
                    <th style="padding: 16px; color: #64748b; font-weight: 600; font-size: 0.9rem;">دۆخ</th>
                    <th style="padding: 16px; color: #64748b; font-weight: 600; font-size: 0.9rem; text-align: left;">کردارەکان</th>
                </tr>
            </thead>
            <tbody>
                @forelse($prescriptions as $prescription)
                <tr style="border-bottom: 1px solid #f1f5f9;">
                    <td style="padding: 16px; font-weight: 600; color: #1e293b;">#{{ $prescription->id }}</td>
                    <td style="padding: 16px; font-weight: 500; color: #334155;">-</td>
                    <td style="padding: 16px; color: #64748b;">-</td>
                    <td style="padding: 16px;">
                        <span style="background: #fffbeb; color: #d97706; padding: 4px 12px; border-radius: 12px; font-size: 0.85rem; font-weight: 600;">چاوەڕێکراو</span>
                    </td>
                    <td style="padding: 16px; text-align: left;">
                        <form action="{{ route('pharmacy.prescriptions.dispense', $prescription->id) }}" method="POST">
                            @csrf
                            <button type="submit" style="color: white; background: #0d9488; padding: 6px 12px; border-radius: 6px; text-decoration: none; display: inline-flex; align-items: center; gap: 4px; font-size: 0.85rem; font-weight: 600; border: none; cursor: pointer;">
                                ئامادەکرا
                            </button>
                        </form>
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="5" style="padding: 32px; text-align: center; color: #94a3b8;">لە ئێستادا هیچ ڕەچەتەیەکی نوێ نییە.</td>
                </tr>
                @endforelse
            </tbody>
        </table>
    </div>
</div>
@endsection
