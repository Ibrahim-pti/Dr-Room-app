@extends('doctor.layouts.app')
@section('header_title', 'خزمەتگوزارییەکان')

@section('content')
<div class="mb-6">
    <h2 class="text-xl font-bold text-slate-800">جۆرەکانی سەردان و نەخۆشییەکان</h2>
    <p class="text-sm text-slate-500 mt-1">لێرە دەتوانیت ئەو خزمەتگوزاریانە زیاد بکەیت کە پێشکەشی دەکەیت لەگەڵ نرخەکانیان.</p>
</div>

@if(session('success'))
    <div class="mb-6 p-4 bg-green-50 border border-green-200 text-green-700 rounded-xl">
        {{ session('success') }}
    </div>
@endif

@if($errors->any())
    <div class="mb-6 p-4 bg-red-50 border border-red-200 text-red-700 rounded-xl text-sm">
        @foreach($errors->all() as $error)
            <div>• {{ $error }}</div>
        @endforeach
    </div>
@endif

<!-- Add New Service Form -->
<form action="{{ route('doctor.services.store') }}" method="POST" class="bg-white rounded-2xl shadow-sm border border-slate-200/60 p-6 mb-8 max-w-3xl">
    @csrf

    <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
        <div>
            <label for="name_ckb" class="block text-sm font-medium text-slate-700 mb-2">ناوی خزمەتگوزاری (کوردی)</label>
            <div class="flex gap-2">
                <input type="text" id="name_ckb" name="name_ckb" value="{{ old('name_ckb') }}" required
                    class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">
                <button type="button" onclick="translateService()" id="add_translate_btn" class="flex items-center gap-2 px-4 py-2 bg-indigo-50 text-indigo-600 rounded-xl hover:bg-indigo-100 transition-colors text-sm font-medium whitespace-nowrap">
                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" width="18" height="18"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5h12M9 3v2m1.048 9.5A18.022 18.022 0 016.412 9m6.088 9h7M11 21l5-10 5 10M12.751 5C11.783 10.77 8.07 15.61 3 18.129"/></svg>
                    <span>وەرگێڕانی ئۆتۆماتیکی</span>
                </button>
            </div>
            @error('name_ckb') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
        </div>

        <div>
            <label for="price" class="block text-sm font-medium text-slate-700 mb-2">نرخ (دینار)</label>
            <input type="number" step="250" min="0" id="price" name="price" value="{{ old('price') }}" required dir="ltr" placeholder="25000"
                class="w-full text-right px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">
            @error('price') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
        </div>
    </div>

    <!-- Offer / discount -->
    <div class="pt-5 mb-6 border-t border-slate-100">
        <label class="flex items-center gap-2 cursor-pointer mb-4">
            <input type="checkbox" id="has_offer" onchange="toggleOffer(this.checked)" class="w-4 h-4 rounded text-blue-600 focus:ring-blue-500">
            <span class="text-sm font-bold text-slate-800">ئۆفەری داشکان هەیە</span>
        </label>

        <div id="offer_fields" class="hidden grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
                <label for="old_price" class="block text-sm font-medium text-slate-700 mb-2">نرخی پێشوو (دینار)</label>
                <input type="number" step="250" min="0" id="old_price" name="old_price" value="{{ old('old_price') }}" dir="ltr" placeholder="35000"
                    class="w-full text-right px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700"
                    oninput="previewDiscount()">
                <p id="discount_preview" class="text-xs text-slate-400 mt-1">لە ئەپەکەدا بە هێڵ بەسەردا دەردەکەوێت.</p>
                @error('old_price') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
            </div>

            <div>
                <label for="discount_until" class="block text-sm font-medium text-slate-700 mb-2">تا کەی؟ <span class="text-slate-400 font-normal">(ئارەزوومەندانە)</span></label>
                <input type="date" id="discount_until" name="discount_until" value="{{ old('discount_until') }}" min="{{ date('Y-m-d') }}"
                    class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">
                <p class="text-xs text-slate-400 mt-1">بەتاڵ = داشکانەکە کۆتایی نایەت.</p>
                @error('discount_until') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
            </div>
        </div>
    </div>

    <!-- Filled by the translate button, or by the server when left blank -->
    <div id="translations_container" class="hidden grid grid-cols-1 md:grid-cols-2 gap-6 mb-6 pt-4 border-t border-slate-100">
        <div>
            <label for="name_en" class="block text-sm font-medium text-slate-700 mb-2">ناوی خزمەتگوزاری (ئینگلیزی)</label>
            <input type="text" id="name_en" name="name_en" value="{{ old('name_en') }}" dir="ltr"
                class="w-full px-4 py-2 bg-white border border-slate-200 rounded-lg">
        </div>
        <div>
            <label for="name_ar" class="block text-sm font-medium text-slate-700 mb-2">ناوی خزمەتگوزاری (عەرەبی)</label>
            <input type="text" id="name_ar" name="name_ar" value="{{ old('name_ar') }}" dir="rtl"
                class="w-full px-4 py-2 bg-white border border-slate-200 rounded-lg">
        </div>
    </div>

    <div class="flex justify-end">
        <button type="submit" id="add_submit_btn" disabled class="px-6 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-xl font-medium transition-colors shadow-lg shadow-blue-500/30 opacity-50 cursor-not-allowed">
            زیادکردنی خزمەتگوزاری
        </button>
    </div>
