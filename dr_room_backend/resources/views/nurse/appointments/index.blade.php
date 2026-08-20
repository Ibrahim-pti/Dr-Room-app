@extends('nurse.layouts.app')

@section('content')
<div class="fade-up">
    <!-- Header -->
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:24px;">
        <div>
            <h1 style="font-size:1.5rem;font-weight:800;color:#0f172a;margin:0 0 4px;">لیستی چاوپێکەوتنەکان</h1>
            <p style="margin:0;color:#64748b;font-size:0.9rem;">بەڕێوەبردنی سەردانەکان و بینینی نەخۆشەکان</p>
        </div>
    </div>

    <!-- Active Appointments (Assigned to this nurse) -->
    <div style="background:#fff;border-radius:16px;border:1px solid #e2e8f0;overflow:hidden;margin-bottom:24px;">
        <div style="padding:20px 24px;border-bottom:1px solid #f1f5f9;display:flex;justify-content:space-between;align-items:center;">
            <h3 style="margin:0;font-size:1.1rem;font-weight:700;color:#0f172a;">چاوپێکەوتنەکانی من</h3>
            <span style="background:#f0fdfa;color:#0d9488;padding:4px 12px;border-radius:20px;font-size:0.8rem;font-weight:700;">{{ $appointments->total() }} چاوپێکەوتن</span>
        </div>
        
        @if($appointments->count() > 0)
            <div style="overflow-x:auto;">
                <table style="width:100%;border-collapse:collapse;text-align:right;">
                    <thead>
                        <tr style="background:#f8fafc;border-bottom:1px solid #e2e8f0;">
                            <th style="padding:16px 24px;font-size:0.8rem;font-weight:700;color:#64748b;text-transform:uppercase;">نەخۆش</th>
                            <th style="padding:16px 24px;font-size:0.8rem;font-weight:700;color:#64748b;text-transform:uppercase;">خزمەتگوزارییەکان</th>
                            <th style="padding:16px 24px;font-size:0.8rem;font-weight:700;color:#64748b;text-transform:uppercase;">کات و بەروار</th>
                            <th style="padding:16px 24px;font-size:0.8rem;font-weight:700;color:#64748b;text-transform:uppercase;">ناونیشان / ژ.مۆبایل</th>
                            <th style="padding:16px 24px;font-size:0.8rem;font-weight:700;color:#64748b;text-transform:uppercase;">نرخ</th>
                            <th style="padding:16px 24px;font-size:0.8rem;font-weight:700;color:#64748b;text-transform:uppercase;">دۆخ</th>
                            <th style="padding:16px 24px;font-size:0.8rem;font-weight:700;color:#64748b;text-transform:uppercase;">کردارەکان</th>
                        </tr>
                    </thead>
                    <tbody>
                    @foreach($appointments as $app)
                        <tr style="border-bottom:1px solid #f1f5f9;transition:background 0.2s;" onmouseover="this.style.background='#f8fafc'" onmouseout="this.style.background='transparent'">
                            <td style="padding:16px 24px;">
                                <div style="display:flex;align-items:center;gap:12px;">
                                    <div style="width:40px;height:40px;border-radius:50%;background:#e0f2fe;color:#0284c7;display:flex;align-items:center;justify-content:center;font-weight:bold;">
                                        {{ mb_substr($app->patient->name ?? 'ن', 0, 1) }}
                                    </div>
                                    <div>
                                        <div style="font-size:0.9rem;font-weight:700;color:#0f172a;">{{ $app->patient->name ?? 'نەخۆش' }}</div>
                                    </div>
                                </div>
                            </td>
                            <td style="padding:16px 24px;">
                                <div style="display:flex;flex-wrap:wrap;gap:6px;">
                                    @if($app->items && $app->items->count() > 0)
                                        @foreach($app->items as $item)
                                            <span style="background:#f1f5f9;color:#475569;padding:4px 10px;border-radius:6px;font-size:0.75rem;font-weight:600;">
                                                {{ $item->item_name }}
                                            </span>
                                        @endforeach
                                    @else
                                        <span style="color:#94a3b8;font-size:0.8rem;">دیارینەکراوە</span>
                                    @endif
                                </div>
                            </td>
                            <td style="padding:16px 24px;">
                                <div style="font-size:0.85rem;color:#334155;font-weight:600;">{{ $app->created_at->format('Y-m-d') }}</div>
                                <div style="font-size:0.75rem;color:#94a3b8;">{{ $app->created_at->format('h:i A') }}</div>
                            </td>
                            <td style="padding:16px 24px;">
                                @php
                                    $patientDetails = is_string($app->patient_details) ? json_decode($app->patient_details, true) : $app->patient_details;
                                @endphp
                                <div style="font-size:0.85rem;color:#334155;">{{ $patientDetails['location'] ?? 'ناونیشان دیارینەکراوە' }}</div>
                                <div style="font-size:0.75rem;color:#64748b;direction:ltr;text-align:right;">{{ $patientDetails['phone'] ?? '' }}</div>
                            </td>
                            <td style="padding:16px 24px;">
                                <div style="font-size:0.9rem;font-weight:700;color:#059669;">{{ number_format($app->total_price, 0) }} د.ع</div>
                            </td>
                            <td style="padding:16px 24px;">
                                @if($app->status == 'completed')
                                    <span style="background:#ecfdf5;color:#059669;padding:6px 12px;border-radius:8px;font-size:0.75rem;font-weight:700;">تەواوکراو</span>
                                @elseif($app->status == 'pending')
                                    <span style="background:#fffbeb;color:#d97706;padding:6px 12px;border-radius:8px;font-size:0.75rem;font-weight:700;">چاوەڕێکراو</span>
                                @elseif($app->status == 'processing')
                                    <span style="background:#eff6ff;color:#2563eb;padding:6px 12px;border-radius:8px;font-size:0.75rem;font-weight:700;">بەڕێوەیە</span>
                                @else
                                    <span style="background:#f1f5f9;color:#64748b;padding:6px 12px;border-radius:8px;font-size:0.75rem;font-weight:700;">{{ $app->status }}</span>
                                @endif
                            </td>
                            <td style="padding:16px 24px;">
                                <div style="display:flex;gap:8px;">
                                    @if($app->status != 'completed')
                                    <form action="{{ route('nurse.appointments.update_status', $app->id) }}" method="POST">
                                        @csrf
                                        @method('PATCH')
                                        <input type="hidden" name="status" value="completed">
                                        <button type="submit" style="background:#0d9488;color:#fff;border:none;padding:6px 12px;border-radius:6px;font-size:0.75rem;font-weight:bold;cursor:pointer;display:flex;align-items:center;gap:4px;">
                                            <svg width="14" height="14" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
                                            تەواوکردن
                                        </button>
                                    </form>
                                    @endif
                                </div>
                            </td>
                        </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
            <div style="padding:16px 24px;border-top:1px solid #f1f5f9;">
                {{ $appointments->links() }}
            </div>
        @else
            <div style="padding:40px;text-align:center;">
                <svg width="48" height="48" fill="none" stroke="#94a3b8" viewBox="0 0 24 24" style="margin:0 auto 16px;"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/></svg>
                <h3 style="margin:0 0 8px;font-size:1.1rem;color:#1e293b;font-weight:700;">هیچ چاوپێکەوتنێکت نییە</h3>
                <p style="margin:0;color:#64748b;font-size:0.9rem;">کاتێک داواکارییەک وەردەگریت لێرە دەردەکەوێت.</p>
            </div>
        @endif
    </div>

    <!-- Unassigned Requests (Pending) -->
    @if(isset($unassignedRequests) && $unassignedRequests->count() > 0)
    <div style="background:#fff;border-radius:16px;border:1px solid #fcd34d;overflow:hidden;box-shadow:0 10px 25px -5px rgba(251,191,36,0.1);">
        <div style="padding:20px 24px;background:#fffbeb;border-bottom:1px solid #fde68a;display:flex;justify-content:space-between;align-items:center;">
            <h3 style="margin:0;font-size:1.1rem;font-weight:700;color:#b45309;">داواکارییە نوێیەکان (کە پەرستاریان نییە)</h3>
            <span style="background:#fef3c7;color:#b45309;padding:4px 12px;border-radius:20px;font-size:0.8rem;font-weight:700;">{{ $unassignedRequests->count() }} داواکاری</span>
        </div>
        
        <div style="overflow-x:auto;">
            <table style="width:100%;border-collapse:collapse;text-align:right;">
                <thead>
                    <tr style="background:#fefce8;border-bottom:1px solid #fde68a;">
                        <th style="padding:16px 24px;font-size:0.8rem;font-weight:700;color:#92400e;text-transform:uppercase;">نەخۆش</th>
                        <th style="padding:16px 24px;font-size:0.8rem;font-weight:700;color:#92400e;text-transform:uppercase;">خزمەتگوزارییەکان</th>
                        <th style="padding:16px 24px;font-size:0.8rem;font-weight:700;color:#92400e;text-transform:uppercase;">کات و بەروار</th>
                        <th style="padding:16px 24px;font-size:0.8rem;font-weight:700;color:#92400e;text-transform:uppercase;">ناونیشان</th>
                        <th style="padding:16px 24px;font-size:0.8rem;font-weight:700;color:#92400e;text-transform:uppercase;">نرخ</th>
                        <th style="padding:16px 24px;font-size:0.8rem;font-weight:700;color:#92400e;text-transform:uppercase;">کردارەکان</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach($unassignedRequests as $req)
                    <tr style="border-bottom:1px solid #fef3c7;background:#fff;">
                        <td style="padding:16px 24px;">
                            <div style="font-size:0.9rem;font-weight:700;color:#0f172a;">{{ $req->patient->name ?? 'نەخۆش' }}</div>
                        </td>
                        <td style="padding:16px 24px;">
                            <div style="display:flex;flex-wrap:wrap;gap:6px;">
                                @if($req->items && $req->items->count() > 0)
                                    @foreach($req->items as $item)
                                        <span style="background:#fef3c7;color:#b45309;padding:4px 10px;border-radius:6px;font-size:0.75rem;font-weight:600;">
                                            {{ $item->item_name }}
                                        </span>
                                    @endforeach
                                @endif
                            </div>
                        </td>
                        <td style="padding:16px 24px;">
                            <div style="font-size:0.85rem;color:#334155;font-weight:600;">{{ $req->created_at->format('Y-m-d') }}</div>
                            <div style="font-size:0.75rem;color:#94a3b8;">{{ $req->created_at->format('h:i A') }}</div>
                        </td>
                        <td style="padding:16px 24px;">
                            @php
                                $patientDetails = is_string($req->patient_details) ? json_decode($req->patient_details, true) : $req->patient_details;
                            @endphp
                            <div style="font-size:0.85rem;color:#334155;">{{ $patientDetails['location'] ?? 'ناونیشان دیارینەکراوە' }}</div>
                        </td>
                        <td style="padding:16px 24px;">
                            <div style="font-size:0.9rem;font-weight:700;color:#b45309;">{{ number_format($req->total_price, 0) }} د.ع</div>
                        </td>
                        <td style="padding:16px 24px;">
                            <form action="{{ route('nurse.appointments.accept', $req->id) }}" method="POST">
                                @csrf
                                <button type="submit" style="background:#f59e0b;color:#fff;border:none;padding:8px 16px;border-radius:8px;font-size:0.8rem;font-weight:bold;cursor:pointer;transition:background 0.2s;display:flex;align-items:center;gap:6px;" onmouseover="this.style.background='#d97706'" onmouseout="this.style.background='#f59e0b'">
                                    <svg width="14" height="14" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                                    وەرگرتنی سەردان
                                </button>
                            </form>
                        </td>
                    </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    </div>
    @endif
</div>
@endsection
