@extends('nurse.layouts.app')
@section('header_title', 'خزمەتگوزارییەکان و نرخەکان')

@section('content')
<div class="mb-6 flex flex-col md:flex-row md:items-center justify-between gap-4">
    <div>
        <h2 class="text-xl font-bold text-slate-800">خزمەتگوزارییەکان و نرخەکان</h2>
        <p class="text-sm text-slate-500 mt-1">ئەو خزمەتگوزارییانەی پێشکەشی نەخۆشی دەکەیت لەگەڵ نرخەکانیان دیاریبکە (دەرزی، کانیۆلا، برینپێچی، هتد).</p>
    </div>

    <div class="flex flex-wrap items-center gap-2.5">
        <button type="button" onclick="handleTranslateServices()" id="translate-services-btn"
            class="inline-flex items-center gap-2 px-4 py-2.5 bg-gradient-to-r from-teal-600 to-emerald-600 hover:from-teal-700 hover:to-emerald-700 text-white rounded-xl font-bold text-xs shadow-md shadow-teal-500/20 transition-all cursor-pointer">
            <svg class="w-4 h-4 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5h12M9 3v2m1.048 9.5A18.022 18.022 0 016.412 9m6.088 9h7M11 21l5-10 5 10M12.751 5C11.783 10.77 8.07 15.61 3 18.129"/></svg>
            <span id="translate-services-btn-text">وەرگێڕانی هەمووی (Translate All)</span>
        </button>

        <button type="button" onclick="addCustomServiceRow()"
            class="inline-flex items-center gap-1.5 px-4 py-2.5 bg-emerald-50 hover:bg-emerald-100 text-emerald-700 rounded-xl text-xs font-bold border border-emerald-200 transition-colors shadow-sm cursor-pointer">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
            + زیادکردنی خزمەتگوزاری
        </button>
    </div>
</div>

@if(session('success'))
    <div class="mb-6 p-4 bg-emerald-50 border border-emerald-200 text-emerald-700 rounded-2xl flex items-center gap-3 shadow-sm">
        <svg class="w-5 h-5 text-emerald-600 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
        <span class="font-medium text-sm">{{ session('success') }}</span>
    </div>
@endif

@if(session('error'))
    <div class="mb-6 p-4 bg-red-50 border border-red-200 text-red-700 rounded-2xl flex items-center gap-3 shadow-sm">
        <span class="font-medium text-sm">{{ session('error') }}</span>
    </div>
@endif

@php
    $customServicesRows = ($nurse && is_array($nurse->custom_services) && count($nurse->custom_services) > 0)
        ? $nurse->custom_services
        : [
            [
                'name' => '',
                'name_kmr' => '',
                'name_en' => '',
                'name_ar' => '',
                'price' => '',
            ]
        ];
@endphp