</form>

<!-- Existing Services List -->
<div class="bg-white rounded-2xl shadow-sm border border-slate-200/60 overflow-hidden">
    <table class="w-full text-right text-sm">
        <thead class="bg-slate-50 text-slate-600 font-medium">
            <tr>
                <th class="py-4 px-6 border-b border-slate-200">ناوی خزمەتگوزاری</th>
                <th class="py-4 px-6 border-b border-slate-200">نرخ</th>
                <th class="py-4 px-6 border-b border-slate-200">دۆخ</th>
                <th class="py-4 px-6 border-b border-slate-200">کردارەکان</th>
            </tr>
        </thead>
        <tbody class="divide-y divide-slate-100 text-slate-700">
            @forelse($services as $service)
            <tr class="hover:bg-slate-50/50 transition-colors {{ $service->is_active ? '' : 'opacity-50' }}">
                <td class="py-4 px-6">
                    <div class="font-medium text-slate-800">{{ $service->name_ckb }}</div>
                    <div class="text-xs text-slate-500 mt-1">EN: {{ $service->name_en }} | AR: {{ $service->name_ar }}</div>
                </td>

                <td class="py-4 px-6">
                    @if($service->has_discount)
                        <div class="flex items-center gap-2">
                            <span class="text-slate-400 line-through text-xs" dir="ltr">{{ number_format($service->old_price) }}</span>
                            <span class="font-semibold text-emerald-600" dir="ltr">{{ number_format($service->price) }} د.ع</span>
                            <span class="px-2 py-0.5 bg-red-50 text-red-600 rounded-lg text-xs font-bold">%{{ $service->discount_percent }}-</span>
                        </div>
                        @if($service->discount_until)
                            <div class="text-xs text-slate-400 mt-1">تا {{ $service->discount_until->format('Y-m-d') }}</div>
                        @endif
                    @else
                        <span class="font-semibold text-emerald-600" dir="ltr">{{ number_format($service->price) }} د.ع</span>
                        @if($service->discount_expired)
                            <div class="text-xs text-amber-600 mt-1">داشکانەکە بەسەرچووە</div>
                        @endif
                    @endif
                </td>

                <td class="py-4 px-6">
                    @if($service->is_active)
                        <span class="px-2.5 py-1 bg-emerald-50 text-emerald-700 rounded-lg text-xs font-medium">چالاک</span>
                    @else
                        <span class="px-2.5 py-1 bg-slate-100 text-slate-500 rounded-lg text-xs font-medium">شاردراوە</span>
                    @endif
                </td>

                @php
                    // Built here rather than inline: Blade's @json directive
                    // cannot parse a multi-line array written inside an attribute.
                    $editPayload = [
                        'id' => $service->id,
                        'name_ckb' => $service->name_ckb,
                        'name_en' => $service->name_en,
                        'name_ar' => $service->name_ar,
                        'price' => (float) $service->price,
                        'old_price' => $service->old_price ? (float) $service->old_price : '',
                        'discount_until' => $service->discount_until?->format('Y-m-d') ?? '',
                    ];
                @endphp

                <td class="py-4 px-6">
                    <div class="flex items-center gap-1">
                        <button type="button"
                            onclick="openEdit({{ json_encode($editPayload, JSON_UNESCAPED_UNICODE | JSON_HEX_APOS | JSON_HEX_QUOT) }})"
                            class="text-blue-500 hover:text-blue-700 p-2 rounded-lg hover:bg-blue-50 transition-colors" title="دەستکاری">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                            </svg>
                        </button>

                        <form action="{{ route('doctor.services.toggle', $service->id) }}" method="POST">
                            @csrf
                            @method('PATCH')
                            <button type="submit" class="text-slate-500 hover:text-slate-700 p-2 rounded-lg hover:bg-slate-100 transition-colors" title="{{ $service->is_active ? 'شاردنەوە لە ئەپ' : 'چالاککردنەوە' }}">
                                @if($service->is_active)
                                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" />
                                    </svg>
                                @else
                                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                                    </svg>
                                @endif
                            </button>
                        </form>

                        <form action="{{ route('doctor.services.destroy', $service->id) }}" method="POST" onsubmit="return confirm('دڵنیایت لە سڕینەوەی؟');">
                            @csrf
                            @method('DELETE')
                            <button type="submit" class="text-red-500 hover:text-red-700 p-2 rounded-lg hover:bg-red-50 transition-colors" title="سڕینەوە">
                                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                                </svg>
                            </button>
                        </form>
                    </div>
                </td>
            </tr>
            @empty
            <tr>
                <td colspan="4" class="py-8 px-6 text-center text-slate-500">
                    هیچ خزمەتگوزارییەک بوونی نییە. تکایە یەکەم خزمەتگوزاری زیاد بکە.
                </td>
            </tr>
            @endforelse
        </tbody>
    </table>
