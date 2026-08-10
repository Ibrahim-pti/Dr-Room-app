@extends('doctor.layouts.app')

@section('content')
<div class="fade-up" style="display:flex;flex-direction:column;gap:24px;padding-bottom:40px;">

    <!-- Welcome -->
    <div style="display:flex;flex-wrap:wrap;align-items:flex-end;justify-content:space-between;gap:16px;background:#fff;padding:24px 28px;border-radius:16px;border:1px solid #e2e8f0;">
        <div>
            <h1 style="font-size:1.6rem;font-weight:800;color:#0f172a;margin:0 0 6px;">داشبۆرد</h1>
            <p style="margin:0;color:#64748b;font-size:0.9rem;font-weight:500;">بەخێربێیتەوە بۆ سیستەم، <span style="color:#4f46e5;font-weight:700;">دکتۆر {{ explode(' ', $user->name)[0] }}</span></p>
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
                ['label' => 'نەخۆشەکانی ئەمڕۆ', 'value' => $todayAppointments ?? 24, 'color' => '#4f46e5', 'bg' => '#eef2ff', 'icon' => 'M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z'],
                ['label' => 'پشکنینی تەواوکراو', 'value' => $completedAppointments ?? 18, 'color' => '#059669', 'bg' => '#ecfdf5', 'icon' => 'M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z'],
                ['label' => 'ڕاوێژی ئۆنلاین', 'value' => $pendingAppointments ?? 6, 'color' => '#7c3aed', 'bg' => '#f5f3ff', 'icon' => 'M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z'],
                ['label' => 'هەڵسەنگاندن', 'value' => number_format($doctor->rating ?? 4.8, 1), 'color' => '#d97706', 'bg' => '#fffbeb', 'icon' => 'M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z'],
            ];
        @endphp
        @foreach($stats as $i => $s)
        <div style="background:#fff;border-radius:14px;padding:22px;border:1px solid #e2e8f0;transition:transform 0.2s ease,box-shadow 0.2s ease;cursor:default;" onmouseover="this.style.transform='translateY(-3px)';this.style.boxShadow='0 8px 25px rgba(0,0,0,0.06)'" onmouseout="this.style.transform='none';this.style.boxShadow='none'">
            <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:16px;">
                <div style="width:44px;height:44px;border-radius:12px;background:{{ $s['bg'] }};display:flex;align-items:center;justify-content:center;">
                    <svg width="22" height="22" fill="none" stroke="{{ $s['color'] }}" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="{{ $s['icon'] }}"/></svg>
                </div>
            </div>
            <div style="font-size:1.75rem;font-weight:800;color:#0f172a;margin-bottom:4px;" dir="ltr">{{ $s['value'] }}</div>
            <div style="font-size:0.8rem;color:#64748b;font-weight:600;">{{ $s['label'] }}</div>
        </div>
        @endforeach
    </div>

    <!-- Content Grid -->
    <div style="display:grid;grid-template-columns:2fr 1fr;gap:20px;">

        <!-- Appointments Table -->
        <div style="background:#fff;border-radius:16px;border:1px solid #e2e8f0;overflow:hidden;display:flex;flex-direction:column;">
            <div style="padding:20px 24px;border-bottom:1px solid #f1f5f9;display:flex;justify-content:space-between;align-items:center;">
                <h3 style="margin:0;font-size:1rem;font-weight:700;color:#0f172a;">خشتەی کارکردنی ئەمڕۆ</h3>
                <a href="{{ route('doctor.appointments.index') }}" style="font-size:0.8rem;font-weight:700;color:#4f46e5;text-decoration:none;background:#eef2ff;padding:6px 14px;border-radius:8px;transition:background 0.2s;" onmouseover="this.style.background='#e0e7ff'" onmouseout="this.style.background='#eef2ff'">هەمووی ببینە</a>
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
                            <div style="font-size:0.78rem;color:#94a3b8;font-weight:500;">{{ $appointment->type == 'online' ? 'ڕاوێژی ئۆنلاین' : 'سەردانی نۆڕینگە' }}</div>
                        </div>
                        <span style="font-size:0.72rem;font-weight:700;padding:5px 12px;border-radius:8px;white-space:nowrap;{{ $appointment->status == 'completed' ? 'background:#ecfdf5;color:#059669;' : ($appointment->status == 'pending' ? 'background:#fffbeb;color:#d97706;' : 'background:#eef2ff;color:#4f46e5;') }}">
                            {{ $appointment->status == 'completed' ? 'تەواوکراو' : ($appointment->status == 'pending' ? 'چاوەڕێکراو' : 'بەڕێوەیە') }}
                        </span>
                    </div>
                    @endforeach
                @else
                    {{-- Empty means empty. This branch used to render invented
                         patients and visit types, which a doctor cannot tell
                         apart from a real schedule. --}}
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

        <!-- Right Column -->
        <div style="display:flex;flex-direction:column;gap:20px;">
            <!-- Chart -->
            <div style="background:#fff;border-radius:16px;border:1px solid #e2e8f0;padding:22px;">
                <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:20px;">
                    <h3 style="margin:0;font-size:1rem;font-weight:700;color:#0f172a;">پوختەی سەردانەکان</h3>
                </div>
                <div style="position:relative;height:200px;">
                    <canvas id="appointmentsChart"></canvas>
                </div>
            </div>

            <!-- Recent Patients -->
            <div style="background:#fff;border-radius:16px;border:1px solid #e2e8f0;overflow:hidden;flex:1;display:flex;flex-direction:column;">
                <div style="padding:18px 22px 8px;">
                    <h3 style="margin:0;font-size:1rem;font-weight:700;color:#0f172a;">دوایین نەخۆشەکان</h3>
                </div>
                <div style="padding:6px 12px;flex:1;">
                    {{-- Real patients this doctor has seen. Never sample rows:
                         a fabricated name here reads as a real medical record. --}}
                    @forelse($recentPatients as $appointment)
                    <div style="display:flex;align-items:center;gap:10px;padding:10px 12px;border-radius:10px;transition:background 0.15s;" onmouseover="this.style.background='#f8fafc'" onmouseout="this.style.background='transparent'">
                        <div style="width:36px;height:36px;border-radius:50%;background:#eef2ff;color:#4f46e5;display:flex;align-items:center;justify-content:center;font-weight:700;font-size:0.85rem;">{{ mb_substr($appointment->patient->name ?? '؟', 0, 1) }}</div>
                        <div style="flex:1;min-width:0;">
                            <div style="font-size:0.82rem;font-weight:700;color:#0f172a;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">{{ $appointment->patient->name ?? 'نەخۆشی نەناسراو' }}</div>
                            <div style="font-size:0.72rem;color:#94a3b8;font-weight:500;">{{ $appointment->patient->phone ?? '—' }}</div>
                        </div>
                        <div style="font-size:0.7rem;font-weight:700;color:#94a3b8;background:#f1f5f9;padding:4px 10px;border-radius:6px;white-space:nowrap;">{{ optional($appointment->appointment_date)->diffForHumans() ?? '—' }}</div>
                    </div>
                    @empty
                    <div style="padding:28px 16px;text-align:center;">
                        <div style="font-size:0.85rem;font-weight:700;color:#0f172a;margin-bottom:4px;">هێشتا هیچ نەخۆشێک نییە</div>
                        <div style="font-size:0.75rem;color:#94a3b8;line-height:1.7;">دوای یەکەم سەردان لێرە دەردەکەون.</div>
                    </div>
                    @endforelse
                </div>
                <div style="padding:12px 16px 16px;">
                    <a href="{{ route('doctor.patients.index') }}" style="display:block;text-align:center;padding:10px;border-radius:10px;background:#f8fafc;color:#64748b;font-weight:700;font-size:0.82rem;text-decoration:none;transition:background 0.2s;" onmouseover="this.style.background='#f1f5f9'" onmouseout="this.style.background='#f8fafc'">بینینی هەموو نەخۆشەکان</a>
                </div>
            </div>
        </div>
    </div>
