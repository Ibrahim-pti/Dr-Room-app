@php
    $selectedType = old('type', $currentType ?? ($labCategories[0] ?? 'پشکنینی گشتی'));
    $customTypeVal = old('custom_type', '');
    $isCustomSelected = $selectedType === '__custom__' || ($selectedType !== '' && !in_array($selectedType, $labCategories ?? [], true));
@endphp

<div>
    <label class="block text-xs font-bold text-slate-700 mb-2" for="typeSelect">
        کەتەگۆری / بەشی پشکنین <span class="text-rose-500">*</span>
    </label>
    <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
        <select
            id="typeSelect"
            name="type"
            onchange="toggleCustomLabCategory(this.value)"
            class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 font-bold text-xs text-slate-800 outline-none"
        >
            @foreach(($labCategories ?? []) as $catOption)
                <option value="{{ $catOption }}" {{ !$isCustomSelected && $selectedType === $catOption ? 'selected' : '' }}>
                    {{ $catOption }}
                </option>
            @endforeach
            <option value="__custom__" {{ $isCustomSelected ? 'selected' : '' }}>+ زیادکردنی کەتەگۆری نوێ...</option>
        </select>

        <input
            type="text"
            id="customTypeInput"
            name="custom_type"
            value="{{ $customTypeVal ?: ($isCustomSelected && $selectedType !== '__custom__' ? $selectedType : '') }}"
            placeholder="ناوی کەتەگۆری نوێ بنووسە..."
            class="{{ $isCustomSelected ? '' : 'hidden' }} w-full px-4 py-2.5 bg-blue-50/60 border border-blue-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 font-bold text-xs text-slate-800 outline-none"
        >
    </div>
    <p class="text-[11px] text-slate-400 mt-1.5">دەتوانیت لە بەشە ئامادەکانی تاقیگە هەڵبژێریت یان کەتەگۆری تایبەتی خۆت زیاد بکەیت.</p>
</div>

<script>
    function toggleCustomLabCategory(value) {
        const customInput = document.getElementById('customTypeInput');
        if (!customInput) return;
        if (value === '__custom__') {
            customInput.classList.remove('hidden');
            customInput.required = true;
            customInput.focus();
        } else {
            customInput.classList.add('hidden');
            customInput.required = false;
        }
    }
    document.addEventListener('DOMContentLoaded', function () {
        const select = document.getElementById('typeSelect');
        if (select) toggleCustomLabCategory(select.value);
    });
</script>
