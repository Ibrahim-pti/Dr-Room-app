<!DOCTYPE html>
<html lang="ckb" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DrRoom - چوونەژوورەوەی ستاف</title>
    <link rel="stylesheet" href="/css/kurdish-font.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Rabar', 'Inter', sans-serif; }
        body { 
            background: #f1f5f9; 
            min-height: 100vh; 
            overflow-x: auto; 
            margin: 0; 
            display: flex;
            padding: 16px;
        }
        
        .split-layout { 
            display: flex; 
            width: 100%; 
            max-width: 1200px; 
            min-height: calc(100vh - 32px);
            background: #ffffff;
            border-radius: 24px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.08);
            overflow: hidden;
            margin: auto;
        }
        
        /* === RIGHT/FORM SIDE (IN RTL) === */
        .left-side {
            width: 55%;
            background: #ffffff;
            display: flex;
            flex-direction: column;
            padding: 40px;
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

        .logo-wrapper { display: flex; align-items: center; gap: 12px; margin-bottom: 40px; }
        .logo-icon { 
            color: #2563EB;
            display: flex; align-items: center; justify-content: center;
        }
        .logo-text h2 { font-size: 26px; font-weight: 800; color: #0f172a; line-height: 1; font-family: 'Inter', sans-serif; }
        .logo-text p { font-size: 12px; color: #64748b; font-weight: 500; margin-top: 4px; }

        h1 { font-size: 26px; font-weight: 800; color: #0f172a; margin-bottom: 8px; }
        .subtitle { font-size: 13.5px; color: #64748b; margin-bottom: 30px; }

        .err-box {
            background: #FEF2F2; border: 1px solid #FEE2E2; border-radius: 10px;
            padding: 12px; margin-bottom: 20px; color: #DC2626; font-size: 13px; font-weight: 500;
        }

        .form-group { margin-bottom: 18px; position: relative; }
        .form-icon { position: absolute; right: 16px; top: 50%; transform: translateY(-50%); color: #94a3b8; pointer-events: none; }
        .form-icon-right { position: absolute; left: 16px; top: 50%; transform: translateY(-50%); color: #94a3b8; cursor: pointer; background: none; border: none; }
        
        .form-control {
            width: 100%; padding: 14px 46px 14px 46px;
            border: 1.5px solid #e2e8f0; border-radius: 14px;
            font-size: 13.5px; color: #334155; outline: none; transition: all 0.2s;
            text-align: right;
        }
        .form-control::placeholder { color: #94a3b8; }
        .form-control:focus { border-color: #2563EB; box-shadow: 0 0 0 3px rgba(37,99,235,0.1); }

        .options { display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; }
        .remember { display: flex; align-items: center; gap: 8px; font-size: 13px; color: #475569; cursor: pointer; font-weight: 500; }
        .remember input { width: 18px; height: 18px; accent-color: #2563EB; cursor: pointer; }
        .forgot { font-size: 13px; color: #2563EB; font-weight: 600; text-decoration: none; }

        .btn-login {
            width: 100%; padding: 14px;
            background: #2563EB; color: #fff;
            border: none; border-radius: 14px;
            font-size: 15px; font-weight: bold; cursor: pointer; transition: background 0.2s;
        }
        .btn-login:hover { background: #1D4ED8; }

        .signup { text-align: center; margin-top: 24px; font-size: 13.5px; color: #64748b; }
        .signup a { color: #2563EB; font-weight: bold; text-decoration: none; }

        .secure-footer { 
            display: flex; justify-content: center; align-items: center; gap: 8px; 
            color: #94a3b8; font-size: 12.5px; font-weight: 500; margin-top: 36px; 
        }

        /* === LEFT/IMAGE SIDE === */
        .right-side {
            width: 45%;
            background: #EFF6FF;
            display: flex;
            align-items: center;
            justify-content: center;
            position: relative;
            overflow: hidden;
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
            .left-side { padding: 40px 30px; width: 60%; }
            .right-side { width: 40%; }
            .logo-text h2 { font-size: 22px; }
            h1 { font-size: 22px; }
            .subtitle { font-size: 12.5px; margin-bottom: 24px; }
            .form-group { margin-bottom: 20px; }
        }
        @media (max-width: 600px) {
            body { padding: 12px; }
            .split-layout { border-radius: 20px; min-height: calc(100vh - 24px); }
            .left-side { padding: 30px 20px; width: 100%; }
            .right-side { display: none; } 
            .logo-wrapper { margin-bottom: 24px; }
            h1 { font-size: 20px; }
            .subtitle { font-size: 12.5px; margin-bottom: 24px; line-height: 1.5; }
            .form-group { margin-bottom: 18px; }
            .form-control { padding: 13px 42px; font-size: 13px; border-radius: 12px; }
            .btn-login { padding: 13px; font-size: 14px; border-radius: 12px; margin-bottom: 16px; }
            .options { margin-bottom: 20px; }
            .remember { font-size: 12px; }
            .forgot { font-size: 12px; }
            .secure-footer { font-size: 12px; margin-top: 24px; }
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
                        <svg width="38" height="38" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
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

                <h1>چوونەژوورەوەی ستاف</h1>
                <p class="subtitle">بەخێربێیتەوە! تکایە بچۆ ژوورەوە بۆ هەژمارەکەت.</p>

                @if (session('success'))
                    <div class="err-box" style="background: #F0FDF4; border-color: #DCFCE7; color: #166534;">
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

                <form method="POST" action="{{ route('staff.login') }}">
                    @csrf
                    
                    <div class="form-group">
                        <svg class="form-icon" width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/>
                        </svg>
                        <input type="text" name="email" value="{{ old('email') }}" required autofocus dir="ltr" class="form-control" placeholder="ئیمەیڵ یان ژمارەی مۆبایل">
                    </div>

                    <div class="form-group">
                        <svg class="form-icon" width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"/>
                        </svg>
                        <input type="password" name="password" id="password" required dir="ltr" class="form-control" placeholder="وشەی تێپەڕ (Password)">
                        <button type="button" class="form-icon-right" onclick="togglePwd()">
                            <svg id="eyeIcon" width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.8">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                                <path stroke-linecap="round" stroke-linejoin="round" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
                            </svg>
                        </button>
                    </div>

                    <div class="options">
                        <label class="remember">
                            <input type="checkbox" name="remember" checked>
                            لەبیرم مەچۆ
                        </label>
                        <a href="{{ route('password.request') }}" class="forgot">وشەی تێپەڕت لەبیرچووە؟</a>
                    </div>

                    <button type="submit" class="btn-login">چوونەژوورەوە</button>
                </form>

                <div class="signup" style="margin-top: 24px;">
                    هەژمارت نییە؟ <a href="{{ route('staff.register') }}">تۆمارکردنی هەژمار</a>
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

    <script>
        function togglePwd() {
            const inp = document.getElementById('password');
            if (inp.type === 'password') {
                inp.type = 'text';
            } else {
                inp.type = 'password';
            }
        }
    </script>
</body>
</html>
