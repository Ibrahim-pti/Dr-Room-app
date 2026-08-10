@extends('doctor.layouts.app')
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

@if(session('error'))
    <div class="mb-6 p-4 bg-red-50 border border-red-200 text-red-700 rounded-xl font-medium">
        {{ session('error') }}
    </div>
@endif

<form id="profile-form" action="{{ route('doctor.profile.update') }}" method="POST" enctype="multipart/form-data" class="bg-white rounded-2xl shadow-sm border border-slate-200/60 p-6 max-w-3xl">
    @csrf
    @method('PUT')
    
    <div class="flex justify-between items-center mb-6">
        <h3 class="text-lg font-bold text-slate-800">زانیارییەکان</h3>
        <button type="button" onclick="translateAll()" id="translateBtn" class="flex items-center gap-2 px-4 py-2 bg-indigo-50 text-indigo-600 rounded-xl hover:bg-indigo-100 transition-colors text-sm font-medium">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" width="18" height="18"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5h12M9 3v2m1.048 9.5A18.022 18.022 0 016.412 9m6.088 9h7M11 21l5-10 5 10M12.751 5C11.783 10.77 8.07 15.61 3 18.129"/></svg>
            <span>وەرگێڕانی ئۆتۆماتیکی (Translate All)</span>
        </button>
    </div>

    <div class="space-y-6">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <!-- Name -->
            <div class="space-y-4">
                <div>
                    <label for="name" class="block text-sm font-medium text-slate-700 mb-2">ناوی تەواو (کوردی)</label>
                    <input type="text" id="name" name="name" value="{{ old('name', $user->name) }}" required
                        class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">
                    @error('name') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
                </div>
                <div>
                    <label for="name_ar" class="block text-sm font-medium text-slate-700 mb-2">ناوی تەواو (عەرەبی)</label>
                    <input type="text" id="name_ar" name="name_ar" value="{{ old('name_ar', $user->name_ar) }}" dir="rtl"
                        class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">
                </div>
                <div>
                    <label for="name_en" class="block text-sm font-medium text-slate-700 mb-2">ناوی تەواو (ئینگلیزی)</label>
                    <input type="text" id="name_en" name="name_en" value="{{ old('name_en', $user->name_en) }}" dir="ltr"
                        class="w-full text-left px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">
                </div>
            </div>

            <!-- Phone -->
            <div>
                <label for="phone" class="block text-sm font-medium text-slate-700 mb-2">ژمارە مۆبایل</label>
                <input type="text" id="phone" name="phone" value="{{ old('phone', $user->phone) }}" required dir="ltr"
                    class="w-full text-right px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">
                @error('phone') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
            </div>
        </div>

        @if($doctor)
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <!-- Specialty -->
            <div class="space-y-4">
                <div>
                    <label for="specialty" class="block text-sm font-medium text-slate-700 mb-2">پسپۆڕی (کوردی)</label>
                    <input type="text" id="specialty" name="specialty" value="{{ old('specialty', $doctor->specialty) }}"
                        class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">
                    @error('specialty') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
                </div>
                <div>
                    <label for="specialty_ar" class="block text-sm font-medium text-slate-700 mb-2">پسپۆڕی (عەرەبی)</label>
                    <input type="text" id="specialty_ar" name="specialty_ar" value="{{ old('specialty_ar', $doctor->specialty_ar) }}" dir="rtl"
                        class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">
                </div>
                <div>
                    <label for="specialty_en" class="block text-sm font-medium text-slate-700 mb-2">پسپۆڕی (ئینگلیزی)</label>
                    <input type="text" id="specialty_en" name="specialty_en" value="{{ old('specialty_en', $doctor->specialty_en) }}" dir="ltr"
                        class="w-full text-left px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">
                </div>
            </div>

            <!-- Profile Image -->
            <div>
                <label for="image" class="block text-sm font-medium text-slate-700 mb-2">وێنەی پڕۆفایل</label>
                <div class="flex items-center gap-4">
                    @if($doctor->image_path)
                        <img src="{{ $doctor->image_path }}" alt="Profile Image" class="w-16 h-16 rounded-full object-cover border border-slate-200">
                    @endif
                    <input type="file" id="image" name="image" accept="image/*"
                        class="block w-full text-sm text-slate-500 file:mr-4 file:py-2.5 file:px-4 file:rounded-xl file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100 transition-all">
                </div>
                @error('image') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
            </div>
        </div>

        <!-- Experience & Fee -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
                <label for="experience_years" class="block text-sm font-medium text-slate-700 mb-2">ساڵی ئەزموون</label>
                <input type="number" id="experience_years" name="experience_years" min="0" max="70" dir="ltr"
                    value="{{ old('experience_years', $doctor->experience_years) }}" placeholder="10"
                    class="w-full text-right px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">
                <p class="text-xs text-slate-400 mt-1">لە ئەپەکەدا لە پڕۆفایلی تۆدا دەردەکەوێت.</p>
                @error('experience_years') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
            </div>

            <div>
                <label for="consultation_fee" class="block text-sm font-medium text-slate-700 mb-2">نرخی پشکنین (دینار)</label>
                <input type="number" id="consultation_fee" name="consultation_fee" min="0" step="250" dir="ltr"
                    value="{{ old('consultation_fee', $doctor->consultation_fee ? (int) $doctor->consultation_fee : '') }}" placeholder="25000"
                    class="w-full text-right px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">
                <p class="text-xs text-slate-400 mt-1">ئەگەر بەتاڵ بێت، نرخی خزمەتگوزارییەکان بەکاردێت.</p>
                @error('consultation_fee') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
            </div>
        </div>

        <!-- Clinic location -->
        <div class="space-y-4 pt-2 border-t border-slate-100">
            <h4 class="text-sm font-bold text-slate-800 pt-4">شوێنی کلینیک</h4>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div class="space-y-4">
                    <div>
                        <label for="clinic_name" class="block text-sm font-medium text-slate-700 mb-2">ناوی کلینیک (کوردی)</label>
                        <input type="text" id="clinic_name" name="clinic_name" value="{{ old('clinic_name', $doctor->clinic_name) }}" placeholder="کلینیکی ..."
                            class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">
                    </div>
                    <div>
                        <label for="clinic_name_ar" class="block text-sm font-medium text-slate-700 mb-2">ناوی کلینیک (عەرەبی)</label>
                        <input type="text" id="clinic_name_ar" name="clinic_name_ar" value="{{ old('clinic_name_ar', $doctor->clinic_name_ar) }}" dir="rtl"
                            class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">
                    </div>
                    <div>
                        <label for="clinic_name_en" class="block text-sm font-medium text-slate-700 mb-2">ناوی کلینیک (ئینگلیزی)</label>
                        <input type="text" id="clinic_name_en" name="clinic_name_en" value="{{ old('clinic_name_en', $doctor->clinic_name_en) }}" dir="ltr"
                            class="w-full text-left px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">
                    </div>
                </div>

                <div class="space-y-4">
                    <div>
                        <label for="address" class="block text-sm font-medium text-slate-700 mb-2">ناونیشان (کوردی)</label>
                        <input type="text" id="address" name="address" value="{{ old('address', $doctor->address) }}" placeholder="شەقام، گەڕەک، شار"
                            class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">
                    </div>
                    <div>
                        <label for="address_ar" class="block text-sm font-medium text-slate-700 mb-2">ناونیشان (عەرەبی)</label>
                        <input type="text" id="address_ar" name="address_ar" value="{{ old('address_ar', $doctor->address_ar) }}" dir="rtl"
                            class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">
                    </div>
                    <div>
                        <label for="address_en" class="block text-sm font-medium text-slate-700 mb-2">ناونیشان (ئینگلیزی)</label>
                        <input type="text" id="address_en" name="address_en" value="{{ old('address_en', $doctor->address_en) }}" dir="ltr"
                            class="w-full text-left px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">
                    </div>
                </div>
            </div>

            <div>
                <label class="block text-sm font-medium text-slate-700 mb-2">شوێن لەسەر نەخشە</label>
                <p class="text-xs text-slate-400 mb-2">کلیک لەسەر نەخشەکە بکە بۆ دانانی نیشانە، یان دوگمەی «شوێنی ئێستام» لێبدە.</p>
                <div id="map" class="w-full h-72 rounded-xl border border-slate-200 z-0"></div>

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

                <input type="hidden" id="latitude" name="latitude" value="{{ old('latitude', $doctor->latitude) }}">
                <input type="hidden" id="longitude" name="longitude" value="{{ old('longitude', $doctor->longitude) }}">
                @error('latitude') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
            </div>
        </div>

        <!-- Bio -->
        <div class="space-y-4">
            <div>
                <label for="bio" class="block text-sm font-medium text-slate-700 mb-2">کورتەیەک دەربارەی خۆت (کوردی)</label>
                <textarea id="bio" name="bio" rows="3"
                    class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">{{ old('bio', $doctor->bio) }}</textarea>
                @error('bio') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
            </div>
            <div>
                <label for="bio_ar" class="block text-sm font-medium text-slate-700 mb-2">کورتەیەک دەربارەی خۆت (عەرەبی)</label>
                <textarea id="bio_ar" name="bio_ar" rows="3" dir="rtl"
                    class="w-full px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">{{ old('bio_ar', $doctor->bio_ar) }}</textarea>
            </div>
            <div>
                <label for="bio_en" class="block text-sm font-medium text-slate-700 mb-2">کورتەیەک دەربارەی خۆت (ئینگلیزی)</label>
                <textarea id="bio_en" name="bio_en" rows="3" dir="ltr"
                    class="w-full text-left px-4 py-2.5 bg-slate-50 border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-slate-700">{{ old('bio_en', $doctor->bio_en) }}</textarea>
            </div>
        </div>
        
        <!-- Video Upload -->
        <div class="border border-slate-200 rounded-xl p-4 bg-slate-50/50">
            <h3 class="text-sm font-semibold text-slate-800 mb-4">ڤیدیۆی ناساندن (هەڵبژاردەیی)</h3>
            
            <div class="space-y-4">
                <div>
                    <label class="block text-sm font-medium text-slate-700 mb-2">جۆری ڤیدیۆ هەڵبژێرە</label>
                    <div class="flex gap-4">
                        <label class="flex items-center gap-2 cursor-pointer">
                            <input type="radio" name="video_type" value="youtube" class="text-blue-600 focus:ring-blue-500" {{ old('video_type', $doctor->video_type) == 'youtube' ? 'checked' : '' }} onchange="toggleVideoInputs('youtube')">
                            <span class="text-sm text-slate-700">لینکی یوتیوب</span>
                        </label>
                        <label class="flex items-center gap-2 cursor-pointer">
                            <input type="radio" name="video_type" value="uploaded" class="text-blue-600 focus:ring-blue-500" {{ old('video_type', $doctor->video_type) == 'uploaded' ? 'checked' : '' }} onchange="toggleVideoInputs('uploaded')">
                            <span class="text-sm text-slate-700">ئەپلۆدکردنی ڤیدیۆ</span>
                        </label>
                    </div>
                </div>

                <div id="youtube_input" class="{{ old('video_type', $doctor->video_type) == 'youtube' ? 'block' : 'hidden' }}">
                    <label for="youtube_url" class="block text-sm font-medium text-slate-700 mb-2">لینکی یوتیوب</label>
                    <input type="url" id="youtube_url" name="youtube_url" value="{{ old('youtube_url', $doctor->video_type == 'youtube' ? $doctor->video_url : '') }}" placeholder="https://youtube.com/watch?v=..." dir="ltr"
                        class="w-full text-left px-4 py-2 bg-white border border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500">
                    @error('youtube_url') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
                </div>

                <div id="upload_input" class="{{ old('video_type', $doctor->video_type) == 'uploaded' ? 'block' : 'hidden' }}">
                    <label for="video_file" class="block text-sm font-medium text-slate-700 mb-2">فایلی ڤیدیۆ هەڵبژێرە (Max 50MB)</label>
                    <input type="file" id="video_file" name="video_file" accept="video/mp4,video/x-m4v,video/*"
                        class="block w-full text-sm text-slate-500 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100">
                    @error('video_file') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
                    
                    @if($doctor->video_type == 'uploaded' && $doctor->video_url)
                        <div class="mt-2 text-sm text-green-600">ڤیدیۆیەک پێشتر ئەپلۆد کراوە.</div>
                    @endif
                </div>
            </div>
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
    async function translateAll() {
        const btn = document.getElementById('translateBtn');
        const originalText = btn.innerHTML;
        btn.innerHTML = '<svg class="animate-spin h-5 w-5 mr-2" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" fill="none"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg> <span>چاوەڕێبە...</span>';
        btn.disabled = true;

        const specialty = document.getElementById('specialty')?.value;
        const bio = document.getElementById('bio')?.value;
        const name = document.getElementById('name')?.value;
        const clinic_name = document.getElementById('clinic_name')?.value;
        const address = document.getElementById('address')?.value;

        try {
            const fieldsToTranslate = [
                { id: 'specialty', val: specialty },
                { id: 'bio', val: bio },
                { id: 'name', val: name },
                { id: 'clinic_name', val: clinic_name },
                { id: 'address', val: address }
            ];

            for (const field of fieldsToTranslate) {
                if (field.val) {
                    const res = await fetch(`/api/translate`, {
                        method: 'POST',
                        headers: {'Content-Type': 'application/json', 'Accept': 'application/json', 'X-CSRF-TOKEN': '{{ csrf_token() }}'},
                        body: JSON.stringify({text: field.val})
                    });
                    const data = await res.json();
                    if(document.getElementById(field.id + '_en')) {
                        document.getElementById(field.id + '_en').value = data.translations?.en || '';
                    }
                    if(document.getElementById(field.id + '_ar')) {
                        document.getElementById(field.id + '_ar').value = data.translations?.ar || '';
                    }
                }
            }
            
            // Re-enable submit button
            const submitBtn = document.getElementById('submit-btn');
            submitBtn.disabled = false;
            submitBtn.classList.remove('opacity-50', 'cursor-not-allowed');
            
        } catch(e) {
            alert('کێشەیەک ڕوویدا لە وەرگێڕان');
        }

        btn.innerHTML = originalText;
        btn.disabled = false;
    }

    // Disable submit if translation needed
    ['specialty', 'bio', 'name', 'clinic_name', 'address'].forEach(id => {
        const el = document.getElementById(id);
        if(el) {
            el.addEventListener('input', () => {
                const submitBtn = document.getElementById('submit-btn');
                if(submitBtn) {
                    submitBtn.disabled = true;
                    submitBtn.classList.add('opacity-50', 'cursor-not-allowed');
                }
            });
        }
    });

    function toggleVideoInputs(type) {
        document.getElementById('youtube_input').style.display = type === 'youtube' ? 'block' : 'none';
        document.getElementById('upload_input').style.display = type === 'uploaded' ? 'block' : 'none';
    }

    document.getElementById('profile-form').addEventListener('submit', function() {
        var btn = document.getElementById('submit-btn');
        btn.disabled = true;
        btn.innerHTML = '<svg class="animate-spin -ml-1 mr-2 h-5 w-5 text-white inline-block" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg> چاوەڕێ بکە...';
        btn.classList.add('opacity-70', 'cursor-not-allowed');
    });
