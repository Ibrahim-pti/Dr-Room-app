<!DOCTYPE html>
<html lang="ckb" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ $branding['header_title'] ?? 'ڕاپۆرتی فەرمی پشکنین' }} - #{{ $result->id }}</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        @media print {
            .no-print { display: none !important; }
            body { background: #fff !important; padding: 0 !important; }
            .report-sheet { box-shadow: none !important; border: none !important; margin: 0 !important; max-width: 100% !important; }
        }
        .watermark-layer {
            position: absolute;
            inset: 0;
            display: flex;
            align-items: center;
            justify-content: center;
            pointer-events: none;
            z-index: 0;
            overflow: hidden;
        }
        .watermark-text {
            transform: rotate(-28deg);
            font-size: 46px;
            font-weight: 900;
            letter-spacing: 6px;
            color: rgba(99, 102, 241, 0.06);
            white-space: nowrap;
            user-select: none;
        }
    </style>
</head>
<body class="bg-slate-100 min-h-screen py-6 px-4 text-slate-800 font-sans">
@php
    $fileUrl = $result->file_path ? Storage::url($result->file_path) : null;
    $isPdf = $fileUrl && str_ends_with(strtolower($fileUrl), '.pdf');
    $labName = $result->lab?->user?->name ?? $result->lab?->name ?? 'تاقیگەی باوەڕپێکراو';
    $patientName = $result->patient?->name ?? 'نەخۆش';
    $patientPhone = $result->patient?->phone ?? '';
    $testName = $result->test?->name ?? 'پشکنینی تاقیگە';
    $logoUrl = $branding['logo_url'] ?? null;
    $sigUrl = $branding['signature_url'] ?? null;
@endphp

<div class="max-w-4xl mx-auto mb-4 flex items-center justify-between no-print">
    <a href="javascript:history.back()" class="px-4 py-2 bg-white border border-slate-200 rounded-xl text-xs font-bold text-slate-600 hover:bg-slate-50">
        گەڕانەوە
    </a>
    <button onclick="window.print()" class="px-5 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-xs font-bold shadow-sm">
        چاپکردن / سەیڤکردن وەک PDF
    </button>
</div>

