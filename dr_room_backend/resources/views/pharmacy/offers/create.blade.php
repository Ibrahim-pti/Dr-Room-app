@extends('pharmacy.layouts.app')

@section('content')
<div class="fade-up max-w-4xl">
    <div style="margin-bottom: 24px;">
        <h2 style="font-size: 1.4rem; font-weight: 800; color: #0f172a;">زیادکردنی ئۆفەر</h2>
        <p style="color: #64748b; font-size: 0.9rem; margin-top: 4px;">ئۆفەرێکی نوێ و کۆدی داشکاندن دابنێ بۆ کڕیارەکانت لە ئەپەکە.</p>
    </div>

    @if ($errors->any())
        <div style="background: #fef2f2; color: #991b1b; padding: 16px; border-radius: 12px; margin-bottom: 24px; border: 1px solid #fecaca; font-weight: 700; font-size: 0.88rem;">
            <ul style="margin: 0; padding-right: 20px;">
                @foreach ($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    <div style="background: white; border-radius: 18px; border: 1px solid #e2e8f0; padding: 24px; box-shadow: 0 1px 3px rgba(0,0,0,0.02);">
        <form action="{{ route('pharmacy.offers.store') }}" method="POST" enctype="multipart/form-data">
            @csrf
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6" style="margin-bottom: 20px;">
                <!-- Title -->
                <div>
                    <label style="display: block; font-weight: 800; color: #334155; font-size: 0.85rem; margin-bottom: 8px;">ناوی ئۆفەر *</label>
                    <input type="text" name="title" value="{{ old('title') }}" placeholder="بۆ نموونە: ئۆفەری داشکاندنی دەرمانەکان 🎉" required style="width: 100%; padding: 12px 16px; border: 1.5px solid #e2e8f0; border-radius: 12px; font-size: 0.92rem; outline: none;">
                </div>

                <!-- Promo Code -->
                <div>
                    <label style="display: block; font-weight: 800; color: #334155; font-size: 0.85rem; margin-bottom: 8px;">کۆدی داشکاندن (Promo Code)</label>
                    <input type="text" name="promo_code" value="{{ old('promo_code', 'PHARMA10') }}" placeholder="PHARMA10" style="width: 100%; padding: 12px 16px; border: 1.5px solid #e2e8f0; border-radius: 12px; font-size: 0.92rem; outline: none;">
                </div>
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-6" style="margin-bottom: 20px;">
                <!-- Discount Percentage -->
                <div>
                    <label style="display: block; font-weight: 800; color: #334155; font-size: 0.85rem; margin-bottom: 8px;">ڕێژەی داشکاندن (%) *</label>
                    <input type="number" name="discount_percentage" value="{{ old('discount_percentage', 10) }}" required min="0" max="100" style="width: 100%; padding: 12px 16px; border: 1.5px solid #e2e8f0; border-radius: 12px; font-size: 0.92rem; outline: none;">
                </div>

                <!-- Start Date -->
                <div>
                    <label style="display: block; font-weight: 800; color: #334155; font-size: 0.85rem; margin-bottom: 8px;">بەرواری دەستپێکردن</label>
                    <input type="date" name="start_date" value="{{ old('start_date', date('Y-m-d')) }}" style="width: 100%; padding: 12px 16px; border: 1.5px solid #e2e8f0; border-radius: 12px; font-size: 0.92rem; outline: none;">
                </div>

                <!-- End Date -->
                <div>
                    <label style="display: block; font-weight: 800; color: #334155; font-size: 0.85rem; margin-bottom: 8px;">بەرواری کۆتایی</label>
                    <input type="date" name="end_date" value="{{ old('end_date') }}" style="width: 100%; padding: 12px 16px; border: 1.5px solid #e2e8f0; border-radius: 12px; font-size: 0.92rem; outline: none;">
                </div>
            </div>

            <!-- Image -->
            <div style="margin-bottom: 20px;">
                <label style="display: block; font-weight: 800; color: #334155; font-size: 0.85rem; margin-bottom: 8px;">وێنەی ئۆفەر (بانەر)</label>
                <input type="file" name="image" accept="image/*" style="width: 100%; padding: 10px 16px; border: 1.5px dashed #cbd5e1; border-radius: 12px; font-size: 0.88rem; background: #f8fafc; color: #64748b;">
            </div>

            <!-- Description -->
            <div style="margin-bottom: 20px;">
                <label style="display: block; font-weight: 800; color: #334155; font-size: 0.85rem; margin-bottom: 8px;">وەسفی ئۆفەر</label>
                <textarea name="description" rows="3" placeholder="داشکاندنی ١٠٪ بە کۆدی PHARMA10 لە کاتی کڕین" style="width: 100%; padding: 12px 16px; border: 1.5px solid #e2e8f0; border-radius: 12px; font-size: 0.92rem; outline: none; resize: vertical;">{{ old('description') }}</textarea>
            </div>

            <!-- Is Active -->
            <div style="margin-bottom: 28px; display: flex; align-items: center; gap: 10px;">
                <input type="checkbox" name="is_active" id="is_active" value="1" checked style="width: 20px; height: 20px; accent-color: #0d9488;">
                <label for="is_active" style="font-weight: 800; color: #334155; cursor: pointer; font-size: 0.9rem;">ئۆفەرەکە چالاکە و لە ئەپەکە پیشانبدرێت</label>
            </div>

            <!-- Buttons -->
            <div style="display: flex; justify-content: flex-end; gap: 12px; flex-wrap: wrap;">
                <a href="{{ route('pharmacy.offers.index') }}" style="padding: 12px 24px; border-radius: 12px; font-weight: 700; color: #64748b; background: #f1f5f9; text-decoration: none; font-size: 0.9rem;">پاشگەزبوونەوە</a>
                <button type="submit" style="padding: 12px 28px; border-radius: 12px; font-weight: 800; color: white; background: #0d9488; border: none; cursor: pointer; font-size: 0.9rem; box-shadow: 0 2px 6px rgba(13,148,136,0.25);">پاشەکەوتکردن</button>
            </div>
        </form>
    </div>
</div>
@endsection
