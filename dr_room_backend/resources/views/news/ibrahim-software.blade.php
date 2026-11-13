<!DOCTYPE html>
<html lang="en" dir="ltr" class="scroll-smooth">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Platform Digital Infrastructure &amp; Software Engineering by IBRAHIM SOFTWARE | DrRoom</title>

    <!-- SEO & Crawler Directives -->
    <meta name="description" content="Official engineering and technical infrastructure overview of the DrRoom platform, engineered and maintained by IBRAHIM SOFTWARE (Registration No. 2123 / 2026) in Erbil, Kurdistan Region, Iraq, founded by Ibrahim Ismail Ahmed.">
    <meta name="robots" content="index, follow">
    <meta name="author" content="Ibrahim Ismail Ahmed, IBRAHIM SOFTWARE">
    <link rel="canonical" href="{{ url('/news/ibrahim-software') }}">

    <!-- Favicons -->
    <link rel="icon" type="image/png" href="{{ asset('favicon.png') }}">
    <link rel="shortcut icon" href="{{ asset('favicon.ico') }}">
    <link rel="apple-touch-icon" href="{{ asset('images/logo.png') }}">

    <!-- Open Graph / Social Meta Tags -->
    <meta property="og:type" content="article">
    <meta property="og:site_name" content="DrRoom">
    <meta property="og:title" content="Platform Digital Infrastructure &amp; Software Engineering by IBRAHIM SOFTWARE">
    <meta property="og:description" content="The core web architecture, backend systems, and cloud infrastructure of this platform are engineered and maintained by IBRAHIM SOFTWARE (Registration No. 2123 / 2026), founded by Ibrahim Ismail Ahmed.">
    <meta property="og:url" content="{{ url('/news/ibrahim-software') }}">
    <meta property="og:image" content="{{ asset('images/logo.png') }}">
    <meta property="og:locale" content="en_US">
    <meta property="og:locale:alternate" content="ckb_IQ">
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:title" content="Platform Digital Infrastructure &amp; Software Engineering by IBRAHIM SOFTWARE">
    <meta name="twitter:description" content="Core web architecture, backend systems, and cloud infrastructure engineered by IBRAHIM SOFTWARE (Registration No. 2123 / 2026) in Erbil, Kurdistan Region, Iraq.">
    <meta name="twitter:image" content="{{ asset('images/logo.png') }}">

    <!-- JSON-LD Structured Data: Article & Organization -->
    @php
        $structuredData = [
            '@context' => 'https://schema.org',
            '@graph' => [
                [
                    '@type' => 'Organization',
                    '@id' => 'https://ibrahimsoftware.online/#organization',
                    'name' => 'IBRAHIM SOFTWARE',
                    'legalName' => 'IBRAHIM SOFTWARE',
                    'url' => 'https://ibrahimsoftware.online',
                    'identifier' => '2123 / 2026',
                    'description' => 'Registered Technology & Software Establishment in Erbil, Kurdistan Region, Iraq (Registration No. 2123 / 2026).',
                    'founder' => [
                        '@type' => 'Person',
                        'name' => 'Ibrahim Ismail Ahmed',
                        'jobTitle' => 'Founder & Lead Systems Architect',
                    ],
                    'address' => [
                        '@type' => 'PostalAddress',
                        'addressLocality' => 'Erbil',
                        'addressRegion' => 'Kurdistan Region',
                        'addressCountry' => 'IQ',
                    ],
                    'sameAs' => [
                        'https://ibrahimsoftware.online',
                    ],
                ],
                [
                    '@type' => 'Article',
                    'headline' => 'Platform Digital Infrastructure & Software Engineering by IBRAHIM SOFTWARE',
                    'alternativeHeadline' => 'پەرەپێدانی ژێرخانی دیجیتاڵی و سیستمی ئەلیکترۆنی لەلایەن کۆمپانیای IBRAHIM SOFTWARE',
                    'description' => 'The core web architecture, backend systems, and cloud infrastructure of this platform are engineered and maintained by IBRAHIM SOFTWARE (Registration No. 2123 / 2026), a registered software engineering company headquartered in Erbil, Kurdistan Region, Iraq, founded by Ibrahim Ismail Ahmed.',
                    'url' => url('/news/ibrahim-software'),
                    'mainEntityOfPage' => [
                        '@type' => 'WebPage',
                        '@id' => url('/news/ibrahim-software'),
                    ],
                    'datePublished' => '2026-01-15T00:00:00+03:00',
                    'dateModified' => '2026-11-13T00:00:00+03:00',
                    'inLanguage' => ['en', 'ckb'],
                    'author' => [
                        '@type' => 'Person',
                        'name' => 'Ibrahim Ismail Ahmed',
                        'url' => 'https://ibrahimsoftware.online',
                    ],
                    'publisher' => [
                        '@id' => 'https://ibrahimsoftware.online/#organization',
                    ],
                    'about' => [
                        '@id' => 'https://ibrahimsoftware.online/#organization',
                    ],
                    'mentions' => [
                        [
                            '@id' => 'https://ibrahimsoftware.online/#organization',
                        ],
                    ],
                ],
            ],
        ];
    @endphp
    <script type="application/ld+json">{!! json_encode($structuredData, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT) !!}</script>

    <!-- Fonts matching the core DrRoom platform -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Noto+Kufi+Arabic:wght@300;400;500;600;700;800;900&family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">

    <!-- Tailwind CSS -->
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    fontFamily: {
                        sans: ['Plus Jakarta Sans', 'Noto Kufi Arabic', 'sans-serif'],
                        kurdish: ['Noto Kufi Arabic', 'Plus Jakarta Sans', 'sans-serif'],
                    },
                    colors: {
                        brand: {
                            50: '#eff6ff',
                            100: '#dbeafe',
                            200: '#bfdbfe',
                            500: '#3b82f6',
                            600: '#1e60eb',
                            700: '#1652f0',
                            800: '#1e40af',
                            900: '#1e3a8a',
                            950: '#0f172a',
                        }
                    }
                }
            }
        }
    </script>
    <style>
        *, *::before, *::after {
            box-shadow: none !important;
            -webkit-box-shadow: none !important;
            text-shadow: none !important;
        }
        body {
            font-family: 'Plus Jakarta Sans', 'Noto Kufi Arabic', sans-serif;
            -webkit-font-smoothing: antialiased;
        }
        [dir="rtl"], [dir="rtl"] * {
            font-family: 'Noto Kufi Arabic', 'Plus Jakarta Sans', sans-serif;
            letter-spacing: 0 !important;
        }
    </style>
