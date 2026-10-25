<!DOCTYPE html>
<html lang="ckb" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DrRoom - گەڕاندنەوەی وشەی نهێنی</title>
    <link rel="icon" type="image/x-icon" href="{{ asset('favicon.ico') }}">
    <link rel="icon" type="image/png" sizes="32x32" href="{{ asset('favicon.png') }}">
    <link rel="stylesheet" href="/css/kurdish-font.css">
    <link href="https://fonts.googleapis.com/css2?family=Noto+Kufi+Arabic:wght@400;500;600;700;800;900&family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Noto Kufi Arabic', 'Plus Jakarta Sans', sans-serif; }
        body { 
            background: #f1f5f9; 
            min-height: 100vh; 
            margin: 0; 
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        
        .card-box { 
            width: 100%; 
            max-width: 480px; 
            background: #ffffff;
            border-radius: 28px;
            box-shadow: 0 20px 45px -10px rgba(15, 23, 42, 0.1);
            overflow: hidden;
            padding: 40px 36px;
        }

        .logo-wrapper { display: flex; align-items: center; gap: 12px; margin-bottom: 24px; }
        .logo-icon { 
            width: 46px; height: 46px;
            border-radius: 14px;
            display: flex; align-items: center; justify-content: center;
            flex-shrink: 0;
        }
        .logo-text h2 { font-size: 24px; font-weight: 900; color: #0f172a; line-height: 1; font-family: 'Plus Jakarta Sans', sans-serif; }
        .logo-text p { font-size: 11.5px; color: #64748b; font-weight: 600; margin-top: 4px; }

        h1 { font-size: 22px; font-weight: 900; color: #0f172a; margin-bottom: 6px; line-height: 1.4; }
        .subtitle { font-size: 13.5px; color: #475569; margin-bottom: 24px; line-height: 1.6; font-weight: 500; }

        .alert-box {
            border-radius: 14px;
            padding: 12px 16px; margin-bottom: 20px; font-size: 13px; font-weight: 600; line-height: 1.5;
        }
        .alert-err { background: #FEF2F2; border: 1px solid #FEE2E2; color: #DC2626; }
        .alert-ok  { background: #F0FDF4; border: 1px solid #DCFCE7; color: #166534; }

        .form-group { margin-bottom: 16px; position: relative; }
        .form-label { display: block; font-size: 13px; font-weight: 700; color: #334155; margin-bottom: 8px; }
        .form-icon { position: absolute; right: 15px; top: 50%; transform: translateY(-50%); color: #64748b; pointer-events: none; }
        .form-icon-right { position: absolute; left: 15px; top: 50%; transform: translateY(-50%); color: #64748b; cursor: pointer; background: none; border: none; }

        .form-control {
            width: 100%; height: 50px; padding: 0 46px 0 46px;
            border: 1.5px solid #cbd5e1; border-radius: 14px;
            font-size: 14.5px; font-weight: 600; color: #0f172a; outline: none; transition: all 0.2s;
            text-align: right;
            background: #f8fafc;
        }
        .form-control::placeholder { color: #94a3b8; font-weight: 500; font-size: 14px; }
        .form-control:focus { border-color: #2563EB; background: #ffffff; box-shadow: 0 0 0 4px rgba(37,99,235,0.12); }

        /* Phone Input with Country Code */
        .phone-input-wrapper {
            display: flex;
            align-items: center;
            width: 100%;
            height: 50px;
            border: 1.5px solid #cbd5e1;
            border-radius: 14px;
            background: #f8fafc;
            transition: all 0.2s;
            overflow: hidden;
            direction: ltr;
        }
        .phone-input-wrapper:focus-within {
            border-color: #2563EB;
            background: #ffffff;
            box-shadow: 0 0 0 4px rgba(37,99,235,0.12);
        }
        .country-badge {
            display: flex;
            align-items: center;
            gap: 6px;
            padding: 0 14px;
            background: #f1f5f9;
            height: 100%;
            border-right: 1.5px solid #cbd5e1;
            color: #0f172a;
            font-size: 13.5px;
            font-weight: 700;
            user-select: none;
            flex-shrink: 0;
        }
        .country-badge .flag { font-size: 16px; }
        .phone-input {
            flex: 1;
            height: 100%;
            border: none !important;
            background: transparent !important;
            box-shadow: none !important;
            padding: 0 14px !important;
            font-size: 15px;
            font-weight: 600;
            color: #0f172a;
            outline: none;
            text-align: left;
            letter-spacing: 0.5px;
        }
        .phone-input::placeholder { color: #94a3b8; font-weight: 500; letter-spacing: normal; }

        .otp-input {
            height: 52px;
            font-size: 22px;
            font-weight: 900;
            letter-spacing: 8px;
            text-align: center;
            direction: ltr;
        }

        .btn-primary {
            width: 100%; height: 50px;
            background: #2563EB; color: #fff;
            border: none; border-radius: 14px;
            font-size: 15px; font-weight: 800; cursor: pointer; transition: all 0.2s;
            box-shadow: 0 4px 14px rgba(37, 99, 235, 0.3);
            display: flex; align-items: center; justify-content: center; gap: 8px;
        }
        .btn-primary:hover { background: #1D4ED8; transform: translateY(-1px); }

        .action-links {
            display: flex; justify-content: space-between; align-items: center; margin-top: 20px; font-size: 13px; font-weight: 600;
        }
        .action-links a { color: #2563EB; text-decoration: none; }
        .action-links a:hover { text-decoration: underline; }

        .back-link {
            display: flex; align-items: center; justify-content: center; gap: 6px;
            margin-top: 24px; color: #64748b; font-size: 13px; font-weight: 700; text-decoration: none;
        }
        .back-link:hover { color: #0f172a; }

        @media (max-width: 500px) {
            .card-box { padding: 30px 20px; border-radius: 22px; }
        }
    </style>
</head>
<body>

    <div class="card-box">
        <div class="logo-wrapper">
            <div class="logo-icon">
                <img src="{{ asset('images/logo.png') }}" alt="DrRoom" style="width: 44px; height: 44px; border-radius: 12px; object-fit: contain; box-shadow: 0 8px 16px rgba(37, 99, 235, 0.2);">
            </div>
            <div class="logo-text">
                <h2>DrRoom</h2>
                <p>خزمەتگوزاری تەندروستی لە بەردەم دەرگاکەت</p>
            </div>
        </div>

        @if (session('success'))
            <div class="alert-box alert-ok">
                {{ session('success') }}
            </div>
        @endif

        @if ($errors->any())
            <div class="alert-box alert-err">
                @foreach ($errors->all() as $error)
                    <div>• {{ $error }}</div>
                @endforeach
            </div>
        @endif

        @if ($step === 'verify')
            <!-- STEP 2: ENTER OTP & NEW PASSWORD -->
            <h1>کۆدی پشتڕاستکردنەوە</h1>
            <p class="subtitle">
                کۆدی ٤ ژمارەیی نێردرا بۆ ژمارەی <strong dir="ltr">{{ $phone }}</strong>. تکایە کۆدەکە و وشەی تێپەڕی نوێ بنووسە.
            </p>

            <form method="POST" action="{{ route('password.update') }}">
                @csrf
                <input type="hidden" name="phone" value="{{ $phone }}">

                <div class="form-group">
                    <label class="form-label">کۆدی پشتڕاستکردنەوە (OTP Code)</label>
                    <input type="text" name="otp_code" required autofocus maxlength="6" dir="ltr" class="form-control otp-input" placeholder="••••">
                </div>

                <div class="form-group">
                    <label class="form-label">وشەی تێپەڕی نوێ</label>
                    <div style="position: relative;">
                        <svg class="form-icon" width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"/>
                        </svg>
                        <input type="password" name="password" id="new_pwd" required dir="ltr" class="form-control" placeholder="لانیکەم ٦ پیت">
                        <button type="button" class="form-icon-right" onclick="togglePwd('new_pwd')">
                            <svg width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.8">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                                <path stroke-linecap="round" stroke-linejoin="round" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
                            </svg>
                        </button>
                    </div>
                </div>

                <div class="form-group">
                    <label class="form-label">دووبارەکردنەوەی وشەی تێپەڕ</label>
                    <div style="position: relative;">
                        <svg class="form-icon" width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                        </svg>
                        <input type="password" name="password_confirmation" id="confirm_pwd" required dir="ltr" class="form-control" placeholder="دووبارەی بکەرەوە">
                    </div>
                </div>

                <button type="submit" class="btn-primary" style="margin-top: 20px;">
                    نوێکردنەوەی وشەی تێپەڕ
                </button>
            </form>

            <div class="action-links">
                <a href="{{ route('password.request') }}">← گۆڕینی ژمارەی مۆبایل</a>
                
                <form method="POST" action="{{ route('password.email') }}" style="display: inline;">
                    @csrf
                    <input type="hidden" name="phone" value="{{ $phone }}">
                    <button type="submit" style="background: none; border: none; color: #2563EB; font-weight: 700; cursor: pointer; font-size: 13px;">
                        دووبارە ناردنەوەی کۆد
                    </button>
                </form>
            </div>

        @else
            <!-- STEP 1: ENTER PHONE NUMBER -->
            <h1>وشەی نهێنیت لەبیرچووە؟</h1>
            <p class="subtitle">
                ژمارەی مۆبایلەکەت بنووسە تا کۆدی پشتڕاستکردنەوەت (OTP) بە کورتەنامە بۆ بنێرین.
            </p>

            <form method="POST" action="{{ route('password.email') }}">
                @csrf

                <div class="form-group">
                    <label class="form-label">ژمارەی مۆبایل</label>
                    <div class="phone-input-wrapper">
                        <div class="country-badge">
                            <span class="flag">🇮🇶</span>
                            <span class="code">+964</span>
                        </div>
                        <input type="tel" name="phone" value="{{ old('phone', $phone) }}" required autofocus dir="ltr" class="phone-input" placeholder="07xxxxxxxxx">
                    </div>
                </div>

                <button type="submit" class="btn-primary" style="margin-top: 24px;">
                    ناردنی کۆدی کورتەنامە (SMS OTP)
                </button>
            </form>

            <a href="{{ route('staff.login') }}" class="back-link">
                ← گەڕانەوە بۆ چوونەژوورەوە
            </a>
        @endif
    </div>

    <script>
        function togglePwd(id) {
            const inp = document.getElementById(id);
            if (inp.type === 'password') {
                inp.type = 'text';
            } else {
                inp.type = 'password';
            }
        }
    </script>
</body>
</html>
