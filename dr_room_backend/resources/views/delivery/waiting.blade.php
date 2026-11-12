@php
    $loc = $locale ?? app()->getLocale();
    $isRtl = in_array($loc, ['ar', 'ckb', 'kmr']);
    $status = $user->status ?? 'pending';
    $profile = $user->driver ? $user->driver->resolvedFieldProfile() : [];
    $applicantRole = $profile['applicant_role'] ?? 'phlebotomist';
    $serviceAreas = $profile['service_areas'] ?? null;
    $shiftKey = $profile['availability_shift'] ?? null;
    $shiftLabels = __('delivery.shifts');
    $shiftText = ($shiftKey && is_array($shiftLabels) && isset($shiftLabels[$shiftKey])) ? $shiftLabels[$shiftKey] : null;
    $wfSteps = __('delivery.wf_steps');

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
    <link rel="shortcut icon" href="{{ asset('favicon.ico') }}">
    <link rel="apple-touch-icon" href="{{ asset('images/logo.png') }}">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Noto+Kufi+Arabic:wght@400;600;700;800;900&family=Plus+Jakarta+Sans:wght@400;600;700;800&display=swap" rel="stylesheet">
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
    <style>
        body {
            background: #F4EFE6;
            color: #1C1A17;
            font-family: {{ $isRtl ? "'Noto Kufi Arabic', sans-serif" : "'Plus Jakarta Sans', 'Noto Kufi Arabic', sans-serif" }};
            -webkit-font-smoothing: antialiased;
        }
    </style>