<form id="services-form" action="{{ route('nurse.services.update') }}" method="POST" class="bg-white rounded-2xl shadow-sm border border-slate-200/80 p-6 md:p-8 w-full">
    @csrf
    @method('PUT')

    <!-- Quick Presets -->
    <div class="mb-6 flex flex-wrap items-center gap-2 pb-4 border-b border-slate-100">
        <span class="text-xs font-bold text-slate-500">پێشنیاری خێرا:</span>
        <button type="button" onclick="quickAddService('دانانی کانیۆلا و سێرووم', 'دانانا کانیۆلا و سێرۆمێ', 'Cannula & IV Infusion', 'تركيب كانيولا ومغذي', 15000)" class="text-xs font-bold px-3 py-1.5 rounded-xl bg-teal-50 hover:bg-teal-100 text-teal-700 border border-teal-200/60 transition">+ دانانی کانیۆلا</button>
        <button type="button" onclick="quickAddService('لێدانی دەرزی (ماسولکە و دەمار)', 'لێدانا دەرزیێ (ماسۆلکە و دەمار)', 'Injections (IM / IV)', 'حقن عضل ووريد', 10000)" class="text-xs font-bold px-3 py-1.5 rounded-xl bg-teal-50 hover:bg-teal-100 text-teal-700 border border-teal-200/60 transition">+ لێدانی دەرزی</button>
        <button type="button" onclick="quickAddService('پانسمانی برین و سووتان', 'پانسمانا برین و سۆتنێ', 'Wound & Burn Dressing', 'تضميد الجروح والحروق', 20000)" class="text-xs font-bold px-3 py-1.5 rounded-xl bg-teal-50 hover:bg-teal-100 text-teal-700 border border-teal-200/60 transition">+ پانسمانی برین</button>
        <button type="button" onclick="quickAddService('دانان و گۆڕینی سۆندەی میز', 'دانان و گوهۆڕینا سۆندەیا میزێ', 'Urinary Catheter Care', 'تركيب وتبديل قسطرة البول', 25000)" class="text-xs font-bold px-3 py-1.5 rounded-xl bg-teal-50 hover:bg-teal-100 text-teal-700 border border-teal-200/60 transition">+ سۆندەی میز</button>
        <button type="button" onclick="quickAddService('پێوانی زەخت و ڕێژەی شەکرە', 'پیڤانا فشارا خوینێ و شەکرێ', 'Blood Pressure & Glucose Check', 'فحص الضغط والسكري', 8000)" class="text-xs font-bold px-3 py-1.5 rounded-xl bg-teal-50 hover:bg-teal-100 text-teal-700 border border-teal-200/60 transition">+ پشکنینی زەخت و شەکرە</button>
    </div>

    <div id="custom-services-container" class="space-y-4 mb-6">
        @foreach($customServicesRows as $cIdx => $csRow)
            <div class="custom-service-row bg-slate-50 border border-slate-200/80 rounded-2xl p-4 transition-all hover:border-emerald-300 relative">
                <div class="grid grid-cols-1 md:grid-cols-12 gap-3 items-center">
                    <div class="md:col-span-3">
                        <label class="block text-[11px] font-bold text-slate-600 mb-1">ناوی خزمەتگوزاری (سۆرانی)</label>
                        <input type="text" name="custom_services[{{ $cIdx }}][name]" value="{{ $csRow['name'] ?? '' }}" placeholder="وەک: دانانی کانیۆلا و سێرووم"
                            class="service-kurdish-input w-full px-3.5 py-2.5 bg-white border border-slate-200 rounded-xl text-xs font-bold text-slate-800 focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500">
                    </div>
                    <div class="md:col-span-3">
                        <label class="block text-[11px] font-bold text-slate-600 mb-1">خزمەتگوزاری (بادینی)</label>
                        <input type="text" name="custom_services[{{ $cIdx }}][name_kmr]" value="{{ $csRow['name_kmr'] ?? '' }}" placeholder="دانانا کانیۆلا"
                            class="service-badini-input w-full px-3.5 py-2.5 bg-white border border-slate-200 rounded-xl text-xs font-medium text-slate-700 focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500">
                    </div>
                    <div class="md:col-span-2">
                        <label class="block text-[11px] font-bold text-slate-600 mb-1">خزمەتگوزاری (ئینگلیزی)</label>
                        <input type="text" name="custom_services[{{ $cIdx }}][name_en]" value="{{ $csRow['name_en'] ?? '' }}" dir="ltr" placeholder="IV Cannula"
                            class="service-english-input w-full px-3.5 py-2.5 bg-white border border-slate-200 rounded-xl text-xs font-medium text-slate-700 focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500">
                    </div>
                    <div class="md:col-span-2">
                        <label class="block text-[11px] font-bold text-slate-600 mb-1">خزمەتگوزاری (عەرەبی)</label>
                        <input type="text" name="custom_services[{{ $cIdx }}][name_ar]" value="{{ $csRow['name_ar'] ?? '' }}" dir="rtl" placeholder="تركيب كانيولا"
                            class="service-arabic-input w-full px-3.5 py-2.5 bg-white border border-slate-200 rounded-xl text-xs font-medium text-slate-700 focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500">
                    </div>
                    <div class="md:col-span-2">
                        <label class="block text-[11px] font-bold text-slate-600 mb-1">نرخ (د.ع)</label>
                        <input type="number" name="custom_services[{{ $cIdx }}][price]" value="{{ $csRow['price'] ?? '' }}" min="0" placeholder="15000"
                            class="w-full px-3.5 py-2.5 bg-white border border-slate-200 rounded-xl text-xs font-bold text-emerald-700 focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500">
                    </div>
                    <div class="md:col-span-12 flex justify-end pt-1">
                        <button type="button" onclick="removeCustomServiceRow(this)" class="text-xs font-bold text-red-500 hover:text-red-700 flex items-center gap-1 hover:bg-red-50 px-2.5 py-1 rounded-lg transition-colors" title="سڕینەوە">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
                            سڕینەوەی ئەم خزمەتگوزارییە
                        </button>
                    </div>
                </div>
            </div>
        @endforeach
    </div>

    <div class="pt-4 border-t border-slate-100 flex items-center justify-end gap-3">
        <button type="submit"
            class="px-8 py-3 bg-gradient-to-r from-teal-600 to-emerald-600 hover:from-teal-700 hover:to-emerald-700 text-white font-bold rounded-xl shadow-lg shadow-teal-500/25 transition-all cursor-pointer text-sm">
            پاشەکەوتکردن و نوێکردنەوە
        </button>
    </div>
