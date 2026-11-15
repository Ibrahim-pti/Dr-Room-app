@extends('nurse.layouts.app')

@section('content')
<div class="fade-up" style="display:flex;flex-direction:column;gap:24px;padding-bottom:40px;">

    <!-- Welcome -->
    <div style="display:flex;flex-wrap:wrap;align-items:flex-end;justify-content:space-between;gap:16px;background:#fff;padding:24px 28px;border-radius:16px;border:1px solid #e2e8f0;">
        <div>
            <h1 style="font-size:1.6rem;font-weight:800;color:#0f172a;margin:0 0 6px;">داشبۆرد</h1>
            <p style="margin:0;color:#64748b;font-size:0.9rem;font-weight:500;">بەخێربێیتەوە بۆ سیستەم، <span style="color:#0d9488;font-weight:700;">پەرستار {{ explode(' ', $user->name)[0] }}</span></p>
        </div>
        <div style="display:flex;align-items:center;gap:8px;background:#f8fafc;padding:8px 16px;border-radius:10px;font-size:0.82rem;color:#94a3b8;font-weight:600;">
            <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
            {{ now()->timezone('Asia/Baghdad')->format('Y-m-d') }}
        </div>
    </div>

    <!-- Stats -->
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        @php
            $stats = [
                ['label' => 'داواکارییەکانی ئەمڕۆ', 'value' => $todayAppointments ?? 0, 'color' => '#0d9488', 'bg' => '#f0fdfa', 'icon' => 'M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z', 'link' => route('nurse.appointments.index')],
                ['label' => 'پشکنینی تەواوکراو', 'value' => $completedAppointments ?? 0, 'color' => '#059669', 'bg' => '#ecfdf5', 'icon' => 'M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z', 'link' => route('nurse.appointments.index')],
                ['label' => 'لە چاوەڕوانیدا', 'value' => $pendingAppointments ?? 0, 'color' => '#d97706', 'bg' => '#fffbeb', 'icon' => 'M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z', 'link' => route('nurse.appointments.index')],
                ['label' => 'هەڵسەنگاندنەکان', 'value' => ($nurse->rating > 0 ? $nurse->rating : '5.0') . ' ★', 'color' => '#d97706', 'bg' => '#fef3c7', 'icon' => 'M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z', 'link' => route('nurse.reviews.index')],
            ];
        @endphp
        @foreach($stats as $s)
        <a href="{{ $s['link'] ?? '#' }}" style="text-decoration:none;background:#fff;border-radius:14px;padding:22px;border:1px solid #e2e8f0;transition:transform 0.2s ease,box-shadow 0.2s ease;display:block;" onmouseover="this.style.transform='translateY(-3px)';this.style.boxShadow='0 8px 25px rgba(0,0,0,0.06)'" onmouseout="this.style.transform='none';this.style.boxShadow='none'">
            <div style="width:44px;height:44px;border-radius:12px;background:{{ $s['bg'] }};display:flex;align-items:center;justify-content:center;margin-bottom:16px;">
                <svg width="22" height="22" fill="none" stroke="{{ $s['color'] }}" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="{{ $s['icon'] }}"/></svg>
            </div>
            <div style="font-size:1.6rem;font-weight:800;color:#0f172a;margin-bottom:4px;" dir="ltr">{{ $s['value'] }}</div>
            <div style="font-size:0.8rem;color:#64748b;font-weight:600;">{{ $s['label'] }}</div>
        </a>
        @endforeach
    </div>

    <!-- Monthly Accounting Summary -->
    @if(isset($monthlyAccounting))
    <div class="bg-white rounded-2xl border border-slate-200/80 p-5 sm:p-6 shadow-xs">
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 mb-4 text-right">
            <div>
                <div class="inline-flex items-center gap-2 px-2.5 py-0.5 rounded-full bg-teal-50 text-teal-700 text-xs font-semibold mb-1">
                    <span>حساباتی مانگانە</span>
                    <span dir="ltr" class="inline-block">{{ $monthlyAccounting['month'] }}</span>
                </div>
                <h2 class="text-base sm:text-lg font-extrabold text-slate-900">پوختەی حساباتی ئەم مانگە</h2>
            </div>
            <a href="{{ route('nurse.reports.index') }}" class="inline-flex items-center justify-center gap-1.5 px-4 py-2 rounded-xl bg-teal-600 hover:bg-teal-700 text-white text-xs font-bold transition shadow-xs">
                <span>بینینی ڕاپۆرتی تەواو</span>
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/></svg>
            </a>
        </div>
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3 text-right">
            <div class="rounded-xl bg-slate-50 border border-slate-100 p-3.5">
                <p class="text-xs text-slate-500">داهاتی پوخت</p>
                <p class="text-lg font-extrabold text-slate-900 mt-1"><span dir="ltr" class="inline-block">{{ number_format($monthlyAccounting['net_revenue'], 0) }}</span> <span class="text-xs font-semibold text-slate-400">د.ع</span></p>
                <p class="text-[11px] text-slate-400 mt-0.5">کۆی گشتی: <span dir="ltr" class="inline-block">{{ number_format($monthlyAccounting['gross_revenue'], 0) }}</span> د.ع</p>
            </div>
            <div class="rounded-xl bg-slate-50 border border-slate-100 p-3.5">
                <p class="text-xs text-slate-500">خزمەتگوزارییە ئەنجامدراوەکان</p>
                <p class="text-lg font-extrabold text-teal-700 mt-1" dir="ltr">{{ number_format($monthlyAccounting['items_performed']) }}</p>
                <p class="text-[11px] text-slate-400 mt-0.5">ژمارەی بڕگەی خزمەتگوزاری</p>
            </div>
            <div class="rounded-xl bg-slate-50 border border-slate-100 p-3.5">
                <p class="text-xs text-slate-500">سەردانە تەواوکراوەکان</p>
                <p class="text-lg font-extrabold text-emerald-700 mt-1"><span dir="ltr" class="inline-block">{{ number_format($monthlyAccounting['completed_orders']) }}</span> <span class="text-xs font-normal text-slate-400">/ {{ number_format($monthlyAccounting['total_orders']) }}</span></p>
                <p class="text-[11px] text-slate-400 mt-0.5">تەواوکراو لە کۆی داواکاری</p>
            </div>
            <div class="rounded-xl bg-slate-50 border border-slate-100 p-3.5">
                <p class="text-xs text-slate-500">نەخۆشەکانی ئەم مانگە</p>
                <p class="text-lg font-extrabold text-slate-900 mt-1" dir="ltr">{{ number_format($monthlyAccounting['unique_patients']) }}</p>
                <p class="text-[11px] text-slate-400 mt-0.5">نەخۆشی جیاواز</p>
            </div>
        </div>
    </div>
    @endif

    <!-- Content Grid -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-5">

        <!-- New Requests & Appointments -->
        <div class="lg:col-span-2 flex flex-col gap-5">
            <!-- Unassigned / Pending Requests -->
            @if(isset($unassignedRequests) && $unassignedRequests->count() > 0)
            <div style="background:#fff;border-radius:16px;border:1px solid #e2e8f0;overflow:hidden;display:flex;flex-direction:column;">
                <div style="padding:20px 24px;border-bottom:1px solid #f1f5f9;display:flex;justify-content:space-between;align-items:center;background:#fffbeb;">
                    <h3 style="margin:0;font-size:1rem;font-weight:700;color:#b45309;">داواکارییە نوێیەکان (چاوەڕێکراو)</h3>
                </div>
                <div style="padding:8px 12px;">
                    @foreach($unassignedRequests as $req)
                    <div style="display:flex;align-items:center;gap:14px;padding:12px 14px;border-bottom:1px solid #f1f5f9;background:#fff;">
                        <div style="width:46px;height:46px;border-radius:50%;background:#fef3c7;display:flex;align-items:center;justify-content:center;color:#b45309;font-weight:bold;">
                            {{ mb_substr($req->patient->name ?? 'ن', 0, 1) }}
                        </div>
                        <div style="flex:1;">
                            <div style="font-size:0.9rem;font-weight:700;color:#0f172a;">{{ $req->patient->name ?? 'نەخۆش' }}</div>
                            <div style="font-size:0.75rem;color:#64748b;margin-top:2px;">
                                @if($req->services)
                                    {{ implode('، ', array_map(function($s) {
                                        $map = ['injection' => 'دەرزی', 'cannula' => 'کانیۆلا', 'dressing' => 'پانسیمان', 'checkup' => 'چاودێری'];
                                        return $map[$s] ?? $s;
                                    }, is_array($req->services) ? $req->services : json_decode($req->services, true) ?? [])) }}
                                @else
                                    پشکنینی گشتی
                                @endif
                                 • {{ $req->address ?? 'ناونیشان دیارینەکراوە' }}
                            </div>
                        </div>
                        <div>
                            <span style="font-size:0.8rem;font-weight:bold;color:#059669;margin-left:10px;">{{ number_format($req->fee, 0) }} د.ع</span>
                            <form action="{{ route('nurse.appointments.accept', $req->id) }}" method="POST" style="display:inline-block;">
                                @csrf
                                <button type="submit" style="background:#0d9488;color:#fff;border:none;padding:6px 14px;border-radius:8px;font-size:0.8rem;font-weight:bold;cursor:pointer;transition:background 0.2s;" onmouseover="this.style.background='#0f766e'" onmouseout="this.style.background='#0d9488'">وەرگرتن</button>
                            </form>
                        </div>
                    </div>
                    @endforeach
                </div>
            </div>
            @endif

            <!-- Upcoming Appointments -->
            <div style="background:#fff;border-radius:16px;border:1px solid #e2e8f0;overflow:hidden;display:flex;flex-direction:column;">
                <div style="padding:20px 24px;border-bottom:1px solid #f1f5f9;display:flex;justify-content:space-between;align-items:center;">
                    <h3 style="margin:0;font-size:1rem;font-weight:700;color:#0f172a;">داواکارییەکانی ئەمڕۆم</h3>
                    <a href="{{ route('nurse.appointments.index') }}" style="font-size:0.8rem;font-weight:700;color:#0d9488;text-decoration:none;background:#f0fdfa;padding:6px 14px;border-radius:8px;transition:background 0.2s;" onmouseover="this.style.background='#ccfbf1'" onmouseout="this.style.background='#f0fdfa'">هەمووی ببینە</a>
                </div>
                <div style="padding:8px 12px;flex:1;">
                    @if(isset($upcomingAppointments) && $upcomingAppointments->count() > 0)
                        @foreach($upcomingAppointments->take(5) as $appointment)
                        <div style="display:flex;align-items:center;gap:14px;padding:12px 14px;border-radius:12px;transition:background 0.15s;" onmouseover="this.style.background='#f8fafc'" onmouseout="this.style.background='transparent'">
                            @php $localDashAppAt = $appointment->created_at?->timezone('Asia/Baghdad'); @endphp
                            <div style="width:52px;text-align:center;">
                                <div style="font-size:1rem;font-weight:800;color:#0f172a;">{{ $localDashAppAt?->format('h:i') }}</div>
                                <div style="font-size:0.65rem;font-weight:700;color:#94a3b8;">{{ $localDashAppAt?->format('A') == 'AM' ? 'ب.ن' : 'د.ن' }}</div>
                            </div>
                            <div style="width:40px;height:40px;border-radius:50%;background:#f1f5f9;display:flex;align-items:center;justify-content:center;font-weight:700;color:#64748b;font-size:0.9rem;flex-shrink:0;overflow:hidden;">
                                @if($appointment->patient && $appointment->patient->profile_image)
                                    <img src="{{ asset('storage/' . $appointment->patient->profile_image) }}" style="width:100%;height:100%;object-fit:cover;">
                                @else
                                    {{ mb_substr($appointment->patient->name ?? 'ن', 0, 1) }}
                                @endif
                            </div>
                            <div style="flex:1;min-width:0;">
                                <div style="font-size:0.88rem;font-weight:700;color:#0f172a;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">{{ $appointment->patient->name ?? 'نەخۆش' }}</div>
                                <div style="font-size:0.78rem;color:#94a3b8;font-weight:500;">
                                    @if($appointment->items && $appointment->items->count() > 0)
                                        {{ $appointment->items->pluck('item_name')->join('، ') }}
                                    @else
                                        خزمەتگوزاری پەرستاری
                                    @endif
                                </div>
                            </div>
                            <span style="font-size:0.72rem;font-weight:700;padding:5px 12px;border-radius:8px;white-space:nowrap;{{ $appointment->status == 'completed' ? 'background:#ecfdf5;color:#059669;' : ($appointment->status == 'pending' ? 'background:#fffbeb;color:#d97706;' : 'background:#f0fdfa;color:#0d9488;') }}">
                                {{ $appointment->status == 'completed' ? 'تەواوکراو' : ($appointment->status == 'pending' ? 'چاوەڕێکراو' : 'بەڕێوەیە') }}
                            </span>
                        </div>
                        @endforeach
                    @else
                        <div style="padding:40px 20px;text-align:center;">
                            <div style="font-size:0.9rem;font-weight:700;color:#0f172a;margin-bottom:6px;">
                                هیچ سەردانێکی داهاتوو نییە
                            </div>
                            <div style="font-size:0.82rem;color:#94a3b8;line-height:1.7;">
                                کاتێک نەخۆشێک کات وەردەگرێت، لێرە دەردەکەوێت.
                            </div>
                        </div>
                    @endif
                </div>
            </div>
        </div>

        <!-- Chart -->
        <div style="background:#fff;border-radius:16px;border:1px solid #e2e8f0;padding:22px;display:flex;flex-direction:column;">
            <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:20px;">
                <h3 style="margin:0;font-size:1rem;font-weight:700;color:#0f172a;">پوختەی کارکردن</h3>
            </div>
            <div style="position:relative;flex:1;min-height:250px;">
                <canvas id="appointmentsChart"></canvas>
            </div>
        </div>
    </div>
