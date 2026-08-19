@extends('lab.layouts.app')
@section('header_title', 'تۆمارکردنی ئەنجامی پشکنین')

@section('content')
<div class="max-w-3xl mx-auto space-y-6">
    <!-- Header -->
    <div class="flex items-center justify-between bg-white p-6 rounded-2xl shadow-sm border border-slate-100">
        <div>
            <h2 class="text-xl font-bold text-slate-800">تۆمارکردنی ئەنجامی پشکنین بۆ نەخۆش</h2>
            <p class="text-xs text-slate-500 mt-1">ئەنجامی پشکنین تۆماربکە یان ڕاپۆرتی فەرمی (PDF / وێنە) ئەپلۆد بکە تاوەکو دەستبەجێ بگاتە ئەپەکەی نەخۆش.</p>
        </div>
        <a href="{{ route('lab.patients.index') }}" class="px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold rounded-xl text-xs transition-colors">
            گەڕانەوە بۆ داواکارییەکان
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
        <form action="{{ route('lab.results.store') }}" method="POST" enctype="multipart/form-data" class="space-y-6">
            @csrf

            @if($order)
                @php
                    $details = is_array($order->patient_details) ? $order->patient_details : (json_decode($order->patient_details, true) ?? []);
                    $pName = $details['full_name'] ?? $details['name'] ?? $order->patient?->name ?? 'نەخۆش';
                    $pPhone = $details['phone'] ?? $order->patient?->phone ?? 'مۆبایل نییە';
                    $pAge = $details['age'] ?? $details['patient_age'] ?? null;
                    
                    $rawGender = $details['patient_gender'] ?? $details['gender'] ?? $order->patient?->gender ?? null;
                    $rawGenderLower = strtolower(trim((string)$rawGender));
                    if (in_array($rawGenderLower, ['male', 'نێر', 'm', 'پیاو'])) {
                        $pGenderText = 'نێر (Male)';
                    } elseif (in_array($rawGenderLower, ['female', 'مێ', 'f', 'ئافرەت', 'ژن'])) {
                        $pGenderText = 'مێ (Female)';
                    } else {
                        $pGenderText = 'دیارینەکراو';
                    }
                @endphp
                <input type="hidden" name="order_id" value="{{ $order->id }}">
                <input type="hidden" name="patient_id" value="{{ $order->patient_id ?? $order->user_id }}">

                <!-- Pre-filled Patient Information Box -->
                <div class="bg-blue-50/70 p-5 rounded-2xl border border-blue-100 space-y-3">
                    <div class="flex items-center justify-between">
                        <div class="text-xs font-black text-blue-900 uppercase tracking-wider flex items-center gap-2">
                            <span>👤 زانیارییەکانی نەخۆش (لە داواکاری #ORD-{{ $order->id }})</span>
                        </div>
                        <span class="px-3 py-1 bg-white text-blue-700 font-bold text-xs rounded-xl shadow-2xs border border-blue-200" dir="ltr">
                            #ORD-{{ $order->id }}
                        </span>
                    </div>

                    <div class="grid grid-cols-2 sm:grid-cols-4 gap-4 text-xs">
                        <div>
                            <span class="text-[11px] text-slate-500 block">ناوی نەخۆش:</span>
                            <strong class="text-slate-800 text-sm">{{ $pName }}</strong>
                        </div>
                        <div>
                            <span class="text-[11px] text-slate-500 block">ژمارەی مۆبایل:</span>
                            <strong class="text-blue-700 text-sm font-mono" dir="ltr">{{ $pPhone }}</strong>
                        </div>
                        <div>
                            <span class="text-[11px] text-slate-500 block">تەمەن:</span>
                            <strong class="text-slate-800">{{ $pAge ? $pAge . ' ساڵ' : 'دیارینەکراو' }}</strong>
                        </div>
                        <div>
                            <span class="text-[11px] text-slate-500 block">ڕەگەز:</span>
                            <strong class="text-slate-800">{{ $pGenderText }}</strong>
                        </div>
                    </div>
                </div>

                <!-- Tests requested by the patient -->
                <div>
                    <label class="block text-xs font-bold text-slate-700 mb-2">🧪 پشکنینە داواکراوەکان (کە نەخۆش هەڵیبژاردووە)</label>
                    <div class="space-y-3">
                        @forelse($order->items as $item)
                            @php
                                $matchedTest = $tests->firstWhere('name', $item->item_name) ?? $tests->first();
                            @endphp
                            <div class="p-3.5 bg-slate-50 rounded-xl border border-slate-200 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                                <div>
                                    <span class="font-bold text-slate-800 text-xs block">{{ $item->item_name }}</span>
                                    <span class="text-[11px] text-blue-600 font-semibold" dir="ltr">{{ number_format($item->price) }} IQD</span>
                                </div>
                                <div class="w-full sm:w-64">
                                    <input type="text" 
                                           name="test_results[{{ $matchedTest?->id ?? $item->id }}]" 
                                           placeholder="ئەنجامی ئەم پشکنینە (ئارەزوومەندانە)" 
                                           class="w-full bg-white border border-slate-200 text-slate-800 font-semibold text-xs rounded-xl px-3 py-2 outline-none focus:border-blue-500">
                                </div>
                            </div>
                        @empty
                            <div class="p-4 bg-slate-50 rounded-xl border text-xs text-slate-500">
                                پشکنینی گشتی تاقیگە
                            </div>
                        @endforelse
                    </div>
                </div>

            @else
                <!-- Manual Entry (When not opened from a specific order) -->
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
                    <div>
                        <label class="block text-xs font-bold text-slate-700 mb-2">نەخۆش هەڵبژێرە *</label>
                        <select name="patient_id" required class="w-full bg-slate-50 border border-slate-200 text-slate-800 font-bold text-xs rounded-xl p-3 outline-none focus:border-blue-500">
                            <option value="">-- نەخۆش دیاریبکە --</option>
                            @foreach($patients as $patient)
                                <option value="{{ $patient->id }}" {{ (old('patient_id', $selectedPatientId) == $patient->id) ? 'selected' : '' }}>
                                    {{ $patient->name }} ({{ $patient->phone ?? 'مۆبایل نییە' }})
                                </option>
                            @endforeach
                        </select>
                    </div>

                    <div>
                        <label class="block text-xs font-bold text-slate-700 mb-2">جۆری پشکنین *</label>
                        <select name="test_id" required class="w-full bg-slate-50 border border-slate-200 text-slate-800 font-bold text-xs rounded-xl p-3 outline-none focus:border-blue-500">
                            <option value="">-- پشکنین دیاریبکە --</option>
                            @foreach($tests as $test)
                                <option value="{{ $test->id }}" {{ (old('test_id', $selectedTestId) == $test->id) ? 'selected' : '' }}>
                                    {{ $test->name }}
                                </option>
                            @endforeach
                        </select>
                    </div>
                </div>

                <div>
                    <label class="block text-xs font-bold text-slate-700 mb-2">بڕ/ئەنجامی پشکنین (Result Value)</label>
                    <input type="text" name="result_value" value="{{ old('result_value') }}" placeholder="نموونە: Hb: 14.2 g/dL یان Negative" 
                           class="w-full bg-slate-50 border border-slate-200 text-slate-800 font-bold text-xs rounded-xl p-3 outline-none focus:border-blue-500">
                </div>
            @endif

            <!-- Status & Upload File Box -->
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-6 pt-2">
                <!-- Status -->
                <div>
                    <label class="block text-xs font-bold text-slate-700 mb-2">حاڵەتی ئەنجام *</label>
                    <select name="status" required class="w-full bg-slate-50 border border-slate-200 text-slate-800 font-bold text-xs rounded-xl p-3 outline-none focus:border-blue-500">
                        <option value="completed" selected>✅ تەواوکراوە (ڕاستەوخۆ دەگاتە ئەپی نەخۆش)</option>
                        <option value="pending">⏳ لە چاوەڕوانیدا (Pending)</option>
                    </select>
                </div>

                <!-- Upload Official Report File -->
                <div>
                    <label class="block text-xs font-bold text-slate-700 mb-2">ڕاپۆرتی فەرمی (PDF یان وێنەی پشکنین)</label>
                    <input type="file" name="file" accept=".pdf,.jpg,.jpeg,.png" 
                           class="w-full bg-slate-50 border border-slate-200 text-slate-700 font-semibold text-xs rounded-xl p-2.5 file:mr-3 file:py-1.5 file:px-3 file:rounded-lg file:border-0 file:text-xs file:font-bold file:bg-blue-600 file:text-white hover:file:bg-blue-700 cursor-pointer">
                </div>
            </div>

            <!-- Notes & Instructions -->
            <div>
                <label class="block text-xs font-bold text-slate-700 mb-2">تێبینی و ڕێنمایی تاقیگە بۆ نەخۆش</label>
                <textarea name="notes" rows="3" placeholder="تێبینی دکتۆری تاقیگە یان ڕێنمایی تایبەت بۆ نەخۆش لێرە بنووسە..." 
                          class="w-full bg-slate-50 border border-slate-200 text-slate-800 text-xs rounded-xl p-3 outline-none focus:border-blue-500">{{ old('notes') }}</textarea>
            </div>

            <!-- Submit Buttons -->
            <div class="flex items-center justify-end gap-3 pt-4 border-t border-slate-100">
                <a href="{{ route('lab.patients.index') }}" class="px-6 py-2.5 bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold rounded-xl text-xs transition-colors">
                    پاشگەزبوونەوە
                </a>
                <button type="submit" class="px-8 py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-xl text-xs shadow-md shadow-emerald-200 transition-all flex items-center gap-2">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
                    تۆمارکردن و ناردنی ئەنجام بۆ نەخۆش
                </button>
            </div>
        </form>
    </div>
</div>
@endsection
