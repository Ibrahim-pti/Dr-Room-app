@extends('pharmacy.layouts.app')

@section('content')
<div class="fade-up">
    <!-- Welcome Section -->
    <div style="background: linear-gradient(135deg, #0d9488 0%, #0f766e 100%); border-radius: 20px; padding: 32px; color: white; display: flex; align-items: center; justify-content: space-between; margin-bottom: 32px; box-shadow: 0 10px 25px -5px rgba(13, 148, 136, 0.4);">
        <div>
            <h1 style="font-size: 1.8rem; font-weight: 800; margin-bottom: 8px;">بەخێربێیت، سەیدەلە {{ explode(' ', $user->name)[0] }}!</h1>
            <p style="color: #ccfbf1; font-size: 1rem;">ئەمڕۆ {{ $todayOrders }} داواکاری نوێمان هەیە.</p>
        </div>
        <div style="background: rgba(255,255,255,0.2); padding: 16px; border-radius: 16px; backdrop-filter: blur(10px);">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" width="48" height="48" style="opacity: 0.9"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"/></svg>
        </div>
    </div>

    <!-- Quick Stats -->
    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 20px; margin-bottom: 32px;">
        <div style="background: white; padding: 24px; border-radius: 16px; border: 1px solid #f1f5f9; display: flex; align-items: center; gap: 16px;">
            <div style="width: 54px; height: 54px; border-radius: 14px; background: #f0fdfa; display: flex; align-items: center; justify-content: center; color: #0d9488;">
                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" width="28" height="28"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
            </div>
            <div>
                <div style="color: #64748b; font-size: 0.85rem; font-weight: 600;">ڕەچەتە چاوەڕێکراوەکان</div>
                <div style="color: #1e293b; font-size: 1.4rem; font-weight: 700; margin-top: 4px;">{{ $pendingPrescriptions }}</div>
            </div>
        </div>

        <div style="background: white; padding: 24px; border-radius: 16px; border: 1px solid #f1f5f9; display: flex; align-items: center; gap: 16px;">
            <div style="width: 54px; height: 54px; border-radius: 14px; background: #fffbeb; display: flex; align-items: center; justify-content: center; color: #d97706;">
                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" width="28" height="28"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"/></svg>
            </div>
            <div>
                <div style="color: #64748b; font-size: 0.85rem; font-weight: 600;">داواکارییەکانی ئەمڕۆ</div>
                <div style="color: #1e293b; font-size: 1.4rem; font-weight: 700; margin-top: 4px;">{{ $todayOrders }}</div>
            </div>
        </div>

        <div style="background: white; padding: 24px; border-radius: 16px; border: 1px solid #f1f5f9; display: flex; align-items: center; gap: 16px;">
            <div style="width: 54px; height: 54px; border-radius: 14px; background: #fef2f2; display: flex; align-items: center; justify-content: center; color: #ef4444;">
                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" width="28" height="28"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>
            </div>
            <div>
                <div style="color: #64748b; font-size: 0.85rem; font-weight: 600;">دەرمانی کەمبووەوە</div>
                <div style="color: #1e293b; font-size: 1.4rem; font-weight: 700; margin-top: 4px;">{{ $lowStockItems }}</div>
            </div>
        </div>
    </div>
</div>
@endsection
