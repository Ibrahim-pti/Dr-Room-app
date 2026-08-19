@extends('lab.layouts.app')
@section('header_title', 'دروستکردنی پاکێجی نوێ')

@section('content')
<div class="max-w-4xl mx-auto space-y-6">
    <!-- Header -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-6 rounded-2xl shadow-sm border border-slate-100">
        <div>
            <h2 class="text-xl font-bold text-slate-800">دروستکردنی پاکێج و ئۆفەری نوێ</h2>
            <p class="text-xs text-slate-500 mt-1">چەند پشکنینێک بە یەکەوە ببەستەرەوە و نرخێکی تایبەت و داشکاو بۆ نەخۆش دابنێ.</p>
        </div>
        <div class="flex items-center gap-3">
            <button type="button" onclick="translateAll()" id="translateBtn" class="flex items-center gap-2 px-4 py-2.5 bg-purple-50 text-purple-600 hover:bg-purple-100 rounded-xl transition-all text-xs font-bold shadow-sm cursor-pointer whitespace-nowrap">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5h12M9 3v2m1.048 9.5A18.022 18.022 0 016.412 9m6.088 9h7M11 21l5-10 5 10M12.751 5C11.783 10.77 8.07 15.61 3 18.129"/></svg>
                <span>وەرگێڕانی ئۆتۆماتیکی</span>
            </button>
            <a href="{{ route('lab.packages.index') }}" class="px-4 py-2.5 bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold rounded-xl text-xs transition-colors whitespace-nowrap">
                گەڕانەوە
            </a>
        </div>
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
        <form action="{{ route('lab.packages.store') }}" method="POST" class="space-y-6">
            @csrf

            <!-- Names in 3 languages -->
            <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
                <div>
                    <label class="block text-xs font-bold text-slate-700 mb-2" for="name">
                        ناوی پاکێج (بە کوردی) <span class="text-rose-500">*</span>
                    </label>
                    <input class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-purple-500/20 focus:border-purple-500 font-bold text-xs text-slate-800 outline-none" 
                           id="name" type="text" name="name" value="{{ old('name') }}" placeholder="نموونە: پاکێجی پشکنینی تەواوی جەستە" required>
                </div>
                <div>
                    <label class="block text-xs font-bold text-slate-700 mb-2" for="name_ar">
                        ناوی پاکێج (بە عەرەبی)
                    </label>
                    <input class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-purple-500/20 focus:border-purple-500 font-bold text-xs text-slate-800 outline-none" 
                           id="name_ar" type="text" name="name_ar" value="{{ old('name_ar') }}" dir="rtl" placeholder="باقة الفحص الشامل للجسم">
                </div>
                <div>
                    <label class="block text-xs font-bold text-slate-700 mb-2" for="name_en">
                        ناوی پاکێج (بە ئینگلیزی)
                    </label>
                    <input class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-purple-500/20 focus:border-purple-500 font-bold text-xs text-slate-800 outline-none" 
                           id="name_en" type="text" name="name_en" value="{{ old('name_en') }}" dir="ltr" placeholder="Full Body Checkup Package">
                </div>
            </div>

            <!-- Tests Checklist -->
            <div>
                <label class="block text-xs font-bold text-slate-700 mb-2">
                    پشکنینە هاوپێچەکان لەناو ئەم پاکێجەدا (Select Included Tests)
                </label>
                <div class="p-4 bg-slate-50 border border-slate-200/70 rounded-2xl max-h-64 overflow-y-auto space-y-2">
                    @forelse($tests as $test)
                        <label class="flex items-center justify-between p-2.5 bg-white rounded-xl border border-slate-100 hover:border-purple-200 cursor-pointer transition-all">
                            <div class="flex items-center gap-3">
                                <input type="checkbox" name="test_ids[]" value="{{ $test->id }}" 
                                       data-price="{{ $test->price }}"
                                       onchange="recalculatePrices()"
                                       class="test-checkbox w-4 h-4 text-purple-600 rounded border-slate-300 focus:ring-purple-500 cursor-pointer">
                                <div>
                                    <div class="text-xs font-bold text-slate-800">{{ $test->name }}</div>
                                    @if($test->name_en)
                                        <div class="text-[11px] text-slate-400" dir="ltr">{{ $test->name_en }}</div>
                                    @endif
                                </div>
                            </div>
                            <div class="text-xs font-bold text-slate-600" dir="ltr">
                                {{ number_format($test->price) }} د.ع
                            </div>
                        </label>
                    @empty
                        <div class="p-4 text-center text-xs text-slate-400">
                            هیچ پشکنینێک تۆمار نەکراوە. سەرەتا لە بەشی پشکنینەکان پشکنین زیاد بکە.
                        </div>
                    @endforelse
                </div>
            </div>

            <!-- Pricing Section -->
            <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
                <div>
                    <label class="block text-xs font-bold text-slate-700 mb-2" for="original_price">
                        کۆی نرخی ئەسڵی (Original Total)
                    </label>
                    <input class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-purple-500/20 focus:border-purple-500 font-bold text-xs text-slate-800 outline-none" 
                           id="original_price" type="text" inputmode="numeric" name="original_price" value="{{ old('original_price') }}" placeholder="نموونە: 60,000" oninput="formatPriceInput(this); updateDiscountPercent();">
                </div>
                <div>
                    <label class="block text-xs font-bold text-slate-700 mb-2" for="price">
                        نرخی ئۆفەری پاکێج (Offer Price) <span class="text-rose-500">*</span>
                    </label>
                    <input class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-purple-500/20 focus:border-purple-500 font-bold text-xs text-slate-800 outline-none" 
                           id="price" type="text" inputmode="numeric" name="price" value="{{ old('price') }}" placeholder="نموونە: 42,000" oninput="formatPriceInput(this); updateDiscountPercent();" required>
                </div>
                <div>
                    <label class="block text-xs font-bold text-slate-700 mb-2" for="discount_display">
                        داشکاندن (خۆکارانە دەژمێردرێت)
                    </label>
                    <input class="w-full px-4 py-2.5 bg-purple-50/60 border border-purple-200 text-purple-700 rounded-xl font-black text-xs outline-none cursor-not-allowed" 
                           id="discount_display" type="text" value="0% ئۆفەر" readonly>
                </div>
            </div>

            <!-- Description -->
            <div class="space-y-4 pt-2">
                <div>
                    <label class="block text-xs font-bold text-slate-700 mb-2" for="description">
                        ڕوونکردنەوە و تایبەتمەندییەکانی پاکێج
                    </label>
                    <textarea class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-purple-500/20 focus:border-purple-500 text-xs text-slate-800 outline-none" 
                              id="description" name="description" rows="3" placeholder="تایبەتمەندییەکانی ئەم پاکێجە و ڕێنمایی بۆ نەخۆش بنووسە...">{{ old('description') }}</textarea>
                </div>

                <!-- Auto-translated hidden descriptions -->
                <input type="hidden" id="description_ar" name="description_ar" value="{{ old('description_ar') }}">
                <input type="hidden" id="description_en" name="description_en" value="{{ old('description_en') }}">
            </div>

            <!-- Active Status -->
            <div class="p-4 bg-slate-50 rounded-xl border border-slate-200/60">
                <label class="flex items-center gap-3 cursor-pointer">
                    <input type="checkbox" name="is_active" value="1" class="w-4 h-4 text-purple-600 rounded border-slate-300 focus:ring-purple-500 cursor-pointer" checked>
                    <span class="text-xs text-slate-800 font-bold">ئەم پاکێجە چالاکە و لە تابی «ئۆفەر و پاکێج» لە ئەپڵیکەیشن بەردەست دەبێت</span>
                </label>
            </div>

            <!-- Actions -->
            <div class="flex items-center justify-end gap-3 pt-4 border-t border-slate-100">
                <a href="{{ route('lab.packages.index') }}" class="px-6 py-2.5 bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold rounded-xl text-xs transition-colors">
                    پاشگەزبوونەوە
                </a>
                <button class="px-8 py-2.5 bg-purple-600 hover:bg-purple-700 text-white font-bold rounded-xl text-xs shadow-md shadow-purple-200 transition-colors flex items-center gap-2" type="submit">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
                    پاشەکەوتکردنی پاکێج
                </button>
            </div>
        </form>
    </div>