<div class="report-sheet relative max-w-4xl mx-auto bg-white rounded-2xl shadow-lg border border-slate-200 overflow-hidden">
    @if(!empty($branding['show_watermark']))
        <div class="watermark-layer">
            <div class="watermark-text">DR. ROOM VERIFIED OFFICIAL</div>
        </div>
    @endif

    <div class="h-2 w-full bg-gradient-to-r from-indigo-600 via-violet-500 to-blue-500 relative z-10"></div>

    <div class="p-6 sm:p-8 relative z-10 space-y-6">
        <!-- Official Header -->
        <div class="flex flex-wrap items-start justify-between gap-4 border-b border-slate-200 pb-5">
            <div class="flex items-start gap-4">
                <div class="w-16 h-16 rounded-2xl border border-slate-200 bg-white overflow-hidden flex items-center justify-center shrink-0">
                    @if($logoUrl)
                        <img src="{{ $logoUrl }}" alt="Logo" class="w-full h-full object-cover">
                    @else
                        <span class="text-indigo-600 font-black text-lg">DR</span>
                    @endif
                </div>
                <div>
                    <h1 class="text-lg sm:text-xl font-black text-slate-900">{{ $branding['header_title'] ?? 'دکتۆر ڕۆم' }}</h1>
                    <p class="text-xs text-slate-500 mt-1" dir="ltr">{{ $branding['header_subtitle'] ?? '' }}</p>
                    <p class="text-xs text-indigo-600 font-bold mt-1" dir="ltr">{{ $branding['emergency_phone'] ?? '' }}</p>
                </div>
            </div>

            <div class="flex flex-col items-end gap-2">
                @if(!empty($branding['show_stamp']))
                    <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-lg bg-emerald-50 text-emerald-700 border border-emerald-400 text-xs font-black">
                        ✓ پەسەندکراوی فەرمی
                    </span>
                @endif
                <span class="text-xs text-slate-500" dir="ltr">#RES-{{ $result->id }} · {{ $result->created_at?->timezone('Asia/Baghdad')->format('Y-m-d H:i') }}</span>
            </div>
        </div>

        <!-- Patient & Lab Details -->
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 bg-slate-50 p-4 rounded-xl border border-slate-200 text-xs">
            <div>
                <span class="text-slate-400 block mb-1">ناوی نەخۆش</span>
                <strong class="text-slate-900 text-sm">{{ $patientName }}</strong>
                @if($patientPhone)
                    <div class="text-slate-500 mt-0.5" dir="ltr">{{ $patientPhone }}</div>
                @endif
            </div>
            <div>
                <span class="text-slate-400 block mb-1">تاقیگەی ئەنجامدەر</span>
                <strong class="text-slate-900 text-sm">{{ $labName }}</strong>
                @if($result->lab?->location)
                    <div class="text-slate-500 mt-0.5">{{ $result->lab->location }}</div>
                @endif
            </div>
            <div>
                <span class="text-slate-400 block mb-1">پشکنین</span>
                <strong class="text-indigo-700 text-sm">{{ $testName }}</strong>
            </div>
        </div>

        <!-- Result & Notes -->
        @if($result->result_value || $result->notes)
            <div class="space-y-3">
                @if($result->result_value)
                    <div class="p-4 rounded-xl bg-blue-50/70 border border-blue-200">
                        <div class="text-xs text-blue-700 font-bold mb-1">ئەنجامی تۆمارکراو</div>
                        <div class="text-base font-black text-slate-900">{{ $result->result_value }}</div>
                    </div>
                @endif
                @if($result->notes)
                    <div class="p-4 rounded-xl bg-slate-50 border border-slate-200">
                        <div class="text-xs text-slate-500 font-bold mb-1">تێبینی و ڕێنمایی پزیشکی</div>
                        <div class="text-sm text-slate-700 leading-relaxed">{{ $result->notes }}</div>
                    </div>
                @endif
            </div>
        @endif

        <!-- Attached Lab File -->
        @if($fileUrl)
            <div class="border border-slate-200 rounded-xl overflow-hidden bg-slate-50">
                <div class="px-4 py-2.5 bg-slate-100 border-b border-slate-200 flex items-center justify-between text-xs">
                    <span class="font-bold text-slate-700">فایلی هاوپێچکراوی تاقیگە</span>
                    <a href="{{ $fileUrl }}" target="_blank" class="text-indigo-600 font-bold hover:underline no-print">کردنەوەی فایلی بنەڕەتی</a>
                </div>
                @if($isPdf)
                    <iframe src="{{ $fileUrl }}" class="w-full h-[650px] bg-white"></iframe>
                @else
                    <div class="p-4 flex justify-center bg-white">
                        <img src="{{ $fileUrl }}" alt="Lab Result" class="max-w-full rounded-lg border border-slate-200">
                    </div>
                @endif
            </div>
        @endif

        <!-- Official Signature & Footer -->
        <div class="border-t border-slate-200 pt-5 flex flex-wrap items-end justify-between gap-6">
            <div class="max-w-xl">
                <p class="text-xs text-slate-600 leading-relaxed">{{ $branding['footer_text'] ?? '' }}</p>
                <p class="text-[11px] text-slate-400 mt-1" dir="ltr">{{ $branding['emergency_phone'] ?? '' }}</p>
            </div>

            @if(!empty($branding['show_signature']))
                <div class="text-center min-w-[180px] p-3 rounded-xl bg-slate-50 border border-slate-200">
                    @if($sigUrl)
                        <img src="{{ $sigUrl }}" alt="Signature" class="h-14 mx-auto object-contain mb-1">
                    @else
                        <div class="h-10 border-b border-dashed border-slate-300 mb-1"></div>
                    @endif
                    <div class="text-xs font-black text-slate-800">{{ $branding['signature_name'] ?? 'بەڕێوەبەری پزیشکی' }}</div>
                    <div class="text-[10px] text-slate-500">{{ $branding['signature_title'] ?? 'واژووی فەرمی' }}</div>
                </div>
            @endif
        </div>
    </div>
</div>
</body>
</html>
