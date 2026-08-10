@extends('pharmacy.layouts.app')

@section('content')
<div class="fade-up">
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px;">
        <h2 style="font-size: 1.5rem; font-weight: 700; color: #0f172a;">ئۆفەرەکان</h2>
        <a href="{{ route('pharmacy.offers.create') }}" style="background: #0d9488; color: white; padding: 10px 20px; border-radius: 8px; font-weight: 600; display: inline-flex; align-items: center; gap: 8px; text-decoration: none;">
            <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
            زیادکردنی ئۆفەر
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
                    <th style="padding: 16px; color: #64748b; font-weight: 600; font-size: 0.9rem;">ناوی ئۆفەر</th>
                    <th style="padding: 16px; color: #64748b; font-weight: 600; font-size: 0.9rem;">داشکاندن</th>
                    <th style="padding: 16px; color: #64748b; font-weight: 600; font-size: 0.9rem;">دۆخ</th>
                    <th style="padding: 16px; color: #64748b; font-weight: 600; font-size: 0.9rem; text-align: left;">کردارەکان</th>
                </tr>
            </thead>
            <tbody>
                @forelse($offers as $offer)
                <tr style="border-bottom: 1px solid #f1f5f9;">
                    <td style="padding: 16px;">
                        @if($offer->image_path)
                            <img src="{{ Storage::url($offer->image_path) }}" alt="{{ $offer->title }}" style="width: 50px; height: 50px; border-radius: 8px; object-fit: cover;">
                        @else
                            <div style="width: 50px; height: 50px; border-radius: 8px; background: #f1f5f9; display: flex; align-items: center; justify-content: center; color: #94a3b8;">
                                <svg width="24" height="24" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v13m0-13V6a2 2 0 112 2h-2zm0 0V5.5A2.5 2.5 0 109.5 8H12zm-7 4h14M5 12a2 2 0 110-4h14a2 2 0 110 4M5 12v7a2 2 0 002 2h10a2 2 0 002-2v-7"/></svg>
                            </div>
                        @endif
                    </td>
                    <td style="padding: 16px; font-weight: 600; color: #1e293b;">{{ $offer->title }}</td>
                    <td style="padding: 16px; color: #ef4444; font-weight: 700;">{{ $offer->discount_percentage }}%</td>
                    <td style="padding: 16px;">
                        @if($offer->is_active)
                            <span style="background: #dcfce7; color: #166534; padding: 4px 12px; border-radius: 12px; font-size: 0.85rem; font-weight: 600;">چالاکە</span>
                        @else
                            <span style="background: #fef2f2; color: #991b1b; padding: 4px 12px; border-radius: 12px; font-size: 0.85rem; font-weight: 600;">ناچالاکە</span>
                        @endif
                    </td>
                    <td style="padding: 16px; text-align: left;">
                        <a href="{{ route('pharmacy.offers.edit', $offer) }}" style="color: #3b82f6; background: #eff6ff; padding: 6px 12px; border-radius: 6px; text-decoration: none; display: inline-flex; align-items: center; gap: 4px; font-size: 0.85rem; font-weight: 600; margin-left: 8px;">
                            دەستکاری
                        </a>
                        <form action="{{ route('pharmacy.offers.destroy', $offer) }}" method="POST" style="display: inline-block;" onsubmit="return confirm('دڵنیایت لە سڕینەوەی ئەم ئۆفەرە؟');">
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
                    <td colspan="5" style="padding: 32px; text-align: center; color: #94a3b8;">هیچ ئۆفەرێک نییە. یەکەم ئۆفەر زیاد بکە.</td>
                </tr>
                @endforelse
            </tbody>
        </table>
        
        <div style="padding: 16px; border-top: 1px solid #f1f5f9;">
            {{ $offers->links() }}
        </div>
    </div>
</div>
@endsection
