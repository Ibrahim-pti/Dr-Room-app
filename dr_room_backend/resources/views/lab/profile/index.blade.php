@extends('lab.layouts.app')
@section('header_title', 'ڕێکخستنی پرۆفایل')

@section('content')
<div class="mb-6">
    <h2 class="text-xl font-bold text-slate-800">ڕێکخستنەکانی پرۆفایل</h2>
    <p class="text-sm text-slate-500 mt-1">لێرە دەتوانیت زانیارییە کەسییەکان و پیشەییەکانی تاقیگە نوێ بکەیتەوە.</p>
</div>

@if(session('success'))
    <div class="mb-6 p-4 bg-green-50 border border-green-200 text-green-700 rounded-xl">
        {{ session('success') }}
    </div>
@endif

@if(session('error'))
    <div class="mb-6 p-4 bg-red-50 border border-red-200 text-red-700 rounded-xl font-medium">
        {{ session('error') }}
    </div>
@endif

<form id="profile-form" action="{{ route('lab.profile.update') }}" method="POST" enctype="multipart/form-data" class="bg-white rounded-2xl shadow-sm border border-slate-200/60 p-6 max-w-4xl">
    @csrf
    @method('PUT')
    
    <div class="flex justify-between items-center mb-6">
        <h3 class="text-lg font-bold text-slate-800">زانیارییەکان</h3>
        <button type="button" onclick="translateAll()" id="translateBtn" class="flex items-center gap-2 px-4 py-2 bg-blue-50 text-blue-600 rounded-xl hover:bg-blue-100 transition-colors text-sm font-medium">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" width="18" height="18"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5h12M9 3v2m1.048 9.5A18.022 18.022 0 016.412 9m6.088 9h7M11 21l5-10 5 10M12.751 5C11.783 10.77 8.07 15.61 3 18.129"/></svg>
            <span>وەرگێڕانی ئۆتۆماتیکی (Translate All)</span>
        </button>
    </div>

    <div class="space-y-6">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <!-- Name -->
            <div class="space-y-4">
                <div>
                    <label for="name" class="block text-sm font-medium text-slate-700 mb-2">ناوی تاقیگە (کوردی) <span class="text-red-500">*</span></label>
                    <input type="text" id="name" name="name" value="{{ old('name', $user->name) }}" required
                        class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">
                    @error('name') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
                </div>
                <div>
                    <label for="name_ar" class="block text-sm font-medium text-slate-700 mb-2">ناوی تاقیگە (عەرەبی)</label>
                    <input type="text" id="name_ar" name="name_ar" value="{{ old('name_ar', $user->name_ar) }}" dir="rtl"
                        class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">
                </div>
                <div>
                    <label for="name_en" class="block text-sm font-medium text-slate-700 mb-2">ناوی تاقیگە (ئینگلیزی)</label>
                    <input type="text" id="name_en" name="name_en" value="{{ old('name_en', $user->name_en) }}" dir="ltr"
                        class="w-full text-left px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">
                </div>
            </div>

            <!-- Contact & Settings -->
            <div class="space-y-4">
                <div>
                    <label for="phone" class="block text-sm font-medium text-slate-700 mb-2">ژمارە مۆبایل <span class="text-red-500">*</span></label>
                    <input type="text" id="phone" name="phone" value="{{ old('phone', $user->phone) }}" required dir="ltr"
                        class="w-full text-right px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">
                    @error('phone') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
                </div>
                <div>
                    <label for="city" class="block text-sm font-medium text-slate-700 mb-2">شار</label>
                    <select id="city" name="city" class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">
                        <option value="Erbil" {{ old('city', $lab?->city) == 'Erbil' ? 'selected' : '' }}>هەولێر (Erbil)</option>
                        <option value="Sulaymaniyah" {{ old('city', $lab?->city) == 'Sulaymaniyah' ? 'selected' : '' }}>سلێمانی (Sulaymaniyah)</option>
                        <option value="Duhok" {{ old('city', $lab?->city) == 'Duhok' ? 'selected' : '' }}>دهۆک (Duhok)</option>
                        <option value="Kirkuk" {{ old('city', $lab?->city) == 'Kirkuk' ? 'selected' : '' }}>کەرکووک (Kirkuk)</option>
                        <option value="Halabja" {{ old('city', $lab?->city) == 'Halabja' ? 'selected' : '' }}>هەڵەبجە (Halabja)</option>
                    </select>
                </div>
            </div>
        </div>

        <!-- Location / Address -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 pt-4 border-t border-slate-100">
            <div>
                <label for="location" class="block text-sm font-medium text-slate-700 mb-2">ناونیشان (کوردی)</label>
                <input type="text" id="location" name="location" value="{{ old('location', $lab?->location) }}"
                    placeholder="نموونە: هەولێر - شەقامی پزیشکان"
                    class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">
            </div>
            <div>
                <label for="location_ar" class="block text-sm font-medium text-slate-700 mb-2">ناونیشان (عەرەبی)</label>
                <input type="text" id="location_ar" name="location_ar" value="{{ old('location_ar', $lab?->location_ar) }}" dir="rtl"
                    placeholder="أربيل - شارع الأطباء"
                    class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">
            </div>
            <div>
                <label for="location_en" class="block text-sm font-medium text-slate-700 mb-2">ناونیشان (ئینگلیزی)</label>
                <input type="text" id="location_en" name="location_en" value="{{ old('location_en', $lab?->location_en) }}" dir="ltr"
                    placeholder="Erbil - Doctors Street"
                    class="w-full text-left px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">
            </div>
        </div>

        <!-- Hours, Discount, YouTube -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 pt-4 border-t border-slate-100">
            <div>
                <label for="opening_hours" class="block text-sm font-medium text-slate-700 mb-2">کاتەکانی دەوام (Opening Hours)</label>
                <input type="text" id="opening_hours" name="opening_hours" value="{{ old('opening_hours', $lab?->opening_hours ?? '08:00 AM - 10:00 PM') }}"
                    placeholder="08:00 AM - 10:00 PM" dir="ltr"
                    class="w-full text-left px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">
            </div>
            <div>
                <label for="discount" class="block text-sm font-medium text-slate-700 mb-2">داشکاندنی گشتی (%)</label>
                <input type="number" id="discount" name="discount" min="0" max="100" value="{{ old('discount', $lab?->discount) }}"
                    placeholder="نموونە: 20" dir="ltr"
                    class="w-full text-left px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">
            </div>
            <div>
                <label for="youtube_url" class="block text-sm font-medium text-slate-700 mb-2">لینکی ڤیدیۆی یوتوب (ناساندن)</label>
                <input type="url" id="youtube_url" name="youtube_url" value="{{ old('youtube_url', $lab?->youtube_url) }}"
                    placeholder="https://www.youtube.com/watch?v=..." dir="ltr"
                    class="w-full text-left px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">
            </div>
        </div>

        <div class="grid grid-cols-1 gap-6 pt-4 border-t border-slate-100">
            <!-- About Us -->
            <div class="space-y-4">
                <div>
                    <label for="about_us" class="block text-sm font-medium text-slate-700 mb-2">دەربارەی تاقیگە (کوردی) <span class="text-red-500">*</span></label>
                    <textarea id="about_us" name="about_us" rows="2" required
                        class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">{{ old('about_us', $lab?->about_us) }}</textarea>
                    @error('about_us') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
                </div>
                <div>
                    <label for="about_us_ar" class="block text-sm font-medium text-slate-700 mb-2">دەربارەی تاقیگە (عەرەبی)</label>
                    <textarea id="about_us_ar" name="about_us_ar" rows="2" dir="rtl"
                        class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">{{ old('about_us_ar', $lab?->about_us_ar) }}</textarea>
                </div>
                <div>
                    <label for="about_us_en" class="block text-sm font-medium text-slate-700 mb-2">دەربارەی تاقیگە (ئینگلیزی)</label>
                    <textarea id="about_us_en" name="about_us_en" rows="2" dir="ltr"
                        class="w-full text-left px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">{{ old('about_us_en', $lab?->about_us_en) }}</textarea>
                </div>
            </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6 pt-4 border-t border-slate-100">
            <!-- Profile Image -->
            <div>
                <label for="image" class="block text-sm font-medium text-slate-700 mb-2">وێنەی تاقیگە یان لۆگۆ</label>
                <div class="flex items-center gap-4">
                    @if($lab && $lab->image_path)
                        <img src="{{ asset($lab->image_path) }}" alt="Lab Image" class="w-16 h-16 rounded-xl object-cover border border-slate-200 shadow-sm">
                    @endif
                    <input type="file" id="image" name="image" accept="image/*"
                        class="block w-full text-sm text-slate-500 file:mr-4 file:py-2.5 file:px-4 file:rounded-xl file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100 transition-all">
                </div>
                @error('image') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
            </div>
            
            <!-- Home Collection -->
            <div>
                <label class="block text-sm font-medium text-slate-700 mb-3">خزمەتگوزارییەکان</label>
                <label class="flex items-center gap-3 p-4 bg-slate-50 border border-slate-200 rounded-xl cursor-pointer hover:bg-slate-100 transition-colors">
                    <input type="checkbox" name="home_sample_collection" value="1" {{ old('home_sample_collection', $lab?->home_sample_collection) ? 'checked' : '' }}
                        class="w-5 h-5 text-blue-600 border-slate-300 rounded focus:ring-blue-500">
                    <span class="text-sm font-medium text-slate-700">بەردەستبوونی وەرگرتنی نموونەی خوێن لە ماڵەوە</span>
                </label>
            </div>
        </div>

        <!-- Map -->
        <div class="border border-slate-200 rounded-xl p-4 bg-slate-50/50 mt-6">
            <h3 class="text-sm font-semibold text-slate-800 mb-4">شوێنی سەر نەخشە</h3>
            <input type="hidden" id="latitude" name="latitude" value="{{ old('latitude', $lab?->latitude) }}">
            <input type="hidden" id="longitude" name="longitude" value="{{ old('longitude', $lab?->longitude) }}">
            <div id="map" class="w-full h-72 rounded-xl border border-slate-200 z-0" style="min-height: 300px;"></div>
            <p class="text-xs text-slate-500 mt-2">کرتە لەسەر نەخشەکە بکە بۆ دیاریکردنی شوێنی تاقیگە.</p>

            <div class="flex flex-wrap items-center gap-3 mt-3">
                <button type="button" onclick="useMyLocation()"
                    class="flex items-center gap-2 px-4 py-2 bg-blue-50 text-blue-600 rounded-xl hover:bg-blue-100 transition-colors text-sm font-medium">
                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" width="16" height="16"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a2 2 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"/></svg>
                    شوێنی ئێستام
                </button>
                <button type="button" onclick="clearLocation()"
                    class="px-4 py-2 bg-slate-50 text-slate-500 rounded-xl hover:bg-slate-100 transition-colors text-sm font-medium">
                    سڕینەوەی شوێن
                </button>
                <span id="coords_label" class="text-xs text-slate-400" dir="ltr"></span>
            </div>
        </div>

        <!-- Submit -->
        <div class="pt-6 border-t border-slate-100 flex items-center gap-4">
            <button type="submit" id="submitBtn" class="px-8 py-3 bg-blue-600 hover:bg-blue-700 text-white rounded-xl font-bold transition-colors shadow-lg shadow-blue-200">
                پاشەکەوتکردن
            </button>
        </div>
    </div>
