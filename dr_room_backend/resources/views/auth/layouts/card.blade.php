<!DOCTYPE html>
<html lang="en" dir="ltr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DrRoom - @yield('title')</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Inter', sans-serif; }

        body {
            background: #f1f5f9;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 24px;
        }

        .card {
            background: #fff;
            width: 100%;
            max-width: 440px;
            border-radius: 24px;
            padding: 40px 36px;
            box-shadow: 0 20px 50px rgba(15, 23, 42, 0.08);
        }

        .logo-wrapper { display: flex; align-items: center; gap: 12px; margin-bottom: 28px; }
        .logo-icon {
            width: 48px; height: 48px;
            display: flex; align-items: center; justify-content: center;
            background: linear-gradient(135deg, #3B82F6, #1D4ED8);
            color: #fff; border-radius: 14px;
        }
        .logo-text h2 { font-size: 19px; font-weight: 800; color: #0F172A; }
        .logo-text p { font-size: 12px; color: #64748B; }

        h1 { font-size: 24px; font-weight: 800; color: #0F172A; margin-bottom: 6px; }
        .subtitle { font-size: 14px; color: #64748B; line-height: 1.6; margin-bottom: 24px; }

        .box {
            padding: 14px 16px; border-radius: 14px; font-size: 13px;
            line-height: 1.6; margin-bottom: 20px; border: 1px solid;
        }
        .box-ok  { background: #F0FDF4; border-color: #DCFCE7; color: #166534; }
        .box-err { background: #FEF2F2; border-color: #FEE2E2; color: #991B1B; }

        .form-group { position: relative; margin-bottom: 16px; }
        .form-icon {
            position: absolute; left: 16px; top: 50%; transform: translateY(-50%);
            color: #94A3B8; pointer-events: none;
        }
        .form-control {
            width: 100%; padding: 14px 16px 14px 48px;
            background: #F8FAFC; border: 1.5px solid #E2E8F0;
            border-radius: 14px; font-size: 14px; color: #0F172A;
            transition: border-color .2s, box-shadow .2s;
        }
        .form-control:focus {
            outline: none; border-color: #3B82F6;
            box-shadow: 0 0 0 4px rgba(59, 130, 246, .12);
        }
        .form-control::placeholder { color: #94A3B8; }

        .btn {
            width: 100%; padding: 15px; border: none; cursor: pointer;
            background: linear-gradient(135deg, #3B82F6, #1D4ED8);
            color: #fff; border-radius: 14px;
            font-size: 15px; font-weight: 700;
            box-shadow: 0 8px 20px rgba(37, 99, 235, .28);
            transition: transform .15s, box-shadow .15s;
        }
        .btn:hover { transform: translateY(-1px); box-shadow: 0 12px 24px rgba(37, 99, 235, .34); }

        .back { display: block; text-align: center; margin-top: 22px; font-size: 13px; color: #64748B; text-decoration: none; }
        .back:hover { color: #2563EB; }

        @media (max-width: 480px) { .card { padding: 32px 24px; } }
    </style>
</head>
<body>
    <div class="card">
        <div class="logo-wrapper">
            <div class="logo-icon">
                <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"></path>
                    <line x1="12" y1="9" x2="12" y2="15"></line>
                    <line x1="9" y1="12" x2="15" y2="12"></line>
                </svg>
            </div>
            <div class="logo-text">
                <h2>DrRoom</h2>
                <p>Healthcare at your doorstep</p>
            </div>
        </div>

        @if (session('status'))
            <div class="box box-ok">{{ session('status') }}</div>
        @endif

        @if ($errors->any())
            <div class="box box-err">
                @foreach ($errors->all() as $error)
                    <div>• {{ $error }}</div>
                @endforeach
            </div>
        @endif

        @yield('content')

        <a href="{{ route('staff.login') }}" class="back">← گەڕانەوە بۆ چوونەژوورەوە</a>
    </div>
</body>
</html>
