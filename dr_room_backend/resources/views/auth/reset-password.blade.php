@extends('auth.layouts.card')
@section('title', 'Reset Password')

@section('content')
    <h1>وشەی نهێنی نوێ</h1>
    <p class="subtitle">وشەیەکی نهێنی نوێ دابنێ بۆ هەژمارەکەت. لانیکەم ٨ پیت بێت.</p>

    <form method="POST" action="{{ route('password.update') }}">
        @csrf
        <input type="hidden" name="token" value="{{ $token }}">

        <div class="form-group">
            <svg class="form-icon" width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.8">
                <path stroke-linecap="round" stroke-linejoin="round" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/>
            </svg>
            <input type="email" name="email" value="{{ old('email', $email) }}" required dir="ltr"
                   class="form-control" placeholder="Email">
        </div>

        <div class="form-group">
            <svg class="form-icon" width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.8">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"/>
            </svg>
            <input type="password" name="password" required autofocus dir="ltr"
                   class="form-control" placeholder="New password">
        </div>

        <div class="form-group">
            <svg class="form-icon" width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.8">
                <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
            </svg>
            <input type="password" name="password_confirmation" required dir="ltr"
                   class="form-control" placeholder="Confirm new password">
        </div>

        <button type="submit" class="btn">گۆڕینی وشەی نهێنی</button>
    </form>
@endsection
