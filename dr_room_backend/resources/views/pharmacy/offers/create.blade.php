@extends('pharmacy.layouts.app')

@section('content')
<div class="fade-up">
    <div style="margin-bottom: 24px;">
        <h2 style="font-size: 1.5rem; font-weight: 700; color: #0f172a;">زیادکردنی ئۆفەر</h2>
        <p style="color: #64748b; font-size: 0.95rem;">ئۆفەرێکی نوێ دابنێ بۆ کڕیارەکانت.</p>
    </div>

    @if ($errors->any())
        <div style="background: #fef2f2; color: #991b1b; padding: 16px; border-radius: 8px; margin-bottom: 24px; border: 1px solid #fecaca;">
            <ul style="margin: 0; padding-right: 20px;">
                @foreach ($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    <div style="background: white; border-radius: 16px; border: 1px solid #f1f5f9; padding: 32px; max-width: 800px;">
        <form action="{{ route('pharmacy.offers.store') }}" method="POST" enctype="multipart/form-data">
            @csrf
            
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 24px; margin-bottom: 24px;">
                <!-- Title -->
                <div>
                    <label style="display: block; font-weight: 600; color: #334155; margin-bottom: 8px;">ناوی ئۆفەر *</label>
                    <input type="text" name="title" value="{{ old('title') }}" required style="width: 100%; padding: 12px 16px; border: 1px solid #e2e8f0; border-radius: 8px; font-size: 0.95rem; outline: none;">
                </div>

                <!-- Discount Percentage -->
                <div>
                    <label style="display: block; font-weight: 600; color: #334155; margin-bottom: 8px;">ڕێژەی داشکاندن (%) *</label>
                    <input type="number" name="discount_percentage" value="{{ old('discount_percentage', 0) }}" required min="0" max="100" style="width: 100%; padding: 12px 16px; border: 1px solid #e2e8f0; border-radius: 8px; font-size: 0.95rem; outline: none;">
                </div>
            </div>

            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 24px; margin-bottom: 24px;">
                <!-- Start Date -->
                <div>
                    <label style="display: block; font-weight: 600; color: #334155; margin-bottom: 8px;">بەرواری دەستپێکردن</label>
                    <input type="date" name="start_date" value="{{ old('start_date') }}" style="width: 100%; padding: 12px 16px; border: 1px solid #e2e8f0; border-radius: 8px; font-size: 0.95rem; outline: none;">
                </div>

                <!-- End Date -->
                <div>
                    <label style="display: block; font-weight: 600; color: #334155; margin-bottom: 8px;">بەرواری کۆتایی</label>
                    <input type="date" name="end_date" value="{{ old('end_date') }}" style="width: 100%; padding: 12px 16px; border: 1px solid #e2e8f0; border-radius: 8px; font-size: 0.95rem; outline: none;">
                </div>
            </div>

            <!-- Image -->
            <div style="margin-bottom: 24px;">
                <label style="display: block; font-weight: 600; color: #334155; margin-bottom: 8px;">وێنەی ئۆفەر (ئارەزوومەندانە)</label>
                <input type="file" name="image" accept="image/*" style="width: 100%; padding: 9px 16px; border: 1px dashed #cbd5e1; border-radius: 8px; font-size: 0.95rem; background: #f8fafc; color: #64748b;">
            </div>

            <!-- Description -->
            <div style="margin-bottom: 24px;">
                <label style="display: block; font-weight: 600; color: #334155; margin-bottom: 8px;">وەسفی ئۆفەر</label>
                <textarea name="description" rows="4" style="width: 100%; padding: 12px 16px; border: 1px solid #e2e8f0; border-radius: 8px; font-size: 0.95rem; outline: none; resize: vertical;">{{ old('description') }}</textarea>
            </div>

            <!-- Is Active -->
            <div style="margin-bottom: 32px; display: flex; align-items: center; gap: 8px;">
                <input type="checkbox" name="is_active" id="is_active" checked style="width: 18px; height: 18px;">
                <label for="is_active" style="font-weight: 600; color: #334155; cursor: pointer;">ئۆفەرەکە چالاکە</label>
            </div>

            <!-- Buttons -->
            <div style="display: flex; justify-content: flex-end; gap: 16px;">
                <a href="{{ route('pharmacy.offers.index') }}" style="padding: 12px 24px; border-radius: 8px; font-weight: 600; color: #64748b; background: #f1f5f9; text-decoration: none;">پاشگەزبوونەوە</a>
                <button type="submit" style="padding: 12px 24px; border-radius: 8px; font-weight: 600; color: white; background: #0d9488; border: none; cursor: pointer;">پاشەکەوتکردن</button>
            </div>
        </form>
    </div>
</div>
@endsection
