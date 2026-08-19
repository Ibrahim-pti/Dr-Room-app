@extends('lab.layouts.app')
@section('header_title', 'زیادکردنی پشکنینی نوێ')

@section('content')
<div class="max-w-4xl mx-auto space-y-6">
    <!-- Header -->
    <div class="flex items-center justify-between bg-white p-6 rounded-2xl shadow-sm border border-slate-100">
        <div>
            <h2 class="text-xl font-bold text-slate-800">زیادکردنی پشکنینی نوێ بۆ تاقیگە</h2>
            <p class="text-xs text-slate-500 mt-1">پشکنینی نوێ لەگەڵ نرخ و داشکاندن زیاد بکە تا ڕاستەوخۆ لەناو ئەپڵیکەیشن دەربکەوێت.</p>
        </div>
        <a href="{{ route('lab.tests.index') }}" class="px-5 py-2.5 bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold rounded-xl text-xs transition-colors">
            گەڕانەوە بۆ لیستەکە
        </a>
    </div>

    @if($errors->any())
        <div class="p-4 bg-rose-50 border border-rose-200 text-rose-700 rounded-2xl text-xs font-bold space-y-1">
            @foreach($errors->all() as $error)
                <div>• {{ $error }}</div>
            @endforeach
        </div>
    @endif

    <!-- Form Container -->
    <div class="bg-white p-8 rounded-2xl shadow-sm border border-slate-100">
        <form action="{{ route('lab.tests.store') }}" method="POST" class="space-y-6">
            @csrf

            <!-- Names in 3 languages -->
            <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
                <div>
                    <label class="block text-xs font-bold text-slate-700 mb-2" for="name">
                        ناوی پشکنین (بە کوردی) <span class="text-rose-500">*</span>
                    </label>
                    <input class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 font-bold text-xs text-slate-800 outline-none" 
                           id="name" type="text" name="name" value="{{ old('name') }}" placeholder="نموونە: پشکنینی گشتی خوێن (CBC)" required>
                </div>
                <div>
                    <label class="block text-xs font-bold text-slate-700 mb-2" for="name_ar">
                        ناوی پشکنین (بە عەرەبی)
                    </label>
                    <input class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 font-bold text-xs text-slate-800 outline-none" 
                           id="name_ar" type="text" name="name_ar" value="{{ old('name_ar') }}" dir="rtl" placeholder="نموونە: فحص الدم الشامل (CBC)">
                </div>
                <div>
                    <label class="block text-xs font-bold text-slate-700 mb-2" for="name_en">
                        ناوی پشکنین (بە ئینگلیزی)
                    </label>
                    <input class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 font-bold text-xs text-slate-800 outline-none" 
                           id="name_en" type="text" name="name_en" value="{{ old('name_en') }}" dir="ltr" placeholder="Complete Blood Count (CBC)">
                </div>
            </div>

            <!-- Pricing & Discount -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                <div>
                    <label class="block text-xs font-bold text-slate-700 mb-2" for="price">
                        نرخی پشکنین بە دینار (IQD) <span class="text-rose-500">*</span>
                    </label>
                    <input class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 font-bold text-xs text-slate-800 outline-none" 
                           id="price" type="number" step="500" name="price" value="{{ old('price') }}" placeholder="10000" required>
                </div>
                <div>
                    <label class="block text-xs font-bold text-slate-700 mb-2" for="discount">
                        داشکاندنی تایبەت (٪)
                    </label>
                    <input class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 font-bold text-xs text-slate-800 outline-none" 
                           id="discount" type="number" min="0" max="100" name="discount" value="{{ old('discount') }}" placeholder="نموونە: 20">
                </div>
            </div>

            <!-- Description -->
            <div>
                <label class="block text-xs font-bold text-slate-700 mb-2" for="description">
                    ڕوونکردنەوە و وەسفی پشکنین
                </label>
                <textarea class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 text-xs text-slate-800 outline-none" 
                          id="description" name="description" rows="3" placeholder="ڕوونکردنەوە و زانیاری زیاتر دەربارەی پشکنینەکە بۆ نەخۆش بنووسە...">{{ old('description') }}</textarea>
            </div>

            <!-- Active Status -->
            <div class="p-4 bg-slate-50 rounded-xl border border-slate-200/60">
                <label class="flex items-center gap-3 cursor-pointer">
                    <input type="checkbox" name="is_active" value="1" class="w-4 h-4 text-blue-600 rounded border-slate-300 focus:ring-blue-500 cursor-pointer" checked>
                    <span class="text-xs text-slate-800 font-bold">ئەم پشکنینە چالاکە و ڕاستەوخۆ لەناو ئەپڵیکەیشن بۆ نەخۆش بەردەست دەبێت</span>
                </label>
            </div>

            <!-- Actions -->
            <div class="flex items-center justify-end gap-3 pt-4 border-t border-slate-100">
                <a href="{{ route('lab.tests.index') }}" class="px-6 py-2.5 bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold rounded-xl text-xs transition-colors">
                    پاشگەزبوونەوە
                </a>
                <button class="px-8 py-2.5 bg-blue-600 hover:bg-blue-700 text-white font-bold rounded-xl text-xs shadow-md shadow-blue-200 transition-colors flex items-center gap-2" type="submit">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
                    پاشەکەوتکردنی پشکنین
                </button>
            </div>
        </form>
    </div>
</div>
@endsection
