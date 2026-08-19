@extends('lab.layouts.app')
@section('header_title', 'ئەنجامەکانی پشکنین')

@section('content')
<div class="space-y-6">
    <!-- Header -->
    <div class="bg-white p-6 rounded-2xl shadow-sm border border-slate-100 flex flex-col sm:flex-row items-center justify-between gap-4">
        <div>
            <h2 class="text-xl font-bold text-slate-800">لیستی ئەنجامە نێردراوەکانی تاقیگە</h2>
            <p class="text-xs text-slate-500 mt-1">سەرجەم ئەو ئەنجام و ڕاپۆرتە فەرمییانەی بۆ نەخۆشەکان نێردراون لە ڕێگەی ئەپڵیکەیشنەوە.</p>
        </div>
        <a href="{{ route('lab.results.create') }}" class="px-5 py-2.5 bg-blue-600 hover:bg-blue-700 text-white font-bold rounded-xl text-xs shadow-md shadow-blue-200 transition-all flex items-center gap-2">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
            تۆمارکردنی ئەنجامی نوێ
        </a>
    </div>

    @if(session('success'))
        <div class="p-4 bg-emerald-50 border border-emerald-200 text-emerald-700 rounded-2xl text-xs font-bold flex items-center gap-3">
            <svg class="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
            <span>{{ session('success') }}</span>
        </div>
    @endif

    <!-- Results Table -->
    <div class="bg-white rounded-2xl shadow-sm border border-slate-100 overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-right text-sm">
                <thead class="bg-slate-50 border-b border-slate-100 text-slate-500 font-bold text-xs">
                    <tr>
                        <th class="px-6 py-4">نەخۆش</th>
                        <th class="px-6 py-4">پشکنین</th>
                        <th class="px-6 py-4">بڕی ئەنجام</th>
                        <th class="px-6 py-4">ڕاپۆرت / فایل</th>
                        <th class="px-6 py-4">حاڵەت</th>
                        <th class="px-6 py-4">بەروار</th>
                        <th class="px-6 py-4 text-center">کردارەکان</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-100">
                    @forelse($results as $result)
                        <tr class="hover:bg-slate-50/70 transition-colors">
                            <!-- Patient -->
                            <td class="px-6 py-4">
                                <div class="font-bold text-slate-800 text-sm">{{ $result->patient->name ?? 'نەخۆش' }}</div>
                                <div class="text-xs text-slate-400 mt-0.5" dir="ltr">{{ $result->patient->phone ?? '' }}</div>
                            </td>

                            <!-- Test Name -->
                            <td class="px-6 py-4">
                                <span class="font-bold text-slate-700">{{ $result->test->name ?? 'پشکنینی گشتی' }}</span>
                            </td>

                            <!-- Value -->
                            <td class="px-6 py-4">
                                <span class="font-semibold text-slate-700">{{ $result->result_value ?? 'تەواوکراو' }}</span>
                            </td>

                            <!-- File Link -->
                            <td class="px-6 py-4">
                                @if($result->file_path)
                                    <a href="{{ Storage::url($result->file_path) }}" target="_blank" class="inline-flex items-center gap-1 px-3 py-1 bg-blue-50 text-blue-600 rounded-lg text-xs font-bold hover:bg-blue-600 hover:text-white transition-colors">
                                        📄 بینینی ڕاپۆرت
                                    </a>
                                @else
                                    <span class="text-xs text-slate-400">فایل نییە</span>
                                @endif
                            </td>

                            <!-- Status -->
                            <td class="px-6 py-4">
                                @if($result->status == 'completed')
                                    <span class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                                        <span class="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                                        تەواوبووە
                                    </span>
                                @else
                                    <span class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-bold bg-amber-50 text-amber-700 border border-amber-200">
                                        <span class="w-1.5 h-1.5 rounded-full bg-amber-500"></span>
                                        چاوەڕوانە
                                    </span>
                                @endif
                            </td>

                            <!-- Date -->
                            <td class="px-6 py-4 text-xs text-slate-500" dir="ltr">
                                {{ $result->created_at->format('Y/m/d H:i') }}
                            </td>

                            <!-- Actions -->
                            <td class="px-6 py-4 text-center">
                                <div class="flex items-center justify-center gap-2">
                                    <a href="{{ route('lab.results.edit', $result) }}" class="px-3 py-1.5 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-xl text-xs font-bold transition-colors">
                                        دەستکاری
                                    </a>
                                    <form action="{{ route('lab.results.destroy', $result) }}" method="POST" class="inline-block" onsubmit="return confirm('ئایا دڵنیایت لە سڕینەوەی ئەم ئەنجامە؟');">
                                        @csrf
                                        @method('DELETE')
                                        <button type="submit" class="px-3 py-1.5 bg-rose-50 hover:bg-rose-600 text-rose-600 hover:text-white rounded-xl text-xs font-bold transition-colors">
                                            سڕینەوە
                                        </button>
                                    </form>
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="7" class="px-6 py-12 text-center text-slate-400 text-sm font-bold">
                                هیچ ئەنجامێک تۆمار نەکراوە.
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if(method_exists($results, 'hasPages') && $results->hasPages())
            <div class="px-6 py-4 bg-slate-50 border-t border-slate-100">
                {{ $results->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