</div>

<script>
async function translateAll() {
    const btn = document.getElementById('translateBtn');
    const nameEl = document.getElementById('name');
    const nameArEl = document.getElementById('name_ar');
    const nameEnEl = document.getElementById('name_en');
    const descEl = document.getElementById('description');
    const descArEl = document.getElementById('description_ar');
    const descEnEl = document.getElementById('description_en');

    if (!nameEl || !nameEl.value.trim()) {
        alert('تکایە سەرەتا ناوی پاکێج بە کوردی بنووسە!');
        nameEl.focus();
        return;
    }

    const originalText = btn.innerHTML;
    try {
        btn.innerHTML = '<svg class="animate-spin h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg> <span>وەرگێڕان...</span>';
        btn.disabled = true;

        // 1. Translate Name
        const resName = await fetch('/api/translate', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'X-CSRF-TOKEN': '{{ csrf_token() }}'
            },
            body: JSON.stringify({ text: nameEl.value.trim() })
        });
        const dataName = await resName.json();
        if (dataName.success && dataName.translations) {
            if (nameArEl) nameArEl.value = dataName.translations.ar || '';
            if (nameEnEl) nameEnEl.value = dataName.translations.en || '';
        }

        // 2. Translate Description if present
        if (descEl && descEl.value.trim()) {
            const resDesc = await fetch('/api/translate', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'X-CSRF-TOKEN': '{{ csrf_token() }}'
                },
                body: JSON.stringify({ text: descEl.value.trim() })
            });
            const dataDesc = await resDesc.json();
            if (dataDesc.success && dataDesc.translations) {
                if (descArEl) descArEl.value = dataDesc.translations.ar || '';
                if (descEnEl) descEnEl.value = dataDesc.translations.en || '';
            }
        }
    } catch (e) {
        console.error(e);
        alert('هەڵەیەک ڕوویدا لە کاتی وەرگێڕاندا.');
    } finally {
        btn.innerHTML = originalText;
        btn.disabled = false;
    }
}

