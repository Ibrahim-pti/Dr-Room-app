<!DOCTYPE html>
<html lang="{{ app()->getLocale() }}" dir="{{ in_array(app()->getLocale(), ['ar', 'ckb']) ? 'rtl' : 'ltr' }}" class="scroll-smooth">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>DrRoom - Healthcare at your doorstep</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    
    <!-- Alpine.js for basic interactivity -->
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.13.3/dist/cdn.min.js"></script>
    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    
    <style>
        .gradient-text {
            background: linear-gradient(90deg, #2563EB, #3B82F6);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .hero-bg {
            background-image: radial-gradient(circle at 100% 50%, rgba(59, 130, 246, 0.08) 0%, transparent 50%);
        }
        .pattern-dots {
            background-image: radial-gradient(#cbd5e1 1px, transparent 1px);
            background-size: 20px 20px;
        }
    </style>
</head>
<body class="font-poppins text-gray-800 antialiased bg-white selection:bg-blue-100 selection:text-blue-900 overflow-x-hidden">

    <!-- Navigation -->
    <nav class="fixed w-full bg-white/90 backdrop-blur-md z-50 border-b border-gray-100" x-data="{ mobileMenuOpen: false }">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex justify-between items-center h-20">
                <!-- Logo -->
                <div class="flex-shrink-0 flex items-center gap-2 cursor-pointer">
                    <div class="w-10 h-10 rounded-full bg-blue-50 flex items-center justify-center text-blue-600">
                        <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24"><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35zM11 9H9v2h2v2h2v-2h2V9h-2V7h-2v2z"/></svg>
                    </div>
                    <div>
                        <h1 class="text-xl font-bold text-gray-900 leading-tight">DrRoom</h1>
                        <p class="text-[10px] text-gray-500">{{ __('landing.subtitle') }}</p>
                    </div>
                </div>

                <!-- Desktop Menu -->
                <div class="hidden md:flex space-x-8 items-center">
                    <a href="#" class="text-blue-600 font-semibold border-b-2 border-blue-600 py-1">{{ __('landing.home') }}</a>
                    <a href="#services" class="text-gray-600 hover:text-blue-600 font-medium transition">{{ __('landing.services') }}</a>
                    <a href="#how-it-works" class="text-gray-600 hover:text-blue-600 font-medium transition">{{ __('landing.how_it_works') }}</a>
                    <a href="#about-us" class="text-gray-600 hover:text-blue-600 font-medium transition">{{ __('landing.about_us') }}</a>
                    <a href="#faq" class="text-gray-600 hover:text-blue-600 font-medium transition">{{ __('landing.faq') }}</a>
                    <a href="#contact" class="text-gray-600 hover:text-blue-600 font-medium transition">{{ __('landing.contact') }}</a>
                </div>

                <!-- Right Actions (Language & Download) -->
                <div class="hidden md:flex items-center gap-4">
                    <!-- Language Switcher -->
                    <div class="relative" x-data="{ langOpen: false }">
                        <button @click="langOpen = !langOpen" @click.away="langOpen = false" class="flex items-center gap-1 text-gray-600 hover:text-blue-600 font-medium transition focus:outline-none">
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5h12M9 3v2m1.048 9.5A18.022 18.022 0 016.412 9m6.088 9h7M11 21l5-10 5 10M12.751 5C11.783 10.77 8.07 15.61 3 18.129"></path></svg>
                            <span>{{ strtoupper(app()->getLocale() == "ckb" ? "KU" : app()->getLocale()) }}</span>
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
                        </button>
                        
                        <div x-show="langOpen" x-transition class="absolute end-0 mt-2 w-32 bg-white rounded-xl shadow-lg border border-gray-100 py-2 z-50" style="display: none;">
                            <a href="/en" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 hover:text-blue-600 transition">English</a>
                            <a href="/ckb" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 hover:text-blue-600 transition">کوردی</a>
                            <a href="/ar" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 hover:text-blue-600 transition">العربية</a>
                        </div>
                    </div>

                    <!-- Download App Button -->
                    <button class="bg-blue-600 hover:bg-blue-700 text-white px-6 py-2.5 rounded-lg font-medium transition shadow-lg shadow-blue-600/30 flex items-center gap-2">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"></path></svg>
                        Download App
                    </button>
                </div>

                <!-- Mobile menu button -->
                <div class="md:hidden flex items-center">
                    <button @click="mobileMenuOpen = !mobileMenuOpen" class="text-gray-600 hover:text-gray-900 focus:outline-none">
                        <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path x-show="!mobileMenuOpen" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
                            <path x-show="mobileMenuOpen" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                    </button>
                </div>
            </div>
        </div>

        <!-- Mobile Menu -->
        <div x-show="mobileMenuOpen" class="md:hidden bg-white border-t border-gray-100" style="display: none;">
            <div class="px-2 pt-2 pb-3 space-y-1 sm:px-3">
                <a href="#" @click="mobileMenuOpen = false" class="block px-3 py-2 text-blue-600 font-semibold bg-blue-50 rounded-md">{{ __('landing.home') }}</a>
                <a href="#services" @click="mobileMenuOpen = false" class="block px-3 py-2 text-gray-600 hover:bg-gray-50 rounded-md font-medium">{{ __('landing.services') }}</a>
                <a href="#how-it-works" @click="mobileMenuOpen = false" class="block px-3 py-2 text-gray-600 hover:bg-gray-50 rounded-md font-medium">{{ __('landing.how_it_works') }}</a>
                <a href="#about-us" @click="mobileMenuOpen = false" class="block px-3 py-2 text-gray-600 hover:bg-gray-50 rounded-md font-medium">{{ __('landing.about_us') }}</a>
                <a href="#faq" @click="mobileMenuOpen = false" class="block px-3 py-2 text-gray-600 hover:bg-gray-50 rounded-md font-medium">{{ __('landing.faq') }}</a>
                <a href="#contact" @click="mobileMenuOpen = false" class="block px-3 py-2 text-gray-600 hover:bg-gray-50 rounded-md font-medium">{{ __('landing.contact') }}</a>
                
                <!-- Mobile Language Selector -->
                <div class="border-t border-gray-100 mt-4 pt-4">
                    <p class="px-3 text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2">{{ __('landing.language') }}</p>
                    <div class="flex gap-2 px-3">
                        <a href="/en" class="flex-1 bg-gray-50 text-gray-600 hover:bg-gray-100 text-center block py-2 rounded-lg text-sm font-medium transition border border-transparent">EN</a>
                        <a href="/ckb" class="flex-1 bg-gray-50 text-gray-600 hover:bg-gray-100 text-center block py-2 rounded-lg text-sm font-medium transition border border-transparent">کوردی</a>
                        <a href="/ar" class="flex-1 bg-gray-50 text-gray-600 hover:bg-gray-100 text-center block py-2 rounded-lg text-sm font-medium transition border border-transparent">عربي</a>
                    </div>
                </div>
            </div>
        </div>
    </nav>

    <!-- Hero Section -->
    <section class="pt-32 pb-16 md:pt-40 md:pb-24 hero-bg overflow-hidden relative">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
            <div class="flex flex-col lg:flex-row items-center justify-between gap-12">
                <!-- Left Content -->
                <div class="w-full lg:w-1/2 flex flex-col items-center lg:items-start text-center lg:text-start">
                    <h1 class="text-4xl md:text-5xl lg:text-6xl font-bold text-slate-900 leading-tight mb-6">
                        {{ __('landing.hero_title_1') }}<br/> {{ __('landing.hero_title_2') }}<br/>
                        <span class="text-blue-600">{{ __('landing.hero_title_3') }}</span>
                    </h1>
                    
                    <p class="text-lg text-slate-600 mb-8 max-w-lg">
                        {{ __('landing.hero_desc') }}
                    </p>
                    
                    <div class="flex flex-col sm:flex-row gap-4 mb-10 w-full justify-center lg:justify-start">
                        <button class="bg-blue-600 hover:bg-blue-700 text-white px-8 py-3.5 rounded-xl font-medium transition shadow-lg shadow-blue-600/30 flex items-center justify-center gap-3">
                            <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24"><path d="M17.523 15.3414C17.523 15.3414 16.2731 16.5913 14.7732 16.5913C13.2732 16.5913 11.7733 15.3414 11.7733 15.3414L10.5234 14.0915C10.5234 14.0915 9.27351 12.8416 9.27351 11.3416C9.27351 9.8417 10.5234 8.59178 10.5234 8.59178L11.7733 7.34188C11.7733 7.34188 12.0858 7.02938 12.7107 7.02938C13.3357 7.02938 13.6482 7.34188 13.6482 7.34188L14.7732 8.4668C14.7732 8.4668 15.0857 8.77929 15.0857 9.40424C15.0857 10.0292 14.7732 10.3417 14.7732 10.3417L13.8357 11.2791C13.8357 11.2791 14.0232 11.9041 14.5232 12.4041C15.0232 12.9041 15.6481 13.0916 15.6481 13.0916L16.5856 12.1541C16.5856 12.1541 16.8981 11.8416 17.5231 11.8416C18.1481 11.8416 18.4606 12.1541 18.4606 12.1541L19.5855 13.279C19.5855 13.279 19.898 13.5915 19.898 14.2165C19.898 14.8414 19.5855 15.1539 19.5855 15.1539L18.3356 16.4038C18.3356 16.4038 18.0231 16.7163 17.3981 16.7163C16.7731 16.7163 16.4606 16.4038 16.4606 16.4038L17.523 15.3414Z"/></svg>
                            <div class="text-start">
                                <div class="text-xs font-normal">{{ __('landing.download_android') }}</div>
                                <div class="text-sm font-bold">{{ __('landing.android') }}</div>
                            </div>
                        </button>
                        
                        <button class="bg-gray-900 hover:bg-black text-white px-8 py-3.5 rounded-xl font-medium transition shadow-lg flex items-center justify-center gap-3">
                            <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24"><path d="M16.364 8.636a2.983 2.983 0 0 0-2.121-.879 2.983 2.983 0 0 0-2.121.879L12 8.757l-.121-.121a2.983 2.983 0 0 0-2.121-.879 2.983 2.983 0 0 0-2.121.879 3.018 3.018 0 0 0 0 4.243l4.243 4.242 4.242-4.242a3.018 3.018 0 0 0 0-4.243z"/></svg>
                            <div class="text-start">
                                <div class="text-xs font-normal">{{ __('landing.download_android') }}</div>
                                <div class="text-sm font-bold">{{ __('landing.ios') }}</div>
                            </div>
                        </button>
                    </div>

                    <div class="flex items-center gap-4">
                        <div class="flex -space-x-3">
                            <img class="w-10 h-10 rounded-full border-2 border-white" src="https://i.pravatar.cc/100?img=1" alt="User">
                            <img class="w-10 h-10 rounded-full border-2 border-white" src="https://i.pravatar.cc/100?img=2" alt="User">
                            <img class="w-10 h-10 rounded-full border-2 border-white" src="https://i.pravatar.cc/100?img=3" alt="User">
                            <img class="w-10 h-10 rounded-full border-2 border-white" src="https://i.pravatar.cc/100?img=4" alt="User">
                        </div>
                        <div>
                            <div class="text-xl font-bold text-slate-900">10K+</div>
                            <div class="text-sm text-slate-500">{{ __('landing.happy_users') }}</div>
                        </div>
                    </div>
                </div>

                <!-- Right Content (Mockups) -->
                <div class="w-full lg:w-1/2 relative flex justify-center lg:justify-end min-h-[500px]">
                    <!-- Back Phone Image -->
                    <div class="absolute end-4 md:end-16 top-10 w-[240px] h-[500px] rounded-[2.5rem] shadow-xl transform rotate-6 z-0 overflow-hidden border-[8px] border-slate-200 bg-slate-100 flex items-center justify-center">
                        <img src="{{ asset('images/app-screen-back.png') }}" alt="App Nursing Services" class="w-full h-full object-cover" onerror="this.onerror=null; this.src='https://placehold.co/240x500/slate-100/slate-400?text=App+Screen\n(Upload+app-screen-back.png)';">
                    </div>

                    <!-- Front Phone Image -->
                    <div class="absolute start-4 md:start-24 top-0 w-[260px] h-[540px] rounded-[2.5rem] shadow-2xl z-10 overflow-hidden border-[10px] border-slate-900 bg-white flex items-center justify-center">
                        <!-- Notch -->
                        <div class="absolute top-0 w-full flex justify-center z-20">
                            <div class="w-1/2 h-6 bg-slate-900 rounded-b-2xl"></div>
                        </div>
                        <img src="{{ asset('images/app-screen-front.png') }}" alt="App Home Screen" class="w-full h-full object-cover" onerror="this.onerror=null; this.src='https://placehold.co/260x540/white/slate-400?text=App+Screen\n(Upload+app-screen-front.png)';">
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Services Section -->
    <section id="services" class="py-20 bg-slate-50 relative">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
            <div class="text-center max-w-3xl mx-auto mb-16">
                <h2 class="text-3xl md:text-4xl font-bold text-slate-900 mb-4">{{ __('landing.our_services') }}</h2>
                <p class="text-slate-600 text-lg">{{ __('landing.services_desc') }}</p>
            </div>

            <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-6">
                <!-- Lab Tests -->
                <div class="bg-white rounded-2xl p-6 text-center shadow-[0_4px_20px_-4px_rgba(0,0,0,0.05)] hover:-translate-y-1 transition duration-300 border border-slate-100 flex flex-col h-full">
                    <div class="w-16 h-16 mx-auto bg-green-50 rounded-2xl flex items-center justify-center mb-4 text-green-500">
                        <span class="text-3xl">🧪</span>
                    </div>
                    <h3 class="font-bold text-slate-900 mb-2">{{ __('landing.lab_tests') }}</h3>
                    <p class="text-sm text-slate-500 mb-6 flex-grow">{{ __('landing.lab_desc') }}</p>
                    <span class="bg-green-50 text-green-600 text-xs font-bold py-1.5 px-3 rounded-lg inline-block w-full">{{ __('landing.available') }}</span>
                </div>
                
                <!-- Nursing -->
                <div class="bg-white rounded-2xl p-6 text-center shadow-[0_8px_30px_-4px_rgba(59,130,246,0.15)] hover:-translate-y-1 transition duration-300 border-2 border-blue-100 flex flex-col h-full relative">
                    <div class="w-16 h-16 mx-auto bg-blue-50 rounded-2xl flex items-center justify-center mb-4 text-blue-500">
                        <span class="text-3xl">👩‍⚕️</span>
                    </div>
                    <h3 class="font-bold text-slate-900 mb-2">{{ __('landing.nursing') }}</h3>
                    <p class="text-sm text-slate-500 mb-6 flex-grow">{{ __('landing.nursing_desc') }}</p>
                    <span class="bg-blue-50 text-blue-600 text-xs font-bold py-1.5 px-3 rounded-lg inline-block w-full">{{ __('landing.available') }}</span>
                </div>
                
                <!-- Doctor -->
                <div class="bg-white rounded-2xl p-6 text-center shadow-[0_4px_20px_-4px_rgba(0,0,0,0.05)] hover:-translate-y-1 transition duration-300 border border-slate-100 flex flex-col h-full">
                    <div class="w-16 h-16 mx-auto bg-purple-50 rounded-2xl flex items-center justify-center mb-4 text-purple-500">
                        <span class="text-3xl">👨‍⚕️</span>
                    </div>
                    <h3 class="font-bold text-slate-900 mb-2">{{ __('landing.doctor') }}</h3>
                    <p class="text-sm text-slate-500 mb-6 flex-grow">{{ __('landing.doctor_desc') }}</p>
                    <span class="bg-slate-100 text-slate-600 text-xs font-medium py-1.5 px-3 rounded-lg inline-block w-full">{{ __('landing.coming_soon') }}</span>
                </div>
                
                <!-- Pharmacy -->
                <div class="bg-white rounded-2xl p-6 text-center shadow-[0_4px_20px_-4px_rgba(0,0,0,0.05)] hover:-translate-y-1 transition duration-300 border border-slate-100 flex flex-col h-full">
                    <div class="w-16 h-16 mx-auto bg-pink-50 rounded-2xl flex items-center justify-center mb-4 text-pink-500">
                        <span class="text-3xl">💊</span>
                    </div>
                    <h3 class="font-bold text-slate-900 mb-2">{{ __('landing.pharmacy') }}</h3>
                    <p class="text-sm text-slate-500 mb-6 flex-grow">{{ __('landing.pharmacy_desc') }}</p>
                    <span class="bg-slate-100 text-slate-600 text-xs font-medium py-1.5 px-3 rounded-lg inline-block w-full">{{ __('landing.coming_soon') }}</span>
                </div>
                
                <!-- X-Ray -->
                <div class="bg-white rounded-2xl p-6 text-center shadow-[0_4px_20px_-4px_rgba(0,0,0,0.05)] hover:-translate-y-1 transition duration-300 border border-slate-100 flex flex-col h-full">
                    <div class="w-16 h-16 mx-auto bg-orange-50 rounded-2xl flex items-center justify-center mb-4 text-orange-500">
                        <span class="text-3xl">🦴</span>
                    </div>
                    <h3 class="font-bold text-slate-900 mb-2">{{ __('landing.xray') }}</h3>
                    <p class="text-sm text-slate-500 mb-6 flex-grow">{{ __('landing.xray_desc') }}</p>
                    <span class="bg-slate-100 text-slate-600 text-xs font-medium py-1.5 px-3 rounded-lg inline-block w-full">{{ __('landing.coming_soon') }}</span>
                </div>
                
                <!-- More Services -->
                <div class="bg-white rounded-2xl p-6 text-center shadow-[0_4px_20px_-4px_rgba(0,0,0,0.05)] hover:-translate-y-1 transition duration-300 border border-slate-100 flex flex-col h-full">
                    <div class="w-16 h-16 mx-auto bg-teal-50 rounded-2xl flex items-center justify-center mb-4 text-teal-500">
                        <span class="text-3xl">💠</span>
                    </div>
                    <h3 class="font-bold text-slate-900 mb-2">{{ __('landing.more_services') }}</h3>
                    <p class="text-sm text-slate-500 mb-6 flex-grow">{{ __('landing.more_desc') }}</p>
                    <span class="bg-slate-100 text-slate-600 text-xs font-medium py-1.5 px-3 rounded-lg inline-block w-full">{{ __('landing.coming_soon') }}</span>
                </div>
            </div>
        </div>
    </section>

    <!-- About Section / Trust -->
    <section id="about-us" class="py-24 relative overflow-hidden">
        <!-- Decorative dots -->
        <div class="absolute start-0 top-1/4 w-64 h-64 pattern-dots opacity-20 -z-10"></div>
        
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex flex-col lg:flex-row items-center gap-16">
                <!-- Left: Phone mockup with Map -->
                <div class="w-full lg:w-1/2 flex justify-center relative">
                    <div class="w-[300px] h-[600px] bg-white rounded-[3rem] border-[12px] border-slate-900 shadow-2xl overflow-hidden relative z-10 flex flex-col justify-center items-center">
                        <!-- Top Notch -->
                        <div class="absolute top-0 w-full flex justify-center z-20">
                            <div class="w-1/2 h-6 bg-slate-900 rounded-b-2xl"></div>
                        </div>
                        <img src="{{ asset('images/app-screen-map.png') }}" alt="App Map Screen" class="w-full h-full object-cover" onerror="this.onerror=null; this.src='https://placehold.co/300x600/white/slate-400?text=App+Map+Screen\n(Upload+app-screen-map.png)';">
                    </div>
                </div>

                <!-- Right: Text & Features -->
                <div class="w-full lg:w-1/2">
                    <div class="text-blue-600 font-bold tracking-wider text-sm mb-2 uppercase">{{ __('landing.about_tag') }}</div>
                    <h2 class="text-3xl md:text-4xl font-bold text-slate-900 mb-6 leading-tight">
                        Quality Care You<br/> Can <span class="text-blue-600"></span>
                    </h2>
                    <p class="text-slate-600 text-lg mb-10">
                        {{ __('landing.about_desc') }}
                    </p>

                    <div class="space-y-6">
                        <div class="flex gap-4">
                            <div class="flex-shrink-0 w-12 h-12 bg-blue-50 text-blue-600 rounded-xl flex items-center justify-center mt-1">
                                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"></path></svg>
                            </div>
                            <div>
                                <h4 class="font-bold text-slate-900 text-lg mb-1">{{ __('landing.verified_prof') }}</h4>
                                <p class="text-slate-500">{{ __('landing.verified_desc') }}</p>
                            </div>
                        </div>

                        <div class="flex gap-4">
                            <div class="flex-shrink-0 w-12 h-12 bg-blue-50 text-blue-600 rounded-xl flex items-center justify-center mt-1">
                                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                            </div>
                            <div>
                                <h4 class="font-bold text-slate-900 text-lg mb-1">{{ __('landing.fast_reliable') }}</h4>
                                <p class="text-slate-500">{{ __('landing.fast_desc') }}</p>
                            </div>
                        </div>

                        <div class="flex gap-4">
                            <div class="flex-shrink-0 w-12 h-12 bg-blue-50 text-blue-600 rounded-xl flex items-center justify-center mt-1">
                                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path></svg>
                            </div>
                            <div>
                                <h4 class="font-bold text-slate-900 text-lg mb-1">{{ __('landing.easy_booking') }}</h4>
                                <p class="text-slate-500">{{ __('landing.easy_desc') }}</p>
                            </div>
                        </div>

                        <div class="flex gap-4">
                            <div class="flex-shrink-0 w-12 h-12 bg-blue-50 text-blue-600 rounded-xl flex items-center justify-center mt-1">
                                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"></path></svg>
                            </div>
                            <div>
                                <h4 class="font-bold text-slate-900 text-lg mb-1">{{ __('landing.secure_pay') }}</h4>
                                <p class="text-slate-500">{{ __('landing.secure_desc') }}</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Stats and App Download Banner -->
    <section class="py-12">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="bg-blue-600 rounded-[2rem] overflow-hidden relative shadow-2xl shadow-blue-600/20">
                <!-- Decorative SVG -->
                <div class="absolute bottom-0 start-0 opacity-10">
                    <svg width="400" height="200" viewBox="0 0 400 200" fill="none"><path d="M0 100 Q 50 50, 100 100 T 200 100 T 300 100 T 400 100 L 400 200 L 0 200 Z" fill="white"/></svg>
                </div>

                <div class="flex flex-col lg:flex-row">
                    <!-- Stats Side -->
                    <div class="w-full lg:w-3/5 p-10 lg:p-16 flex items-center">
                        <div class="grid grid-cols-1 md:grid-cols-3 gap-8 w-full text-white text-center md:text-start divide-y md:divide-y-0 md:divide-x divide-blue-400">
                            <div class="pt-6 md:pt-0">
                                <div class="text-4xl md:text-5xl font-bold mb-2">10K+</div>
                                <div class="text-blue-100 font-medium">{{ __('landing.happy_users') }}</div>
                            </div>
                            <div class="pt-6 md:pt-0 md:ps-8">
                                <div class="text-4xl md:text-5xl font-bold mb-2">500+</div>
                                <div class="text-blue-100 font-medium">{{ __('landing.verified_prof') }}</div>
                            </div>
                            <div class="pt-6 md:pt-0 md:ps-8">
                                <div class="text-4xl md:text-5xl font-bold mb-2">50K+</div>
                                <div class="text-blue-100 font-medium">{{ __('landing.services_completed') }}</div>
                            </div>
                        </div>
                    </div>

                    <!-- App Download Side -->
                    <div class="w-full lg:w-2/5 bg-blue-700/50 p-10 lg:p-16 relative overflow-hidden flex flex-col justify-center">
                        <div class="relative z-10">
                            <h3 class="text-2xl font-bold text-white mb-3">{{ __('landing.download_drroom') }}</h3>
                            <p class="text-blue-100 mb-8 max-w-xs">{{ __('landing.get_best_exp') }}</p>
                            
                            <div class="flex gap-4">
                                <button class="bg-black text-white px-4 py-2 rounded-lg flex items-center gap-2 hover:bg-gray-900 transition">
                                    <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24"><path d="M17.523 15.3414C17.523 15.3414 16.2731 16.5913 14.7732 16.5913C13.2732 16.5913 11.7733 15.3414 11.7733 15.3414L10.5234 14.0915C10.5234 14.0915 9.27351 12.8416 9.27351 11.3416C9.27351 9.8417 10.5234 8.59178 10.5234 8.59178L11.7733 7.34188C11.7733 7.34188 12.0858 7.02938 12.7107 7.02938C13.3357 7.02938 13.6482 7.34188 13.6482 7.34188L14.7732 8.4668C14.7732 8.4668 15.0857 8.77929 15.0857 9.40424C15.0857 10.0292 14.7732 10.3417 14.7732 10.3417L13.8357 11.2791C13.8357 11.2791 14.0232 11.9041 14.5232 12.4041C15.0232 12.9041 15.6481 13.0916 15.6481 13.0916L16.5856 12.1541C16.5856 12.1541 16.8981 11.8416 17.5231 11.8416C18.1481 11.8416 18.4606 12.1541 18.4606 12.1541L19.5855 13.279C19.5855 13.279 19.898 13.5915 19.898 14.2165C19.898 14.8414 19.5855 15.1539 19.5855 15.1539L18.3356 16.4038C18.3356 16.4038 18.0231 16.7163 17.3981 16.7163C16.7731 16.7163 16.4606 16.4038 16.4606 16.4038L17.523 15.3414Z"/></svg>
                                    <div class="text-start leading-tight">
                                        <div class="text-[10px] font-normal">{{ __('landing.get_on') }}</div>
                                        <div class="text-sm font-bold">{{ __('landing.google_play') }}</div>
                                    </div>
                                </button>
                                
                                <button class="bg-black text-white px-4 py-2 rounded-lg flex items-center gap-2 hover:bg-gray-900 transition">
                                    <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24"><path d="M16.364 8.636a2.983 2.983 0 0 0-2.121-.879 2.983 2.983 0 0 0-2.121.879L12 8.757l-.121-.121a2.983 2.983 0 0 0-2.121-.879 2.983 2.983 0 0 0-2.121.879 3.018 3.018 0 0 0 0 4.243l4.243 4.242 4.242-4.242a3.018 3.018 0 0 0 0-4.243z"/></svg>
                                    <div class="text-start leading-tight">
                                        <div class="text-[10px] font-normal">{{ __('landing.download_on') }}</div>
                                        <div class="text-sm font-bold">{{ __('landing.app_store') }}</div>
                                    </div>
                                </button>
                            </div>
                        </div>
                        
                        <!-- Partial phone showing bottom right -->
                        <div class="absolute -bottom-16 -end-10 w-48 h-64 bg-white rounded-t-[2rem] border-8 border-slate-900 shadow-2xl transform rotate-12 z-0 hidden md:flex items-center justify-center overflow-hidden">
                            <!-- Top Notch -->
                            <div class="absolute top-0 w-full flex justify-center z-20">
                                <div class="w-1/2 h-4 bg-slate-900 rounded-b-xl"></div>
                            </div>
                            <img src="{{ asset('images/app-screen-banner.png') }}" alt="App Banner Screen" class="w-full h-full object-cover" onerror="this.onerror=null; this.src='https://placehold.co/200x300/white/slate-400?text=App\n(Upload+app-screen-banner.png)';">
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- How It Works Section -->
    <section id="how-it-works" class="py-20 bg-white relative">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
            <h2 class="text-3xl md:text-4xl font-bold text-slate-900 mb-4">{{ __('landing.how_it_works') }}</h2>
            <p class="text-slate-600 text-lg mb-16">{{ __('landing.how_works_desc') }}</p>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
                <div class="relative">
                    <div class="w-16 h-16 mx-auto bg-blue-100 text-blue-600 rounded-2xl flex items-center justify-center font-bold text-2xl mb-6 shadow-sm">1</div>
                    <h4 class="font-bold text-slate-900 text-xl mb-3">{{ __('landing.download_app') }}</h4>
                    <p class="text-slate-500">{{ __('landing.step_1_desc') }}</p>
                    <div class="hidden md:block absolute top-8 start-[60%] w-[80%] border-t-2 border-dashed border-blue-200"></div>
                </div>
                <div class="relative">
                    <div class="w-16 h-16 mx-auto bg-blue-100 text-blue-600 rounded-2xl flex items-center justify-center font-bold text-2xl mb-6 shadow-sm">2</div>
                    <h4 class="font-bold text-slate-900 text-xl mb-3">{{ __('landing.step_2') }}</h4>
                    <p class="text-slate-500">{{ __('landing.step_2_desc') }}</p>
                    <div class="hidden md:block absolute top-8 start-[60%] w-[80%] border-t-2 border-dashed border-blue-200"></div>
                </div>
                <div>
                    <div class="w-16 h-16 mx-auto bg-blue-100 text-blue-600 rounded-2xl flex items-center justify-center font-bold text-2xl mb-6 shadow-sm">3</div>
                    <h4 class="font-bold text-slate-900 text-xl mb-3">{{ __('landing.step_3') }}</h4>
                    <p class="text-slate-500">{{ __('landing.step_3_desc') }}</p>
                </div>
            </div>
        </div>
    </section>

    <!-- FAQ Section -->
    <section id="faq" class="py-20 bg-slate-50 relative border-t border-slate-100">
        <div class="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="text-center mb-12">
                <h2 class="text-3xl md:text-4xl font-bold text-slate-900 mb-4">{{ __('landing.faq_title') }}</h2>
                <p class="text-slate-600 text-lg">Got questions? We've got answers.</p>
            </div>
            <div class="space-y-4">
                <div class="bg-white rounded-2xl p-6 shadow-sm border border-slate-100" x-data="{ expanded: false }">
                    <button @click="expanded = !expanded" class="flex justify-between items-center w-full text-start font-bold text-slate-900 text-lg focus:outline-none">
                        <span>{{ __('landing.faq_1_q') }}</span>
                        <svg class="w-5 h-5 text-blue-600 transform transition-transform" :class="{'rotate-180': expanded}" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" /></svg>
                    </button>
                    <p x-show="expanded" class="mt-4 text-slate-600" style="display: none;">{{ __('landing.faq_1_a') }}</p>
                </div>
                <div class="bg-white rounded-2xl p-6 shadow-sm border border-slate-100" x-data="{ expanded: false }">
                    <button @click="expanded = !expanded" class="flex justify-between items-center w-full text-start font-bold text-slate-900 text-lg focus:outline-none">
                        <span>{{ __('landing.faq_2_q') }}</span>
                        <svg class="w-5 h-5 text-blue-600 transform transition-transform" :class="{'rotate-180': expanded}" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" /></svg>
                    </button>
                    <p x-show="expanded" class="mt-4 text-slate-600" style="display: none;">{{ __('landing.faq_2_a') }}</p>
                </div>
                <div class="bg-white rounded-2xl p-6 shadow-sm border border-slate-100" x-data="{ expanded: false }">
                    <button @click="expanded = !expanded" class="flex justify-between items-center w-full text-start font-bold text-slate-900 text-lg focus:outline-none">
                        <span>{{ __('landing.faq_3_q') }}</span>
                        <svg class="w-5 h-5 text-blue-600 transform transition-transform" :class="{'rotate-180': expanded}" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" /></svg>
                    </button>
                    <p x-show="expanded" class="mt-4 text-slate-600" style="display: none;">{{ __('landing.faq_3_a') }}</p>
                </div>
            </div>
        </div>
    </section>

    <!-- Testimonials -->
    <section class="py-20 bg-slate-50 relative overflow-hidden">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="text-center mb-16">
                <h2 class="text-3xl md:text-4xl font-bold text-slate-900 mb-4">{{ __('landing.testimonials') }}</h2>
                <p class="text-slate-600 text-lg">{{ __('landing.test_desc') }}</p>
            </div>

            <div class="flex items-center gap-6 overflow-x-auto pb-8 snap-x hide-scrollbar">
                
                <!-- Card 1 -->
                <div class="bg-white rounded-2xl p-8 shadow-sm border border-slate-100 min-w-[320px] snap-center">
                    <div class="flex text-yellow-400 mb-4">
                        <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>
                        <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>
                        <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>
                        <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>
                        <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>
                    </div>
                    <p class="text-slate-600 mb-8 h-20">{{ __('landing.test_1') }}</p>
                    <div class="flex items-center gap-4">
                        <img src="https://i.pravatar.cc/100?img=5" class="w-12 h-12 rounded-full object-cover" alt="User">
                        <div>
                            <div class="font-bold text-slate-900">Sara Ahmed</div>
                            <div class="text-xs text-slate-500">Erbil</div>
                        </div>
                    </div>
                </div>

                <!-- Card 2 -->
                <div class="bg-white rounded-2xl p-8 shadow-sm border border-slate-100 min-w-[320px] snap-center">
                    <div class="flex text-yellow-400 mb-4">
                        <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>
                        <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>
                        <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>
                        <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>
                        <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>
                    </div>
                    <p class="text-slate-600 mb-8 h-20">{{ __('landing.test_2') }}</p>
                    <div class="flex items-center gap-4">
                        <img src="https://i.pravatar.cc/100?img=11" class="w-12 h-12 rounded-full object-cover" alt="User">
                        <div>
                            <div class="font-bold text-slate-900">Hewar Mustafa</div>
                            <div class="text-xs text-slate-500">Duhok</div>
                        </div>
                    </div>
                </div>

                <!-- Card 3 -->
                <div class="bg-white rounded-2xl p-8 shadow-sm border border-slate-100 min-w-[320px] snap-center">
                    <div class="flex text-yellow-400 mb-4">
                        <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>
                        <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>
                        <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>
                        <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>
                        <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20"><path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path></svg>
                    </div>
                    <p class="text-slate-600 mb-8 h-20">{{ __('landing.test_3') }}</p>
                    <div class="flex items-center gap-4">
                        <img src="https://i.pravatar.cc/100?img=9" class="w-12 h-12 rounded-full object-cover" alt="User">
                        <div>
                            <div class="font-bold text-slate-900">Zana Karim</div>
                            <div class="text-xs text-slate-500">Sulaymaniyah</div>
                        </div>
                    </div>
                </div>

            </div>

            <!-- Dots -->
            <div class="flex justify-center mt-6 gap-2">
                <div class="w-6 h-2 rounded-full bg-blue-600"></div>
                <div class="w-4 h-2 rounded-full bg-slate-200"></div>
                <div class="w-4 h-2 rounded-full bg-slate-200"></div>
            </div>
        </div>
    </section>

    <!-- Footer -->
    <footer id="contact" class="bg-white pt-20 pb-10 border-t border-slate-100">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-8 lg:gap-12 mb-16">
                <!-- Brand -->
                <div class="lg:col-span-1">
                    <div class="flex items-center gap-2 mb-6">
                        <div class="w-10 h-10 rounded-full bg-blue-50 flex items-center justify-center text-blue-600">
                            <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24"><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35zM11 9H9v2h2v2h2v-2h2V9h-2V7h-2v2z"/></svg>
                        </div>
                        <div>
                            <h2 class="text-xl font-bold text-slate-900 leading-tight">DrRoom</h2>
                            <p class="text-[10px] text-slate-500">{{ __('landing.subtitle') }}</p>
                        </div>
                    </div>
                    <p class="text-sm text-slate-500 mb-6 leading-relaxed">
                        {{ __('landing.footer_desc') }}
                    </p>
                    <div class="flex gap-4">
                        <a href="#" class="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center text-slate-500 hover:bg-blue-50 hover:text-blue-600 transition"><svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24"><path d="M24 4.557c-.883.392-1.832.656-2.828.775 1.017-.609 1.798-1.574 2.165-2.724-.951.564-2.005.974-3.127 1.195-.897-.957-2.178-1.555-3.594-1.555-3.179 0-5.515 2.966-4.797 6.045-4.091-.205-7.719-2.165-10.148-5.144-1.29 2.213-.669 5.108 1.523 6.574-.806-.026-1.566-.247-2.229-.616-.054 2.281 1.581 4.415 3.949 4.89-.693.188-1.452.232-2.224.084.626 1.956 2.444 3.379 4.6 3.419-2.07 1.623-4.678 2.348-7.29 2.04 2.179 1.397 4.768 2.212 7.548 2.212 9.142 0 14.307-7.721 13.995-14.646.962-.695 1.797-1.562 2.457-2.549z"/></svg></a>
                        <a href="#" class="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center text-slate-500 hover:bg-blue-50 hover:text-blue-600 transition"><svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"/></svg></a>
                        <a href="#" class="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center text-slate-500 hover:bg-blue-50 hover:text-blue-600 transition"><svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24"><path d="M19.615 3.184c-3.604-.246-11.631-.245-15.23 0-3.897.266-4.356 2.62-4.385 8.816.029 6.185.484 8.549 4.385 8.816 3.6.245 11.626.246 15.23 0 3.897-.266 4.356-2.62 4.385-8.816-.029-6.185-.484-8.549-4.385-8.816zm-10.615 12.816v-8l8 3.993-8 4.007z"/></svg></a>
                        <a href="#" class="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center text-slate-500 hover:bg-blue-50 hover:text-blue-600 transition"><svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24"><path d="M9 8h-3v4h3v12h5v-12h3.642l.358-4h-4v-1.667c0-.955.192-1.333 1.115-1.333h2.885v-5h-3.808c-3.596 0-5.192 1.583-5.192 4.615v3.385z"/></svg></a>
                    </div>
                </div>

                <!-- Links 1 -->
                <div>
                    <h4 class="font-bold text-slate-900 mb-6">{{ __('landing.quick_links') }}</h4>
                    <ul class="space-y-3 text-sm text-slate-600">
                        <li><a href="#" class="hover:text-blue-600 transition">{{ __('landing.home') }}</a></li>
                        <li><a href="#services" class="hover:text-blue-600 transition">{{ __('landing.services') }}</a></li>
                        <li><a href="#how-it-works" class="hover:text-blue-600 transition">{{ __('landing.how_it_works') }}</a></li>
                        <li><a href="#about-us" class="hover:text-blue-600 transition">{{ __('landing.about_us') }}</a></li>
                        <li><a href="#contact" class="hover:text-blue-600 transition">{{ __('landing.contact') }}</a></li>
                    </ul>
                </div>

                <!-- Links 2 -->
                <div>
                    <h4 class="font-bold text-slate-900 mb-6">{{ __('landing.services') }}</h4>
                    <ul class="space-y-3 text-sm text-slate-600">
                        <li><a href="#" class="hover:text-blue-600 transition">{{ __('landing.lab_tests') }}</a></li>
                        <li><a href="#" class="hover:text-blue-600 transition">{{ __('landing.nursing') }}</a></li>
                        <li><a href="#" class="hover:text-blue-600 transition">Doctor Consultation</a></li>
                        <li><a href="#" class="hover:text-blue-600 transition">{{ __('landing.pharmacy') }}</a></li>
                        <li><a href="#" class="hover:text-blue-600 transition">X-Ray & Ultrasound</a></li>
                        <li><a href="#" class="hover:text-blue-600 transition">{{ __('landing.more_services') }}</a></li>
                    </ul>
                </div>

                <!-- Links 3 -->
                <div>
                    <h4 class="font-bold text-slate-900 mb-6">{{ __('landing.support') }}</h4>
                    <ul class="space-y-3 text-sm text-slate-600">
                        <li><a href="#faq" class="hover:text-blue-600 transition">{{ __('landing.faq') }}</a></li>
                        <li><a href="#" class="hover:text-blue-600 transition">{{ __('landing.privacy') }}</a></li>
                        <li><a href="#" class="hover:text-blue-600 transition">{{ __('landing.terms') }}</a></li>
                        <li><a href="#" class="hover:text-blue-600 transition">{{ __('landing.help') }}</a></li>
                    </ul>
                </div>

                <!-- Contact -->
                <div>
                    <h4 class="font-bold text-slate-900 mb-6">{{ __('landing.contact_us') }}</h4>
                    <ul class="space-y-4 text-sm text-slate-600">
                        <li class="flex items-start gap-3">
                            <svg class="w-5 h-5 text-blue-600 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"></path></svg>
                            <span>+964 750 123 4567</span>
                        </li>
                        <li class="flex items-start gap-3">
                            <svg class="w-5 h-5 text-blue-600 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path></svg>
                            <span>info@drroom.com</span>
                        </li>
                        <li class="flex items-start gap-3">
                            <svg class="w-5 h-5 text-blue-600 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>
                            <span>Erbil, Kurdistan Region, Iraq</span>
                        </li>
                    </ul>
                </div>
            </div>

            <div class="text-center text-xs text-slate-500 pt-8 border-t border-slate-100">
                &copy; {{ date('Y') }} DrRoom. All rights reserved.
            </div>
        </div>
    </footer>

</body>
</html>