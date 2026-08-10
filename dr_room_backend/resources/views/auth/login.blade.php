<!DOCTYPE html>
<html lang="en" dir="ltr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DrRoom - Staff Login</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Inter', sans-serif; }
        body { 
            background: #f1f5f9; 
            min-height: 100vh; 
            overflow-x: auto; 
            margin: 0; 
            display: flex;
            padding: 16px; /* Just a tiny bit of space so the frame is visible */
        }
        
        /* 
           The layout fills almost the entire screen but keeps a beautiful frame!
        */
        .split-layout { 
            display: flex; 
            width: 100%; 
            max-width: 1200px; 
            min-height: calc(100vh - 32px); /* Fills screen minus the small padding */
            background: #ffffff;
            border-radius: 24px; /* The visible frame corners */
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.08); /* The visible frame shadow */
            overflow: hidden;
            margin: auto;
        }
        
        /* === LEFT SIDE === */
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

        .logo-wrapper { display: flex; align-items: center; gap: 12px; margin-bottom: 50px; }
        .logo-icon { 
            color: #2563EB; /* Blue for doctor */
            display: flex; align-items: center; justify-content: center;
        }
        .logo-text h2 { font-size: 26px; font-weight: 800; color: #0f172a; line-height: 1; }
        .logo-text p { font-size: 11px; color: #64748b; font-weight: 500; margin-top: 4px; }

        h1 { font-size: 28px; font-weight: 800; color: #0f172a; margin-bottom: 10px; }
        .subtitle { font-size: 14px; color: #64748b; margin-bottom: 36px; }

        .err-box {
            background: #FEF2F2; border: 1px solid #FEE2E2; border-radius: 8px;
            padding: 12px; margin-bottom: 20px; color: #DC2626; font-size: 13px; font-weight: 500;
        }

        .form-group { margin-bottom: 18px; position: relative; }
        .form-icon { position: absolute; left: 16px; top: 50%; transform: translateY(-50%); color: #94a3b8; pointer-events: none; }
        .form-icon-right { position: absolute; right: 16px; top: 50%; transform: translateY(-50%); color: #94a3b8; cursor: pointer; background: none; border: none; }
        
        .form-control {
            width: 100%; padding: 15px 44px;
            border: 1.5px solid #e2e8f0; border-radius: 12px;
            font-size: 14px; color: #334155; outline: none; transition: all 0.2s;
        }
        .form-control::placeholder { color: #94a3b8; }
        .form-control:focus { border-color: #2563EB; box-shadow: 0 0 0 3px rgba(37,99,235,0.1); }

        .options { display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; }
        .remember { display: flex; align-items: center; gap: 8px; font-size: 13px; color: #475569; cursor: pointer; font-weight: 500; }
        .remember input { width: 18px; height: 18px; accent-color: #2563EB; cursor: pointer; }
        .forgot { font-size: 13px; color: #2563EB; font-weight: 600; text-decoration: none; }

        .btn-login {
            width: 100%; padding: 15px;
            background: #2563EB; color: #fff;
            border: none; border-radius: 12px;
            font-size: 15px; font-weight: 600; cursor: pointer; transition: background 0.2s;
        }
        .btn-login:hover { background: #1D4ED8; }

        .divider { display: flex; align-items: center; gap: 16px; margin: 24px 0; }
        .divider::before, .divider::after { content: ''; flex: 1; height: 1px; background: #e2e8f0; }
        .divider span { font-size: 12px; color: #94a3b8; font-weight: 500; }

        .btn-google {
            width: 100%; padding: 14px;
            background: #fff; border: 1.5px solid #e2e8f0; border-radius: 12px;
            font-size: 14px; font-weight: 600; color: #334155;
            display: flex; align-items: center; justify-content: center; gap: 10px; cursor: pointer; transition: background 0.2s;
        }
        .btn-google:hover { background: #f8fafc; }

        .signup { text-align: center; margin-top: 24px; font-size: 14px; color: #64748b; }
        .signup a { color: #2563EB; font-weight: 600; text-decoration: none; }

        .secure-footer { 
            display: flex; justify-content: center; align-items: center; gap: 8px; 
            color: #94a3b8; font-size: 13px; font-weight: 500; margin-top: 40px; 
        }

        /* === RIGHT SIDE === */
        .right-side {
            width: 45%;
            background: #EFF6FF;
            display: flex;
            align-items: center;
            justify-content: center;
            position: relative;
            overflow: hidden;
        }
        
        /* The image perfectly fills the right half of the screen */
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

        /* Make it natively fluid on smaller screens so the narrow design looks beautiful */
        @media (max-width: 900px) {
            .left-side { padding: 40px 30px; width: 60%; }
            .right-side { width: 40%; }
            .logo-text h2 { font-size: 22px; }
            h1 { font-size: 24px; }
            .subtitle { font-size: 13px; margin-bottom: 30px; }
            .form-group { margin-bottom: 24px; }
        }
        @media (max-width: 600px) {
            body { padding: 12px; } /* Keep small frame on mobile too */
            .split-layout { border-radius: 20px; min-height: calc(100vh - 24px); }
            .left-side { padding: 30px 20px; width: 65%; } /* Give more width to the form */
            .right-side { width: 35%; } 
            .logo-wrapper { margin-bottom: 30px; }
            h1 { font-size: 22px; }
            .subtitle { font-size: 13px; margin-bottom: 30px; line-height: 1.5; }
            .form-group { margin-bottom: 22px; } /* Spread them out vertically */
            .form-control { padding: 14px 40px; font-size: 13px; border-radius: 12px; } /* Make fields thicker and nicer */
            .form-icon { width: 18px; height: 18px; left: 14px; }
            .form-icon-right { width: 18px; height: 18px; right: 14px; }
            .btn-login, .btn-google { padding: 14px; font-size: 14px; border-radius: 12px; margin-bottom: 16px; }
            .options { margin-bottom: 24px; }
            .remember { font-size: 12px; }
            .forgot { font-size: 12px; }
            .secure-footer { font-size: 12px; margin-top: 30px; }
        }
    </style>
</head>
<body>

    <div class="split-layout">
        <!-- Left Side: Form -->
        <div class="left-side">
            <div class="left-content">
                <div class="logo-wrapper">
                    <div class="logo-icon">
                        <!-- Custom Medical Heart Icon -->
                        <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
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

                <h1>Staff Login</h1>
                <p class="subtitle">Welcome back! Please login to your account.</p>

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
                        <input type="email" name="email" value="{{ old('email') }}" required autofocus dir="ltr" class="form-control" placeholder="Email or Phone">
                    </div>

                    <div class="form-group">
                        <svg class="form-icon" width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"/>
                        </svg>
                        <input type="password" name="password" id="password" required dir="ltr" class="form-control" placeholder="Password">
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
                            Remember me
                        </label>
                        <a href="{{ route('password.request') }}" class="forgot">Forgot Password?</a>
                    </div>

                    <button type="submit" class="btn-login">Login</button>
                </form>

                <div class="divider">
                    <span>or</span>
                </div>

                <button type="button" class="btn-google">
                    <svg width="20" height="20" viewBox="0 0 24 24">
                        <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 01-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z" fill="#4285F4"/>
                        <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
                        <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/>
                        <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
                    </svg>
                    Continue with Google
                </button>

                <div class="signup">
                    Don't have an account? <a href="{{ route('staff.register') }}">Sign up</a>
                </div>
            </div>

            <div class="secure-footer">
                <svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/>
                </svg>
                Your data is secure with us
            </div>
        </div>

        <!-- Right Side: Image -->
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
