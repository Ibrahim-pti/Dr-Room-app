@php
    $doctor = Auth::user()->doctor;
    $isProfileComplete = $doctor && $doctor->specialty && $doctor->bio ;
    $hasServices = $doctor && $doctor->services()->exists();
    $hasSchedules = $doctor && $doctor->schedules()->exists();
    $isSetupComplete = $isProfileComplete && $hasServices && $hasSchedules;
@endphp
<!DOCTYPE html>
<html lang="ckb" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DrRoom - داشبۆردی دکتۆر</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <style>
        body { font-family: 'Rabar', 'Inter', sans-serif; background: #f0f2f5; margin: 0; }
        ::-webkit-scrollbar { width: 5px; }
        ::-webkit-scrollbar-track { background: transparent; }
        ::-webkit-scrollbar-thumb { background: rgba(99,102,241,0.3); border-radius: 10px; }
        ::-webkit-scrollbar-thumb:hover { background: rgba(99,102,241,0.5); }

        /* Sidebar */
        .dr-sidebar {
            position: fixed;
            top: 0;
            right: 0;
            width: 270px;
            height: 100vh;
            background: #ffffff;
            border-left: 1px solid #e2e8f0;
            z-index: 50;
            display: flex;
            flex-direction: column;
            transition: transform 0.35s cubic-bezier(0.4, 0, 0.2, 1);
            overflow: hidden;
        }
        .dr-sidebar.collapsed { transform: translateX(100%); }

        .dr-sidebar .logo-area {
            padding: 24px 20px;
            display: flex;
            align-items: center;
            gap: 12px;
            border-bottom: 1px solid #f1f5f9;
        }
        .dr-sidebar .logo-icon {
            width: 42px; height: 42px;
            background: #eef2ff;
            border-radius: 12px;
            display: flex; align-items: center; justify-content: center;
        }
        .dr-sidebar .logo-text {
            font-size: 1.4rem;
            font-weight: 800;
            color: #1e293b;
            letter-spacing: -0.02em;
        }

        .dr-sidebar nav { flex: 1; overflow-y: auto; padding: 16px 12px; }
        .dr-sidebar nav::-webkit-scrollbar { width: 3px; }
        .dr-sidebar nav::-webkit-scrollbar-thumb { background: #e2e8f0; border-radius: 10px; }

        .nav-item {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 11px 14px;
            border-radius: 10px;
            color: #64748b;
            font-weight: 600;
            font-size: 0.88rem;
            cursor: pointer;
            transition: all 0.2s ease;
            text-decoration: none;
            border: none;
            background: none;
            width: 100%;
            text-align: right;
        }
        .nav-item:hover { background: #f8fafc; color: #1e293b; }
        .nav-item.active { background: #eef2ff; color: #4f46e5; font-weight: 700; }
        .nav-item svg { width: 20px; height: 20px; flex-shrink: 0; }


        .nav-label {
            font-size: 0.7rem;
            font-weight: 700;
            color: #cbd5e1;
            text-transform: uppercase;
            letter-spacing: 0.08em;
            padding: 16px 14px 6px;
        }

        .sidebar-footer {
            padding: 16px;
            border-top: 1px solid #f1f5f9;
        }
        .logout-btn {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 11px 14px;
            border-radius: 10px;
            color: #fca5a5;
            font-weight: 600;
            font-size: 0.88rem;
            cursor: pointer;
            transition: all 0.2s ease;
            border: none;
            background: none;
            width: 100%;
            text-align: right;
        }
        .logout-btn:hover { background: rgba(239,68,68,0.12); color: #fecaca; }
        .logout-btn svg { width: 20px; height: 20px; }

        /* Overlay */
        .sidebar-overlay {
            position: fixed; inset: 0;
            background: rgba(15,23,42,0.5);
            backdrop-filter: blur(4px);
            z-index: 40;
            opacity: 0;
            pointer-events: none;
            transition: opacity 0.3s ease;
        }
        .sidebar-overlay.show { opacity: 1; pointer-events: auto; }

        /* Main */
        .dr-main {
            margin-right: 270px;
            min-height: 100vh;
            transition: margin-right 0.35s cubic-bezier(0.4, 0, 0.2, 1);
        }
        .dr-header {
            position: sticky;
            top: 0;
            z-index: 30;
            height: 68px;
            background: rgba(255,255,255,0.85);
            backdrop-filter: blur(16px);
            -webkit-backdrop-filter: blur(16px);
            border-bottom: 1px solid rgba(0,0,0,0.04);
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 0 24px;
        }
        .dr-header .menu-btn {
            display: none;
            width: 40px; height: 40px;
            border-radius: 10px;
            border: none;
            background: #f1f5f9;
            color: #64748b;
            cursor: pointer;
            align-items: center;
            justify-content: center;
            transition: all 0.2s ease;
        }
        .dr-header .menu-btn:hover { background: #e2e8f0; color: #334155; }
        .dr-header .menu-btn svg { width: 22px; height: 22px; }

        .header-profile {
            display: flex;
            align-items: center;
            gap: 12px;
        }
        .header-profile .info { text-align: right; }
        .header-profile .info .name { font-size: 0.88rem; font-weight: 700; color: #1e293b; }
        .header-profile .info .role { font-size: 0.75rem; color: #94a3b8; font-weight: 500; }
        .header-profile .avatar {
            width: 40px; height: 40px;
            border-radius: 50%;
            background: linear-gradient(135deg, #dbeafe, #e0e7ff);
            display: flex; align-items: center; justify-content: center;
            font-weight: 700;
            color: #4f46e5;
            font-size: 1rem;
            overflow: hidden;
            border: 2px solid #fff;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
        }
        .header-profile .avatar img { width: 100%; height: 100%; object-fit: cover; }

        .notif-btn {
            position: relative;
            width: 40px; height: 40px;
            border-radius: 50%;
            border: none;
            background: #f8fafc;
            color: #94a3b8;
            cursor: pointer;
            display: flex; align-items: center; justify-content: center;
            transition: all 0.2s ease;
        }
        .notif-btn:hover { background: #f1f5f9; color: #64748b; }
        .notif-btn svg { width: 22px; height: 22px; }
        .notif-btn .dot {
            position: absolute; top: 8px; right: 8px;
            width: 8px; height: 8px;
            background: #ef4444;
            border-radius: 50%;
            border: 2px solid #fff;
        }

        .dr-content { padding: 24px; max-width: 1280px; margin: 0 auto; }

        /* Responsive */
        @media (max-width: 1023px) {
            .dr-sidebar { transform: translateX(100%); }
            .dr-sidebar.open { transform: translateX(0); }
            .dr-main { margin-right: 0; }
            .dr-header .menu-btn { display: flex; }
            .header-profile .info { display: none; }
        }
        @media (max-width: 639px) {
            .dr-content { padding: 16px; }
            .dr-header { padding: 0 16px; height: 60px; }
        }

        /* Animations */
        @keyframes fadeUp { from { opacity: 0; transform: translateY(12px); } to { opacity: 1; transform: translateY(0); } }
        .fade-up { animation: fadeUp 0.5s ease forwards; }
    </style>
</head>
<body>

    @if(!request()->routeIs('staff.login') && !request()->routeIs('staff.register'))
        <!-- Overlay -->
        <div class="sidebar-overlay" id="sidebarOverlay" onclick="closeSidebar()"></div>

        <!-- Sidebar -->
        <aside class="dr-sidebar" id="sidebar">
            <div class="logo-area">
                <div class="logo-icon">
                    <svg fill="none" stroke="#4f46e5" viewBox="0 0 24 24" width="24" height="24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"/></svg>
                </div>
                <span class="logo-text">DrRoom</span>
            </div>

            <nav>
                @if(!$isSetupComplete)
                    <div class="nav-label" style="color: #3b82f6; background: #eff6ff; padding: 12px; border-radius: 8px; line-height: 1.6; margin-bottom: 16px; font-size: 0.85rem;">
                        <strong>بەخێربێیت!</strong><br>
                        تکایە سەرەتا ئەم هەنگاوانە تەواو بکە بۆ ئەوەی داشبۆرد بکرێتەوە.
                    </div>
                @else

                <div class="nav-label">سەرەکی</div>

                <!-- Dashboard -->
                <a href="{{ route('doctor.dashboard') }}" class="nav-item {{ request()->routeIs('doctor.dashboard') ? 'active' : '' }}">
                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z"/></svg>
                    داشبۆرد
                </a>

                <div class="nav-label">بەڕێوەبردن</div>

                <!-- Appointments -->
                <a href="{{ route('doctor.appointments.index') }}" class="nav-item {{ request()->routeIs('doctor.appointments.*') ? 'active' : '' }}">
                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
                    چاوپێکەوتنەکان
                </a>

                <!-- Patients -->
                <a href="{{ route('doctor.patients.index') }}" class="nav-item {{ request()->routeIs('doctor.patients.*') ? 'active' : '' }}">
                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"/></svg>
                    نەخۆشەکان
                </a>

                <!-- Earnings -->
                <a href="{{ route('doctor.earnings.index') }}" class="nav-item {{ request()->routeIs('doctor.earnings.*') ? 'active' : '' }}">
                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                    داهات
                </a>

                @endif

                <!-- Profile -->
                <a href="{{ route('doctor.profile.index') }}" class="nav-item {{ request()->routeIs('doctor.profile.*') ? 'active' : '' }}">
                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/></svg>
                    @if(!$isSetupComplete) ١. زانیارییەکان @else پرۆفایل @endif
                </a>

                <!-- Services -->
                <a href="{{ route('doctor.services.index') }}" class="nav-item {{ request()->routeIs('doctor.services.*') ? 'active' : '' }}">
                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"/></svg>
                    @if(!$isSetupComplete) ٢. خزمەتگوزارییەکان @else خزمەتگوزارییەکان @endif
                </a>

                <!-- Schedules -->
                <a href="{{ route('doctor.schedules.index') }}" class="nav-item {{ request()->routeIs('doctor.schedules.*') ? 'active' : '' }}">
                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                    @if(!$isSetupComplete) ٣. خشتەی کارکردن @else خشتەی کارکردن @endif
                </a>

                @if($isSetupComplete)
                <!-- Reviews -->
                <a href="{{ route('doctor.reviews.index') }}" class="nav-item {{ request()->routeIs('doctor.reviews.*') ? 'active' : '' }}">
                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.196-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.783-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z"/></svg>
                    هەڵسەنگاندنەکان
                </a>
                @endif
            </nav>

            <div class="sidebar-footer">
                <form method="POST" action="{{ route('staff.logout') }}">
                    @csrf
                    <button type="submit" class="logout-btn">
                        <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"/></svg>
                        چوونەدەرەوە
                    </button>
                </form>
            </div>
        </aside>

        <!-- Main -->
        <div class="dr-main" id="mainArea">
            <header class="dr-header">
                <div style="display:flex;align-items:center;gap:12px;">
                    <button class="menu-btn" id="menuBtn" onclick="toggleSidebar()">
                        <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"/></svg>
                    </button>
                    <div style="display:none;" id="mobileLogo" class="mobile-logo">
                        <span style="font-size:1.15rem;font-weight:800;color:#1e293b;">DrRoom</span>
                    </div>
                </div>

                <div class="header-profile">
                    <button class="notif-btn">
                        <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/></svg>
                        <span class="dot"></span>
                    </button>
                    <div class="info">
                        <div class="name">دکتۆر {{ explode(' ', Auth::user()->name)[0] }}</div>
                        <div class="role">{{ Auth::user()->doctor->specialty ?? 'پزیشکی گشتی' }}</div>
                    </div>
                    <div class="avatar">
                        @if(Auth::user()->doctor && Auth::user()->doctor->profile_image)
                            <img src="{{ asset('storage/' . Auth::user()->doctor->profile_image) }}" alt="Profile">
                        @else
                            {{ mb_substr(Auth::user()->name, 0, 1) }}
                        @endif
                    </div>
                </div>
            </header>

            <main class="dr-content">
                @yield('content')
            </main>
        </div>

        <script>
            function toggleSidebar() {
                const sidebar = document.getElementById('sidebar');
                const overlay = document.getElementById('sidebarOverlay');
                if (sidebar.classList.contains('open')) {
                    closeSidebar();
                } else {
                    sidebar.classList.add('open');
                    overlay.classList.add('show');
                }
            }
            function closeSidebar() {
                document.getElementById('sidebar').classList.remove('open');
                document.getElementById('sidebarOverlay').classList.remove('show');
            }

            document.addEventListener('DOMContentLoaded', function() {
                // Mobile logo
                if (window.innerWidth < 1024) {
                    document.getElementById('mobileLogo').style.display = 'block';
                }
                window.addEventListener('resize', () => {
                    document.getElementById('mobileLogo').style.display = window.innerWidth < 1024 ? 'block' : 'none';
                    if (window.innerWidth >= 1024) closeSidebar();
                });
            });
        </script>
    @else
        <main style="min-height:100vh;display:flex;align-items:center;justify-content:center;background:#f0f2f5;padding:16px;position:relative;overflow:hidden;">
            <div style="position:absolute;top:-20%;right:-10%;width:50%;height:50%;border-radius:50%;background:rgba(99,102,241,0.06);filter:blur(80px);pointer-events:none;"></div>
            <div style="position:absolute;bottom:-20%;left:-10%;width:40%;height:60%;border-radius:50%;background:rgba(79,70,229,0.06);filter:blur(80px);pointer-events:none;"></div>
            <div style="width:100%;max-width:1200px;margin:0 auto;position:relative;z-index:1;">
                @yield('content')
            </div>
        </main>
    @endif
</body>
</html>
