@extends('doctor.layouts.app')
@section('header_title', 'هەڵسەنگاندن و بۆچوونەکان')

@section('content')
<div class="mb-6">
    <h2 class="text-xl font-bold text-slate-800">هەڵسەنگاندن و بۆچوونەکان</h2>
    <p class="text-sm text-slate-500 mt-1">ئەوەی نەخۆشەکانت دەربارەی خزمەتگوزارییەکەت نووسیویانە.</p>
</div>

@php
    $total = $doctor?->total_reviews ?? 0;
    $average = (float) ($doctor?->rating ?? 0);
@endphp

<!-- Summary -->
<div class="bg-white rounded-2xl shadow-sm border border-slate-200/60 p-6 mb-6">
    <div class="grid grid-cols-1 md:grid-cols-3 gap-8 items-center">
        <div class="text-center md:border-l md:border-slate-200">
            <p class="text-5xl font-extrabold text-slate-800">{{ number_format($average, 1) }}</p>
            <div class="flex justify-center gap-0.5 mt-2">
                @for($i = 1; $i <= 5; $i++)
                    <svg class="w-5 h-5 {{ $i <= round($average) ? 'text-amber-400' : 'text-slate-200' }}" fill="currentColor" viewBox="0 0 20 20">
                        <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.286 3.958a1 1 0 00.95.69h4.162c.969 0 1.371 1.24.588 1.81l-3.367 2.446a1 1 0 00-.363 1.118l1.286 3.958c.3.921-.755 1.688-1.539 1.118l-3.366-2.446a1 1 0 00-1.176 0l-3.367 2.446c-.783.57-1.838-.197-1.539-1.118l1.287-3.958a1 1 0 00-.364-1.118L2.063 9.385c-.783-.57-.38-1.81.588-1.81h4.162a1 1 0 00.951-.69l1.285-3.958z"/>
                    </svg>
                @endfor
            </div>
            <p class="text-sm text-slate-500 mt-2">لەسەر بنەمای {{ $total }} بۆچوون</p>
        </div>

        <div class="md:col-span-2 space-y-2">
            @foreach($breakdown as $star => $count)
                @php $percent = $total > 0 ? ($count / $total) * 100 : 0; @endphp
                <div class="flex items-center gap-3">
                    <span class="text-sm font-medium text-slate-600 w-8 text-left" dir="ltr">{{ $star }} ★</span>
                    <div class="flex-1 h-2 bg-slate-100 rounded-full overflow-hidden">
                        <div class="h-full bg-amber-400 rounded-full" style="width: {{ $percent }}%"></div>
                    </div>
                    <span class="text-sm text-slate-400 w-8">{{ $count }}</span>
                </div>
            @endforeach
        </div>
    </div>
</div>

<!-- Review list -->
<div class="bg-white rounded-2xl shadow-sm border border-slate-200/60 overflow-hidden">
    @forelse($reviews as $review)
        <div class="p-5 {{ !$loop->last ? 'border-b border-slate-100' : '' }}">
            <div class="flex items-start justify-between gap-4">
                <div class="flex items-start gap-3">
                    <div class="w-10 h-10 rounded-full bg-blue-50 text-blue-600 flex items-center justify-center font-bold shrink-0">
                        {{ mb_substr($review->patient?->name ?? '؟', 0, 1) }}
                    </div>
                    <div>
                        <p class="font-semibold text-slate-800">{{ $review->patient?->name ?? 'نەخۆشێک' }}</p>
                        <div class="flex gap-0.5 mt-1">
                            @for($i = 1; $i <= 5; $i++)
                                <svg class="w-4 h-4 {{ $i <= $review->rating ? 'text-amber-400' : 'text-slate-200' }}" fill="currentColor" viewBox="0 0 20 20">
                                    <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.286 3.958a1 1 0 00.95.69h4.162c.969 0 1.371 1.24.588 1.81l-3.367 2.446a1 1 0 00-.363 1.118l1.286 3.958c.3.921-.755 1.688-1.539 1.118l-3.366-2.446a1 1 0 00-1.176 0l-3.367 2.446c-.783.57-1.838-.197-1.539-1.118l1.287-3.958a1 1 0 00-.364-1.118L2.063 9.385c-.783-.57-.38-1.81.588-1.81h4.162a1 1 0 00.951-.69l1.285-3.958z"/>
                                </svg>
                            @endfor
                        </div>
                    </div>
                </div>
                <span class="text-xs text-slate-400 shrink-0">{{ $review->created_at?->diffForHumans() }}</span>
            </div>

            @if($review->comment)
                <p class="text-sm text-slate-600 leading-relaxed mt-3">{{ $review->comment }}</p>
            @endif
        </div>
    @empty
        <div class="p-12 text-center">
            <svg class="w-12 h-12 mx-auto text-slate-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.86 9.86 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"/>
            </svg>
            <p class="text-slate-500 font-medium mt-4">هێشتا هیچ بۆچوونێکت نییە</p>
            <p class="text-sm text-slate-400 mt-1">دوای ئەوەی نەخۆشەکان سەردانت دەکەن، بۆچوونەکانیان لێرە دەردەکەون.</p>
        </div>
    @endforelse
</div>

@if($reviews->hasPages())
    <div class="mt-6">{{ $reviews->links() }}</div>
@endif
@endsection
