@extends('pharmacy.layouts.app')

@section('content')
<div class="fade-up">
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px;">
        <h2 style="font-size: 1.5rem; font-weight: 700; color: #0f172a;">دەرمانەکان (کۆگا)</h2>
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
                    <th style="padding: 16px; color: #64748b; font-weight: 600; font-size: 0.9rem;">نرخ</th>
                    <th style="padding: 16px; color: #64748b; font-weight: 600; font-size: 0.9rem;">بڕ (دانە)</th>
                    <th style="padding: 16px; color: #64748b; font-weight: 600; font-size: 0.9rem; text-align: left;">کردارەکان</th>
                </tr>
            </thead>
            <tbody>
                @forelse($medications as $medication)
                <tr style="border-bottom: 1px solid #f1f5f9;">
                    <td style="padding: 16px;">
                        @if($medication->image_path)
                            <img src="{{ Storage::url($medication->image_path) }}" alt="{{ $medication->name }}" style="width: 50px; height: 50px; border-radius: 8px; object-fit: cover;">
                        @else
                            <div style="width: 50px; height: 50px; border-radius: 8px; background: #f1f5f9; display: flex; align-items: center; justify-content: center; color: #94a3b8;">
                                <svg width="24" height="24" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
                            </div>
                        @endif
                    </td>
                    <td style="padding: 16px; font-weight: 600; color: #1e293b;">{{ $medication->name }}</td>
                    <td style="padding: 16px; color: #0d9488; font-weight: 600;">IQD {{ number_format($medication->price) }}</td>
                    <td style="padding: 16px;">
                        <span style="background: {{ $medication->stock > 10 ? '#dcfce7' : '#fee2e2' }}; color: {{ $medication->stock > 10 ? '#166534' : '#991b1b' }}; padding: 4px 12px; border-radius: 12px; font-size: 0.85rem; font-weight: 600;">
                            {{ $medication->stock }}
                        </span>
                    </td>
                    <td style="padding: 16px; text-align: left;">
                        <a href="{{ route('pharmacy.medications.edit', $medication) }}" style="color: #3b82f6; background: #eff6ff; padding: 6px 12px; border-radius: 6px; text-decoration: none; display: inline-flex; align-items: center; gap: 4px; font-size: 0.85rem; font-weight: 600; margin-left: 8px;">
                            <svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z"/></svg>
                            دەستکاری
                        </a>
                        <form action="{{ route('pharmacy.medications.destroy', $medication) }}" method="POST" style="display: inline-block;" onsubmit="return confirm('دڵنیایت لە سڕینەوەی ئەم دەرمانە؟');">
                            @csrf
                            @method('DELETE')
                            <button type="submit" style="color: #ef4444; background: #fef2f2; padding: 6px 12px; border-radius: 6px; text-decoration: none; display: inline-flex; align-items: center; gap: 4px; font-size: 0.85rem; font-weight: 600; border: none; cursor: pointer;">
                                <svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
                                سڕینەوە
                            </button>
                        </form>
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="5" style="padding: 32px; text-align: center; color: #94a3b8;">هیچ دەرمانێک نییە. یەکەم دەرمان زیاد بکە.</td>
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
