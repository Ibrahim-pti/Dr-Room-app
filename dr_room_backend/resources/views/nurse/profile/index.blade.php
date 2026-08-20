@extends('nurse.layouts.app')
@section('header_title', 'ڕێکخستنی پڕۆفایل')

@section('content')
<div class="mb-6 flex flex-col md:flex-row md:items-center justify-between gap-4">
    <div>
        <h2 class="text-xl font-bold text-slate-800">ڕێکخستنەکانی پڕۆفایل</h2>
        <p class="text-sm text-slate-500 mt-1">لێرە دەتوانیت زانیارییە کەسییەکان، پسپۆڕییەکان و شوێنەکەت نوێ بکەیتەوە.</p>
    </div>

    <!-- Translate All Button at the Top -->
    <button type="button" onclick="handleTranslateAll()" id="translate-all-btn"
        class="inline-flex items-center gap-2 px-5 py-2.5 bg-gradient-to-r from-teal-600 to-emerald-600 hover:from-teal-700 hover:to-emerald-700 text-white rounded-xl font-bold text-xs shadow-md shadow-teal-500/20 transition-all transform active:scale-95 cursor-pointer">
        <svg class="w-4 h-4 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5h12M9 3v2m1.048 9.5A18.022 18.022 0 016.412 9m6.088 9h7M11 21l5-10 5 10M12.751 5C11.783 10.77 8.07 15.61 3 18.129"/></svg>
        <span id="translate-btn-text">وەرگێڕانی هەمووی (Translate All)</span>
    </button>
</div>

@if(session('success'))
    <div class="mb-6 p-4 bg-emerald-50 border border-emerald-200 text-emerald-700 rounded-2xl flex items-center gap-3 shadow-sm">
        <svg class="w-5 h-5 text-emerald-600 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/></svg>
        <span class="font-medium text-sm">{{ session('success') }}</span>
    </div>
@endif

