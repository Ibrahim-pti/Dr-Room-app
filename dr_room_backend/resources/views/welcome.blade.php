@php
    $approvedLabs = $labs ?? \App\Models\User::where('role', 'lab')
        ->where('status', 'approved')
        ->with('lab')
        ->orderBy('created_at', 'desc')
        ->get();

    $resolveLabIcon = function($user) {
        $lab = $user->lab;
        $path = ($lab && !empty($lab->image_path)) ? $lab->image_path : $user->profile_image;
        if (!empty($path)) {
            if (str_starts_with($path, 'http://') || str_starts_with($path, 'https://')) {
                return $path;
            }
            if (file_exists(public_path($path))) {
                return asset($path);
            }
            if (file_exists(public_path('storage/' . $path))) {
                return asset('storage/' . $path);
            }
            if (file_exists(public_path('assets/' . $path))) {
                return asset('assets/' . $path);
            }
            if (file_exists(public_path('images/' . $path))) {
                return asset('images/' . $path);
            }
        }
        return asset('images/logo.png');
    };

    $resolveLabName = function($user) {
        $loc = app()->getLocale();
        if ($loc === 'en' && !empty($user->name_en)) return $user->name_en;
        if ($loc === 'ar' && !empty($user->name_ar)) return $user->name_ar;
        return $user->name;
    };

    // Flat line icons (no emoji). Usage: {!! $ico('path-d') !!}
    $ico = fn (string $d, string $cls = 'w-5 h-5') => '<svg class="'.$cls.'" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="'.$d.'"></path></svg>';

    $icoFlask   = 'M9 3h6M10 3v6l-5 9a2 2 0 001.7 3h10.6a2 2 0 001.7-3l-5-9V3';
    $icoHeart   = 'M4.318 6.318a4.5 4.5 0 016.364 0L12 7.636l1.318-1.318a4.5 4.5 0 116.364 6.364L12 20.364l-7.682-7.682a4.5 4.5 0 010-6.364z';
    $icoSteth   = 'M6 3v6a4 4 0 008 0V3M10 13v2a4 4 0 008 0v-1M18 11a2 2 0 100 4 2 2 0 000-4z';
    $icoPill    = 'M10.5 3.5l-7 7a4.95 4.95 0 007 7l7-7a4.95 4.95 0 00-7-7zM8.5 8.5l7 7';
    $icoScan    = 'M4 8V6a2 2 0 012-2h2M16 4h2a2 2 0 012 2v2M20 16v2a2 2 0 01-2 2h-2M8 20H6a2 2 0 01-2-2v-2M7 12h10';
    $icoNews    = 'M5 5h11v14H7a2 2 0 01-2-2V5zM16 9h3v8a2 2 0 01-2 2M8 9h5M8 12h5M8 15h3';
    $icoShield  = 'M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6l8-3zM9 12l2 2 4-4';
    $icoBolt    = 'M13 10V3L4 14h7v7l9-11h-7z';
    $icoPhone   = 'M12 18h.01M8 3h8a1 1 0 011 1v16a1 1 0 01-1 1H8a1 1 0 01-1-1V4a1 1 0 011-1z';
    $icoLock    = 'M7 11V8a5 5 0 0110 0v3M6 11h12v9H6z';
    $icoCamera  = 'M4 8a2 2 0 012-2h2l1.5-2h5L16 6h2a2 2 0 012 2v9a2 2 0 01-2 2H6a2 2 0 01-2-2V8zM12 17a3 3 0 100-6 3 3 0 000 6z';
    $icoBulb    = 'M9 18h6M10 21h4M12 3a6 6 0 00-3.5 10.9c.6.5 1 1.2 1 2.1V17h5v-1.9c0-.9.4-1.6 1-2.1A6 6 0 0012 3z';
    $icoStar    = 'M12 4l2.4 4.9 5.4.8-3.9 3.8.9 5.4L12 16.3 7.2 18.9l.9-5.4-3.9-3.8 5.4-.8L12 4z';
    $icoCheck   = 'M5 12.5l4.2 4.2L19 7';
    $icoTag     = 'M3 12V4a1 1 0 011-1h8l9 9-9 9-9-9zM8 8h.01';
    $icoPlus    = 'M12 5v14M5 12h14';
    $icoClock   = 'M12 7v5l3 2M21 12a9 9 0 11-18 0 9 9 0 0118 0z';
    $icoUser    = 'M16 7a4 4 0 11-8 0 4 4 0 018 0zM4 21a8 8 0 0116 0';
    $icoMail    = 'M3 8l9 6 9-6M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z';
    $icoPin     = 'M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0zM15 11a3 3 0 11-6 0 3 3 0 016 0z';
    $icoArrow   = 'M14 5l7 7m0 0l-7 7m7-7H3';
    $icoDown    = 'M19 9l-7 7-7-7';
