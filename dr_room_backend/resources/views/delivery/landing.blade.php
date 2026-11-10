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
</head>
<body class="bg-slate-50 text-slate-900 antialiased min-h-screen flex flex-col selection:bg-blue-100 selection:text-blue-900 overflow-x-hidden" x-data="{ langOpen: false, showPass: false, showConfirm: false, submitting: false }">

    <!-- Top Navigation Bar -->
    <header class="sticky top-0 z-40 bg-white/95 backdrop-blur-md border-b border-slate-200/80">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex items-center justify-between h-18 py-3.5 gap-3">
                <a href="{{ $mainSiteHref }}" class="flex items-center gap-3 group flex-shrink-0">
                    <img src="{{ asset('images/logo.png') }}" alt="DrRoom" class="w-10 h-10 rounded-xl border border-slate-200 object-contain p-1 bg-white">
                    <div class="flex flex-col">
                        <div class="flex items-center gap-2">
                            <span class="text-lg font-black text-slate-900 leading-none" dir="ltr">Dr<span class="text-[#1e60eb]">Room</span></span>
                            <span class="px-2 py-0.5 rounded-lg text-[10px] font-extrabold bg-emerald-50 text-emerald-700 border border-emerald-200">{{ __('landing.delivery_short') }}</span>
                        </div>
                        <span class="text-[10px] text-slate-400 font-semibold mt-0.5 hidden sm:block">{{ __('delivery.brand_tag') }}</span>
                    </div>
                </a>

                <div class="flex items-center gap-2 sm:gap-3">
                    <a href="{{ $mainSiteHref }}" class="hidden md:inline-flex items-center gap-1.5 text-xs font-bold text-slate-600 hover:text-blue-600 px-3 py-2 rounded-xl hover:bg-slate-50 transition whitespace-nowrap">
                        <span>{{ __('delivery.nav_home') }}</span>
                    </a>
                    <a href="{{ route('staff.landing') }}" class="hidden sm:inline-flex items-center gap-1.5 text-xs font-bold text-slate-700 bg-slate-50 hover:bg-blue-50 hover:text-blue-600 border border-slate-200 px-3 py-2 rounded-xl transition whitespace-nowrap">
                        <span>{{ __('delivery.nav_staff') }}</span>
                    </a>

                    <!-- 3-Language Switcher -->
                    <div class="relative">
                        <button type="button" @click="langOpen = !langOpen" @click.away="langOpen = false"
                                class="flex items-center gap-1.5 px-3 py-2 rounded-xl bg-slate-50 hover:bg-slate-100 text-slate-700 font-bold text-xs border border-slate-200 transition">
                            <svg class="w-4 h-4 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5h12M9 3v2m1.048 9.5A18.022 18.022 0 016.412 9m6.088 9h7M11 21l5-10 5 10M12.751 5C11.783 10.77 8.07 15.61 3 18.129"></path>
                            </svg>
                            <span>{{ strtoupper($loc == 'ckb' ? 'KU' : $loc) }}</span>
                            <svg class="w-3.5 h-3.5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
                        </button>

                        <div x-show="langOpen" x-transition style="display: none;"
                             class="absolute end-0 mt-2 w-40 bg-white rounded-2xl border border-slate-200 shadow-lg py-1.5 z-50">
                            <a href="{{ $langHref('ckb') }}" class="flex items-center justify-between px-4 py-2 text-xs font-bold {{ $loc == 'ckb' ? 'text-blue-600 bg-blue-50' : 'text-slate-700 hover:bg-slate-50' }}">
                                <span>کوردی (Kurdish)</span>
                                @if($loc == 'ckb') <span class="w-1.5 h-1.5 rounded-full bg-blue-600"></span> @endif
                            </a>
                            <a href="{{ $langHref('ar') }}" class="flex items-center justify-between px-4 py-2 text-xs font-bold {{ $loc == 'ar' ? 'text-blue-600 bg-blue-50' : 'text-slate-700 hover:bg-slate-50' }}">
                                <span>العربية (Arabic)</span>
                                @if($loc == 'ar') <span class="w-1.5 h-1.5 rounded-full bg-blue-600"></span> @endif
                            </a>
                            <a href="{{ $langHref('en') }}" class="flex items-center justify-between px-4 py-2 text-xs font-bold {{ $loc == 'en' ? 'text-blue-600 bg-blue-50' : 'text-slate-700 hover:bg-slate-50' }}">
                                <span>English</span>
                                @if($loc == 'en') <span class="w-1.5 h-1.5 rounded-full bg-blue-600"></span> @endif
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </header>

    <!-- Main Hero + Clean Registration Card -->
    <main class="flex-1 py-8 sm:py-12 lg:py-14">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="grid grid-cols-1 lg:grid-cols-12 gap-8 lg:gap-12 items-start">

                <!-- Left / Narrative & Benefits -->
                <div class="lg:col-span-5 space-y-6 pt-2">
                    <div class="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-emerald-50 border border-emerald-200 text-emerald-700 text-xs font-extrabold">
                        <span class="relative flex h-2 w-2">
                            <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                            <span class="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
                        </span>
                        <span>{{ __('delivery.badge') }}</span>
                    </div>

                    <h1 class="text-3xl sm:text-4xl lg:text-[40px] font-black text-slate-900 leading-[1.45]">
                        {{ __('delivery.hero_title_1') }}
                        <span class="text-[#1e60eb] block mt-1">{{ __('delivery.hero_title_2') }}</span>
                    </h1>

                    <p class="text-sm sm:text-base text-slate-600 leading-[1.9] font-medium">
                        {{ __('delivery.hero_desc') }}
                    </p>

                    <!-- Quick Language Pills for Mobile Convenience -->
                    <div class="flex flex-wrap items-center gap-2 sm:hidden">
                        <a href="{{ $langHref('ckb') }}" class="px-3 py-1.5 rounded-xl text-xs font-bold border {{ $loc == 'ckb' ? 'bg-blue-600 text-white border-blue-600' : 'bg-white text-slate-700 border-slate-200' }}">کوردی</a>
                        <a href="{{ $langHref('ar') }}" class="px-3 py-1.5 rounded-xl text-xs font-bold border {{ $loc == 'ar' ? 'bg-blue-600 text-white border-blue-600' : 'bg-white text-slate-700 border-slate-200' }}">العربية</a>
                        <a href="{{ $langHref('en') }}" class="px-3 py-1.5 rounded-xl text-xs font-bold border {{ $loc == 'en' ? 'bg-blue-600 text-white border-blue-600' : 'bg-white text-slate-700 border-slate-200' }}">English</a>
                    </div>

                    <!-- Highlights -->
                    <div class="space-y-3.5 pt-2">
                        <div class="bg-white border border-slate-200/90 rounded-2xl p-4 flex items-start gap-3.5">
                            <div class="w-10 h-10 rounded-xl bg-blue-50 border border-blue-100 text-[#1e60eb] flex items-center justify-center flex-shrink-0">
                                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                            </div>
                            <div>
                                <h3 class="text-sm font-extrabold text-slate-900">{{ __('delivery.feat_1_title') }}</h3>
                                <p class="text-xs text-slate-500 mt-1 leading-relaxed">{{ __('delivery.feat_1_desc') }}</p>
                            </div>
                        </div>

                        <div class="bg-white border border-slate-200/90 rounded-2xl p-4 flex items-start gap-3.5">
                            <div class="w-10 h-10 rounded-xl bg-emerald-50 border border-emerald-100 text-emerald-600 flex items-center justify-center flex-shrink-0">
                                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>
                            </div>
                            <div>
                                <h3 class="text-sm font-extrabold text-slate-900">{{ __('delivery.feat_2_title') }}</h3>
                                <p class="text-xs text-slate-500 mt-1 leading-relaxed">{{ __('delivery.feat_2_desc') }}</p>
                            </div>
                        </div>

                        <div class="bg-white border border-slate-200/90 rounded-2xl p-4 flex items-start gap-3.5">
                            <div class="w-10 h-10 rounded-xl bg-indigo-50 border border-indigo-100 text-indigo-600 flex items-center justify-center flex-shrink-0">
                                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"></path></svg>
                            </div>
                            <div>
                                <h3 class="text-sm font-extrabold text-slate-900">{{ __('delivery.feat_3_title') }}</h3>
                                <p class="text-xs text-slate-500 mt-1 leading-relaxed">{{ __('delivery.feat_3_desc') }}</p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Right / Responsive Self-Registration Card -->
                <div class="lg:col-span-7">
                    <div class="bg-white rounded-3xl border border-slate-200/90 shadow-xl shadow-slate-200/40 p-6 sm:p-8 lg:p-9">
                        <div class="mb-6">
                            <h2 class="text-xl sm:text-2xl font-black text-slate-900">{{ __('delivery.form_title') }}</h2>
                            <p class="text-xs sm:text-sm text-slate-500 mt-2 leading-relaxed">{{ __('delivery.form_subtitle') }}</p>
                        </div>

                        @if($errors->any())
                            <div class="mb-5 p-4 rounded-2xl bg-red-50 border border-red-200 text-red-700 text-xs font-bold space-y-1">
                                @foreach($errors->all() as $error)
                                    <p>• {{ $error }}</p>
                                @endforeach
                            </div>
                        @endif

                        <form method="POST" action="{{ route('delivery.register') }}" class="space-y-4" @submit="submitting = true">
                            @csrf
                            <input type="hidden" name="locale" value="{{ $loc }}">

                            <!-- Full Name -->
                            <div>
                                <label class="block text-xs font-extrabold text-slate-700 mb-1.5">{{ __('delivery.full_name') }} <span class="text-red-500">*</span></label>
                                <input type="text" name="name" value="{{ old('name') }}" required
                                       placeholder="{{ __('delivery.full_name_placeholder') }}"
                                       class="w-full px-4 py-3 rounded-xl bg-slate-50 border border-slate-200 text-sm font-semibold text-slate-900 focus:bg-white focus:border-[#1e60eb] focus:ring-2 focus:ring-blue-500/15 outline-none transition">
                            </div>

                            <!-- Phone Number & City -->
                            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                                <div>
                                    <label class="block text-xs font-extrabold text-slate-700 mb-1.5">{{ __('delivery.phone') }} <span class="text-red-500">*</span></label>
                                    <input type="tel" name="phone" value="{{ old('phone') }}" required dir="ltr"
                                           placeholder="{{ __('delivery.phone_placeholder') }}"
                                           class="w-full px-4 py-3 rounded-xl bg-slate-50 border border-slate-200 text-sm font-bold text-slate-900 text-left focus:bg-white focus:border-[#1e60eb] focus:ring-2 focus:ring-blue-500/15 outline-none transition">
                                    <p class="text-[11px] text-slate-400 mt-1 font-medium">{{ __('delivery.phone_hint') }}</p>
                                </div>

                                <div>
                                    <label class="block text-xs font-extrabold text-slate-700 mb-1.5">{{ __('delivery.city') }} <span class="text-red-500">*</span></label>
                                    <select name="city"
                                            class="w-full px-4 py-3 rounded-xl bg-slate-50 border border-slate-200 text-sm font-semibold text-slate-900 focus:bg-white focus:border-[#1e60eb] focus:ring-2 focus:ring-blue-500/15 outline-none transition">
                                        @foreach($cities as $c)
                                            <option value="{{ $c }}" {{ old('city') == $c ? 'selected' : '' }}>{{ $c }}</option>
                                        @endforeach
                                    </select>
                                </div>
                            </div>

                            <!-- Vehicle Type & Service Scope -->
                            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                                <div>
                                    <label class="block text-xs font-extrabold text-slate-700 mb-1.5">{{ __('delivery.vehicle_type') }}</label>
                                    <select name="vehicle_type"
                                            class="w-full px-4 py-3 rounded-xl bg-slate-50 border border-slate-200 text-sm font-semibold text-slate-900 focus:bg-white focus:border-[#1e60eb] focus:ring-2 focus:ring-blue-500/15 outline-none transition">
                                        @foreach(__('delivery.vehicles') as $vKey => $vLabel)
                                            <option value="{{ $vKey }}" {{ old('vehicle_type', 'motorcycle') == $vKey ? 'selected' : '' }}>{{ $vLabel }}</option>
                                        @endforeach
                                    </select>
                                </div>

                                <div>
                                    <label class="block text-xs font-extrabold text-slate-700 mb-1.5">{{ __('delivery.service_scope') }}</label>
                                    <select name="service_scope"
                                            class="w-full px-4 py-3 rounded-xl bg-slate-50 border border-slate-200 text-sm font-semibold text-slate-900 focus:bg-white focus:border-[#1e60eb] focus:ring-2 focus:ring-blue-500/15 outline-none transition">
                                        @foreach(__('delivery.scopes') as $sKey => $sLabel)
                                            <option value="{{ $sKey }}" {{ old('service_scope', 'both') == $sKey ? 'selected' : '' }}>{{ $sLabel }}</option>
                                        @endforeach
                                    </select>
                                </div>
                            </div>

                            <!-- Optional Plate Number -->
                            <div>
                                <label class="block text-xs font-extrabold text-slate-700 mb-1.5">{{ __('delivery.plate_number') }}</label>
                                <input type="text" name="plate_number" value="{{ old('plate_number') }}" dir="ltr"
                                       placeholder="{{ __('delivery.plate_placeholder') }}"
                                       class="w-full px-4 py-3 rounded-xl bg-slate-50 border border-slate-200 text-sm font-semibold text-slate-900 text-left focus:bg-white focus:border-[#1e60eb] focus:ring-2 focus:ring-blue-500/15 outline-none transition">
                            </div>

                            <!-- Password & Confirmation -->
                            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                                <div>
                                    <label class="block text-xs font-extrabold text-slate-700 mb-1.5">{{ __('delivery.password') }} <span class="text-red-500">*</span></label>
                                    <div class="relative">
                                        <input :type="showPass ? 'text' : 'password'" name="password" required minlength="6" dir="ltr"
                                               placeholder="{{ __('delivery.password_placeholder') }}"
                                               class="w-full px-4 py-3 pe-11 rounded-xl bg-slate-50 border border-slate-200 text-sm font-semibold text-slate-900 text-left focus:bg-white focus:border-[#1e60eb] focus:ring-2 focus:ring-blue-500/15 outline-none transition">
                                        <button type="button" @click="showPass = !showPass"
                                                class="absolute inset-y-0 end-0 px-3 text-slate-400 hover:text-slate-600 flex items-center">
                                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path></svg>
                                        </button>
                                    </div>
                                </div>

                                <div>
                                    <label class="block text-xs font-extrabold text-slate-700 mb-1.5">{{ __('delivery.password_confirm') }} <span class="text-red-500">*</span></label>
                                    <div class="relative">
                                        <input :type="showConfirm ? 'text' : 'password'" name="password_confirmation" required minlength="6" dir="ltr"
                                               placeholder="{{ __('delivery.password_confirm_placeholder') }}"
                                               class="w-full px-4 py-3 pe-11 rounded-xl bg-slate-50 border border-slate-200 text-sm font-semibold text-slate-900 text-left focus:bg-white focus:border-[#1e60eb] focus:ring-2 focus:ring-blue-500/15 outline-none transition">
                                        <button type="button" @click="showConfirm = !showConfirm"
                                                class="absolute inset-y-0 end-0 px-3 text-slate-400 hover:text-slate-600 flex items-center">
                                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path></svg>
                                        </button>
                                    </div>
                                </div>
                            </div>

                            <div class="pt-2">
                                <button type="submit" :disabled="submitting"
                                        class="w-full py-3.5 px-6 rounded-2xl bg-[#1e60eb] hover:bg-blue-700 disabled:opacity-60 text-white font-extrabold text-sm shadow-lg shadow-blue-600/20 transition flex items-center justify-center gap-2 active:scale-[0.99]">
                                    <span x-show="!submitting">{{ __('delivery.submit_btn') }}</span>
                                    <span x-show="submitting" style="display: none;">{{ __('delivery.submitting') }}</span>
                                </button>
                            </div>

                            <p class="text-[11px] text-center text-slate-400 font-medium pt-1">
                                {{ __('delivery.step_note') }}
                            </p>
                        </form>
                    </div>
                </div>

            </div>
        </div>
    </main>

</body>
</html>
