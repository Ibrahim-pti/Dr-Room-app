@php
    $loc = $locale ?? app()->getLocale();
    $isRtl = in_array($loc, ['ar', 'ckb', 'kmr']);
    $cities = __('delivery.cities');
    if (!is_array($cities)) {
        $cities = ['هەولێر', 'سلێمانی', 'دهۆک', 'کەرکوک', 'هەڵەبجە'];
    }
    $rolesMeta = __('delivery.roles');
    $educationOpts = __('delivery.education_options');
    $skillsOpts = __('delivery.skills_options');
    $shiftOpts = __('delivery.shifts');
    $workDaysOpts = __('delivery.work_days_options');
    $wfSteps = __('delivery.wf_steps');
    $faqs = __('delivery.faqs');

    $isSubdomain = str_starts_with(strtolower(request()->getHost()), 'delivery.');
    $langHref = fn (string $target) => $isSubdomain ? '/' . $target : '/delivery/' . $target;
    $mainSiteHref = $isSubdomain
        ? str_ireplace('://delivery.', '://', url('/'))
        : '/' . ($loc === 'ckb' ? '' : $loc);

    $initialStep = 1;
    if ($errors->has('agree_terms') || $errors->has('files')) {
        $initialStep = 4;
    }

    $oldSkills = old('clinical_skills', []);
    if (!is_array($oldSkills)) {
        $oldSkills = [];
    }
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
            --muted: #5F574D;
            --line: #D8CFC2;
            --accent: #FF5A00;
            --accent-deep: #DC4900;
            --accent-soft: #FFE6D6;
        }

        html {
            overflow-x: clip;
            scroll-behavior: smooth;
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

        .card {
            background: var(--surface);
            border: 1px solid #EAE1D5;
            border-radius: 22px;
        }

        .kicker {
            display: inline-flex;
            align-items: center;
            gap: 7px;
            font-size: 12px;
            font-weight: 800;
            padding: 6px 14px;
            border: 1px solid #EAE1D5;
            border-radius: 999px;
            background: var(--surface);
            color: var(--ink);
        }

        .hero-headline {
            font-weight: 900;
            line-height: 1.78 !important;
            letter-spacing: -0.01em;
        }

        /* Crisp flat bordered input boxes */
        .field-box {
            width: 100%;
            min-height: 48px;
            padding: 10px 14px;
            background: #FFFFFF;
            border: 1.5px solid #DED5C8;
            border-radius: 13px;
            font-size: 14px;
            font-weight: 600;
            color: var(--ink);
            outline: none;
            transition: border-color .16s ease;
        }
        .field-box::placeholder { color: #9A9082; font-weight: 500; font-size: 13px; }
        .field-box:focus {
            border-color: var(--accent);
        }

        .phone-group {
            display: flex;
            align-items: stretch;
            background: #FFFFFF;
            border: 1.5px solid #DED5C8;
            border-radius: 13px;
            overflow: hidden;
            transition: border-color .16s ease;
        }
        .phone-group:focus-within {
            border-color: var(--accent);
        }
        .phone-group input {
            flex: 1;
            min-width: 0;
            min-height: 46px;
            padding: 10px 14px;
            border: 0;
            background: transparent;
            font-size: 14px;
            font-weight: 700;
            color: var(--ink);
            outline: none;
        }
        .phone-group input::placeholder { color: #9A9082; font-weight: 500; font-size: 13px; }

        .label {
            display: block;
            font-size: 13px;
            font-weight: 800;
            margin-bottom: 7px;
            color: var(--ink);
        }
        .req { color: var(--accent-deep); }

        .role-card {
            display: flex;
            align-items: flex-start;
            gap: 12px;
            width: 100%;
            padding: 13px 14px;
            border: 1px solid #E5DDD0;
            border-radius: 15px;
            background: #FFFFFF;
            text-align: start;
            cursor: pointer;
            transition: border-color .16s ease, background-color .16s ease;
        }
        .role-card:hover { border-color: #CFC3B2; background: #FFFDF9; }
        .role-card.is-on {
            border: 1.5px solid var(--accent);
            background: #FFF4EC;
            color: var(--ink);
        }
        .role-card.is-on .role-sub { color: #6B5D52; }
        .role-icon {
            width: 38px;
            height: 38px;
            border-radius: 11px;
            background: #FAF5ED;
            color: var(--accent-deep);
            display: flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
            transition: background-color .16s ease, color .16s ease;
        }
        .role-card.is-on .role-icon {
            background: var(--accent);
            color: #FFFFFF;
        }

        .opt-pill {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            padding: 10px 14px;
            border: 1px solid #E3DAD0;
            border-radius: 12px;
            background: #FFFFFF;
            color: var(--ink);
            font-size: 12.5px;
            font-weight: 800;
            line-height: 1.5;
            cursor: pointer;
            transition: all .15s ease;
        }
        .opt-pill:hover { border-color: #C7BBAA; background: #FFFDF9; }
        .opt-pill.is-on {
            background: #FFF2E8;
            border: 1.5px solid var(--accent);
            color: #B93A00;
        }

        .skill-chip {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 10px 12px;
            border: 1px solid #E3DAD0;
            border-radius: 12px;
            background: #FFFFFF;
            font-size: 12px;
            font-weight: 700;
            line-height: 1.6;
            cursor: pointer;
            transition: all .15s ease;
            text-align: start;
        }
        .skill-chip:hover { border-color: #C7BBAA; }
        .skill-chip.is-on {
            border: 1.5px solid var(--accent);
            background: #FFF4EC;
            color: var(--ink);
        }

        .btn-main {
            height: 50px;
            padding: 0 22px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            background: var(--accent);
            color: #FFFFFF;
            border: 0;
            border-radius: 14px;
            font-size: 14.5px;
            font-weight: 800;
            cursor: pointer;
            transition: background-color .15s ease;
        }
        .btn-main:hover { background: var(--accent-deep); }
        .btn-main:disabled { opacity: .65; cursor: not-allowed; }

        .btn-secondary {
            height: 50px;
            padding: 0 18px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            background: #FFFFFF;
            color: var(--ink);
            border: 1px solid #DDD3C4;
            border-radius: 14px;
            font-size: 14px;
            font-weight: 800;
            cursor: pointer;
            transition: background-color .15s ease, border-color .15s ease;
        }
        .btn-secondary:hover { background: #F8F3EB; border-color: #C4B7A5; }

        .btn-ghost {
            display: inline-flex;
            align-items: center;
            height: 38px;
            padding: 0 14px;
            border: 1px solid #DFD5C7;
            border-radius: 12px;
            background: var(--surface);
            color: var(--ink);
            font-size: 13px;
            font-weight: 800;
            white-space: nowrap;
            text-decoration: none;
            transition: all .15s ease;
        }
        .btn-ghost:hover { background: var(--ink); border-color: var(--ink); color: var(--surface); }

        .rule-dash { border-top: 1px solid #E8DFD3; }

        .outline-num {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 42px;
            height: 42px;
            border-radius: 12px;
            background: #FFF1E7;
            color: var(--accent-deep);
            font-weight: 900;
            font-size: 16px;
        }
    </style>
</head>
<body class="min-h-screen flex flex-col antialiased"
      x-data="{
          langOpen: false,
          step: {{ $initialStep }},
          clientError: '',
          showPass: false,
          showConfirm: false,
          submitting: false,
          applicantRole: '{{ old('applicant_role', 'phlebotomist') }}',
          gender: '{{ old('gender', 'male') }}',
          experienceYears: {{ (int) old('experience_years', 1) }},
          skills: @js($oldSkills),
          shift: '{{ old('availability_shift', 'full_flex') }}',
          workDays: '{{ old('work_days', 'daily') }}',
          hasPrivateCar: '{{ old('has_private_car', '1') }}',
          willingToTravel: '{{ old('willing_to_travel', '1') }}',
          vehicle: '{{ old('vehicle_type', 'car') }}',
          scope: '{{ old('service_scope', 'both') }}',
          agreed: {{ old('agree_terms') ? 'true' : 'false' }},
          files: { id_document: '', certificate: '', license: '', cv: '' },
          openFaq: 0,

          toggleSkill(key) {
              if (this.skills.includes(key)) {
                  this.skills = this.skills.filter(item => item !== key);
              } else {
                  this.skills.push(key);
              }
          },

          onFileChange(key, event) {
              const file = event.target.files && event.target.files[0];
              this.files[key] = file ? file.name : '';
          },

          nextStep() {
              this.clientError = '';
              if (this.step === 1) {
                  const name = (this.$refs.fullName?.value || '').trim();
                  const phone = (this.$refs.phoneInput?.value || '').trim();
                  const pass = this.$refs.passInput?.value || '';
                  const passConf = this.$refs.passConfirmInput?.value || '';

                  if (!name) {
                      this.clientError = @js(__('delivery.err_name'));
                      return;
                  }
                  if (!phone) {
                      this.clientError = @js(__('delivery.err_phone'));
                      return;
                  }
                  if (pass.length < 6) {
                      this.clientError = @js(__('delivery.err_password'));
                      return;
                  }
                  if (pass !== passConf) {
                      this.clientError = @js(__('delivery.err_password_confirm'));
                      return;
                  }
              }
              if (this.step < 4) {
                  this.step++;
                  document.getElementById('apply-form')?.scrollIntoView({ behavior: 'smooth', block: 'start' });
              }
          },

          prevStep() {
              this.clientError = '';
              if (this.step > 1) {
                  this.step--;
              }
          }
      }">

    <!-- Header -->
    <header class="border-b border-[#E6DDD0] bg-[#F4EFE6]/95 backdrop-blur-md sticky top-0 z-40">
        <div class="w-full px-5 sm:px-8 lg:px-14 2xl:px-20 h-[72px] flex items-center justify-between gap-3">
            <a href="{{ $mainSiteHref }}" class="flex items-center gap-3 min-w-0">
                <img src="{{ asset('images/logo.png') }}" alt="DrRoom" class="w-10 h-10 object-contain flex-shrink-0 border border-[#E6DDD0] rounded-xl bg-[var(--surface)] p-1">
                <div class="flex items-center gap-2 min-w-0">
                    <span class="text-lg font-black leading-none" dir="ltr">Dr<span class="text-[var(--accent)]">Room</span></span>
                    <span class="hidden sm:inline-block kicker !text-[11px] !py-1">{{ __('delivery.brand_tag') }}</span>
                </div>
            </a>

            <div class="flex items-center gap-2">
                <a href="{{ $mainSiteHref }}" class="hidden md:inline-flex btn-ghost !border-transparent !bg-transparent hover:!bg-[var(--surface)] hover:!border-[#E6DDD0] hover:!text-[var(--ink)]">{{ __('delivery.nav_home') }}</a>
                <a href="{{ route('staff.landing') }}" class="hidden sm:inline-flex btn-ghost">{{ __('delivery.nav_staff') }}</a>
                <a href="#apply-form" class="hidden lg:inline-flex btn-ghost !bg-[var(--accent)] !text-white !border-transparent hover:!bg-[var(--accent-deep)]">{{ __('delivery.nav_join') }}</a>

                <div class="relative">
                    <button type="button" @click="langOpen = !langOpen" @click.away="langOpen = false" class="btn-ghost gap-1.5">
                        <span>{{ strtoupper($loc == 'ckb' ? 'KU-S' : ($loc == 'kmr' ? 'KU-B' : $loc)) }}</span>
                        <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.2" d="M19 9l-7 7-7-7"></path></svg>
                    </button>

                    <div x-show="langOpen" x-transition style="display: none;" class="absolute end-0 mt-2 w-52 card py-1.5 z-50">
                        <a href="{{ $langHref('ckb') }}" class="flex items-center justify-between px-4 py-2.5 text-xs font-extrabold {{ $loc == 'ckb' ? 'bg-[var(--accent-soft)]' : 'hover:bg-[#F7F1E8]' }}">
                            <span>کوردی سۆرانی (Kurdish)</span>
                            @if($loc == 'ckb') <span class="w-2 h-2 rounded-full bg-[var(--accent)] border border-[var(--ink)]"></span> @endif
                        </a>
                        <a href="{{ $langHref('kmr') }}" class="flex items-center justify-between px-4 py-2.5 text-xs font-extrabold {{ $loc == 'kmr' ? 'bg-[var(--accent-soft)]' : 'hover:bg-[#F7F1E8]' }}">
                            <span>کوردی بادینی (Badini)</span>
                            @if($loc == 'kmr') <span class="w-2 h-2 rounded-full bg-[var(--accent)] border border-[var(--ink)]"></span> @endif
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

    <!-- Main Hero + Multi-Step Application -->
    <main class="flex-1 w-full px-5 sm:px-8 lg:px-14 2xl:px-20 py-10 sm:py-14">
        <div class="grid grid-cols-1 lg:grid-cols-12 gap-10 xl:gap-14 items-start">

            <!-- Pitch & Clinical Benefits Column -->
            <div class="lg:col-span-6 space-y-7 text-start">
                <div class="space-y-5">
                    <span class="kicker">
                        <span class="w-2 h-2 rounded-full bg-[var(--accent)]"></span>
                        {{ __('delivery.badge') }}
                    </span>

                    <h1 class="hero-headline text-[28px] sm:text-[36px] xl:text-[42px] !leading-[1.78] text-[var(--ink)]">
                        <span class="block">{{ __('delivery.hero_title_1') }}</span>
                        <span class="block text-[var(--accent-deep)] mt-2">{{ __('delivery.hero_title_2') }}</span>
                    </h1>

                    <p class="text-sm sm:text-[15.5px] text-[var(--muted)] leading-[2] max-w-2xl font-medium">
                        {{ __('delivery.hero_desc') }}
                    </p>

                    <div class="flex flex-wrap gap-2.5 pt-1">
                        <span class="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-[var(--surface)] border border-[#E6DDD0] text-xs font-extrabold text-[var(--ink)]">
                            <svg class="w-4 h-4 text-[var(--accent)]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"></path></svg>
                            {{ __('delivery.hero_pill_1') }}
                        </span>
                        <span class="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-[var(--surface)] border border-[#E6DDD0] text-xs font-extrabold text-[var(--ink)]">
                            <svg class="w-4 h-4 text-[var(--accent)]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                            {{ __('delivery.hero_pill_2') }}
                        </span>
                        <span class="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-[var(--surface)] border border-[#E6DDD0] text-xs font-extrabold text-[var(--ink)]">
                            <svg class="w-4 h-4 text-[var(--accent)]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                            {{ __('delivery.hero_pill_3') }}
                        </span>
                    </div>
                </div>

                <!-- High-Contrast Feature Highlight Card (Flat & Clean) -->
                <div class="rounded-[22px] bg-[#EC5200] text-white p-6">
                    <div class="flex items-start justify-between gap-4">
                        <div class="space-y-2">
                            <span class="inline-block px-3 py-1 rounded-full bg-white/20 text-white text-[10.5px] font-extrabold tracking-wider">
                                {{ __('delivery.highlight_badge') }}
                            </span>
                            <h2 class="text-lg sm:text-xl font-black text-white leading-[1.7]">
                                {{ __('delivery.feat_1_title') }}
                            </h2>
                            <p class="text-sm text-white/95 leading-[1.9] font-medium">
                                {{ __('delivery.feat_1_desc') }}
                            </p>
                        </div>
                        <div class="w-12 h-12 rounded-2xl bg-white/15 text-white flex items-center justify-center flex-shrink-0">
                            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z"></path>
                            </svg>
                        </div>
                    </div>
                </div>

                <!-- 3 Secondary Benefit Cards (Spacious 2-col layout with zero cramped text) -->
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
                    <div class="card p-5 space-y-2.5">
                        <div class="w-10 h-10 rounded-xl bg-[#FFF1E7] text-[var(--accent-deep)] flex items-center justify-center">
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>
                        </div>
                        <h3 class="text-sm font-black leading-[1.65]">{{ __('delivery.feat_2_title') }}</h3>
                        <p class="text-xs text-[var(--muted)] leading-[1.85]">{{ __('delivery.feat_2_desc') }}</p>
                    </div>

                    <div class="card p-5 space-y-2.5">
                        <div class="w-10 h-10 rounded-xl bg-[#FFF1E7] text-[var(--accent-deep)] flex items-center justify-center">
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"></path></svg>
                        </div>
                        <h3 class="text-sm font-black leading-[1.65]">{{ __('delivery.feat_3_title') }}</h3>
                        <p class="text-xs text-[var(--muted)] leading-[1.85]">{{ __('delivery.feat_3_desc') }}</p>
                    </div>

                    <div class="card p-5 sm:col-span-2 flex items-start gap-4">
                        <div class="w-10 h-10 rounded-xl bg-[#FFF1E7] text-[var(--accent-deep)] flex items-center justify-center flex-shrink-0">
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z"></path></svg>
                        </div>
                        <div class="space-y-1">
                            <h3 class="text-sm font-black leading-[1.65]">{{ __('delivery.feat_4_title') }}</h3>
                            <p class="text-xs text-[var(--muted)] leading-[1.85]">{{ __('delivery.feat_4_desc') }}</p>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 4-Step Interactive Medical Recruitment Form Column -->
            <div class="lg:col-span-6" id="apply-form">
                <div class="card p-5 sm:p-8 text-start">
                    <div class="flex flex-wrap items-center justify-between gap-2 pb-4 border-b border-[#EFE8DC]">
                        <span class="px-3 py-1 rounded-full bg-[#FFF2E8] text-[var(--accent-deep)] text-[11px] font-extrabold">
                            {{ __('delivery.form_badge') }}
                        </span>
                        <span class="text-xs font-extrabold text-[var(--muted)]">
                            {{ __('delivery.step_of') }} <span class="text-[var(--accent-deep)]" x-text="step"></span> / 4
                        </span>
                    </div>

                    <div class="mt-4 text-start">
                        <h2 class="text-xl sm:text-2xl font-black text-[var(--ink)] leading-[1.65] text-start">{{ __('delivery.form_title') }}</h2>
                        <p class="text-xs sm:text-[13px] text-[var(--muted)] mt-1.5 leading-[1.85] text-start">{{ __('delivery.form_subtitle') }}</p>
                    </div>

                    <!-- Interactive 4-Step Progress Bar -->
                    <div class="grid grid-cols-4 items-start gap-2.5 mt-5 mb-6">
                        @foreach([
                            1 => __('delivery.step_1_short'),
                            2 => __('delivery.step_2_short'),
                            3 => __('delivery.step_3_short'),
                            4 => __('delivery.step_4_short'),
                        ] as $idx => $stepTitle)
                            <button type="button"
                                    @click="if ({{ $idx }} <= step) step = {{ $idx }}"
                                    class="w-full flex flex-col items-stretch justify-start text-start group cursor-pointer focus:outline-none">
                                <div class="w-full h-1.5 rounded-full transition-colors duration-200"
                                     :class="step >= {{ $idx }} ? 'bg-[var(--accent)]' : 'bg-[#EAE2D6]'"></div>
                                <p class="mt-2 w-full text-start text-[10.5px] sm:text-[11px] font-extrabold leading-[1.6]"
                                   :class="step === {{ $idx }} ? 'text-[var(--accent-deep)]' : (step > {{ $idx }} ? 'text-[var(--ink)]' : 'text-[var(--muted)]')">
                                    {{ $idx }}. {{ $stepTitle }}
                                </p>
                            </button>
                        @endforeach
                    </div>

                    @if($errors->any())
                        <div class="mb-5 p-4 rounded-xl bg-red-50 border-[1.5px] border-red-400 text-xs font-bold text-red-900 space-y-1">
                            @foreach($errors->all() as $error)
                                <p>• {{ $error }}</p>
                            @endforeach
                        </div>
                    @endif

                    <div x-show="clientError" x-cloak style="display: none;"
                         class="mb-5 p-3.5 rounded-xl bg-red-50 border-[1.5px] border-red-400 text-xs font-extrabold text-red-900"
                         x-text="clientError"></div>

                    <form method="POST"
                          action="{{ route('delivery.register') }}"
                          enctype="multipart/form-data"
                          @submit="if (step < 4) { $event.preventDefault(); nextStep(); return; } if (!agreed) { $event.preventDefault(); clientError = @js(__('delivery.err_terms')); return; } submitting = true;"
                          class="space-y-5">
                        @csrf
                        <input type="hidden" name="locale" value="{{ $loc }}">
                        <input type="hidden" name="applicant_role" :value="applicantRole">
                        <input type="hidden" name="gender" :value="gender">
                        <input type="hidden" name="availability_shift" :value="shift">
                        <input type="hidden" name="work_days" :value="workDays">
                        <input type="hidden" name="has_private_car" :value="hasPrivateCar">
                        <input type="hidden" name="willing_to_travel" :value="willingToTravel">
                        <input type="hidden" name="vehicle_type" :value="applicantRole === 'courier' ? vehicle : (hasPrivateCar === '1' ? 'car' : 'motorcycle')">
                        <input type="hidden" name="service_scope" :value="applicantRole === 'courier' ? scope : (applicantRole === 'phlebotomist' ? 'lab_sample' : 'both')">

                        <!-- ==================== STEP 1: Role & Identity ==================== -->
                        <div x-show="step === 1" class="space-y-4">
                            <div>
                                <label class="label">{{ __('delivery.role_label') }} <span class="req">*</span></label>
                                <div class="space-y-2.5">
                                    @foreach(['phlebotomist', 'mobile_nurse', 'both', 'courier'] as $roleKey)
                                        @php $rInfo = $rolesMeta[$roleKey] ?? ['title' => $roleKey, 'desc' => '']; @endphp
                                        <button type="button"
                                                @click="applicantRole = '{{ $roleKey }}'"
                                                :class="applicantRole === '{{ $roleKey }}' ? 'is-on' : ''"
                                                class="role-card">
                                            <span class="role-icon">
                                                @if($roleKey === 'phlebotomist')
                                                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"></path></svg>
                                                @elseif($roleKey === 'mobile_nurse')
                                                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"></path></svg>
                                                @elseif($roleKey === 'both')
                                                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v12m6-6H6"></path></svg>
                                                @else
                                                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"></path></svg>
                                                @endif
                                            </span>
                                            <span class="min-w-0 flex-1">
                                                <span class="block text-[13px] font-black leading-[1.45]">{{ $rInfo['title'] }}</span>
                                                <span class="role-sub block text-[11.5px] font-medium text-[var(--muted)] mt-0.5 leading-[1.55]">{{ $rInfo['desc'] }}</span>
                                            </span>
                                        </button>
                                    @endforeach
                                </div>
                            </div>

                            <div>
                                <label class="label">{{ __('delivery.full_name') }} <span class="req">*</span></label>
                                <input type="text" x-ref="fullName" name="name" value="{{ old('name') }}" required
                                       placeholder="{{ __('delivery.full_name_placeholder') }}" class="field-box">
                            </div>

                            <div class="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
                                <div>
                                    <label class="label">{{ __('delivery.phone') }} <span class="req">*</span></label>
                                    <div class="phone-group" dir="ltr">
                                        <span class="inline-flex items-center gap-1.5 px-3 bg-[#F6F1EA] border-e border-[#D9CFC2] text-xs font-extrabold text-[var(--ink)]">
                                            <span>🇮🇶</span>
                                            <span>+964</span>
                                        </span>
                                        <input type="tel" x-ref="phoneInput" name="phone" value="{{ old('phone') }}" required inputmode="tel"
                                               placeholder="{{ __('delivery.phone_placeholder') }}">
                                    </div>
                                    <p class="mt-1 text-[11px] font-medium text-[var(--muted)]">{{ __('delivery.phone_hint') }}</p>
                                </div>

                                <div>
                                    <label class="label">{{ __('delivery.city') }} <span class="req">*</span></label>
                                    <select name="city" class="field-box cursor-pointer">
                                        @foreach($cities as $c)
                                            <option value="{{ $c }}" {{ old('city', $cities[0]) == $c ? 'selected' : '' }}>{{ $c }}</option>
                                        @endforeach
                                    </select>
                                </div>
                            </div>

                            <div>
                                <label class="label">{{ __('delivery.gender') }} <span class="req">*</span></label>
                                <div class="grid grid-cols-2 gap-2.5">
                                    <button type="button" @click="gender = 'male'" :class="gender === 'male' ? 'is-on' : ''" class="opt-pill">
                                        {{ __('delivery.gender_male') }}
                                    </button>
                                    <button type="button" @click="gender = 'female'" :class="gender === 'female' ? 'is-on' : ''" class="opt-pill">
                                        {{ __('delivery.gender_female') }}
                                    </button>
                                </div>
                            </div>

                            <div class="grid grid-cols-1 sm:grid-cols-2 gap-3.5 items-end">
                                <div>
                                    <label class="label">{{ __('delivery.password') }} <span class="req">*</span></label>
                                    <div class="relative">
                                        <input :type="showPass ? 'text' : 'password'" x-ref="passInput" name="password" required minlength="6"
                                               class="field-box pe-10">
                                        <button type="button" @click="showPass = !showPass" class="absolute inset-y-0 end-3 flex items-center text-[var(--muted)] hover:text-[var(--ink)]">
                                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path></svg>
                                        </button>
                                    </div>
                                </div>

                                <div>
                                    <label class="label whitespace-nowrap">{{ __('delivery.password_confirm') }} <span class="req">*</span></label>
                                    <div class="relative">
                                        <input :type="showConfirm ? 'text' : 'password'" x-ref="passConfirmInput" name="password_confirmation" required minlength="6"
                                               placeholder="{{ __('delivery.password_confirm_placeholder') }}" class="field-box pe-10">
                                        <button type="button" @click="showConfirm = !showConfirm" class="absolute inset-y-0 end-3 flex items-center text-[var(--muted)] hover:text-[var(--ink)]">
                                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path></svg>
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- ==================== STEP 2: Clinical Experience & Skills ==================== -->
                        <div x-show="step === 2" x-cloak style="display: none;" class="space-y-4">
                            <div class="p-3.5 rounded-xl bg-[#FAF5ED] border border-[var(--line)]">
                                <h3 class="text-sm font-black text-[var(--ink)]"
                                    x-text="applicantRole === 'courier' ? @js(__('delivery.step2_courier_title')) : @js(__('delivery.step2_medical_title'))"></h3>
                                <p class="text-xs text-[var(--muted)] mt-1 leading-[1.7]"
                                   x-text="applicantRole === 'courier' ? @js(__('delivery.step2_courier_desc')) : @js(__('delivery.step2_medical_desc'))"></p>
                            </div>

                            <div class="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
                                <div x-show="applicantRole !== 'courier'">
                                    <label class="label">{{ __('delivery.education_label') }}</label>
                                    <select name="education_level" class="field-box cursor-pointer">
                                        @foreach($educationOpts as $edKey => $edLabel)
                                            <option value="{{ $edKey }}" {{ old('education_level', 'bsc_lab') == $edKey ? 'selected' : '' }}>{{ $edLabel }}</option>
                                        @endforeach
                                    </select>
                                </div>

                                <div>
                                    <label class="label">{{ __('delivery.experience_label') }}</label>
                                    <div class="flex items-center gap-2">
                                        <button type="button" @click="if (experienceYears > 0) experienceYears--"
                                                class="w-11 h-11 rounded-xl border-[1.5px] border-[#B9AE9E] bg-white font-black text-lg hover:border-[var(--ink)]">-</button>
                                        <input type="number" name="experience_years" min="0" max="60" x-model.number="experienceYears"
                                               class="field-box text-center !w-24 font-black">
                                        <button type="button" @click="if (experienceYears < 60) experienceYears++"
                                                class="w-11 h-11 rounded-xl border-[1.5px] border-[#B9AE9E] bg-white font-black text-lg hover:border-[var(--ink)]">+</button>
                                        <span class="text-xs font-extrabold text-[var(--muted)]">{{ __('delivery.experience_suffix') }}</span>
                                    </div>
                                </div>
                            </div>

                            <div>
                                <label class="label">{{ __('delivery.skills_label') }}</label>
                                <div class="grid grid-cols-1 sm:grid-cols-2 gap-2">
                                    @foreach($skillsOpts as $skKey => $skLabel)
                                        @php
                                            $isLogisticsSkill = in_array($skKey, ['cold_chain', 'pharma_handling'], true);
                                        @endphp
                                        <button type="button"
                                                @if(!$isLogisticsSkill) x-show="applicantRole !== 'courier'" @endif
                                                @click="toggleSkill('{{ $skKey }}')"
                                                :class="skills.includes('{{ $skKey }}') ? 'is-on' : ''"
                                                class="skill-chip">
                                            <span class="w-4 h-4 rounded flex items-center justify-center border border-current flex-shrink-0"
                                                  :class="skills.includes('{{ $skKey }}') ? 'bg-[var(--accent)] border-[var(--accent)] text-white' : ''">
                                                <svg x-show="skills.includes('{{ $skKey }}')" class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7"></path></svg>
                                            </span>
                                            <span>{{ $skLabel }}</span>
                                        </button>
                                    @endforeach
                                </div>
                                <template x-for="sk in skills" :key="sk">
                                    <input type="hidden" name="clinical_skills[]" :value="sk">
                                </template>
                            </div>
                        </div>

                        <!-- ==================== STEP 3: Zones, Schedule & Car ==================== -->
                        <div x-show="step === 3" x-cloak style="display: none;" class="space-y-4">
                            <h3 class="text-sm font-black text-[var(--ink)]">{{ __('delivery.step3_title') }}</h3>

                            <div>
                                <label class="label">{{ __('delivery.service_areas_label') }}</label>
                                <input type="text" name="service_areas" value="{{ old('service_areas') }}"
                                       placeholder="{{ __('delivery.service_areas_placeholder') }}" class="field-box">
                            </div>

                            <div>
                                <label class="label">{{ __('delivery.shift_label') }}</label>
                                <div class="grid grid-cols-1 sm:grid-cols-3 gap-2">
                                    @foreach($shiftOpts as $shKey => $shLabel)
                                        <button type="button" @click="shift = '{{ $shKey }}'"
                                                :class="shift === '{{ $shKey }}' ? 'is-on' : ''"
                                                class="opt-pill !text-[11.5px] !py-2.5">
                                            {{ $shLabel }}
                                        </button>
                                    @endforeach
                                </div>
                            </div>

                            <div>
                                <label class="label">{{ __('delivery.work_days_label') }}</label>
                                <div class="grid grid-cols-1 sm:grid-cols-3 gap-2">
                                    @foreach($workDaysOpts as $wdKey => $wdLabel)
                                        <button type="button" @click="workDays = '{{ $wdKey }}'"
                                                :class="workDays === '{{ $wdKey }}' ? 'is-on' : ''"
                                                class="opt-pill !text-[11.5px] !py-2.5">
                                            {{ $wdLabel }}
                                        </button>
                                    @endforeach
                                </div>
                            </div>

                            <!-- Simple Yes/No Private Car Question (No bike/motorcycle icons for clinical roles!) -->
                            <div>
                                <label class="label">{{ __('delivery.has_car_label') }}</label>
                                <div class="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
                                    <button type="button" @click="hasPrivateCar = '1'" :class="hasPrivateCar === '1' ? 'is-on' : ''" class="opt-pill">
                                        {{ __('delivery.yes_have_car') }}
                                    </button>
                                    <button type="button" @click="hasPrivateCar = '0'" :class="hasPrivateCar === '0' ? 'is-on' : ''" class="opt-pill">
                                        {{ __('delivery.no_need_car') }}
                                    </button>
                                </div>
                            </div>

                            <!-- Vehicle & Scope pickers shown ONLY when courier track is selected -->
                            <div x-show="applicantRole === 'courier'" class="space-y-4 pt-1 border-t border-dashed border-[var(--line)]">
                                <div>
                                    <label class="label">{{ __('delivery.vehicle_type') }}</label>
                                    <div class="grid grid-cols-3 gap-2">
                                        @foreach(['car', 'motorcycle', 'refrigerated_van'] as $vKey)
                                            <button type="button" @click="vehicle = '{{ $vKey }}'"
                                                    :class="vehicle === '{{ $vKey }}' ? 'is-on' : ''"
                                                    class="opt-pill !text-[11.5px]">
                                                {{ __("delivery.vehicle_short_{$vKey}") }}
                                            </button>
                                        @endforeach
                                    </div>
                                </div>

                                <div>
                                    <label class="label">{{ __('delivery.service_scope') }}</label>
                                    <div class="grid grid-cols-3 gap-2">
                                        @foreach(['pharmacy', 'both', 'lab_sample'] as $scKey)
                                            <button type="button" @click="scope = '{{ $scKey }}'"
                                                    :class="scope === '{{ $scKey }}' ? 'is-on' : ''"
                                                    class="opt-pill !text-[11.5px]">
                                                {{ __("delivery.scope_short_{$scKey}") }}
                                            </button>
                                        @endforeach
                                    </div>
                                </div>
                            </div>

                            <div>
                                <label class="label">{{ __('delivery.willing_travel_label') }}</label>
                                <div class="grid grid-cols-2 gap-2.5">
                                    <button type="button" @click="willingToTravel = '1'" :class="willingToTravel === '1' ? 'is-on' : ''" class="opt-pill">
                                        {{ __('delivery.yes_label') }}
                                    </button>
                                    <button type="button" @click="willingToTravel = '0'" :class="willingToTravel === '0' ? 'is-on' : ''" class="opt-pill">
                                        {{ __('delivery.no_label') }}
                                    </button>
                                </div>
                            </div>

                            <div x-show="hasPrivateCar === '1' || applicantRole === 'courier'">
                                <label class="label">{{ __('delivery.plate_number') }}</label>
                                <input type="text" name="plate_number" value="{{ old('plate_number') }}"
                                       placeholder="{{ __('delivery.plate_placeholder') }}" class="field-box">
                            </div>
                        </div>

                        <!-- ==================== STEP 4: Document Uploads & Submit ==================== -->
                        <div x-show="step === 4" x-cloak style="display: none;" class="space-y-4">
                            <div class="p-3.5 rounded-xl bg-[#FAF5ED] border border-[var(--line)]">
                                <h3 class="text-sm font-black text-[var(--ink)]">{{ __('delivery.step4_title') }}</h3>
                                <p class="text-xs text-[var(--muted)] mt-1 leading-[1.7]">{{ __('delivery.step4_desc') }}</p>
                            </div>

                            <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                                @foreach([
                                    'id_document' => __('delivery.doc_id'),
                                    'certificate' => __('delivery.doc_certificate'),
                                    'license' => __('delivery.doc_license'),
                                    'cv' => __('delivery.doc_cv'),
                                ] as $docField => $docLabel)
                                    <label class="block p-3.5 rounded-xl border-[1.5px] border-dashed border-[#B9AE9E] bg-white hover:border-[var(--ink)] cursor-pointer transition">
                                        <span class="block text-xs font-extrabold text-[var(--ink)] leading-[1.5]">{{ $docLabel }}</span>
                                        <span class="mt-2 inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-[#FFF3EB] text-[var(--accent-deep)] text-[11px] font-extrabold">
                                            <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12"></path></svg>
                                            <span x-text="files['{{ $docField }}'] ? files['{{ $docField }}'] : @js(__('delivery.file_choose'))"></span>
                                        </span>
                                        <input type="file" name="{{ $docField }}" accept=".jpg,.jpeg,.png,.pdf"
                                               @change="onFileChange('{{ $docField }}', $event)" class="sr-only">
                                    </label>
                                @endforeach
                            </div>

                            <label class="flex items-start gap-3 p-3.5 rounded-xl border-[1.5px] border-[#C8BEB0] bg-white cursor-pointer">
                                <input type="checkbox" name="agree_terms" value="1" x-model="agreed"
                                       class="mt-1 w-4 h-4 rounded accent-[#FF5A00] flex-shrink-0">
                                <span class="text-xs font-bold text-[var(--ink)] leading-[1.75]">
                                    {{ __('delivery.agree_terms_label') }}
                                </span>
                            </label>

                            <p class="text-[11.5px] text-[var(--muted)] leading-[1.7]">
                                {{ __('delivery.step_note') }}
                            </p>
                        </div>

                        <!-- Navigation Controls -->
                        <div class="pt-3 flex items-center gap-3">
                            <button type="button" x-show="step > 1" @click="prevStep()" class="btn-secondary">
                                {{ __('delivery.btn_prev') }}
                            </button>

                            <button type="button" x-show="step < 4" @click="nextStep()" class="btn-main flex-1">
                                <span>{{ __('delivery.btn_next') }}</span>
                            </button>

                            <button type="submit" x-show="step === 4" x-cloak style="display: none;" :disabled="submitting" class="btn-main flex-1">
                                <span x-show="!submitting">{{ __('delivery.submit_btn') }}</span>
                                <span x-show="submitting" style="display: none;">{{ __('delivery.submitting') }}</span>
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </main>

    <!-- Role Comparison Section -->
    <section class="rule-dash">
        <div class="w-full px-5 sm:px-8 lg:px-14 2xl:px-20 py-14 sm:py-18 text-start">
            <div class="max-w-2xl mb-10 space-y-2.5">
                <span class="kicker">{{ __('delivery.compare_badge') }}</span>
                <h2 class="text-2xl sm:text-3xl font-black text-[var(--ink)] leading-[1.45]">{{ __('delivery.compare_title') }}</h2>
                <p class="text-sm text-[var(--muted)] leading-[1.85]">{{ __('delivery.compare_sub') }}</p>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
                @foreach([
                    ['tag' => __('delivery.compare_phleb_tag'), 'title' => __('delivery.compare_phleb_title'), 'points' => __('delivery.compare_phleb_points'), 'highlight' => true],
                    ['tag' => __('delivery.compare_nurse_tag'), 'title' => __('delivery.compare_nurse_title'), 'points' => __('delivery.compare_nurse_points'), 'highlight' => false],
                    ['tag' => __('delivery.compare_courier_tag'), 'title' => __('delivery.compare_courier_title'), 'points' => __('delivery.compare_courier_points'), 'highlight' => false],
                ] as $track)
                    <div class="card p-6 space-y-4 {{ $track['highlight'] ? '!bg-[#FFF9F4] !border-[#FFD7BE]' : '' }}">
                        <span class="inline-block px-3 py-1 rounded-full bg-[#FFF2E8] text-[var(--accent-deep)] text-[11px] font-extrabold">
                            {{ $track['tag'] }}
                        </span>
                        <h3 class="text-lg font-black text-[var(--ink)] leading-[1.6]">{{ $track['title'] }}</h3>
                        <ul class="space-y-2.5">
                            @foreach((array) $track['points'] as $pt)
                                <li class="flex items-start gap-2.5 text-xs sm:text-[13px] text-[var(--muted)] leading-[1.8] font-medium">
                                    <span class="w-5 h-5 rounded-full bg-[var(--accent-soft)] text-[var(--accent-deep)] flex items-center justify-center flex-shrink-0 mt-0.5 font-black text-[11px]">✓</span>
                                    <span>{{ $pt }}</span>
                                </li>
                            @endforeach
                        </ul>
                    </div>
                @endforeach
            </div>
        </div>
    </section>

    <!-- 5-Step Real Workflow -->
    <section class="rule-dash">
        <div class="w-full px-5 sm:px-8 lg:px-14 2xl:px-20 py-14 sm:py-18 text-start">
            <div class="max-w-2xl mb-10 space-y-2.5">
                <span class="kicker">{{ __('delivery.how_badge') }}</span>
                <h2 class="text-2xl sm:text-3xl font-black text-[var(--ink)] leading-[1.6]">{{ __('delivery.how_title') }}</h2>
                <p class="text-sm text-[var(--muted)] leading-[1.9]">{{ __('delivery.how_sub') }}</p>
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
                @foreach((array) $wfSteps as $idx => $wf)
                    <div class="card p-5 space-y-3">
                        <span class="outline-num">{{ str_pad((string) ($idx + 1), 2, '0', STR_PAD_LEFT) }}</span>
                        <h3 class="text-sm font-black text-[var(--ink)] leading-[1.65]">{{ $wf['t'] ?? '' }}</h3>
                        <p class="text-xs text-[var(--muted)] leading-[1.85]">{{ $wf['d'] ?? '' }}</p>
                    </div>
                @endforeach
            </div>
        </div>
    </section>

    <!-- Trust & Verification Band -->
    <section class="w-full px-5 sm:px-8 lg:px-14 2xl:px-20 pb-14">
        <div class="rounded-[26px] bg-[#1F1C18] text-white p-7 sm:p-10 grid grid-cols-1 lg:grid-cols-12 gap-8 items-center text-start">
            <div class="lg:col-span-7 space-y-3">
                <span class="inline-block px-3 py-1 rounded-full bg-[var(--accent)] text-white text-[11px] font-extrabold">
                    {{ __('delivery.trust_badge') }}
                </span>
                <h2 class="text-2xl sm:text-3xl font-black leading-[1.65]">{{ __('delivery.trust_title') }}</h2>
                <p class="text-sm text-[#D7CEC2] leading-[1.95] max-w-2xl">{{ __('delivery.trust_desc') }}</p>
            </div>
            <div class="lg:col-span-5 space-y-3">
                @foreach((array) __('delivery.trust_points') as $tp)
                    <div class="flex items-start gap-3 p-3.5 rounded-2xl bg-white/10">
                        <span class="w-6 h-6 rounded-full bg-[var(--accent)] text-white flex items-center justify-center flex-shrink-0 text-xs font-black">✓</span>
                        <span class="text-xs sm:text-[13px] font-bold leading-[1.75] text-white">{{ $tp }}</span>
                    </div>
                @endforeach
            </div>
        </div>
    </section>

    <!-- 6-Item Interactive FAQ Accordion -->
    <section class="rule-dash">
        <div class="w-full px-5 sm:px-8 lg:px-14 2xl:px-20 py-14 sm:py-18 text-start">
            <div class="max-w-3xl mx-auto">
                <div class="mb-8 space-y-2.5 text-center">
                    <span class="kicker">{{ __('delivery.faq_badge') }}</span>
                    <h2 class="text-2xl sm:text-3xl font-black text-[var(--ink)] leading-[1.6]">{{ __('delivery.faq_title') }}</h2>
                </div>

                <div class="space-y-3">
                    @foreach((array) $faqs as $fIdx => $fq)
                        <div class="card overflow-hidden">
                            <button type="button"
                                    @click="openFaq = openFaq === {{ $fIdx }} ? -1 : {{ $fIdx }}"
                                    class="w-full px-5 py-4 flex items-center justify-between gap-4 text-start font-extrabold text-sm text-[var(--ink)] leading-[1.65]">
                                <span>{{ $fq['q'] ?? '' }}</span>
                                <span class="w-7 h-7 rounded-full bg-[#F5EFE6] text-[var(--accent-deep)] flex items-center justify-center flex-shrink-0 text-base leading-none font-black"
                                      x-text="openFaq === {{ $fIdx }} ? '−' : '+'"></span>
                            </button>
                            <div x-show="openFaq === {{ $fIdx }}" x-collapse style="display: none;"
                                 class="px-5 pb-4 pt-2 text-xs sm:text-[13px] text-[var(--muted)] leading-[1.95] border-t border-[#EFE8DC]">
                                {{ $fq['a'] ?? '' }}
                            </div>
                        </div>
                    @endforeach
                </div>
            </div>
        </div>
    </section>

    <!-- Complete Footer -->
    <footer class="border-t border-[#E6DDD0] bg-[var(--surface)] text-start">
        <div class="w-full px-5 sm:px-8 lg:px-14 2xl:px-20 py-10 grid grid-cols-1 md:grid-cols-12 gap-8">
            <div class="md:col-span-5 space-y-3">
                <div class="flex items-center gap-2.5">
                    <img src="{{ asset('images/logo.png') }}" alt="DrRoom" class="w-9 h-9 rounded-xl border border-[#E6DDD0] p-1 object-contain">
                    <span class="text-lg font-black" dir="ltr">Dr<span class="text-[var(--accent)]">Room</span></span>
                </div>
                <p class="text-xs text-[var(--muted)] leading-[1.9] max-w-md">{{ __('delivery.footer_brand_desc') }}</p>
            </div>

            <div class="md:col-span-3 space-y-2.5">
                <h4 class="text-xs font-black uppercase tracking-wide text-[var(--ink)]">{{ __('delivery.footer_col_links') }}</h4>
                <ul class="space-y-2 text-xs font-bold text-[var(--muted)]">
                    <li><a href="{{ $mainSiteHref }}" class="hover:text-[var(--accent-deep)]">{{ __('delivery.nav_home') }}</a></li>
                    <li><a href="{{ route('staff.landing') }}" class="hover:text-[var(--accent-deep)]">{{ __('delivery.nav_staff') }}</a></li>
                    <li><a href="#apply-form" class="hover:text-[var(--accent-deep)]">{{ __('delivery.nav_join') }}</a></li>
                </ul>
            </div>

            <div class="md:col-span-4 space-y-2.5">
                <h4 class="text-xs font-black uppercase tracking-wide text-[var(--ink)]">{{ __('delivery.footer_col_contact') }}</h4>
                <p class="text-xs font-bold text-[var(--ink)]">{{ __('delivery.footer_support_hours') }}</p>
                <p class="text-[11.5px] text-[var(--muted)] leading-[1.85]">{{ __('delivery.footer_privacy_note') }}</p>
            </div>
        </div>
        <div class="border-t border-[#EFE8DC] px-5 sm:px-8 lg:px-14 2xl:px-20 py-5 text-center">
            <p class="text-xs font-bold text-[var(--muted)]">{{ __('delivery.footer_copy') }}</p>
        </div>
    </footer>

</body>
</html>
