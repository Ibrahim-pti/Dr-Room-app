@extends('lab.layouts.app')

@section('content')
<div class="fade-up" style="display:flex;flex-direction:column;gap:24px;padding-bottom:40px;">

    <!-- Welcome -->
    <div style="display:flex;flex-wrap:wrap;align-items:flex-end;justify-content:space-between;gap:16px;background:#fff;padding:24px 28px;border-radius:16px;border:1px solid #e2e8f0;">
        <div>
            <h1 style="font-size:1.6rem;font-weight:800;color:#0f172a;margin:0 0 6px;">داشبۆردی تاقیگە</h1>
            <p style="margin:0;color:#64748b;font-size:0.9rem;font-weight:500;">بەخێربێیتەوە بۆ سیستەم، <span style="color:#7c3aed;font-weight:700;">{{ explode(' ', $user->name)[0] }}</span></p>
        </div>
        <div style="display:flex;align-items:center;gap:8px;background:#f8fafc;padding:8px 16px;border-radius:10px;font-size:0.82rem;color:#94a3b8;font-weight:600;">
            <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
            {{ now()->format('Y-m-d') }}
        </div>
    </div>

    <!-- Stats -->
    <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:16px;">
        @php
            $stats = [
                [
                    'label' => 'داواکارییەکانی ئەمڕۆ', 
                    'value' => $todayRequests, 
                    'color' => '#7c3aed', 
                    'bg' => '#f5f3ff', 
                    'icon' => 'M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z'
                ],
                [
                    'label' => 'پشکنینی تەواوکراو', 
                    'value' => $completedTests, 
                    'color' => '#059669', 
                    'bg' => '#ecfdf5', 
                    'icon' => 'M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z'
                ],
                [
                    'label' => 'سەردانیکەرانی پرۆفایل', 
                    'value' => number_format($viewsCount), 
                    'color' => '#2563eb', 
                    'bg' => '#eff6ff', 
                    'icon' => 'M15 12a3 3 0 11-6 0 3 3 0 016 0z M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z'
                ],
                [
                    'label' => 'تێکڕای هەڵسەنگاندن', 
                    'value' => number_format($rating, 1) . ' ⭐', 
                    'color' => '#f59e0b', 
                    'bg' => '#fef3c7', 
                    'icon' => 'M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z'
                ],
            ];
        @endphp
        @foreach($stats as $s)
        <div style="background:#fff;border-radius:14px;padding:22px;border:1px solid #e2e8f0;transition:transform 0.2s ease,box-shadow 0.2s ease;cursor:default;" onmouseover="this.style.transform='translateY(-3px)';this.style.boxShadow='0 8px 25px rgba(0,0,0,0.06)'" onmouseout="this.style.transform='none';this.style.boxShadow='none'">
            <div style="width:44px;height:44px;border-radius:12px;background:{{ $s['bg'] }};display:flex;align-items:center;justify-content:center;margin-bottom:16px;">
                <svg width="22" height="22" fill="none" stroke="{{ $s['color'] }}" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="{{ $s['icon'] }}"/></svg>
            </div>
            <div style="font-size:1.75rem;font-weight:800;color:#0f172a;margin-bottom:4px;" dir="ltr">{{ $s['value'] }}</div>
            <div style="font-size:0.8rem;color:#64748b;font-weight:600;">{{ $s['label'] }}</div>
        </div>
        @endforeach
    </div>

    <!-- Content Grid -->
    <div style="display:grid;grid-template-columns:2fr 1fr;gap:20px;">

        <!-- Left Column: Recent Requests & Feedback -->
        <div style="display:flex;flex-direction:column;gap:20px;">
            <!-- Recent Requests -->
            <div style="background:#fff;border-radius:16px;border:1px solid #e2e8f0;overflow:hidden;display:flex;flex-direction:column;">
                <div style="padding:20px 24px;border-bottom:1px solid #f1f5f9;display:flex;justify-content:space-between;align-items:center;">
                    <h3 style="margin:0;font-size:1rem;font-weight:700;color:#0f172a;">داواکارییە نوێیەکان</h3>
                    <a href="{{ route('lab.patients.index') }}" style="font-size:0.8rem;font-weight:700;color:#7c3aed;text-decoration:none;background:#f5f3ff;padding:6px 14px;border-radius:8px;transition:background 0.2s;" onmouseover="this.style.background='#ede9fe'" onmouseout="this.style.background='#f5f3ff'">هەمووی ببینە</a>
                </div>
                <div style="padding:8px 12px;flex:1;">
                    @forelse($recentRequests as $request)
                    <div style="display:flex;align-items:center;gap:14px;padding:12px 14px;border-radius:12px;transition:background 0.15s;" onmouseover="this.style.background='#f8fafc'" onmouseout="this.style.background='transparent'">
                        <div style="width:52px;text-align:center;">
                            <div style="font-size:0.82rem;font-weight:800;color:#0f172a;" dir="ltr">#{{ $request->id }}</div>
                        </div>
                        <div style="width:40px;height:40px;border-radius:50%;background:#f1f5f9;display:flex;align-items:center;justify-content:center;font-weight:700;color:#64748b;font-size:0.9rem;flex-shrink:0;">{{ mb_substr($request->patient->name ?? '؟', 0, 1) }}</div>
                        <div style="flex:1;min-width:0;">
                            <div style="font-size:0.88rem;font-weight:700;color:#0f172a;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">{{ $request->patient->name ?? 'نەخۆشی نەناسراو' }}</div>
                            <div style="font-size:0.78rem;color:#94a3b8;font-weight:500;">{{ $request->test_type ?? '—' }}</div>
                        </div>
                        <span style="font-size:0.72rem;font-weight:700;padding:5px 12px;border-radius:8px;white-space:nowrap;background:#f1f5f9;color:#475569;">{{ $request->status ?? '—' }}</span>
                    </div>
                    @empty
                    <div style="padding:40px 20px;text-align:center;">
                        <div style="font-size:0.9rem;font-weight:700;color:#0f172a;margin-bottom:6px;">
                            هیچ داواکارییەک نییە
                        </div>
                        <div style="font-size:0.82rem;color:#94a3b8;line-height:1.7;">
                            @if(! $schemaReady)
                                بەشی ئەنجامی پشکنین هێشتا لە سیستەمدا دانەمەزراوە.
                            @else
                                کاتێک داواکاری نوێ بێت، لێرە دەردەکەوێت.
                            @endif
                        </div>
                    </div>
                    @endforelse
                </div>
            </div>

            <!-- Recent Feedback & Reviews -->
            <div style="background:#fff;border-radius:16px;border:1px solid #e2e8f0;overflow:hidden;">
                <div style="padding:20px 24px;border-bottom:1px solid #f1f5f9;display:flex;justify-content:space-between;align-items:center;">
                    <div style="display:flex;align-items:center;gap:8px;">
                        <h3 style="margin:0;font-size:1rem;font-weight:700;color:#0f172a;">دوایین هەڵسەنگاندن و فیدباکەکانی نەخۆش</h3>
                        <span style="font-size:0.75rem;padding:2px 8px;border-radius:6px;background:#fef3c7;color:#b45309;font-weight:700;">{{ $totalReviews }} فیدباک</span>
                    </div>
                    <a href="{{ route('lab.reviews.index') }}" style="font-size:0.8rem;font-weight:700;color:#f59e0b;text-decoration:none;background:#fef3c7;padding:6px 14px;border-radius:8px;transition:background 0.2s;">بینینی هەمووی</a>
                </div>
                <div style="padding:12px;display:flex;flex-direction:column;gap:10px;">
                    @forelse($recentReviews as $rev)
                        <div style="padding:14px;background:#f8fafc;border-radius:12px;border:1px solid #f1f5f9;">
                            <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:8px;">
                                <div style="display:flex;align-items:center;gap:10px;">
                                    <div style="width:32px;height:32px;border-radius:50%;background:#e0f2fe;color:#0284c7;display:flex;align-items:center;justify-content:center;font-weight:bold;font-size:0.8rem;">
                                        {{ mb_substr($rev->patient?->name ?? 'ن', 0, 1) }}
                                    </div>
                                    <div>
                                        <div style="font-size:0.85rem;font-weight:700;color:#0f172a;">{{ $rev->patient?->name ?? 'نەخۆش' }}</div>
                                        <div style="font-size:0.72rem;color:#94a3b8;">{{ $rev->created_at ? $rev->created_at->diffForHumans() : 'نوێ' }}</div>
                                    </div>
                                </div>
                                <div style="display:flex;align-items:center;gap:2px;background:#fff;padding:4px 8px;border-radius:8px;border:1px solid #fde68a;">
                                    @for($i=1; $i<=5; $i++)
                                        <span style="color:{{ $i <= $rev->rating ? '#f59e0b' : '#cbd5e1' }};font-size:0.75rem;">★</span>
                                    @endfor
                                    <span style="font-size:0.75rem;font-weight:bold;color:#b45309;margin-right:3px;">{{ $rev->rating }}.0</span>
                                </div>
                            </div>
                            @if($rev->comment)
                                <div style="font-size:0.8rem;color:#475569;line-height:1.5;background:#fff;padding:8px 12px;border-radius:8px;border:1px solid #f1f5f9;">
                                    {{ $rev->comment }}
                                </div>
                            @endif
                        </div>
                    @empty
                        <div style="padding:30px;text-align:center;color:#94a3b8;font-size:0.85rem;">
                            هیچ فیدباکێک نییە. کاتێک نەخۆش لە ئەپەوە سەرنج دەدات، لێرە دەردەکەوێت.
                        </div>
                    @endforelse
                </div>
            </div>
        </div>

        <!-- Right Column: Lab Profile Overview & Summary -->
        <div style="display:flex;flex-direction:column;gap:20px;">
            <!-- Rating Card -->
            <div style="background:linear-gradient(135deg, #f59e0b, #d97706);border-radius:16px;padding:24px;color:#fff;text-align:center;box-shadow:0 10px 25px rgba(245, 158, 11, 0.25);">
                <div style="font-size:3.5rem;font-weight:900;margin-bottom:6px;">{{ number_format($rating, 1) }}</div>
                <div style="display:flex;justify-content:center;gap:4px;margin-bottom:12px;font-size:1.4rem;">
                    @for($i=1; $i<=5; $i++)
                        <span style="color:{{ $i <= round($rating) ? '#fef08a' : 'rgba(255,255,255,0.4)' }};">★</span>
                    @endfor
                </div>
                <div style="font-size:0.88rem;font-weight:700;color:#fef3c7;margin-bottom:16px;">
                    لە کۆی {{ number_format($totalReviews) }} هەڵسەنگاندن
                </div>
                <a href="{{ route('lab.reviews.index') }}" style="display:inline-block;width:100%;padding:10px 0;background:rgba(255,255,255,0.2);color:#fff;font-size:0.82rem;font-weight:bold;text-decoration:none;border-radius:10px;backdrop-filter:blur(4px);transition:background 0.2s;" onmouseover="this.style.background='rgba(255,255,255,0.3)'" onmouseout="this.style.background='rgba(255,255,255,0.2)'">
                    بینینی سەرنجەکانی نەخۆش
                </a>
            </div>

            <!-- Views Card -->
            <div style="background:#fff;border-radius:16px;border:1px solid #e2e8f0;padding:22px;display:flex;flex-direction:column;gap:12px;">
                <div style="display:flex;align-items:center;justify-content:space-between;">
                    <div style="font-size:0.9rem;font-weight:700;color:#0f172a;">سەردانیکەرانی تاقیگە</div>
                    <div style="width:32px;height:32px;border-radius:8px;background:#eff6ff;display:flex;align-items:center;justify-content:center;color:#2563eb;">
                        <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                    </div>
                </div>
                <div style="font-size:2rem;font-weight:800;color:#2563eb;" dir="ltr">{{ number_format($viewsCount) }}</div>
                <div style="font-size:0.78rem;color:#64748b;line-height:1.6;">
                    ژمارەی ئەو نەخۆشانەی کە پرۆفایلی تاقیگەکەیان لە ئەپڵیکەیشن کردۆتەوە.
                </div>
            </div>
        </div>
    </div>
</div>

<style>
    @media (max-width: 1023px) {
        div[style*="grid-template-columns:2fr 1fr"] { grid-template-columns: 1fr !important; }
        div[style*="grid-template-columns:repeat(4,1fr)"] { grid-template-columns: repeat(2, 1fr) !important; }
    }
    @media (max-width: 639px) {
        div[style*="grid-template-columns:repeat(4,1fr)"] { grid-template-columns: 1fr !important; }
    }
</style>
@endsection