</div>

<style>
    @media (max-width: 1023px) {
        div[style*="grid-template-columns:2fr 1fr"] { grid-template-columns: 1fr !important; }
    }
    @media (max-width: 639px) {
        div[style*="grid-template-columns:repeat(3,1fr)"] { grid-template-columns: 1fr !important; }
    }
</style>

<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
<script>
    document.addEventListener('DOMContentLoaded', function() {
        const ctx = document.getElementById('appointmentsChart');
        if (ctx) {
            new Chart(ctx, {
                type: 'bar',
                data: {
                    // Real counts for the last 7 days, from NurseDashboardController.
                    labels: @json($weeklyChart->pluck('label')),
                    datasets: [{
                        label: 'داواکارییەکان',
                        data: @json($weeklyChart->pluck('count')),
                        backgroundColor: '#0d9488',
                        borderRadius: 6,
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: { legend: { display: false } },
                    scales: {
                        x: { grid: { display: false }, border: { display: false }, ticks: { color: '#94a3b8', font: { family: 'Rabar', weight: 'bold', size: 11 } } },
                        y: { beginAtZero: true, grid: { color: '#f1f5f9' }, border: { display: false }, ticks: { color: '#94a3b8', maxTicksLimit: 5, font: { weight: 'bold', size: 11 } } }
                    }
                }
            });
        }
    });
</script>
@endsection
