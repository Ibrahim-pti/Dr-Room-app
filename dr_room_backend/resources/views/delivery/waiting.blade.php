@php
    $loc = $locale ?? app()->getLocale();
    $isRtl = in_array($loc, ['ar', 'ckb', 'kmr']);
    $status = $user->status ?? 'pending';
    $isSubdomain = str_starts_with(strtolower(request()->getHost()), 'delivery.');
    $mainSiteHref = $isSubdomain
        ? str_ireplace('://delivery.', '://', url('/'))
        : '/' . ($loc === 'ckb' ? '' : $loc);
@endphp
<!DOCTYPE html>
<html lang="{{ $loc }}" dir="{{ $isRtl ? 'rtl' : 'ltr' }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ __('delivery.meta_title') }}</title>
    <link rel="icon" type="image/png" href="{{ asset('favicon.png') }}">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Noto+Kufi+Arabic:wght@400;600;700;800&family=Plus+Jakarta+Sans:wght@400;600;700;800&display=swap" rel="stylesheet">
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    fontFamily: {
                        sans: ["{{ $isRtl ? 'Noto Kufi Arabic' : 'Plus Jakarta Sans' }}", 'Noto Kufi Arabic', 'Plus Jakarta Sans', 'sans-serif'],
                    }
                }
            }
        }
    </script>
</head>
<body class="bg-slate-50 text-slate-900 min-h-screen flex items-center justify-center p-4">

    <div class="w-full max-w-lg bg-white rounded-3xl border border-slate-200 shadow-xl shadow-slate-200/50 p-7 sm:p-10 text-center">
        <div class="flex items-center justify-center gap-2.5 mb-6">
            <img src="{{ asset('images/logo.png') }}" alt="DrRoom" class="w-11 h-11 rounded-2xl border border-slate-200 p-1 object-contain">
            <span class="text-xl font-black" dir="ltr">Dr<span class="text-[#1e60eb]">Room</span> Delivery</span>
        </div>

        @if($status === 'approved')
            <div class="w-20 h-20 rounded-full bg-emerald-50 border border-emerald-200 text-emerald-600 flex items-center justify-center mx-auto mb-5">
                <svg class="w-10 h-10" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.2" d="M5 13l4 4L19 7"></path>
                </svg>
            </div>
            <h1 class="text-xl sm:text-2xl font-black text-slate-900">{{ __('delivery.approved_title') }}</h1>
            <p class="text-sm text-slate-600 mt-3 leading-relaxed">{{ __('delivery.approved_subtitle') }}</p>
        @elseif($status === 'blocked')
            <div class="w-20 h-20 rounded-full bg-red-50 border border-red-200 text-red-600 flex items-center justify-center mx-auto mb-5">
                <svg class="w-10 h-10" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.2" d="M6 18L18 6M6 6l12 12"></path>
                </svg>
            </div>
            <h1 class="text-xl sm:text-2xl font-black text-slate-900">{{ __('delivery.blocked_title') }}</h1>
            <p class="text-sm text-slate-600 mt-3 leading-relaxed">{{ __('delivery.blocked_subtitle') }}</p>
        @else
            <div class="w-20 h-20 rounded-full bg-blue-50 border border-blue-200 text-[#1e60eb] flex items-center justify-center mx-auto mb-5 animate-pulse">
                <svg class="w-10 h-10" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                </svg>
            </div>
            <span class="inline-block px-3.5 py-1 rounded-full bg-amber-50 border border-amber-200 text-amber-700 text-xs font-extrabold mb-3">
                {{ __('delivery.wait_status_label') }}
            </span>
            <h1 class="text-xl sm:text-2xl font-black text-slate-900">{{ __('delivery.wait_title') }}</h1>
            <p class="text-sm text-slate-600 mt-3 leading-relaxed">{{ __('delivery.wait_subtitle') }}</p>
        @endif

        <div class="mt-6 p-4 rounded-2xl bg-slate-50 border border-slate-200 text-start flex items-center justify-between gap-3">
            <div>
                <p class="text-[11px] font-bold text-slate-400">{{ __('delivery.registered_phone') }}</p>
                <p class="text-sm font-black text-slate-900 mt-0.5" dir="ltr">{{ $user->phone }}</p>
            </div>
            <div class="text-end">
                <p class="text-xs font-extrabold text-slate-700">{{ $user->name }}</p>
                <p class="text-[11px] text-slate-500">{{ $user->driver->city ?? '' }}</p>
            </div>
        </div>

        <div class="mt-6 flex flex-col sm:flex-row gap-3">
            <a href="{{ $mainSiteHref }}" class="flex-1 py-3 px-4 rounded-xl bg-[#1e60eb] hover:bg-blue-700 text-white text-xs font-extrabold transition">
                {{ __('delivery.back_home') }}
            </a>
            <form method="POST" action="{{ route('delivery.logout') }}" class="flex-1">
                @csrf
                <button type="submit" class="w-full py-3 px-4 rounded-xl bg-white hover:bg-slate-50 border border-slate-200 text-slate-600 text-xs font-bold transition">
                    {{ __('delivery.logout_other') }}
                </button>
            </form>
        </div>
    </div>

    @if($status === 'pending')
    <script>
        setInterval(async () => {
            try {
                const res = await fetch("{{ route('delivery.status') }}", { headers: { 'Accept': 'application/json' } });
                if (!res.ok) return;
                const data = await res.json();
                if (data.status && data.status !== 'pending') {
                    window.location.reload();
                }
            } catch (_) {}
        }, 5000);
    </script>
    @endif

</body>
</html>
