<!DOCTYPE html>
<html lang="ckb" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DrRoom - چاوەڕێی پەسەندکردن</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Inter', sans-serif; }
        body { 
            background: #f1f5f9; 
            min-height: 100vh; 
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 16px;
        }
        
        .waiting-card {
            background: #ffffff;
            border-radius: 24px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.08);
            width: 100%;
            max-width: 480px;
            padding: 40px;
            text-align: center;
        }

        .icon-wrapper {
            width: 80px;
            height: 80px;
            background: #EFF6FF;
            color: #2563EB;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 24px;
        }

        .icon-wrapper svg {
            width: 40px;
            height: 40px;
            animation: pulse 2s infinite ease-in-out;
        }

        @keyframes pulse {
            0% { transform: scale(1); opacity: 1; }
            50% { transform: scale(1.1); opacity: 0.7; }
            100% { transform: scale(1); opacity: 1; }
        }

        h1 { font-size: 24px; font-weight: 800; color: #0f172a; margin-bottom: 12px; }
        p { font-size: 14px; color: #64748b; line-height: 1.6; margin-bottom: 32px; }

        .loading-dots {
            display: flex;
            justify-content: center;
            gap: 8px;
            margin-bottom: 32px;
        }

        .dot {
            width: 8px;
            height: 8px;
            background: #CBD5E1;
            border-radius: 50%;
            animation: bounce 1.4s infinite ease-in-out both;
        }

        .dot:nth-child(1) { animation-delay: -0.32s; }
        .dot:nth-child(2) { animation-delay: -0.16s; }
        .dot:nth-child(3) { animation-delay: 0s; }

        @keyframes bounce {
            0%, 80%, 100% { transform: scale(0); }
            40% { transform: scale(1); background: #3B82F6; }
        }

        .btn-logout {
            width: 100%; padding: 14px;
            background: #fff; color: #64748b;
            border: 1.5px solid #e2e8f0; border-radius: 12px;
            font-size: 14px; font-weight: 600; cursor: pointer; transition: all 0.2s;
        }
        
        .btn-logout:hover { 
            background: #FEF2F2; 
            border-color: #FEE2E2;
            color: #DC2626; 
        }

    </style>
</head>
<body>

    <div class="waiting-card">
        <div class="icon-wrapper">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
            </svg>
        </div>
        
        <h1>چاوەڕێی پەسەندکردن بە</h1>
        <p>هەژمارەکەت بە سەرکەوتوویی دروستکرا، بەڵام پێویستە لەلایەن ئەدمینەوە پەسەند بکرێت پێش ئەوەی بتوانیت بچیتە ناو سیستەمەکە. تکایە چاوەڕێ بکە...</p>

        <div class="loading-dots">
            <div class="dot"></div>
            <div class="dot"></div>
            <div class="dot"></div>
        </div>

        <form method="POST" action="{{ route('staff.logout') }}">
            @csrf
            <button type="submit" class="btn-logout">چوونەدەرەوە</button>
        </form>
    </div>

    <script>
        // Poll the server every 5 seconds to check if status is approved
        setInterval(() => {
            fetch("{{ route('staff.status') }}")
                .then(response => response.json())
                .then(data => {
                    if (data.status === 'approved') {
                        // Redirect to home/dashboard which will route based on role
                        window.location.href = "{{ route('staff.login') }}";
                    }
                })
                .catch(error => console.error('Error checking status:', error));
        }, 5000);
    </script>
</body>
</html>
