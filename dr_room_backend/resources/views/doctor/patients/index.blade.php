@extends('doctor.layouts.app')
@section('header_title', 'نەخۆشەکانم')

@section('content')
<div class="mb-6 flex justify-between items-center">
    <div>
        <h2 class="text-xl font-bold text-slate-800">لیستی نەخۆشەکانم</h2>
        <p class="text-sm text-slate-500 mt-1">ئەو نەخۆشانەی کە پێشتر چاوپێکەوتنیان لەگەڵ تۆ هەبووە.</p>
    </div>
</div>

<div class="bg-white rounded-2xl shadow-sm border border-slate-200/60 overflow-hidden">
    <div class="overflow-x-auto">
        <table class="w-full text-right text-sm">
            <thead class="bg-slate-50 border-b border-slate-100 text-slate-500 font-medium">
                <tr>
                    <th class="px-6 py-4">ناوی نەخۆش</th>
                    <th class="px-6 py-4">مۆبایل</th>
                    <th class="px-6 py-4">ژمارەی سەردانەکان</th>
                    <th class="px-6 py-4">کۆتا سەردان</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
                @forelse($patients as $patient)
                    <tr class="hover:bg-slate-50/50 transition-colors">
                        <td class="px-6 py-4">
                            <div class="font-semibold text-slate-800">{{ $patient->name }}</div>
                            <div class="text-xs text-slate-500">{{ $patient->email ?? '-' }}</div>
                        </td>
                        <td class="px-6 py-4 text-slate-600" dir="ltr">
                            {{ $patient->phone ?? 'نەزانراو' }}
                        </td>
                        <td class="px-6 py-4">
                            <span class="inline-flex items-center justify-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                                {{ $patient->total_visits }}
                            </span>
                        </td>
                        <td class="px-6 py-4 text-slate-600" dir="ltr">
                            {{ $patient->appointments->first()->appointment_date->format('Y-m-d') ?? '-' }}
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
@endsection