@endphp
<!DOCTYPE html>
<html lang="{{ app()->getLocale() }}" dir="{{ in_array(app()->getLocale(), ['ar', 'ckb']) ? 'rtl' : 'ltr' }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ __('landing.app_name') }} - {{ __('landing.subtitle') }}</title>

    <link rel="icon" type="image/png" href="{{ asset('favicon.png') }}">
    <link rel="shortcut icon" href="{{ asset('favicon.ico') }}">
    <link rel="apple-touch-icon" href="{{ asset('images/logo.png') }}">

    <!-- SEO & Social Share Preview Meta Tags -->
    <meta name="description" content="{{ __('landing.hero_desc') }}">
    <meta name="keywords" content="دکتۆر رووم, DrRoom, پشکنینی تاقیگە لە ماڵەوە, پەرستاری لە ماڵەوە, پزیشک لە ماڵەوە, هەولێر, سلێمانی, دهۆک">
    <meta property="og:type" content="website">
    <meta property="og:url" content="{{ url()->current() }}">
    <meta property="og:title" content="{{ __('landing.app_name') }} - {{ __('landing.subtitle') }}">
    <meta property="og:description" content="{{ __('landing.hero_desc') }}">
    <meta property="og:image" content="{{ asset('images/logo.png') }}">
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:title" content="{{ __('landing.app_name') }} - {{ __('landing.subtitle') }}">
    <meta name="twitter:description" content="{{ __('landing.hero_desc') }}">
    <meta name="twitter:image" content="{{ asset('images/logo.png') }}">

    <!-- Alpine.js -->
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.13.3/dist/cdn.min.js"></script>

    <!-- Fonts: Katibeh for display headings, Noto Kufi Arabic for Kurdish/Arabic text, Plus Jakarta Sans for Latin -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Katibeh&family=Noto+Kufi+Arabic:wght@400;500;600;700;800;900&family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">

    <!-- Tailwind CSS CDN -->
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    fontFamily: {
                        sans: ['Noto Kufi Arabic', 'Plus Jakarta Sans', 'sans-serif'],
                    },
                }
            }
        }
    </script>

    <style>
        :root {
            --paper: #F4EFE6;
            --surface: #FFFCF7;
            --ink: #1C1A17;
            --muted: #6E665B;
            --line: #D9D0C2;
            --blue: #1E60EB;
            --blue-ink: #1647B8;
            --blue-soft: #E4ECFD;
            --green: #1F9D63;
            --green-soft: #E3F4EC;
        }

        /* Flat, hand-cut feel: solid ink borders, no shadows, no blur, no gradients */
        *, *::before, *::after { box-shadow: none !important; text-shadow: none !important; }

        html {
            overflow-x: clip;
            scrollbar-width: none;
            scroll-behavior: smooth;
        }
        html::-webkit-scrollbar, body::-webkit-scrollbar { display: none; }

        body {
            background: var(--paper);
            color: var(--ink);
            font-family: 'Noto Kufi Arabic', 'Plus Jakarta Sans', sans-serif;
            overflow-x: clip;
            -webkit-font-smoothing: antialiased;
        }
        ::selection { background: var(--blue-soft); color: var(--ink); }
        [x-cloak] { display: none !important; }

        .card {
            background: var(--surface);
            border: 1.5px solid var(--ink);
            border-radius: 18px;
        }
        .kicker {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            font-size: 12px;
            font-weight: 800;
            padding: 5px 12px;
            border: 1.5px solid var(--ink);
            border-radius: 999px;
            background: var(--surface);
            line-height: 1.4;
        }
        .kicker.is-blue { background: var(--blue); color: #fff; }

        /* Display headings in Katibeh */
        .heading {
            font-family: 'Katibeh', 'Noto Kufi Arabic', sans-serif;
            font-weight: 400;
            line-height: 1.65 !important;
            letter-spacing: 0;
        }
        h1.heading { font-size: clamp(3rem, 6vw, 5.6rem) !important; }
        h2.heading { font-size: clamp(2.4rem, 4vw, 3.6rem) !important; }
        h3.heading { font-size: clamp(1.9rem, 2.6vw, 2.5rem) !important; }

        .underline-wrap { position: relative; display: inline-block; }
        .underline-wrap svg {
            position: absolute;
            inset-inline: -4px;
            bottom: -10px;
            width: calc(100% + 8px);
            height: 14px;
            overflow: visible;
        }

        .btn-primary {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
            height: 52px;
            padding: 0 22px;
            background: var(--blue);
            color: #fff;
            border: 1.5px solid var(--ink);
            border-radius: 16px;
            font-size: 15px;
            font-weight: 900;
            white-space: nowrap;
            transition: background-color .15s ease;
            cursor: pointer;
        }
        .btn-primary:hover { background: var(--blue-ink); }
        .btn-primary:active { transform: translateY(1px); }

        .btn-ink {
            display: inline-flex;
            align-items: center;
            gap: 12px;
            min-height: 60px;
            padding: 10px 20px;
            background: var(--ink);
            color: var(--surface);
            border: 1.5px solid var(--ink);
            border-radius: 16px;
            transition: background-color .15s ease;
            cursor: pointer;
        }
        .btn-ink:hover { background: #3a3631; }

        .btn-ghost {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            height: 40px;
            padding: 0 14px;
            border: 1.5px solid var(--ink);
            border-radius: 12px;
            background: transparent;
            color: var(--ink);
            font-size: 13px;
            font-weight: 800;
            white-space: nowrap;
            transition: background-color .15s ease, color .15s ease;
        }
        .btn-ghost:hover { background: var(--ink); color: var(--surface); }

        .icon-tile {
            width: 44px;
            height: 44px;
            display: flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
            border: 1.5px solid var(--ink);
            border-radius: 12px;
            background: var(--surface);
            color: var(--ink);
        }
        .icon-tile.is-blue { background: var(--blue); color: #fff; }

        .chip {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            font-size: 12px;
            font-weight: 800;
            padding: 6px 12px;
            border: 1.5px solid var(--ink);
            border-radius: 10px;
            background: var(--blue-soft);
            color: var(--blue-ink);
            line-height: 1.4;
        }

        .outline-num {
            display: block;
            font-weight: 900;
            font-size: 60px;
            line-height: 1;
            color: transparent;
            -webkit-text-stroke: 1.5px var(--ink);
        }

        .rule-dash { border-top: 1.5px dashed var(--line); }

        /* Phone frame: solid ink bezel with a notch, no glow */
        .phone {
            position: relative;
            overflow: hidden;
            background: var(--ink);
            border: 9px solid var(--ink);
            border-radius: 44px;
        }
        .phone img {
            display: block;
            width: 100%;
            height: 100%;
            object-fit: cover;
            border-radius: 34px;
        }
        .phone .notch {
            position: absolute;
            top: 10px;
            left: 50%;
            transform: translateX(-50%);
            width: 92px;
            height: 22px;
            background: var(--ink);
            border-radius: 999px;
            z-index: 5;
        }

        /* Floating tags beside the phone (flat, slightly tilted on larger screens) */
        .float-tag {
            position: absolute;
            z-index: 30;
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 12px 14px;
            background: var(--surface);
            border: 1.5px solid var(--ink);
            border-radius: 16px;
            max-width: 240px;
        }
        @media (min-width: 640px) {
            .tilt-l { transform: rotate(-2deg); }
            .tilt-r { transform: rotate(1.5deg); }
        }

        /* Lab ticker */
        @keyframes marquee-scroll {
            0% { transform: translateX(0); }
            100% { transform: translateX(-50%); }
        }
        .marquee-track {
            display: flex;
            width: max-content;
            gap: 1rem;
            animation: marquee-scroll 32s linear infinite;
        }
        .marquee-track:hover { animation-play-state: paused; }

        /* Fields for accordion and tabs */
        .tab-btn {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 12px 18px;
            border: 1.5px solid var(--ink);
            border-radius: 14px;
            background: var(--surface);
            color: var(--ink);
            font-size: 14px;
            font-weight: 800;
            transition: background-color .15s ease, color .15s ease;
            cursor: pointer;
        }
        .tab-btn:hover { background: #F7F1E8; }
        .tab-btn.is-on { background: var(--ink); color: var(--surface); }

        .row-item {
            display: flex;
            align-items: center;
            gap: 14px;
            padding: 14px;
            border: 1.5px solid var(--ink);
            border-radius: 14px;
            background: var(--surface);
        }

        .pillar {
            background: var(--surface);
            border: 1.5px solid var(--ink);
            border-radius: 18px;
            padding: 22px;
        }

        .service-card {
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            gap: 20px;
            padding: 26px;
            background: var(--surface);
            border: 1.5px solid var(--ink);
            border-radius: 18px;
        }

        .faq-item {
            border: 1.5px solid var(--ink);
            border-radius: 16px;
            background: var(--surface);
            overflow: hidden;
        }

        .footer-link { transition: color .15s ease; }
        .footer-link:hover { color: var(--blue); }

        @media (prefers-reduced-motion: reduce) {
            .marquee-track { animation: none; }
            html { scroll-behavior: auto; }
        }
    </style>
</head>
<body x-data="{ showDownloadModal: false }" class="antialiased min-h-screen flex flex-col">

    <!-- Header -->
    <header x-data="{ mobileMenuOpen: false }" class="sticky top-0 z-50 bg-[var(--paper)] border-b-[1.5px] border-[var(--ink)]">
        <div class="w-full px-5 sm:px-8 lg:px-16 2xl:px-24 h-[72px] flex items-center justify-between gap-4">
            <!-- Brand -->
            <a href="/" class="flex items-center gap-3 min-w-0">
                <img src="{{ asset('images/logo.png') }}" alt="DrRoom" class="w-10 h-10 object-contain flex-shrink-0 border-[1.5px] border-[var(--ink)] rounded-xl bg-[var(--surface)] p-1">
                <div class="flex flex-col min-w-0">
                    <span class="text-lg font-black leading-none" dir="ltr">Dr<span class="text-[var(--blue)]">Room</span></span>
                    <span class="hidden sm:block text-[11px] font-semibold text-[var(--muted)] mt-1 leading-normal">{{ __('landing.subtitle') }}</span>
                </div>
            </a>

            <!-- Desktop menu -->
            <nav class="hidden xl:flex items-center gap-7">
                <a href="#" class="text-sm font-extrabold hover:text-[var(--blue)] transition">{{ __('landing.home') }}</a>
                <a href="#services" class="text-sm font-extrabold hover:text-[var(--blue)] transition">{{ __('landing.services') }}</a>
                <a href="#app-screens" class="text-sm font-extrabold hover:text-[var(--blue)] transition">{{ __('landing.features') }}</a>
                <a href="#why-us" class="text-sm font-extrabold hover:text-[var(--blue)] transition">{{ __('landing.about_tag') }}</a>
                <a href="#faq" class="text-sm font-extrabold hover:text-[var(--blue)] transition">{{ __('landing.faq') }}</a>
            </nav>

            <!-- Desktop actions -->
            <div class="hidden sm:flex items-center gap-2 flex-shrink-0">
                <a href="/staff" class="btn-ghost">
                    <span>{{ __('landing.staff_short') }}</span>
                </a>
                <a href="/delivery/{{ app()->getLocale() }}" class="btn-ghost">
                    <span>{{ __('landing.delivery_short') }}</span>
                </a>

                <div class="relative" x-data="{ langOpen: false }">
                    <button @click="langOpen = !langOpen" @click.away="langOpen = false" class="btn-ghost">
                        <span>{{ strtoupper(app()->getLocale() == 'ckb' ? 'KU' : app()->getLocale()) }}</span>
                        <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.2" d="M19 9l-7 7-7-7"></path></svg>
                    </button>
                    <div x-show="langOpen" x-transition style="display: none;" class="absolute end-0 mt-2 w-44 card py-1.5 z-50">
                        <a href="/ckb" class="flex items-center justify-between px-4 py-2.5 text-xs font-extrabold {{ app()->getLocale() == 'ckb' ? 'bg-[var(--blue-soft)]' : 'hover:bg-[#F7F1E8]' }}">
                            <span>کوردی (Kurdish)</span>
                            @if(app()->getLocale() == 'ckb') <span class="w-2 h-2 rounded-full bg-[var(--blue)]"></span> @endif
                        </a>
                        <a href="/en" class="flex items-center justify-between px-4 py-2.5 text-xs font-extrabold {{ app()->getLocale() == 'en' ? 'bg-[var(--blue-soft)]' : 'hover:bg-[#F7F1E8]' }}">
                            <span>English</span>
                            @if(app()->getLocale() == 'en') <span class="w-2 h-2 rounded-full bg-[var(--blue)]"></span> @endif
                        </a>
                        <a href="/ar" class="flex items-center justify-between px-4 py-2.5 text-xs font-extrabold {{ app()->getLocale() == 'ar' ? 'bg-[var(--blue-soft)]' : 'hover:bg-[#F7F1E8]' }}">
                            <span>العربية (Arabic)</span>
                            @if(app()->getLocale() == 'ar') <span class="w-2 h-2 rounded-full bg-[var(--blue)]"></span> @endif
                        </a>
                    </div>
                </div>

                <a href="#download" @click.prevent="showDownloadModal = true" class="btn-primary !h-10 !text-sm !px-4 !rounded-xl">
                    {!! $ico($icoDown, 'w-4 h-4') !!}
                    <span>{{ __('landing.download_app') }}</span>
                </a>
            </div>

            <!-- Mobile actions -->
            <div class="flex sm:hidden items-center gap-2">
                <a href="/staff" class="btn-ghost !h-9 !px-3 !text-xs">{{ __('landing.staff_short') }}</a>
                <button @click="mobileMenuOpen = !mobileMenuOpen" class="w-10 h-10 flex items-center justify-center border-[1.5px] border-[var(--ink)] rounded-xl bg-[var(--surface)]" aria-label="Menu">
                    <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path x-show="!mobileMenuOpen" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 7h16M4 12h16M4 17h16" />
                        <path x-show="mobileMenuOpen" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                </button>
            </div>
        </div>

        <!-- Mobile drawer -->
        <div x-show="mobileMenuOpen" x-transition style="display: none;" class="sm:hidden border-t-[1.5px] border-[var(--ink)] bg-[var(--surface)]">
            <div class="px-5 py-5 space-y-2">
                <a href="#" @click="mobileMenuOpen = false" class="block px-4 py-3 rounded-xl border-[1.5px] border-[var(--ink)] font-extrabold text-sm">{{ __('landing.home') }}</a>
                <a href="#services" @click="mobileMenuOpen = false" class="block px-4 py-3 rounded-xl border-[1.5px] border-[var(--ink)] font-extrabold text-sm">{{ __('landing.services') }}</a>
                <a href="#app-screens" @click="mobileMenuOpen = false" class="block px-4 py-3 rounded-xl border-[1.5px] border-[var(--ink)] font-extrabold text-sm">{{ __('landing.features') }}</a>
                <a href="#why-us" @click="mobileMenuOpen = false" class="block px-4 py-3 rounded-xl border-[1.5px] border-[var(--ink)] font-extrabold text-sm">{{ __('landing.about_tag') }}</a>
                <a href="#faq" @click="mobileMenuOpen = false" class="block px-4 py-3 rounded-xl border-[1.5px] border-[var(--ink)] font-extrabold text-sm">{{ __('landing.faq') }}</a>
                <a href="/delivery/{{ app()->getLocale() }}" class="flex items-center justify-between px-4 py-3 rounded-xl border-[1.5px] border-[var(--ink)] bg-[var(--green-soft)] font-extrabold text-sm">
                    <span>{{ __('landing.delivery_short') }}</span>
                    <span class="text-xs">{{ __('delivery.nav_join') }}</span>
                </a>
                <div class="pt-3 mt-3 border-t-[1.5px] border-dashed border-[var(--line)]">
                    <p class="text-[11px] font-extrabold text-[var(--muted)] mb-2">{{ __('landing.language') }}</p>
                    <div class="grid grid-cols-3 gap-2">
                        <a href="/ckb" class="text-center py-2.5 rounded-xl border-[1.5px] border-[var(--ink)] text-xs font-extrabold {{ app()->getLocale() == 'ckb' ? 'bg-[var(--ink)] text-[var(--surface)]' : '' }}">کوردی</a>
                        <a href="/en" class="text-center py-2.5 rounded-xl border-[1.5px] border-[var(--ink)] text-xs font-extrabold {{ app()->getLocale() == 'en' ? 'bg-[var(--ink)] text-[var(--surface)]' : '' }}">English</a>
                        <a href="/ar" class="text-center py-2.5 rounded-xl border-[1.5px] border-[var(--ink)] text-xs font-extrabold {{ app()->getLocale() == 'ar' ? 'bg-[var(--ink)] text-[var(--surface)]' : '' }}">العربية</a>
                    </div>
                </div>
            </div>
        </div>
    </header>

    @if($approvedLabs->count() >= 5)
    <!-- Registered labs ticker -->
    <section class="border-b-[1.5px] border-[var(--ink)] bg-[var(--surface)] py-4 overflow-hidden">
        <div class="w-full px-5 sm:px-8 lg:px-16 2xl:px-24 mb-3 flex items-center gap-3">
            <span class="w-2.5 h-2.5 rounded-full bg-[var(--green)] border border-[var(--ink)]"></span>
            <h3 class="text-sm font-black leading-normal">{{ __('landing.registered_labs') }}</h3>
            <span class="chip !bg-[var(--green-soft)] !text-[#17704A]">{{ $approvedLabs->count() }} {{ __('landing.labs_count') }}</span>
        </div>

        <div class="w-full overflow-hidden select-none" dir="ltr">
            <div class="marquee-track">
                @for($loopIndex = 0; $loopIndex < 4; $loopIndex++)
                    <div class="flex items-center gap-3 flex-shrink-0">
                        @foreach($approvedLabs as $labUser)
                            <div dir="{{ in_array(app()->getLocale(), ['ar', 'ckb']) ? 'rtl' : 'ltr' }}" class="inline-flex items-center gap-3 px-3.5 py-2 bg-[var(--paper)] rounded-2xl border-[1.5px] border-[var(--ink)] whitespace-nowrap flex-shrink-0">
                                <img src="{{ $resolveLabIcon($labUser) }}"
                                     alt="{{ $resolveLabName($labUser) }}"
                                     class="w-8 h-8 rounded-xl object-cover border-[1.5px] border-[var(--ink)] bg-[var(--surface)] flex-shrink-0"
                                     onerror="this.onerror=null; this.src='{{ asset('images/logo.png') }}';">
                                <span class="text-xs font-black">{{ $resolveLabName($labUser) }}</span>
                                <span class="text-[10px] font-extrabold px-1.5 py-0.5 rounded-md border-[1.5px] border-[var(--ink)] bg-[var(--blue-soft)] text-[var(--blue-ink)]">{{ __('landing.verified_badge') }}</span>
                            </div>
                        @endforeach
                    </div>
                @endfor
            </div>
        </div>
    </section>
    @endif

    <!-- Hero -->
    <section class="relative flex-1 overflow-hidden">
        <div class="w-full px-5 sm:px-8 lg:px-16 2xl:px-24 {{ $approvedLabs->count() >= 5 ? 'pt-12 sm:pt-16' : 'pt-14 sm:pt-20' }} pb-16 sm:pb-24">
            <div class="grid grid-cols-1 lg:grid-cols-12 gap-14 lg:gap-16 items-center">

                <!-- Copy -->
                <div class="lg:col-span-6 space-y-8 text-start">
                    <span class="kicker">{{ __('landing.app_showcase_tag') }}</span>

                    <h1 class="heading">
                        <span class="block">{{ __('landing.hero_title_1') }}</span>
                        <span class="underline-wrap mt-3 text-[var(--blue)]">
                            {{ __('landing.hero_title_2') }}
                            <svg viewBox="0 0 200 14" preserveAspectRatio="none" aria-hidden="true">
                                <path d="M3 9 C 40 3, 70 12, 105 6 S 170 4, 197 8" stroke="#1C1A17" stroke-width="3" fill="none" stroke-linecap="round"/>
                            </svg>
                        </span>
                        <span class="block mt-4">{{ __('landing.hero_title_3') }}</span>
                    </h1>

                    <p class="text-base sm:text-lg text-[var(--muted)] font-medium leading-[2] max-w-xl">
                        {{ __('landing.hero_desc') }}
                    </p>

                    <div class="flex flex-col sm:flex-row gap-3 max-w-xl">
                        <a href="#download" @click.prevent="showDownloadModal = true" class="btn-ink flex-1 group">
                            {!! $ico('M3.609 1.814L13.792 12 3.61 22.186a2.023 2.023 0 01-.61-1.45V3.264c0-.56.22-1.07.609-1.45z', 'w-6 h-6 text-[var(--green)] flex-shrink-0') !!}
                            <span class="text-start flex flex-col gap-0.5">
                                <span class="text-[10px] opacity-70 font-normal leading-normal">{{ __('landing.download_android') }}</span>
                                <span class="text-sm font-extrabold leading-normal">{{ __('landing.android') }}</span>
                            </span>
                        </a>
                        <a href="#download" @click.prevent="showDownloadModal = true" class="btn-primary flex-1 !h-[60px] !rounded-2xl !justify-start !px-5 group">
                            <svg class="w-6 h-6 flex-shrink-0" fill="currentColor" viewBox="0 0 24 24"><path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 6.37c.62-.75 1.04-1.8 1.01-2.85-.9.04-2.03.62-2.68 1.38-.58.67-.99 1.74-.96 2.81 1.01.08 2.01-.59 2.63-1.34z"/></svg>
                            <span class="text-start flex flex-col gap-0.5">
                                <span class="text-[10px] opacity-80 font-normal leading-normal">{{ __('landing.download_ios') }}</span>
                                <span class="text-sm font-extrabold leading-normal">{{ __('landing.ios') }}</span>
                            </span>
                        </a>
                    </div>
                </div>

                <!-- Phone visual -->
                <div class="lg:col-span-6 flex justify-center select-none">
                    <div class="relative w-[280px] sm:w-[320px] h-[580px] sm:h-[660px]">
                        <div class="float-tag tilt-l -top-4 -start-4 sm:-start-12">
                            <div class="icon-tile is-blue">{!! $ico($icoSteth, 'w-5 h-5') !!}</div>
                            <div class="flex flex-col gap-1">
                                <div class="text-xs font-black leading-normal">{{ __('landing.free_consultation') }}</div>
                                <div class="text-[11px] font-bold text-[var(--blue-ink)] leading-normal">{{ __('landing.free_consultation_sub') }}</div>
                            </div>
                        </div>

                        <div class="float-tag tilt-r bottom-20 -end-4 sm:-end-12">
                            <div class="icon-tile">{!! $ico($icoScan, 'w-5 h-5') !!}</div>
                            <div class="flex flex-col gap-1">
                                <div class="text-xs font-black leading-normal">{{ __('landing.ai_scanner_pill') }}</div>
                                <div class="text-[11px] font-bold text-[var(--muted)] leading-normal">{{ __('landing.ai_scanner_pill_acc') }}</div>
                            </div>
                        </div>

                        <div class="phone w-full h-full z-20">
                            <div class="notch"></div>
                            <img src="{{ asset('images/app_home.png') }}" alt="DrRoom App Live Interface">
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Services -->
    <section id="services" class="rule-dash py-20 sm:py-28">
        <div class="w-full px-5 sm:px-8 lg:px-16 2xl:px-24">
            <div class="grid grid-cols-1 lg:grid-cols-12 gap-6 items-end mb-14">
                <div class="lg:col-span-7 space-y-4 text-start">
                    <span class="kicker">{{ __('landing.our_services') }}</span>
                    <h2 class="heading">{{ __('landing.our_services') }}</h2>
                </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5 lg:gap-6">
                <div class="service-card">
                    <div class="space-y-5">
                        <div class="icon-tile">{!! $ico($icoFlask) !!}</div>
                        <div class="space-y-3">
                            <h3 class="text-lg font-black leading-[1.8]">{{ __('landing.lab_tests') }}</h3>
                            <p class="text-sm text-[var(--muted)] leading-[1.9]">{{ __('landing.lab_desc') }}</p>
                        </div>
                    </div>
                    <div><span class="chip">{{ __('landing.available_home') }}</span></div>
                </div>

                <div class="service-card">
                    <div class="space-y-5">
                        <div class="icon-tile">{!! $ico($icoHeart) !!}</div>
                        <div class="space-y-3">
                            <h3 class="text-lg font-black leading-[1.8]">{{ __('landing.nursing') }}</h3>
                            <p class="text-sm text-[var(--muted)] leading-[1.9]">{{ __('landing.nursing_desc') }}</p>
                        </div>
                    </div>
                    <div><span class="chip">{{ __('landing.fast_booking') }}</span></div>
                </div>

                <div class="service-card">
                    <div class="space-y-5">
                        <div class="icon-tile">{!! $ico($icoSteth) !!}</div>
                        <div class="space-y-3">
                            <h3 class="text-lg font-black leading-[1.8]">{{ __('landing.doctor') }}</h3>
                            <p class="text-sm text-[var(--muted)] leading-[1.9]">{{ __('landing.doctor_desc') }}</p>
                        </div>
                    </div>
                    <div><span class="chip">{{ __('landing.fast_booking') }}</span></div>
                </div>

                <div class="service-card">
                    <div class="space-y-5">
                        <div class="icon-tile">{!! $ico($icoPill) !!}</div>
                        <div class="space-y-3">
                            <h3 class="text-lg font-black leading-[1.8]">{{ __('landing.pharmacy') }}</h3>
                            <p class="text-sm text-[var(--muted)] leading-[1.9]">{{ __('landing.pharmacy_desc') }}</p>
                        </div>
                    </div>
                    <div><span class="chip">{{ __('landing.instant_delivery') }}</span></div>
                </div>

                <div class="service-card">
                    <div class="space-y-5">
                        <div class="icon-tile">{!! $ico($icoScan) !!}</div>
                        <div class="space-y-3">
                            <h3 class="text-lg font-black leading-[1.8]">{{ __('landing.xray') }}</h3>
                            <p class="text-sm text-[var(--muted)] leading-[1.9]">{{ __('landing.xray_desc') }}</p>
                        </div>
                    </div>
                    <div><span class="chip">{{ __('landing.available_home') }}</span></div>
                </div>

                <div class="service-card">
                    <div class="space-y-5">
                        <div class="icon-tile">{!! $ico($icoNews) !!}</div>
                        <div class="space-y-3">
                            <h3 class="text-lg font-black leading-[1.8]">{{ __('landing.health_news') }}</h3>
                            <p class="text-sm text-[var(--muted)] leading-[1.9]">{{ __('landing.health_news_desc') }}</p>
                        </div>
                    </div>
                    <div><span class="chip">{{ __('landing.latest_articles') }}</span></div>
                </div>
            </div>
        </div>
    </section>

    <!-- In-app screens -->
    <section id="app-screens" class="rule-dash py-20 sm:py-28" x-data="{ activeTab: 'labs' }">
        <div class="w-full px-5 sm:px-8 lg:px-16 2xl:px-24">
            <div class="grid grid-cols-1 lg:grid-cols-12 gap-6 mb-12">
                <div class="lg:col-span-7 space-y-4 text-start">
                    <span class="kicker">{{ __('landing.app_showcase_tag') }}</span>
                    <h2 class="heading">
                        <span>{{ __('landing.app_showcase_title') }}</span>
                        <span class="text-[var(--blue)]">{{ __('landing.app_showcase_title_2') }}</span>
                    </h2>
                </div>
                <div class="lg:col-span-5 flex items-end">
                    <p class="text-sm sm:text-base text-[var(--muted)] font-medium leading-[2] text-start">{{ __('landing.app_showcase_desc') }}</p>
                </div>
            </div>

            <div class="flex flex-wrap gap-3 mb-10">
                <button @click="activeTab = 'labs'" :class="activeTab === 'labs' ? 'is-on' : ''" class="tab-btn">
                    {!! $ico($icoFlask, 'w-4 h-4') !!}<span>{{ __('landing.screen_labs_tab') }}</span>
                </button>
                <button @click="activeTab = 'nursing'" :class="activeTab === 'nursing' ? 'is-on' : ''" class="tab-btn">
                    {!! $ico($icoHeart, 'w-4 h-4') !!}<span>{{ __('landing.screen_nursing_tab') }}</span>
                </button>
                <button @click="activeTab = 'firstaid'" :class="activeTab === 'firstaid' ? 'is-on' : ''" class="tab-btn">
                    {!! $ico($icoNews, 'w-4 h-4') !!}<span>{{ __('landing.screen_firstaid_tab') }}</span>
                </button>
                <button @click="activeTab = 'aiscan'" :class="activeTab === 'aiscan' ? 'is-on' : ''" class="tab-btn">
                    {!! $ico($icoScan, 'w-4 h-4') !!}<span>{{ __('landing.screen_aiscan_tab') }}</span>
                </button>
            </div>

            <div class="card p-6 sm:p-10 lg:p-14">
                <!-- Labs -->
                <div x-show="activeTab === 'labs'" x-transition class="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
                    <div class="lg:col-span-5 flex justify-center">
                        <div class="phone w-[260px] sm:w-[290px] h-[540px] sm:h-[600px]">
                            <div class="notch"></div>
                            <img src="{{ asset('images/app_labs.png') }}" alt="DrRoom Medical Labs" onerror="this.onerror=null; this.src='{{ asset('images/app_home.png') }}';">
                        </div>
                    </div>
                    <div class="lg:col-span-7 space-y-6 text-start">
                        <span class="chip">{!! $ico($icoFlask, 'w-4 h-4') !!} {{ __('landing.screen_labs_tab') }}</span>
                        <h3 class="heading">{{ __('landing.screen_labs_title') }}</h3>
                        <p class="text-sm sm:text-base text-[var(--muted)] leading-[2] font-medium">{{ __('landing.screen_labs_desc') }}</p>
                        <div class="space-y-3">
                            <div class="row-item"><span class="icon-tile !w-9 !h-9">{!! $ico($icoStar, 'w-4 h-4') !!}</span><span class="text-sm font-bold">{{ __('landing.screen_labs_f1') }}</span></div>
                            <div class="row-item"><span class="icon-tile !w-9 !h-9">{!! $ico($icoTag, 'w-4 h-4') !!}</span><span class="text-sm font-bold">{{ __('landing.screen_labs_f2') }}</span></div>
                            <div class="row-item"><span class="icon-tile !w-9 !h-9">{!! $ico($icoCheck, 'w-4 h-4') !!}</span><span class="text-sm font-bold">{{ __('landing.screen_labs_f3') }}</span></div>
                        </div>
                    </div>
                </div>

                <!-- Nursing -->
                <div x-show="activeTab === 'nursing'" x-transition style="display: none;" class="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
                    <div class="lg:col-span-5 flex justify-center">
                        <div class="phone w-[260px] sm:w-[290px] h-[540px] sm:h-[600px]">
                            <div class="notch"></div>
                            <img src="{{ asset('images/app_home.png') }}" alt="DrRoom Nursing">
                        </div>
                    </div>
                    <div class="lg:col-span-7 space-y-6 text-start">
                        <span class="chip">{!! $ico($icoHeart, 'w-4 h-4') !!} {{ __('landing.screen_nursing_tab') }}</span>
                        <h3 class="heading">{{ __('landing.screen_nursing_title') }}</h3>
                        <p class="text-sm sm:text-base text-[var(--muted)] leading-[2] font-medium">{{ __('landing.screen_nursing_desc') }}</p>
                        <div class="space-y-3">
                            <div class="row-item"><span class="icon-tile !w-9 !h-9">{!! $ico($icoCheck, 'w-4 h-4') !!}</span><span class="text-sm font-bold">{{ __('landing.screen_nursing_f1') }}</span></div>
                            <div class="row-item"><span class="icon-tile !w-9 !h-9">{!! $ico($icoPlus, 'w-4 h-4') !!}</span><span class="text-sm font-bold">{{ __('landing.screen_nursing_f2') }}</span></div>
                            <div class="row-item"><span class="icon-tile !w-9 !h-9">{!! $ico($icoBolt, 'w-4 h-4') !!}</span><span class="text-sm font-bold">{{ __('landing.screen_nursing_f3') }}</span></div>
                        </div>
                    </div>
                </div>

                <!-- First aid -->
                <div x-show="activeTab === 'firstaid'" x-transition style="display: none;" class="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
                    <div class="lg:col-span-5 flex justify-center">
                        <div class="phone w-[260px] sm:w-[290px] h-[540px] sm:h-[600px]">
                            <div class="notch"></div>
                            <img src="{{ asset('images/app_first_aid.png') }}" alt="DrRoom First Aid">
                        </div>
                    </div>
                    <div class="lg:col-span-7 space-y-6 text-start">
                        <span class="chip">{!! $ico($icoNews, 'w-4 h-4') !!} {{ __('landing.screen_firstaid_tab') }}</span>
                        <h3 class="heading">{{ __('landing.screen_firstaid_title') }}</h3>
                        <p class="text-sm sm:text-base text-[var(--muted)] leading-[2] font-medium">{{ __('landing.screen_firstaid_desc') }}</p>
                        <div class="space-y-3">
                            <div class="row-item"><span class="icon-tile !w-9 !h-9">{!! $ico($icoCheck, 'w-4 h-4') !!}</span><span class="text-sm font-bold">{{ __('landing.screen_firstaid_f1') }}</span></div>
                            <div class="row-item"><span class="icon-tile !w-9 !h-9">{!! $ico($icoStar, 'w-4 h-4') !!}</span><span class="text-sm font-bold">{{ __('landing.screen_firstaid_f2') }}</span></div>
                            <div class="row-item"><span class="icon-tile !w-9 !h-9">{!! $ico($icoBulb, 'w-4 h-4') !!}</span><span class="text-sm font-bold">{{ __('landing.screen_firstaid_f3') }}</span></div>
                        </div>
                    </div>
                </div>

                <!-- AI scanner -->
                <div x-show="activeTab === 'aiscan'" x-transition style="display: none;" class="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
                    <div class="lg:col-span-5 flex justify-center">
                        <div class="phone w-[260px] sm:w-[290px] h-[540px] sm:h-[600px]">
                            <div class="notch"></div>
                            <img src="{{ asset('images/app_ai_scanner.png') }}" alt="DrRoom AI Scanner">
                        </div>
                    </div>
                    <div class="lg:col-span-7 space-y-6 text-start">
                        <span class="chip">{!! $ico($icoScan, 'w-4 h-4') !!} {{ __('landing.screen_aiscan_badge') }}</span>
                        <h3 class="heading">{{ __('landing.screen_aiscan_title') }}</h3>
                        <p class="text-sm sm:text-base text-[var(--muted)] leading-[2] font-medium">{{ __('landing.screen_aiscan_desc') }}</p>
                        <div class="space-y-3">
                            <div class="row-item"><span class="icon-tile is-blue !w-9 !h-9">{!! $ico($icoCamera, 'w-4 h-4') !!}</span><span class="text-sm font-bold">{{ __('landing.screen_aiscan_f1') }}</span></div>
                            <div class="row-item"><span class="icon-tile !w-9 !h-9">{!! $ico($icoBulb, 'w-4 h-4') !!}</span><span class="text-sm font-bold">{{ __('landing.screen_aiscan_f2') }}</span></div>
                            <div class="row-item"><span class="icon-tile !w-9 !h-9">{!! $ico($icoCheck, 'w-4 h-4') !!}</span><span class="text-sm font-bold">{{ __('landing.screen_aiscan_f3') }}</span></div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Why us -->
    <section id="why-us" class="rule-dash py-20 sm:py-28">
        <div class="w-full px-5 sm:px-8 lg:px-16 2xl:px-24 grid grid-cols-1 lg:grid-cols-12 gap-14 lg:gap-16 items-center">
            <div class="lg:col-span-5 flex justify-center select-none">
                <div class="phone w-[270px] sm:w-[300px] h-[560px] sm:h-[620px]">
                    <div class="notch"></div>
                    <img src="{{ asset('images/app_home.png') }}" alt="DrRoom Trust" onerror="this.onerror=null; this.src='{{ asset('images/app-screen-front.png') }}';">
                </div>
            </div>

            <div class="lg:col-span-7 space-y-8 text-start">
                <div class="space-y-4">
                    <span class="kicker">{{ __('landing.about_tag') }}</span>
                    <h2 class="heading">
                        <span>{{ __('landing.quality_care') }}</span>
                        <span class="text-[var(--blue)]">{{ __('landing.can_trust') }}</span>
                    </h2>
                    <p class="text-sm sm:text-base text-[var(--muted)] font-medium leading-[2]">{{ __('landing.about_desc') }}</p>
                </div>

                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 sm:gap-5">
                    <div class="pillar space-y-4">
                        <div class="icon-tile is-blue">{!! $ico($icoShield) !!}</div>
                        <h4 class="font-black text-sm sm:text-base leading-[1.9]">{{ __('landing.verified_prof') }}</h4>
                        <p class="text-xs sm:text-sm text-[var(--muted)] leading-[1.95] font-medium">{{ __('landing.verified_desc') }}</p>
                    </div>

                    <div class="pillar space-y-4">
                        <div class="icon-tile">{!! $ico($icoBolt) !!}</div>
                        <h4 class="font-black text-sm sm:text-base leading-[1.9]">{{ __('landing.fast_reliable') }}</h4>
                        <p class="text-xs sm:text-sm text-[var(--muted)] leading-[1.95] font-medium">{{ __('landing.fast_desc') }}</p>
                    </div>

                    <div class="pillar space-y-4">
                        <div class="icon-tile">{!! $ico($icoPhone) !!}</div>
                        <h4 class="font-black text-sm sm:text-base leading-[1.9]">{{ __('landing.easy_booking') }}</h4>
                        <p class="text-xs sm:text-sm text-[var(--muted)] leading-[1.95] font-medium">{{ __('landing.easy_desc') }}</p>
                    </div>

                    <div class="pillar space-y-4">
                        <div class="icon-tile">{!! $ico($icoLock) !!}</div>
                        <h4 class="font-black text-sm sm:text-base leading-[1.9]">{{ __('landing.secure_pay') }}</h4>
                        <p class="text-xs sm:text-sm text-[var(--muted)] leading-[1.95] font-medium">{{ __('landing.secure_desc') }}</p>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Staff banner -->
    <section class="px-5 sm:px-8 lg:px-16 2xl:px-24 pb-20 sm:pb-28">
        <div class="w-full bg-[var(--ink)] text-[var(--surface)] rounded-[1.75rem] border-[1.5px] border-[var(--ink)] p-7 sm:p-10 lg:p-12 flex flex-col lg:flex-row items-start lg:items-center justify-between gap-8">
            <div class="space-y-4 text-start max-w-2xl">
                <span class="kicker !bg-transparent !text-[var(--surface)] !border-[var(--surface)]">{{ __('landing.staff_banner_tag') }}</span>
                <h3 class="heading !text-[var(--surface)]">{{ __('landing.staff_banner_title') }}</h3>
                <p class="text-sm text-[#CFC7BA] leading-[2] font-medium">{{ __('landing.staff_banner_desc') }}</p>
            </div>
            <a href="/staff" class="btn-primary !bg-[var(--blue)] flex-shrink-0 !h-14 !px-7 !text-sm">
                <span>{{ __('landing.staff_banner_btn') }}</span>
                <span class="rtl:rotate-180">{!! $ico($icoArrow, 'w-4 h-4') !!}</span>
            </a>
        </div>
    </section>

    <!-- Download -->
    <section id="download" class="rule-dash py-20 sm:py-28">
        <div class="w-full px-5 sm:px-8 lg:px-16 2xl:px-24">
            <div class="bg-[var(--blue)] text-white rounded-[1.75rem] border-[1.5px] border-[var(--ink)] overflow-hidden grid grid-cols-1 lg:grid-cols-12 items-center">
                <div class="lg:col-span-7 p-8 sm:p-12 lg:p-16 space-y-6 text-start">
                    <span class="kicker !bg-transparent !text-white !border-white">{{ __('landing.download_app_tag') }}</span>
                    <h3 class="heading !text-white">{{ __('landing.download_drroom') }}</h3>
                    <p class="text-sm sm:text-base text-blue-50 leading-[2] font-medium max-w-md">{{ __('landing.get_best_exp') }}</p>
                    <div class="flex flex-wrap gap-3 pt-2">
                        <button @click="showDownloadModal = true" class="btn-ink !min-h-[56px] active:translate-y-px">
                            <svg class="w-6 h-6 text-[var(--green)] flex-shrink-0" fill="currentColor" viewBox="0 0 24 24"><path d="M3.609 1.814L13.792 12 3.61 22.186a2.023 2.023 0 01-.61-1.45V3.264c0-.56.22-1.07.609-1.45zm11.602 11.602L18.49 10.13a2.012 2.012 0 000-3.26l-3.279-3.286-4.526 4.526 4.526 4.526zm-9.336 9.336l9.336-9.336-3.818-3.818-9.845 9.845c.87.87 2.37.87 4.327 3.309zm9.336-18.672L5.875 3.416C3.918 5.855 2.418 5.855 1.548 6.725l9.845 9.845 3.818-3.818z"/></svg>
                            <span class="text-start flex flex-col gap-0.5">
                                <span class="text-[10px] opacity-70 font-normal leading-normal">{{ __('landing.get_on') }}</span>
                                <span class="text-xs font-extrabold leading-normal">{{ __('landing.google_play') }}</span>
                            </span>
                        </button>
                        <button @click="showDownloadModal = true" class="btn-ink !min-h-[56px] active:translate-y-px">
                            <svg class="w-6 h-6 flex-shrink-0" fill="currentColor" viewBox="0 0 24 24"><path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 6.37c.62-.75 1.04-1.8 1.01-2.85-.9.04-2.03.62-2.68 1.38-.58.67-.99 1.74-.96 2.81 1.01.08 2.01-.59 2.63-1.34z"/></svg>
                            <span class="text-start flex flex-col gap-0.5">
                                <span class="text-[10px] opacity-70 font-normal leading-normal">{{ __('landing.download_on') }}</span>
                                <span class="text-xs font-extrabold leading-normal">{{ __('landing.app_store') }}</span>
                            </span>
                        </button>
                    </div>
                </div>
                <div class="lg:col-span-5 flex justify-center items-end self-stretch pt-8 lg:pt-0">
                    <div class="w-56 sm:w-64 h-80 sm:h-96 rounded-t-[2.8rem] border-[9px] border-[var(--ink)] bg-[var(--ink)] overflow-hidden translate-y-0">
                        <img src="{{ asset('images/app_home.png') }}" alt="DrRoom App" class="w-full h-full object-cover">
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- How it works -->
    <section id="how-it-works" class="rule-dash py-20 sm:py-28">
        <div class="w-full px-5 sm:px-8 lg:px-16 2xl:px-24">
            <div class="max-w-3xl mb-14 space-y-4 text-start">
                <span class="kicker">{{ __('landing.how_works_title') }}</span>
                <h2 class="heading">{{ __('landing.how_works_title') }}</h2>
                <p class="text-sm sm:text-base text-[var(--muted)] font-medium leading-[2]">{{ __('landing.how_works_desc') }}</p>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-3 md:divide-x-[1.5px] md:divide-dashed md:divide-[var(--line)] gap-12 md:gap-0">
                <div class="md:px-8 first:md:ps-0 last:md:pe-0 space-y-5 text-start">
                    <span class="outline-num">01</span>
                    <h4 class="text-lg font-black leading-[1.8]">{{ __('landing.step_1') }}</h4>
                    <p class="text-sm text-[var(--muted)] leading-[1.95]">{{ __('landing.step_1_desc') }}</p>
                </div>
                <div class="md:px-8 first:md:ps-0 last:md:pe-0 space-y-5 text-start">
                    <span class="outline-num">02</span>
                    <h4 class="text-lg font-black leading-[1.8]">{{ __('landing.step_2') }}</h4>
                    <p class="text-sm text-[var(--muted)] leading-[1.95]">{{ __('landing.step_2_desc') }}</p>
                </div>
                <div class="md:px-8 first:md:ps-0 last:md:pe-0 space-y-5 text-start">
                    <span class="outline-num">03</span>
                    <h4 class="text-lg font-black leading-[1.8]">{{ __('landing.step_3') }}</h4>
                    <p class="text-sm text-[var(--muted)] leading-[1.95]">{{ __('landing.step_3_desc') }}</p>
                </div>
            </div>
        </div>
    </section>

    <!-- FAQ -->
    <section id="faq" class="rule-dash py-20 sm:py-28">
        <div class="w-full px-5 sm:px-8 lg:px-16 2xl:px-24 grid grid-cols-1 lg:grid-cols-12 gap-12">
            <div class="lg:col-span-5 space-y-4 text-start">
                <span class="kicker">{{ __('landing.faq_title') }}</span>
                <h2 class="heading">{{ __('landing.faq_title') }}</h2>
                <p class="text-sm sm:text-base text-[var(--muted)] font-medium leading-[2]">{{ __('landing.faq_desc') }}</p>
            </div>

            <div class="lg:col-span-7 space-y-3" x-data="{ open: 1 }">
                @foreach([
                    ['n' => 1, 'q' => __('landing.faq_1_q'), 'a' => __('landing.faq_1_a')],
                    ['n' => 2, 'q' => __('landing.faq_2_q'), 'a' => __('landing.faq_2_a')],
                    ['n' => 3, 'q' => __('landing.faq_3_q'), 'a' => __('landing.faq_3_a')],
                    ['n' => 4, 'q' => __('landing.faq_4_q'), 'a' => __('landing.faq_4_a')],
                ] as $item)
                    <div class="faq-item">
                        <button @click="open = (open === {{ $item['n'] }} ? null : {{ $item['n'] }})" class="w-full flex items-center justify-between gap-4 p-5 text-start font-black text-sm sm:text-base">
                            <span>{{ $item['q'] }}</span>
                            <span class="icon-tile !w-9 !h-9 transition-transform duration-200" :class="open === {{ $item['n'] }} ? 'rotate-180 is-blue' : ''">
                                {!! $ico($icoDown, 'w-4 h-4') !!}
                            </span>
                        </button>
                        <div x-show="open === {{ $item['n'] }}" x-transition style="display: none;" class="px-5 pb-5">
                            <p class="pt-4 border-t-[1.5px] border-dashed border-[var(--line)] text-sm text-[var(--muted)] leading-[2] font-medium">{{ $item['a'] }}</p>
                        </div>
                    </div>
                @endforeach
            </div>
        </div>
    </section>

    <!-- Footer -->
    <footer id="contact" class="border-t-[1.5px] border-[var(--ink)] bg-[var(--surface)]">
        <div class="w-full px-5 sm:px-8 lg:px-16 2xl:px-24 pt-16 pb-10">
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-10 mb-14 text-start">
                <div class="lg:col-span-2 space-y-5">
                    <div class="flex items-center gap-3">
                        <img src="{{ asset('images/logo.png') }}" alt="DrRoom" class="w-11 h-11 object-contain border-[1.5px] border-[var(--ink)] rounded-xl bg-[var(--surface)] p-1">
                        <div>
                            <div class="text-xl font-black leading-tight" dir="ltr">Dr<span class="text-[var(--blue)]">Room</span></div>
                            <p class="text-[11px] font-semibold text-[var(--muted)] mt-1">{{ __('landing.subtitle') }}</p>
                        </div>
                    </div>
                    <p class="text-sm text-[var(--muted)] leading-[2] max-w-sm font-medium">{{ __('landing.footer_desc') }}</p>
                    <div class="flex items-center gap-2.5">
                        <a href="https://instagram.com" target="_blank" rel="noopener noreferrer" class="w-10 h-10 rounded-xl border-[1.5px] border-[var(--ink)] flex items-center justify-center hover:bg-[var(--ink)] hover:text-[var(--surface)] transition" aria-label="Instagram"><svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"/></svg></a>
                        <a href="https://tiktok.com" target="_blank" rel="noopener noreferrer" class="w-10 h-10 rounded-xl border-[1.5px] border-[var(--ink)] flex items-center justify-center hover:bg-[var(--ink)] hover:text-[var(--surface)] transition" aria-label="TikTok"><svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24"><path d="M12.525.02c1.31-.02 2.61-.01 3.91-.02.08 1.53.63 3.09 1.75 4.17 1.12 1.11 2.7 1.62 4.24 1.79v4.03c-1.44-.05-2.89-.35-4.2-.97-.57-.26-1.1-.59-1.62-.93-.01 2.92.01 5.84-.02 8.75-.08 1.4-.54 2.79-1.35 3.94-1.31 1.92-3.58 3.17-5.91 3.21-1.43.08-2.86-.31-4.08-1.03-2.02-1.19-3.44-3.37-3.65-5.71-.02-.5-.03-1-.01-1.49.18-1.9 1.12-3.72 2.58-4.96 1.66-1.44 3.98-2.13 6.15-1.72.02 1.48-.04 2.96-.04 4.44-.99-.32-2.15-.23-3.02.37-.63.41-1.11 1.04-1.36 1.75-.21.51-.24 1.07-.14 1.61.24 1.64 1.82 3.02 3.5 2.87 1.12-.01 2.19-.66 2.77-1.61.19-.33.4-.67.41-1.06.1-1.79.06-3.57.07-5.36.01-4.03-.01-8.05.02-12.07z"/></svg></a>
                        <a href="https://facebook.com" target="_blank" rel="noopener noreferrer" class="w-10 h-10 rounded-xl border-[1.5px] border-[var(--ink)] flex items-center justify-center hover:bg-[var(--ink)] hover:text-[var(--surface)] transition" aria-label="Facebook"><svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/></svg></a>
                    </div>
                </div>

                <div>
                    <h4 class="font-black text-sm mb-5">{{ __('landing.quick_links') }}</h4>
                    <ul class="space-y-3 text-sm text-[var(--muted)] font-medium">
                        <li><a href="#" class="footer-link">{{ __('landing.home') }}</a></li>
                        <li><a href="#services" class="footer-link">{{ __('landing.services') }}</a></li>
                        <li><a href="#app-screens" class="footer-link">{{ __('landing.app_showcase_tag') }}</a></li>
                        <li><a href="#why-us" class="footer-link">{{ __('landing.about_tag') }}</a></li>
                        <li><a href="#how-it-works" class="footer-link">{{ __('landing.how_it_works') }}</a></li>
                        <li><a href="/staff" class="font-extrabold text-[var(--blue)] footer-link">{{ __('landing.staff_portal') }}</a></li>
                    </ul>
                </div>

                <div>
                    <h4 class="font-black text-sm mb-5">{{ __('landing.services') }}</h4>
                    <ul class="space-y-3 text-sm text-[var(--muted)] font-medium">
                        <li><a href="#services" class="footer-link">{{ __('landing.lab_tests') }}</a></li>
                        <li><a href="#services" class="footer-link">{{ __('landing.nursing') }}</a></li>
                        <li><a href="#services" class="footer-link">{{ __('landing.doctor') }}</a></li>
                        <li><a href="#services" class="footer-link">{{ __('landing.pharmacy') }}</a></li>
                        <li><a href="#services" class="footer-link">{{ __('landing.xray') }}</a></li>
                        <li><a href="#services" class="footer-link">{{ __('landing.health_news') }}</a></li>
                    </ul>
                </div>

                <div>
                    <h4 class="font-black text-sm mb-5">{{ __('landing.contact_us') }}</h4>
                    <ul class="space-y-4 text-sm text-[var(--muted)] font-medium">
                        <li class="flex items-start gap-3">
                            <span class="icon-tile !w-8 !h-8 !rounded-lg">{!! $ico($icoPhone, 'w-4 h-4') !!}</span>
                            <a href="tel:+9647506148003" class="footer-link pt-1.5" dir="ltr">+964 750 614 8003</a>
                        </li>
                        <li class="flex items-start gap-3">
                            <span class="icon-tile !w-8 !h-8 !rounded-lg">{!! $ico($icoPhone, 'w-4 h-4') !!}</span>
                            <a href="tel:+9647764114040" class="footer-link pt-1.5" dir="ltr">+964 776 411 4040</a>
                        </li>
                        <li class="flex items-start gap-3">
                            <span class="icon-tile !w-8 !h-8 !rounded-lg">{!! $ico($icoMail, 'w-4 h-4') !!}</span>
                            <a href="mailto:drrroomapp@gmail.com" class="footer-link pt-1.5">drrroomapp@gmail.com</a>
                        </li>
                        <li class="flex items-start gap-3">
                            <span class="icon-tile !w-8 !h-8 !rounded-lg">{!! $ico($icoPin, 'w-4 h-4') !!}</span>
                            <span class="pt-1.5">{{ __('landing.address') }}</span>
                        </li>
                    </ul>
                </div>
            </div>

            <div class="flex flex-col sm:flex-row items-center justify-between gap-4 pt-6 border-t-[1.5px] border-dashed border-[var(--line)] text-xs text-[var(--muted)] font-medium">
                <div>&copy; {{ date('Y') }} DrRoom. {{ __('landing.rights_reserved') }}.</div>
                <div class="flex flex-wrap gap-6">
                    <a href="/privacy-policy" class="font-extrabold text-[var(--blue)] footer-link">{{ __('landing.privacy') }}</a>
                    <a href="/privacy-policy" class="footer-link">{{ __('landing.terms') }}</a>
                    <a href="/staff/login" class="font-extrabold text-[var(--blue)] footer-link">{{ __('landing.staff_login') }}</a>
                </div>
            </div>
        </div>
    </footer>

    <!-- WhatsApp -->
    <a href="https://wa.me/9647506148003?text={{ rawurlencode('سڵاو، دەربارەی خزمەتگوزارییەکانی دکتۆر رووم پرسیارم هەیە') }}"
       target="_blank"
       rel="noopener noreferrer"
       class="fixed bottom-5 start-5 sm:bottom-6 sm:start-6 z-50 flex items-center gap-2.5 bg-[#25D366] hover:bg-[#20bd5a] text-[var(--ink)] px-4 py-3 rounded-2xl border-[1.5px] border-[var(--ink)] active:translate-y-px transition"
       aria-label="WhatsApp Contact">
        <svg class="w-5 h-5 fill-current flex-shrink-0" viewBox="0 0 24 24"><path d="M.057 24l1.687-6.163c-1.041-1.804-1.588-3.849-1.587-5.946.003-6.556 5.338-11.891 11.893-11.891 3.181.001 6.167 1.24 8.413 3.488 2.245 2.248 3.481 5.236 3.48 8.414-.003 6.557-5.338 11.892-11.893 11.892-1.99-.001-3.951-.5-5.688-1.448l-6.305 1.654zm6.597-3.807c1.676.995 3.276 1.591 5.392 1.592 5.448 0 9.886-4.434 9.889-9.885.002-5.462-4.415-9.89-9.881-9.892-5.452 0-9.887 4.434-9.889 9.884-.001 2.225.651 3.891 1.746 5.634l-.999 3.648 3.742-.981zm11.387-5.464c-.074-.124-.272-.198-.57-.347-.297-.149-1.758-.868-2.031-.967-.272-.099-.47-.149-.669.149-.198.297-.768.967-.941 1.165-.173.198-.347.223-.644.074-.297-.149-1.255-.462-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.297-.347.446-.521.151-.172.2-.296.3-.495.099-.198.05-.372-.025-.521-.075-.148-.669-1.611-.916-2.206-.242-.579-.487-.501-.669-.51l-.57-.01c-.198 0-.52.074-.792.372s-1.04 1.016-1.04 2.479 1.065 2.876 1.213 3.074c.149.198 2.095 3.2 5.076 4.487.709.306 1.263.489 1.694.626.712.226 1.36.194 1.872.118.571-.085 1.758-.719 2.006-1.413.248-.695.248-1.29.173-1.414z"/></svg>
        <span class="text-xs sm:text-sm font-extrabold hidden sm:inline-block">{{ __('landing.whatsapp_contact') }}</span>
    </a>

    <!-- Download modal -->
    <div x-show="showDownloadModal" x-cloak class="fixed inset-0 z-[60] overflow-y-auto" aria-labelledby="modal-title" role="dialog" aria-modal="true">
        <div x-show="showDownloadModal"
             x-transition:enter="ease-out duration-200"
             x-transition:enter-start="opacity-0"
             x-transition:enter-end="opacity-100"
             x-transition:leave="ease-in duration-150"
             x-transition:leave-start="opacity-100"
             x-transition:leave-end="opacity-0"
             @click="showDownloadModal = false"
             class="fixed inset-0" style="background: rgba(28, 26, 23, 0.5);"></div>

        <div class="flex min-h-full items-center justify-center p-4">
            <div x-show="showDownloadModal"
                 x-transition:enter="ease-out duration-200"
                 x-transition:enter-start="opacity-0 scale-95"
                 x-transition:enter-end="opacity-100 scale-100"
                 x-transition:leave="ease-in duration-150"
                 x-transition:leave-start="opacity-100 scale-100"
                 x-transition:leave-end="opacity-0 scale-95"
                 class="relative w-full max-w-lg bg-[var(--surface)] border-[1.5px] border-[var(--ink)] rounded-[1.5rem] p-6 sm:p-8 text-start">
                <div class="flex items-center gap-3 mb-5">
                    <img src="{{ asset('images/logo.png') }}" alt="DrRoom" class="w-11 h-11 object-contain border-[1.5px] border-[var(--ink)] rounded-xl bg-[var(--surface)] p-1">
                    <div>
                        <h3 class="text-base sm:text-lg font-black" id="modal-title">{{ __('landing.app_coming_soon_title') }}</h3>
                        <p class="text-xs text-[var(--blue)] font-extrabold mt-0.5">Google Play & App Store</p>
                    </div>
                </div>

                <p class="text-sm text-[var(--muted)] leading-[2] mb-6 font-medium">{{ __('landing.app_coming_soon_desc') }}</p>

                <div class="space-y-3">
                    <a href="https://wa.me/9647506148003?text={{ rawurlencode('سڵاو، دەمەوێت لە ڕێگەی دکتۆر روومەوە خزمەتگوزاری پزیشکی داوا بکەم') }}"
                       target="_blank"
                       rel="noopener noreferrer"
                       class="w-full flex items-center justify-center gap-3 bg-[#25D366] hover:bg-[#20bd5a] text-[var(--ink)] py-3.5 px-5 rounded-2xl font-extrabold text-sm border-[1.5px] border-[var(--ink)] transition active:translate-y-px">
                        <svg class="w-5 h-5 fill-current flex-shrink-0" viewBox="0 0 24 24"><path d="M.057 24l1.687-6.163c-1.041-1.804-1.588-3.849-1.587-5.946.003-6.556 5.338-11.891 11.893-11.891 3.181.001 6.167 1.24 8.413 3.488 2.245 2.248 3.481 5.236 3.48 8.414-.003 6.557-5.338 11.892-11.893 11.892-1.99-.001-3.951-.5-5.688-1.448l-6.305 1.654zm6.597-3.807c1.676.995 3.276 1.591 5.392 1.592 5.448 0 9.886-4.434 9.889-9.885.002-5.462-4.415-9.89-9.881-9.892-5.452 0-9.887 4.434-9.889 9.884-.001 2.225.651 3.891 1.746 5.634l-.999 3.648 3.742-.981zm11.387-5.464c-.074-.124-.272-.198-.57-.347-.297-.149-1.758-.868-2.031-.967-.272-.099-.47-.149-.669.149-.198.297-.768.967-.941 1.165-.173.198-.347.223-.644.074-.297-.149-1.255-.462-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.297-.347.446-.521.151-.172.2-.296.3-.495.099-.198.05-.372-.025-.521-.075-.148-.669-1.611-.916-2.206-.242-.579-.487-.501-.669-.51l-.57-.01c-.198 0-.52.074-.792.372s-1.04 1.016-1.04 2.479 1.065 2.876 1.213 3.074c.149.198 2.095 3.2 5.076 4.487.709.306 1.263.489 1.694.626.712.226 1.36.194 1.872.118.571-.085 1.758-.719 2.006-1.413.248-.695.248-1.29.173-1.414z"/></svg>
                        <span>{{ __('landing.notify_whatsapp') }}</span>
                    </a>

                    <button @click="showDownloadModal = false" type="button" class="w-full py-2.5 px-4 text-xs font-extrabold text-[var(--muted)] hover:text-[var(--ink)] transition text-center">
                        {{ __('landing.close') }}
                    </button>
                </div>
            </div>
        </div>
    </div>

</body>
</html>