</form>

<script>
    let customServiceRowIdx = {{ count($customServicesRows) }};

    function escapeHtmlAttr(str) {
        return String(str ?? '')
            .replace(/&/g, '&amp;')
            .replace(/"/g, '&quot;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;');
    }

    function addCustomServiceRow(name = '', nameKmr = '', nameEn = '', nameAr = '', price = '') {
        const container = document.getElementById('custom-services-container');
        if (!container) return;

        const row = document.createElement('div');
        row.className = 'custom-service-row bg-slate-50 border border-slate-200/80 rounded-2xl p-4 transition-all hover:border-emerald-300 relative';
        row.innerHTML = `
            <div class="grid grid-cols-1 md:grid-cols-12 gap-3 items-center">
                <div class="md:col-span-3">
                    <label class="block text-[11px] font-bold text-slate-600 mb-1">ناوی خزمەتگوزاری (سۆرانی)</label>
                    <input type="text" name="custom_services[${customServiceRowIdx}][name]" value="${escapeHtmlAttr(name)}" placeholder="وەک: دانانی کانیۆلا و سێرووم"
                        class="service-kurdish-input w-full px-3.5 py-2.5 bg-white border border-slate-200 rounded-xl text-xs font-bold text-slate-800 focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500">
                </div>
                <div class="md:col-span-3">
                    <label class="block text-[11px] font-bold text-slate-600 mb-1">خزمەتگوزاری (بادینی)</label>
                    <input type="text" name="custom_services[${customServiceRowIdx}][name_kmr]" value="${escapeHtmlAttr(nameKmr)}" placeholder="دانانا کانیۆلا"
                        class="service-badini-input w-full px-3.5 py-2.5 bg-white border border-slate-200 rounded-xl text-xs font-medium text-slate-700 focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500">
                </div>
                <div class="md:col-span-2">
                    <label class="block text-[11px] font-bold text-slate-600 mb-1">خزمەتگوزاری (ئینگلیزی)</label>
                    <input type="text" name="custom_services[${customServiceRowIdx}][name_en]" value="${escapeHtmlAttr(nameEn)}" dir="ltr" placeholder="IV Cannula"
                        class="service-english-input w-full px-3.5 py-2.5 bg-white border border-slate-200 rounded-xl text-xs font-medium text-slate-700 focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500">
                </div>
                <div class="md:col-span-2">
                    <label class="block text-[11px] font-bold text-slate-600 mb-1">خزمەتگوزاری (عەرەبی)</label>
                    <input type="text" name="custom_services[${customServiceRowIdx}][name_ar]" value="${escapeHtmlAttr(nameAr)}" dir="rtl" placeholder="تركيب كانيولا"
                        class="service-arabic-input w-full px-3.5 py-2.5 bg-white border border-slate-200 rounded-xl text-xs font-medium text-slate-700 focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500">
                </div>
                <div class="md:col-span-2">
                    <label class="block text-[11px] font-bold text-slate-600 mb-1">نرخ (د.ع)</label>
                    <input type="number" name="custom_services[${customServiceRowIdx}][price]" value="${escapeHtmlAttr(price)}" min="0" placeholder="15000"
                        class="w-full px-3.5 py-2.5 bg-white border border-slate-200 rounded-xl text-xs font-bold text-emerald-700 focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500">
                </div>
                <div class="md:col-span-12 flex justify-end pt-1">
                    <button type="button" onclick="removeCustomServiceRow(this)" class="text-xs font-bold text-red-500 hover:text-red-700 flex items-center gap-1 hover:bg-red-50 px-2.5 py-1 rounded-lg transition-colors" title="سڕینەوە">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
                        سڕینەوەی ئەم خزمەتگوزارییە
                    </button>
                </div>
            </div>
        `;
        container.appendChild(row);
        customServiceRowIdx++;
    }

    function quickAddService(name, nameKmr, nameEn, nameAr, price) {
        const firstKurdishInput = document.querySelector('.custom-service-row .service-kurdish-input');
        if (firstKurdishInput && !firstKurdishInput.value.trim()) {
            const row = firstKurdishInput.closest('.custom-service-row');
            row.querySelector('.service-kurdish-input').value = name;
            row.querySelector('.service-badini-input').value = nameKmr;
            row.querySelector('.service-english-input').value = nameEn;
            row.querySelector('.service-arabic-input').value = nameAr;
            row.querySelector('input[type="number"]').value = price;
        } else {
            addCustomServiceRow(name, nameKmr, nameEn, nameAr, price);
        }
    }

    function removeCustomServiceRow(btn) {
        const rows = document.querySelectorAll('.custom-service-row');
        if (rows.length > 1) {
            btn.closest('.custom-service-row').remove();
        } else {
            const row = btn.closest('.custom-service-row');
            row.querySelectorAll('input').forEach(i => i.value = '');
        }
    }

    async function handleTranslateServices() {
        const btn = document.getElementById('translate-services-btn');
        const btnText = document.getElementById('translate-services-btn-text');
        const token = document.querySelector('#services-form input[name="_token"]')?.value;

        const customServiceRows = document.querySelectorAll('.custom-service-row');
        const customServicesPayload = [];
        customServiceRows.forEach(row => {
            const kInput = row.querySelector('.service-kurdish-input');
            const bInput = row.querySelector('.service-badini-input');
            const eInput = row.querySelector('.service-english-input');
            const aInput = row.querySelector('.service-arabic-input');
            if (kInput && kInput.value.trim()) {
                customServicesPayload.push({
                    name: kInput.value.trim(),
                    name_kmr: bInput ? bInput.value.trim() : '',
                    name_en: eInput ? eInput.value.trim() : '',
                    name_ar: aInput ? aInput.value.trim() : '',
                });
            }
        });

        if (customServicesPayload.length === 0) {
            alert('تکایە سەرەتا ناوی خزمەتگوزارییەک بە سۆرانی بنووسە.');
            return;
        }

        btn.disabled = true;
        btnText.textContent = 'خەریکی وەرگێڕانە...';
        btn.classList.add('opacity-80');

        try {
            const res = await fetch("{{ route('nurse.services.translate') }}", {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': token,
                    'Accept': 'application/json',
                },
                body: JSON.stringify({
                    custom_services: customServicesPayload,
                }),
            });

            const json = await res.json();
            if (json.success && json.data && Array.isArray(json.data.custom_services_translated)) {
                let payloadIdx = 0;
                customServiceRows.forEach(row => {
                    const kInput = row.querySelector('.service-kurdish-input');
                    if (!kInput || !kInput.value.trim()) return;

                    const item = json.data.custom_services_translated[payloadIdx++];
                    if (!item) return;

                    const bInput = row.querySelector('.service-badini-input');
                    const eInput = row.querySelector('.service-english-input');
                    const aInput = row.querySelector('.service-arabic-input');

                    if (bInput && item.name_kmr) bInput.value = item.name_kmr;
                    if (eInput && item.name_en) eInput.value = item.name_en;
                    if (aInput && item.name_ar) aInput.value = item.name_ar;
                });
            }
        } catch (err) {
            console.error(err);
            alert('هەڵەیەک لە وەرگێڕاندا ڕوویدا.');
        } finally {
            btn.disabled = false;
            btnText.textContent = 'وەرگێڕانی هەمووی (Translate All)';
            btn.classList.remove('opacity-80');
        }
    }
</script>
@endsection
