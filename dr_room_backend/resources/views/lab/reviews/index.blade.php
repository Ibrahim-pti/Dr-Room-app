@extends('lab.layouts.app')
@section('header_title', 'هەڵسەنگاندن و فیدباکەکان')

@section('content')
<div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white p-6 rounded-3xl shadow-sm border border-slate-100">
        <div>
            <div class="flex items-center gap-3">
                <h2 class="text-xl font-bold text-slate-800">ڕا و هەڵسەنگاندنی نەخۆشەکان</h2>
                <span class="px-3 py-1 bg-amber-50 text-amber-600 rounded-full text-xs font-bold border border-amber-100 flex items-center gap-1">
                    <svg class="w-3.5 h-3.5 fill-current" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/></svg>
                    تێکڕا: {{ number_format($rating, 1) }} لە ٥
                </span>
            </div>
            <p class="text-sm text-slate-500 mt-1">هەموو ئەو ئەستێرە و سەرنجانەی نەخۆش لە ئەپڵیکەیشنەوە بۆ ئەم تاقیگەیەی ناردووە.</p>
        </div>

        <div class="flex items-center gap-3">
            <div class="px-4 py-2 bg-blue-50 text-blue-700 rounded-2xl text-xs font-bold border border-blue-100 flex items-center gap-2">
                <svg class="w-4 h-4 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
                <span>کۆی سەردانی پرۆفایل: <strong class="text-blue-800 text-sm">{{ number_format($viewsCount) }}</strong></span>
            </div>
        </div>
    </div>

    <!-- Rating Stats Overview -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <!-- Big Score Card -->
        <div class="bg-gradient-to-br from-amber-500 to-amber-600 rounded-3xl p-8 text-white shadow-lg shadow-amber-500/20 flex flex-col items-center justify-center text-center">
            <div class="text-6xl font-black mb-2">{{ number_format($rating, 1) }}</div>
            <div class="flex items-center gap-1.5 mb-3">
                @for($i = 1; $i <= 5; $i++)
                    <svg class="w-6 h-6 {{ $i <= round($rating) ? 'text-amber-200 fill-current' : 'text-amber-700/50 fill-current' }}" viewBox="0 0 20 20">
                        <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/>
                    </svg>
                @endfor
            </div>
            <div class="text-sm font-bold text-amber-100">
                لە کۆی {{ number_format($totalReviews) }} هەڵسەنگاندنی نەخۆش
            </div>
        </div>

        <!-- Breakdown Progress Bars -->
        <div class="md:col-span-2 bg-white rounded-3xl p-6 shadow-sm border border-slate-100 flex flex-col justify-center space-y-3">
            @foreach(range(5, 1) as $star)
                @php
                    $b = $breakdown[$star] ?? ['count' => 0, 'percentage' => 0];
                @endphp
                <div class="flex items-center gap-3 text-xs">
                    <div class="flex items-center gap-1 w-16 font-bold text-slate-700">
                        <span>{{ $star }}</span>
                        <svg class="w-3.5 h-3.5 fill-current text-amber-400" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/></svg>
                    </div>
                    <div class="flex-1 h-3 bg-slate-100 rounded-full overflow-hidden">
                        <div class="h-full bg-amber-400 rounded-full transition-all duration-500" style="width: {{ $b['percentage'] }}%;"></div>
                    </div>
                    <div class="w-16 text-left font-bold text-slate-500">
                        {{ $b['count'] }} ({{ $b['percentage'] }}%)
                    </div>
                </div>
            @endforeach
        </div>
    </div>

    <!-- Reviews List -->
    <div class="bg-white rounded-3xl shadow-sm border border-slate-100 overflow-hidden">
        <div class="p-6 border-b border-slate-100 flex items-center justify-between">
            <h3 class="font-bold text-slate-800 text-base">لیستی سەرنج و فیدباکەکان</h3>
            <span class="text-xs text-slate-400">نوێترین لە سەرەوە</span>
        </div>

        <div class="divide-y divide-slate-100">
            @forelse($reviews as $review)
                <div class="p-6 hover:bg-slate-50/60 transition-colors space-y-3">
                    <div class="flex items-start justify-between gap-4">
                        <div class="flex items-center gap-3">
                            <div class="w-10 h-10 rounded-full bg-blue-100 text-blue-600 flex items-center justify-center font-bold text-sm overflow-hidden">
                                @if($review->patient?->profile_image)
                                    <img src="{{ asset('storage/' . $review->patient->profile_image) }}" class="w-full h-full object-cover">
                                @else
                                    {{ mb_substr($review->patient?->name ?? 'ن', 0, 1) }}
                                @endif
                            </div>
                            <div>
                                <div class="font-bold text-slate-800 text-sm">
                                    {{ $review->patient?->name ?? 'نەخۆش' }}
                                </div>
                                <div class="text-xs text-slate-400">
                                    {{ $review->created_at ? $review->created_at->diffForHumans() : 'نوێ' }}
                                </div>
                            </div>
                        </div>

                        <!-- Stars -->
                        <div class="flex items-center gap-1 px-3 py-1 bg-amber-50 rounded-xl border border-amber-100">
                            @for($i = 1; $i <= 5; $i++)
                                <svg class="w-3.5 h-3.5 {{ $i <= $review->rating ? 'text-amber-400 fill-current' : 'text-slate-200 fill-current' }}" viewBox="0 0 20 20">
                                    <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/>
                                </svg>
                            @endfor
                            <span class="text-xs font-bold text-amber-700 mr-1">{{ $review->rating }}.0</span>
                        </div>
                    </div>

                    <!-- Comment text -->
                    @if($review->comment)
                        <div class="text-xs text-slate-700 leading-relaxed bg-slate-50 p-3.5 rounded-2xl border border-slate-100">
                            {{ $review->comment }}
                        </div>
                    @else
                        <div class="text-xs text-slate-400 italic">
                            (تەنها ئەستێرەی داوە بە بێ نووسینی فیدباک)
                        </div>
                    @endif
                </div>
            @empty
                <div class="p-16 text-center text-slate-400">
                    <div class="w-16 h-16 bg-amber-50 rounded-full flex items-center justify-center mx-auto mb-3 text-amber-400">
                        <svg class="w-8 h-8 fill-current" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/></svg>
                    </div>
                    <div class="font-bold text-slate-700 text-base">هێشتا هیچ هەڵسەنگاندنێک تۆمار نەکراوە</div>
                    <div class="text-xs text-slate-400 mt-1">کاتێک نەخۆش لە ئەپڵیکەیشنەوە ئەستێرە یان سەرنج دەدات، لێرە پیشان دەدرێت.</div>
                </div>
            @endforelse
        </div>

        @if($reviews->hasPages())
            <div class="px-6 py-4 bg-slate-50/70 border-t border-slate-100">
                {{ $reviews->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