function formatPriceInput(input) {
    let raw = input.value.replace(/,/g, '').replace(/[^0-9]/g, '');
    if (raw) {
        input.value = Number(raw).toLocaleString('en-US');
    } else {
        input.value = '';
    }
}

function recalculatePrices() {
    const checkboxes = document.querySelectorAll('.test-checkbox:checked');
    let total = 0;
    checkboxes.forEach(cb => {
        const price = parseFloat(cb.dataset.price) || 0;
        total += price;
    });

    const origInput = document.getElementById('original_price');
    if (total > 0) {
        origInput.value = Number(total).toLocaleString('en-US');
    }
    updateDiscountPercent();
}

function updateDiscountPercent() {
    const origRaw = parseFloat((document.getElementById('original_price').value || '').replace(/,/g, '')) || 0;
    const priceRaw = parseFloat((document.getElementById('price').value || '').replace(/,/g, '')) || 0;
    const display = document.getElementById('discount_display');

    if (origRaw > 0 && priceRaw > 0 && origRaw > priceRaw) {
        const diff = origRaw - priceRaw;
        const pct = Math.round((diff / origRaw) * 100);
        display.value = `${pct}% ئۆفەر (داشکاندن)`;
    } else {
        display.value = '0% ئۆفەر';
    }
}
</script>
@endsection
