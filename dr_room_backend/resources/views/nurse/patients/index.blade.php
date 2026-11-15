@extends('nurse.layouts.app')
@section('header_title', 'نەخۆشەکانم')

@section('content')
<div class="w-full fade-up">
    <div class="mb-6 flex flex-wrap justify-between items-center gap-4 bg-white rounded-2xl shadow-sm border border-slate-200/80 px-6 py-5">
        <div>
            <h2 class="text-xl font-bold text-slate-800">لیستی نەخۆشەکانم</h2>
            <p class="text-sm text-slate-500 mt-1">ئەو نەخۆشانەی کە پێشتر چاوپێکەوتنیان لەگەڵ تۆ هەبووە.</p>
        </div>
        <span class="inline-flex items-center px-3.5 py-1.5 rounded-full text-xs font-bold bg-teal-50 text-teal-700 border border-teal-100">
            {{ $patients->total() }} نەخۆش
        </span>
    </div>

    <div class="bg-white rounded-2xl shadow-sm border border-slate-200/80 overflow-hidden w-full">
        <div class="overflow-x-auto">
            <table class="w-full text-right text-sm">
                <thead class="bg-slate-50 border-b border-slate-100 text-slate-600 font-bold">
                    <tr>
                        <th class="px-6 py-4 text-right whitespace-nowrap">ناوی نەخۆش</th>
                        <th class="px-6 py-4 text-right whitespace-nowrap">مۆبایل</th>
                        <th class="px-6 py-4 text-right whitespace-nowrap">ژمارەی سەردانەکان</th>
                        <th class="px-6 py-4 text-right whitespace-nowrap">کۆتا سەردان</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                    @forelse($patients as $patient)
                        <tr class="hover:bg-slate-50/70 transition-colors">
                            <td class="px-6 py-4 text-right">
                                <div class="flex items-center gap-3">
                                    <div class="w-10 h-10 rounded-full bg-teal-50 text-teal-700 flex items-center justify-center font-bold text-sm shrink-0">
                                        {{ mb_substr($patient->name ?? 'ن', 0, 1) }}
                                    </div>
                                    <div>
                                        <div class="font-semibold text-slate-800">{{ $patient->name }}</div>
                                        <div class="text-xs text-slate-500">{{ $patient->email ?? '-' }}</div>
                                    </div>
                                </div>
                            </td>
                            <td class="px-6 py-4 text-right text-slate-600 whitespace-nowrap">
                                @if($patient->phone)
                                    <span dir="ltr" class="inline-block font-medium">{{ $patient->phone }}</span>
                                @else
                                    <span>نەزانراو</span>
                                @endif
                            </td>
                            <td class="px-6 py-4 text-right whitespace-nowrap">
                                <span class="inline-flex items-center justify-center px-3 py-1 rounded-full text-xs font-bold bg-teal-50 text-teal-700">
                                    {{ ($patient->total_visits ?? 0) + ($patient->total_appointments ?? 0) }}
                                </span>
                            </td>
                            <td class="px-6 py-4 text-right text-slate-600 whitespace-nowrap">
                                @php
                                    $lastOrderDate = $patient->orders->first()?->created_at?->copy()->timezone('Asia/Baghdad');
                                    $lastAppDate = $patient->nurseAppointments->first()?->appointment_date;
                                    $lastVisit = null;
                                    if ($lastOrderDate && $lastAppDate) {
                                        $lastVisit = $lastOrderDate->gt($lastAppDate) ? $lastOrderDate : $lastAppDate;
                                    } else {
                                        $lastVisit = $lastOrderDate ?? $lastAppDate;
                                    }
                                @endphp
                                <span dir="ltr" class="inline-block">{{ $lastVisit ? \Carbon\Carbon::parse($lastVisit)->format('Y-m-d') : '-' }}</span>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="4" class="px-6 py-12 text-center text-slate-500">
                                <svg class="w-12 h-12 text-slate-300 mx-auto mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"></path></svg>
                                هیچ نەخۆشێک نەدۆزرایەوە
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        
        @if($patients->hasPages())
            <div class="p-4 border-t border-slate-100">
                {{ $patients->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