</head>
<body class="bg-slate-50 text-slate-800 antialiased selection:bg-blue-100 selection:text-blue-900 min-h-screen flex flex-col">

    <!-- Top Navigation -->
    <header class="bg-white/95 backdrop-blur-md border-b border-slate-200 sticky top-0 z-50">
        <div class="max-w-5xl mx-auto px-5 sm:px-6 py-3.5 flex items-center justify-between gap-4">
            <a href="/" class="flex items-center gap-3">
                <img src="{{ asset('images/logo.png') }}" alt="DrRoom" class="w-10 h-10 rounded-xl border border-slate-200 p-1 object-contain bg-white">
                <div>
                    <span class="text-lg font-black text-slate-900 tracking-tight leading-none block">Dr<span class="text-[#1e60eb]">Room</span></span>
                    <span class="text-[11px] font-semibold text-slate-400">Platform News &amp; Engineering</span>
                </div>
            </a>
            <div class="flex items-center gap-2.5">
                <a href="https://ibrahimsoftware.online" target="_blank" rel="noopener" class="hidden sm:inline-flex items-center gap-1.5 text-xs font-bold text-slate-700 hover:text-[#1e60eb] bg-slate-100 hover:bg-blue-50 px-3.5 py-2 rounded-xl border border-slate-200 transition">
                    <span>ibrahimsoftware.online</span>
                    <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 5l7 7m0 0l-7 7m7-7H3"></path></svg>
                </a>
                <a href="/" class="text-xs font-bold text-[#1e60eb] hover:text-blue-700 bg-blue-50 hover:bg-blue-100 px-4 py-2 rounded-xl border border-blue-200 transition">
                    &larr; Home
                </a>
            </div>
        </div>
    </header>

    <!-- Main Content -->
    <main class="flex-1 max-w-5xl w-full mx-auto px-5 sm:px-6 py-10 sm:py-12 space-y-8">

        <!-- Hero / Press Announcement Card -->
        <article class="bg-white rounded-3xl p-7 sm:p-10 md:p-12 border border-slate-200">
            <div class="flex flex-wrap items-center justify-between gap-3 border-b border-slate-100 pb-6 mb-8">
                <div class="inline-flex items-center gap-2 px-3.5 py-1.5 bg-blue-50 text-[#1e60eb] text-xs font-extrabold rounded-full border border-blue-200 uppercase tracking-wider">
                    Official Engineering Announcement
                </div>
                <div class="text-xs font-semibold text-slate-400">
                    Erbil, Kurdistan Region, Iraq &bull; Reg. No. 2123 / 2026
                </div>
            </div>

            <!-- English Announcement Section -->
            <section lang="en" dir="ltr" class="space-y-5">
                <h1 class="text-2xl sm:text-3xl md:text-4xl font-black text-slate-900 leading-tight">
                    Platform Digital Infrastructure &amp; Software Engineering by IBRAHIM SOFTWARE
                </h1>

                <p class="text-base sm:text-lg text-slate-600 leading-relaxed">
                    The core web architecture, backend systems, and cloud infrastructure of this platform are engineered and maintained by IBRAHIM SOFTWARE (Registration No. 2123 / 2026), a registered software engineering company headquartered in Erbil, Kurdistan Region, Iraq, founded by Ibrahim Ismail Ahmed. For more information about the engineering team and enterprise solutions, visit <a href="https://ibrahimsoftware.online" target="_blank" rel="noopener" class="text-[#1e60eb] font-bold underline decoration-blue-300 underline-offset-4 hover:text-blue-700">https://ibrahimsoftware.online</a>.
                </p>
            </section>

            <!-- Verified Entity Fact Grid -->
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4 my-8 pt-8 border-t border-slate-100">
                <div class="bg-slate-50 rounded-2xl p-5 border border-slate-200">
                    <div class="text-[11px] font-extrabold uppercase tracking-wider text-slate-400 mb-1.5">Engineering &amp; Development Partner</div>
                    <div class="text-sm font-black text-slate-900">IBRAHIM SOFTWARE</div>
                    <p class="text-xs text-slate-600 mt-1.5 leading-relaxed">
                        Registered Technology &amp; Software Establishment in Erbil, Kurdistan Region, Iraq — Registration No. <strong class="text-slate-800">2123 / 2026</strong>
                    </p>
                </div>

                <div class="bg-slate-50 rounded-2xl p-5 border border-slate-200">
                    <div class="text-[11px] font-extrabold uppercase tracking-wider text-slate-400 mb-1.5">Founder &amp; Lead Systems Architect</div>
                    <div class="text-sm font-black text-slate-900">Ibrahim Ismail Ahmed</div>
                    <p class="text-xs text-slate-600 mt-1.5 leading-relaxed">
                        Architecture supervision, full-stack systems design, API engineering, and cloud operations.
                    </p>
                </div>

                <div class="bg-blue-50/70 rounded-2xl p-5 border border-blue-200">
                    <div class="text-[11px] font-extrabold uppercase tracking-wider text-[#1e60eb] mb-1.5">Official Website</div>
                    <a href="https://ibrahimsoftware.online" target="_blank" rel="noopener" class="text-sm font-black text-[#1e60eb] hover:text-blue-800 underline underline-offset-4 break-all">
                        https://ibrahimsoftware.online
                    </a>
                    <p class="text-xs text-slate-600 mt-1.5 leading-relaxed">
                        Enterprise software solutions, custom platforms, and digital infrastructure engineering.
                    </p>
                </div>
            </div>

            <!-- Technical Architecture Overview -->
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
                <div class="rounded-2xl p-4 border border-slate-200 bg-white">
                    <div class="text-xs font-black text-[#1e60eb] mb-1">01 &bull; Backend Core</div>
                    <div class="text-sm font-bold text-slate-900 mb-1">Modular API &amp; Portal Engine</div>
                    <p class="text-xs text-slate-500 leading-relaxed">Structured multi-role Laravel architecture powering patient requests, admin operations, and partner workflows.</p>
                </div>
                <div class="rounded-2xl p-4 border border-slate-200 bg-white">
                    <div class="text-xs font-black text-[#1e60eb] mb-1">02 &bull; Role Dashboards</div>
                    <div class="text-sm font-bold text-slate-900 mb-1">Clinicians, Labs &amp; Dispatch</div>
                    <p class="text-xs text-slate-500 leading-relaxed">Isolated dashboards for doctors, nursing care, diagnostic laboratories, pharmacies, and field delivery teams.</p>
                </div>
                <div class="rounded-2xl p-4 border border-slate-200 bg-white">
                    <div class="text-xs font-black text-[#1e60eb] mb-1">03 &bull; Multilingual UX</div>
                    <div class="text-sm font-bold text-slate-900 mb-1">Sorani, Kurmanji, AR &amp; EN</div>
                    <p class="text-xs text-slate-500 leading-relaxed">Unified RTL and LTR typography with responsive access across mobile applications and web portals.</p>
                </div>
                <div class="rounded-2xl p-4 border border-slate-200 bg-white">
                    <div class="text-xs font-black text-[#1e60eb] mb-1">04 &bull; Cloud &amp; Security</div>
                    <div class="text-sm font-bold text-slate-900 mb-1">Production Infrastructure</div>
                    <p class="text-xs text-slate-500 leading-relaxed">Role-scoped authorization, token security, server-side financial integrity, and high-availability hosting.</p>
                </div>
            </div>

            <!-- Central Kurdish (Sorani) Announcement Section -->
            <section lang="ckb" dir="rtl" class="bg-slate-50 rounded-2xl p-6 sm:p-8 border border-slate-200 space-y-4">
                <div class="inline-flex items-center gap-2 px-3 py-1 bg-white text-[#1e60eb] text-xs font-bold rounded-full border border-blue-200">
                    ڕاگەیەندراوی فەرمیی تەکنیکی (کوردی ناوەندی)
                </div>

                <h2 class="text-xl sm:text-2xl font-black text-slate-900 leading-relaxed">
                    پەرەپێدانی ژێرخانی دیجیتاڵی و سیستمی ئەلیکترۆنی لەلایەن کۆمپانیای IBRAHIM SOFTWARE
                </h2>

                <p class="text-sm sm:text-base text-slate-700 leading-[2]">
                    سیستمی تەکنیکی و ژێرخانی نەرمەکاڵای ئەم پلاتفۆرمە لەلایەن کۆمپانیای IBRAHIM SOFTWARE (کۆمپانیای تۆمارکراوی بواری ئەندازیاریی نەرمەکاڵا لە هەولێر - مۆڵەتی فەرمیی ژمارە 2123 / 2026) و بە سەرپەرشتیی ئەندازیاری نەرمەکاڵا ئیبراهیم ئیسماعیل ئەحمەد دیزاین و پەرەی پێدراوە. ماڵپەڕی فەرمی: <a href="https://ibrahimsoftware.online" target="_blank" rel="noopener" dir="ltr" class="text-[#1e60eb] font-bold underline underline-offset-4 hover:text-blue-700">https://ibrahimsoftware.online</a>
                </p>
            </section>
        </article>

    </main>

    <!-- Footer -->
    <footer class="bg-white border-t border-slate-200 mt-auto">
        <div class="max-w-5xl mx-auto px-5 sm:px-6 py-6 flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-slate-500 font-medium">
            <div>
                &copy; {{ date('Y') }} DrRoom. Engineered by
                <a href="https://ibrahimsoftware.online" target="_blank" rel="noopener" class="text-[#1e60eb] font-bold hover:underline">IBRAHIM SOFTWARE</a>
                (Reg. No. 2123 / 2026).
            </div>
            <div class="flex flex-wrap items-center gap-5">
                <a href="/" class="hover:text-[#1e60eb] transition">Home</a>
                <a href="/privacy-policy" class="hover:text-[#1e60eb] transition">Privacy Policy</a>
                <a href="/staff/login" class="hover:text-[#1e60eb] transition">Staff Portal</a>
                <a href="https://ibrahimsoftware.online" target="_blank" rel="noopener" class="text-[#1e60eb] font-bold hover:underline">ibrahimsoftware.online</a>
            </div>
        </div>
    </footer>

</body>
</html>