<form id="profile-form" action="{{ route('nurse.profile.update') }}" method="POST" enctype="multipart/form-data" class="bg-white rounded-2xl shadow-sm border border-slate-200/80 p-6 md:p-8 max-w-4xl">
    @csrf
    @method('PUT')
    
    <div class="space-y-8">
        <!-- Profile Image -->
        <div>
            <label class="block text-sm font-bold text-slate-700 mb-3">وێنەی پڕۆفایل</label>
            <div class="flex items-center gap-5">
                @if($nurse && $nurse->image_path)
                    <img src="{{ asset('storage/' . $nurse->image_path) }}" class="w-20 h-20 rounded-2xl object-cover border-2 border-teal-200 shadow-sm">
                @elseif($user->profile_image)
                    <img src="{{ asset('storage/' . $user->profile_image) }}" class="w-20 h-20 rounded-2xl object-cover border-2 border-teal-200 shadow-sm">
                @else
                    <div class="w-20 h-20 rounded-2xl bg-gradient-to-br from-teal-500 to-teal-600 flex items-center justify-center shadow-sm">
                        <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/></svg>
                    </div>
                @endif
                <div>
                    <input type="file" id="image" name="image" accept="image/*" class="text-sm text-slate-500 file:mr-4 file:py-2.5 file:px-4 file:rounded-xl file:border-0 file:text-sm file:font-semibold file:bg-teal-50 file:text-teal-700 hover:file:bg-teal-100 transition-all cursor-pointer">
                    <p class="text-xs text-slate-400 mt-1.5">JPEG, PNG, WebP (حەجمی بەرز: 3MB)</p>
                </div>
            </div>
        </div>

        <!-- Basic Information -->
        <div class="border-t border-slate-100 pt-6">
            <h3 class="text-base font-bold text-slate-800 mb-4 flex items-center gap-2">
                <span class="w-2 h-2 rounded-full bg-teal-500"></span>
                زانیارییە سەرەکییەکان
            </h3>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-5 mb-5">
                <!-- Name (Kurdish) -->
                <div>
                    <label for="name" class="block text-xs font-bold text-slate-600 mb-1.5">ناوی تەواو (کوردی) <span class="text-red-500">*</span></label>
                    <input type="text" id="name" name="name" value="{{ old('name', $user->name) }}" required placeholder="وەک: شاژوان عوسمان ڕەشید"
                        class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-teal-500/20 focus:border-teal-500 transition-all font-medium text-slate-700 text-sm">
                    @error('name') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
                </div>

                <!-- Name (English) -->
                <div>
                    <label for="name_en" class="block text-xs font-bold text-slate-600 mb-1.5">ناو (ئینگلیزی)</label>
                    <input type="text" id="name_en" name="name_en" value="{{ old('name_en', $user->name_en) }}" dir="ltr" placeholder="Full name in English"
                        class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-teal-500/20 focus:border-teal-500 transition-all font-medium text-slate-700 text-sm">
                </div>

                <!-- Name (Arabic) -->
                <div>
                    <label for="name_ar" class="block text-xs font-bold text-slate-600 mb-1.5">ناو (عەرەبی)</label>
                    <input type="text" id="name_ar" name="name_ar" value="{{ old('name_ar', $user->name_ar) }}" dir="rtl" placeholder="الاسم الكامل بالعربية"
                        class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-teal-500/20 focus:border-teal-500 transition-all font-medium text-slate-700 text-sm">
                </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                <!-- Phone -->
                <div>
                    <label for="phone" class="block text-xs font-bold text-slate-600 mb-1.5">ژمارەی مۆبایل <span class="text-red-500">*</span></label>
                    <input type="text" id="phone" name="phone" value="{{ old('phone', $user->phone ?? ($nurse->phone ?? '')) }}" required dir="ltr" placeholder="0750XXXXXXX"
                        class="w-full text-right px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-teal-500/20 focus:border-teal-500 transition-all font-medium text-slate-700 text-sm">
                    @error('phone') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
                </div>

                <!-- Fee -->
                <div>
                    <label for="fee" class="block text-xs font-bold text-slate-600 mb-1.5">نرخی سەردان / خزمەتگوزاری (دینار)</label>
                    <input type="number" step="500" id="fee" name="fee" value="{{ old('fee', $nurse ? (float)$nurse->fee : 15000) }}" dir="ltr" placeholder="15000"
                        class="w-full text-right px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-teal-500/20 focus:border-teal-500 transition-all font-medium text-slate-700 text-sm">
                    @error('fee') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
                </div>
            </div>
        </div>

        @if($nurse)
        <!-- Specialty & Skills (Multi-Specialty Dynamic List) -->
        <div class="border-t border-slate-100 pt-6">
            <div class="flex items-center justify-between mb-4">
                <h3 class="text-base font-bold text-slate-800 flex items-center gap-2">
                    <span class="w-2 h-2 rounded-full bg-teal-500"></span>
                    پسپۆڕی و بوارەکان (دەتوانیت چەندین پسپۆڕی زیاد بکەیت)
                </h3>
                <button type="button" onclick="addSpecialtyRow()"
                    class="flex items-center gap-1.5 px-4 py-2 bg-teal-50 hover:bg-teal-100 text-teal-700 rounded-xl text-xs font-bold border border-teal-200 transition-colors shadow-sm cursor-pointer">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
                    + زیادکردنی پسپۆڕی نوێ
                </button>
            </div>

            @php
                $existingKurdish = array_filter(array_map('trim', preg_split('/[،,]/', $nurse->specialty ?? '')));
                $existingEnglish = array_filter(array_map('trim', preg_split('/[،,]/', $nurse->specialty_en ?? '')));
                $existingArabic = array_filter(array_map('trim', preg_split('/[،,]/', $nurse->specialty_ar ?? '')));

                $maxCount = max(count($existingKurdish), 1);
                $specialtiesRows = [];
                for ($i = 0; $i < $maxCount; $i++) {
                    $specialtiesRows[] = [
                        'name' => $existingKurdish[$i] ?? '',
                        'name_en' => $existingEnglish[$i] ?? '',
                        'name_ar' => $existingArabic[$i] ?? '',
                    ];
                }
            @endphp

            <div id="specialties-container" class="space-y-3 mb-5">
                @foreach($specialtiesRows as $idx => $sRow)
                    <div class="specialty-row bg-slate-50 border border-slate-200/80 rounded-2xl p-4 transition-all hover:border-teal-300 relative">
                        <div class="grid grid-cols-1 md:grid-cols-12 gap-3 items-center">
                            <div class="md:col-span-4">
                                <label class="block text-[11px] font-bold text-slate-600 mb-1">پسپۆڕی (کوردی)</label>
                                <input type="text" name="specialties[{{ $idx }}][name]" value="{{ $sRow['name'] }}" placeholder="وەک: پەرستاری فریاکەوتن"
                                    class="specialty-kurdish-input w-full px-3.5 py-2.5 bg-white border border-slate-200 rounded-xl text-xs font-bold text-slate-800 focus:ring-2 focus:ring-teal-500/20 focus:border-teal-500">
                            </div>
                            <div class="md:col-span-4">
                                <label class="block text-[11px] font-bold text-slate-600 mb-1">پسپۆڕی (ئینگلیزی)</label>
                                <input type="text" name="specialties[{{ $idx }}][name_en]" value="{{ $sRow['name_en'] }}" dir="ltr" placeholder="Emergency Nursing"
                                    class="specialty-english-input w-full px-3.5 py-2.5 bg-white border border-slate-200 rounded-xl text-xs font-medium text-slate-700 focus:ring-2 focus:ring-teal-500/20 focus:border-teal-500">
                            </div>
                            <div class="md:col-span-3">
                                <label class="block text-[11px] font-bold text-slate-600 mb-1">پسپۆڕی (عەرەبی)</label>
                                <input type="text" name="specialties[{{ $idx }}][name_ar]" value="{{ $sRow['name_ar'] }}" dir="rtl" placeholder="تمريض طوارئ"
                                    class="specialty-arabic-input w-full px-3.5 py-2.5 bg-white border border-slate-200 rounded-xl text-xs font-medium text-slate-700 focus:ring-2 focus:ring-teal-500/20 focus:border-teal-500">
                            </div>
                            <div class="md:col-span-1 flex justify-end pt-2 md:pt-4">
                                <button type="button" onclick="removeSpecialtyRow(this)" class="p-2 text-red-400 hover:text-red-600 hover:bg-red-50 rounded-xl transition-colors" title="سڕینەوە">
                                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
                                </button>
                            </div>
                        </div>
                    </div>
                @endforeach
            </div>

            <!-- City & Service Type -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                <!-- City with Select & Custom Input -->
                <div>
                    <label for="city" class="block text-xs font-bold text-slate-600 mb-1.5">شار (دەتوانیت لە لیستەکە هەڵبژێریت یان بەدەست بنووسیت)</label>
                    <div class="relative">
                        <input type="text" id="city" name="city" list="cities-list" value="{{ old('city', $nurse->city) }}" placeholder="هەڵبژێرە یان بنووسە: هەولێر، سلێمانی، سۆران..."
                            class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-teal-500/20 focus:border-teal-500 transition-all font-medium text-slate-700 text-sm">
                        <datalist id="cities-list">
                            <option value="Erbil">هەولێر (Erbil)</option>
                            <option value="Sulaymaniyah">سلێمانی (Sulaymaniyah)</option>
                            <option value="Duhok">دهۆک (Duhok)</option>
                            <option value="Kirkuk">کەرکووک (Kirkuk)</option>
                            <option value="Halabja">هەڵەبجە (Halabja)</option>
                            <option value="Zakho">زاخۆ (Zakho)</option>
                            <option value="Soran">سۆران (Soran)</option>
                            <option value="Koya">کۆیە (Koya)</option>
                            <option value="Ranya">ڕانیە (Ranya)</option>
                            <option value="Garmian">گەرمیان (Garmian)</option>
                            <option value="Shaqlawa">شەقڵاوە (Shaqlawa)</option>
                            <option value="Akre">ئاکرێ (Akre)</option>
                        </datalist>
                    </div>
                    @error('city') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
                </div>

                <!-- Service Type -->
                <div>
                    <label for="service_type" class="block text-xs font-bold text-slate-600 mb-1.5">جۆری خزمەتگوزاری سەرەکی</label>
                    <select id="service_type" name="service_type"
                        class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-teal-500/20 focus:border-teal-500 transition-all font-medium text-slate-700 text-sm">
                        <option value="home_nursing" {{ old('service_type', $nurse->service_type) == 'home_nursing' ? 'selected' : '' }}>پەرستاری ماڵەوە (Home Nursing)</option>
                        <option value="clinic" {{ old('service_type', $nurse->service_type) == 'clinic' ? 'selected' : '' }}>کلینیک (Clinic)</option>
                        <option value="hospital" {{ old('service_type', $nurse->service_type) == 'hospital' ? 'selected' : '' }}>نەخۆشخانە (Hospital)</option>
                    </select>
                    @error('service_type') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
                </div>
            </div>
        </div>

        <!-- Address & Interactive Map with Auto Geocoding -->
        <div class="border-t border-slate-100 pt-6">
            <h3 class="text-base font-bold text-slate-800 mb-2 flex items-center gap-2">
                <span class="w-2 h-2 rounded-full bg-teal-500"></span>
                شوێن لەسەر نەخشە و ناونیشان
            </h3>
            <p class="text-xs text-slate-400 mb-4">کاتێک لەسەر نەخشەکە شوێنەکەت دیاری دەکەیت، ناونیشانەکە بە شێوەیەکی ئۆتۆماتیکی دەنوسرێت و وەردەگێڕدرێت.</p>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
                <div>
                    <label for="address" class="block text-xs font-bold text-slate-600 mb-1.5">ناونیشان / گەڕەک (کوردی)</label>
                    <input type="text" id="address" name="address" value="{{ old('address', $nurse->address) }}" placeholder="هەولێر، ٦٠ مەتری، نزیک..."
                        class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-teal-500/20 focus:border-teal-500 transition-all font-medium text-slate-700 text-sm">
                </div>
                <div>
                    <label for="address_en" class="block text-xs font-bold text-slate-600 mb-1.5">ناونیشان (ئینگلیزی)</label>
                    <input type="text" id="address_en" name="address_en" value="{{ old('address_en', $nurse->address_en) }}" dir="ltr" placeholder="Street / Area in English"
                        class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-teal-500/20 focus:border-teal-500 transition-all font-medium text-slate-700 text-sm">
                </div>
                <div>
                    <label for="address_ar" class="block text-xs font-bold text-slate-600 mb-1.5">ناونیشان (عەرەبی)</label>
                    <input type="text" id="address_ar" name="address_ar" value="{{ old('address_ar', $nurse->address_ar) }}" dir="rtl" placeholder="العنوان / الحي بالعربية"
                        class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-teal-500/20 focus:border-teal-500 transition-all font-medium text-slate-700 text-sm">
                </div>
            </div>

            <!-- Leaflet Map Container -->
            <div class="mt-3">
                <div id="map" class="w-full h-72 rounded-2xl border border-slate-200 z-0 overflow-hidden shadow-inner"></div>

                <div class="flex flex-wrap items-center gap-3 mt-3">
                    <button type="button" onclick="useMyLocation()"
                        class="flex items-center gap-2 px-4 py-2 bg-teal-50 text-teal-700 rounded-xl hover:bg-teal-100 transition-colors text-xs font-bold border border-teal-200">
                        <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" width="16" height="16"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a2 2 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"/></svg>
                        شوێنی ئێستام دیاریبکە
                    </button>
                    <button type="button" onclick="clearLocation()"
                        class="px-4 py-2 bg-slate-100 text-slate-600 rounded-xl hover:bg-slate-200 transition-colors text-xs font-bold">
                        سڕینەوەی نیشانە
                    </button>
                    <span id="coords_label" class="text-xs text-slate-400 font-mono" dir="ltr"></span>
                    <span id="geo_loading" class="text-xs text-teal-600 font-bold hidden animate-pulse">دۆزینەوەی ناونیشان لەسەر نەخشە...</span>
                </div>

                <input type="hidden" id="latitude" name="latitude" value="{{ old('latitude', $nurse->latitude) }}">
                <input type="hidden" id="longitude" name="longitude" value="{{ old('longitude', $nurse->longitude) }}">
            </div>
        </div>

        <!-- Availability Toggle -->
        <div class="border-t border-slate-100 pt-6">
            <div class="flex items-center justify-between p-4 bg-slate-50 rounded-2xl border border-slate-200/80">
                <div>
                    <p class="font-bold text-slate-800 text-sm">ئامادەبوون بۆ وەرگرتنی داواکاری لە ئەپەکە</p>
                    <p class="text-xs text-slate-500 mt-1">کاتێک چالاک بێت، بەکارهێنەرانی ناو ئەپەکە دەتوانن داواکاریت بۆ بنێرن و تۆ وەک پەرستار هەڵبژێرن.</p>
                </div>
                <label class="relative inline-flex items-center cursor-pointer">
                    <input type="hidden" name="is_available" value="0">
                    <input type="checkbox" name="is_available" value="1" {{ old('is_available', $nurse->is_available) ? 'checked' : '' }} class="sr-only peer">
                    <div class="w-12 h-6 bg-slate-300 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-slate-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-teal-500"></div>
                </label>
            </div>
        </div>

        <!-- Bio (Kurdish, English, Arabic) -->
        <div class="border-t border-slate-100 pt-6 space-y-4">
            <h3 class="text-base font-bold text-slate-800 mb-2 flex items-center gap-2">
                <span class="w-2 h-2 rounded-full bg-teal-500"></span>
                کورتەیەک دەربارەی خۆت (بایۆگرافی)
            </h3>
            
            <div>
                <label for="bio" class="block text-xs font-bold text-slate-600 mb-1.5">دەربارەی خۆت و ئەزموونت (کوردی)</label>
                <textarea id="bio" name="bio" rows="3" placeholder="کورتەیەک دەربارەی ئەزموونی کارکردن و لێهاتووییت بنووسە..."
                    class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-teal-500/20 focus:border-teal-500 transition-all font-medium text-slate-700 text-sm">{{ old('bio', $nurse->bio) }}</textarea>
                @error('bio') <p class="text-red-500 text-xs mt-1">{{ $message }}</p> @enderror
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                    <label for="bio_en" class="block text-xs font-bold text-slate-600 mb-1.5">دەربارەی خۆت (ئینگلیزی)</label>
                    <textarea id="bio_en" name="bio_en" rows="2" dir="ltr" placeholder="Short biography in English..."
                        class="w-full text-left px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-teal-500/20 focus:border-teal-500 transition-all font-medium text-slate-700 text-sm">{{ old('bio_en', $nurse->bio_en) }}</textarea>
                </div>
                <div>
                    <label for="bio_ar" class="block text-xs font-bold text-slate-600 mb-1.5">دەربارەی خۆت (عەرەبی)</label>
                    <textarea id="bio_ar" name="bio_ar" rows="2" dir="rtl" placeholder="نبذة عن خبرتك باللغة العربية..."
                        class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-teal-500/20 focus:border-teal-500 transition-all font-medium text-slate-700 text-sm">{{ old('bio_ar', $nurse->bio_ar) }}</textarea>
                </div>
            </div>
        </div>
        @endif

        <div class="pt-6 border-t border-slate-100 flex justify-end">
            <button id="submit-btn" type="submit" class="px-8 py-3 bg-teal-600 hover:bg-teal-700 text-white rounded-xl font-bold transition-all shadow-lg shadow-teal-500/20 flex items-center justify-center min-w-[160px] text-sm cursor-pointer">
                پاشەکەوتکردنی هەموو گۆڕانکارییەکان
            </button>
        </div>
    </div>