</form>
@endsection

@section('scripts')
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=" crossorigin="" />
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js" integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=" crossorigin=""></script>

<script>
let map, marker;
const defaultLat = 36.1911; // Erbil
const defaultLng = 44.0092;

function initLabMap() {
    const latInput = document.getElementById('latitude');
    const lngInput = document.getElementById('longitude');
    
    let curLat = parseFloat(latInput.value) || defaultLat;
    let curLng = parseFloat(lngInput.value) || defaultLng;
    const hasInitialCoords = Boolean(latInput.value && lngInput.value);

    map = L.map('map').setView([curLat, curLng], hasInitialCoords ? 15 : 12);

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; OpenStreetMap contributors'
    }).addTo(map);

    if (hasInitialCoords) {
        setMarker(curLat, curLng);
    }

    map.on('click', function(e) {
        setMarker(e.latlng.lat, e.latlng.lng);
    });
    
    setTimeout(() => map.invalidateSize(), 500);
}

function setMarker(lat, lng) {
    if (marker) {
        marker.setLatLng([lat, lng]);
    } else {
        marker = L.marker([lat, lng], { draggable: true }).addTo(map);
        marker.on('dragend', function(e) {
            const pos = e.target.getLatLng();
            updateCoords(pos.lat, pos.lng);
        });
    }
    updateCoords(lat, lng);
}

