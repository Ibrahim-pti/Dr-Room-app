@extends('pharmacy.layouts.app')
@section('header_title', 'پرۆفایلی دەرمانخانە')

@section('content')
<div class="fade-up max-w-5xl">
    <div class="mb-6">
        <h2 class="text-xl font-bold text-slate-800">پرۆفایلی دەرمانخانە</h2>
        <p class="text-sm text-slate-500 mt-1">زانیارییە سەرەکییەکانی دەرمانخانەکەت لێرە نوێ بکەرەوە بۆ ئەوەی لە ئەپەکە پیشانبدرێت.</p>
    </div>
    
    @if(session('success'))
        <div class="mb-6 p-4 bg-green-50 border border-green-200 text-green-700 rounded-xl font-medium">
            {{ session('success') }}
        </div>
    @endif

    @if ($errors->any())
        <div class="mb-6 p-4 bg-red-50 border border-red-200 text-red-700 rounded-xl font-medium">
            <ul class="list-disc list-inside space-y-1">
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
        
        $galleryImages = [];
        if ($pharmacy && !empty($pharmacy->gallery_images)) {
            $raw = is_array($pharmacy->gallery_images) ? $pharmacy->gallery_images : json_decode($pharmacy->gallery_images, true);
            if (is_array($raw)) {
                $galleryImages = $raw;
            }
        }
    @endphp

    <div class="bg-white rounded-2xl shadow-sm border border-slate-200/60 p-6 md:p-8">
        <form id="profile-form" action="{{ route('pharmacy.profile.update') }}" method="POST" enctype="multipart/form-data">
            @csrf
            
            <div class="flex flex-wrap justify-between items-center gap-4 mb-6 pb-4 border-b border-slate-100">
                <h3 class="text-lg font-bold text-slate-800">زانیارییە سەرەکییەکان</h3>
                <button type="button" onclick="translateAll()" id="translateBtn" class="flex items-center gap-2 px-4 py-2 bg-emerald-50 text-emerald-700 border border-emerald-200 rounded-xl hover:bg-emerald-100 transition-colors text-sm font-bold shadow-sm">
                    <svg class="w-4 h-4 text-emerald-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5h12M9 3v2m1.048 9.5A18.022 18.022 0 016.412 9m6.088 9h7M11 21l5-10 5 10M12.751 5C11.783 10.77 8.07 15.61 3 18.129"/></svg>
                    <span>وەرگێڕانی ئۆتۆماتیکی (Translate All)</span>
                </button>
            </div>

            <!-- Image & Header -->
            <div class="flex items-center gap-5 mb-8 pb-6 border-b border-slate-100">
                @if($profileImg)
                    <img src="{{ $profileImg }}" alt="{{ $user->name }}" class="w-20 h-20 rounded-2xl object-cover border-2 border-emerald-600 shadow-sm">
                @else
                    <div class="w-20 h-20 rounded-2xl bg-emerald-50 text-emerald-600 flex items-center justify-center text-3xl font-bold border border-emerald-200">
                        {{ mb_substr($user->name, 0, 1) }}
                    </div>
                @endif
                <div>
                    <label class="block font-bold text-slate-700 mb-1.5 text-sm">گۆڕینی لۆگۆ / وێنەی سەرەکی</label>
                    <input type="file" name="profile_image" accept="image/*" class="text-sm text-slate-500 file:mr-4 file:py-2 file:px-4 file:rounded-xl file:border-0 file:text-xs file:font-bold file:bg-emerald-50 file:text-emerald-700 hover:file:bg-emerald-100 cursor-pointer">
                </div>
            </div>

            <!-- Name (Kurdish, Arabic, English) -->
            <div class="space-y-4 mb-6">
                <h4 class="text-sm font-bold text-slate-700">ناوی دەرمانخانە بە سێ زمان</h4>
                <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div>
                        <label for="name" class="block text-xs font-bold text-slate-600 mb-1.5">ناوی دەرمانخانە (کوردی) <span class="text-red-500">*</span></label>
                        <input type="text" id="name" name="name" value="{{ old('name', $user->name) }}" required
                            class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 text-sm font-medium text-slate-700">
                    </div>
                    <div>
                        <label for="name_ar" class="block text-xs font-bold text-slate-600 mb-1.5">ناوی دەرمانخانە (عەرەبی)</label>
                        <input type="text" id="name_ar" name="name_ar" value="{{ old('name_ar', $user->name_ar) }}" dir="rtl"
                            class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 text-sm font-medium text-slate-700">
                    </div>
                    <div>
                        <label for="name_en" class="block text-xs font-bold text-slate-600 mb-1.5">ناوی دەرمانخانە (ئینگلیزی)</label>
                        <input type="text" id="name_en" name="name_en" value="{{ old('name_en', $user->name_en) }}" dir="ltr"
                            class="w-full text-left px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 text-sm font-medium text-slate-700">
                    </div>
                </div>
            </div>

            <!-- Phone, City, Delivery Fee & Time -->
            <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6 pt-4 border-t border-slate-100">
                <div>
                    <label for="phone" class="block text-xs font-bold text-slate-600 mb-1.5">ژمارەی پەیوەندی <span class="text-red-500">*</span></label>
                    <input type="text" id="phone" name="phone" value="{{ old('phone', $user->phone ?? ($pharmacy ? $pharmacy->phone : '')) }}" required dir="ltr"
                        class="w-full text-right px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 text-sm font-medium text-slate-700">
                </div>

                <div>
                    <label for="city" class="block text-xs font-bold text-slate-600 mb-1.5">شار</label>
                    <select id="city" name="city" class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 text-sm font-medium text-slate-700">
                        <option value="هەولێر" {{ old('city', $pharmacy?->city) == 'هەولێر' || old('city', $pharmacy?->city) == 'Erbil' ? 'selected' : '' }}>هەولێر (Erbil)</option>
                        <option value="سلێمانی" {{ old('city', $pharmacy?->city) == 'سلێمانی' || old('city', $pharmacy?->city) == 'Sulaymaniyah' ? 'selected' : '' }}>سلێمانی (Sulaymaniyah)</option>
                        <option value="دهۆک" {{ old('city', $pharmacy?->city) == 'دهۆک' || old('city', $pharmacy?->city) == 'Duhok' ? 'selected' : '' }}>دهۆک (Duhok)</option>
                        <option value="کەرکووک" {{ old('city', $pharmacy?->city) == 'کەرکووک' || old('city', $pharmacy?->city) == 'Kirkuk' ? 'selected' : '' }}>کەرکووک (Kirkuk)</option>
                        <option value="هەڵەبجە" {{ old('city', $pharmacy?->city) == 'هەڵەبجە' || old('city', $pharmacy?->city) == 'Halabja' ? 'selected' : '' }}>هەڵەبجە (Halabja)</option>
                    </select>
                </div>

                <div>
                    <label for="delivery_fee" class="block text-xs font-bold text-slate-600 mb-1.5">کرێی گەیاندن (دینار)</label>
                    <input type="number" id="delivery_fee" name="delivery_fee" value="{{ old('delivery_fee', $pharmacy ? (int)$pharmacy->delivery_fee : 3000) }}" min="0" dir="ltr"
                        class="w-full text-right px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 text-sm font-medium text-slate-700">
                </div>

                <div>
                    <label for="delivery_time" class="block text-xs font-bold text-slate-600 mb-1.5">کاتی خەمڵێنراوی گەیاندن</label>
                    <input type="text" id="delivery_time" name="delivery_time" value="{{ old('delivery_time', $pharmacy ? $pharmacy->delivery_time : '۲۰-۳۰ خولەک') }}" placeholder="۲۰-۳۰ خولەک"
                        class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 text-sm font-medium text-slate-700">
                </div>
            </div>

            <!-- Facebook & Email -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6 pt-4 border-t border-slate-100">
                <div>
                    <label for="facebook_url" class="block text-xs font-bold text-slate-600 mb-1.5">بەستەری فەیسبووک / پەیج</label>
                    <input type="text" id="facebook_url" name="facebook_url" value="{{ old('facebook_url', $pharmacy ? $pharmacy->facebook_url : '') }}" placeholder="https://facebook.com/..." dir="ltr"
                        class="w-full text-left px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 text-sm font-medium text-slate-700">
                </div>

                <div>
                    <label class="block text-xs font-bold text-slate-600 mb-1.5">ئیمەیڵی چوونەژوورەوە (ناگۆڕدرێت)</label>
                    <input type="email" disabled value="{{ $user->email }}" dir="ltr"
                        class="w-full text-left px-4 py-2.5 bg-slate-100 border border-slate-200 rounded-xl text-sm font-medium text-slate-500 cursor-not-allowed">
                </div>
            </div>

            <!-- Address (Kurdish, Arabic, English) -->
            <div class="space-y-4 mb-6 pt-4 border-t border-slate-100">
                <h4 class="text-sm font-bold text-slate-700">ناونیشانی تەواوی دەرمانخانە</h4>
                <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div>
                        <label for="location" class="block text-xs font-bold text-slate-600 mb-1.5">ناونیشان (کوردی)</label>
                        <input type="text" id="location" name="location" value="{{ old('location', $pharmacy?->location) }}" placeholder="شەقامی ١٠٠ مەتری - نزیک نەخۆشخانەی ڕزگاری"
                            class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 text-sm font-medium text-slate-700">
                    </div>
                    <div>
                        <label for="location_ar" class="block text-xs font-bold text-slate-600 mb-1.5">ناونیشان (عەرەبی)</label>
                        <input type="text" id="location_ar" name="location_ar" value="{{ old('location_ar', $pharmacy?->location_ar) }}" dir="rtl" placeholder="شارع ۱۰۰ متري - قرب مستشفى رزكاري"
                            class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 text-sm font-medium text-slate-700">
                    </div>
                    <div>
                        <label for="location_en" class="block text-xs font-bold text-slate-600 mb-1.5">ناونیشان (ئینگلیزی)</label>
                        <input type="text" id="location_en" name="location_en" value="{{ old('location_en', $pharmacy?->location_en) }}" dir="ltr" placeholder="100m Street - Near Rizgary Hospital"
                            class="w-full text-left px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 text-sm font-medium text-slate-700">
                    </div>
                </div>
            </div>

            <!-- About / Bio (Kurdish, Arabic, English) -->
            <div class="space-y-4 mb-6 pt-4 border-t border-slate-100">
                <h4 class="text-sm font-bold text-slate-700">دەربارەی دەرمانخانە (پێناسە)</h4>
                <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div>
                        <label for="bio" class="block text-xs font-bold text-slate-600 mb-1.5">دەربارە (کوردی)</label>
                        <textarea id="bio" name="bio" rows="3" placeholder="کورتەیەک دەربارەی خزمەتگوزارییەکان و دەرمانەکانی دەرمانخانەکەت..."
                            class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 text-sm font-medium text-slate-700 resize-y">{{ old('bio', $pharmacy?->bio) }}</textarea>
                    </div>
                    <div>
                        <label for="bio_ar" class="block text-xs font-bold text-slate-600 mb-1.5">دەربارە (عەرەبی)</label>
                        <textarea id="bio_ar" name="bio_ar" rows="3" dir="rtl" placeholder="نبذة عن خدمات وأدوية الصيدلية..."
                            class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 text-sm font-medium text-slate-700 resize-y">{{ old('bio_ar', $pharmacy?->bio_ar) }}</textarea>
                    </div>
                    <div>
                        <label for="bio_en" class="block text-xs font-bold text-slate-600 mb-1.5">دەربارە (ئینگلیزی)</label>
                        <textarea id="bio_en" name="bio_en" rows="3" dir="ltr" placeholder="About the pharmacy services and medications..."
                            class="w-full text-left px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 text-sm font-medium text-slate-700 resize-y">{{ old('bio_en', $pharmacy?->bio_en) }}</textarea>
                    </div>
                </div>
            </div>

            <!-- Carousel Gallery Images Section -->
            <div class="border border-slate-200 rounded-2xl p-5 bg-slate-50/50 mb-6 pt-4">
                <div class="flex items-center justify-between mb-3">
                    <div>
                        <h4 class="text-sm font-bold text-slate-800">وێنەکانی کارسۆلی سەرەوەی ئەپ (App Carousel Gallery)</h4>
                        <p class="text-xs text-slate-500 mt-0.5">ئەو وێنانەی لە سەرەوەی لاپەڕەی دەرمانخانەکەت لە ئەپەکەدا دەسوڕێنەوە.</p>
                    </div>
                </div>

                <!-- Current Gallery Grid -->
                @if(count($galleryImages) > 0)
                    <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4 mb-4">
                        @foreach($galleryImages as $index => $img)
                            @php
                                $imgUrl = str_starts_with($img, 'http') ? $img : asset('storage/' . $img);
                            @endphp
                            <div class="relative group rounded-xl overflow-hidden border border-slate-200 bg-white shadow-sm aspect-video">
                                <img src="{{ $imgUrl }}" alt="Carousel Image {{ $index + 1 }}" class="w-full h-full object-cover">
                                <button type="button" onclick="deleteGalleryImage('{{ $img }}')" class="absolute top-2 right-2 p-1.5 bg-red-600/90 hover:bg-red-700 text-white rounded-lg opacity-90 group-hover:opacity-100 transition-all shadow-md" title="سڕینەوەی وێنە">
                                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
                                </button>
                                <span class="absolute bottom-2 left-2 px-2 py-0.5 bg-black/60 text-white text-[10px] font-bold rounded-md">#{{ $index + 1 }}</span>
                            </div>
                        @endforeach
                    </div>
                @else
                    <div class="text-center py-6 border-2 border-dashed border-slate-200 rounded-xl bg-white mb-4">
                        <svg class="w-10 h-10 text-slate-300 mx-auto mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
                        <p class="text-xs text-slate-400 font-medium">هیچ وێنەیەکی تایبەت بە کارسۆل زیادنەکراوە.</p>
                    </div>
                @endif

                <!-- Upload New Images -->
                <div>
                    <label class="block text-xs font-bold text-slate-700 mb-1.5">زیادکردنی وێنەی نوێ بۆ کارسۆل (دەتوانیت چەند وێنەیەک بەیەکەوە هەڵبژێریت)</label>
                    <input type="file" name="gallery_images[]" multiple accept="image/*" class="w-full text-sm text-slate-500 file:mr-4 file:py-2 file:px-4 file:rounded-xl file:border-0 file:text-xs file:font-bold file:bg-emerald-50 file:text-emerald-700 hover:file:bg-emerald-100 cursor-pointer">
                </div>
            </div>

            <!-- Map Picker Section (Leaflet Interactive Map) -->
            <div class="border border-slate-200 rounded-2xl p-5 bg-slate-50/50 mb-6 pt-4">
                <div class="mb-3">
                    <h4 class="text-sm font-bold text-slate-800">دیاریکردنی شوێن لەسەر نەخشە (Map Location)</h4>
                    <p class="text-xs text-slate-500 mt-0.5">کرتە لەسەر نەخشەکە بکە یان نیشاندەرەکە ڕابکێشە بۆ دیاریکردنی شوێنی دەرمانخانە.</p>
                </div>

                <input type="hidden" id="latitude" name="latitude" value="{{ old('latitude', $pharmacy?->latitude) }}">
                <input type="hidden" id="longitude" name="longitude" value="{{ old('longitude', $pharmacy?->longitude) }}">
                
                <div id="map" class="w-full rounded-xl border border-slate-200 z-0 shadow-inner" style="height: 300px; min-height: 300px;"></div>

                <div class="flex flex-wrap items-center gap-3 mt-3">
                    <button type="button" onclick="useMyLocation()"
                        class="flex items-center gap-2 px-4 py-2 bg-emerald-600 text-white rounded-xl hover:bg-emerald-700 transition-colors text-xs font-bold shadow-sm shadow-emerald-200">
                        <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" class="w-4 h-4"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a2 2 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"/></svg>
                        <span>شوێنی ئێستام دیاری بکە</span>
                    </button>
                    <button type="button" onclick="clearLocation()"
                        class="px-4 py-2 bg-white text-slate-600 border border-slate-200 rounded-xl hover:bg-slate-50 transition-colors text-xs font-bold">
                        سڕینەوەی شوێن
                    </button>
                </div>
            </div>

            <!-- Open / Closed Switch -->
            <div class="mb-8 p-4 bg-emerald-50/60 border border-emerald-100 rounded-xl flex items-center gap-3">
                <input type="checkbox" name="is_open" id="is_open" value="1" {{ old('is_open', $pharmacy ? $pharmacy->is_open : true) ? 'checked' : '' }} class="w-5 h-5 text-emerald-600 border-slate-300 rounded focus:ring-emerald-500 cursor-pointer">
                <label for="is_open" class="font-bold text-slate-700 text-sm cursor-pointer select-none">دەرمانخانەکە لە ئێستادا کراوەیە بۆ وەرگرتنی داواکاری و کڕین (Open Now)</label>
            </div>

            <!-- Submit Button -->
            <div class="flex justify-end pt-4 border-t border-slate-100">
                <button type="submit" id="submitBtn" class="px-8 py-3 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl font-bold transition-all shadow-lg shadow-emerald-200 flex items-center gap-2">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
                    <span>پاشەکەوتکردنی گۆڕانکارییەکان</span>
                </button>
            </div>
        </form>

        <!-- Hidden Form for Deleting a Single Gallery Image -->
        <form id="delete-gallery-form" action="{{ route('pharmacy.profile.gallery.delete') }}" method="POST" style="display:none;">
            @csrf
            <input type="hidden" name="image" id="delete-image-input">
        </form>
    </div>
