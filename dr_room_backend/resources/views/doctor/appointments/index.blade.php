@extends('doctor.layouts.app')
@section('header_title', 'چاوپێکەوتنەکان')

@section('content')
<div class="mb-6 flex justify-between items-center">
    <div>
        <h2 class="text-xl font-bold text-slate-800">خشتەی چاوپێکەوتنەکان</h2>
        <p class="text-sm text-slate-500 mt-1">لێرە دەتوانیت سەرجەم چاوپێکەوتنەکانت ببینیت و بەڕێوەیان ببەیت.</p>
    </div>
</div>

@if(session('success'))
    <div class="mb-6 p-4 bg-green-50 border border-green-200 text-green-700 rounded-xl">
        {{ session('success') }}
    </div>
@endif

<div class="bg-white rounded-2xl shadow-sm border border-slate-200/60 overflow-hidden">
    <div class="overflow-x-auto">
        <table class="w-full text-right text-sm">
            <thead class="bg-slate-50 border-b border-slate-100 text-slate-500 font-medium">
                <tr>
                    <th class="px-6 py-4">نەخۆش</th>
                    <th class="px-6 py-4">بەروار و کات</th>
                    <th class="px-6 py-4">جۆر</th>
                    <th class="px-6 py-4">تێبینی</th>
                    <th class="px-6 py-4">دۆخ</th>
                    <th class="px-6 py-4 text-center">کردارەکان</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
                @forelse($appointments as $appointment)
                    <tr class="hover:bg-slate-50/50 transition-colors">
                        <td class="px-6 py-4">
                            <div class="font-semibold text-slate-800">{{ $appointment->patient->name ?? 'نەناسراو' }}</div>
                            <div class="text-xs text-slate-500">{{ $appointment->patient->phone ?? '' }}</div>
                        </td>
                        <td class="px-6 py-4 text-slate-600" dir="ltr">
                            {{ $appointment->appointment_date->format('Y-m-d H:i') }}
                        </td>
                        <td class="px-6 py-4 text-slate-600">
                            {{ $appointment->type === 'in_person' ? 'لە نۆڕینگە' : 'ئۆنلاین' }}
                        </td>
                        <td class="px-6 py-4 text-slate-600 max-w-xs truncate" title="{{ $appointment->notes }}">
                            {{ $appointment->notes ?? '-' }}
                        </td>
                        <td class="px-6 py-4">
                            @if($appointment->status === 'pending')
                                <span class="px-3 py-1 bg-yellow-100 text-yellow-700 rounded-full text-xs font-semibold">چاوەڕێکراو</span>
                            @elseif($appointment->status === 'confirmed')
                                <span class="px-3 py-1 bg-blue-100 text-blue-700 rounded-full text-xs font-semibold">پەسەندکراو</span>
                            @elseif($appointment->status === 'completed')
                                <span class="px-3 py-1 bg-green-100 text-green-700 rounded-full text-xs font-semibold">تەواوبوو</span>
                            @else
                                <span class="px-3 py-1 bg-red-100 text-red-700 rounded-full text-xs font-semibold">هەڵوەشایەوە</span>
                            @endif
                        </td>
                        <td class="px-6 py-4 text-center">
                            @if($appointment->status === 'pending')
                                <form action="{{ route('doctor.appointments.update_status', $appointment) }}" method="POST" class="inline">
                                    @csrf
                                    @method('PATCH')
                                    <input type="hidden" name="status" value="confirmed">
                                    <button type="submit" class="text-blue-600 hover:bg-blue-50 px-3 py-1 rounded transition-colors text-xs font-medium border border-blue-200 mr-2">پەسەندکردن</button>
                                </form>
                                <form action="{{ route('doctor.appointments.update_status', $appointment) }}" method="POST" class="inline">
                                    @csrf
                                    @method('PATCH')
                                    <input type="hidden" name="status" value="cancelled">
                                    <button type="submit" class="text-red-600 hover:bg-red-50 px-3 py-1 rounded transition-colors text-xs font-medium border border-red-200">ڕەتکردنەوە</button>
                                </form>
                            @elseif($appointment->status === 'confirmed')
                                <form action="{{ route('doctor.appointments.update_status', $appointment) }}" method="POST" class="inline">
                                    @csrf
                                    @method('PATCH')
                                    <input type="hidden" name="status" value="completed">
                                    <button type="submit" class="text-green-600 hover:bg-green-50 px-3 py-1 rounded transition-colors text-xs font-medium border border-green-200">تەواوکردن</button>
                                </form>
                            @else
                                <span class="text-slate-400 text-xs">هیچ کردارێک نییە</span>
                            @endif
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="6" class="px-6 py-12 text-center text-slate-500">
                            <svg class="w-12 h-12 text-slate-300 mx-auto mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path></svg>
                            هیچ چاوپێکەوتنێک نەدۆزرایەوە
                        </td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>
    
    @if($appointments->hasPages())
        <div class="p-4 border-t border-slate-100">
            {{ $appointments->links() }}
        </div>
    @endif
</div>
@endsection
