@extends('auth.layouts.card')
@section('title', 'Forgot Password')

@section('content')
    <h1>وشەی نهێنیت لەبیرچووە؟</h1>
    <p class="subtitle">
        ئیمێلی هەژمارەکەت بنووسە. بەستەرێکت بۆ دەنێرین بۆ دانانی وشەی نهێنییەکی نوێ.
    </p>

    <form method="POST" action="{{ route('password.email') }}">
        @csrf

        <div class="form-group">
            <svg class="form-icon" width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.8">
                <path stroke-linecap="round" stroke-linejoin="round" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/>
            </svg>
            <input type="email" name="email" value="{{ old('email') }}" required autofocus dir="ltr"
                   class="form-control" placeholder="Email">
        </div>

        <button type="submit" class="btn">ناردنی بەستەری گەڕاندنەوە</button>
    </form>
@endsection
