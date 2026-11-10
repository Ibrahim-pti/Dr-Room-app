@php
    $loc = $locale ?? app()->getLocale();
    $isRtl = in_array($loc, ['ar', 'ckb', 'kmr']);
    $cities = __('delivery.cities');
    if (!is_array($cities)) {
        $cities = ['هەولێر', 'سلێمانی', 'دهۆک', 'کەرکوک', 'هەڵەبجە'];
    }
    $isSubdomain = str_starts_with(strtolower(request()->getHost()), 'delivery.');
    $langHref = fn (string $target) => $isSubdomain ? '/' . $target : '/delivery/' . $target;
    $mainSiteHref = $isSubdomain
        ? str_ireplace('://delivery.', '://', url('/'))
        : '/' . ($loc === 'ckb' ? '' : $loc);
@endphp
<!DOCTYPE html>
<html lang="{{ $loc }}" dir="{{ $isRtl ? 'rtl' : 'ltr' }}" class="scroll-smooth">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ __('delivery.meta_title') }}</title>

    <link rel="icon" type="image/png" href="{{ asset('favicon.png') }}">
    <link rel="shortcut icon" href="{{ asset('favicon.ico') }}">
    <link rel="apple-touch-icon" href="{{ asset('images/logo.png') }}">

    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.13.3/dist/cdn.min.js"></script>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Noto+Kufi+Arabic:wght@400;500;600;700;800;900&family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    fontFamily: {
                        sans: ["{{ $isRtl ? 'Noto Kufi Arabic' : 'Plus Jakarta Sans' }}", 'Noto Kufi Arabic', 'Plus Jakarta Sans', 'sans-serif'],
                    }
                }
            }
        }
    </script>
    <style>
        body {
            font-family: {{ $isRtl ? "'Noto Kufi Arabic', sans-serif" : "'Plus Jakarta Sans', 'Noto Kufi Arabic', sans-serif" }};
        }
        .kurdish-heading {
            line-height: 1.75 !important;
        }
    </style>