</script>

{{-- Leaflet + OpenStreetMap: no API key, same tiles the Flutter app uses. --}}
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"
      integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=" crossorigin="">
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"
        integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=" crossorigin=""></script>
<script>
    // Erbil, as a starting view when the doctor has no pin yet.
    const DEFAULT_CENTER = [36.1911, 44.0092];

    const latInput = document.getElementById('latitude');
    const lngInput = document.getElementById('longitude');
    const coordsLabel = document.getElementById('coords_label');

    const savedLat = parseFloat(latInput.value);
    const savedLng = parseFloat(lngInput.value);
    const hasSaved = !isNaN(savedLat) && !isNaN(savedLng);

    const map = L.map('map').setView(hasSaved ? [savedLat, savedLng] : DEFAULT_CENTER, hasSaved ? 15 : 12);

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 19,
        attribution: '&copy; OpenStreetMap',
    }).addTo(map);

    let marker = null;

    function setLocation(lat, lng, fly) {
        latInput.value = lat.toFixed(7);
        lngInput.value = lng.toFixed(7);
        coordsLabel.textContent = lat.toFixed(5) + ', ' + lng.toFixed(5);

        if (marker) {
            marker.setLatLng([lat, lng]);
        } else {
            marker = L.marker([lat, lng], { draggable: true }).addTo(map);
            marker.on('dragend', function (e) {
                const p = e.target.getLatLng();
                setLocation(p.lat, p.lng, false);
            });
        }

        if (fly) map.setView([lat, lng], 16);
    }

    function clearLocation() {
        latInput.value = '';
        lngInput.value = '';
        coordsLabel.textContent = '';
        if (marker) {
            map.removeLayer(marker);
            marker = null;
        }
    }

    function useMyLocation() {
        if (!navigator.geolocation) {
            alert('وێبگەڕەکەت پشتگیری شوێن ناکات.');
            return;
        }
        navigator.geolocation.getCurrentPosition(
            function (pos) { setLocation(pos.coords.latitude, pos.coords.longitude, true); },
            function () { alert('نەتوانرا شوێنەکەت بدۆزرێتەوە. ڕێگەپێدان بپشکنە.'); },
        );
    }

    map.on('click', function (e) { setLocation(e.latlng.lat, e.latlng.lng, false); });

    if (hasSaved) setLocation(savedLat, savedLng, false);

    // The container starts hidden inside the form layout on some screens.
    setTimeout(function () { map.invalidateSize(); }, 200);
</script>
@endsection
