<!DOCTYPE html>
<html lang="ckb" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DrRoom - تۆمارکردنی ستاف</title>
    <link rel="stylesheet" href="/css/kurdish-font.css">
    <link href="https://fonts.googleapis.com/css2?family=Noto+Kufi+Arabic:wght@400;500;600;700;800;900&family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Noto Kufi Arabic', 'Plus Jakarta Sans', sans-serif; }
        body { 
            background: #f1f5f9; 
            min-height: 100vh; 
            overflow-x: hidden; 
            margin: 0; 
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 16px;
        }
        
        .split-layout { 
            display: flex; 
            width: 100%; 
            max-width: 1100px; 
            min-height: 640px;
            background: #ffffff;
            border-radius: 28px;
            box-shadow: 0 20px 45px -10px rgba(15, 23, 42, 0.1);
            overflow: visible;
            margin: auto;
        }
        
        /* === FORM SIDE (IN RTL) === */
        .left-side {
            width: 55%;
            background: #ffffff;
            display: flex;
            flex-direction: column;
            padding: 40px;
            border-radius: 28px 0 0 28px;
        }
        
        .left-content {
            flex: 1;
            display: flex;
            flex-direction: column;
            justify-content: center;
            max-width: 420px;
            width: 100%;
            margin: 0 auto;
        }

        .logo-wrapper { display: flex; align-items: center; gap: 12px; margin-bottom: 24px; }
        .logo-icon { 
            width: 46px; height: 46px;
            border-radius: 14px;
            background: linear-gradient(135deg, #2563eb, #38bdf8);
            color: #ffffff;
            display: flex; align-items: center; justify-content: center;
            box-shadow: 0 8px 16px rgba(37, 99, 235, 0.25);
            flex-shrink: 0;
        }
        .logo-text h2 { font-size: 24px; font-weight: 900; color: #0f172a; line-height: 1; font-family: 'Plus Jakarta Sans', sans-serif; }
        .logo-text p { font-size: 11.5px; color: #64748b; font-weight: 600; margin-top: 4px; }

        h1 { font-size: 24px; font-weight: 900; color: #0f172a; margin-bottom: 6px; line-height: 1.4; }
        .subtitle { font-size: 13.5px; color: #475569; margin-bottom: 22px; line-height: 1.6; font-weight: 500; }

        .err-box {
            background: #FEF2F2; border: 1px solid #FEE2E2; border-radius: 12px;
            padding: 12px; margin-bottom: 18px; color: #DC2626; font-size: 13px; font-weight: 600;
        }

        .form-group { margin-bottom: 14px; position: relative; }
        .form-icon { position: absolute; right: 15px; top: 50%; transform: translateY(-50%); color: #64748b; pointer-events: none; z-index: 2; }
        
        .form-control {
            width: 100%; height: 50px; padding: 0 46px 0 46px;
            border: 1.5px solid #cbd5e1; border-radius: 14px;
            font-size: 14.5px; font-weight: 600; color: #0f172a; outline: none; transition: all 0.2s;
            text-align: right;
            background: #f8fafc;
        }
        .form-control::placeholder { color: #64748b; font-weight: 500; font-size: 14px; }
        .form-control:focus { border-color: #2563EB; background: #ffffff; box-shadow: 0 0 0 4px rgba(37,99,235,0.12); }

        /* Custom Dropdown Trigger */
        .select-btn {
            width: 100%; height: 50px; padding: 0 16px 0 16px;
            border: 1.5px solid #cbd5e1; border-radius: 14px;
            background: #f8fafc; cursor: pointer;
            display: flex; align-items: center; justify-content: space-between;
            transition: all 0.2s; outline: none;
        }
        .select-btn:hover { background: #f1f5f9; border-color: #94a3b8; }
        .select-btn.active { border-color: #2563EB; background: #ffffff; box-shadow: 0 0 0 4px rgba(37,99,235,0.12); }

        /* Custom Dropdown Menu (Opens Below) */
        .custom-dropdown-menu {
            position: absolute;
            top: calc(100% + 6px);
            left: 0;
            right: 0;
            background: #ffffff;
            border: 1.5px solid #e2e8f0;
            border-radius: 18px;
            box-shadow: 0 20px 35px -10px rgba(15, 23, 42, 0.2), 0 0 0 1px rgba(0,0,0,0.05);
            padding: 8px;
            z-index: 50;
        }

        .dropdown-item {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 10px 14px;
            border-radius: 12px;
            cursor: pointer;
            transition: all 0.15s ease;
            margin-bottom: 2px;
        }
        .dropdown-item:last-child { margin-bottom: 0; }
        .dropdown-item:hover { background: #f1f5f9; }
        .dropdown-item.selected { background: #EFF6FF; border: 1px solid #BFDBFE; }

        .item-content { display: flex; align-items: center; gap: 12px; }
        .item-icon-box {
            width: 36px; height: 36px; border-radius: 10px;
            display: flex; align-items: center; justify-content: center;
            font-size: 16px;
        }
        .item-title { font-size: 14.5px; font-weight: 800; color: #0f172a; line-height: 1.2; text-align: right; }
        .item-sub { font-size: 11.5px; font-weight: 600; color: #64748b; line-height: 1.2; text-align: right; }
        .check-badge {
            width: 22px; height: 22px; border-radius: 50%;
            background: #2563eb; color: #fff;
            display: flex; align-items: center; justify-content: center;
            font-size: 12px; font-weight: bold;
        }

        .btn-login {
            width: 100%; height: 50px; margin-top: 8px;
            background: #2563EB; color: #fff;
            border: none; border-radius: 14px;
            font-size: 15px; font-weight: 800; cursor: pointer; transition: all 0.2s;
            box-shadow: 0 4px 14px rgba(37, 99, 235, 0.3);
            display: flex; align-items: center; justify-content: center;
        }
        .btn-login:hover { background: #1D4ED8; transform: translateY(-1px); }

        .signup { text-align: center; margin-top: 18px; font-size: 13.5px; color: #475569; font-weight: 600; }
        .signup a { color: #2563EB; font-weight: 800; text-decoration: none; margin-right: 4px; }
        .signup a:hover { text-decoration: underline; }

        .secure-footer { 
            display: flex; justify-content: center; align-items: center; gap: 6px; 
            color: #64748b; font-size: 12.5px; font-weight: 600; margin-top: 24px; 
        }

        /* === IMAGE SIDE === */
        .right-side {
            width: 45%;
            background: #EFF6FF;
            display: flex;
            align-items: center;
            justify-content: center;
            position: relative;
            overflow: hidden;
            border-radius: 0 28px 28px 0;
        }
        
        .right-side img {
            width: 100%;
            height: 100%;
            object-fit: cover;
            object-position: center top;
            position: absolute;
            top: 0;
            left: 0;
            z-index: 2;
        }

        @media (max-width: 900px) {
            .left-side { padding: 36px 24px; width: 60%; }
            .right-side { width: 40%; }
            .logo-text h2 { font-size: 22px; }
            h1 { font-size: 22px; }
        }
        @media (max-width: 600px) {
            body { padding: 12px; }
            .split-layout { border-radius: 24px; min-height: auto; box-shadow: 0 10px 30px rgba(0,0,0,0.06); }
            .left-side { padding: 28px 18px; width: 100%; border-radius: 24px; }
            .right-side { display: none; } 
            .logo-wrapper { margin-bottom: 20px; }
            h1 { font-size: 22px; }
            .subtitle { font-size: 13px; margin-bottom: 18px; }
            .form-control { height: 50px; font-size: 14.5px; padding: 0 46px 0 46px; }
            .select-btn { height: 50px; }
            .btn-login { height: 50px; font-size: 15px; }
            .secure-footer { font-size: 12px; margin-top: 20px; }
        }
    </style>
</head>
<body>

    <div class="split-layout">
        <!-- Form Side -->
        <div class="left-side">
            <div class="left-content">
                <div class="logo-wrapper">
                    <div class="logo-icon">
                        <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"></path>
                            <line x1="12" y1="9" x2="12" y2="15"></line>
                            <line x1="9" y1="12" x2="15" y2="12"></line>
                        </svg>
                    </div>
                    <div class="logo-text">
                        <h2>DrRoom</h2>
                        <p>خزمەتگوزاری تەندروستی لە بەردەم دەرگاکەت</p>
                    </div>
                </div>

                <h1>تۆمارکردنی ستاف</h1>
                <p class="subtitle">زانیارییەکانت پڕبکەرەوە بۆ بەشداریکردن وەک پزیشک، پەرستار، تاقیگە یان دەرمانخانە.</p>

                @if (session('success'))
                    <div class="err-box" style="background: #ECFDF5; border-color: #D1FAE5; color: #059669;">
                        {{ session('success') }}
                    </div>
                @endif

                @if ($errors->any())
                    <div class="err-box">
                        @foreach ($errors->all() as $error)
                            <div>• {{ $error }}</div>
                        @endforeach
                    </div>
                @endif

                <form method="POST" action="{{ route('staff.register') }}">
                    @csrf
                    
                    <div class="form-group">
                        <svg class="form-icon" width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/>
                        </svg>
                        <input type="text" name="name" value="{{ old('name') }}" required autofocus dir="auto" class="form-control" placeholder="ناوی سیانی">
                    </div>

                    <div class="form-group">
                        <svg class="form-icon" width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/>
                        </svg>
                        <input type="email" name="email" value="{{ old('email') }}" required dir="ltr" class="form-control" placeholder="ناونیشانی ئیمەیڵ">
                    </div>

                    <div class="form-group">
                        <svg class="form-icon" width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"/>
                        </svg>
                        <input type="text" name="phone" value="{{ old('phone') }}" required dir="ltr" class="form-control" placeholder="ژمارەی مۆبایل">
                    </div>
                    
                    <!-- Luxury Downward Opening Custom Dropdown -->
                    <div class="form-group" 
                         x-data="{ 
                             open: false, 
                             selected: '{{ old('role', '') }}', 
                             selectedTitle: '{{ old('role') == 'doctor' ? 'پزیشک (Doctor)' : (old('role') == 'nurse' ? 'پەرستار (Nurse)' : (old('role') == 'lab' ? 'تاقیگە (Laboratory)' : (old('role') == 'pharmacy' ? 'دەرمانخانە (Pharmacy)' : ''))) }}' 
                         }">
                        
                        <input type="hidden" name="role" :value="selected" required>
                        
                        <button type="button" 
                                @click="open = !open" 
                                @click.away="open = false" 
                                class="select-btn"
                                :class="{ 'active': open }">
                            
                            <div style="display: flex; align-items: center; gap: 12px;">
                                <svg width="20" height="20" fill="none" stroke="#64748b" viewBox="0 0 24 24" stroke-width="1.8">
                                    <path stroke-linecap="round" stroke-linejoin="round" d="M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2m4 6h.01M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/>
                                </svg>
                                <span :style="selected ? 'color: #0f172a; font-weight: 800;' : 'color: #64748b; font-weight: 500;'" 
                                      x-text="selectedTitle || 'ڕۆڵ یان پیشەکەت هەڵبژێرە...'" 
                                      style="font-size: 14.5px;"></span>
                            </div>

                            <svg width="20" height="20" fill="none" stroke="#64748b" viewBox="0 0 24 24" stroke-width="2.2" 
                                 :style="open ? 'transform: rotate(180deg); transition: transform 0.2s;' : 'transition: transform 0.2s;'">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7"/>
                            </svg>
                        </button>

                        <!-- Dropdown Menu Below -->
                        <div x-show="open" 
                             x-transition:enter="transition ease-out duration-150"
                             x-transition:enter-start="opacity-0 transform -translate-y-2"
                             x-transition:enter-end="opacity-100 transform translate-y-0"
                             x-transition:leave="transition ease-in duration-100"
                             x-transition:leave-start="opacity-100 transform translate-y-0"
                             x-transition:leave-end="opacity-0 transform -translate-y-2"
                             class="custom-dropdown-menu" 
                             style="display: none;">
                            
                            <!-- Doctor -->
                            <div class="dropdown-item" 
                                 :class="{ 'selected': selected === 'doctor' }" 
                                 @click="selected = 'doctor'; selectedTitle = 'پزیشک (Doctor)'; open = false;">
                                <div class="item-content">
                                    <div class="item-icon-box" style="background: #EFF6FF; color: #2563eb;">🩺</div>
                                    <div>
                                        <div class="item-title">پزیشک</div>
                                        <div class="item-sub">Doctor</div>
                                    </div>
                                </div>
                                <div class="check-badge" x-show="selected === 'doctor'">✓</div>
                            </div>

                            <!-- Nurse -->
                            <div class="dropdown-item" 
                                 :class="{ 'selected': selected === 'nurse' }" 
                                 @click="selected = 'nurse'; selectedTitle = 'پەرستار (Nurse)'; open = false;">
                                <div class="item-content">
                                    <div class="item-icon-box" style="background: #F0FDF4; color: #16a34a;">💉</div>
                                    <div>
                                        <div class="item-title">پەرستار</div>
                                        <div class="item-sub">Nurse</div>
                                    </div>
                                </div>
                                <div class="check-badge" x-show="selected === 'nurse'">✓</div>
                            </div>

                            <!-- Lab -->
                            <div class="dropdown-item" 
                                 :class="{ 'selected': selected === 'lab' }" 
                                 @click="selected = 'lab'; selectedTitle = 'تاقیگە (Laboratory)'; open = false;">
                                <div class="item-content">
                                    <div class="item-icon-box" style="background: #FAF5FF; color: #9333ea;">🔬</div>
                                    <div>
                                        <div class="item-title">تاقیگە</div>
                                        <div class="item-sub">Laboratory</div>
                                    </div>
                                </div>
                                <div class="check-badge" x-show="selected === 'lab'">✓</div>
                            </div>

                            <!-- Pharmacy -->
                            <div class="dropdown-item" 
                                 :class="{ 'selected': selected === 'pharmacy' }" 
                                 @click="selected = 'pharmacy'; selectedTitle = 'دەرمانخانە (Pharmacy)'; open = false;">
                                <div class="item-content">
                                    <div class="item-icon-box" style="background: #FFF7ED; color: #ea580c;">💊</div>
                                    <div>
                                        <div class="item-title">دەرمانخانە</div>
                                        <div class="item-sub">Pharmacy</div>
                                    </div>
                                </div>
                                <div class="check-badge" x-show="selected === 'pharmacy'">✓</div>
                            </div>
                        </div>
                    </div>

                    <div class="form-group">
                        <svg class="form-icon" width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"/>
                        </svg>
                        <input type="password" name="password" id="password" required dir="ltr" class="form-control" placeholder="وشەی تێپەڕ (Password)">
                    </div>

                    <div class="form-group">
                        <svg class="form-icon" width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/>
                        </svg>
                        <input type="password" name="password_confirmation" required dir="ltr" class="form-control" placeholder="دووبارەکردنەوەی وشەی تێپەڕ">
                    </div>

                    <button type="submit" class="btn-login">دروستکردنی هەژمار</button>
                </form>

                <div class="signup">
                    پێشتر هەژمارت هەبووە؟ <a href="{{ route('staff.login') }}">چوونەژوورەوە</a>
                </div>
            </div>

            <div class="secure-footer">
                <svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/>
                </svg>
                زانیارییەکانت پارێزراون لای ئێمە
            </div>
        </div>

        <!-- Image Side -->
        <div class="right-side">
            <img src="{{ asset('images/doctor.png') }}" alt="Doctor">
        </div>
    </div>

</body>
</html>
