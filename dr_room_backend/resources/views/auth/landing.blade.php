<!DOCTYPE html>
<html lang="ckb" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DrRoom - سەکۆی ستافی تەندروستی</title>
    <link href="https://fonts.googleapis.com/css2?family=Noto+Kufi+Arabic:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Noto Kufi Arabic', sans-serif; }
        html { scroll-behavior: smooth; }
        body { 
            background: #f8fafc; 
            min-height: 100vh; 
            overflow-x: hidden; 
            color: #0f172a;
        }

        /* === NAVBAR === */
        .navbar {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 16px 40px;
            background: #ffffff;
            box-shadow: 0 4px 20px rgba(0,0,0,0.03);
            position: sticky;
            top: 0;
            z-index: 100;
        }
        
        .nav-brand { display: flex; align-items: center; gap: 12px; text-decoration: none; }
        .nav-brand svg { color: #2563EB; width: 32px; height: 32px; }
        .nav-brand h2 { font-size: 22px; font-weight: 800; color: #0f172a; direction: ltr; margin: 0; }
        
        .nav-links { display: flex; gap: 32px; align-items: center; }
        .nav-links a { text-decoration: none; color: #475569; font-weight: 600; font-size: 15px; transition: color 0.2s; }
        .nav-links a:hover { color: #2563EB; }
        
        .nav-auth { display: flex; gap: 12px; align-items: center; }
        .btn-nav-login { text-decoration: none; color: #334155; font-weight: 700; font-size: 14px; padding: 10px 20px; border-radius: 10px; transition: background 0.2s; }
        .btn-nav-login:hover { background: #f1f5f9; }
        .btn-nav-register { text-decoration: none; color: #fff; background: #2563EB; font-weight: 700; font-size: 14px; padding: 10px 24px; border-radius: 10px; box-shadow: 0 4px 12px rgba(37,99,235,0.2); transition: background 0.2s; }
        .btn-nav-register:hover { background: #1D4ED8; }

        .hamburger { display: none; background: none; border: none; color: #334155; cursor: pointer; padding: 8px; }
        .hamburger svg { width: 28px; height: 28px; }

        /* === MOBILE SIDEBAR === */
        .sidebar-overlay {
            position: fixed; top: 0; left: 0; width: 100%; height: 100%;
            background: rgba(15, 23, 42, 0.4); backdrop-filter: blur(4px);
            z-index: 1000; opacity: 0; visibility: hidden; transition: 0.3s;
        }
        .sidebar {
            position: fixed; top: 0; right: -300px; width: 280px; height: 100%;
            background: #ffffff; z-index: 1001;
            box-shadow: -5px 0 25px rgba(0,0,0,0.1);
            display: flex; flex-direction: column;
            transition: 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        }
        
        .sidebar.active { right: 0; }
        .sidebar-overlay.active { opacity: 1; visibility: visible; }
        
        .sidebar-header {
            padding: 20px 24px; border-bottom: 1px solid #f1f5f9;
            display: flex; justify-content: space-between; align-items: center;
        }
        .btn-close { background: #f1f5f9; border: none; width: 36px; height: 36px; border-radius: 50%; display: flex; align-items: center; justify-content: center; color: #64748b; cursor: pointer; transition: 0.2s; }
        .btn-close:hover { background: #e2e8f0; color: #0f172a; }
        
        .sidebar-links { padding: 24px; display: flex; flex-direction: column; gap: 8px; flex: 1; }
        .sidebar-links a { 
            text-decoration: none; color: #334155; font-size: 15px; font-weight: 600; 
            display: flex; align-items: center; gap: 12px; padding: 12px 16px; border-radius: 12px; transition: 0.2s;
        }
        .sidebar-links a:hover { background: #EFF6FF; color: #2563EB; }
        .sidebar-links a svg { width: 20px; height: 20px; color: #94a3b8; }
        .sidebar-links a:hover svg { color: #2563EB; }
        
        .sidebar-footer { padding: 24px; border-top: 1px solid #f1f5f9; display: flex; flex-direction: column; gap: 12px; }

        @media (max-width: 992px) {
            .nav-links, .nav-auth { display: none; }
            .hamburger { display: block; }
            .navbar { padding: 16px 20px; }
        }

        /* === SPLIT LAYOUT === */
        .hero-section { padding: 40px 16px; display: flex; justify-content: center; }

        .split-layout { 
            display: flex; width: 100%; max-width: 1200px; 
            background: #ffffff; border-radius: 24px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.04); overflow: hidden;
        }
        
        .right-side { width: 55%; padding: 60px 40px; display: flex; flex-direction: column; }
        .right-content { flex: 1; display: flex; flex-direction: column; justify-content: center; max-width: 480px; margin: 0 auto; width: 100%; }

        .badge {
            display: inline-flex; align-items: center; gap: 8px; padding: 6px 12px;
            background: #EFF6FF; color: #2563EB; border-radius: 20px; font-size: 13px; font-weight: 600; margin-bottom: 24px; width: fit-content;
        }

        h1 { font-size: 36px; font-weight: 800; color: #0f172a; margin-bottom: 20px; line-height: 1.4; }
        h1 span { color: #2563EB; }
        .subtitle { font-size: 15px; color: #64748b; margin-bottom: 30px; line-height: 1.8; }

        .features { margin-bottom: 40px; display: flex; flex-direction: column; gap: 20px; }
        .feature-item { display: flex; align-items: flex-start; gap: 12px; }
        .feature-icon { 
            width: 28px; height: 28px; color: #2563EB; flex-shrink: 0;
            background: #EFF6FF; border-radius: 8px; padding: 5px;
        }
        .feature-text { color: #1e293b; font-size: 15px; font-weight: 700; line-height: 1.5; }
        .feature-subtext { color: #64748b; font-size: 13px; font-weight: 500; margin-top: 4px; }

        .buttons-group { display: flex; gap: 16px; }
        .btn-primary {
            flex: 1; padding: 16px; text-align: center; background: #2563EB; color: #fff;
            border: none; border-radius: 12px; text-decoration: none; font-size: 15px; font-weight: 700; transition: 0.2s;
        }
        .btn-primary:hover { background: #1D4ED8; }
        .btn-secondary {
            flex: 1; padding: 16px; text-align: center; background: #fff; color: #334155; 
            border: 1.5px solid #e2e8f0; border-radius: 12px; text-decoration: none; font-size: 15px; font-weight: 700; transition: 0.2s;
        }
        .btn-secondary:hover { background: #f8fafc; border-color: #cbd5e1; }

        .secure-footer { display: flex; justify-content: center; align-items: center; gap: 8px; color: #94a3b8; font-size: 13px; font-weight: 600; margin-top: 40px; }

        /* Left side image */
        .left-side { width: 45%; background: #EFF6FF; position: relative; overflow: hidden; padding: 40px; display: flex; align-items: center; justify-content: center; }
        .image-composition { position: relative; width: 100%; height: 100%; min-height: 500px; display: flex; align-items: center; justify-content: center; }
        .img-main { width: 85%; height: 85%; object-fit: cover; border-radius: 24px; box-shadow: 0 20px 40px rgba(37, 99, 235, 0.15); z-index: 2; border: 8px solid #ffffff; }
        .img-bg-shape { position: absolute; width: 100%; height: 100%; background: linear-gradient(135deg, #2563EB 0%, #60A5FA 100%); border-radius: 32px; transform: rotate(-4deg); z-index: 1; opacity: 0.15; }

        /* === SECTIONS === */
        .content-section { max-width: 1200px; margin: 0 auto 80px auto; padding: 0 24px; scroll-margin-top: 100px; }
        .section-header { text-align: center; margin-bottom: 48px; }
        .section-header h2 { font-size: 32px; font-weight: 800; color: #0f172a; margin-bottom: 16px; }
        .section-header p { font-size: 16px; color: #64748b; max-width: 700px; margin: 0 auto; line-height: 1.8; }

        .benefits-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 24px; }
        .benefit-card { background: #ffffff; border-radius: 20px; padding: 32px; border: 1px solid #e2e8f0; transition: 0.3s; }
        .benefit-card:hover { transform: translateY(-5px); box-shadow: 0 20px 40px rgba(37,99,235,0.08); border-color: #bfdbfe; }
        .b-icon { width: 56px; height: 56px; border-radius: 16px; background: #EFF6FF; color: #2563EB; display: flex; align-items: center; justify-content: center; margin-bottom: 24px; }
        .b-icon svg { width: 28px; height: 28px; }
        .benefit-card h3 { font-size: 18px; font-weight: 700; color: #0f172a; margin-bottom: 12px; }
        .benefit-card p { font-size: 14px; color: #64748b; line-height: 1.7; }

        /* Download Section */
        .download-section { background: linear-gradient(135deg, #1e40af 0%, #2563eb 100%); border-radius: 32px; padding: 60px; display: flex; align-items: center; justify-content: space-between; color: #ffffff; position: relative; overflow: hidden; }
        .dl-circle { position: absolute; border-radius: 50%; background: rgba(255,255,255,0.1); }
        .download-content { max-width: 500px; position: relative; z-index: 10; }
        .download-content h2 { font-size: 36px; font-weight: 800; margin-bottom: 20px; line-height: 1.3; }
        .download-content p { font-size: 16px; color: rgba(255,255,255,0.9); margin-bottom: 32px; line-height: 1.8; }
        .store-buttons { display: flex; gap: 16px; }
        .store-btn { background: #000000; color: #ffffff; padding: 12px 24px; border-radius: 12px; display: flex; align-items: center; gap: 12px; text-decoration: none; transition: 0.2s; }
        .store-btn:hover { transform: translateY(-3px); }
        .store-btn svg { width: 28px; height: 28px; }
        .store-text span { display: block; font-size: 10px; color: #a1a1aa; font-family: sans-serif; }
        .store-text strong { display: block; font-size: 16px; font-weight: 600; font-family: sans-serif; }
        .download-image { position: relative; z-index: 10; width: 40%; display: flex; justify-content: center; }

        /* Footer */
        .site-footer {
            background: #ffffff;
            padding: 40px 24px;
            text-align: center;
            border-top: 1px solid #e2e8f0;
            margin-top: 60px;
        }
        .site-footer p { color: #64748b; font-size: 14px; margin-bottom: 16px; }
        .footer-links { display: flex; justify-content: center; gap: 24px; margin-bottom: 24px; }
        .footer-links a { text-decoration: none; color: #334155; font-size: 14px; font-weight: 600; transition: color 0.2s; }
        .footer-links a:hover { color: #2563EB; }

        @media (max-width: 992px) {
            .right-side { padding: 40px 30px; width: 55%; }
            .left-side { width: 45%; padding: 20px; }
            .benefits-grid { grid-template-columns: repeat(2, 1fr); }
            .download-section { flex-direction: column; text-align: center; padding: 40px; }
            .download-content { margin-bottom: 40px; }
            .store-buttons { justify-content: center; }
            .download-image { width: 80%; }
        }

        @media (max-width: 768px) {
            h1 { font-size: 28px; }
            .split-layout { border-radius: 20px; flex-direction: column-reverse; }
            .right-side { width: 100%; padding: 30px 20px; }
            .left-side { width: 100%; height: 350px; padding: 20px; flex: none; }
            .image-composition { min-height: auto; }
            .benefits-grid { grid-template-columns: 1fr; }
            .store-buttons { flex-direction: column; }
            .download-section h2 { font-size: 28px; }
            .buttons-group { flex-direction: column; }
            .hero-section { scroll-margin-top: 80px; }
        }
    </style>
</head>
<body>

    <!-- NAVBAR -->
    <header class="navbar">
        <a href="#home" class="nav-brand">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"></path>
                <line x1="12" y1="9" x2="12" y2="15"></line>
                <line x1="9" y1="12" x2="15" y2="12"></line>
            </svg>
            <h2>DrRoom</h2>
        </a>

        <div class="nav-links">
            <a href="#home">سەرەکی</a>
            <a href="#about">دەربارە</a>
            <a href="#features">تایبەتمەندییەکان</a>
            <a href="#contact">پەیوەندی</a>
        </div>

        <div class="nav-auth">
            <a href="{{ route('staff.login') }}" class="btn-nav-login">چوونەژوورەوە</a>
            <a href="{{ route('staff.register') }}" class="btn-nav-register">دروستکردنی هەژمار</a>
        </div>

        <button class="hamburger" id="hamburgerBtn">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16M4 12h16M4 18h16"></path>
            </svg>
        </button>
    </header>

    <!-- MOBILE SIDEBAR -->
    <div class="sidebar-overlay" id="sidebarOverlay"></div>
    <aside class="sidebar" id="sidebar">
        <div class="sidebar-header">
            <div class="nav-brand">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"></path>
                    <line x1="12" y1="9" x2="12" y2="15"></line>
                    <line x1="9" y1="12" x2="15" y2="12"></line>
                </svg>
                <h2>DrRoom</h2>
            </div>
            <button class="btn-close" id="closeSidebarBtn">
                <svg width="24" height="24" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"></path>
                </svg>
            </button>
        </div>
        
        <div class="sidebar-links">
            <a href="#home">
                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"></path></svg>
                سەرەکی
            </a>
            <a href="#about">
                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                دەربارە
            </a>
            <a href="#features">
                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z"></path></svg>
                تایبەتمەندییەکان
            </a>
            <a href="#contact">
                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"></path></svg>
                پەیوەندی
            </a>
        </div>
        
        <div class="sidebar-footer">
            <a href="{{ route('staff.login') }}" class="btn-secondary text-center">چوونەژوورەوە</a>
            <a href="{{ route('staff.register') }}" class="btn-primary text-center">دروستکردنی هەژمار</a>
        </div>
    </aside>

    <!-- HERO SECTION -->
    <div class="hero-section" id="home">
        <div class="split-layout">
            <!-- Right Content -->
            <div class="right-side">
                <div class="right-content">
                    <div class="badge">
                        <svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M13 10V3L4 14h7v7l9-11h-7z"></path></svg>
                        سەکۆی فەرمی ستاف
                    </div>

                    <h1>بەڕێوەبردنی کارەکانت <br> بە شێوەیەکی <span>زیرەکتر</span></h1>
                    
                    <p class="subtitle">
                        پۆڕتاڵی تایبەتی دکتۆر ڕووم بۆ پزیشکان، پەرستاران، وە تاقیگەکان. لە یەک جێگەوە نەخۆشەکانت ببینە، ڕەچەتە بنووسە و کارەکانت بەڕێوەببە.
                    </p>

                    <div class="features">
                        <div class="feature-item">
                            <svg class="feature-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path></svg>
                            <div>
                                <div class="feature-text">سیستەمی ڕەچەتەی ئەلیکترۆنی زیرەک</div>
                                <div class="feature-subtext">ناردنی دەرمان بۆ دەرمانخانە بەبێ کاغەز.</div>
                            </div>
                        </div>
                        <div class="feature-item">
                            <svg class="feature-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M10 6H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V8a2 2 0 00-2-2h-5m-4 0V5a2 2 0 114 0v1m-4 0a2 2 0 104 0m-5 8a2 2 0 100-4 2 2 0 000 4zm0 0c1.306 0 2.417.835 2.83 2M9 14a3.001 3.001 0 00-2.83 2M15 11h3m-3 4h2"></path></svg>
                            <div>
                                <div class="feature-text">مەلەفی دیجیتاڵی گشتگیر بۆ نەخۆشەکان</div>
                                <div class="feature-subtext">بینینی مێژووی نەخۆش بە تەواوی زانیارییەکانەوە.</div>
                            </div>
                        </div>
                        <div class="feature-item">
                            <svg class="feature-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"></path></svg>
                            <div>
                                <div class="feature-text">بەستنەوەی ڕاستەوخۆ بە تاقیگەکانەوە</div>
                                <div class="feature-subtext">داواکردن و وەرگرتنەوەی ئەنجامی پشکنین دەستبەجێ.</div>
                            </div>
                        </div>
                    </div>

                </div>
            </div>

            <!-- Left Image -->
            <div class="left-side">
                <div class="image-composition">
                    <div class="img-bg-shape"></div>
                    <img src="https://plus.unsplash.com/premium_photo-1681842883882-b5c1c9f37869?q=80&w=2081&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D" alt="Medical Team" class="img-main">
                </div>
            </div>
            
        </div>
    </div>

    <!-- WHY DOCTORS SHOULD USE THIS PORTAL -->
    <div class="content-section" id="features">
        <div class="section-header">
            <h2>بۆچی پزیشکان پێویستە ئەم وێبسایتە بەکاربهێنن؟</h2>
            <p>دکتۆر ڕووم تەنها ئەپڵیکەیشنێکی مۆبایل نییە بۆ نەخۆشەکان، بەڵکو سیستەمێکی کارگێڕی (Management System) تەواوە بۆ پزیشکان.</p>
        </div>

        <div class="benefits-grid">
            <div class="benefit-card">
                <div class="b-icon">
                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path></svg>
                </div>
                <h3>بەڕێوەبردنی گشتگیر</h3>
                <p>تەواوی کارەکانی کلینیکەکەت لە یەک سەکۆی پێشکەوتوودا کۆکراوەتەوە، لە تۆمارکردنی نەخۆشەوە تا نووسینی ڕەچەتە بە شێوازێکی زیرەک.</p>
            </div>
            
            <div class="benefit-card">
                <div class="b-icon">
                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"></path></svg>
                </div>
                <h3>بەڕێوەبردنی ستافەکەت</h3>
                <p>لە ڕێگەی ئەم وێبسایتەوە دەتوانیت ڕۆڵی پەرستار و تاقیگەکان دیاری بکەیت و چاودێری ئیشەکانیان بکەیت لە یەک جێگەوە.</p>
            </div>

            <div class="benefit-card">
                <div class="b-icon">
                    <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path></svg>
                </div>
                <h3>ڕاپۆرت و ئاماری ڕۆژانە</h3>
                <p>زانیاری تەواو و گرافیک دەربارەی ژمارەی نەخۆشەکانت و کارەکانی ڕۆژانەت دەستبکەوێت بۆ بەرەوپێشبردنی کلینیکەکەت.</p>
            </div>
        </div>
    </div>

    <!-- DOWNLOAD APP SECTION -->
    <div class="content-section" id="about">
        <div class="download-section">
            <div class="dl-circle w-64 h-64 -top-32 -right-32"></div>
            <div class="dl-circle w-96 h-96 -bottom-48 -left-20 opacity-50"></div>
            
            <div class="download-content">
                <h2>ئەپڵیکەیشنی دکتۆر ڕووم بۆ نەخۆشەکان</h2>
                <p>ئەپڵیکەیشنەکەمان بەردەستە بۆ نەخۆشەکان تاوەکو بتوانن بە ئاسانی سەرە بگرن لەلای پزیشکەکان، ئەنجامی پشکنینەکانیان ببینن، و بەردەوام ئاگاداری تەندروستیان بن.</p>
                
                <div class="store-buttons">
                    <a href="#" class="store-btn">
                        <svg viewBox="0 0 384 512" fill="currentColor"><path d="M318.7 268.7c-.2-36.7 16.4-64.4 50-84.8-18.8-26.9-47.2-41.7-84.7-44.6-35.5-2.8-74.3 20.7-88.5 20.7-15 0-49.4-19.7-76.4-19.7C63.3 141.2 4 184.8 4 273.5q0 39.3 14.4 81.2c12.8 36.7 59 126.7 107.2 125.2 25.2-.6 43-17.9 75.8-17.9 31.8 0 48.3 17.9 76.4 17.3 48.6-.7 90.4-82.5 102.6-119.3-65.2-30.7-61.7-90-61.7-91.3zM34.4 46.2c31.3 41.5 86.8 35.8 86.8 35.8-5.7-50 36.5-93.5 36.5-93.5-31 .3-82.8 45.4-82.8 45.4-5.8 50 36.6 93.6 36.6 93.6-31.2-.3-82.9-45.5-82.9-45.5C33 83.4 34.4 46.2 34.4 46.2zM218.4 82.5c-30.7-.7-59.7-22.1-59.7-22.1s-5.8 50 36.6 93.6c31.2-.3 82.9-45.5 82.9-45.5s-5.7-50 36.5-93.5c-31 .3-82.8 45.4-82.8 45.4z"/></svg>
                        <div class="store-text">
                            <span>Download on the</span>
                            <strong>App Store</strong>
                        </div>
                    </a>
                    
                    <a href="#" class="store-btn">
                        <svg viewBox="0 0 512 512" fill="currentColor"><path d="M325.3 234.3L104.6 13l280.8 161.2-60.1 60.1zM47 0C34 6.8 25.3 19.2 25.3 35.3v441.3c0 16.1 8.7 28.5 21.7 35.3l256.6-256L47 0zm425.2 225.6l-58.9-34.1-65.7 64.5 65.7 64.5 60.1-34.1c18-14.3 18-46.5-1.2-60.8zM104.6 499l280.8-161.2-60.1-60.1L104.6 499z"/></svg>
                        <div class="store-text">
                            <span>GET IT ON</span>
                            <strong>Google Play</strong>
                        </div>
                    </a>
                </div>
            </div>
            
            <div class="download-image">
                <img src="https://images.unsplash.com/photo-1512428559087-560fa5ceab42?q=80&w=600&auto=format&fit=crop" alt="Mobile App" style="border-radius: 30px; border: 6px solid rgba(255,255,255,0.2); box-shadow: 0 20px 40px rgba(0,0,0,0.2); transform: rotate(5deg); max-width: 250px;">
            </div>
        </div>
    </div>

    <!-- FOOTER / CONTACT SECTION -->
    <footer class="site-footer" id="contact">
        <div class="footer-links">
            <a href="#home">سەرەکی</a>
            <a href="#about">دەربارە</a>
            <a href="#features">تایبەتمەندییەکان</a>
        </div>
        <p>پەیوەندیمان پێوە بکە بۆ پرسیارەکانت: 07501234567 | info@drroom.app</p>
        <p>&copy; 2026 DrRoom. هەموو مافێک پارێزراوە.</p>
    </footer>

    <!-- Scripts -->
    <script>
        const hamburgerBtn = document.getElementById('hamburgerBtn');
        const closeSidebarBtn = document.getElementById('closeSidebarBtn');
        const sidebar = document.getElementById('sidebar');
        const sidebarOverlay = document.getElementById('sidebarOverlay');
        const sidebarLinks = document.querySelectorAll('.sidebar-links a');

        function toggleSidebar() {
            sidebar.classList.toggle('active');
            sidebarOverlay.classList.toggle('active');
            
            if(sidebar.classList.contains('active')) {
                document.body.style.overflow = 'hidden';
            } else {
                document.body.style.overflow = '';
            }
        }

        hamburgerBtn.addEventListener('click', toggleSidebar);
        closeSidebarBtn.addEventListener('click', toggleSidebar);
        sidebarOverlay.addEventListener('click', toggleSidebar);

        // Close sidebar when clicking a link and allow smooth scroll
        sidebarLinks.forEach(link => {
            link.addEventListener('click', () => {
                if (sidebar.classList.contains('active')) {
                    toggleSidebar();
                }
            });
        });
    </script>
</body>
</html>
