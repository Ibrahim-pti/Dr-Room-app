@extends('pharmacy.layouts.app')
@section('header_title', 'دەستکاریکردنی دەرمان')

@section('content')
<div class="fade-up max-w-4xl">
    <div class="mb-6">
        <h2 class="text-xl font-bold text-slate-800">دەستکاریکردنی دەرمان</h2>
        <p class="text-sm text-slate-500 mt-1">گۆڕانکاری لە زانیارییەکانی {{ $medication->name }} بکە.</p>
    </div>

    @if ($errors->any())
        <div class="mb-6 p-4 bg-red-50 border border-red-200 text-red-700 rounded-xl font-medium">
            <ul class="list-disc list-inside space-y-1">
                @foreach ($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    <div class="bg-white rounded-2xl shadow-sm border border-slate-200/60 p-6 md:p-8">
        <form action="{{ route('pharmacy.medications.update', $medication->id) }}" method="POST" enctype="multipart/form-data">
            @csrf
            @method('PUT')
            
            <div class="flex flex-wrap justify-between items-center gap-4 mb-6 pb-4 border-b border-slate-100">
                <h3 class="text-base font-bold text-slate-800">زانیارییە سەرەکییەکان</h3>
                <button type="button" onclick="translateAll()" id="translateBtn" class="flex items-center gap-2 px-4 py-2 bg-emerald-50 text-emerald-700 border border-emerald-200 rounded-xl hover:bg-emerald-100 transition-colors text-sm font-bold shadow-sm">
                    <svg class="w-4 h-4 text-emerald-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5h12M9 3v2m1.048 9.5A18.022 18.022 0 016.412 9m6.088 9h7M11 21l5-10 5 10M12.751 5C11.783 10.77 8.07 15.61 3 18.129"/></svg>
                    <span>وەرگێڕانی ئۆتۆماتیکی (Translate All)</span>
                </button>
            </div>

            <!-- Name (Kurdish, Arabic, English) -->
            <div class="space-y-4 mb-6">
                <h4 class="text-xs font-bold text-slate-700">ناوی دەرمان بە سێ زمان</h4>
                <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div>
                        <label for="name" class="block text-xs font-bold text-slate-600 mb-1.5">ناوی دەرمان (کوردی) <span class="text-red-500">*</span></label>
                        <input type="text" id="name" name="name" value="{{ old('name', $medication->name) }}" required
                            class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 text-sm font-medium text-slate-700">
                    </div>
                    <div>
                        <label for="name_ar" class="block text-xs font-bold text-slate-600 mb-1.5">ناوی دەرمان (عەرەبی)</label>
                        <input type="text" id="name_ar" name="name_ar" value="{{ old('name_ar', $medication->name_ar) }}" dir="rtl"
                            class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 text-sm font-medium text-slate-700">
                    </div>
                    <div>
                        <label for="name_en" class="block text-xs font-bold text-slate-600 mb-1.5">ناوی دەرمان (ئینگلیزی)</label>
                        <input type="text" id="name_en" name="name_en" value="{{ old('name_en', $medication->name_en) }}" dir="ltr"
                            class="w-full text-left px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 text-sm font-medium text-slate-700">
                    </div>
                </div>
            </div>

            <!-- Category, Dosage Form, Price & Stock -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6 pt-4 border-t border-slate-100">
                <!-- Category -->
                <div>
                    <label for="category" class="block text-xs font-bold text-slate-600 mb-1.5">پۆلێن (کەتەگۆری)</label>
                    <input type="text" id="category" name="category" list="category_list" value="{{ old('category', $medication->category) }}" placeholder="ناوی کەتەگۆری بنووسە یان هەڵیبژێرە..."
                        class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 text-sm font-medium text-slate-700">
                    <datalist id="category_list">
                        @if(isset($existingCategories))
                            @foreach($existingCategories as $catName)
                                <option value="{{ $catName }}">
                            @endforeach
                        @endif
                    </datalist>
                </div>

                <!-- Dosage Form -->
                <div>
                    <label for="dosage_form" class="block text-xs font-bold text-slate-600 mb-1.5">یەکە / شێواز</label>
                    <input type="text" id="dosage_form" name="dosage_form" value="{{ old('dosage_form', $medication->dosage_form ?? 'پاکەت') }}"
                        class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 text-sm font-medium text-slate-700">
                </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6 pt-4 border-t border-slate-100">
                <!-- Price -->
                <div>
                    <label for="price" class="block text-xs font-bold text-slate-600 mb-1.5">نرخی فرۆشتن (دینار) <span class="text-red-500">*</span></label>
                    <input type="number" id="price" name="price" value="{{ old('price', (int)$medication->price) }}" required min="0" dir="ltr"
                        class="w-full text-right px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 text-sm font-medium text-slate-700">
                </div>

                <!-- Discount Percent -->
                <div>
                    <label for="discount_percent" class="block text-xs font-bold text-slate-600 mb-1.5">ڕێژەی داشکاندن (٪)</label>
                    <input type="number" id="discount_percent" name="discount_percent" value="{{ old('discount_percent', $medication->discount_percent) }}" min="0" max="100" placeholder="20" dir="ltr"
                        class="w-full text-right px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 text-sm font-medium text-slate-700">
                </div>

                <!-- Stock -->
                <div>
                    <label for="stock" class="block text-xs font-bold text-slate-600 mb-1.5">بڕی بەردەست (دانە) <span class="text-red-500">*</span></label>
                    <input type="number" id="stock" name="stock" value="{{ old('stock', $medication->stock) }}" required min="0" dir="ltr"
                        class="w-full text-right px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 text-sm font-medium text-slate-700">
                </div>
            </div>

            <!-- Image -->
            <div class="mb-6 pt-4 border-t border-slate-100">
                <label class="block text-xs font-bold text-slate-600 mb-1.5">وێنەی دەرمان</label>
                @if($medication->image_path)
                    <div class="mb-3">
                        <img src="{{ str_starts_with($medication->image_path, 'http') ? $medication->image_path : asset('storage/' . $medication->image_path) }}" alt="{{ $medication->name }}" class="w-20 h-20 object-cover rounded-xl border border-slate-200 shadow-sm">
                    </div>
                @endif
                <input type="file" name="image" accept="image/*" class="w-full text-sm text-slate-500 file:mr-4 file:py-2 file:px-4 file:rounded-xl file:border-0 file:text-xs file:font-bold file:bg-emerald-50 file:text-emerald-700 hover:file:bg-emerald-100 cursor-pointer">
            </div>

            <!-- Description (Kurdish, Arabic, English) -->
            <div class="space-y-4 mb-6 pt-4 border-t border-slate-100">
                <h4 class="text-xs font-bold text-slate-700">وەسف و شێوازی بەکارهێنان</h4>
                <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div>
                        <label for="description" class="block text-xs font-bold text-slate-600 mb-1.5">وەسف (کوردی)</label>
                        <textarea id="description" name="description" rows="3" placeholder="وەسفێکی کورت لەسەر سوودەکانی ئەم دەرمانە بنووسە..."
                            class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 text-sm font-medium text-slate-700 resize-y">{{ old('description', $medication->description) }}</textarea>
                    </div>
                    <div>
                        <label for="description_ar" class="block text-xs font-bold text-slate-600 mb-1.5">وەسف (عەرەبی)</label>
                        <textarea id="description_ar" name="description_ar" rows="3" dir="rtl" placeholder="وصف موجز عن استخدامات الدواء..."
                            class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 text-sm font-medium text-slate-700 resize-y">{{ old('description_ar', $medication->description_ar) }}</textarea>
                    </div>
                    <div>
                        <label for="description_en" class="block text-xs font-bold text-slate-600 mb-1.5">وەسف (ئینگلیزی)</label>
                        <textarea id="description_en" name="description_en" rows="3" dir="ltr" placeholder="Short description and dosage instructions..."
                            class="w-full text-left px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 text-sm font-medium text-slate-700 resize-y">{{ old('description_en', $medication->description_en) }}</textarea>
                    </div>
                </div>
            </div>

            <!-- Active Toggle -->
            <div class="mb-8 p-4 bg-emerald-50/60 border border-emerald-100 rounded-xl flex items-center gap-3">
                <input type="checkbox" name="is_active" id="is_active" value="1" {{ old('is_active', $medication->is_active) ? 'checked' : '' }} class="w-5 h-5 text-emerald-600 border-slate-300 rounded focus:ring-emerald-500 cursor-pointer">
                <label for="is_active" class="font-bold text-slate-700 text-sm cursor-pointer select-none">دەرمانەکە چالاکە و لە ئەپەکە پیشانبدرێت</label>
            </div>

            <!-- Buttons -->
            <div class="flex justify-end gap-3 pt-4 border-t border-slate-100">
                <a href="{{ route('pharmacy.medications.index') }}" class="px-6 py-2.5 rounded-xl font-bold text-slate-600 bg-slate-100 hover:bg-slate-200 transition-colors text-sm">پاشگەزبوونەوە</a>
                <button type="submit" class="px-8 py-2.5 rounded-xl font-bold text-white bg-emerald-600 hover:bg-emerald-700 transition-colors text-sm shadow-md shadow-emerald-200">تازەکردنەوە</button>
            </div>
        </form>
    </div>
</div>
@endsection

@section('scripts')
<script>
async function translateAll() {
    const btn = document.getElementById('translateBtn');
    const originalText = btn.innerHTML;
    
    try {
        btn.innerHTML = '<svg class="animate-spin h-4 w-4 mr-2" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg> <span>وەرگێڕان دەکرێت...</span>';
        btn.disabled = true;

        const fieldsToTranslate = [
            { source: 'name', ar: 'name_ar', en: 'name_en' },
            { source: 'description', ar: 'description_ar', en: 'description_en' }
        ];

        for (const field of fieldsToTranslate) {
            const sourceEl = document.getElementById(field.source);
            const arEl = document.getElementById(field.ar);
            const enEl = document.getElementById(field.en);

            if (sourceEl && sourceEl.value.trim()) {
                const res = await fetch('/api/translate', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json'
                    },
                    body: JSON.stringify({ text: sourceEl.value })
                });
                
                const data = await res.json();
                
                if (data.success && data.translations) {
                    if (arEl && data.translations.ar) {
                        arEl.value = data.translations.ar;
                        arEl.classList.add('bg-emerald-50');
                        setTimeout(() => arEl.classList.remove('bg-emerald-50'), 1500);
                    }
                    if (enEl && data.translations.en) {
                        enEl.value = data.translations.en;
                        enEl.classList.add('bg-emerald-50');
                        setTimeout(() => enEl.classList.remove('bg-emerald-50'), 1500);
                    }
                }
            }
        }
    } catch (e) {
        console.error(e);
        alert('هەڵەیەک ڕوویدا لە وەرگێڕانەکە: ' + (e.message || e));
    } finally {
        btn.innerHTML = originalText;
        btn.disabled = false;
    }
}
</script>
@endsection
