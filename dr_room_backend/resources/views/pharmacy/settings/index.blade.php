@extends('pharmacy.layouts.app')
@section('content')
<div class="fade-up">
    <h2 style="font-size: 1.5rem; font-weight: 700; color: #0f172a; margin-bottom: 24px;">ڕێکخستنەکان</h2>
    
    @if(session('success'))
        <div style="background: #d1fae5; color: #065f46; padding: 12px; border-radius: 8px; margin-bottom: 20px;">
            {{ session('success') }}
        </div>
    @endif
    
    <div style="background: white; border-radius: 16px; padding: 32px; border: 1px solid #f1f5f9; max-width: 600px;">
        <form action="{{ route('pharmacy.settings.update') }}" method="POST">
            @csrf
            <div style="margin-bottom: 16px;">
                <label style="display: block; font-weight: 600; margin-bottom: 8px;">کرێی گەیاندنی بنەڕەتی (IQD)</label>
                <input type="number" name="delivery_fee" value="3000" style="width: 100%; padding: 12px; border-radius: 8px; border: 1px solid #e2e8f0; outline: none;">
            </div>
            <div style="margin-bottom: 24px;">
                <label style="display: block; font-weight: 600; margin-bottom: 8px;">کرێوەی کارکردن</label>
                <input type="text" value="کرێوە (24 کاتژمێر)" style="width: 100%; padding: 12px; border-radius: 8px; border: 1px solid #e2e8f0; outline: none;">
            </div>
            <button type="submit" style="background: #0d9488; color: white; padding: 12px 24px; border-radius: 8px; border: none; font-weight: 600; cursor: pointer;">پاشەکەوتکردن</button>
        </form>
    </div>
</div>
@endsection
