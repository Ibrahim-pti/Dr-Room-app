@extends('nurse.layouts.app')
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

@if(isset($unassignedRequests) && $unassignedRequests->count() > 0)
<div class="mb-8">
    <h3 class="text-lg font-bold text-amber-700 mb-4">داواکارییە نوێیەکان (بۆ وەرگرتن)</h3>
    <div class="bg-white rounded-2xl shadow-sm border border-amber-200 overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-start text-sm table-fixed">
                <thead class="bg-amber-50 border-b border-amber-100 text-amber-700 font-medium">
                    <tr>
                        <th class="px-6 py-4 whitespace-nowrap">نەخۆش</th>
                        <th class="px-6 py-4 whitespace-nowrap">خزمەتگوزارییەکان</th>
                        <th class="px-6 py-4 whitespace-nowrap">ناونیشان و مۆبایل</th>
                        <th class="px-6 py-4 whitespace-nowrap">بەروار و کات</th>
                        <th class="px-6 py-4 whitespace-nowrap">تێبینی</th>
                        <th class="px-6 py-4 text-center whitespace-nowrap">کردارەکان</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-amber-100">
                    @foreach($unassignedRequests as $req)
                        <tr class="hover:bg-amber-50/30 transition-colors">
                            <td class="px-6 py-4">
                                <div class="font-semibold text-slate-800">{{ $req->patient->name ?? 'نەناسراو' }}</div>
                            </td>
                            <td class="px-6 py-4 text-slate-600 font-medium">
                                @if($req->services)
                                    {{ implode('، ', array_map(function($s) {
                                        $map = ['injection' => 'دەرزی', 'cannula' => 'کانیۆلا', 'dressing' => 'پانسیمان', 'checkup' => 'چاودێری'];
                                        return $map[$s] ?? $s;
                                    }, is_array($req->services) ? $req->services : json_decode($req->services, true) ?? [])) }}
                                @else
                                    پشکنینی گشتی
                                @endif
                                <div class="text-xs text-emerald-600 mt-1">{{ number_format($req->fee, 0) }} د.ع</div>
                            </td>
                            <td class="px-6 py-4 text-slate-600 text-xs">
                                <div>{{ $req->address ?? '-' }}</div>
                                <div dir="ltr" class="text-right text-slate-400 mt-1">{{ $req->phone ?? '-' }}</div>
                            </td>
                            <td class="px-6 py-4 text-slate-600 text-xs" dir="ltr">
                                {{ $req->appointment_date->format('Y-m-d h:i A') }}
                            </td>
                            <td class="px-6 py-4 text-slate-600 text-xs max-w-[150px] truncate" title="{{ $req->notes }}">
                                {{ $req->notes ?? '-' }}
                            </td>
                            <td class="px-6 py-4 text-center">
                                <form action="{{ route('nurse.appointments.accept', $req->id) }}" method="POST" class="inline">
                                    @csrf
                                    <button type="submit" class="bg-amber-500 hover:bg-amber-600 text-white px-4 py-1.5 rounded-lg transition-colors text-xs font-bold shadow-sm">
                                        وەرگرتن
                                    </button>
                                </form>
                            </td>
                        </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    </div>
</div>
@endif

<div>
    <h3 class="text-lg font-bold text-slate-800 mb-4">کارەکانی خۆم</h3>
<div class="bg-white rounded-2xl shadow-sm border border-slate-200/60 overflow-hidden">
    <div class="overflow-x-auto">
        <table class="w-full text-start text-sm table-fixed">
            <thead class="bg-slate-50 border-b border-slate-100 text-slate-500 font-medium">
                <tr>
                    <th class="px-6 py-4 whitespace-nowrap">نەخۆش</th>
                    <th class="px-6 py-4 whitespace-nowrap">خزمەتگوزارییەکان</th>
                    <th class="px-6 py-4 whitespace-nowrap">ناونیشان و مۆبایل</th>
                    <th class="px-6 py-4 whitespace-nowrap">بەروار و کات</th>
                    <th class="px-6 py-4 whitespace-nowrap">دۆخ</th>
                    <th class="px-6 py-4 text-center whitespace-nowrap">کردارەکان</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
                @forelse($appointments as $appointment)
                    <tr class="hover:bg-slate-50/50 transition-colors">
                        <td class="px-6 py-4">
                            <div class="font-semibold text-slate-800">{{ $appointment->patient->name ?? 'نەناسراو' }}</div>
                        </td>
                        <td class="px-6 py-4 text-slate-600 font-medium">
                            @if($appointment->services)
                                {{ implode('، ', array_map(function($s) {
                                    $map = ['injection' => 'دەرزی', 'cannula' => 'کانیۆلا', 'dressing' => 'پانسیمان', 'checkup' => 'چاودێری'];
                                    return $map[$s] ?? $s;
                                }, is_array($appointment->services) ? $appointment->services : json_decode($appointment->services, true) ?? [])) }}
                            @else
                                پشکنینی گشتی
                            @endif
                            <div class="text-xs text-emerald-600 mt-1">{{ number_format($appointment->fee, 0) }} د.ع</div>
                        </td>
                        <td class="px-6 py-4 text-slate-600 text-xs">
                            <div>{{ $appointment->address ?? '-' }}</div>
                            <div dir="ltr" class="text-right text-slate-400 mt-1">{{ $appointment->phone ?? '-' }}</div>
                        </td>
                        <td class="px-6 py-4 text-slate-600 text-xs" dir="ltr">
                            {{ $appointment->appointment_date->format('Y-m-d h:i A') }}
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
                            @if($appointment->status === 'pending' || $appointment->status === 'confirmed')
                                <form action="{{ route('nurse.appointments.update_status', $appointment) }}" method="POST" class="inline">
                                    @csrf
                                    @method('PATCH')
                                    <input type="hidden" name="status" value="completed">
                                    <button type="submit" class="text-green-600 hover:bg-green-50 px-3 py-1.5 rounded transition-colors text-xs font-medium border border-green-200">تەواوکردن</button>
                                </form>
                                <form action="{{ route('nurse.appointments.update_status', $appointment) }}" method="POST" class="inline">
                                    @csrf
                                    @method('PATCH')
                                    <input type="hidden" name="status" value="cancelled">
                                    <button type="submit" class="text-red-600 hover:bg-red-50 px-3 py-1.5 rounded transition-colors text-xs font-medium border border-red-200 mr-2">ڕەتکردنەوە</button>
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
</div>
@endsection