</head>
<body class="bg-[#F8FAFC] text-slate-900 antialiased min-h-screen flex flex-col selection:bg-orange-100 selection:text-orange-900 overflow-x-hidden"
      x-data="{
          langOpen: false,
          mobileNav: false,
          showPass: false,
          showConfirm: false,
          submitting: false,
          vehicle: '{{ old('vehicle_type', 'motorcycle') }}',
          scope: '{{ old('service_scope', 'both') }}'
      }">

    <!-- Clean Talabat-Style Sticky Top Navbar -->
    <header class="sticky top-0 z-40 bg-white/95 backdrop-blur-md border-b border-slate-200/80">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex items-center justify-between h-20 gap-4">
                <!-- Brand -->
                <a href="{{ $mainSiteHref }}" class="flex items-center gap-3 flex-shrink-0">
                    <img src="{{ asset('images/logo.png') }}" alt="DrRoom" class="w-11 h-11 rounded-2xl border border-slate-200 object-contain p-1 bg-white">
                    <div class="flex flex-col">
                        <div class="flex items-center gap-2">
                            <span class="text-xl font-black text-slate-900 leading-none" dir="ltr">Dr<span class="text-[#FF5A00]">Room</span></span>
                            <span class="px-2.5 py-1 rounded-full text-[11px] font-extrabold bg-[#FFF3EB] text-[#FF5A00] border border-[#FFD6BF]">
                                {{ __('landing.delivery_short') }}
                            </span>
                        </div>
                        <span class="text-[11px] text-slate-500 font-semibold mt-1 hidden sm:block">{{ __('delivery.brand_tag') }}</span>
                    </div>
                </a>

                <!-- Desktop Actions -->
                <div class="flex items-center gap-2.5 sm:gap-3">
                    <a href="{{ $mainSiteHref }}" class="hidden md:inline-flex items-center gap-1.5 text-xs font-bold text-slate-600 hover:text-[#FF5A00] px-3.5 py-2.5 rounded-xl hover:bg-orange-50/70 transition whitespace-nowrap">
                        {{ __('delivery.nav_home') }}
                    </a>
                    <a href="{{ route('staff.landing') }}" class="hidden sm:inline-flex items-center gap-1.5 text-xs font-bold text-slate-700 bg-slate-50 hover:bg-slate-100 border border-slate-200 px-3.5 py-2.5 rounded-xl transition whitespace-nowrap">
                        {{ __('delivery.nav_staff') }}
                    </a>

                    <!-- 3-Language Switcher -->
                    <div class="relative">
                        <button type="button" @click="langOpen = !langOpen" @click.away="langOpen = false"
                                class="flex items-center gap-2 px-3.5 py-2.5 rounded-xl bg-slate-50 hover:bg-slate-100 text-slate-700 font-bold text-xs border border-slate-200 transition">
                            <svg class="w-4 h-4 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5h12M9 3v2m1.048 9.5A18.022 18.022 0 016.412 9m6.088 9h7M11 21l5-10 5 10M12.751 5C11.783 10.77 8.07 15.61 3 18.129"></path>
                            </svg>
                            <span>{{ strtoupper($loc == 'ckb' ? 'KU' : $loc) }}</span>
                            <svg class="w-3.5 h-3.5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
                        </button>

                        <div x-show="langOpen" x-transition style="display: none;"
                             class="absolute end-0 mt-2 w-44 bg-white rounded-2xl border border-slate-200 shadow-xl py-2 z-50">
                            <a href="{{ $langHref('ckb') }}" class="flex items-center justify-between px-4 py-2.5 text-xs font-bold {{ $loc == 'ckb' ? 'text-[#FF5A00] bg-orange-50' : 'text-slate-700 hover:bg-slate-50' }}">
                                <span>کوردی (Kurdish)</span>
                                @if($loc == 'ckb') <span class="w-2 h-2 rounded-full bg-[#FF5A00]"></span> @endif
                            </a>
                            <a href="{{ $langHref('ar') }}" class="flex items-center justify-between px-4 py-2.5 text-xs font-bold {{ $loc == 'ar' ? 'text-[#FF5A00] bg-orange-50' : 'text-slate-700 hover:bg-slate-50' }}">
                                <span>العربية (Arabic)</span>
                                @if($loc == 'ar') <span class="w-2 h-2 rounded-full bg-[#FF5A00]"></span> @endif
                            </a>
                            <a href="{{ $langHref('en') }}" class="flex items-center justify-between px-4 py-2.5 text-xs font-bold {{ $loc == 'en' ? 'text-[#FF5A00] bg-orange-50' : 'text-slate-700 hover:bg-slate-50' }}">
                                <span>English</span>
                                @if($loc == 'en') <span class="w-2 h-2 rounded-full bg-[#FF5A00]"></span> @endif
                            </a>
                        </div>
                    </div>

                    <a href="#register-form" class="hidden sm:inline-flex items-center justify-center px-5 py-2.5 rounded-xl bg-[#FF5A00] hover:bg-[#E04F00] text-white text-xs font-extrabold shadow-md shadow-orange-500/20 transition whitespace-nowrap">
                        {{ __('delivery.nav_join') }}
                    </a>
                </div>
            </div>
        </div>
    </header>

    <!-- Warm Talabat-Inspired Split Hero + Clean Form -->
    <section class="relative bg-gradient-to-b from-[#FFF6F0] via-[#FFF9F5] to-[#F8FAFC] border-b border-slate-200/70 py-10 sm:py-14 lg:py-16">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="grid grid-cols-1 lg:grid-cols-12 gap-10 lg:gap-12 items-start">

                <!-- Story & Benefits Side -->
                <div class="lg:col-span-6 space-y-8 text-start pt-2">
                    <div class="inline-flex items-center gap-2.5 px-4 py-2 rounded-full bg-white border border-orange-200 shadow-sm text-[#FF5A00] text-xs font-extrabold">
                        <span class="relative flex h-2.5 w-2.5">
                            <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-orange-400 opacity-75"></span>
                            <span class="relative inline-flex rounded-full h-2.5 w-2.5 bg-[#FF5A00]"></span>
                        </span>
                        <span>{{ __('delivery.badge') }}</span>
                    </div>

                    <div class="space-y-4">
                        <h1 class="kurdish-heading text-3xl sm:text-4xl lg:text-[42px] font-black text-slate-900">
                            <span class="block">{{ __('delivery.hero_title_1') }}</span>
                            <span class="block text-[#FF5A00] mt-2">{{ __('delivery.hero_title_2') }}</span>
                        </h1>

                        <p class="text-base sm:text-[17px] text-slate-600 leading-[2.0] font-medium max-w-xl">
                            {{ __('delivery.hero_desc') }}
                        </p>
                    </div>

                    <!-- Vibrant Talabat-Style Courier Visual Banner Card -->
                    <div class="bg-gradient-to-br from-[#FF5A00] to-[#FF7A2F] rounded-3xl p-6 sm:p-7 text-white shadow-xl shadow-orange-500/20 relative overflow-hidden">
                        <div class="absolute -end-10 -bottom-10 w-44 h-44 rounded-full bg-white/10"></div>
                        <div class="absolute top-4 end-6 w-20 h-20 rounded-full bg-white/10"></div>

                        <div class="relative flex flex-col sm:flex-row sm:items-center justify-between gap-5">
                            <div class="space-y-2.5">
                                <span class="inline-block text-[11px] font-extrabold uppercase tracking-wider bg-white/20 px-3 py-1 rounded-full">
                                    DrRoom Rider App
                                </span>
                                <h3 class="text-xl font-black leading-relaxed">
                                    {{ __('delivery.feat_1_title') }}
                                </h3>
                                <p class="text-xs sm:text-sm text-orange-50 leading-relaxed max-w-md">
                                    {{ __('delivery.feat_1_desc') }}
                                </p>
                            </div>

                            <!-- Crisp Courier Scooter Vector -->
                            <div class="w-24 h-24 sm:w-28 sm:h-28 rounded-2xl bg-white/15 backdrop-blur border border-white/25 flex items-center justify-center flex-shrink-0">
                                <svg class="w-16 h-16 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.6" d="M5 17a2.5 2.5 0 105 0 2.5 2.5 0 00-5 0zm10 0a2.5 2.5 0 105 0 2.5 2.5 0 00-5 0zM9 17h6m-2-6V7a1 1 0 011-1h2.586a1 1 0 01.707.293l2.414 2.414A1 1 0 0120 9.414V14a1 1 0 01-1 1h-1M3 8h7a1 1 0 011 1v6H4a1 1 0 01-1-1V8z"/>
                                </svg>
                            </div>
                        </div>
                    </div>

                    <!-- Benefit Feature Cards (Spacious, Clean Borders, Zero Clutter) -->
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                        <div class="bg-white border border-slate-200 rounded-2xl p-5 space-y-2.5 shadow-sm">
                            <div class="w-11 h-11 rounded-2xl bg-emerald-50 text-emerald-600 flex items-center justify-center border border-emerald-100">
                                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>
                            </div>
                            <h4 class="text-sm font-extrabold text-slate-900 leading-relaxed">{{ __('delivery.feat_2_title') }}</h4>
                            <p class="text-xs text-slate-500 leading-[1.85]">{{ __('delivery.feat_2_desc') }}</p>
                        </div>

                        <div class="bg-white border border-slate-200 rounded-2xl p-5 space-y-2.5 shadow-sm">
                            <div class="w-11 h-11 rounded-2xl bg-blue-50 text-[#1e60eb] flex items-center justify-center border border-blue-100">
                                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"></path></svg>
                            </div>
                            <h4 class="text-sm font-extrabold text-slate-900 leading-relaxed">{{ __('delivery.feat_3_title') }}</h4>
                            <p class="text-xs text-slate-500 leading-[1.85]">{{ __('delivery.feat_3_desc') }}</p>
                        </div>
                    </div>
                </div>

                <!-- Registration Form Card (Clean Single-Column Flow, Zero Overlapping) -->
                <div class="lg:col-span-6" id="register-form">
                    <div class="bg-white rounded-[28px] border border-slate-200/90 shadow-2xl shadow-slate-200/60 p-6 sm:p-9 text-start">
                        <div class="pb-6 mb-6 border-b border-slate-100">
                            <h2 class="text-xl sm:text-2xl font-black text-slate-900 leading-relaxed">{{ __('delivery.form_title') }}</h2>
                            <p class="text-xs sm:text-sm text-slate-500 mt-2 leading-[1.9]">{{ __('delivery.form_subtitle') }}</p>
                        </div>

                        @if($errors->any())
                            <div class="mb-6 p-4 rounded-2xl bg-red-50 border border-red-200 text-red-700 text-xs font-bold space-y-1.5 leading-relaxed">
                                @foreach($errors->all() as $error)
                                    <p>• {{ $error }}</p>
                                @endforeach
                            </div>
                        @endif

                        <form method="POST" action="{{ route('delivery.register') }}" class="space-y-5" @submit="submitting = true">
                            @csrf
                            <input type="hidden" name="locale" value="{{ $loc }}">
                            <input type="hidden" name="vehicle_type" x-model="vehicle">
                            <input type="hidden" name="service_scope" x-model="scope">

                            <!-- 1. Full Name -->
                            <div>
                                <label class="block text-xs font-extrabold text-slate-700 mb-2">{{ __('delivery.full_name') }} <span class="text-red-500">*</span></label>
                                <input type="text" name="name" value="{{ old('name') }}" required
                                       placeholder="{{ __('delivery.full_name_placeholder') }}"
                                       class="w-full h-12 px-4 rounded-2xl bg-slate-50 border border-slate-200 text-sm font-semibold text-slate-900 placeholder:text-slate-400 focus:bg-white focus:border-[#FF5A00] focus:ring-4 focus:ring-orange-500/10 outline-none transition">
                            </div>

                            <!-- 2. Phone Number (Always clean Iraq flag prefix box + LTR digits) -->
                            <div>
                                <label class="block text-xs font-extrabold text-slate-700 mb-2">{{ __('delivery.phone') }} <span class="text-red-500">*</span></label>
                                <div dir="ltr" class="flex items-center h-12 rounded-2xl bg-slate-50 border border-slate-200 focus-within:bg-white focus-within:border-[#FF5A00] focus-within:ring-4 focus-within:ring-orange-500/10 overflow-hidden transition">
                                    <div class="px-4 h-full bg-orange-50/80 border-r border-slate-200 flex items-center gap-1.5 text-xs font-black text-[#FF5A00] flex-shrink-0">
                                        <span>🇮🇶</span>
                                        <span>+964</span>
                                    </div>
                                    <input type="tel" name="phone" value="{{ old('phone') }}" required dir="ltr"
                                           placeholder="{{ __('delivery.phone_placeholder') }}"
                                           class="flex-1 h-full px-4 bg-transparent text-sm font-bold text-slate-900 placeholder:text-slate-400 outline-none text-left">
                                </div>
                                <p class="text-[11px] text-slate-400 mt-1.5 font-medium leading-relaxed">{{ __('delivery.phone_hint') }}</p>
                            </div>

                            <!-- 3. City & Plate Number (Clean 2-col on SM+, no cramped clipping) -->
                            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                                <div>
                                    <label class="block text-xs font-extrabold text-slate-700 mb-2">{{ __('delivery.city') }} <span class="text-red-500">*</span></label>
                                    <select name="city"
                                            class="w-full h-12 px-4 rounded-2xl bg-slate-50 border border-slate-200 text-sm font-bold text-slate-900 focus:bg-white focus:border-[#FF5A00] focus:ring-4 focus:ring-orange-500/10 outline-none transition">
                                        @foreach($cities as $c)
                                            <option value="{{ $c }}" {{ old('city') == $c ? 'selected' : '' }}>{{ $c }}</option>
                                        @endforeach
                                    </select>
                                </div>

                                <div>
                                    <label class="block text-xs font-extrabold text-slate-700 mb-2">{{ __('delivery.plate_number') }}</label>
                                    <input type="text" name="plate_number" value="{{ old('plate_number') }}" dir="ltr"
                                           placeholder="{{ __('delivery.plate_placeholder') }}"
                                           class="w-full h-12 px-4 rounded-2xl bg-slate-50 border border-slate-200 text-sm font-semibold text-slate-900 text-left placeholder:text-slate-400 focus:bg-white focus:border-[#FF5A00] focus:ring-4 focus:ring-orange-500/10 outline-none transition">
                                </div>
                            </div>

                            <!-- 4. Visual Vehicle Selector Cards (Talabat-style Pill Cards — NEVER clips Kurdish!) -->
                            <div>
                                <label class="block text-xs font-extrabold text-slate-700 mb-2.5">{{ __('delivery.vehicle_type') }}</label>
                                <div class="grid grid-cols-3 gap-2.5">
                                    @foreach(['motorcycle' => '🛵', 'car' => '🚗', 'refrigerated_van' => '🧊'] as $vKey => $emoji)
                                        <button type="button" @click="vehicle = '{{ $vKey }}'"
                                                :class="vehicle === '{{ $vKey }}'
                                                    ? 'bg-[#FFF3EB] border-[#FF5A00] text-[#FF5A00] ring-2 ring-orange-500/15'
                                                    : 'bg-slate-50 border-slate-200 text-slate-700 hover:bg-slate-100'"
                                                class="py-3 px-2 rounded-2xl border text-center transition flex flex-col items-center gap-1.5">
                                            <span class="text-xl leading-none">{{ $emoji }}</span>
                                            <span class="text-[11.5px] font-extrabold leading-snug">{{ __('delivery.vehicle_short_' . $vKey) }}</span>
                                        </button>
                                    @endforeach
                                </div>
                            </div>

                            <!-- 5. Visual Service Scope Pills -->
                            <div>
                                <label class="block text-xs font-extrabold text-slate-700 mb-2.5">{{ __('delivery.service_scope') }}</label>
                                <div class="grid grid-cols-3 gap-2.5">
                                    @foreach(['both', 'pharmacy', 'lab_sample'] as $sKey)
                                        <button type="button" @click="scope = '{{ $sKey }}'"
                                                :class="scope === '{{ $sKey }}'
                                                    ? 'bg-[#FFF3EB] border-[#FF5A00] text-[#FF5A00] ring-2 ring-orange-500/15'
                                                    : 'bg-slate-50 border-slate-200 text-slate-700 hover:bg-slate-100'"
                                                class="py-3 px-2 rounded-2xl border text-center transition text-[11.5px] font-extrabold leading-snug">
                                            {{ __('delivery.scope_short_' . $sKey) }}
                                        </button>
                                    @endforeach
                                </div>
                            </div>

                            <!-- 6. Password & Confirm (Flex container -> Eye toggle NEVER overlaps text!) -->
                            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                                <div>
                                    <label class="block text-xs font-extrabold text-slate-700 mb-2">{{ __('delivery.password') }} <span class="text-red-500">*</span></label>
                                    <div class="flex items-center h-12 rounded-2xl bg-slate-50 border border-slate-200 focus-within:bg-white focus-within:border-[#FF5A00] focus-within:ring-4 focus-within:ring-orange-500/10 overflow-hidden transition">
                                        <input :type="showPass ? 'text' : 'password'" name="password" required minlength="6"
                                               placeholder="{{ __('delivery.password_placeholder') }}"
                                               class="flex-1 min-w-0 h-full px-4 bg-transparent text-sm font-semibold text-slate-900 placeholder:text-slate-400 placeholder:text-xs outline-none">
                                        <button type="button" @click="showPass = !showPass"
                                                class="px-3.5 h-full text-slate-400 hover:text-slate-700 flex items-center justify-center flex-shrink-0">
                                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path></svg>
                                        </button>
                                    </div>
                                </div>

                                <div>
                                    <label class="block text-xs font-extrabold text-slate-700 mb-2">{{ __('delivery.password_confirm') }} <span class="text-red-500">*</span></label>
                                    <div class="flex items-center h-12 rounded-2xl bg-slate-50 border border-slate-200 focus-within:bg-white focus-within:border-[#FF5A00] focus-within:ring-4 focus-within:ring-orange-500/10 overflow-hidden transition">
                                        <input :type="showConfirm ? 'text' : 'password'" name="password_confirmation" required minlength="6"
                                               placeholder="{{ __('delivery.password_confirm_placeholder') }}"
                                               class="flex-1 min-w-0 h-full px-4 bg-transparent text-sm font-semibold text-slate-900 placeholder:text-slate-400 placeholder:text-xs outline-none">
                                        <button type="button" @click="showConfirm = !showConfirm"
                                                class="px-3.5 h-full text-slate-400 hover:text-slate-700 flex items-center justify-center flex-shrink-0">
                                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path></svg>
                                        </button>
                                    </div>
                                </div>
                            </div>

                            <!-- 7. Vibrant Talabat CTA Button -->
                            <div class="pt-2">
                                <button type="submit" :disabled="submitting"
                                        class="w-full min-h-[52px] py-3.5 px-6 rounded-2xl bg-[#FF5A00] hover:bg-[#E04F00] disabled:opacity-60 text-white font-black text-sm shadow-lg shadow-orange-500/25 transition flex items-center justify-center gap-2 active:scale-[0.99]">
                                    <span x-show="!submitting">{{ __('delivery.submit_btn') }}</span>
                                    <span x-show="submitting" style="display: none;">{{ __('delivery.submitting') }}</span>
                                </button>
                            </div>

                            <p class="text-[11.5px] text-center text-slate-400 font-medium leading-[1.85] pt-1">
                                {{ __('delivery.step_note') }}
                            </p>
                        </form>
                    </div>
                </div>

            </div>
        </div>
    </section>

    <!-- 3 Simple Steps Section (Talabat Rider Style) -->
    <section class="py-12 sm:py-16 bg-white border-b border-slate-200/70">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="text-center max-w-2xl mx-auto mb-10 space-y-2.5">
                <h2 class="kurdish-heading text-2xl sm:text-3xl font-black text-slate-900">{{ __('delivery.how_title') }}</h2>
                <p class="text-xs sm:text-sm text-slate-500 leading-relaxed">{{ __('delivery.how_sub') }}</p>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                @foreach([
                    ['icon' => '📝', 'title' => __('delivery.step1_t'), 'desc' => __('delivery.step1_d')],
                    ['icon' => '✅', 'title' => __('delivery.step2_t'), 'desc' => __('delivery.step2_d')],
                    ['icon' => '🛵', 'title' => __('delivery.step3_t'), 'desc' => __('delivery.step3_d')],
                ] as $step)
                    <div class="bg-[#F8FAFC] border border-slate-200/80 rounded-3xl p-6 space-y-3 text-start">
                        <div class="w-12 h-12 rounded-2xl bg-white border border-slate-200 flex items-center justify-center text-2xl shadow-sm">
                            {{ $step['icon'] }}
                        </div>
                        <h3 class="text-base font-black text-slate-900 leading-relaxed">{{ $step['title'] }}</h3>
                        <p class="text-xs sm:text-sm text-slate-600 leading-[1.9]">{{ $step['desc'] }}</p>
                    </div>
                @endforeach
            </div>
        </div>
    </section>

    <footer class="py-7 bg-slate-50 text-center">
        <p class="text-xs font-bold text-slate-400">{{ __('delivery.footer_copy') }}</p>
    </footer>

</body>
</html>