</div>

<style>
    @media (max-width: 1023px) {
        div[style*="grid-template-columns:2fr 1fr"] { grid-template-columns: 1fr !important; }
    }
    @media (max-width: 639px) {
        div[style*="grid-template-columns:repeat(4,1fr)"] { grid-template-columns: repeat(2, 1fr) !important; }
    }
</style>

<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
<script>
    document.addEventListener('DOMContentLoaded', function() {
        const ctx = document.getElementById('appointmentsChart');
        if (ctx) {
            new Chart(ctx, {
                type: 'line',
                data: {
                    // Real counts for the last 7 days, from DoctorDashboardController.
                    labels: @json($weeklyChart->pluck('label')),
                    datasets: [{
                        label: 'سەردانەکان',
                        data: @json($weeklyChart->pluck('count')),
                        borderColor: '#4f46e5',
                        backgroundColor: 'rgba(79, 70, 229, 0.08)',
                        borderWidth: 2.5,
                        fill: true,
                        tension: 0.4,
                        pointBackgroundColor: '#fff',
                        pointBorderColor: '#4f46e5',
                        pointBorderWidth: 2,
                        pointRadius: 4,
                        pointHoverRadius: 6,
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: { legend: { display: false } },
                    scales: {
                        x: { grid: { display: false }, border: { display: false }, ticks: { color: '#94a3b8', font: { family: 'Rabar', weight: 'bold', size: 11 } } },
                        y: { beginAtZero: true, grid: { color: '#f1f5f9' }, border: { display: false }, ticks: { color: '#94a3b8', maxTicksLimit: 5, font: { weight: 'bold', size: 11 } } }
                    },
                    interaction: { intersect: false, mode: 'index' }
                }
            });
        }
    });
</script>
@endsection
