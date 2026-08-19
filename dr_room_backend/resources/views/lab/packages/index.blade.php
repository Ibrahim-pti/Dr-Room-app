@extends('lab.layouts.app')
@section('header_title', 'پاکێج و ئۆفەرەکان')

@section('content')
<div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white p-6 rounded-3xl shadow-sm border border-slate-100">
        <div>
            <div class="flex items-center gap-3">
                <h2 class="text-xl font-bold text-slate-800">لیستی پاکێج و ئۆفەرەکانی تاقیگە</h2>
                <span class="px-3 py-1 bg-purple-50 text-purple-600 rounded-full text-xs font-bold border border-purple-100">
                    کۆی گشتی: {{ $packages->total() }} پاکێج
                </span>
            </div>
            <p class="text-sm text-slate-500 mt-1">پاکێجی چەند پشکنینێک بە یەکەوە بە نرخی داشکاو و تایبەت دروست بکە بۆ ئەپڵیکەیشن.</p>
        </div>
        <div>
            <a href="{{ route('lab.packages.create') }}" class="inline-flex items-center gap-2 px-6 py-2.5 bg-purple-600 hover:bg-purple-700 text-white font-bold rounded-2xl shadow-md shadow-purple-200 transition-all text-xs whitespace-nowrap">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
                دروستکردنی پاکێجی نوێ
            </a>
        </div>
    </div>

    @if(session('success'))
        <div class="p-4 bg-emerald-50 border border-emerald-200 text-emerald-700 rounded-2xl font-bold flex items-center gap-3">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
            {{ session('success') }}
        </div>
    @endif

    <!-- Packages Table -->
    <div class="bg-white rounded-3xl shadow-sm border border-slate-100 overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-right text-sm">
                <thead class="bg-slate-50 border-b border-slate-100 text-slate-500 font-bold">
                    <tr>
                        <th class="px-6 py-4">ناوی پاکێج</th>
                        <th class="px-6 py-4">پشکنینە هاوپێچەکان</th>
                        <th class="px-6 py-4">نرخی پێشوو</th>
                        <th class="px-6 py-4">نرخی ئۆفەر (IQD)</th>
                        <th class="px-6 py-4">داشکاندن</th>
                        <th class="px-6 py-4">حاڵەت</th>
                        <th class="px-6 py-4 text-center">کردارەکان</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                    @forelse($packages as $package)
                        <tr class="hover:bg-slate-50/60 transition-colors">
                            <!-- Name -->
                            <td class="px-6 py-4">
                                <div class="font-bold text-slate-800 text-base">{{ $package->name }}</div>
                                @if($package->name_en || $package->name_ar)
                                    <div class="text-xs text-slate-400 mt-0.5" dir="ltr">
                                        {{ $package->name_en ?? $package->name_ar }}
                                    </div>
                                @endif
                                @if($package->description)
                                    <div class="text-xs text-slate-500 mt-1 max-w-xs line-clamp-1" title="{{ $package->description }}">
                                        {{ $package->description }}
                                    </div>
                                @endif
                            </td>

                            <!-- Tests Included -->
                            <td class="px-6 py-4">
                                @php $tests = $package->tests; @endphp
                                @if($tests->isNotEmpty())
                                    <div class="flex flex-wrap gap-1 max-w-xs">
                                        @foreach($tests->take(3) as $t)
                                            <span class="inline-flex items-center px-2 py-0.5 rounded-lg bg-blue-50 text-blue-700 text-xs font-semibold">
                                                {{ $t->name }}
                                            </span>
                                        @endforeach
                                        @if($tests->count() > 3)
                                            <span class="inline-flex items-center px-2 py-0.5 rounded-lg bg-slate-100 text-slate-600 text-xs font-bold">
                                                +{{ $tests->count() - 3 }} پشکنینی تر
                                            </span>
                                        @endif
                                    </div>
                                @else
                                    <span class="text-xs text-slate-400">گشت پشکنینەکان</span>
                                @endif
                            </td>

                            <!-- Original Price -->
                            <td class="px-6 py-4">
                                @if($package->original_price && $package->original_price > $package->price)
                                    <div class="font-bold text-slate-400 line-through text-xs" dir="ltr">
                                        {{ number_format($package->original_price) }} د.ع
                                    </div>
                                @else
                                    <span class="text-xs text-slate-400">—</span>
                                @endif
                            </td>

                            <!-- Offer Price -->
                            <td class="px-6 py-4">
                                <div class="font-black text-emerald-600 text-base" dir="ltr">
                                    {{ number_format($package->price) }} د.ع
                                </div>
                            </td>

                            <!-- Discount -->
                            <td class="px-6 py-4">
                                @if($package->discount && $package->discount > 0)
                                    <span class="inline-flex items-center px-2.5 py-1 rounded-xl bg-purple-50 text-purple-700 font-black text-xs border border-purple-200">
                                        {{ $package->discount }}% ئۆفەر
                                    </span>
                                @else
                                    <span class="text-xs text-slate-400 font-medium">—</span>
                                @endif
                            </td>

                            <!-- Status -->
                            <td class="px-6 py-4">
                                @if($package->is_active)
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
                                    <a href="{{ route('lab.packages.edit', $package) }}" 
                                       class="px-3.5 py-1.5 bg-blue-50 text-blue-600 hover:bg-blue-600 hover:text-white rounded-xl font-bold text-xs transition-all flex items-center gap-1">
                                        <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/></svg>
                                        دەستکاری
                                    </a>
                                    <form action="{{ route('lab.packages.destroy', $package) }}" method="POST" class="inline-block" onsubmit="return confirm('ئایا دڵنیایت لە سڕینەوەی ئەم پاکێجە؟');">
                                        @csrf
                                        @method('DELETE')
                                        <button type="submit" class="px-3.5 py-1.5 bg-rose-50 text-rose-600 hover:bg-rose-600 hover:text-white rounded-xl font-bold text-xs transition-all flex items-center gap-1">
                                            <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
                                            سڕینەوە
                                        </button>
                                    </form>
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="7" class="px-6 py-16 text-center text-slate-500">
                                <div class="w-16 h-16 bg-purple-50 rounded-full flex items-center justify-center mx-auto mb-3 text-purple-400">
                                    <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z"/></svg>
                                </div>
                                <div class="font-bold text-slate-700 text-base">هیچ پاکێجێک دروست نەکراوە</div>
                                <div class="text-xs text-slate-400 mt-1">کلیك لەسەر دوگمەی "دروستکردنی پاکێجی نوێ" بکە بۆ زیادکردنی ئۆفەری تایبەت.</div>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        <!-- Pagination Footer -->
        <div class="px-6 py-4 bg-slate-50/70 border-t border-slate-100 flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-slate-500">
            <div class="font-medium">
                پیشاندانی <span class="font-bold text-slate-800">{{ $packages->firstItem() ?? 0 }}</span> بۆ <span class="font-bold text-slate-800">{{ $packages->lastItem() ?? 0 }}</span> لە کۆی <span class="font-bold text-purple-600">{{ $packages->total() }}</span> پاکێج
            </div>

            <div>
                {{ $packages->links() }}
            </div>
        </div>
    </div>
</div>
@endsection