</form>

{{-- Leaflet OpenStreetMap Assets --}}
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=" crossorigin="">
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js" integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=" crossorigin=""></script>

<script>
    // Map initialization
    const DEFAULT_CENTER = [36.1911, 44.0092]; // Erbil
    const latInput = document.getElementById('latitude');
    const lngInput = document.getElementById('longitude');
    const coordsLabel = document.getElementById('coords_label');
    const geoLoading = document.getElementById('geo_loading');

    const savedLat = parseFloat(latInput?.value);
    const savedLng = parseFloat(lngInput?.value);
    const hasSaved = !isNaN(savedLat) && !isNaN(savedLng);

    const map = L.map('map').setView(hasSaved ? [savedLat, savedLng] : DEFAULT_CENTER, hasSaved ? 15 : 12);

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 19,
        attribution: '&copy; OpenStreetMap',
    }).addTo(map);

    let marker = null;

    function setLocation(lat, lng, fly, fetchAddress = true) {
        if (latInput) latInput.value = lat.toFixed(7);
        if (lngInput) lngInput.value = lng.toFixed(7);
        if (coordsLabel) coordsLabel.textContent = lat.toFixed(5) + ', ' + lng.toFixed(5);

        if (marker) {
            marker.setLatLng([lat, lng]);
        } else {
            marker = L.marker([lat, lng], { draggable: true }).addTo(map);
            marker.on('dragend', function (e) {
                const p = e.target.getLatLng();
                setLocation(p.lat, p.lng, false, true);
            });
        }

        if (fly) map.setView([lat, lng], 16);

        if (fetchAddress) {
            reverseGeocodeAndFill(lat, lng);
        }
    }

    function clearLocation() {
        if (latInput) latInput.value = '';
        if (lngInput) lngInput.value = '';
        if (coordsLabel) coordsLabel.textContent = '';
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
            function (pos) { setLocation(pos.coords.latitude, pos.coords.longitude, true, true); },
            function () { alert('نەتوانرا شوێنەکەت بدۆزرێتەوە. تکایە ڕێگەپێدانی شوێن چالاک بکە.'); }
        );
    }

    // Reverse Geocoding with OSM Nominatim
    async function reverseGeocodeAndFill(lat, lng) {
        if (geoLoading) geoLoading.classList.remove('hidden');
        try {
            const url = `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}&accept-language=ckb,ku,ar,en`;
            const res = await fetch(url, { headers: { 'User-Agent': 'DrRoomApp/1.0' } });
            const data = await res.json();
            
            if (data && data.address) {
                const road = data.address.road || data.address.neighbourhood || data.address.suburb || data.address.residential || '';
                const city = data.address.city || data.address.town || data.address.county || data.address.state || '';
                
                let detectedAddress = '';
                if (city && road) {
                    detectedAddress = `${city}، ${road}`;
                } else if (city || road) {
                    detectedAddress = city || road;
                } else if (data.display_name) {
                    detectedAddress = data.display_name.split(',').slice(0, 3).join('، ');
                }

                if (detectedAddress) {
                    const addressField = document.getElementById('address');
                    if (addressField) {
                        addressField.value = detectedAddress;
                    }

                    // Auto-fill city if empty
                    const cityField = document.getElementById('city');
                    if (cityField && !cityField.value.trim() && city) {
                        cityField.value = city;
                    }

                    // Auto translate address immediately
                    autoTranslateAddress(detectedAddress);
                }
            }
        } catch (err) {
            console.error('Reverse geocode error:', err);
        } finally {
            if (geoLoading) geoLoading.classList.add('hidden');
        }
    }

    async function autoTranslateAddress(addrText) {
        try {
            const token = document.querySelector('input[name="_token"]')?.value;
            const res = await fetch("{{ route('nurse.profile.translate') }}", {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': token,
                    'Accept': 'application/json',
                },
                body: JSON.stringify({ address: addrText }),
            });
            const json = await res.json();
            if (json.success && json.data) {
                if (json.data.address_en) document.getElementById('address_en').value = json.data.address_en;
                if (json.data.address_ar) document.getElementById('address_ar').value = json.data.address_ar;
            }
        } catch (e) {
            console.error('Address translation error:', e);
        }
    }

    map.on('click', function (e) { setLocation(e.latlng.lat, e.latlng.lng, false, true); });

    if (hasSaved) setLocation(savedLat, savedLng, false, false);

    setTimeout(function () { map.invalidateSize(); }, 300);

    // Dynamic Specialty Rows Management
    let specialtyRowIdx = {{ count($specialtiesRows) }};

    function addSpecialtyRow() {
        const container = document.getElementById('specialties-container');
        if (!container) return;

        const row = document.createElement('div');
        row.className = 'specialty-row bg-slate-50 border border-slate-200/80 rounded-2xl p-4 transition-all hover:border-teal-300 relative animate-fadeIn';
        row.innerHTML = `
            <div class="grid grid-cols-1 md:grid-cols-12 gap-3 items-center">
                <div class="md:col-span-4">
                    <label class="block text-[11px] font-bold text-slate-600 mb-1">پسپۆڕی (کوردی)</label>
                    <input type="text" name="specialties[${specialtyRowIdx}][name]" placeholder="وەک: پەرستاری فریاکەوتن"
                        class="specialty-kurdish-input w-full px-3.5 py-2.5 bg-white border border-slate-200 rounded-xl text-xs font-bold text-slate-800 focus:ring-2 focus:ring-teal-500/20 focus:border-teal-500">
                </div>
                <div class="md:col-span-4">
                    <label class="block text-[11px] font-bold text-slate-600 mb-1">پسپۆڕی (ئینگلیزی)</label>
                    <input type="text" name="specialties[${specialtyRowIdx}][name_en]" dir="ltr" placeholder="Emergency Nursing"
                        class="specialty-english-input w-full px-3.5 py-2.5 bg-white border border-slate-200 rounded-xl text-xs font-medium text-slate-700 focus:ring-2 focus:ring-teal-500/20 focus:border-teal-500">
                </div>
                <div class="md:col-span-3">
                    <label class="block text-[11px] font-bold text-slate-600 mb-1">پسپۆڕی (عەرەبی)</label>
                    <input type="text" name="specialties[${specialtyRowIdx}][name_ar]" dir="rtl" placeholder="تمريض طوارئ"
                        class="specialty-arabic-input w-full px-3.5 py-2.5 bg-white border border-slate-200 rounded-xl text-xs font-medium text-slate-700 focus:ring-2 focus:ring-teal-500/20 focus:border-teal-500">
                </div>
                <div class="md:col-span-1 flex justify-end pt-2 md:pt-4">
                    <button type="button" onclick="removeSpecialtyRow(this)" class="p-2 text-red-400 hover:text-red-600 hover:bg-red-50 rounded-xl transition-colors" title="سڕینەوە">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg>
                    </button>
                </div>
            </div>
        `;
        container.appendChild(row);
        specialtyRowIdx++;
    }

    function removeSpecialtyRow(btn) {
        const rows = document.querySelectorAll('.specialty-row');
        if (rows.length > 1) {
            btn.closest('.specialty-row').remove();
        } else {
            // If only one row, just clear its inputs
            const row = btn.closest('.specialty-row');
            row.querySelectorAll('input').forEach(i => i.value = '');
        }
    }

    // Translate All Function
    async function handleTranslateAll() {
        const btn = document.getElementById('translate-all-btn');
        const btnText = document.getElementById('translate-btn-text');
        const token = document.querySelector('input[name="_token"]')?.value;

        const nameVal = document.getElementById('name')?.value || '';
        const cityVal = document.getElementById('city')?.value || '';
        const addressVal = document.getElementById('address')?.value || '';
        const bioVal = document.getElementById('bio')?.value || '';

        // Collect all specialties from dynamic rows
        const specialtyRows = document.querySelectorAll('.specialty-row');
        const specialtiesPayload = [];
        specialtyRows.forEach(row => {
            const kInput = row.querySelector('.specialty-kurdish-input');
            const eInput = row.querySelector('.specialty-english-input');
            const aInput = row.querySelector('.specialty-arabic-input');
            if (kInput && kInput.value.trim()) {
                specialtiesPayload.push({
                    name: kInput.value.trim(),
                    name_en: eInput ? eInput.value.trim() : '',
                    name_ar: aInput ? aInput.value.trim() : '',
                });
            }
        });

        if (!nameVal && specialtiesPayload.length === 0 && !addressVal && !bioVal) {
            alert('تکایە سەرەتا خانە کوردییەکان پڕبکەرەوە.');
            return;
        }

        btn.disabled = true;
        btnText.innerHTML = '<span class="inline-block animate-spin mr-1">↻</span> خەریکی وەرگێڕانە...';
        btn.classList.add('opacity-80');

        try {
            const res = await fetch("{{ route('nurse.profile.translate') }}", {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': token,
                    'Accept': 'application/json',
                },
                body: JSON.stringify({
                    name: nameVal,
                    specialties: specialtiesPayload,
                    city: cityVal,
                    address: addressVal,
                    bio: bioVal,
                }),
            });

            const json = await res.json();

            if (json.success && json.data) {
                const d = json.data;

                // Set Name, Address, Bio
                const fields = [
                    { id: 'name_en', val: d.name_en },
                    { id: 'name_ar', val: d.name_ar },
                    { id: 'address_en', val: d.address_en },
                    { id: 'address_ar', val: d.address_ar },
                    { id: 'bio_en', val: d.bio_en },
                    { id: 'bio_ar', val: d.bio_ar },
                ];

                fields.forEach(f => {
                    const el = document.getElementById(f.id);
                    if (el && f.val) {
                        el.value = f.val;
                        el.classList.add('ring-2', 'ring-teal-400', 'bg-teal-50/40');
                        setTimeout(() => {
                            el.classList.remove('ring-2', 'ring-teal-400', 'bg-teal-50/40');
                        }, 2000);
                    }
                });

                // Set Translated Specialties into rows
                if (d.specialties_translated && Array.isArray(d.specialties_translated)) {
                    specialtyRows.forEach((row, i) => {
                        const item = d.specialties_translated[i];
                        if (item) {
                            const eInput = row.querySelector('.specialty-english-input');
                            const aInput = row.querySelector('.specialty-arabic-input');
                            if (eInput && item.name_en) {
                                eInput.value = item.name_en;
                                eInput.classList.add('ring-2', 'ring-teal-400', 'bg-teal-50/40');
                                setTimeout(() => eInput.classList.remove('ring-2', 'ring-teal-400', 'bg-teal-50/40'), 2000);
                            }
                            if (aInput && item.name_ar) {
                                aInput.value = item.name_ar;
                                aInput.classList.add('ring-2', 'ring-teal-400', 'bg-teal-50/40');
                                setTimeout(() => aInput.classList.remove('ring-2', 'ring-teal-400', 'bg-teal-50/40'), 2000);
                            }
                        }
                    });
                }

                btnText.textContent = '✓ هەمووی وەرگێڕدرا';
                setTimeout(() => {
                    btnText.textContent = 'وەرگێڕانی هەمووی (Translate All)';
                }, 2500);
            } else {
                alert(json.message || 'هەڵەیەک ڕوویدا لە کاتی وەرگێڕاندا.');
                btnText.textContent = 'وەرگێڕانی هەمووی (Translate All)';
            }
        } catch (err) {
            console.error('Translation failed:', err);
            alert('نەتوانرا پەیوەندی بە سێرڤەرەوە بکرێت بۆ وەرگێڕان.');
            btnText.textContent = 'وەرگێڕانی هەمووی (Translate All)';
        } finally {
            btn.disabled = false;
            btn.classList.remove('opacity-80');
        }
    }

    // Form submit loading
    document.getElementById('profile-form').addEventListener('submit', function() {
        var btn = document.getElementById('submit-btn');
        btn.disabled = true;
        btn.innerHTML = '<svg class="animate-spin -ml-1 mr-2 h-5 w-5 text-white inline-block" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg> پاشەکەوت دەکرێت...';
        btn.classList.add('opacity-70', 'cursor-not-allowed');
    });
</script>
@endsection