</div>
@endsection

@section('scripts')
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=" crossorigin="" />
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js" integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=" crossorigin=""></script>

<script>
let map, marker;
const defaultLat = 36.1911; // Erbil
const defaultLng = 44.0092;

function initPharmacyMap() {
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
}

function clearLocation() {
    if (marker) {
        map.removeLayer(marker);
        marker = null;
    }
    document.getElementById('latitude').value = '';
    document.getElementById('longitude').value = '';
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

function deleteGalleryImage(imagePath) {
    if (confirm('ئایا دڵنیایت لە سڕینەوەی ئەم وێنەیە لە کارسۆل؟')) {
        document.getElementById('delete-image-input').value = imagePath;
        document.getElementById('delete-gallery-form').submit();
    }
}

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initPharmacyMap);
} else {
    initPharmacyMap();
}

async function translateAll() {
    const btn = document.getElementById('translateBtn');
    const originalText = btn.innerHTML;
    
    try {
        btn.innerHTML = '<svg class="animate-spin h-4 w-4 mr-2" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg> <span>وەرگێڕان دەکرێت...</span>';
        btn.disabled = true;

        const fieldsToTranslate = [
            { source: 'name', ar: 'name_ar', en: 'name_en' },
            { source: 'location', ar: 'location_ar', en: 'location_en' },
            { source: 'bio', ar: 'bio_ar', en: 'bio_en' }
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
                        'Accept': 'application/json'
                    },
                    body: JSON.stringify({ text: sourceEl.value })
                });
                
                const data = await res.json();
                
                if (data.success && data.translations) {
                    if (arEl && data.translations.ar) {
                        arEl.value = data.translations.ar;
                        arEl.classList.add('bg-emerald-50');
                        setTimeout(() => arEl.classList.remove('bg-emerald-50'), 1500);
                    }
                    if (enEl && data.translations.en) {
                        enEl.value = data.translations.en;
                        enEl.classList.add('bg-emerald-50');
                        setTimeout(() => enEl.classList.remove('bg-emerald-50'), 1500);
                    }
                }
            }
        }
    } catch (e) {
        console.error(e);
        alert('هەڵەیەک ڕوویدا لە وەرگێڕانەکە: ' + (e.message || e));
    } finally {
        btn.innerHTML = originalText;
        btn.disabled = false;
    }
}
</script>
@endsection