</div>

<!-- Edit modal -->
<div id="edit_modal" class="hidden fixed inset-0 z-50 items-center justify-center bg-slate-900/50 p-4">
    <div class="bg-white rounded-2xl shadow-xl w-full max-w-lg p-6">
        <h3 class="text-lg font-bold text-slate-800 mb-5">دەستکاری خزمەتگوزاری</h3>

        <form id="edit_form" method="POST">
            @csrf
            @method('PUT')

            <div class="space-y-4">
                <div>
                    <label class="block text-sm font-medium text-slate-700 mb-2">ناو (کوردی)</label>
                    <div class="flex gap-2">
                        <input type="text" name="name_ckb" id="edit_name_ckb" required
                            class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500">
                        <button type="button" onclick="translateEditService()" class="flex items-center gap-2 px-4 py-2 bg-indigo-50 text-indigo-600 rounded-xl hover:bg-indigo-100 transition-colors text-sm font-medium whitespace-nowrap">
                            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" width="18" height="18"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5h12M9 3v2m1.048 9.5A18.022 18.022 0 016.412 9m6.088 9h7M11 21l5-10 5 10M12.751 5C11.783 10.77 8.07 15.61 3 18.129"/></svg>
                            <span>وەرگێڕانی ئۆتۆماتیکی</span>
                        </button>
                    </div>
                </div>

                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <label class="block text-sm font-medium text-slate-700 mb-2">ناو (ئینگلیزی)</label>
                        <input type="text" name="name_en" id="edit_name_en" dir="ltr"
                            class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500">
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-slate-700 mb-2">ناو (عەرەبی)</label>
                        <input type="text" name="name_ar" id="edit_name_ar" dir="rtl"
                            class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500">
                    </div>
                </div>

                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <label class="block text-sm font-medium text-slate-700 mb-2">نرخ (دینار)</label>
                        <input type="number" step="250" min="0" name="price" id="edit_price" required dir="ltr"
                            class="w-full text-right px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500">
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-slate-700 mb-2">نرخی پێشوو</label>
                        <input type="number" step="250" min="0" name="old_price" id="edit_old_price" dir="ltr" placeholder="بەتاڵ = بێ داشکان"
                            class="w-full text-right px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500">
                    </div>
                </div>

                <div>
                    <label class="block text-sm font-medium text-slate-700 mb-2">داشکان تا</label>
                    <input type="date" name="discount_until" id="edit_discount_until" min="{{ date('Y-m-d') }}"
                        class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500">
                </div>
            </div>

            <div class="flex justify-end gap-3 mt-6">
                <button type="button" onclick="closeEdit()" class="px-5 py-2.5 bg-slate-100 text-slate-600 rounded-xl font-medium hover:bg-slate-200 transition-colors">پاشگەزبوونەوە</button>
                <button type="submit" id="edit_submit_btn" class="px-5 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-xl font-medium transition-colors">پاشەکەوتکردن</button>
            </div>
        </form>
    </div>
