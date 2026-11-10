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
                    },
                    colors: {
                        brand: { DEFAULT: '#FF5A00', dark: '#E04F00', soft: '#FFF1E8' },
                    },
                }
            }
        }
    </script>
    <style>
        body {
            font-family: {{ $isRtl ? "'Noto Kufi Arabic', sans-serif" : "'Plus Jakarta Sans', 'Noto Kufi Arabic', sans-serif" }};
        }
        .kurdish-heading {
            line-height: 1.9 !important;
        }
        .grad-text {
            background-image: linear-gradient(90deg, #FF5A00 0%, #FF8A3D 100%);
            -webkit-background-clip: text;
            background-clip: text;
            color: transparent;
        }
        .hero-mesh {
            background:
                radial-gradient(60% 50% at 0% 0%, rgba(255, 90, 0, 0.14) 0%, transparent 70%),
                radial-gradient(50% 45% at 100% 20%, rgba(30, 96, 235, 0.10) 0%, transparent 70%),
                radial-gradient(60% 50% at 50% 100%, rgba(255, 138, 61, 0.12) 0%, transparent 70%),
                #FCFAF8;
        }
        .field {
            width: 100%;
            height: 3rem;
            padding: 0 1rem;
            border-radius: 0.875rem;
            background: #ffffff;
            border: 1px solid #e2e8f0;
            font-size: 0.875rem;
            font-weight: 600;
            color: #0f172a;
            outline: none;
            transition: border-color .2s, box-shadow .2s;
        }
        .field::placeholder { color: #94a3b8; font-weight: 500; }
        .field:focus {
            border-color: #FF5A00;
            box-shadow: 0 0 0 4px rgba(255, 90, 0, 0.12);
        }
        .field-wrap {
            display: flex;
            align-items: center;
            height: 3rem;
            border-radius: 0.875rem;
            background: #ffffff;
            border: 1px solid #e2e8f0;
            overflow: hidden;
            transition: border-color .2s, box-shadow .2s;
        }
        .field-wrap:focus-within {
            border-color: #FF5A00;
            box-shadow: 0 0 0 4px rgba(255, 90, 0, 0.12);
        }
        .field-wrap .field {
            border: 0;
            box-shadow: none;
            border-radius: 0;
            flex: 1;
            min-width: 0;
        }
        .field-wrap .field:focus { box-shadow: none; }
        .label {
            display: block;
            font-size: 0.8125rem;
            font-weight: 700;
            color: #334155;
            margin-bottom: 0.5rem;
        }
        .opt {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            gap: 0.5rem;
            padding: 0.875rem 0.5rem;
            border-radius: 1rem;
            border: 1.5px solid #e2e8f0;
            background: #ffffff;
            color: #475569;
            font-size: 0.75rem;
            font-weight: 700;
            line-height: 1.5;
            text-align: center;
            transition: all .2s ease;
            cursor: pointer;
        }
        .opt:hover { border-color: #cbd5e1; background: #f8fafc; }
        .opt.is-on {
            border-color: #FF5A00;
            background: #FFF4EE;
            color: #FF5A00;
            box-shadow: 0 6px 18px -8px rgba(255, 90, 0, 0.45);
        }
        .opt-icon {
            width: 2.5rem;
            height: 2.5rem;
            border-radius: 0.75rem;
            display: flex;
            align-items: center;
            justify-content: center;
            background: #f1f5f9;
            color: #64748b;
            transition: all .2s ease;
        }
        .opt.is-on .opt-icon { background: #FF5A00; color: #ffffff; }
        .reveal { animation: rise .7s cubic-bezier(.2,.7,.2,1) both; }
        .reveal-2 { animation: rise .7s .12s cubic-bezier(.2,.7,.2,1) both; }
        .reveal-3 { animation: rise .7s .24s cubic-bezier(.2,.7,.2,1) both; }
        @keyframes rise {
            from { opacity: 0; transform: translateY(14px); }
            to   { opacity: 1; transform: translateY(0); }
        }
        @media (prefers-reduced-motion: reduce) {
            .reveal, .reveal-2, .reveal-3 { animation: none; }
        }
    </style>
</head>
<body class="hero-mesh text-slate-900 antialiased min-h-screen flex flex-col overflow-x-hidden selection:bg-orange-100 selection:text-orange-900"
      x-data="{
          langOpen: false,
          showPass: false,
          showConfirm: false,
          submitting: false,
          vehicle: '{{ old('vehicle_type', 'motorcycle') }}',
          scope: '{{ old('service_scope', 'both') }}'
      }">

    <!-- Floating Glass Navbar -->
    <header class="sticky top-0 z-40 px-3 sm:px-6 lg:px-8 pt-3">
        <div class="max-w-7xl mx-auto h-16 px-3 sm:px-5 flex items-center justify-between gap-3 rounded-2xl bg-white/75 backdrop-blur-xl border border-white/80 shadow-[0_10px_30px_-12px_rgba(15,23,42,0.18)]">
            <!-- Brand -->
            <a href="{{ $mainSiteHref }}" class="flex items-center gap-2.5 min-w-0">
                <img src="{{ asset('images/logo.png') }}" alt="DrRoom" class="w-10 h-10 rounded-xl object-contain bg-white ring-1 ring-slate-200/80 p-1 flex-shrink-0">
                <div class="flex items-center gap-2 min-w-0">
                    <span class="text-lg font-black text-slate-900 leading-none" dir="ltr">Dr<span class="text-[#FF5A00]">Room</span></span>
                    <span class="hidden sm:inline-flex px-2.5 py-1 rounded-full text-[11px] font-extrabold bg-[#FFF1E8] text-[#FF5A00] whitespace-nowrap">
                        {{ __('landing.delivery_short') }}
                    </span>
                </div>
            </a>

            <!-- Actions -->
            <div class="flex items-center gap-2">
                <a href="{{ $mainSiteHref }}" class="hidden md:inline-flex items-center px-3.5 py-2 rounded-xl text-xs font-bold text-slate-600 hover:text-[#FF5A00] hover:bg-orange-50 transition whitespace-nowrap">
                    {{ __('delivery.nav_home') }}
                </a>
                <a href="{{ route('staff.landing') }}" class="hidden sm:inline-flex items-center px-3.5 py-2 rounded-xl text-xs font-bold text-slate-700 bg-slate-100/80 hover:bg-slate-200/70 transition whitespace-nowrap">
                    {{ __('delivery.nav_staff') }}
                </a>

                <!-- Language Switcher -->
                <div class="relative">
                    <button type="button" @click="langOpen = !langOpen" @click.away="langOpen = false"
                            class="flex items-center gap-1.5 h-9 px-3 rounded-xl bg-slate-100/80 hover:bg-slate-200/70 text-slate-700 font-bold text-xs transition">
                        <svg class="w-4 h-4 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5h12M9 3v2m1.048 9.5A18.022 18.022 0 016.412 9m6.088 9h7M11 21l5-10 5 10M12.751 5C11.783 10.77 8.07 15.61 3 18.129"></path>
                        </svg>
                        <span>{{ strtoupper($loc == 'ckb' ? 'KU' : $loc) }}</span>
                        <svg class="w-3.5 h-3.5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
                    </button>

                    <div x-show="langOpen" x-transition style="display: none;"
                         class="absolute end-0 mt-2 w-44 bg-white rounded-2xl border border-slate-100 shadow-2xl shadow-slate-900/10 py-1.5 z-50">
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

                <a href="#register-form" class="hidden sm:inline-flex items-center h-9 px-4 rounded-xl bg-[#FF5A00] hover:bg-[#E04F00] text-white text-xs font-extrabold shadow-lg shadow-orange-500/25 transition whitespace-nowrap">
                    {{ __('delivery.nav_join') }}
                </a>
            </div>
        </div>
    </header>

    <!-- Hero -->
    <section class="relative flex-1 overflow-hidden">
        <!-- Ambient shapes -->
        <div class="pointer-events-none absolute -top-24 start-[-8rem] w-[28rem] h-[28rem] rounded-full bg-orange-300/25 blur-3xl"></div>
        <div class="pointer-events-none absolute top-40 end-[-6rem] w-[24rem] h-[24rem] rounded-full bg-blue-300/20 blur-3xl"></div>

        <div class="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-12 sm:pt-16 lg:pt-20 pb-16 sm:pb-20">
            <div class="grid grid-cols-1 lg:grid-cols-12 gap-12 lg:gap-16 items-center">

                <!-- Story Side -->
                <div class="lg:col-span-6 space-y-9 text-start">
                    <div class="reveal inline-flex items-center gap-2.5 ps-3 pe-4 py-1.5 rounded-full bg-white shadow-sm ring-1 ring-orange-100 text-[#FF5A00] text-xs font-extrabold">
                        <span class="relative flex h-2.5 w-2.5">
                            <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-orange-400 opacity-75"></span>
                            <span class="relative inline-flex rounded-full h-2.5 w-2.5 bg-[#FF5A00]"></span>
                        </span>
                        <span>{{ __('delivery.badge') }}</span>
                    </div>

                    <div class="reveal-2 space-y-5">
                        <h1 class="kurdish-heading text-[2.25rem] sm:text-5xl lg:text-[3.4rem] font-black text-slate-900 tracking-tight">
                            <span class="block">{{ __('delivery.hero_title_1') }}</span>
                            <span class="block grad-text pb-2">{{ __('delivery.hero_title_2') }}</span>
                        </h1>

                        <p class="text-base sm:text-lg text-slate-600 leading-[2] font-medium max-w-xl">
                            {{ __('delivery.hero_desc') }}
                        </p>
                    </div>

                    <!-- Featured Rider Card -->
                    <div class="reveal-3 relative overflow-hidden rounded-[1.75rem] bg-slate-900 text-white p-6 sm:p-7 shadow-2xl shadow-slate-900/20">
                        <div class="pointer-events-none absolute -end-16 -bottom-16 w-56 h-56 rounded-full bg-[#FF5A00]/40 blur-3xl"></div>
                        <div class="pointer-events-none absolute -start-10 -top-10 w-36 h-36 rounded-full bg-white/5"></div>

                        <div class="relative flex items-center justify-between gap-5">
                            <div class="space-y-3 min-w-0">
                                <span class="inline-flex items-center gap-1.5 text-[11px] font-extrabold uppercase tracking-wider text-orange-200 bg-white/10 px-3 py-1 rounded-full">
                                    <span class="w-1.5 h-1.5 rounded-full bg-[#FF5A00]"></span>
                                    DrRoom Rider App
                                </span>
                                <h3 class="text-lg sm:text-xl font-black leading-[1.9]">
                                    {{ __('delivery.feat_1_title') }}
                                </h3>
                                <p class="text-xs sm:text-sm text-slate-300 leading-[1.9] max-w-md">
                                    {{ __('delivery.feat_1_desc') }}
                                </p>
                            </div>

                            <div class="w-20 h-20 sm:w-24 sm:h-24 rounded-3xl bg-gradient-to-br from-[#FF5A00] to-[#FF8A3D] flex items-center justify-center flex-shrink-0 shadow-lg shadow-orange-500/30">
                                <svg class="w-12 h-12 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.7" d="M5 17a2.5 2.5 0 105 0 2.5 2.5 0 00-5 0zm10 0a2.5 2.5 0 105 0 2.5 2.5 0 00-5 0zM9 17h6m-2-6V7a1 1 0 011-1h2.586a1 1 0 01.707.293l2.414 2.414A1 1 0 0120 9.414V14a1 1 0 01-1 1h-1M3 8h7a1 1 0 011 1v6H4a1 1 0 01-1-1V8z"/>
                                </svg>
                            </div>
                        </div>
                    </div>

                    <!-- Benefits -->
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                        <div class="group bg-white rounded-3xl p-5 space-y-3 ring-1 ring-slate-900/5 shadow-sm hover:shadow-xl hover:-translate-y-0.5 transition duration-300">
                            <div class="w-11 h-11 rounded-2xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
                                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>
                            </div>
                            <h4 class="text-sm font-extrabold text-slate-900 leading-[1.9]">{{ __('delivery.feat_2_title') }}</h4>
                            <p class="text-xs text-slate-500 leading-[1.9]">{{ __('delivery.feat_2_desc') }}</p>
                        </div>

                        <div class="group bg-white rounded-3xl p-5 space-y-3 ring-1 ring-slate-900/5 shadow-sm hover:shadow-xl hover:-translate-y-0.5 transition duration-300">
                            <div class="w-11 h-11 rounded-2xl bg-blue-50 text-[#1e60eb] flex items-center justify-center">
                                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"></path></svg>
                            </div>
                            <h4 class="text-sm font-extrabold text-slate-900 leading-[1.9]">{{ __('delivery.feat_3_title') }}</h4>
                            <p class="text-xs text-slate-500 leading-[1.9]">{{ __('delivery.feat_3_desc') }}</p>
                        </div>
                    </div>
                </div>

                <!-- Form Side -->
                <div class="lg:col-span-6" id="register-form">
                    <div class="relative bg-white rounded-[2rem] p-6 sm:p-9 ring-1 ring-slate-900/5 shadow-[0_30px_70px_-20px_rgba(15,23,42,0.22)] text-start">
                        <div class="mb-7 space-y-2">
                            <h2 class="text-2xl sm:text-[1.7rem] font-black text-slate-900 leading-[1.7]">{{ __('delivery.form_title') }}</h2>
                            <p class="text-xs sm:text-sm text-slate-500 leading-[1.9]">{{ __('delivery.form_subtitle') }}</p>
                        </div>

                        @if($errors->any())
                            <div class="mb-6 p-4 rounded-2xl bg-red-50 ring-1 ring-red-200 text-red-700 text-xs font-bold space-y-1.5 leading-relaxed">
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

                            <!-- Full Name -->
                            <div>
                                <label class="label">{{ __('delivery.full_name') }} <span class="text-[#FF5A00]">*</span></label>
                                <input type="text" name="name" value="{{ old('name') }}" required
                                       placeholder="{{ __('delivery.full_name_placeholder') }}"
                                       class="field">
                            </div>

                            <!-- Phone -->
                            <div>
                                <label class="label">{{ __('delivery.phone') }} <span class="text-[#FF5A00]">*</span></label>
                                <div dir="ltr" class="field-wrap">
                                    <div class="h-full px-3.5 bg-slate-50 border-r border-slate-200 flex items-center gap-1.5 text-xs font-black text-slate-700 flex-shrink-0">
                                        <span>🇮🇶</span>
                                        <span>+964</span>
                                    </div>
                                    <input type="tel" name="phone" value="{{ old('phone') }}" required dir="ltr"
                                           placeholder="{{ __('delivery.phone_placeholder') }}"
                                           class="field text-left">
                                </div>
                                <p class="text-[11px] text-slate-400 mt-2 font-medium leading-[1.9]">{{ __('delivery.phone_hint') }}</p>
                            </div>

                            <!-- City & Plate -->
                            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                                <div>
                                    <label class="label">{{ __('delivery.city') }} <span class="text-[#FF5A00]">*</span></label>
                                    <select name="city" class="field appearance-none cursor-pointer">
                                        @foreach($cities as $c)
                                            <option value="{{ $c }}" {{ old('city') == $c ? 'selected' : '' }}>{{ $c }}</option>
                                        @endforeach
                                    </select>
                                </div>

                                <div>
                                    <label class="label">{{ __('delivery.plate_number') }}</label>
                                    <input type="text" name="plate_number" value="{{ old('plate_number') }}" dir="ltr"
                                           placeholder="{{ __('delivery.plate_placeholder') }}"
                                           class="field text-left">
                                </div>
                            </div>

                            <!-- Vehicle -->
                            <div>
                                <label class="label">{{ __('delivery.vehicle_type') }}</label>
                                <div class="grid grid-cols-3 gap-2.5">
                                    @php
                                        $vehicles = [
                                            'motorcycle' => 'M5 17a2.5 2.5 0 105 0 2.5 2.5 0 00-5 0zm10 0a2.5 2.5 0 105 0 2.5 2.5 0 00-5 0zM9 17h6m-2-6V7a1 1 0 011-1h2.586a1 1 0 01.707.293l2.414 2.414A1 1 0 0120 9.414V14a1 1 0 01-1 1h-1M3 8h7a1 1 0 011 1v6H4a1 1 0 01-1-1V8z',
                                            'car' => 'M8 17h8M8 17a2 2 0 11-4 0 2 2 0 014 0zm8 0a2 2 0 104 0 2 2 0 00-4 0zM3 6h11v9H3V6zm11 3h4l3 3v3h-7V9z',
                                            'refrigerated_van' => 'M12 3v18m9-9H3m2.6-6.4l12.8 12.8M18.4 5.6L5.6 18.4',
                                        ];
                                    @endphp
                                    @foreach($vehicles as $vKey => $path)
                                        <button type="button" @click="vehicle = '{{ $vKey }}'"
                                                :class="vehicle === '{{ $vKey }}' ? 'is-on' : ''"
                                                class="opt">
                                            <span class="opt-icon">
                                                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="{{ $path }}"></path></svg>
                                            </span>
                                            <span>{{ __('delivery.vehicle_short_' . $vKey) }}</span>
                                        </button>
                                    @endforeach
                                </div>
                            </div>

                            <!-- Service Scope -->
                            <div>
                                <label class="label">{{ __('delivery.service_scope') }}</label>
                                <div class="grid grid-cols-3 gap-2.5">
                                    @php
                                        $scopes = [
                                            'both' => 'M13 10V3L4 14h7v7l9-11h-7z',
                                            'pharmacy' => 'M12 4v16M4 12h16',
                                            'lab_sample' => 'M9 3h6M10 3v6l-5 9a2 2 0 001.7 3h10.6a2 2 0 001.7-3l-5-9V3',
                                        ];
                                    @endphp
                                    @foreach($scopes as $sKey => $path)
                                        <button type="button" @click="scope = '{{ $sKey }}'"
                                                :class="scope === '{{ $sKey }}' ? 'is-on' : ''"
                                                class="opt">
                                            <span class="opt-icon">
                                                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="{{ $path }}"></path></svg>
                                            </span>
                                            <span>{{ __('delivery.scope_short_' . $sKey) }}</span>
                                        </button>
                                    @endforeach
                                </div>
                            </div>

                            <!-- Password & Confirm -->
                            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                                <div>
                                    <label class="label">{{ __('delivery.password') }} <span class="text-[#FF5A00]">*</span></label>
                                    <div class="field-wrap">
                                        <input :type="showPass ? 'text' : 'password'" name="password" required minlength="6"
                                               placeholder="{{ __('delivery.password_placeholder') }}"
                                               class="field placeholder:text-xs">
                                        <button type="button" @click="showPass = !showPass"
                                                class="px-3.5 h-full text-slate-400 hover:text-slate-700 flex items-center justify-center flex-shrink-0 transition">
                                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path></svg>
                                        </button>
                                    </div>
                                </div>

                                <div>
                                    <label class="label">{{ __('delivery.password_confirm') }} <span class="text-[#FF5A00]">*</span></label>
                                    <div class="field-wrap">
                                        <input :type="showConfirm ? 'text' : 'password'" name="password_confirmation" required minlength="6"
                                               placeholder="{{ __('delivery.password_confirm_placeholder') }}"
                                               class="field placeholder:text-xs">
                                        <button type="button" @click="showConfirm = !showConfirm"
                                                class="px-3.5 h-full text-slate-400 hover:text-slate-700 flex items-center justify-center flex-shrink-0 transition">
                                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path></svg>
                                        </button>
                                    </div>
                                </div>
                            </div>

                            <!-- Submit -->
                            <div class="pt-2">
                                <button type="submit" :disabled="submitting"
                                        class="w-full h-14 px-6 rounded-2xl bg-gradient-to-r from-[#FF5A00] to-[#FF7A2F] hover:from-[#E04F00] hover:to-[#FF6A1F] disabled:opacity-60 text-white font-black text-sm shadow-xl shadow-orange-500/30 hover:-translate-y-0.5 active:translate-y-0 transition duration-200 flex items-center justify-center gap-2">
                                    <span x-show="!submitting">{{ __('delivery.submit_btn') }}</span>
                                    <span x-show="submitting" style="display: none;">{{ __('delivery.submitting') }}</span>
                                </button>
                            </div>

                            <p class="text-[11.5px] text-center text-slate-400 font-medium leading-[1.9] pt-1">
                                {{ __('delivery.step_note') }}
                            </p>
                        </form>
                    </div>
                </div>

            </div>
        </div>
    </section>

    <!-- Steps -->
    <section class="relative py-16 sm:py-24 bg-white border-y border-slate-100">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="text-center max-w-2xl mx-auto mb-14 space-y-3">
                <h2 class="kurdish-heading text-2xl sm:text-4xl font-black text-slate-900">{{ __('delivery.how_title') }}</h2>
                <p class="text-sm sm:text-base text-slate-500 leading-[1.9]">{{ __('delivery.how_sub') }}</p>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                @foreach([
                    ['n' => '01', 'title' => __('delivery.step1_t'), 'desc' => __('delivery.step1_d')],
                    ['n' => '02', 'title' => __('delivery.step2_t'), 'desc' => __('delivery.step2_d')],
                    ['n' => '03', 'title' => __('delivery.step3_t'), 'desc' => __('delivery.step3_d')],
                ] as $step)
                    <div class="group relative bg-[#FCFAF8] rounded-[1.75rem] p-7 ring-1 ring-slate-900/5 hover:bg-white hover:shadow-2xl hover:shadow-slate-900/10 hover:-translate-y-1 transition duration-300 text-start">
                        <div class="flex items-center justify-between mb-8">
                            <span class="w-12 h-12 rounded-2xl bg-gradient-to-br from-[#FF5A00] to-[#FF8A3D] text-white font-black text-sm flex items-center justify-center shadow-lg shadow-orange-500/30">
                                {{ $step['n'] }}
                            </span>
                        </div>
                        <h3 class="text-lg font-black text-slate-900 leading-[1.8] mb-2">{{ $step['title'] }}</h3>
                        <p class="text-sm text-slate-600 leading-[1.95]">{{ $step['desc'] }}</p>
                    </div>
                @endforeach
            </div>
        </div>
    </section>

    <footer class="py-8 text-center">
        <p class="text-xs font-bold text-slate-400">{{ __('delivery.footer_copy') }}</p>
    </footer>

</body>
</html>
