@extends('nurse.layouts.app')
@section('header_title', 'ڕێکخستنی پڕۆفایل')

@section('content')
<div class="mb-6">
    <h2 class="text-xl font-bold text-slate-800">ڕێکخستنەکانی پڕۆفایل</h2>
    <p class="text-sm text-slate-500 mt-1">لێرە دەتوانیت زانیارییە کەسییەکان و پیشەییەکانت نوێ بکەیتەوە.</p>
</div>

@if(session('success'))
    <div class="mb-6 p-4 bg-green-50 border border-green-200 text-green-700 rounded-xl">
        {{ session('success') }}
    </div>
@endif

<form id="profile-form" action="{{ route('nurse.profile.update') }}" method="POST" class="bg-white rounded-2xl shadow-sm border border-slate-200/60 p-6 max-w-3xl">
    @csrf
    @method('PUT')
    
    <div class="space-y-6">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <!-- Name -->
            <div>
                <label for="name" class="block text-sm font-medium text-slate-700 mb-2">ناوی تەواو</label>
                <input type="text" id="name" name="name" value="{{ old('name', $user->name) }}" required
                    class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">
                @error('name') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
            </div>

            <!-- Phone -->
            <div>
                <label for="phone" class="block text-sm font-medium text-slate-700 mb-2">ژمارە مۆبایل</label>
                <input type="text" id="phone" name="phone" value="{{ old('phone', $user->phone) }}" required dir="ltr"
                    class="w-full text-right px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">
                @error('phone') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
            </div>
        </div>

        @if($nurse)
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <!-- Specialty -->
            <div>
                <label for="specialty" class="block text-sm font-medium text-slate-700 mb-2">پسپۆڕی</label>
                <input type="text" id="specialty" name="specialty" value="{{ old('specialty', $nurse->specialty) }}"
                    class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">
                @error('specialty') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
            </div>

            <!-- Consultation Fee -->
            <div>
                <label for="consultation_fee" class="block text-sm font-medium text-slate-700 mb-2">نرخی بینین ($)</label>
                <input type="number" step="0.01" id="consultation_fee" name="consultation_fee" value="{{ old('consultation_fee', $nurse->consultation_fee) }}" dir="ltr"
                    class="w-full text-right px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700 hidden">
                <!-- Nurses usually don't have consultation_fee in their table based on schema, wait let me check schema! -->
                @error('consultation_fee') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
            </div>
        </div>

        <!-- Bio -->
        <div>
            <label for="bio" class="block text-sm font-medium text-slate-700 mb-2">کورتەیەک دەربارەی خۆت</label>
            <textarea id="bio" name="bio" rows="4"
                class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">{{ old('bio', $nurse->bio) }}</textarea>
            @error('bio') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
        </div>
        @endif

        <div class="pt-4 border-t border-slate-100 flex justify-end">
            <button id="submit-btn" type="submit" class="px-6 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-xl font-medium transition-colors shadow-lg shadow-blue-500/30 flex items-center justify-center min-w-[140px]">
                پاشەکەوتکردن
            </button>
        </div>
    </div>
</form>

<script>
    document.getElementById('profile-form').addEventListener('submit', function() {
        var btn = document.getElementById('submit-btn');
        btn.disabled = true;
        btn.innerHTML = '<svg class="animate-spin -ml-1 mr-2 h-5 w-5 text-white inline-block" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg> چاوەڕێ بکە...';
        btn.classList.add('opacity-70', 'cursor-not-allowed');
    });
</script>
@endsection
