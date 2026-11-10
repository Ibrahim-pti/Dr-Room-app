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
<html lang="{{ $loc }}" dir="{{ $isRtl ? 'rtl' : 'ltr' }}">
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
            --accent: #FF5A00;
            --accent-ink: #C43F00;
            --accent-soft: #FFE6D6;
        }

        html {
            overflow-x: clip;
            scrollbar-width: none;
        }
        html::-webkit-scrollbar,
        body::-webkit-scrollbar { display: none; }
        body {
            background: var(--paper);
            color: var(--ink);
            font-family: {{ $isRtl ? "'Noto Kufi Arabic', sans-serif" : "'Plus Jakarta Sans', 'Noto Kufi Arabic', sans-serif" }};
            overflow-x: clip;
            -webkit-font-smoothing: antialiased;
        }
        ::selection { background: var(--accent-soft); color: var(--ink); }

        /* Flat, hand-cut feel: solid ink borders, no shadows, no blur, no gradients */
        .card {
            background: var(--surface);
            border: 1.5px solid var(--ink);
            border-radius: 18px;
        }
        .kicker {
            display: inline-block;
            font-size: 12px;
            font-weight: 800;
            letter-spacing: .02em;
            padding: 4px 12px;
            border: 1.5px solid var(--ink);
            border-radius: 999px;
            background: var(--surface);
        }
        .heading {
            font-weight: 900;
            line-height: 1.65 !important;
            letter-spacing: 0;
        }
        .underline-wrap { position: relative; display: inline-block; }
        .underline-wrap svg {
            position: absolute;
            inset-inline: -4px;
            bottom: -10px;
            width: calc(100% + 8px);
            height: 14px;
            overflow: visible;
        }

        /* Fields: underline style, like a paper form */
        .field {
            width: 100%;
            height: 48px;
            padding: 0 2px;
            background: transparent;
            border: 0;
            border-bottom: 1.5px solid var(--ink);
            border-radius: 0;
            font-size: 15px;
            font-weight: 600;
            color: var(--ink);
            outline: none;
        }
        .field::placeholder { color: #A39A8C; font-weight: 500; font-size: 14px; }
        .field:focus { border-bottom-width: 3px; padding-bottom: 0; }
        .field-wrap {
            display: flex;
            align-items: center;
            border-bottom: 1.5px solid var(--ink);
        }
        .field-wrap:focus-within { border-bottom-width: 3px; }
        .field-wrap .field { border: 0; flex: 1; min-width: 0; }
        .field-wrap .field:focus { border: 0; }
        select.field { appearance: none; cursor: pointer; }
        .label {
            display: block;
            font-size: 13px;
            font-weight: 800;
            margin-bottom: 6px;
            color: var(--ink);
        }
        .req { color: var(--accent-ink); }

        /* Choice tiles */
        .opt {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            gap: 8px;
            min-height: 84px;
            padding: 12px 6px;
            border: 1.5px solid var(--ink);
            border-radius: 14px;
            background: var(--surface);
            color: var(--ink);
            font-size: 12px;
            font-weight: 800;
            line-height: 1.5;
            text-align: center;
            cursor: pointer;
            transition: background-color .15s ease, color .15s ease;
        }
        .opt:hover { background: #F7F1E8; }
        .opt.is-on { background: var(--ink); color: var(--surface); }
        .opt.is-on .opt-icon { background: var(--accent); color: var(--ink); }
        .opt-icon {
            width: 34px;
            height: 34px;
            display: flex;
            align-items: center;
            justify-content: center;
            border: 1.5px solid currentColor;
            border-radius: 10px;
        }

        .btn-main {
            width: 100%;
            height: 56px;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            background: var(--accent);
            color: var(--ink);
            border: 1.5px solid var(--ink);
            border-radius: 16px;
            font-size: 16px;
            font-weight: 900;
            cursor: pointer;
            transition: background-color .15s ease;
        }
        .btn-main:hover { background: #FF7A33; }
        .btn-main:disabled { opacity: .6; cursor: not-allowed; }

        .btn-ghost {
            display: inline-flex;
            align-items: center;
            height: 38px;
            padding: 0 14px;
            border: 1.5px solid var(--ink);
            border-radius: 12px;
            background: transparent;
            color: var(--ink);
            font-size: 13px;
            font-weight: 800;
            white-space: nowrap;
            text-decoration: none;
        }
        .btn-ghost:hover { background: var(--ink); color: var(--surface); }

        .tilt-l { transform: rotate(-1.5deg); }
        .tilt-r { transform: rotate(1deg); }

        /* Dashed rule between sections */
        .rule-dash { border-top: 1.5px dashed var(--line); }

        .outline-num {
            font-weight: 900;
            font-size: 56px;
            line-height: 1;
            color: transparent;
            -webkit-text-stroke: 1.5px var(--ink);
        }
    </style>
</head>
<body class="min-h-screen flex flex-col antialiased"
      x-data="{
          langOpen: false,
          showPass: false,
          showConfirm: false,
          submitting: false,
          vehicle: '{{ old('vehicle_type', 'motorcycle') }}',
          scope: '{{ old('service_scope', 'both') }}'
      }">

    <!-- Top bar -->
    <header class="border-b-[1.5px] border-[var(--ink)] bg-[var(--paper)]">
        <div class="max-w-6xl mx-auto px-4 sm:px-6 h-[72px] flex items-center justify-between gap-3">
            <a href="{{ $mainSiteHref }}" class="flex items-center gap-3 min-w-0">
                <img src="{{ asset('images/logo.png') }}" alt="DrRoom" class="w-10 h-10 object-contain flex-shrink-0 border-[1.5px] border-[var(--ink)] rounded-xl bg-[var(--surface)] p-1">
                <div class="flex items-center gap-2 min-w-0">
                    <span class="text-lg font-black leading-none" dir="ltr">Dr<span class="text-[var(--accent)]">Room</span></span>
                    <span class="hidden sm:inline-block kicker !text-[11px] !py-0.5">{{ __('landing.delivery_short') }}</span>
                </div>
            </a>

            <div class="flex items-center gap-2">
                <a href="{{ $mainSiteHref }}" class="hidden md:inline-flex btn-ghost !border-transparent hover:!border-[var(--ink)]">{{ __('delivery.nav_home') }}</a>
                <a href="{{ route('staff.landing') }}" class="hidden sm:inline-flex btn-ghost">{{ __('delivery.nav_staff') }}</a>

                <div class="relative">
                    <button type="button" @click="langOpen = !langOpen" @click.away="langOpen = false" class="btn-ghost gap-1.5">
                        <span>{{ strtoupper($loc == 'ckb' ? 'KU' : $loc) }}</span>
                        <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.2" d="M19 9l-7 7-7-7"></path></svg>
                    </button>

                    <div x-show="langOpen" x-transition style="display: none;"
                         class="absolute end-0 mt-2 w-44 card py-1.5 z-50">
                        <a href="{{ $langHref('ckb') }}" class="flex items-center justify-between px-4 py-2.5 text-xs font-extrabold {{ $loc == 'ckb' ? 'bg-[var(--accent-soft)]' : 'hover:bg-[#F7F1E8]' }}">
                            <span>کوردی (Kurdish)</span>
                            @if($loc == 'ckb') <span class="w-2 h-2 rounded-full bg-[var(--accent)] border border-[var(--ink)]"></span> @endif
                        </a>
                        <a href="{{ $langHref('ar') }}" class="flex items-center justify-between px-4 py-2.5 text-xs font-extrabold {{ $loc == 'ar' ? 'bg-[var(--accent-soft)]' : 'hover:bg-[#F7F1E8]' }}">
                            <span>العربية (Arabic)</span>
                            @if($loc == 'ar') <span class="w-2 h-2 rounded-full bg-[var(--accent)] border border-[var(--ink)]"></span> @endif
                        </a>
                        <a href="{{ $langHref('en') }}" class="flex items-center justify-between px-4 py-2.5 text-xs font-extrabold {{ $loc == 'en' ? 'bg-[var(--accent-soft)]' : 'hover:bg-[#F7F1E8]' }}">
                            <span>English</span>
                            @if($loc == 'en') <span class="w-2 h-2 rounded-full bg-[var(--accent)] border border-[var(--ink)]"></span> @endif
                        </a>
                    </div>
                </div>
            </div>
        </div>
    </header>

    <!-- Hero + form -->
    <main class="flex-1">
        <div class="max-w-6xl mx-auto px-4 sm:px-6 pt-10 sm:pt-16 pb-14 sm:pb-20">
            <div class="grid grid-cols-1 lg:grid-cols-12 gap-10 lg:gap-14 items-start">

                <!-- Story -->
                <div class="lg:col-span-6 space-y-8 text-start">
                    <span class="kicker">{{ __('delivery.badge') }}</span>

                    <h1 class="heading text-[2.1rem] sm:text-5xl lg:text-[3.25rem]">
                        <span class="block">{{ __('delivery.hero_title_1') }}</span>
                        <span class="underline-wrap mt-3 text-[var(--accent-ink)]">
                            {{ __('delivery.hero_title_2') }}
                            <svg viewBox="0 0 200 14" preserveAspectRatio="none" aria-hidden="true">
                                <path d="M3 9 C 40 3, 70 12, 105 6 S 170 4, 197 8" stroke="#1C1A17" stroke-width="3" fill="none" stroke-linecap="round"/>
                            </svg>
                        </span>
                    </h1>

                    <p class="text-base sm:text-lg leading-[2] font-medium text-[var(--muted)] max-w-xl">
                        {{ __('delivery.hero_desc') }}
                    </p>

                    <!-- Rider note -->
                    <div class="card tilt-l p-6 sm:p-7 bg-[var(--accent)]">
                        <div class="flex items-start gap-5">
                            <div class="w-14 h-14 flex-shrink-0 flex items-center justify-center rounded-2xl border-[1.5px] border-[var(--ink)] bg-[var(--surface)]">
                                <svg class="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M5 17a2.5 2.5 0 105 0 2.5 2.5 0 00-5 0zm10 0a2.5 2.5 0 105 0 2.5 2.5 0 00-5 0zM9 17h6m-2-6V7a1 1 0 011-1h2.586a1 1 0 01.707.293l2.414 2.414A1 1 0 0120 9.414V14a1 1 0 01-1 1h-1M3 8h7a1 1 0 011 1v6H4a1 1 0 01-1-1V8z"/>
                                </svg>
                            </div>
                            <div class="space-y-2 min-w-0">
                                <span class="text-[11px] font-black tracking-wide">DRROOM RIDER APP</span>
                                <h3 class="text-lg sm:text-xl font-black leading-[1.9]">{{ __('delivery.feat_1_title') }}</h3>
                                <p class="text-sm font-semibold leading-[1.9]">{{ __('delivery.feat_1_desc') }}</p>
                            </div>
                        </div>
                    </div>

                    <!-- Benefits -->
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                        <div class="card p-5 space-y-3">
                            <div class="w-9 h-9 flex items-center justify-center border-[1.5px] border-[var(--ink)] rounded-lg">
                                <svg class="w-4.5 h-4.5 w-[18px] h-[18px]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>
                            </div>
                            <h4 class="text-sm font-black leading-[1.9]">{{ __('delivery.feat_2_title') }}</h4>
                            <p class="text-xs text-[var(--muted)] leading-[1.9]">{{ __('delivery.feat_2_desc') }}</p>
                        </div>

                        <div class="card p-5 space-y-3">
                            <div class="w-9 h-9 flex items-center justify-center border-[1.5px] border-[var(--ink)] rounded-lg">
                                <svg class="w-[18px] h-[18px]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"></path></svg>
                            </div>
                            <h4 class="text-sm font-black leading-[1.9]">{{ __('delivery.feat_3_title') }}</h4>
                            <p class="text-xs text-[var(--muted)] leading-[1.9]">{{ __('delivery.feat_3_desc') }}</p>
                        </div>
                    </div>
                </div>

                <!-- Form -->
                <div class="lg:col-span-6" id="register-form">
                    <div class="card p-6 sm:p-9 text-start relative">
                        <span class="kicker tilt-r absolute -top-3.5 end-6 !bg-[var(--ink)] !text-[var(--surface)] !border-[var(--ink)]">{{ __('landing.delivery_short') }}</span>

                        <div class="pb-6 mb-7 border-b-[1.5px] border-dashed border-[var(--line)] space-y-2">
                            <h2 class="text-2xl sm:text-[1.7rem] font-black leading-[1.75]">{{ __('delivery.form_title') }}</h2>
                            <p class="text-xs sm:text-sm text-[var(--muted)] leading-[1.9]">{{ __('delivery.form_subtitle') }}</p>
                        </div>

                        @if($errors->any())
                            <div class="mb-6 p-4 rounded-xl border-[1.5px] border-[#B3261E] bg-[#FDECEA] text-[#8C1D18] text-xs font-bold space-y-1.5 leading-relaxed">
                                @foreach($errors->all() as $error)
                                    <p>• {{ $error }}</p>
                                @endforeach
                            </div>
                        @endif

                        <form method="POST" action="{{ route('delivery.register') }}" class="space-y-6" @submit="submitting = true">
                            @csrf
                            <input type="hidden" name="locale" value="{{ $loc }}">
                            <input type="hidden" name="vehicle_type" x-model="vehicle">
                            <input type="hidden" name="service_scope" x-model="scope">

                            <div>
                                <label class="label">{{ __('delivery.full_name') }} <span class="req">*</span></label>
                                <input type="text" name="name" value="{{ old('name') }}" required
                                       placeholder="{{ __('delivery.full_name_placeholder') }}"
                                       class="field">
                            </div>

                            <div>
                                <label class="label">{{ __('delivery.phone') }} <span class="req">*</span></label>
                                <div dir="ltr" class="field-wrap">
                                    <div class="h-12 pe-3 flex items-center gap-1.5 text-xs font-black flex-shrink-0">
                                        <span>🇮🇶</span>
                                        <span>+964</span>
                                    </div>
                                    <input type="tel" name="phone" value="{{ old('phone') }}" required dir="ltr"
                                           placeholder="{{ __('delivery.phone_placeholder') }}"
                                           class="field text-left">
                                </div>
                                <p class="text-[11px] text-[var(--muted)] mt-2 font-medium leading-[1.9]">{{ __('delivery.phone_hint') }}</p>
                            </div>

                            <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
                                <div>
                                    <label class="label">{{ __('delivery.city') }} <span class="req">*</span></label>
                                    <select name="city" class="field">
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
                                                <svg class="w-[18px] h-[18px]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.9" d="{{ $path }}"></path></svg>
                                            </span>
                                            <span>{{ __('delivery.vehicle_short_' . $vKey) }}</span>
                                        </button>
                                    @endforeach
                                </div>
                            </div>

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
                                                <svg class="w-[18px] h-[18px]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.9" d="{{ $path }}"></path></svg>
                                            </span>
                                            <span>{{ __('delivery.scope_short_' . $sKey) }}</span>
                                        </button>
                                    @endforeach
                                </div>
                            </div>

                            <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
                                <div>
                                    <label class="label">{{ __('delivery.password') }} <span class="req">*</span></label>
                                    <div class="field-wrap">
                                        <input :type="showPass ? 'text' : 'password'" name="password" required minlength="6"
                                               placeholder="{{ __('delivery.password_placeholder') }}"
                                               class="field">
                                        <button type="button" @click="showPass = !showPass" class="px-2 h-12 text-[var(--muted)] hover:text-[var(--ink)] flex-shrink-0">
                                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path></svg>
                                        </button>
                                    </div>
                                </div>

                                <div>
                                    <label class="label">{{ __('delivery.password_confirm') }} <span class="req">*</span></label>
                                    <div class="field-wrap">
                                        <input :type="showConfirm ? 'text' : 'password'" name="password_confirmation" required minlength="6"
                                               placeholder="{{ __('delivery.password_confirm_placeholder') }}"
                                               class="field">
                                        <button type="button" @click="showConfirm = !showConfirm" class="px-2 h-12 text-[var(--muted)] hover:text-[var(--ink)] flex-shrink-0">
                                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path></svg>
                                        </button>
                                    </div>
                                </div>
                            </div>

                            <div class="pt-2">
                                <button type="submit" :disabled="submitting" class="btn-main">
                                    <span x-show="!submitting">{{ __('delivery.submit_btn') }}</span>
                                    <span x-show="submitting" style="display: none;">{{ __('delivery.submitting') }}</span>
                                </button>
                            </div>

                            <p class="text-[11.5px] text-center text-[var(--muted)] font-medium leading-[1.9]">
                                {{ __('delivery.step_note') }}
                            </p>
                        </form>
                    </div>
                </div>

            </div>
        </div>
    </main>

    <!-- Steps -->
    <section class="rule-dash border-t-0">
        <div class="max-w-6xl mx-auto px-4 sm:px-6 py-16 sm:py-20">
            <div class="max-w-2xl mb-12 space-y-3 text-start">
                <h2 class="heading text-2xl sm:text-4xl">{{ __('delivery.how_title') }}</h2>
                <p class="text-sm sm:text-base text-[var(--muted)] leading-[1.9]">{{ __('delivery.how_sub') }}</p>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-3 md:divide-x-[1.5px] md:divide-dashed md:divide-[var(--line)] gap-10 md:gap-0">
                @foreach([
                    ['n' => '01', 'title' => __('delivery.step1_t'), 'desc' => __('delivery.step1_d')],
                    ['n' => '02', 'title' => __('delivery.step2_t'), 'desc' => __('delivery.step2_d')],
                    ['n' => '03', 'title' => __('delivery.step3_t'), 'desc' => __('delivery.step3_d')],
                ] as $step)
                    <div class="md:px-8 first:md:ps-0 last:md:pe-0 space-y-5 text-start">
                        <span class="outline-num">{{ $step['n'] }}</span>
                        <h3 class="text-lg font-black leading-[1.8]">{{ $step['title'] }}</h3>
                        <p class="text-sm text-[var(--muted)] leading-[1.95]">{{ $step['desc'] }}</p>
                    </div>
                @endforeach
            </div>
        </div>
    </section>

    <footer class="border-t-[1.5px] border-dashed border-[var(--line)]">
        <div class="max-w-6xl mx-auto px-4 sm:px-6 py-7 text-center">
            <p class="text-xs font-bold text-[var(--muted)]">{{ __('delivery.footer_copy') }}</p>
        </div>
    </footer>

</body>
</html>
