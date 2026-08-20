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

<form id="profile-form" action="{{ route('nurse.profile.update') }}" method="POST" enctype="multipart/form-data" class="bg-white rounded-2xl shadow-sm border border-slate-200/60 p-6 max-w-3xl">
    @csrf
    @method('PUT')
    
    <div class="space-y-6">
        <!-- Profile Image -->
        <div>
            <label class="block text-sm font-medium text-slate-700 mb-3">وێنەی پڕۆفایل</label>
            <div class="flex items-center gap-5">
                @if($nurse && $nurse->image_path)
                    <img src="{{ asset('storage/' . $nurse->image_path) }}" class="w-20 h-20 rounded-2xl object-cover border-2 border-teal-200">
                @else
                    <div class="w-20 h-20 rounded-2xl bg-gradient-to-br from-teal-500 to-teal-600 flex items-center justify-center">
                        <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/></svg>
                    </div>
                @endif
                <div>
                    <input type="file" id="image" name="image" accept="image/*" class="text-sm text-slate-500 file:mr-4 file:py-2 file:px-4 file:rounded-xl file:border-0 file:text-sm file:font-semibold file:bg-teal-50 file:text-teal-700 hover:file:bg-teal-100 transition-all">
                    <p class="text-xs text-slate-400 mt-1">JPEG, PNG, WebP (حەجمی بەرز: 2MB)</p>
                </div>
            </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <!-- Name -->
            <div>
                <label for="name" class="block text-sm font-medium text-slate-700 mb-2">ناوی تەواو</label>
                <input type="text" id="name" name="name" value="{{ old('name', $user->name) }}" required
                    class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-teal-500/20 focus:border-teal-500 transition-all font-medium text-slate-700">
                @error('name') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
            </div>

            <!-- Phone -->
            <div>
                <label for="phone" class="block text-sm font-medium text-slate-700 mb-2">ژمارە مۆبایل</label>
                <input type="text" id="phone" name="phone" value="{{ old('phone', $user->phone) }}" required dir="ltr"
                    class="w-full text-right px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-teal-500/20 focus:border-teal-500 transition-all font-medium text-slate-700">
                @error('phone') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
            </div>
        </div>

        @if($nurse)
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <!-- Specialty -->
            <div>
                <label for="specialty" class="block text-sm font-medium text-slate-700 mb-2">پسپۆڕی</label>
                <input type="text" id="specialty" name="specialty" value="{{ old('specialty', $nurse->specialty) }}"
                    class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-teal-500/20 focus:border-teal-500 transition-all font-medium text-slate-700">
                @error('specialty') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
            </div>

            <!-- Fee -->
            <div>
                <label for="fee" class="block text-sm font-medium text-slate-700 mb-2">نرخی خزمەتگوزاری (بە دینار)</label>
                <input type="number" step="1" id="fee" name="fee" value="{{ old('fee', $nurse->fee) }}" dir="ltr" placeholder="15000"
                    class="w-full text-right px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-teal-500/20 focus:border-teal-500 transition-all font-medium text-slate-700">
                @error('fee') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
            </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <!-- City -->
            <div>
                <label for="city" class="block text-sm font-medium text-slate-700 mb-2">شار</label>
                <select id="city" name="city"
                    class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-teal-500/20 focus:border-teal-500 transition-all font-medium text-slate-700">
                    <option value="">شارەکەت هەڵبژێرە</option>
                    <option value="Erbil" {{ old('city', $nurse->city) == 'Erbil' ? 'selected' : '' }}>هەولێر</option>
                    <option value="Sulaymaniyah" {{ old('city', $nurse->city) == 'Sulaymaniyah' ? 'selected' : '' }}>سلێمانی</option>
                    <option value="Duhok" {{ old('city', $nurse->city) == 'Duhok' ? 'selected' : '' }}>دهۆک</option>
                    <option value="Kirkuk" {{ old('city', $nurse->city) == 'Kirkuk' ? 'selected' : '' }}>کەرکووک</option>
                    <option value="Halabja" {{ old('city', $nurse->city) == 'Halabja' ? 'selected' : '' }}>هەڵەبجە</option>
                </select>
                @error('city') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
            </div>

            <!-- Service Type -->
            <div>
                <label for="service_type" class="block text-sm font-medium text-slate-700 mb-2">جۆری خزمەتگوزاری</label>
                <select id="service_type" name="service_type"
                    class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-teal-500/20 focus:border-teal-500 transition-all font-medium text-slate-700">
                    <option value="home_nursing" {{ old('service_type', $nurse->service_type) == 'home_nursing' ? 'selected' : '' }}>پەرستاری ماڵ</option>
                    <option value="clinic" {{ old('service_type', $nurse->service_type) == 'clinic' ? 'selected' : '' }}>کلینیک</option>
                    <option value="hospital" {{ old('service_type', $nurse->service_type) == 'hospital' ? 'selected' : '' }}>نەخۆشخانە</option>
                </select>
                @error('service_type') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
            </div>
        </div>

        <!-- Offered Services -->
        <div>
            <label class="block text-sm font-medium text-slate-700 mb-3">خزمەتگوزارییەکانی پێشکەشکراو</label>
            <p class="text-xs text-slate-400 mb-3">ئەو خزمەتگوزارییانە هەڵبژێرە کە تۆ دەیانپێشکەشدەکەیت. ئەمانە لە ئەپەکە نیشان دەدرێن.</p>
            <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
                @php
                    $currentServices = old('offered_services', $nurse->offered_services ?? []);
                    $serviceOptions = [
                        ['id' => 'injection', 'label' => 'دەرزی', 'icon' => '💉'],
                        ['id' => 'cannula', 'label' => 'کانیۆلا', 'icon' => '🩸'],
                        ['id' => 'dressing', 'label' => 'پانسیمان', 'icon' => '🩹'],
                        ['id' => 'checkup', 'label' => 'چاودێری', 'icon' => '❤️'],
                    ];
                @endphp
                @foreach($serviceOptions as $option)
                    <label class="relative cursor-pointer">
                        <input type="checkbox" name="offered_services[]" value="{{ $option['id'] }}"
                            {{ in_array($option['id'], $currentServices ?? []) ? 'checked' : '' }}
                            class="peer sr-only">
                        <div class="p-3 rounded-xl border-2 border-slate-200 bg-slate-50 text-center transition-all peer-checked:border-teal-500 peer-checked:bg-teal-50 peer-checked:shadow-lg peer-checked:shadow-teal-500/10 hover:bg-slate-100">
                            <span class="text-2xl block mb-1">{{ $option['icon'] }}</span>
                            <span class="text-sm font-bold text-slate-700 peer-checked:text-teal-700">{{ $option['label'] }}</span>
                        </div>
                    </label>
                @endforeach
            </div>
        </div>

        <!-- Availability Toggle -->
        <div class="flex items-center justify-between p-4 bg-slate-50 rounded-xl border border-slate-200">
            <div>
                <p class="font-bold text-slate-700 text-sm">ئامادەبوون بۆ وەرگرتنی داواکاری</p>
                <p class="text-xs text-slate-500 mt-1">کاتێک چالاک بێت، نەخۆشەکان دەتوانن لە ئەپەکە داواکاریت بۆ بنێرن.</p>
            </div>
            <label class="relative inline-flex items-center cursor-pointer">
                <input type="hidden" name="is_available" value="0">
                <input type="checkbox" name="is_available" value="1" {{ old('is_available', $nurse->is_available) ? 'checked' : '' }} class="sr-only peer">
                <div class="w-11 h-6 bg-slate-300 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-teal-300/20 rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-slate-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-teal-500"></div>
            </label>
        </div>

        <!-- Bio -->
        <div>
            <label for="bio" class="block text-sm font-medium text-slate-700 mb-2">کورتەیەک دەربارەی خۆت</label>
            <textarea id="bio" name="bio" rows="4"
                class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-teal-500/20 focus:border-teal-500 transition-all font-medium text-slate-700">{{ old('bio', $nurse->bio) }}</textarea>
            @error('bio') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
        </div>
        @endif

        <div class="pt-4 border-t border-slate-100 flex justify-end">
            <button id="submit-btn" type="submit" class="px-6 py-2.5 bg-teal-600 hover:bg-teal-700 text-white rounded-xl font-medium transition-colors shadow-lg shadow-teal-500/30 flex items-center justify-center min-w-[140px]">
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
