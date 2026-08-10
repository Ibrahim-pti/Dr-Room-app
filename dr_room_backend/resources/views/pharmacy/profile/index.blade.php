@extends('pharmacy.layouts.app')
@section('content')
<div class="fade-up">
    <h2 style="font-size: 1.5rem; font-weight: 700; color: #0f172a; margin-bottom: 24px;">پرۆفایلی دەرمانخانە</h2>
    
    @if(session('success'))
        <div style="background: #d1fae5; color: #065f46; padding: 12px; border-radius: 8px; margin-bottom: 20px;">
            {{ session('success') }}
        </div>
    @endif
    
    <div style="background: white; border-radius: 16px; padding: 32px; border: 1px solid #f1f5f9; max-width: 600px;">
        <form action="{{ route('pharmacy.profile.update') }}" method="POST">
            @csrf
            <div style="margin-bottom: 16px;">
                <label style="display: block; font-weight: 600; margin-bottom: 8px;">ناوی دەرمانخانە</label>
                <input type="text" name="name" value="{{ $user->name }}" style="width: 100%; padding: 12px; border-radius: 8px; border: 1px solid #e2e8f0; outline: none;">
            </div>
            <div style="margin-bottom: 16px;">
                <label style="display: block; font-weight: 600; margin-bottom: 8px;">ژمارەی مۆبایل</label>
                <input type="text" name="phone" value="{{ $user->phone }}" style="width: 100%; padding: 12px; border-radius: 8px; border: 1px solid #e2e8f0; outline: none;" dir="ltr">
            </div>
            <div style="margin-bottom: 24px;">
                <label style="display: block; font-weight: 600; margin-bottom: 8px;">ئیمەیڵ</label>
                <input type="email" disabled value="{{ $user->email }}" style="width: 100%; padding: 12px; border-radius: 8px; border: 1px solid #e2e8f0; background: #f8fafc; color: #64748b;" dir="ltr">
            </div>
            <button type="submit" style="background: #0d9488; color: white; padding: 12px 24px; border-radius: 8px; border: none; font-weight: 600; cursor: pointer;">پاشەکەوتکردن</button>
        </form>
    </div>
</div>
@endsection
