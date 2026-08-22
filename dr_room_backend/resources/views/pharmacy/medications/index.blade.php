@extends('pharmacy.layouts.app')

@section('content')
<div class="fade-up">
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px;">
        <div>
            <h2 style="font-size: 1.5rem; font-weight: 700; color: #0f172a;">دەرمانەکان (کۆگا)</h2>
            <p style="color: #64748b; font-size: 0.95rem;">بەڕێوەبردنی دەرمانەکان، نرخ، مەخزەن و پۆلێنەکان.</p>
        </div>
        <a href="{{ route('pharmacy.medications.create') }}" style="background: #0d9488; color: white; padding: 10px 20px; border-radius: 8px; font-weight: 600; display: inline-flex; align-items: center; gap: 8px; text-decoration: none;">
            <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
            زیادکردنی دەرمان
        </a>
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
                    <th style="padding: 16px; color: #64748b; font-weight: 600; font-size: 0.9rem;">وێنە</th>
                    <th style="padding: 16px; color: #64748b; font-weight: 600; font-size: 0.9rem;">ناوی دەرمان</th>
                    <th style="padding: 16px; color: #64748b; font-weight: 600; font-size: 0.9rem;">پۆلێن</th>
                    <th style="padding: 16px; color: #64748b; font-weight: 600; font-size: 0.9rem;">نرخ</th>
                    <th style="padding: 16px; color: #64748b; font-weight: 600; font-size: 0.9rem;">بڕ (مەخزەن)</th>
                    <th style="padding: 16px; color: #64748b; font-weight: 600; font-size: 0.9rem; text-align: left;">کردارەکان</th>
                </tr>
            </thead>
            <tbody>
                @forelse($medications as $medication)
                @php
                    $imgUrl = $medication->image_path 
                        ? (str_starts_with($medication->image_path, 'http') ? $medication->image_path : asset('storage/' . $medication->image_path)) 
                        : null;
                @endphp
                <tr style="border-bottom: 1px solid #f1f5f9;">
                    <td style="padding: 16px;">
                        @if($imgUrl)
                            <img src="{{ $imgUrl }}" alt="{{ $medication->name }}" style="width: 48px; height: 48px; border-radius: 8px; object-fit: cover; border: 1px solid #e2e8f0;">
                        @else
                            <div style="width: 48px; height: 48px; border-radius: 8px; background: #f1f5f9; display: flex; align-items: center; justify-content: center; color: #94a3b8;">
                                <svg width="24" height="24" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
                            </div>
                        @endif
                    </td>
                    <td style="padding: 16px;">
                        <div style="font-weight: 600; color: #1e293b;">{{ $medication->name }}</div>
                        @if($medication->badge)
                            <span style="background: #fef3c7; color: #b45309; padding: 2px 8px; border-radius: 6px; font-size: 0.75rem; font-weight: 600;">{{ $medication->badge }}</span>
                        @endif
                    </td>
                    <td style="padding: 16px; color: #475569; font-weight: 500;">
                        <span style="background: #f1f5f9; padding: 4px 10px; border-radius: 8px; font-size: 0.85rem;">
                            {{ $medication->category ?? 'گشتی' }}
                        </span>
                    </td>
                    <td style="padding: 16px;">
                        <div style="color: #0d9488; font-weight: 800; font-size: 0.95rem;" dir="ltr">IQD {{ number_format($medication->price) }}</div>
                        @if($medication->original_price && $medication->original_price > $medication->price)
                            <div style="display: flex; align-items: center; gap: 6px; margin-top: 2px;">
                                <span style="text-decoration: line-through; color: #94a3b8; font-size: 0.78rem;" dir="ltr">IQD {{ number_format($medication->original_price) }}</span>
                                @if($medication->discount_percent)
                                    <span style="background: #fef2f2; color: #dc2626; font-size: 0.7rem; font-weight: 800; padding: 1px 6px; border-radius: 6px;">-{{ $medication->discount_percent }}%</span>
                                @endif
                            </div>
                        @endif
                    </td>
                    <td style="padding: 16px;">
                        <span style="background: {{ $medication->stock > 0 ? '#dcfce7' : '#fee2e2' }}; color: {{ $medication->stock > 0 ? '#166534' : '#991b1b' }}; padding: 4px 12px; border-radius: 12px; font-size: 0.85rem; font-weight: 600;">
                            {{ $medication->stock > 0 ? $medication->stock . ' دانە' : 'نەماوە' }}
                        </span>
                    </td>
                    <td style="padding: 16px; text-align: left;">
                        <a href="{{ route('pharmacy.medications.edit', $medication) }}" style="color: #3b82f6; background: #eff6ff; padding: 6px 12px; border-radius: 6px; text-decoration: none; display: inline-flex; align-items: center; gap: 4px; font-size: 0.85rem; font-weight: 600; margin-left: 8px;">
                            دەستکاری
                        </a>
                        <form action="{{ route('pharmacy.medications.destroy', $medication) }}" method="POST" style="display: inline-block;" onsubmit="return confirm('دڵنیایت لە سڕینەوەی ئەم دەرمانە؟');">
                            @csrf
                            @method('DELETE')
                            <button type="submit" style="color: #ef4444; background: #fef2f2; padding: 6px 12px; border-radius: 6px; text-decoration: none; display: inline-flex; align-items: center; gap: 4px; font-size: 0.85rem; font-weight: 600; border: none; cursor: pointer;">
                                سڕینەوە
                            </button>
                        </form>
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="6" style="padding: 32px; text-align: center; color: #94a3b8;">هیچ دەرمانێک نییە. یەکەم دەرمان زیاد بکە.</td>
                </tr>
                @endforelse
            </tbody>
        </table>
        
        <div style="padding: 16px; border-top: 1px solid #f1f5f9;">
            {{ $medications->links() }}
        </div>
    </div>
</div>
@endsection
