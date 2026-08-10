<!DOCTYPE html>
<html lang="en" dir="ltr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DrRoom - Staff Register</title>
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

        .logo-wrapper { display: flex; align-items: center; gap: 12px; margin-bottom: 40px; }
        .logo-icon { 
            color: #2563EB; /* Blue for doctor */
            display: flex; align-items: center; justify-content: center;
        }
        .logo-text h2 { font-size: 26px; font-weight: 800; color: #0f172a; line-height: 1; }
        .logo-text p { font-size: 11px; color: #64748b; font-weight: 500; margin-top: 4px; }

        h1 { font-size: 28px; font-weight: 800; color: #0f172a; margin-bottom: 10px; }
        .subtitle { font-size: 14px; color: #64748b; margin-bottom: 30px; }

        .err-box {
            background: #FEF2F2; border: 1px solid #FEE2E2; border-radius: 8px;
            padding: 12px; margin-bottom: 20px; color: #DC2626; font-size: 13px; font-weight: 500;
        }

        .form-group { margin-bottom: 16px; position: relative; }
        .form-icon { position: absolute; left: 16px; top: 50%; transform: translateY(-50%); color: #94a3b8; pointer-events: none; }
        .form-icon-right { position: absolute; right: 16px; top: 50%; transform: translateY(-50%); color: #94a3b8; cursor: pointer; background: none; border: none; }
        
        .form-control {
            width: 100%; padding: 15px 44px;
            border: 1.5px solid #e2e8f0; border-radius: 12px;
            font-size: 14px; color: #334155; outline: none; transition: all 0.2s;
        }
        .form-control::placeholder { color: #94a3b8; }
        .form-control:focus { border-color: #2563EB; box-shadow: 0 0 0 3px rgba(37,99,235,0.1); }

        .btn-login {
            width: 100%; padding: 15px; margin-top: 10px;
            background: #2563EB; color: #fff;
            border: none; border-radius: 12px;
            font-size: 15px; font-weight: 600; cursor: pointer; transition: background 0.2s;
        }
        .btn-login:hover { background: #1D4ED8; }

        .signup { text-align: center; margin-top: 24px; font-size: 14px; color: #64748b; }
        .signup a { color: #2563EB; font-weight: 600; text-decoration: none; }

        .secure-footer { 
            display: flex; justify-content: center; align-items: center; gap: 8px; 
            color: #94a3b8; font-size: 13px; font-weight: 500; margin-top: 30px; 
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
            .subtitle { font-size: 13px; margin-bottom: 24px; }
            .form-group { margin-bottom: 16px; }
        }
        @media (max-width: 600px) {
            body { padding: 12px; } /* Keep small frame on mobile too */
            .split-layout { border-radius: 20px; min-height: calc(100vh - 24px); }
            .left-side { padding: 30px 20px; width: 65%; } /* Give more width to the form */
            .right-side { width: 35%; } 
            .logo-wrapper { margin-bottom: 20px; }
            h1 { font-size: 22px; }
            .subtitle { font-size: 13px; margin-bottom: 24px; line-height: 1.5; }
            .form-group { margin-bottom: 16px; } /* Spread them out vertically */
            .form-control { padding: 14px 40px; font-size: 13px; border-radius: 12px; } /* Make fields thicker and nicer */
            .form-icon { width: 18px; height: 18px; left: 14px; }
            .form-icon-right { width: 18px; height: 18px; right: 14px; }
            .btn-login { padding: 14px; font-size: 14px; border-radius: 12px; margin-bottom: 16px; }
            .secure-footer { font-size: 12px; margin-top: 20px; }
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

                <h1>Staff Register</h1>
                <p class="subtitle">Fill in your details to join as a Doctor, Nurse, or Lab.</p>

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
                        <!-- User Icon -->
                        <svg class="form-icon" width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/>
                        </svg>
                        <input type="text" name="name" value="{{ old('name') }}" required autofocus dir="auto" class="form-control" placeholder="Full Name">
                    </div>

                    <div class="form-group">
                        <svg class="form-icon" width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/>
                        </svg>
                        <input type="email" name="email" value="{{ old('email') }}" required dir="ltr" class="form-control" placeholder="Email Address">
                    </div>

                    <div class="form-group">
                        <svg class="form-icon" width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"/>
                        </svg>
                        <input type="text" name="phone" value="{{ old('phone') }}" required dir="ltr" class="form-control" placeholder="Phone Number">
                    </div>
                    
                    <div class="form-group">
                        <svg class="form-icon" width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2m4 6h.01M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/>
                        </svg>
                        <select name="role" required class="form-control" style="appearance: auto;">
                            <option value="" disabled selected>Select your role...</option>
                            <option value="doctor" {{ old('role') == 'doctor' ? 'selected' : '' }}>Doctor</option>
                            <option value="nurse" {{ old('role') == 'nurse' ? 'selected' : '' }}>Nurse</option>
                            <option value="lab" {{ old('role') == 'lab' ? 'selected' : '' }}>Laboratory</option>
                            <option value="pharmacy" {{ old('role') == 'pharmacy' ? 'selected' : '' }}>Pharmacy</option>
                        </select>
                    </div>

                    <div class="form-group">
                        <svg class="form-icon" width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"/>
                        </svg>
                        <input type="password" name="password" id="password" required dir="ltr" class="form-control" placeholder="Password">
                    </div>

                    <div class="form-group">
                        <svg class="form-icon" width="20" height="20" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="1.8">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"/>
                        </svg>
                        <input type="password" name="password_confirmation" required dir="ltr" class="form-control" placeholder="Confirm Password">
                    </div>

                    <button type="submit" class="btn-login">Create Account</button>
                </form>

                <div class="signup">
                    Already have an account? <a href="{{ route('staff.login') }}">Login</a>
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

</body>
</html>
