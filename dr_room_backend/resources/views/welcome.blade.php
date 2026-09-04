<!DOCTYPE html>
<html lang="{{ app()->getLocale() }}" dir="{{ in_array(app()->getLocale(), ['ar', 'ckb']) ? 'rtl' : 'ltr' }}" class="scroll-smooth">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ __('landing.app_name') }} - {{ __('landing.subtitle') }}</title>
    
    <!-- Alpine.js for interactivity -->
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.13.3/dist/cdn.min.js"></script>
    
    <!-- Google Fonts: Noto Kufi Arabic for Kurdish/Arabic, Plus Jakarta Sans for English -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Noto+Kufi+Arabic:wght@300;400;500;600;700;800;900&family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    
    <!-- Tailwind CSS CDN for instant rendering -->
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    fontFamily: {
                        sans: ['Noto Kufi Arabic', 'Plus Jakarta Sans', 'sans-serif'],
                    },
                    colors: {
                        brand: {
                            50: '#eff6ff',
                            100: '#dbeafe',
                            200: '#bfdbfe',
                            500: '#3b82f6',
                            600: '#2563eb',
                            700: '#1d4ed8',
                            800: '#1e40af',
                            900: '#1e3a8a',
                            950: '#0f172a',
                        }
                    },
                    keyframes: {
                        float: {
                            '0%, 100%': { transform: 'translateY(0px)' },
                            '50%': { transform: 'translateY(-10px)' },
                        },
                        pulseGlow: {
                            '0%, 100%': { opacity: '0.4', transform: 'scale(1)' },
                            '50%': { opacity: '0.8', transform: 'scale(1.05)' },
                        }
                    },
                    animation: {
                        float: 'float 4s ease-in-out infinite',
                        'float-slow': 'float 6s ease-in-out infinite',
                        'pulse-glow': 'pulseGlow 5s ease-in-out infinite',
                    }
                }
            }
        }
    </script>
    
    <style>
        * {
            font-family: 'Noto Kufi Arabic', 'Plus Jakarta Sans', sans-serif;
        }
        .gradient-text {
            background: linear-gradient(135deg, #1d4ed8 0%, #2563eb 50%, #0ea5e9 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            display: inline-block;
            padding-bottom: 4px;
        }
        .hero-mesh {
            background-color: #ffffff;
            background-image: 
                radial-gradient(at 0% 0%, rgba(37, 99, 235, 0.09) 0px, transparent 50%),
                radial-gradient(at 100% 0%, rgba(56, 189, 248, 0.09) 0px, transparent 50%),
                radial-gradient(at 50% 100%, rgba(99, 102, 241, 0.05) 0px, transparent 50%);
        }
        .pattern-grid {
            background-image: radial-gradient(#cbd5e1 1.2px, transparent 1.2px);
            background-size: 24px 24px;
        }
        .glass-card {
            background: rgba(255, 255, 255, 0.85);
            backdrop-filter: blur(12px);
            -webkit-backdrop-filter: blur(12px);
        }
        .phone-frame {
            box-shadow: 0 25px 60px -15px rgba(15, 23, 42, 0.35), 0 0 0 1px rgba(255, 255, 255, 0.2);
        }
        .hide-scrollbar::-webkit-scrollbar {
            display: none;
        }
        .hide-scrollbar {
            -ms-overflow-style: none;
            scrollbar-width: none;
        }
    </style>
</head>
<body class="text-slate-800 antialiased bg-white selection:bg-blue-100 selection:text-blue-900 overflow-x-hidden">

    <!-- Header Navigation -->
    <nav class="fixed top-0 inset-x-0 bg-white/90 backdrop-blur-md z-50 border-b border-slate-200/70 shadow-xs transition-all duration-200" x-data="{ mobileMenuOpen: false }">
        <div class="max-w-7xl 2xl:max-w-[1440px] mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex justify-between items-center h-20 gap-3 xl:gap-6">
                
                <!-- Brand Logo (Compact & Modern) -->
                <a href="/" class="flex-shrink-0 flex items-center gap-3 group">
                    <div class="w-10 h-10 rounded-2xl bg-gradient-to-tr from-blue-600 to-sky-500 flex items-center justify-center text-white shadow-md shadow-blue-500/25 group-hover:scale-105 transition-transform duration-200">
                        <svg class="w-5 h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"></path>
                            <line x1="12" y1="9" x2="12" y2="15"></line>
                            <line x1="9" y1="12" x2="15" y2="12"></line>
                        </svg>
                    </div>
                    <div class="flex flex-col">
                        <span class="text-xl font-black text-slate-900 tracking-tight leading-none">Dr<span class="text-blue-600">Room</span></span>
                        <span class="text-[10px] text-slate-400 font-semibold mt-1 leading-none hidden sm:block">{{ __('landing.subtitle') }}</span>
                    </div>
                </a>

                <!-- Desktop Menu (Center floating pill bar, perfectly proportioned, no stretching) -->
                <div class="hidden xl:flex items-center gap-1 bg-slate-100/80 p-1.5 rounded-full border border-slate-200/60 shadow-xs">
                    <a href="#" class="text-blue-600 bg-white font-bold px-3.5 py-1.5 rounded-full shadow-xs text-xs transition whitespace-nowrap">{{ __('landing.home') }}</a>
                    <a href="#services" class="text-slate-600 hover:text-blue-600 hover:bg-white/60 font-semibold px-3 py-1.5 rounded-full text-xs transition whitespace-nowrap">{{ __('landing.services') }}</a>
                    <a href="#app-screens" class="text-slate-600 hover:text-blue-600 hover:bg-white/60 font-semibold px-3 py-1.5 rounded-full text-xs transition whitespace-nowrap">{{ __('landing.features') }}</a>
                    <a href="#why-us" class="text-slate-600 hover:text-blue-600 hover:bg-white/60 font-semibold px-3 py-1.5 rounded-full text-xs transition whitespace-nowrap">{{ __('landing.about_tag') }}</a>
                    <a href="#how-it-works" class="text-slate-600 hover:text-blue-600 hover:bg-white/60 font-semibold px-3 py-1.5 rounded-full text-xs transition whitespace-nowrap">{{ __('landing.how_it_works') }}</a>
                    <a href="#faq" class="text-slate-600 hover:text-blue-600 hover:bg-white/60 font-semibold px-3 py-1.5 rounded-full text-xs transition whitespace-nowrap">{{ __('landing.faq') }}</a>
                </div>

                <!-- Right Actions (Language & Staff Portal & Download) -->
                <div class="hidden sm:flex items-center gap-2 lg:gap-3 flex-shrink-0">
                    <!-- Staff Portal Link -->
                    <a href="/staff" class="inline-flex items-center gap-1.5 text-slate-700 hover:text-blue-600 font-bold text-xs px-3.5 py-2 rounded-xl bg-slate-50 hover:bg-blue-50 border border-slate-200/70 hover:border-blue-200 transition shadow-xs whitespace-nowrap group">
                        <span class="w-2 h-2 rounded-full bg-emerald-500 group-hover:scale-110 transition-transform"></span>
                        <span>{{ __('landing.staff_short') }}</span>
                        <svg class="w-3.5 h-3.5 text-slate-400 group-hover:text-blue-600 transition-colors" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"></path></svg>
                    </a>

                    <!-- Language Switcher -->
                    <div class="relative" x-data="{ langOpen: false }">
                        <button @click="langOpen = !langOpen" @click.away="langOpen = false" class="flex items-center gap-1.5 px-3 py-2 rounded-xl bg-slate-50 hover:bg-slate-100 text-slate-700 font-bold text-xs transition border border-slate-200/70 focus:outline-none">
                            <svg class="w-4 h-4 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5h12M9 3v2m1.048 9.5A18.022 18.022 0 016.412 9m6.088 9h7M11 21l5-10 5 10M12.751 5C11.783 10.77 8.07 15.61 3 18.129"></path></svg>
                            <span>{{ strtoupper(app()->getLocale() == "ckb" ? "KU" : app()->getLocale()) }}</span>
                            <svg class="w-3.5 h-3.5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
                        </button>
                        
                        <div x-show="langOpen" x-transition class="absolute end-0 mt-2 w-36 bg-white rounded-2xl shadow-xl border border-slate-100 py-1.5 z-50" style="display: none;">
                            <a href="/ckb" class="flex items-center justify-between px-4 py-2 text-xs font-bold {{ app()->getLocale() == 'ckb' ? 'text-blue-600 bg-blue-50/70' : 'text-slate-700 hover:bg-slate-50' }} transition">
                                <span>کوردی (Kurdish)</span>
                                @if(app()->getLocale() == 'ckb') <span class="w-1.5 h-1.5 rounded-full bg-blue-600"></span> @endif
                            </a>
                            <a href="/en" class="flex items-center justify-between px-4 py-2 text-xs font-bold {{ app()->getLocale() == 'en' ? 'text-blue-600 bg-blue-50/70' : 'text-slate-700 hover:bg-slate-50' }} transition">
                                <span>English</span>
                                @if(app()->getLocale() == 'en') <span class="w-1.5 h-1.5 rounded-full bg-blue-600"></span> @endif
                            </a>
                            <a href="/ar" class="flex items-center justify-between px-4 py-2 text-xs font-bold {{ app()->getLocale() == 'ar' ? 'text-blue-600 bg-blue-50/70' : 'text-slate-700 hover:bg-slate-50' }} transition">
                                <span>العربية (Arabic)</span>
                                @if(app()->getLocale() == 'ar') <span class="w-1.5 h-1.5 rounded-full bg-blue-600"></span> @endif
                            </a>
                        </div>
                    </div>

                    <!-- Download Button -->
                    <a href="#download" class="bg-gradient-to-r from-blue-600 to-sky-600 hover:from-blue-700 hover:to-sky-700 text-white px-4 py-2.5 rounded-xl font-bold text-xs transition shadow-md shadow-blue-500/20 flex items-center gap-2 whitespace-nowrap hover:scale-[1.02] active:scale-[0.98]">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"></path></svg>
                        <span>{{ __('landing.download_app') }}</span>
                    </a>
                </div>

                <!-- Mobile & Tablet Menu Button -->
                <div class="xl:hidden flex items-center gap-2">
                    <a href="/staff" class="text-xs font-bold text-blue-600 bg-blue-50 px-2.5 py-1.5 rounded-lg border border-blue-100 flex items-center gap-1.5">
                        <span class="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                        <span>ستاف</span>
                    </a>
                    <button @click="mobileMenuOpen = !mobileMenuOpen" class="w-10 h-10 rounded-xl bg-slate-50 border border-slate-200/60 flex items-center justify-center text-slate-700 hover:text-slate-900 focus:outline-none">
                        <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path x-show="!mobileMenuOpen" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
                            <path x-show="mobileMenuOpen" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                    </button>
                </div>
            </div>
        </div>

        <!-- Mobile Menu Drawer -->
        <div x-show="mobileMenuOpen" x-transition class="xl:hidden bg-white border-t border-slate-100 shadow-xl" style="display: none;">
            <div class="px-4 pt-3 pb-6 space-y-2">
                <a href="#" @click="mobileMenuOpen = false" class="block px-4 py-2.5 text-blue-600 font-bold bg-blue-50 rounded-xl text-sm">{{ __('landing.home') }}</a>
                <a href="#services" @click="mobileMenuOpen = false" class="block px-4 py-2.5 text-slate-700 hover:bg-slate-50 font-bold rounded-xl text-sm">{{ __('landing.services') }}</a>
                <a href="#app-screens" @click="mobileMenuOpen = false" class="block px-4 py-2.5 text-slate-700 hover:bg-slate-50 font-bold rounded-xl text-sm">{{ __('landing.features') }}</a>
                <a href="#why-us" @click="mobileMenuOpen = false" class="block px-4 py-2.5 text-slate-700 hover:bg-slate-50 font-bold rounded-xl text-sm">{{ __('landing.about_tag') }}</a>
                <a href="#how-it-works" @click="mobileMenuOpen = false" class="block px-4 py-2.5 text-slate-700 hover:bg-slate-50 font-bold rounded-xl text-sm">{{ __('landing.how_it_works') }}</a>
                <a href="#faq" @click="mobileMenuOpen = false" class="block px-4 py-2.5 text-slate-700 hover:bg-slate-50 font-bold rounded-xl text-sm">{{ __('landing.faq') }}</a>
                <a href="/staff" class="block px-4 py-2.5 text-blue-700 font-extrabold bg-blue-50/60 rounded-xl text-sm border border-blue-100 flex items-center justify-between">
                    <span>{{ __('landing.staff_portal') }}</span>
                    <span class="text-xs bg-blue-600 text-white px-2 py-0.5 rounded-md">چوونەژوورەوە</span>
                </a>
                
                <!-- Mobile Language Selector -->
                <div class="border-t border-slate-100 mt-4 pt-3">
                    <p class="px-2 text-[11px] font-bold text-slate-400 uppercase tracking-wider mb-2">{{ __('landing.language') }}</p>
                    <div class="grid grid-cols-3 gap-2">
                        <a href="/ckb" class="text-center py-2 rounded-xl text-xs font-bold {{ app()->getLocale() == 'ckb' ? 'bg-blue-600 text-white' : 'bg-slate-100 text-slate-700' }}">کوردی</a>
                        <a href="/en" class="text-center py-2 rounded-xl text-xs font-bold {{ app()->getLocale() == 'en' ? 'bg-blue-600 text-white' : 'bg-slate-100 text-slate-700' }}">English</a>
                        <a href="/ar" class="text-center py-2 rounded-xl text-xs font-bold {{ app()->getLocale() == 'ar' ? 'bg-blue-600 text-white' : 'bg-slate-100 text-slate-700' }}">العربية</a>
                    </div>
                </div>
            </div>
        </div>
    </nav>

    <!-- Hero Section -->
    <section class="pt-32 pb-16 md:pt-40 md:pb-28 hero-mesh overflow-hidden relative">
        <!-- Floating decorative blurs -->
        <div class="absolute top-20 start-10 w-80 h-80 bg-blue-400/15 rounded-full blur-3xl pointer-events-none animate-pulse-glow"></div>
        <div class="absolute top-40 end-10 w-96 h-96 bg-sky-400/15 rounded-full blur-3xl pointer-events-none animate-pulse-glow" style="animation-delay: 2s;"></div>

        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
            <div class="flex flex-col lg:flex-row items-center justify-between gap-12 lg:gap-16">
                
                <!-- Hero Left / Start Content -->
                <div class="w-full lg:w-1/2 flex flex-col items-center lg:items-start text-center lg:text-start">
                    
                    <!-- Headline with clean vertical spacing for Kurdish/Arabic script -->
                    <h1 class="text-3xl sm:text-4xl md:text-5xl lg:text-[46px] font-black text-slate-900 flex flex-col gap-2.5 sm:gap-3.5 mb-6 tracking-normal">
                        <span class="block leading-[1.3]">{{ __('landing.hero_title_1') }}</span>
                        <span class="block leading-[1.3]">
                            <span class="gradient-text">{{ __('landing.hero_title_2') }}</span>
                        </span>
                        <span class="block leading-[1.3]">{{ __('landing.hero_title_3') }}</span>
                    </h1>
                    
                    <!-- Description -->
                    <p class="text-base sm:text-lg text-slate-600 mb-8 max-w-xl leading-relaxed font-medium">
                        {{ __('landing.hero_desc') }}
                    </p>
                    
                    <!-- Action Download Buttons -->
                    <div class="flex flex-col sm:flex-row gap-3.5 w-full justify-center lg:justify-start max-w-md">
                        <!-- Google Play Button -->
                        <a href="#download" class="flex-1 bg-slate-950 hover:bg-black text-white px-5 py-3.5 rounded-2xl font-medium transition shadow-lg shadow-slate-950/20 flex items-center justify-center gap-3 group border border-slate-800">
                            <svg class="w-6 h-6 text-emerald-400 flex-shrink-0 group-hover:scale-110 transition-transform" fill="currentColor" viewBox="0 0 24 24"><path d="M3.609 1.814L13.792 12 3.61 22.186a2.023 2.023 0 01-.61-1.45V3.264c0-.56.22-1.07.609-1.45zm11.602 11.602L18.49 10.13a2.012 2.012 0 000-3.26l-3.279-3.286-4.526 4.526 4.526 4.526zm-9.336 9.336l9.336-9.336-3.818-3.818-9.845 9.845c.87.87 2.37.87 4.327 3.309zm9.336-18.672L5.875 3.416C3.918 5.855 2.418 5.855 1.548 6.725l9.845 9.845 3.818-3.818z"/></svg>
                            <div class="text-start leading-tight">
                                <div class="text-[10px] text-slate-400 font-normal">{{ __('landing.download_android') }}</div>
                                <div class="text-sm font-extrabold">{{ __('landing.android') }}</div>
                            </div>
                        </a>
                        
                        <!-- iOS App Store Button -->
                        <a href="#download" class="flex-1 bg-blue-600 hover:bg-blue-700 text-white px-5 py-3.5 rounded-2xl font-medium transition shadow-lg shadow-blue-600/30 flex items-center justify-center gap-3 group">
                            <svg class="w-6 h-6 flex-shrink-0 group-hover:scale-110 transition-transform" fill="currentColor" viewBox="0 0 24 24"><path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 6.37c.62-.75 1.04-1.8 1.01-2.85-.9.04-2.03.62-2.68 1.38-.58.67-.99 1.74-.96 2.81 1.01.08 2.01-.59 2.63-1.34z"/></svg>
                            <div class="text-start leading-tight">
                                <div class="text-[10px] text-blue-200 font-normal">{{ __('landing.download_ios') }}</div>
                                <div class="text-sm font-extrabold">{{ __('landing.ios') }}</div>
                            </div>
                        </a>
                    </div>
                </div>

                <!-- Hero Right / Dual Phone Showcase -->
                <div class="w-full lg:w-1/2 relative flex justify-center lg:justify-end min-h-[560px] sm:min-h-[620px] select-none">
                    
                    <!-- Floating Badge: AI Scanner Feature -->
                    <div class="absolute -top-3 start-2 sm:start-8 z-30 bg-white/95 backdrop-blur-md rounded-2xl p-3 shadow-xl border border-slate-100 flex items-center gap-3 animate-float">
                        <div class="w-10 h-10 rounded-xl bg-purple-100 text-purple-600 flex items-center justify-center text-lg font-bold">
                            🤖
                        </div>
                        <div>
                            <div class="text-[11px] font-extrabold text-slate-900">سکانەری زیرەکی دەرمان</div>
                            <div class="text-[10px] text-purple-600 font-bold">دروستی ٩٩.٤٪ بە کامێرا</div>
                        </div>
                    </div>

                    <!-- Floating Badge: Emergency SOS -->
                    <div class="absolute bottom-6 end-0 sm:end-6 z-30 bg-white/95 backdrop-blur-md rounded-2xl p-3 shadow-xl border border-rose-100 flex items-center gap-3 animate-float-slow">
                        <div class="w-10 h-10 rounded-xl bg-rose-100 text-rose-600 flex items-center justify-center text-lg font-bold">
                            🚨
                        </div>
                        <div>
                            <div class="text-[11px] font-extrabold text-slate-900">فریاکەوتنی ١٢٢ و SOS</div>
                            <div class="text-[10px] text-rose-600 font-bold">پەیوەندی بەپەلە بە نەخۆشخانە</div>
                        </div>
                    </div>

                    <!-- Back Phone: AI Medicine & Prescription Scanner -->
                    <div class="absolute end-4 sm:end-8 top-12 w-[240px] sm:w-[270px] h-[500px] sm:h-[550px] rounded-[3rem] shadow-2xl transform rotate-6 z-10 overflow-hidden border-[8px] border-slate-900 bg-slate-900 transition-transform duration-300 hover:rotate-3">
                        <div class="absolute top-2 left-1/2 -translate-x-1/2 w-20 h-4 bg-slate-900 rounded-full z-20"></div>
                        <img src="{{ asset('images/app_ai_scanner.png') }}" alt="DrRoom AI Scanner" class="w-full h-full object-cover rounded-[2.4rem]">
                    </div>

                    <!-- Front Phone: Main Home Screen -->
                    <div class="absolute start-4 sm:start-10 top-0 w-[250px] sm:w-[280px] h-[520px] sm:h-[570px] rounded-[3.2rem] phone-frame z-20 overflow-hidden border-[9px] border-slate-950 bg-slate-950 transition-transform duration-300 hover:-translate-y-2">
                        <div class="absolute top-2.5 left-1/2 -translate-x-1/2 w-24 h-4 bg-slate-950 rounded-full z-30 shadow-inner"></div>
                        <img src="{{ asset('images/app_home.png') }}" alt="DrRoom Home" class="w-full h-full object-cover rounded-[2.5rem]">
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- NEW INTERACTIVE SECTION: App Screens Showcase -->
    <section id="app-screens" class="py-24 bg-gradient-to-b from-slate-50 via-white to-slate-50 relative border-t border-slate-100 overflow-hidden" x-data="{ activeTab: 'home' }">
        <div class="absolute end-0 top-1/4 w-96 h-96 bg-blue-100/40 rounded-full blur-3xl pointer-events-none"></div>
        <div class="absolute start-0 bottom-1/4 w-96 h-96 bg-purple-100/40 rounded-full blur-3xl pointer-events-none"></div>

        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
            
            <div class="text-center max-w-3xl mx-auto mb-14">
                <span class="text-blue-600 font-extrabold text-xs uppercase tracking-wider bg-blue-50 px-4 py-1.5 rounded-full border border-blue-200/60">
                    {{ __('landing.app_showcase_tag') }}
                </span>
                <h2 class="text-2xl sm:text-3xl md:text-4xl lg:text-[40px] font-black text-slate-900 mt-4 mb-4 flex flex-col gap-2 items-center tracking-normal">
                    <span class="block leading-[1.3]">{{ __('landing.app_showcase_title') }}</span>
                    <span class="block leading-[1.3]">
                        <span class="gradient-text">{{ __('landing.app_showcase_title_2') }}</span>
                    </span>
                </h2>
                <p class="text-slate-600 text-base md:text-lg font-medium leading-relaxed">
                    {{ __('landing.app_showcase_desc') }}
                </p>
            </div>

            <!-- Tab Switcher Navigation -->
            <div class="flex flex-wrap justify-center gap-2 sm:gap-3 mb-16">
                <!-- Tab 1: Home & SOS -->
                <button @click="activeTab = 'home'" :class="activeTab === 'home' ? 'bg-blue-600 text-white shadow-lg shadow-blue-500/30 scale-105' : 'bg-white text-slate-700 hover:bg-slate-100 border border-slate-200/80'" class="px-5 py-3 rounded-2xl font-black text-xs sm:text-sm transition-all duration-200 flex items-center gap-2">
                    <span>🏠</span>
                    <span>{{ __('landing.screen_home_tab') }}</span>
                </button>

                <!-- Tab 2: AI Scanner -->
                <button @click="activeTab = 'ai'" :class="activeTab === 'ai' ? 'bg-purple-600 text-white shadow-lg shadow-purple-500/30 scale-105' : 'bg-white text-slate-700 hover:bg-slate-100 border border-slate-200/80'" class="px-5 py-3 rounded-2xl font-black text-xs sm:text-sm transition-all duration-200 flex items-center gap-2">
                    <span>🤖</span>
                    <span>{{ __('landing.screen_ai_tab') }}</span>
                </button>

                <!-- Tab 3: Labs -->
                <button @click="activeTab = 'labs'" :class="activeTab === 'labs' ? 'bg-emerald-600 text-white shadow-lg shadow-emerald-500/30 scale-105' : 'bg-white text-slate-700 hover:bg-slate-100 border border-slate-200/80'" class="px-5 py-3 rounded-2xl font-black text-xs sm:text-sm transition-all duration-200 flex items-center gap-2">
                    <span>🧪</span>
                    <span>{{ __('landing.screen_labs_tab') }}</span>
                </button>

                <!-- Tab 4: First Aid -->
                <button @click="activeTab = 'firstaid'" :class="activeTab === 'firstaid' ? 'bg-rose-600 text-white shadow-lg shadow-rose-500/30 scale-105' : 'bg-white text-slate-700 hover:bg-slate-100 border border-slate-200/80'" class="px-5 py-3 rounded-2xl font-black text-xs sm:text-sm transition-all duration-200 flex items-center gap-2">
                    <span>🚑</span>
                    <span>{{ __('landing.screen_firstaid_tab') }}</span>
                </button>
            </div>

            <!-- Tab Content Presentation -->
            <div class="bg-white rounded-[2.5rem] p-6 sm:p-10 lg:p-14 border border-slate-100 shadow-xl shadow-slate-200/50">
                
                <!-- CONTENT 1: Home & SOS Screen -->
                <div x-show="activeTab === 'home'" x-transition:enter="transition ease-out duration-300" x-transition:enter-start="opacity-0 translate-y-4" x-transition:enter-end="opacity-100 translate-y-0" class="flex flex-col lg:flex-row items-center gap-10 lg:gap-16">
                    <div class="w-full lg:w-1/2 flex justify-center">
                        <div class="w-[260px] sm:w-[290px] h-[530px] sm:h-[590px] rounded-[3.2rem] phone-frame border-[8px] border-slate-950 bg-slate-950 overflow-hidden relative group">
                            <div class="absolute top-2 left-1/2 -translate-x-1/2 w-24 h-4 bg-slate-950 rounded-full z-20"></div>
                            <img src="{{ asset('images/app_home.png') }}" alt="DrRoom App Home" class="w-full h-full object-cover rounded-[2.5rem] group-hover:scale-105 transition-transform duration-300">
                        </div>
                    </div>
                    <div class="w-full lg:w-1/2">
                        <div class="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-xl bg-blue-50 text-blue-700 text-xs font-black mb-4">
                            <span>🏠</span> {{ __('landing.screen_home_tab') }}
                        </div>
                        <h3 class="text-2xl sm:text-3xl font-black text-slate-900 mb-4 leading-[1.6]">
                            {{ __('landing.screen_home_title') }}
                        </h3>
                        <p class="text-slate-600 text-base leading-relaxed mb-8 font-medium">
                            {{ __('landing.screen_home_desc') }}
                        </p>
                        <div class="space-y-4">
                            <div class="flex items-center gap-3.5 p-3.5 rounded-2xl bg-slate-50 border border-slate-100">
                                <div class="w-9 h-9 rounded-xl bg-blue-100 text-blue-600 flex items-center justify-center font-bold flex-shrink-0">✓</div>
                                <span class="text-sm font-bold text-slate-800">{{ __('landing.screen_home_f1') }}</span>
                            </div>
                            <div class="flex items-center gap-3.5 p-3.5 rounded-2xl bg-rose-50 border border-rose-100">
                                <div class="w-9 h-9 rounded-xl bg-rose-100 text-rose-600 flex items-center justify-center font-bold flex-shrink-0">🚨</div>
                                <span class="text-sm font-bold text-rose-900">{{ __('landing.screen_home_f2') }}</span>
                            </div>
                            <div class="flex items-center gap-3.5 p-3.5 rounded-2xl bg-slate-50 border border-slate-100">
                                <div class="w-9 h-9 rounded-xl bg-blue-100 text-blue-600 flex items-center justify-center font-bold flex-shrink-0">✓</div>
                                <span class="text-sm font-bold text-slate-800">{{ __('landing.screen_home_f3') }}</span>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- CONTENT 2: AI Medicine Scanner Screen -->
                <div x-show="activeTab === 'ai'" x-transition:enter="transition ease-out duration-300" x-transition:enter-start="opacity-0 translate-y-4" x-transition:enter-end="opacity-100 translate-y-0" class="flex flex-col lg:flex-row items-center gap-10 lg:gap-16" style="display: none;">
                    <div class="w-full lg:w-1/2 flex justify-center">
                        <div class="w-[260px] sm:w-[290px] h-[530px] sm:h-[590px] rounded-[3.2rem] phone-frame border-[8px] border-purple-950 bg-purple-950 overflow-hidden relative group">
                            <div class="absolute top-2 left-1/2 -translate-x-1/2 w-24 h-4 bg-purple-950 rounded-full z-20"></div>
                            <img src="{{ asset('images/app_ai_scanner.png') }}" alt="DrRoom AI Scanner" class="w-full h-full object-cover rounded-[2.5rem] group-hover:scale-105 transition-transform duration-300">
                        </div>
                    </div>
                    <div class="w-full lg:w-1/2">
                        <div class="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-xl bg-purple-50 text-purple-700 text-xs font-black mb-4">
                            <span>🤖</span> {{ __('landing.screen_ai_tab') }}
                        </div>
                        <h3 class="text-2xl sm:text-3xl font-black text-slate-900 mb-4 leading-[1.6]">
                            {{ __('landing.screen_ai_title') }}
                        </h3>
                        <p class="text-slate-600 text-base leading-relaxed mb-8 font-medium">
                            {{ __('landing.screen_ai_desc') }}
                        </p>
                        <div class="space-y-4">
                            <div class="flex items-center gap-3.5 p-3.5 rounded-2xl bg-purple-50/70 border border-purple-100">
                                <div class="w-9 h-9 rounded-xl bg-purple-100 text-purple-600 flex items-center justify-center font-bold flex-shrink-0">📷</div>
                                <span class="text-sm font-bold text-purple-950">{{ __('landing.screen_ai_f1') }}</span>
                            </div>
                            <div class="flex items-center gap-3.5 p-3.5 rounded-2xl bg-slate-50 border border-slate-100">
                                <div class="w-9 h-9 rounded-xl bg-blue-100 text-blue-600 flex items-center justify-center font-bold flex-shrink-0">✓</div>
                                <span class="text-sm font-bold text-slate-800">{{ __('landing.screen_ai_f2') }}</span>
                            </div>
                            <div class="flex items-center gap-3.5 p-3.5 rounded-2xl bg-slate-50 border border-slate-100">
                                <div class="w-9 h-9 rounded-xl bg-blue-100 text-blue-600 flex items-center justify-center font-bold flex-shrink-0">✓</div>
                                <span class="text-sm font-bold text-slate-800">{{ __('landing.screen_ai_f3') }}</span>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- CONTENT 3: Medical Laboratories Screen -->
                <div x-show="activeTab === 'labs'" x-transition:enter="transition ease-out duration-300" x-transition:enter-start="opacity-0 translate-y-4" x-transition:enter-end="opacity-100 translate-y-0" class="flex flex-col lg:flex-row items-center gap-10 lg:gap-16" style="display: none;">
                    <div class="w-full lg:w-1/2 flex justify-center">
                        <div class="w-[260px] sm:w-[290px] h-[530px] sm:h-[590px] rounded-[3.2rem] phone-frame border-[8px] border-emerald-950 bg-emerald-950 overflow-hidden relative group">
                            <div class="absolute top-2 left-1/2 -translate-x-1/2 w-24 h-4 bg-emerald-950 rounded-full z-20"></div>
                            <img src="{{ asset('images/app_labs.png') }}" alt="DrRoom Medical Labs" class="w-full h-full object-cover rounded-[2.5rem] group-hover:scale-105 transition-transform duration-300">
                        </div>
                    </div>
                    <div class="w-full lg:w-1/2">
                        <div class="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-xl bg-emerald-50 text-emerald-700 text-xs font-black mb-4">
                            <span>🧪</span> {{ __('landing.screen_labs_tab') }}
                        </div>
                        <h3 class="text-2xl sm:text-3xl font-black text-slate-900 mb-4 leading-[1.6]">
                            {{ __('landing.screen_labs_title') }}
                        </h3>
                        <p class="text-slate-600 text-base leading-relaxed mb-8 font-medium">
                            {{ __('landing.screen_labs_desc') }}
                        </p>
                        <div class="space-y-4">
                            <div class="flex items-center gap-3.5 p-3.5 rounded-2xl bg-emerald-50/70 border border-emerald-100">
                                <div class="w-9 h-9 rounded-xl bg-emerald-100 text-emerald-600 flex items-center justify-center font-bold flex-shrink-0">★</div>
                                <span class="text-sm font-bold text-emerald-950">{{ __('landing.screen_labs_f1') }}</span>
                            </div>
                            <div class="flex items-center gap-3.5 p-3.5 rounded-2xl bg-amber-50 border border-amber-100">
                                <div class="w-9 h-9 rounded-xl bg-amber-100 text-amber-600 flex items-center justify-center font-bold flex-shrink-0">%</div>
                                <span class="text-sm font-bold text-amber-950">{{ __('landing.screen_labs_f2') }}</span>
                            </div>
                            <div class="flex items-center gap-3.5 p-3.5 rounded-2xl bg-slate-50 border border-slate-100">
                                <div class="w-9 h-9 rounded-xl bg-blue-100 text-blue-600 flex items-center justify-center font-bold flex-shrink-0">✓</div>
                                <span class="text-sm font-bold text-slate-800">{{ __('landing.screen_labs_f3') }}</span>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- CONTENT 4: First Aid Screen -->
                <div x-show="activeTab === 'firstaid'" x-transition:enter="transition ease-out duration-300" x-transition:enter-start="opacity-0 translate-y-4" x-transition:enter-end="opacity-100 translate-y-0" class="flex flex-col lg:flex-row items-center gap-10 lg:gap-16" style="display: none;">
                    <div class="w-full lg:w-1/2 flex justify-center">
                        <div class="w-[260px] sm:w-[290px] h-[530px] sm:h-[590px] rounded-[3.2rem] phone-frame border-[8px] border-rose-950 bg-rose-950 overflow-hidden relative group">
                            <div class="absolute top-2 left-1/2 -translate-x-1/2 w-24 h-4 bg-rose-950 rounded-full z-20"></div>
                            <img src="{{ asset('images/app_first_aid.png') }}" alt="DrRoom First Aid Guide" class="w-full h-full object-cover rounded-[2.5rem] group-hover:scale-105 transition-transform duration-300">
                        </div>
                    </div>
                    <div class="w-full lg:w-1/2">
                        <div class="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-xl bg-rose-50 text-rose-700 text-xs font-black mb-4">
                            <span>🚑</span> {{ __('landing.screen_firstaid_tab') }}
                        </div>
                        <h3 class="text-2xl sm:text-3xl font-black text-slate-900 mb-4 leading-[1.6]">
                            {{ __('landing.screen_firstaid_title') }}
                        </h3>
                        <p class="text-slate-600 text-base leading-relaxed mb-8 font-medium">
                            {{ __('landing.screen_firstaid_desc') }}
                        </p>
                        <div class="space-y-4">
                            <div class="flex items-center gap-3.5 p-3.5 rounded-2xl bg-rose-50/70 border border-rose-100">
                                <div class="w-9 h-9 rounded-xl bg-rose-100 text-rose-600 flex items-center justify-center font-bold flex-shrink-0">🫀</div>
                                <span class="text-sm font-bold text-rose-950">{{ __('landing.screen_firstaid_f1') }}</span>
                            </div>
                            <div class="flex items-center gap-3.5 p-3.5 rounded-2xl bg-slate-50 border border-slate-100">
                                <div class="w-9 h-9 rounded-xl bg-blue-100 text-blue-600 flex items-center justify-center font-bold flex-shrink-0">🔥</div>
                                <span class="text-sm font-bold text-slate-800">{{ __('landing.screen_firstaid_f2') }}</span>
                            </div>
                            <div class="flex items-center gap-3.5 p-3.5 rounded-2xl bg-slate-50 border border-slate-100">
                                <div class="w-9 h-9 rounded-xl bg-blue-100 text-blue-600 flex items-center justify-center font-bold flex-shrink-0">✓</div>
                                <span class="text-sm font-bold text-slate-800">{{ __('landing.screen_firstaid_f3') }}</span>
                            </div>
                        </div>
                    </div>
                </div>

            </div>
        </div>
    </section>

    <!-- Core Services Section -->
    <section id="services" class="py-24 bg-white relative">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
            
            <div class="text-center max-w-3xl mx-auto mb-16">
                <span class="text-blue-600 font-extrabold text-xs uppercase tracking-wider bg-blue-50 px-3.5 py-1.5 rounded-full border border-blue-200/60">{{ __('landing.our_services') }}</span>
                <h2 class="text-3xl md:text-4xl font-black text-slate-900 mt-4 mb-4 tracking-tight">{{ __('landing.our_services') }}</h2>
                <p class="text-slate-600 text-base md:text-lg font-medium">{{ __('landing.services_desc') }}</p>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
                
                <!-- Service 1: Lab Tests -->
                <div class="bg-slate-50/70 hover:bg-white rounded-3xl p-8 shadow-sm hover:shadow-xl hover:-translate-y-1.5 transition-all duration-300 border border-slate-100 flex flex-col justify-between group">
                    <div>
                        <div class="w-16 h-16 rounded-2xl bg-emerald-100/70 text-emerald-600 flex items-center justify-center text-3xl mb-6 shadow-sm group-hover:scale-110 transition-transform">
                            🧪
                        </div>
                        <h3 class="text-xl font-black text-slate-900 mb-3">{{ __('landing.lab_tests') }}</h3>
                        <p class="text-slate-600 text-sm leading-relaxed mb-6">{{ __('landing.lab_desc') }}</p>
                    </div>
                    <div class="pt-4 border-t border-slate-200/60 flex items-center justify-between">
                        <span class="bg-emerald-50 text-emerald-700 text-xs font-extrabold px-3 py-1 rounded-lg">{{ __('landing.available_home') }}</span>
                        <span class="text-xs font-bold text-slate-400">PDF ئەنجام</span>
                    </div>
                </div>
                
                <!-- Service 2: Home Nursing -->
                <div class="bg-white rounded-3xl p-8 shadow-md hover:shadow-xl hover:-translate-y-1.5 transition-all duration-300 border-2 border-blue-200 flex flex-col justify-between group relative overflow-hidden">
                    <div class="absolute top-0 end-0 bg-blue-600 text-white text-[10px] font-black px-3 py-1 rounded-bl-xl uppercase tracking-wider">سەرەکی</div>
                    <div>
                        <div class="w-16 h-16 rounded-2xl bg-blue-100/70 text-blue-600 flex items-center justify-center text-3xl mb-6 shadow-sm group-hover:scale-110 transition-transform">
                            👩‍⚕️
                        </div>
                        <h3 class="text-xl font-black text-slate-900 mb-3">{{ __('landing.nursing') }}</h3>
                        <p class="text-slate-600 text-sm leading-relaxed mb-6">{{ __('landing.nursing_desc') }}</p>
                    </div>
                    <div class="pt-4 border-t border-slate-100 flex items-center justify-between">
                        <span class="bg-blue-50 text-blue-700 text-xs font-extrabold px-3 py-1 rounded-lg">{{ __('landing.fast_booking') }}</span>
                        <span class="text-xs font-bold text-slate-400">ستافی مۆڵەتپێدراو</span>
                    </div>
                </div>
                
                <!-- Service 3: AI Prescription Scanner -->
                <div class="bg-slate-50/70 hover:bg-white rounded-3xl p-8 shadow-sm hover:shadow-xl hover:-translate-y-1.5 transition-all duration-300 border border-slate-100 flex flex-col justify-between group">
                    <div>
                        <div class="w-16 h-16 rounded-2xl bg-purple-100/70 text-purple-600 flex items-center justify-center text-3xl mb-6 shadow-sm group-hover:scale-110 transition-transform">
                            🤖
                        </div>
                        <h3 class="text-xl font-black text-slate-900 mb-3">{{ __('landing.screen_ai_tab') }}</h3>
                        <p class="text-slate-600 text-sm leading-relaxed mb-6">{{ __('landing.screen_ai_desc') }}</p>
                    </div>
                    <div class="pt-4 border-t border-slate-200/60 flex items-center justify-between">
                        <span class="bg-purple-50 text-purple-700 text-xs font-extrabold px-3 py-1 rounded-lg">AI شیکاری بە دەستبەجێ</span>
                        <span class="text-xs font-bold text-purple-500">٩٩.٤٪ ڕێژەی دروستی</span>
                    </div>
                </div>
                
                <!-- Service 4: Pharmacy -->
                <div class="bg-slate-50/70 hover:bg-white rounded-3xl p-8 shadow-sm hover:shadow-xl hover:-translate-y-1.5 transition-all duration-300 border border-slate-100 flex flex-col justify-between group">
                    <div>
                        <div class="w-16 h-16 rounded-2xl bg-rose-100/70 text-rose-600 flex items-center justify-center text-3xl mb-6 shadow-sm group-hover:scale-110 transition-transform">
                            💊
                        </div>
                        <h3 class="text-xl font-black text-slate-900 mb-3">{{ __('landing.pharmacy') }}</h3>
                        <p class="text-slate-600 text-sm leading-relaxed mb-6">{{ __('landing.pharmacy_desc') }}</p>
                    </div>
                    <div class="pt-4 border-t border-slate-200/60 flex items-center justify-between">
                        <span class="bg-rose-50 text-rose-700 text-xs font-extrabold px-3 py-1 rounded-lg">{{ __('landing.instant_delivery') }}</span>
                        <span class="text-xs font-bold text-slate-400">بارکردنی ڕەچەتە</span>
                    </div>
                </div>
                
                <!-- Service 5: First Aid & Emergency Guide -->
                <div class="bg-slate-50/70 hover:bg-white rounded-3xl p-8 shadow-sm hover:shadow-xl hover:-translate-y-1.5 transition-all duration-300 border border-slate-100 flex flex-col justify-between group">
                    <div>
                        <div class="w-16 h-16 rounded-2xl bg-amber-100/70 text-amber-600 flex items-center justify-center text-3xl mb-6 shadow-sm group-hover:scale-110 transition-transform">
                            🚑
                        </div>
                        <h3 class="text-xl font-black text-slate-900 mb-3">{{ __('landing.screen_firstaid_tab') }}</h3>
                        <p class="text-slate-600 text-sm leading-relaxed mb-6">{{ __('landing.screen_firstaid_desc') }}</p>
                    </div>
                    <div class="pt-4 border-t border-slate-200/60 flex items-center justify-between">
                        <span class="bg-amber-50 text-amber-800 text-xs font-extrabold px-3 py-1 rounded-lg">ڕێبەری CPR و سووتان</span>
                        <span class="text-xs font-bold text-rose-500">SOS ١٢٢</span>
                    </div>
                </div>
                
                <!-- Service 6: Smart Records -->
                <div class="bg-slate-50/70 hover:bg-white rounded-3xl p-8 shadow-sm hover:shadow-xl hover:-translate-y-1.5 transition-all duration-300 border border-slate-100 flex flex-col justify-between group">
                    <div>
                        <div class="w-16 h-16 rounded-2xl bg-cyan-100/70 text-cyan-600 flex items-center justify-center text-3xl mb-6 shadow-sm group-hover:scale-110 transition-transform">
                            📁
                        </div>
                        <h3 class="text-xl font-black text-slate-900 mb-3">{{ __('landing.more_services') }}</h3>
                        <p class="text-slate-600 text-sm leading-relaxed mb-6">{{ __('landing.more_desc') }}</p>
                    </div>
                    <div class="pt-4 border-t border-slate-200/60 flex items-center justify-between">
                        <span class="bg-cyan-50 text-cyan-700 text-xs font-extrabold px-3 py-1 rounded-lg">پارێزراو بە تەواوی</span>
                        <span class="text-xs font-bold text-slate-400">مەلەفی دیجیتاڵی</span>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Why Choose Us Section -->
    <section id="why-us" class="py-24 bg-slate-50/70 relative overflow-hidden border-t border-slate-100">
        <div class="absolute start-0 top-1/3 w-64 h-64 pattern-grid opacity-30 -z-10"></div>
        
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex flex-col lg:flex-row items-center gap-14 lg:gap-20">
                
                <!-- Left: Phone mockup with First Aid & CPR Guides -->
                <div class="w-full lg:w-1/2 flex justify-center relative select-none">
                    <div class="w-[260px] sm:w-[290px] h-[530px] sm:h-[590px] bg-slate-950 rounded-[3.2rem] border-[9px] border-slate-950 phone-frame overflow-hidden relative z-10 flex flex-col justify-center items-center">
                        <!-- Dynamic Island -->
                        <div class="absolute top-2 w-24 h-4 bg-slate-950 rounded-full z-20"></div>
                        <img src="{{ asset('images/app_first_aid.png') }}" alt="DrRoom First Aid & CPR" class="w-full h-full object-cover rounded-[2.5rem]">
                    </div>
                </div>

                <!-- Right: Content & Trust Features -->
                <div class="w-full lg:w-1/2">
                    <div class="text-blue-600 font-extrabold tracking-wider text-xs mb-3 uppercase bg-blue-50 px-3.5 py-1.5 rounded-full inline-block border border-blue-200/60">{{ __('landing.about_tag') }}</div>
                    
                    <h2 class="text-3xl md:text-4xl font-black text-slate-900 mb-6 flex flex-col gap-2 tracking-tight">
                        <span class="block leading-[1.3]">{{ __('landing.quality_care') }}</span>
                        <span class="block leading-[1.3]">
                            <span class="gradient-text">{{ __('landing.can_trust') }}</span>
                        </span>
                    </h2>
                    
                    <p class="text-slate-600 text-base md:text-lg mb-8 leading-relaxed font-medium">
                        {{ __('landing.about_desc') }}
                    </p>

                    <div class="space-y-6">
                        <!-- Feature 1 -->
                        <div class="flex items-start gap-4">
                            <div class="flex-shrink-0 w-12 h-12 bg-blue-100/70 text-blue-600 rounded-2xl flex items-center justify-center shadow-sm">
                                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"></path></svg>
                            </div>
                            <div>
                                <h4 class="font-bold text-slate-900 text-base mb-1">{{ __('landing.verified_prof') }}</h4>
                                <p class="text-slate-500 text-sm leading-relaxed">{{ __('landing.verified_desc') }}</p>
                            </div>
                        </div>

                        <!-- Feature 2 -->
                        <div class="flex items-start gap-4">
                            <div class="flex-shrink-0 w-12 h-12 bg-emerald-100/70 text-emerald-600 rounded-2xl flex items-center justify-center shadow-sm">
                                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                            </div>
                            <div>
                                <h4 class="font-bold text-slate-900 text-base mb-1">{{ __('landing.fast_reliable') }}</h4>
                                <p class="text-slate-500 text-sm leading-relaxed">{{ __('landing.fast_desc') }}</p>
                            </div>
                        </div>

                        <!-- Feature 3 -->
                        <div class="flex items-start gap-4">
                            <div class="flex-shrink-0 w-12 h-12 bg-purple-100/70 text-purple-600 rounded-2xl flex items-center justify-center shadow-sm">
                                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path></svg>
                            </div>
                            <div>
                                <h4 class="font-bold text-slate-900 text-base mb-1">{{ __('landing.easy_booking') }}</h4>
                                <p class="text-slate-500 text-sm leading-relaxed">{{ __('landing.easy_desc') }}</p>
                            </div>
                        </div>

                        <!-- Feature 4 -->
                        <div class="flex items-start gap-4">
                            <div class="flex-shrink-0 w-12 h-12 bg-amber-100/70 text-amber-600 rounded-2xl flex items-center justify-center shadow-sm">
                                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"></path></svg>
                            </div>
                            <div>
                                <h4 class="font-bold text-slate-900 text-base mb-1">{{ __('landing.secure_pay') }}</h4>
                                <p class="text-slate-500 text-sm leading-relaxed">{{ __('landing.secure_desc') }}</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Staff & Healthcare Professionals Banner -->
    <section class="py-12 bg-gradient-to-r from-slate-950 via-blue-950 to-slate-950 text-white">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex flex-col lg:flex-row items-center justify-between gap-8 py-6">
                <div>
                    <span class="text-blue-400 font-extrabold text-xs uppercase tracking-wider bg-blue-500/10 px-3 py-1 rounded-full border border-blue-400/20">{{ __('landing.staff_banner_tag') }}</span>
                    <h3 class="text-2xl sm:text-3xl font-black mt-3 mb-2">{{ __('landing.staff_banner_title') }}</h3>
                    <p class="text-slate-300 text-sm sm:text-base max-w-2xl leading-relaxed">{{ __('landing.staff_banner_desc') }}</p>
                </div>
                <a href="/staff" class="bg-blue-600 hover:bg-blue-500 text-white font-extrabold text-sm px-8 py-4 rounded-2xl shadow-xl shadow-blue-600/30 transition transform hover:-translate-y-0.5 flex-shrink-0 flex items-center gap-2">
                    <span>{{ __('landing.staff_banner_btn') }}</span>
                    <svg class="w-4 h-4 rtl:rotate-180" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 5l7 7m0 0l-7 7m7-7H3"></path></svg>
                </a>
            </div>
        </div>
    </section>

    <!-- Stats and App Download Section -->
    <section id="download" class="py-20 bg-white">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="bg-gradient-to-br from-blue-600 via-blue-700 to-indigo-800 rounded-[2.5rem] overflow-hidden relative shadow-2xl shadow-blue-600/25">
                
                <div class="flex flex-col lg:flex-row">
                    <!-- Download CTA Side -->
                    <div class="w-full lg:w-3/5 p-8 sm:p-12 lg:p-16 flex flex-col justify-center">
                        <span class="text-blue-200 font-extrabold text-xs uppercase tracking-wider mb-2">دابەزاندنی ئەپ</span>
                        <h3 class="text-2xl sm:text-4xl font-black text-white mb-4 leading-[1.5]">{{ __('landing.download_drroom') }}</h3>
                        <p class="text-blue-100 text-base max-w-md mb-8 leading-relaxed font-medium">{{ __('landing.get_best_exp') }}</p>
                        
                        <div class="flex flex-wrap gap-3">
                            <button class="bg-black text-white px-6 py-3.5 rounded-2xl flex items-center gap-3 hover:bg-slate-900 transition shadow-lg">
                                <svg class="w-6 h-6 text-emerald-400 flex-shrink-0" fill="currentColor" viewBox="0 0 24 24"><path d="M3.609 1.814L13.792 12 3.61 22.186a2.023 2.023 0 01-.61-1.45V3.264c0-.56.22-1.07.609-1.45zm11.602 11.602L18.49 10.13a2.012 2.012 0 000-3.26l-3.279-3.286-4.526 4.526 4.526 4.526zm-9.336 9.336l9.336-9.336-3.818-3.818-9.845 9.845c.87.87 2.37.87 4.327 3.309zm9.336-18.672L5.875 3.416C3.918 5.855 2.418 5.855 1.548 6.725l9.845 9.845 3.818-3.818z"/></svg>
                                <div class="text-start leading-tight">
                                    <div class="text-[9px] text-slate-400 font-normal">{{ __('landing.get_on') }}</div>
                                    <div class="text-xs font-extrabold">{{ __('landing.google_play') }}</div>
                                </div>
                            </button>
                            
                            <button class="bg-black text-white px-6 py-3.5 rounded-2xl flex items-center gap-3 hover:bg-slate-900 transition shadow-lg">
                                <svg class="w-6 h-6 flex-shrink-0" fill="currentColor" viewBox="0 0 24 24"><path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 6.37c.62-.75 1.04-1.8 1.01-2.85-.9.04-2.03.62-2.68 1.38-.58.67-.99 1.74-.96 2.81 1.01.08 2.01-.59 2.63-1.34z"/></svg>
                                <div class="text-start leading-tight">
                                    <div class="text-[9px] text-slate-400 font-normal">{{ __('landing.download_on') }}</div>
                                    <div class="text-xs font-extrabold">{{ __('landing.app_store') }}</div>
                                </div>
                            </button>
                        </div>
                    </div>

                    <!-- App Visual Mockup Side -->
                    <div class="w-full lg:w-2/5 bg-blue-700/40 p-8 sm:p-12 relative overflow-hidden flex items-center justify-center">
                        <div class="w-60 sm:w-68 h-84 sm:h-96 rounded-t-[2.8rem] border-8 border-slate-900 shadow-2xl transform rotate-3 overflow-hidden bg-slate-900">
                            <img src="{{ asset('images/app_home.png') }}" alt="DrRoom App" class="w-full h-full object-cover">
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- How It Works Section -->
    <section id="how-it-works" class="py-24 bg-slate-50 relative border-t border-slate-100">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
            
            <div class="max-w-3xl mx-auto mb-16">
                <span class="text-blue-600 font-extrabold text-xs uppercase tracking-wider bg-blue-50 px-3.5 py-1.5 rounded-full border border-blue-200/60">{{ __('landing.how_works_title') }}</span>
                <h2 class="text-3xl md:text-4xl font-black text-slate-900 mt-4 mb-4 tracking-tight">{{ __('landing.how_works_title') }}</h2>
                <p class="text-slate-600 text-base md:text-lg font-medium">{{ __('landing.how_works_desc') }}</p>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-8 relative">
                
                <!-- Step 1 -->
                <div class="bg-white rounded-3xl p-8 border border-slate-100 shadow-sm relative z-10 flex flex-col items-center">
                    <div class="w-16 h-16 rounded-2xl bg-blue-50 text-blue-600 font-black text-2xl flex items-center justify-center mb-6 shadow-sm">1</div>
                    <h4 class="font-black text-slate-900 text-lg mb-3">{{ __('landing.step_1') }}</h4>
                    <p class="text-slate-500 text-sm leading-relaxed">{{ __('landing.step_1_desc') }}</p>
                </div>
                
                <!-- Step 2 -->
                <div class="bg-white rounded-3xl p-8 border border-slate-100 shadow-sm relative z-10 flex flex-col items-center">
                    <div class="w-16 h-16 rounded-2xl bg-blue-600 text-white font-black text-2xl flex items-center justify-center mb-6 shadow-lg shadow-blue-500/25">2</div>
                    <h4 class="font-black text-slate-900 text-lg mb-3">{{ __('landing.step_2') }}</h4>
                    <p class="text-slate-500 text-sm leading-relaxed">{{ __('landing.step_2_desc') }}</p>
                </div>
                
                <!-- Step 3 -->
                <div class="bg-white rounded-3xl p-8 border border-slate-100 shadow-sm relative z-10 flex flex-col items-center">
                    <div class="w-16 h-16 rounded-2xl bg-emerald-50 text-emerald-600 font-black text-2xl flex items-center justify-center mb-6 shadow-sm">3</div>
                    <h4 class="font-black text-slate-900 text-lg mb-3">{{ __('landing.step_3') }}</h4>
                    <p class="text-slate-500 text-sm leading-relaxed">{{ __('landing.step_3_desc') }}</p>
                </div>
            </div>
        </div>
    </section>



    <!-- FAQ Section -->
    <section id="faq" class="py-24 bg-slate-50 relative border-t border-slate-100">
        <div class="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="text-center mb-14">
                <span class="text-blue-600 font-extrabold text-xs uppercase tracking-wider bg-blue-50 px-3.5 py-1.5 rounded-full border border-blue-200/60">{{ __('landing.faq_title') }}</span>
                <h2 class="text-3xl md:text-4xl font-black text-slate-900 mt-4 mb-4 tracking-tight">{{ __('landing.faq_title') }}</h2>
                <p class="text-slate-600 text-base md:text-lg font-medium">{{ __('landing.faq_desc') }}</p>
            </div>
            
            <div class="space-y-4">
                <!-- FAQ Item 1 -->
                <div class="bg-white rounded-2xl p-6 shadow-sm border border-slate-100" x-data="{ expanded: true }">
                    <button @click="expanded = !expanded" class="flex justify-between items-center w-full text-start font-black text-slate-900 text-base focus:outline-none">
                        <span>{{ __('landing.faq_1_q') }}</span>
                        <svg class="w-5 h-5 text-blue-600 transform transition-transform" :class="{'rotate-180': expanded}" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" /></svg>
                    </button>
                    <p x-show="expanded" x-transition class="mt-4 text-slate-600 text-sm leading-relaxed border-t border-slate-50 pt-3">{{ __('landing.faq_1_a') }}</p>
                </div>

                <!-- FAQ Item 2 -->
                <div class="bg-white rounded-2xl p-6 shadow-sm border border-slate-100" x-data="{ expanded: false }">
                    <button @click="expanded = !expanded" class="flex justify-between items-center w-full text-start font-black text-slate-900 text-base focus:outline-none">
                        <span>{{ __('landing.faq_2_q') }}</span>
                        <svg class="w-5 h-5 text-blue-600 transform transition-transform" :class="{'rotate-180': expanded}" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" /></svg>
                    </button>
                    <p x-show="expanded" x-transition class="mt-4 text-slate-600 text-sm leading-relaxed border-t border-slate-50 pt-3" style="display: none;">{{ __('landing.faq_2_a') }}</p>
                </div>

                <!-- FAQ Item 3 -->
                <div class="bg-white rounded-2xl p-6 shadow-sm border border-slate-100" x-data="{ expanded: false }">
                    <button @click="expanded = !expanded" class="flex justify-between items-center w-full text-start font-black text-slate-900 text-base focus:outline-none">
                        <span>{{ __('landing.faq_3_q') }}</span>
                        <svg class="w-5 h-5 text-blue-600 transform transition-transform" :class="{'rotate-180': expanded}" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" /></svg>
                    </button>
                    <p x-show="expanded" x-transition class="mt-4 text-slate-600 text-sm leading-relaxed border-t border-slate-50 pt-3" style="display: none;">{{ __('landing.faq_3_a') }}</p>
                </div>

                <!-- FAQ Item 4 -->
                <div class="bg-white rounded-2xl p-6 shadow-sm border border-slate-100" x-data="{ expanded: false }">
                    <button @click="expanded = !expanded" class="flex justify-between items-center w-full text-start font-black text-slate-900 text-base focus:outline-none">
                        <span>{{ __('landing.faq_4_q') }}</span>
                        <svg class="w-5 h-5 text-blue-600 transform transition-transform" :class="{'rotate-180': expanded}" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" /></svg>
                    </button>
                    <p x-show="expanded" x-transition class="mt-4 text-slate-600 text-sm leading-relaxed border-t border-slate-50 pt-3" style="display: none;">{{ __('landing.faq_4_a') }}</p>
                </div>
            </div>
        </div>
    </section>

    <!-- Footer -->
    <footer id="contact" class="bg-white pt-20 pb-12 border-t border-slate-100">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-8 lg:gap-12 mb-16">
                
                <!-- Brand Info -->
                <div class="lg:col-span-2">
                    <div class="flex items-center gap-3 mb-6">
                        <div class="w-11 h-11 rounded-2xl bg-gradient-to-tr from-blue-600 to-sky-500 flex items-center justify-center text-white shadow-md shadow-blue-500/25">
                            <svg class="w-6 h-6" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"></path>
                                <line x1="12" y1="9" x2="12" y2="15"></line>
                                <line x1="9" y1="12" x2="15" y2="12"></line>
                            </svg>
                        </div>
                        <div>
                            <div class="text-xl font-black text-slate-900 leading-none">DrRoom</div>
                            <p class="text-[11px] font-semibold text-slate-400 mt-1 leading-none">{{ __('landing.subtitle') }}</p>
                        </div>
                    </div>
                    
                    <p class="text-sm text-slate-500 mb-6 leading-relaxed max-w-sm">
                        {{ __('landing.footer_desc') }}
                    </p>
                    
                    <div class="flex items-center gap-3">
                        <a href="https://facebook.com" target="_blank" class="w-10 h-10 rounded-xl bg-slate-50 hover:bg-blue-50 hover:text-blue-600 text-slate-600 flex items-center justify-center transition border border-slate-100"><svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/></svg></a>
                        <a href="https://instagram.com" target="_blank" class="w-10 h-10 rounded-xl bg-slate-50 hover:bg-rose-50 hover:text-rose-600 text-slate-600 flex items-center justify-center transition border border-slate-100"><svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"/></svg></a>
                        <a href="https://t.me" target="_blank" class="w-10 h-10 rounded-xl bg-slate-50 hover:bg-sky-50 hover:text-sky-600 text-slate-600 flex items-center justify-center transition border border-slate-100"><svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M12 0C5.373 0 0 5.373 0 12s5.373 12 12 12 12-5.373 12-12S18.627 0 12 0zm5.894 8.221l-1.97 9.28c-.145.658-.537.818-1.084.508l-3-2.21-1.446 1.394c-.14.18-.357.295-.6.295-.002 0-.003 0-.005 0l.213-3.054 5.56-5.022c.24-.213-.054-.334-.373-.121l-6.869 4.326-2.96-.924c-.643-.204-.657-.643.136-.953l11.57-4.458c.538-.196 1.006.128.832.943z"/></svg></a>
                    </div>
                </div>

                <!-- Quick Links -->
                <div>
                    <h4 class="font-black text-slate-900 text-sm mb-6">{{ __('landing.quick_links') }}</h4>
                    <ul class="space-y-3 text-sm text-slate-600 font-medium">
                        <li><a href="#" class="hover:text-blue-600 transition">{{ __('landing.home') }}</a></li>
                        <li><a href="#app-screens" class="hover:text-blue-600 transition">{{ __('landing.app_showcase_tag') }}</a></li>
                        <li><a href="#services" class="hover:text-blue-600 transition">{{ __('landing.services') }}</a></li>
                        <li><a href="#why-us" class="hover:text-blue-600 transition">{{ __('landing.about_tag') }}</a></li>
                        <li><a href="#how-it-works" class="hover:text-blue-600 transition">{{ __('landing.how_it_works') }}</a></li>
                        <li><a href="/staff" class="text-blue-600 font-bold hover:underline transition">{{ __('landing.staff_portal') }}</a></li>
                    </ul>
                </div>

                <!-- Services Links -->
                <div>
                    <h4 class="font-black text-slate-900 text-sm mb-6">{{ __('landing.services') }}</h4>
                    <ul class="space-y-3 text-sm text-slate-600 font-medium">
                        <li><a href="#services" class="hover:text-blue-600 transition">{{ __('landing.lab_tests') }}</a></li>
                        <li><a href="#services" class="hover:text-blue-600 transition">{{ __('landing.nursing') }}</a></li>
                        <li><a href="#services" class="hover:text-blue-600 transition">{{ __('landing.screen_ai_tab') }}</a></li>
                        <li><a href="#services" class="hover:text-blue-600 transition">{{ __('landing.pharmacy') }}</a></li>
                        <li><a href="#services" class="hover:text-blue-600 transition">{{ __('landing.screen_firstaid_tab') }}</a></li>
                    </ul>
                </div>

                <!-- Contact Details -->
                <div>
                    <h4 class="font-black text-slate-900 text-sm mb-6">{{ __('landing.contact_us') }}</h4>
                    <ul class="space-y-4 text-sm text-slate-600 font-medium">
                        <li class="flex items-start gap-3">
                            <svg class="w-5 h-5 text-blue-600 flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"></path></svg>
                            <span dir="ltr">+964 750 000 0000</span>
                        </li>
                        <li class="flex items-start gap-3">
                            <svg class="w-5 h-5 text-blue-600 flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path></svg>
                            <span>contact@drroom.app</span>
                        </li>
                        <li class="flex items-start gap-3">
                            <svg class="w-5 h-5 text-blue-600 flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>
                            <span>{{ __('landing.address') }}</span>
                        </li>
                    </ul>
                </div>
            </div>

            <div class="flex flex-col sm:flex-row items-center justify-between pt-8 border-t border-slate-100 text-xs text-slate-400 font-medium gap-4">
                <div>
                    &copy; {{ date('Y') }} DrRoom. {{ __('landing.rights_reserved') }}.
                </div>
                <div class="flex gap-6">
                    <a href="/privacy-policy" class="text-blue-600 font-bold hover:underline transition">{{ __('landing.privacy') }}</a>
                    <a href="/privacy-policy" class="hover:text-slate-600 transition">{{ __('landing.terms') }}</a>
                    <a href="/staff/login" class="text-blue-600 font-bold hover:underline transition">چوونەژوورەوەی ستاف</a>
                </div>
            </div>
        </div>
    </footer>

</body>
</html>