<!DOCTYPE html>
<html lang="ckb" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DrRoom - داشبۆردی دەرمانخانە</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <style>
        body { font-family: 'Rabar', 'Inter', sans-serif; background: #f0f2f5; margin: 0; }
        ::-webkit-scrollbar { width: 5px; }
        ::-webkit-scrollbar-track { background: transparent; }
        ::-webkit-scrollbar-thumb { background: rgba(13,148,136,0.3); border-radius: 10px; }
        ::-webkit-scrollbar-thumb:hover { background: rgba(13,148,136,0.5); }

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
            background: #f0fdfa;
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
        .nav-item.active { background: #f0fdfa; color: #0d9488; font-weight: 700; }
        .nav-item svg { width: 20px; height: 20px; flex-shrink: 0; }
        .nav-item .chevron { margin-right: auto; margin-left: 0; transition: transform 0.25s ease; }
        .nav-item .chevron.open { transform: rotate(180deg); }

        .nav-sub { padding-right: 44px; padding-left: 8px; overflow: hidden; max-height: 0; transition: max-height 0.3s ease; }
        .nav-sub.open { max-height: 300px; }
        .nav-sub a {
            display: block;
            padding: 8px 12px;
            font-size: 0.82rem;
            color: #94a3b8;
            text-decoration: none;
            border-radius: 8px;
            transition: all 0.2s ease;
            font-weight: 500;
        }
        .nav-sub a:hover { color: #1e293b; background: #f8fafc; }
        .nav-sub a.active { color: #0d9488; font-weight: 700; }

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
            color: #0d9488;
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
                    <svg fill="none" stroke="#0d9488" viewBox="0 0 24 24" width="24" height="24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"/></svg>
                </div>
                <span class="logo-text">DrRoom</span>
            </div>

            <nav>
                <div class="nav-label">سەرەکی</div>
                <a href="{{ route('pharmacy.dashboard') }}" class="nav-item {{ request()->routeIs('pharmacy.dashboard') ? 'active' : '' }}">
                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z"/></svg>
                    داشبۆرد
                </a>

                <div class="nav-label">بەڕێوەبردن</div>
                
                <a href="{{ route('pharmacy.prescriptions.index') }}" class="nav-item {{ request()->routeIs('pharmacy.prescriptions.*') ? 'active' : '' }}">
                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
                    ڕەچەتەکان
                </a>
                
                <a href="{{ route('pharmacy.orders.index') }}" class="nav-item {{ request()->routeIs('pharmacy.orders.*') ? 'active' : '' }}">
                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"/></svg>
                    داواکارییەکان
                </a>
                
                <a href="{{ route('pharmacy.medications.index') }}" class="nav-item {{ request()->routeIs('pharmacy.medications.*') ? 'active' : '' }}">
                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"/></svg>
                    دەرمانەکان (کۆگا)
                </a>

                <a href="{{ route('pharmacy.offers.index') }}" class="nav-item {{ request()->routeIs('pharmacy.offers.*') ? 'active' : '' }}">
                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v13m0-13V6a2 2 0 112 2h-2zm0 0V5.5A2.5 2.5 0 109.5 8H12zm-7 4h14M5 12a2 2 0 110-4h14a2 2 0 110 4M5 12v7a2 2 0 002 2h10a2 2 0 002-2v-7"/></svg>
                    ئۆفەرەکان
                </a>
                
                <a href="{{ route('pharmacy.customers.index') }}" class="nav-item {{ request()->routeIs('pharmacy.customers.*') ? 'active' : '' }}">
                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"/></svg>
                    کڕیارەکان
                </a>
                
                <div class="nav-label">تر</div>
                
                <a href="{{ route('pharmacy.earnings.index') }}" class="nav-item {{ request()->routeIs('pharmacy.earnings.*') ? 'active' : '' }}">
                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
                    داهات
                </a>
                
                <a href="{{ route('pharmacy.notifications.index') }}" class="nav-item {{ request()->routeIs('pharmacy.notifications.*') ? 'active' : '' }}">
                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/></svg>
                    ئاگادارکردنەوەکان
                </a>
                
                <a href="{{ route('pharmacy.profile.index') }}" class="nav-item {{ request()->routeIs('pharmacy.profile.*') ? 'active' : '' }}">
                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/></svg>
                    پرۆفایل
                </a>
                
                <a href="{{ route('pharmacy.settings.index') }}" class="nav-item {{ request()->routeIs('pharmacy.settings.*') ? 'active' : '' }}">
                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/></svg>
                    ڕێکخستنەکان
                </a>
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

            let openMenu = null;
            function toggleNav(name) {
                const sub = document.getElementById('sub-' + name);
                const chev = document.getElementById('chevron-' + name);
                if (openMenu && openMenu !== name) {
                    const prevSub = document.getElementById('sub-' + openMenu);
                    const prevChev = document.getElementById('chevron-' + openMenu);
                    if (prevSub) prevSub.classList.remove('open');
                    if (prevChev) prevChev.classList.remove('open');
                }
                if (sub.classList.contains('open')) {
                    sub.classList.remove('open');
                    if (chev) chev.classList.remove('open');
                    openMenu = null;
                } else {
                    sub.classList.add('open');
                    if (chev) chev.classList.add('open');
                    openMenu = name;
                }
            }

            // Auto-open the active submenu
            document.addEventListener('DOMContentLoaded', function() {
                const url = window.location.href.split('?')[0];
                document.querySelectorAll('.nav-sub a').forEach(link => {
                    if (link.href && link.href.split('?')[0] === url) {
                        link.classList.add('active');
                        const sub = link.closest('.nav-sub');
                        if (sub) {
                            sub.classList.add('open');
                            const id = sub.id.replace('sub-', '');
                            const chev = document.getElementById('chevron-' + id);
                            if (chev) chev.classList.add('open');
                            openMenu = id;
                        }
                    }
                });

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
            <div style="position:absolute;top:-20%;right:-10%;width:50%;height:50%;border-radius:50%;background:rgba(13,148,136,0.06);filter:blur(80px);pointer-events:none;"></div>
            <div style="position:absolute;bottom:-20%;left:-10%;width:40%;height:60%;border-radius:50%;background:rgba(79,70,229,0.06);filter:blur(80px);pointer-events:none;"></div>
            <div style="width:100%;max-width:1200px;margin:0 auto;position:relative;z-index:1;">
                @yield('content')
            </div>
        </main>
    @endif
</body>
</html>
