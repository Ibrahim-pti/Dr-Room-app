@extends('lab.layouts.app')
@section('header_title', 'بەڕێوەبردنی پشکنینەکان')

@section('content')
<div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-6 rounded-3xl shadow-sm border border-slate-100">
        <div>
            <h2 class="text-xl font-bold text-slate-800">لیستی پشکنینە بەردەستەکانی تاقیگە</h2>
            <p class="text-sm text-slate-500 mt-1">ئەو پشکنینانەی لە تاقیگەکەت بەردەستن و لە ئەپڵیکەیشندا بۆ نەخۆشەکان دەردەکەون.</p>
        </div>
        <a href="{{ route('lab.tests.create') }}" class="inline-flex items-center gap-2 px-5 py-2.5 bg-blue-600 hover:bg-blue-700 text-white font-bold rounded-2xl shadow-md shadow-blue-200 transition-all text-sm">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
            زیادکردنی پشکنینی نوێ
        </a>
    </div>

    <!-- Filter Type Buttons -->
    <div class="flex items-center gap-2 bg-white p-2 rounded-2xl shadow-sm border border-slate-100 overflow-x-auto">
        <a href="{{ route('lab.tests.index') }}" 
           class="px-4 py-2 rounded-xl text-xs font-bold transition-all {{ !$type ? 'bg-blue-600 text-white shadow-sm' : 'text-slate-600 hover:bg-slate-50' }}">
            هەموو جۆرەکان ({{ $tests->count() }})
        </a>
        <a href="{{ route('lab.tests.index', ['type' => 'blood']) }}" 
           class="px-4 py-2 rounded-xl text-xs font-bold transition-all {{ $type == 'blood' ? 'bg-rose-600 text-white shadow-sm' : 'text-slate-600 hover:bg-slate-50' }}">
            🩸 پشکنینی خوێن
        </a>
        <a href="{{ route('lab.tests.index', ['type' => 'urine']) }}" 
           class="px-4 py-2 rounded-xl text-xs font-bold transition-all {{ $type == 'urine' ? 'bg-amber-600 text-white shadow-sm' : 'text-slate-600 hover:bg-slate-50' }}">
            🧪 پشکنینی میز
        </a>
        <a href="{{ route('lab.tests.index', ['type' => 'hormone']) }}" 
           class="px-4 py-2 rounded-xl text-xs font-bold transition-all {{ $type == 'hormone' ? 'bg-purple-600 text-white shadow-sm' : 'text-slate-600 hover:bg-slate-50' }}">
            🧬 پشکنینی هۆرمۆن
        </a>
        <a href="{{ route('lab.tests.index', ['type' => 'other']) }}" 
           class="px-4 py-2 rounded-xl text-xs font-bold transition-all {{ $type == 'other' ? 'bg-slate-700 text-white shadow-sm' : 'text-slate-600 hover:bg-slate-50' }}">
            🔬 ئەوانی تر
        </a>
    </div>

    @if(session('success'))
        <div class="p-4 bg-emerald-50 border border-emerald-200 text-emerald-700 rounded-2xl font-bold flex items-center gap-3">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
            {{ session('success') }}
        </div>
    @endif

    <!-- Tests Table -->
    <div class="bg-white rounded-3xl shadow-sm border border-slate-100 overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-right text-sm">
                <thead class="bg-slate-50 border-b border-slate-100 text-slate-500 font-bold">
                    <tr>
                        <th class="px-6 py-4">ناوی پشکنین</th>
                        <th class="px-6 py-4">جۆر</th>
                        <th class="px-6 py-4">نرخ (IQD)</th>
                        <th class="px-6 py-4">داشکاندن</th>
                        <th class="px-6 py-4">حاڵەت</th>
                        <th class="px-6 py-4 text-center">کردارەکان</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                    @forelse($tests as $test)
                        <tr class="hover:bg-slate-50/60 transition-colors">
                            <!-- Name -->
                            <td class="px-6 py-4">
                                <div class="font-bold text-slate-800 text-base">{{ $test->name }}</div>
                                @if($test->name_en || $test->name_ar)
                                    <div class="text-xs text-slate-400 mt-0.5" dir="ltr">
                                        {{ $test->name_en ?? $test->name_ar }}
                                    </div>
                                @endif
                                @if($test->description)
                                    <div class="text-xs text-slate-500 mt-1 max-w-sm line-clamp-1" title="{{ $test->description }}">
                                        {{ $test->description }}
                                    </div>
                                @endif
                            </td>

                            <!-- Type -->
                            <td class="px-6 py-4">
                                @if($test->type == 'blood')
                                    <span class="inline-flex items-center gap-1 px-2.5 py-1 rounded-xl bg-rose-50 text-rose-700 font-bold text-xs border border-rose-200/50">
                                        🩸 خوێن
                                    </span>
                                @elseif($test->type == 'urine')
                                    <span class="inline-flex items-center gap-1 px-2.5 py-1 rounded-xl bg-amber-50 text-amber-700 font-bold text-xs border border-amber-200/50">
                                        🧪 میز
                                    </span>
                                @elseif($test->type == 'hormone')
                                    <span class="inline-flex items-center gap-1 px-2.5 py-1 rounded-xl bg-purple-50 text-purple-700 font-bold text-xs border border-purple-200/50">
                                        🧬 هۆرمۆن
                                    </span>
                                @else
                                    <span class="inline-flex items-center gap-1 px-2.5 py-1 rounded-xl bg-slate-100 text-slate-700 font-bold text-xs">
                                        🔬 گشتی
                                    </span>
                                @endif
                            </td>

                            <!-- Price -->
                            <td class="px-6 py-4">
                                <div class="font-black text-slate-800 text-base" dir="ltr">
                                    {{ number_format($test->price) }} د.ع
                                </div>
                            </td>

                            <!-- Discount -->
                            <td class="px-6 py-4">
                                @if($test->discount && $test->discount > 0)
                                    <span class="inline-flex items-center px-2.5 py-1 rounded-xl bg-red-50 text-red-600 font-black text-xs border border-red-200">
                                        {{ $test->discount }}% داشکاندن
                                    </span>
                                @else
                                    <span class="text-xs text-slate-400">داشکاندن نییە</span>
                                @endif
                            </td>

                            <!-- Status -->
                            <td class="px-6 py-4">
                                @if($test->is_active)
                                    <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                                        <span class="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                                        چالاکە لە ئەپ
                                    </span>
                                @else
                                    <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-slate-100 text-slate-500">
                                        <span class="w-1.5 h-1.5 rounded-full bg-slate-400"></span>
                                        ناچالاکە
                                    </span>
                                @endif
                            </td>

                            <!-- Actions -->
                            <td class="px-6 py-4 text-center">
                                <div class="flex items-center justify-center gap-2">
                                    <a href="{{ route('lab.tests.edit', $test) }}" 
                                       class="px-3 py-1.5 bg-blue-50 text-blue-600 hover:bg-blue-600 hover:text-white rounded-xl font-bold text-xs transition-all flex items-center gap-1">
                                        <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/></svg>
                                        دەستکاری
                                    </a>
                                    <form action="{{ route('lab.tests.destroy', $test) }}" method="POST" class="inline-block" onsubmit="return confirm('ئایا دڵنیایت لە سڕینەوەی ئەم پشکنینە؟');">
                                        @csrf
                                        @method('DELETE')
                                        <button type="submit" class="px-3 py-1.5 bg-rose-50 text-rose-600 hover:bg-rose-600 hover:text-white rounded-xl font-bold text-xs transition-all flex items-center gap-1">
                                            <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
                                            سڕینەوە
                                        </button>
                                    </form>
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" class="px-6 py-16 text-center text-slate-500">
                                <div class="w-16 h-16 bg-slate-50 rounded-full flex items-center justify-center mx-auto mb-3 text-slate-300">
                                    <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"/></svg>
                                </div>
                                <div class="font-bold text-slate-700 text-base">هیچ پشکنینێک تۆمار نەکراوە</div>
                                <div class="text-xs text-slate-400 mt-1">کلیك لەسەر دوگمەی "زیادکردنی پشکنینی نوێ" بکە بۆ زیادکردن.</div>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection
