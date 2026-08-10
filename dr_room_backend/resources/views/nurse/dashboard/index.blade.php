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
            {{ now()->format('Y-m-d') }}
        </div>
    </div>

    <!-- Stats -->
    <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:16px;">
        @php
            $stats = [
                ['label' => 'داواکارییەکانی ئەمڕۆ', 'value' => $todayAppointments ?? 12, 'color' => '#0d9488', 'bg' => '#f0fdfa', 'icon' => 'M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z'],
                ['label' => 'پشکنینی تەواوکراو', 'value' => $completedAppointments ?? 8, 'color' => '#059669', 'bg' => '#ecfdf5', 'icon' => 'M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z'],
                ['label' => 'لە چاوەڕوانیدا', 'value' => $pendingAppointments ?? 4, 'color' => '#d97706', 'bg' => '#fffbeb', 'icon' => 'M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z'],
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

        <!-- Appointments -->
        <div style="background:#fff;border-radius:16px;border:1px solid #e2e8f0;overflow:hidden;display:flex;flex-direction:column;">
            <div style="padding:20px 24px;border-bottom:1px solid #f1f5f9;display:flex;justify-content:space-between;align-items:center;">
                <h3 style="margin:0;font-size:1rem;font-weight:700;color:#0f172a;">داواکارییەکانی ئەمڕۆ</h3>
                <a href="{{ route('nurse.appointments.index') }}" style="font-size:0.8rem;font-weight:700;color:#0d9488;text-decoration:none;background:#f0fdfa;padding:6px 14px;border-radius:8px;transition:background 0.2s;" onmouseover="this.style.background='#ccfbf1'" onmouseout="this.style.background='#f0fdfa'">هەمووی ببینە</a>
            </div>
            <div style="padding:8px 12px;flex:1;">
                @if(isset($upcomingAppointments) && $upcomingAppointments->count() > 0)
                    @foreach($upcomingAppointments->take(5) as $appointment)
                    <div style="display:flex;align-items:center;gap:14px;padding:12px 14px;border-radius:12px;transition:background 0.15s;" onmouseover="this.style.background='#f8fafc'" onmouseout="this.style.background='transparent'">
                        <div style="width:52px;text-align:center;">
                            <div style="font-size:1rem;font-weight:800;color:#0f172a;">{{ $appointment->appointment_date->format('h:i') }}</div>
                            <div style="font-size:0.65rem;font-weight:700;color:#94a3b8;">{{ $appointment->appointment_date->format('A') == 'AM' ? 'ب.ن' : 'د.ن' }}</div>
                        </div>
                        <div style="width:40px;height:40px;border-radius:50%;background:#f1f5f9;display:flex;align-items:center;justify-content:center;font-weight:700;color:#64748b;font-size:0.9rem;flex-shrink:0;overflow:hidden;">
                            @if($appointment->patient->profile_image)
                                <img src="{{ asset('storage/' . $appointment->patient->profile_image) }}" style="width:100%;height:100%;object-fit:cover;">
                            @else
                                {{ mb_substr($appointment->patient->name, 0, 1) }}
                            @endif
                        </div>
                        <div style="flex:1;min-width:0;">
                            <div style="font-size:0.88rem;font-weight:700;color:#0f172a;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">{{ $appointment->patient->name }}</div>
                            <div style="font-size:0.78rem;color:#94a3b8;font-weight:500;">{{ $appointment->service->name ?? 'پشکنینی گشتی' }}</div>
                        </div>
                        <span style="font-size:0.72rem;font-weight:700;padding:5px 12px;border-radius:8px;white-space:nowrap;{{ $appointment->status == 'completed' ? 'background:#ecfdf5;color:#059669;' : ($appointment->status == 'pending' ? 'background:#fffbeb;color:#d97706;' : 'background:#f0fdfa;color:#0d9488;') }}">
                            {{ $appointment->status == 'completed' ? 'تەواوکراو' : ($appointment->status == 'pending' ? 'چاوەڕێکراو' : 'بەڕێوەیە') }}
                        </span>
                    </div>
                    @endforeach
                @else
                    {{-- Empty means empty. This branch used to render invented
                         patients and procedures (blood draw, wound dressing),
                         which a nurse cannot tell apart from a real round. --}}
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
