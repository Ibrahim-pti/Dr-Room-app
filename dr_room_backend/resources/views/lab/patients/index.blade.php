@extends('lab.layouts.app')

@section('content')
<div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-6 rounded-3xl shadow-sm border border-slate-100">
        <div>
            <h2 class="text-xl font-bold text-slate-800">داواکارییەکانی تاقیگە</h2>
            <p class="text-sm text-slate-500 mt-1">ئەو نەخۆشانەی کە پشکنینیان بۆ کراوە یان لە چاوەڕوانیدان.</p>
        </div>
    </div>

    <div class="bg-white rounded-3xl shadow-sm border border-slate-100 overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-right text-sm">
                <thead class="bg-slate-50 border-b border-slate-100 text-slate-500 font-medium">
                    <tr>
                        <th class="px-6 py-4">ناوی نەخۆش</th>
                        <th class="px-6 py-4">مۆبایل</th>
                        <th class="px-6 py-4">کۆتا سەردان</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                    @forelse($patients as $patient)
                        <tr class="hover:bg-slate-50/50 transition-colors">
                            <td class="px-6 py-4">
                                <div class="font-bold text-slate-800">{{ $patient->name }}</div>
                                <div class="text-xs font-medium text-slate-500">{{ $patient->email ?? '-' }}</div>
                            </td>
                            <td class="px-6 py-4 text-slate-600 font-medium" dir="ltr">
                                {{ $patient->phone ?? 'نەزانراو' }}
                            </td>
                            <td class="px-6 py-4 text-slate-600 font-medium" dir="ltr">
                                {{ $patient->created_at->format('Y-m-d') }}
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="3" class="px-6 py-12 text-center text-slate-500">
                                <svg class="w-12 h-12 text-slate-300 mx-auto mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"></path></svg>
                                هیچ داواکارییەک نەدۆزرایەوە
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        
        @if(method_exists($patients, 'hasPages') && $patients->hasPages())
            <div class="p-4 border-t border-slate-100">
                {{ $patients->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
