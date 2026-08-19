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
        <a href="{{ route('lab.results.index') }}" class="px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold rounded-xl text-xs transition-colors">
            گەڕانەوە بۆ ئەنجامەکان
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

            @if(!empty($selectedOrderId))
                <input type="hidden" name="order_id" value="{{ $selectedOrderId }}">
            @endif

            <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
                <!-- Patient Selector -->
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

                <!-- Test Selector -->
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

            <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
                <!-- Result Value -->
                <div>
                    <label class="block text-xs font-bold text-slate-700 mb-2">بڕ/ئەنجامی پشکنین (Result Value)</label>
                    <input type="text" name="result_value" value="{{ old('result_value') }}" placeholder="نموونە: Hb: 14.2 g/dL یان Negative" 
                           class="w-full bg-slate-50 border border-slate-200 text-slate-800 font-bold text-xs rounded-xl p-3 outline-none focus:border-blue-500">
                </div>

                <!-- Status -->
                <div>
                    <label class="block text-xs font-bold text-slate-700 mb-2">حاڵەتی پشکنین *</label>
                    <select name="status" required class="w-full bg-slate-50 border border-slate-200 text-slate-800 font-bold text-xs rounded-xl p-3 outline-none focus:border-blue-500">
                        <option value="completed" {{ old('status', 'completed') == 'completed' ? 'selected' : '' }}>✅ تەواوکراوە و ئامادەیە بۆ نەخۆش</option>
                        <option value="pending" {{ old('status') == 'pending' ? 'selected' : '' }}>⏳ چاوەڕوانە (Pending)</option>
                    </select>
                </div>
            </div>

            <!-- Upload Result File (PDF or Image) -->
            <div>
                <label class="block text-xs font-bold text-slate-700 mb-2">فایلی فەرمی ئەنجام (ڕاپۆرتی PDF یان وێنەی پشکنین)</label>
                <input type="file" name="file" accept=".pdf,.jpg,.jpeg,.png" 
                       class="w-full bg-slate-50 border border-slate-200 text-slate-700 font-semibold text-xs rounded-xl p-3 file:mr-4 file:py-2 file:px-4 file:rounded-xl file:border-0 file:text-xs file:font-bold file:bg-blue-600 file:text-white hover:file:bg-blue-700 cursor-pointer">
                <p class="text-[11px] text-slate-400 mt-1.5">فۆرماتە ڕێگەپێدراوەکان: PDF, JPG, PNG (زۆرترین قەبارە: 5MB). ئەم فایلە دەستبەجێ لەناو ئەپی نەخۆش بەردەست دەبێت.</p>
            </div>

            <!-- Notes -->
            <div>
                <label class="block text-xs font-bold text-slate-700 mb-2">تێبینی و ڕێنمایی تاقیگە بۆ نەخۆش</label>
                <textarea name="notes" rows="3" placeholder="ڕێنمایی بۆ نەخۆش یان تێبینی تایبەتی دکتۆری تاقیگە بنووسە..." 
                          class="w-full bg-slate-50 border border-slate-200 text-slate-800 text-xs rounded-xl p-3 outline-none focus:border-blue-500">{{ old('notes') }}</textarea>
            </div>

            <!-- Submit Button -->
            <div class="flex items-center justify-end gap-3 pt-4 border-t border-slate-100">
                <a href="{{ route('lab.results.index') }}" class="px-6 py-2.5 bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold rounded-xl text-xs transition-colors">
                    پاشگەزبوونەوە
                </a>
                <button type="submit" class="px-8 py-2.5 bg-blue-600 hover:bg-blue-700 text-white font-bold rounded-xl text-xs shadow-md shadow-blue-200 transition-all flex items-center gap-2">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
                    تۆمارکردن و ناردنی ئەنجام بۆ نەخۆش
                </button>
            </div>
        </form>
    </div>
</div>
@endsection
