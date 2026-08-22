@extends('pharmacy.layouts.app')

@section('content')
<div class="fade-up">
    <div style="margin-bottom: 24px;">
        <h2 style="font-size: 1.5rem; font-weight: 700; color: #0f172a;">پرۆفایلی دەرمانخانە</h2>
        <p style="color: #64748b; font-size: 0.95rem;">زانیارییە سەرەکییەکانی دەرمانخانەکەت لێرە تازەبکەرەوە بۆ ئەوەی لە ئەپەکە پیشانبدرێت.</p>
    </div>
    
    @if(session('success'))
        <div style="background: #d1fae5; color: #065f46; padding: 12px; border-radius: 8px; margin-bottom: 20px;">
            {{ session('success') }}
        </div>
    @endif

    @if ($errors->any())
        <div style="background: #fef2f2; color: #991b1b; padding: 16px; border-radius: 8px; margin-bottom: 24px; border: 1px solid #fecaca;">
            <ul style="margin: 0; padding-right: 20px;">
                @foreach ($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
    @endif
    
    @php
        $pharmacy = $user->pharmacy;
        $profileImg = $pharmacy && $pharmacy->image_path 
            ? (str_starts_with($pharmacy->image_path, 'http') ? $pharmacy->image_path : asset('storage/' . $pharmacy->image_path)) 
            : ($user->profile_image ? (str_starts_with($user->profile_image, 'http') ? $user->profile_image : asset('storage/' . $user->profile_image)) : null);
    @endphp

    <div style="background: white; border-radius: 16px; padding: 32px; border: 1px solid #f1f5f9; max-width: 800px;">
        <form action="{{ route('pharmacy.profile.update') }}" method="POST" enctype="multipart/form-data">
            @csrf
            
            <!-- Image & Name Header -->
            <div style="display: flex; align-items: center; gap: 20px; margin-bottom: 28px; padding-bottom: 20px; border-bottom: 1px solid #f1f5f9;">
                @if($profileImg)
                    <img src="{{ $profileImg }}" alt="{{ $user->name }}" style="width: 80px; height: 80px; border-radius: 16px; object-fit: cover; border: 2px solid #0d9488;">
                @else
                    <div style="width: 80px; height: 80px; border-radius: 16px; background: #e6fffa; color: #0d9488; display: flex; align-items: center; justify-content: center; font-size: 2rem; font-weight: 700;">
                        {{ mb_substr($user->name, 0, 1) }}
                    </div>
                @endif
                <div>
                    <label style="display: block; font-weight: 600; color: #334155; margin-bottom: 6px;">گۆڕینی لۆگۆ / وێنەی سەرەکی</label>
                    <input type="file" name="profile_image" accept="image/*" style="font-size: 0.85rem; color: #64748b;">
                </div>
            </div>

            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 24px; margin-bottom: 24px;">
                <div>
                    <label style="display: block; font-weight: 600; color: #334155; margin-bottom: 8px;">ناوی دەرمانخانە *</label>
                    <input type="text" name="name" value="{{ old('name', $user->name) }}" required style="width: 100%; padding: 12px 16px; border-radius: 8px; border: 1px solid #e2e8f0; outline: none;">
                </div>

                <div>
                    <label style="display: block; font-weight: 600; color: #334155; margin-bottom: 8px;">ژمارەی پەیوەندی *</label>
                    <input type="text" name="phone" value="{{ old('phone', $user->phone ?? ($pharmacy ? $pharmacy->phone : '')) }}" required style="width: 100%; padding: 12px 16px; border-radius: 8px; border: 1px solid #e2e8f0; outline: none;" dir="ltr">
                </div>
            </div>

            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 24px; margin-bottom: 24px;">
                <div>
                    <label style="display: block; font-weight: 600; color: #334155; margin-bottom: 8px;">شار</label>
                    <input type="text" name="city" value="{{ old('city', $pharmacy ? $pharmacy->city : 'هەولێر') }}" placeholder="هەولێر" style="width: 100%; padding: 12px 16px; border-radius: 8px; border: 1px solid #e2e8f0; outline: none;">
                </div>

                <div>
                    <label style="display: block; font-weight: 600; color: #334155; margin-bottom: 8px;">ناونیشانی تەواو</label>
                    <input type="text" name="location" value="{{ old('location', $pharmacy ? $pharmacy->location : '') }}" placeholder="شەقامی ١٠٠ مەتری - نزیک نەخۆشخانەی ڕزگاری" style="width: 100%; padding: 12px 16px; border-radius: 8px; border: 1px solid #e2e8f0; outline: none;">
                </div>
            </div>

            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 24px; margin-bottom: 24px;">
                <div>
                    <label style="display: block; font-weight: 600; color: #334155; margin-bottom: 8px;">کرێی گەیاندن (دینار)</label>
                    <input type="number" name="delivery_fee" value="{{ old('delivery_fee', $pharmacy ? (int)$pharmacy->delivery_fee : 3000) }}" min="0" style="width: 100%; padding: 12px 16px; border-radius: 8px; border: 1px solid #e2e8f0; outline: none;">
                </div>

                <div>
                    <label style="display: block; font-weight: 600; color: #334155; margin-bottom: 8px;">کاتی خەمڵێنراوی گەیاندن</label>
                    <input type="text" name="delivery_time" value="{{ old('delivery_time', $pharmacy ? $pharmacy->delivery_time : '۲۰-۳۰ خولەک') }}" placeholder="۲۰-۳۰ خولەک" style="width: 100%; padding: 12px 16px; border-radius: 8px; border: 1px solid #e2e8f0; outline: none;">
                </div>
            </div>

            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 24px; margin-bottom: 24px;">
                <div>
                    <label style="display: block; font-weight: 600; color: #334155; margin-bottom: 8px;">بەستەری فەیسبووک / پەڕە</label>
                    <input type="text" name="facebook_url" value="{{ old('facebook_url', $pharmacy ? $pharmacy->facebook_url : '') }}" placeholder="https://facebook.com/..." style="width: 100%; padding: 12px 16px; border-radius: 8px; border: 1px solid #e2e8f0; outline: none;" dir="ltr">
                </div>

                <div>
                    <label style="display: block; font-weight: 600; color: #334155; margin-bottom: 8px;">ئیمەیڵ (ناگۆڕدرێت)</label>
                    <input type="email" disabled value="{{ $user->email }}" style="width: 100%; padding: 12px 16px; border-radius: 8px; border: 1px solid #e2e8f0; background: #f8fafc; color: #64748b;" dir="ltr">
                </div>
            </div>

            <div style="margin-bottom: 24px;">
                <label style="display: block; font-weight: 600; color: #334155; margin-bottom: 8px;">دەربارەی دەرمانخانە</label>
                <textarea name="bio" rows="3" placeholder="کورتەیەک دەربارەی خزمەتگوزارییەکان و دەرمانەکانی دەرمانخانەکەت..." style="width: 100%; padding: 12px 16px; border-radius: 8px; border: 1px solid #e2e8f0; outline: none; resize: vertical;">{{ old('bio', $pharmacy ? $pharmacy->bio : '') }}</textarea>
            </div>

            <!-- Open / Closed Switch -->
            <div style="margin-bottom: 32px; display: flex; align-items: center; gap: 10px;">
                <input type="checkbox" name="is_open" id="is_open" value="1" {{ old('is_open', $pharmacy ? $pharmacy->is_open : true) ? 'checked' : '' }} style="width: 18px; height: 18px;">
                <label for="is_open" style="font-weight: 600; color: #334155; cursor: pointer;">دەرمانخانەکە لە ئێستادا کراوەیە بۆ وەرگرتنی داواکاری</label>
            </div>

            <div style="display: flex; justify-content: flex-end;">
                <button type="submit" style="background: #0d9488; color: white; padding: 12px 32px; border-radius: 8px; border: none; font-weight: 600; cursor: pointer;">پاشەکەوتکردن</button>
            </div>
        </form>
    </div>
</div>
@endsection
