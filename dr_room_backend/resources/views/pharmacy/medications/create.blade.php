@extends('pharmacy.layouts.app')

@section('content')
<div class="fade-up">
    <div style="margin-bottom: 24px;">
        <h2 style="font-size: 1.5rem; font-weight: 700; color: #0f172a;">زیادکردنی دەرمان</h2>
        <p style="color: #64748b; font-size: 0.95rem;">زانیارییەکانی دەرمانەکە لێرە پڕبکەرەوە بۆ زیادکردنی بۆ کۆگاکەت.</p>
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
        <form action="{{ route('pharmacy.medications.store') }}" method="POST" enctype="multipart/form-data">
            @csrf
            
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 24px; margin-bottom: 24px;">
                <!-- Name -->
                <div>
                    <label style="display: block; font-weight: 600; color: #334155; margin-bottom: 8px;">ناوی دەرمان *</label>
                    <input type="text" name="name" value="{{ old('name') }}" placeholder="بۆ نموونە: Augmentin 1g" required style="width: 100%; padding: 12px 16px; border: 1px solid #e2e8f0; border-radius: 8px; font-size: 0.95rem; outline: none;">
                </div>

                <!-- Category -->
                <div>
                    <label style="display: block; font-weight: 600; color: #334155; margin-bottom: 8px;">پۆلێن (کەتیگۆری)</label>
                    <select name="category" style="width: 100%; padding: 12px 16px; border: 1px solid #e2e8f0; border-radius: 8px; font-size: 0.95rem; outline: none; background: white;">
                        <option value="ئازارشکێن" {{ old('category') == 'ئازارشکێن' ? 'selected' : '' }}>ئازارشکێن ⚡</option>
                        <option value="دژەهەوکردن" {{ old('category') == 'دژەهەوکردن' ? 'selected' : '' }}>دژەهەوکردن 🛡️</option>
                        <option value="ڤیتامین" {{ old('category') == 'ڤیتامین' ? 'selected' : '' }}>ڤیتامین 🍊</option>
                        <option value="گەدە و هەرس" {{ old('category') == 'گەدە و هەرس' ? 'selected' : '' }}>گەدە و هەرس 🫀</option>
                        <option value="منداڵان" {{ old('category') == 'منداڵان' ? 'selected' : '' }}>منداڵان 👶</option>
                        <option value="تەندروستی گشتی" {{ old('category') == 'تەندروستی گشتی' ? 'selected' : '' }}>تەندروستی گشتی 💊</option>
                    </select>
                </div>
            </div>

            <div style="display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 24px; margin-bottom: 24px;">
                <!-- Price -->
                <div>
                    <label style="display: block; font-weight: 600; color: #334155; margin-bottom: 8px;">نرخی فرۆشتن (دینار) *</label>
                    <input type="number" name="price" value="{{ old('price', 0) }}" required min="0" style="width: 100%; padding: 12px 16px; border: 1px solid #e2e8f0; border-radius: 8px; font-size: 0.95rem; outline: none;">
                </div>

                <!-- Original Price -->
                <div>
                    <label style="display: block; font-weight: 600; color: #334155; margin-bottom: 8px;">نرخی سەرەتایی پێش داشکاندن</label>
                    <input type="number" name="original_price" value="{{ old('original_price') }}" min="0" placeholder="ئارەزوومەندانە" style="width: 100%; padding: 12px 16px; border: 1px solid #e2e8f0; border-radius: 8px; font-size: 0.95rem; outline: none;">
                </div>

                <!-- Discount Percent -->
                <div>
                    <label style="display: block; font-weight: 600; color: #334155; margin-bottom: 8px;">ڕێژەی داشکاندن (٪)</label>
                    <input type="number" name="discount_percent" value="{{ old('discount_percent') }}" min="0" max="100" placeholder="بۆ نموونە: 20" style="width: 100%; padding: 12px 16px; border: 1px solid #e2e8f0; border-radius: 8px; font-size: 0.95rem; outline: none;">
                </div>
            </div>

            <div style="display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 24px; margin-bottom: 24px;">
                <!-- Stock -->
                <div>
                    <label style="display: block; font-weight: 600; color: #334155; margin-bottom: 8px;">بڕی بەردەست (دانە) *</label>
                    <input type="number" name="stock" value="{{ old('stock', 30) }}" required min="0" style="width: 100%; padding: 12px 16px; border: 1px solid #e2e8f0; border-radius: 8px; font-size: 0.95rem; outline: none;">
                </div>

                <!-- Dosage Form -->
                <div>
                    <label style="display: block; font-weight: 600; color: #334155; margin-bottom: 8px;">یەکە / شێواز</label>
                    <input type="text" name="dosage_form" value="{{ old('dosage_form', 'پاکەت') }}" placeholder="پاکەت / دانە" style="width: 100%; padding: 12px 16px; border: 1px solid #e2e8f0; border-radius: 8px; font-size: 0.95rem; outline: none;">
                </div>

                <!-- Badge -->
                <div>
                    <label style="display: block; font-weight: 600; color: #334155; margin-bottom: 8px;">باج / نیشانە</label>
                    <input type="text" name="badge" value="{{ old('badge') }}" placeholder="بۆ نموونە: ئۆرجیناڵ ⭐" style="width: 100%; padding: 12px 16px; border: 1px solid #e2e8f0; border-radius: 8px; font-size: 0.95rem; outline: none;">
                </div>
            </div>

            <!-- Image -->
            <div style="margin-bottom: 24px;">
                <label style="display: block; font-weight: 600; color: #334155; margin-bottom: 8px;">وێنەی دەرمان</label>
                <input type="file" name="image" accept="image/*" style="width: 100%; padding: 9px 16px; border: 1px dashed #cbd5e1; border-radius: 8px; font-size: 0.95rem; background: #f8fafc; color: #64748b;">
            </div>

            <!-- Description -->
            <div style="margin-bottom: 24px;">
                <label style="display: block; font-weight: 600; color: #334155; margin-bottom: 8px;">وەسف و شێوازی بەکارهێنان</label>
                <textarea name="description" rows="3" placeholder="وەسفێکی کورت لەسەر سوودەکانی ئەم دەرمانە بنووسە..." style="width: 100%; padding: 12px 16px; border: 1px solid #e2e8f0; border-radius: 8px; font-size: 0.95rem; outline: none; resize: vertical;">{{ old('description') }}</textarea>
            </div>

            <!-- Toggles -->
            <div style="display: flex; gap: 24px; margin-bottom: 32px;">
                <label style="display: flex; align-items: center; gap: 8px; cursor: pointer; color: #334155; font-weight: 600;">
                    <input type="checkbox" name="requires_prescription" value="1" {{ old('requires_prescription') ? 'checked' : '' }} style="width: 18px; height: 18px;">
                    پێویستی بە ڕەچەتەی پزیشک هەیە
                </label>
            </div>

            <!-- Buttons -->
            <div style="display: flex; justify-content: flex-end; gap: 16px;">
                <a href="{{ route('pharmacy.medications.index') }}" style="padding: 12px 24px; border-radius: 8px; font-weight: 600; color: #64748b; background: #f1f5f9; text-decoration: none;">پاشگەزبوونەوە</a>
                <button type="submit" style="padding: 12px 24px; border-radius: 8px; font-weight: 600; color: white; background: #0d9488; border: none; cursor: pointer;">پاشەکەوتکردن</button>
            </div>
        </form>
    </div>
</div>
@endsection