</div>

<script>
    function toggleOffer(on) {
        document.getElementById('offer_fields').classList.toggle('hidden', !on);
        document.getElementById('offer_fields').classList.toggle('grid', on);
        if (!on) {
            document.getElementById('old_price').value = '';
            document.getElementById('discount_until').value = '';
        }
    }

    function previewDiscount() {
        const price = parseFloat(document.getElementById('price').value);
        const oldPrice = parseFloat(document.getElementById('old_price').value);
        const label = document.getElementById('discount_preview');

        if (!price || !oldPrice || oldPrice <= price) {
            label.textContent = 'لە ئەپەکەدا بە هێڵ بەسەردا دەردەکەوێت.';
            label.className = 'text-xs text-slate-400 mt-1';
            return;
        }
        const percent = Math.round(((oldPrice - price) / oldPrice) * 100);
        label.textContent = 'داشکانی ' + percent + '% — نەخۆش ئەمە دەبینێت.';
        label.className = 'text-xs text-emerald-600 font-medium mt-1';
    }

    function openEdit(service) {
        document.getElementById('edit_form').action = '{{ url('doctor/services') }}/' + service.id;
        document.getElementById('edit_name_ckb').value = service.name_ckb ?? '';
        document.getElementById('edit_name_en').value = service.name_en ?? '';
        document.getElementById('edit_name_ar').value = service.name_ar ?? '';
        document.getElementById('edit_price').value = service.price;
        document.getElementById('edit_old_price').value = service.old_price;
        document.getElementById('edit_discount_until').value = service.discount_until;

        const modal = document.getElementById('edit_modal');
        modal.classList.remove('hidden');
        modal.classList.add('flex');
    }

    function closeEdit() {
        const modal = document.getElementById('edit_modal');
        modal.classList.add('hidden');
        modal.classList.remove('flex');
    }

    document.getElementById('edit_modal').addEventListener('click', function (e) {
        if (e.target === this) closeEdit();
    });

    function translateService() {
        const text = document.getElementById('name_ckb').value;
        if (!text) return;

        document.getElementById('translations_container').classList.remove('hidden');
        document.getElementById('translations_container').classList.add('grid');
        document.getElementById('name_en').value = 'لە وەرگێڕاندایە...';
        document.getElementById('name_ar').value = 'لە وەرگێڕاندایە...';

        fetch('{{ route('api.translate') }}', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-TOKEN': '{{ csrf_token() }}'
            },
            body: JSON.stringify({ text: text })
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                document.getElementById('name_en').value = data.translations.en;
                document.getElementById('name_ar').value = data.translations.ar;
                
                const addBtn = document.getElementById('add_submit_btn');
                addBtn.disabled = false;
                addBtn.classList.remove('opacity-50', 'cursor-not-allowed');
            }
        });
    }

    function translateEditService() {
        const text = document.getElementById('edit_name_ckb').value;
        if (!text) return;

        document.getElementById('edit_name_en').value = 'لە وەرگێڕاندایە...';
        document.getElementById('edit_name_ar').value = 'لە وەرگێڕاندایە...';

        fetch('{{ route('api.translate') }}', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-TOKEN': '{{ csrf_token() }}'
            },
            body: JSON.stringify({ text: text })
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                document.getElementById('edit_name_en').value = data.translations.en;
                document.getElementById('edit_name_ar').value = data.translations.ar;
                
                const editBtn = document.getElementById('edit_submit_btn');
                editBtn.disabled = false;
                editBtn.classList.remove('opacity-50', 'cursor-not-allowed');
            }
        });
    }

    // Disable submit buttons on input change
    document.getElementById('name_ckb').addEventListener('input', function() {
        const addBtn = document.getElementById('add_submit_btn');
        addBtn.disabled = true;
        addBtn.classList.add('opacity-50', 'cursor-not-allowed');
    });

    document.getElementById('edit_name_ckb').addEventListener('input', function() {
        const editBtn = document.getElementById('edit_submit_btn');
        editBtn.disabled = true;
        editBtn.classList.add('opacity-50', 'cursor-not-allowed');
    });

    // Keep the offer block open when validation bounced the form back.
    @if(old('old_price'))
        toggleOffer(true);
        document.getElementById('has_offer').checked = true;
        previewDiscount();
    @endif
</script>
@endsection
