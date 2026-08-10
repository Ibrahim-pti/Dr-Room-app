@extends('doctor.layouts.app')
@section('header_title', 'داهاتەکان')

@section('content')
<div class="mb-6">
    <h2 class="text-xl font-bold text-slate-800">داهاتەکانت</h2>
    <p class="text-sm text-slate-500 mt-1">پوختەی داهاتەکانت لە چاوپێکەوتنە تەواوکراوەکان.</p>
</div>

<div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
    <!-- Total Earnings -->
    <div class="bg-white rounded-2xl shadow-sm border border-slate-200/60 p-6 flex items-center justify-between">
        <div>
            <p class="text-sm font-medium text-slate-500 mb-1">کۆی گشتی داهات</p>
            <h3 class="text-3xl font-bold text-slate-800" dir="ltr">${{ number_format($totalEarnings, 2) }}</h3>
        </div>
        <div class="w-14 h-14 rounded-full bg-blue-50 flex items-center justify-center text-blue-600">
            <svg class="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
        </div>
    </div>

    <!-- Monthly Earnings -->
    <div class="bg-white rounded-2xl shadow-sm border border-slate-200/60 p-6 flex items-center justify-between">
        <div>
            <p class="text-sm font-medium text-slate-500 mb-1">داهاتی ئەم مانگە</p>
            <h3 class="text-3xl font-bold text-slate-800" dir="ltr">${{ number_format($monthlyEarnings, 2) }}</h3>
        </div>
        <div class="w-14 h-14 rounded-full bg-green-50 flex items-center justify-center text-green-600">
            <svg class="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path></svg>
        </div>
    </div>
</div>

<div class="bg-white rounded-2xl shadow-sm border border-slate-200/60 overflow-hidden">
    <div class="p-6 border-b border-slate-100">
        <h3 class="text-lg font-bold text-slate-800">چاوپێکەوتنە پارە دراوەکان</h3>
    </div>
    <div class="overflow-x-auto">
        <table class="w-full text-right text-sm">
            <thead class="bg-slate-50 border-b border-slate-100 text-slate-500 font-medium">
                <tr>
                    <th class="px-6 py-4">نەخۆش</th>
                    <th class="px-6 py-4">بەروار</th>
                    <th class="px-6 py-4">بڕی پارە</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
                @forelse($completedAppointments as $appointment)
                    <tr class="hover:bg-slate-50/50 transition-colors">
                        <td class="px-6 py-4">
                            <div class="font-semibold text-slate-800">{{ $appointment->patient->name ?? 'نەناسراو' }}</div>
                        </td>
                        <td class="px-6 py-4 text-slate-600" dir="ltr">
                            {{ $appointment->appointment_date->format('Y-m-d') }}
                        </td>
                        <td class="px-6 py-4 text-slate-800 font-semibold" dir="ltr">
                            ${{ number_format($appointment->fee, 2) }}
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="3" class="px-6 py-12 text-center text-slate-500">
                            هیچ داهاتێک نەدۆزرایەوە
                        </td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>
    
    @if($completedAppointments->hasPages())
        <div class="p-4 border-t border-slate-100">
            {{ $completedAppointments->links() }}
        </div>
    @endif
</div>
@endsection