</head>
<body class="min-h-screen flex flex-col">

    <!-- Top Navigation matching main recruitment portal -->
    <header class="border-b border-[#E6DDD0] bg-[#F4EFE6]">
        <div class="w-full max-w-5xl mx-auto px-5 h-[70px] flex items-center justify-between gap-3">
            <a href="{{ $mainSiteHref }}" class="flex items-center gap-3 min-w-0">
                <img src="{{ asset('images/logo.png') }}" alt="DrRoom" class="w-10 h-10 rounded-xl border border-[#E6DDD0] bg-[#FFFCF7] p-1 object-contain flex-shrink-0">
                <div class="flex items-center gap-2 min-w-0">
                    <span class="text-lg font-black leading-none" dir="ltr">Dr<span class="text-[#FF5A00]">Room</span></span>
                    <span class="hidden sm:inline-block px-3 py-1 rounded-full border border-[#EAE1D5] bg-[#FFFCF7] text-[11px] font-extrabold text-[#1C1A17]">
                        {{ __('delivery.brand_tag') }}
                    </span>
                </div>
            </a>

            <div class="flex items-center gap-2">
                <a href="{{ $mainSiteHref }}" class="hidden sm:inline-flex items-center h-9 px-3.5 rounded-xl border border-[#DFD5C7] bg-[#FFFCF7] hover:bg-[#1C1A17] hover:text-white text-xs font-extrabold transition">
                    {{ __('delivery.nav_home') }}
                </a>
                <a href="{{ route('staff.landing') }}" class="inline-flex items-center h-9 px-3.5 rounded-xl border border-[#DFD5C7] bg-[#FFFCF7] hover:bg-[#1C1A17] hover:text-white text-xs font-extrabold transition">
                    {{ __('delivery.nav_staff') }}
                </a>
            </div>
        </div>
    </header>

    <!-- Main Centered Status Container -->
    <main class="flex-1 flex items-center justify-center px-4 py-8 sm:py-12">
        <div class="w-full max-w-2xl bg-[#FFFCF7] rounded-[24px] border border-[#EAE1D5] overflow-hidden">

            <!-- Status Header Banner -->
            @if($status === 'approved')
                <div class="bg-[#ECFDF5] border-b border-[#D1FAE5] px-6 sm:px-9 py-8 text-center">
                    <div class="w-16 h-16 rounded-2xl bg-[#10B981] text-white flex items-center justify-center mx-auto mb-4">
                        <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.4" d="M5 13l4 4L19 7"></path>
                        </svg>
                    </div>
                    <h1 class="text-xl sm:text-2xl font-black text-[#065F46] leading-[1.65]">{{ __('delivery.approved_title') }}</h1>
                    <p class="text-xs sm:text-sm text-[#047857] mt-2.5 leading-[1.9] max-w-lg mx-auto font-medium">{{ __('delivery.approved_subtitle') }}</p>
                </div>
            @elseif($status === 'blocked')
                <div class="bg-[#FEF2F2] border-b border-[#FECACA] px-6 sm:px-9 py-8 text-center">
                    <div class="w-16 h-16 rounded-2xl bg-[#EF4444] text-white flex items-center justify-center mx-auto mb-4">
                        <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.4" d="M6 18L18 6M6 6l12 12"></path>
                        </svg>
                    </div>
                    <h1 class="text-xl sm:text-2xl font-black text-[#991B1B] leading-[1.65]">{{ __('delivery.blocked_title') }}</h1>
                    <p class="text-xs sm:text-sm text-[#B91C1C] mt-2.5 leading-[1.9] max-w-lg mx-auto font-medium">{{ __('delivery.blocked_subtitle') }}</p>
                </div>
            @else
                <div class="bg-[#FFF6EF] border-b border-[#FFE2CC] px-6 sm:px-9 py-8 text-center">
                    <div class="w-16 h-16 rounded-2xl bg-[#FF5A00] text-white flex items-center justify-center mx-auto mb-4">
                        <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                        </svg>
                    </div>
                    <span class="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-white border border-[#FFD6B8] text-[#C43F00] text-xs font-extrabold mb-3">
                        <span class="w-2 h-2 rounded-full bg-[#FF5A00] animate-ping"></span>
                        {{ __('delivery.wait_status_label') }}
                    </span>
                    <h1 class="text-xl sm:text-2xl font-black text-[#1C1A17] leading-[1.65]">{{ __('delivery.wait_title') }}</h1>
                    <p class="text-xs sm:text-sm text-[#5F574D] mt-2.5 leading-[1.9] max-w-lg mx-auto font-medium">{{ __('delivery.wait_subtitle') }}</p>
                </div>
            @endif

            <!-- Body Content -->
            <div class="p-6 sm:p-8 space-y-6">

                <!-- Clean 3-Stage Stepper -->
                @if($status !== 'blocked')
                    <div class="grid grid-cols-3 gap-2.5 items-start">
                        <div class="p-3 rounded-2xl bg-[#FAF5ED] border border-[#EAE1D5] text-start">
                            <div class="w-6 h-6 rounded-full bg-[#10B981] text-white flex items-center justify-center text-xs font-black mb-2">✓</div>
                            <p class="text-[11px] font-black text-[#1C1A17] leading-[1.55]">{{ $wfSteps[0]['t'] ?? '' }}</p>
                        </div>
                        <div class="p-3 rounded-2xl border text-start {{ $status === 'approved' ? 'bg-[#FAF5ED] border-[#EAE1D5]' : 'bg-[#FFF4EC] border-[#FF5A00]' }}">
                            <div class="w-6 h-6 rounded-full flex items-center justify-center text-xs font-black mb-2 {{ $status === 'approved' ? 'bg-[#10B981] text-white' : 'bg-[#FF5A00] text-white' }}">
                                {{ $status === 'approved' ? '✓' : ($isRtl ? '٢' : '2') }}
                            </div>
                            <p class="text-[11px] font-black text-[#1C1A17] leading-[1.55]">{{ $wfSteps[1]['t'] ?? '' }}</p>
                        </div>
                        <div class="p-3 rounded-2xl border text-start {{ $status === 'approved' ? 'bg-[#ECFDF5] border-[#10B981]' : 'bg-[#FAF5ED] border-[#EAE1D5] opacity-75' }}">
                            <div class="w-6 h-6 rounded-full flex items-center justify-center text-xs font-black mb-2 {{ $status === 'approved' ? 'bg-[#10B981] text-white' : 'bg-[#E5DDD0] text-[#5F574D]' }}">
                                {{ $status === 'approved' ? '✓' : ($isRtl ? '٣' : '3') }}
                            </div>
                            <p class="text-[11px] font-black text-[#1C1A17] leading-[1.55]">{{ $wfSteps[2]['t'] ?? '' }}</p>
                        </div>
                    </div>
                @endif

                <!-- Structured 2x2 Summary Cards -->
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 text-start">
                    <div class="p-4 rounded-2xl bg-[#FAF5ED] border border-[#EAE1D5]">
                        <p class="text-[11px] font-bold text-[#6E665B]">{{ __('delivery.full_name') }}</p>
                        <p class="text-sm font-black text-[#1C1A17] mt-1">{{ $user->name }}</p>
                        @if($user->driver && $user->driver->city)
                            <p class="text-xs font-bold text-[#5F574D] mt-0.5">{{ $user->driver->city }}</p>
                        @endif
                    </div>

                    <div class="p-4 rounded-2xl bg-[#FAF5ED] border border-[#EAE1D5]">
                        <p class="text-[11px] font-bold text-[#6E665B]">{{ __('delivery.registered_phone') }}</p>
                        <p class="text-sm font-black text-[#1C1A17] mt-1" dir="ltr">{{ $user->phone }}</p>
                        <p class="text-[11px] font-medium text-[#5F574D] mt-0.5">{{ __('delivery.phone_hint') }}</p>
                    </div>

                    <div class="p-4 rounded-2xl bg-[#FAF5ED] border border-[#EAE1D5] {{ (!$shiftText && !$serviceAreas) ? 'sm:col-span-2' : '' }}">
                        <p class="text-[11px] font-bold text-[#6E665B]">{{ __('delivery.compare_badge') }}</p>
                        <span class="inline-block mt-1.5 px-3 py-1 rounded-full bg-[#FFF2E8] border border-[#FFD4B8] text-[#C43F00] text-xs font-extrabold">
                            {{ __("delivery.role_short_{$applicantRole}") }}
                        </span>
                    </div>

                    @if($shiftText || $serviceAreas)
                        <div class="p-4 rounded-2xl bg-[#FAF5ED] border border-[#EAE1D5]">
                            <p class="text-[11px] font-bold text-[#6E665B]">{{ __('delivery.step_3_short') }}</p>
                            @if($shiftText)
                                <p class="text-xs font-black text-[#1C1A17] mt-1">{{ $shiftText }}</p>
                            @endif
                            @if($serviceAreas)
                                <p class="text-[11.5px] font-medium text-[#5F574D] mt-0.5">{{ $serviceAreas }}</p>
                            @endif
                        </div>
                    @endif
                </div>

                <!-- Symmetrical Action Buttons (1 line each, matched height) -->
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-1">
                    <a href="{{ $mainSiteHref }}"
                       class="min-h-[48px] px-5 rounded-2xl bg-[#FF5A00] hover:bg-[#DC4900] text-white text-xs sm:text-[13px] font-extrabold flex items-center justify-center whitespace-nowrap transition">
                        {{ __('delivery.back_home') }}
                    </a>
                    <form method="POST" action="{{ route('delivery.logout') }}" class="w-full">
                        @csrf
                        <button type="submit"
                                class="w-full min-h-[48px] px-5 rounded-2xl bg-white hover:bg-[#FAF5ED] border border-[#DDD3C4] text-[#1C1A17] text-xs sm:text-[13px] font-extrabold flex items-center justify-center whitespace-nowrap transition">
                            {{ __('delivery.logout_other') }}
                        </button>
                    </form>
                </div>

            </div>
        </div>
    </main>

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
