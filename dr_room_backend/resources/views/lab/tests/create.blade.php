@extends('lab.layouts.app')

@section('content')
<div class="container mx-auto px-4 py-6">
    <div class="flex justify-between items-center mb-6">
        <h1 class="text-2xl font-bold text-gray-800">زیادکردنی پشکنین</h1>
        <a href="{{ route('lab.tests.index') }}" class="bg-gray-500 hover:bg-gray-600 text-white font-bold py-2 px-4 rounded-xl transition-colors">
            گەڕانەوە
        </a>
    </div>

    @if($errors->any())
        <div class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-xl mb-4">
            <ul>
                @foreach($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    <div class="bg-white shadow-sm border border-slate-200/60 rounded-2xl p-6">
        <form action="{{ route('lab.tests.store') }}" method="POST">
            @csrf
            
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
                <div>
                    <label class="block text-gray-700 text-sm font-bold mb-2" for="name">
                        ناوی پشکنین (کوردی) <span class="text-red-500">*</span>
                    </label>
                    <input class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 font-medium text-slate-700" id="name" type="text" name="name" value="{{ old('name') }}" placeholder="نموونە: پشکنینی گشتی خوێن (CBC)" required>
                </div>
                <div>
                    <label class="block text-gray-700 text-sm font-bold mb-2" for="name_ar">
                        ناوی پشکنین (عەرەبی)
                    </label>
                    <input class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 font-medium text-slate-700" id="name_ar" type="text" name="name_ar" value="{{ old('name_ar') }}" dir="rtl" placeholder="فحص الدم الشامل (CBC)">
                </div>
                <div>
                    <label class="block text-gray-700 text-sm font-bold mb-2" for="name_en">
                        ناوی پشکنین (ئینگلیزی)
                    </label>
                    <input class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 font-medium text-slate-700" id="name_en" type="text" name="name_en" value="{{ old('name_en') }}" dir="ltr" placeholder="Complete Blood Count (CBC)">
                </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
                <div>
                    <label class="block text-gray-700 text-sm font-bold mb-2" for="type">
                        جۆری پشکنین <span class="text-red-500">*</span>
                    </label>
                    <select class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 font-medium text-slate-700" id="type" name="type" required>
                        <option value="blood" {{ old('type') == 'blood' ? 'selected' : '' }}>خوێن (Blood)</option>
                        <option value="urine" {{ old('type') == 'urine' ? 'selected' : '' }}>میز (Urine)</option>
                        <option value="hormone" {{ old('type') == 'hormone' ? 'selected' : '' }}>هۆرمۆن (Hormone)</option>
                        <option value="other" {{ old('type') == 'other' ? 'selected' : '' }}>تر (Other)</option>
                    </select>
                </div>
                <div>
                    <label class="block text-gray-700 text-sm font-bold mb-2" for="price">
                        نرخ بە دینار (IQD) <span class="text-red-500">*</span>
                    </label>
                    <input class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 font-medium text-slate-700" id="price" type="number" step="500" name="price" value="{{ old('price') }}" placeholder="10000" required>
                </div>
                <div>
                    <label class="block text-gray-700 text-sm font-bold mb-2" for="discount">
                        داشکاندن (%)
                    </label>
                    <input class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 font-medium text-slate-700" id="discount" type="number" min="0" max="100" name="discount" value="{{ old('discount') }}" placeholder="نموونە: 20">
                </div>
            </div>

            <div class="mb-4">
                <label class="block text-gray-700 text-sm font-bold mb-2" for="description">
                    زانیاری زیاتر / وەسفی پشکنین
                </label>
                <textarea class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 font-medium text-slate-700" id="description" name="description" rows="3" placeholder="ڕوونکردنەوە دەربارەی پشکنینەکە...">{{ old('description') }}</textarea>
            </div>

            <div class="mb-6">
                <label class="flex items-center gap-2 cursor-pointer">
                    <input type="checkbox" name="is_active" value="1" class="w-5 h-5 text-blue-600 rounded" checked>
                    <span class="text-gray-700 font-bold">ئەم پشکنینە چالاکە و لە ئەپەکە دەردەکەوێت</span>
                </label>
            </div>

            <div class="flex items-center justify-end">
                <button class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2.5 px-6 rounded-xl shadow-md transition-colors" type="submit">
                    پاشەکەوتکردنی پشکنین
                </button>
            </div>
        </form>
    </div>
</div>
@endsection