function updateCoords(lat, lng) {
    document.getElementById('latitude').value = lat.toFixed(6);
    document.getElementById('longitude').value = lng.toFixed(6);
    const label = document.getElementById('coords_label');
    if (label) {
        label.textContent = `${lat.toFixed(4)}, ${lng.toFixed(4)}`;
    }
}

function clearLocation() {
    if (marker) {
        map.removeLayer(marker);
        marker = null;
    }
    document.getElementById('latitude').value = '';
    document.getElementById('longitude').value = '';
    const label = document.getElementById('coords_label');
    if (label) {
        label.textContent = '';
    }
}

function useMyLocation() {
    if (!navigator.geolocation) {
        alert('گەڕان بەدوای شوێن لە وێبگەڕەکەت پشتگیری ناکرێت.');
        return;
    }
    navigator.geolocation.getCurrentPosition(
        function(pos) {
            const lat = pos.coords.latitude;
            const lng = pos.coords.longitude;
            map.setView([lat, lng], 15);
            setMarker(lat, lng);
        },
        function() {
            alert('نەتوانرا شوێنی ئێستات بدۆزرێتەوە.');
        },
        { enableHighAccuracy: true }
    );
}

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initLabMap);
} else {
    initLabMap();
}

async function translateAll() {
    const btn = document.getElementById('translateBtn');
    const originalText = btn.innerHTML;
    
    try {
        btn.innerHTML = '<svg class="animate-spin h-5 w-5 mr-2" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg> <span>چاوەڕێبە...</span>';
        btn.disabled = true;

        const fieldsToTranslate = [
            { source: 'name', ar: 'name_ar', en: 'name_en' },
            { source: 'location', ar: 'location_ar', en: 'location_en' },
            { source: 'about_us', ar: 'about_us_ar', en: 'about_us_en' }
        ];

        for (const field of fieldsToTranslate) {
            const sourceEl = document.getElementById(field.source);
            const arEl = document.getElementById(field.ar);
            const enEl = document.getElementById(field.en);

            if (sourceEl && sourceEl.value.trim()) {
                const res = await fetch('/api/translate', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                        'X-CSRF-TOKEN': '{{ csrf_token() }}'
                    },
                    body: JSON.stringify({ text: sourceEl.value })
                });
                
                const data = await res.json();
                
                if (data.success && data.translations) {
                    if (arEl && !arEl.value.trim()) {
                        arEl.value = data.translations.ar;
                    }
                    if (enEl && !enEl.value.trim()) {
                        enEl.value = data.translations.en;
                    }
                }
            }
        }
    } catch (e) {
        console.error(e);
        alert('هەڵەیەک ڕوویدا لە وەرگێڕانەکە');
    } finally {
        btn.innerHTML = originalText;
        btn.disabled = false;
    }
}
</script>
@endsection
