{{--
    Shown for dashboard sections that are routed but not built yet.

    This page must never render sample rows, sample counts or controls that do
    nothing. An earlier version filled the table with invented patient records
    and status badges; in a medical dashboard that is indistinguishable from
    real data and someone can act on it. Say plainly that the section is not
    ready and send the user somewhere that works.
--}}
@extends($layout)

@section('content')
<div class="fade-up" style="display:flex;flex-direction:column;gap:24px;padding-bottom:40px;">

    <div style="background:#fff;padding:24px 28px;border-radius:16px;border:1px solid #e2e8f0;">
        <h1 style="font-size:1.6rem;font-weight:800;color:#0f172a;margin:0 0 6px;">{{ $title ?? 'بەش' }}</h1>
        <p style="margin:0;color:#64748b;font-size:0.9rem;font-weight:500;">
            ئەم بەشە هێشتا ئامادە نەکراوە
        </p>
    </div>

    <div style="background:#fff;border-radius:16px;border:1px solid #e2e8f0;padding:48px 28px;text-align:center;">

        <div style="width:64px;height:64px;margin:0 auto 20px;border-radius:16px;background:#f1f5f9;display:flex;align-items:center;justify-content:center;">
            <svg width="30" height="30" fill="none" stroke="#64748b" viewBox="0 0 24 24" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                      d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/>
            </svg>
        </div>

        <h2 style="font-size:1.15rem;font-weight:800;color:#0f172a;margin:0 0 10px;">
            «{{ $title ?? 'ئەم بەشە' }}» بەم زووانە دادەمەزرێت
        </h2>

        <p style="margin:0 auto 8px;max-width:460px;color:#475569;font-size:0.92rem;line-height:1.8;">
            هێشتا هیچ داتایەکی ڕاستەقینە بۆ ئەم بەشە نییە. هەرچی لێرە ببینیت
            دواتر لە سیستەمەوە دێت — ئێستا هیچ ژمارە و تۆمارێک پیشان نادرێت
            تاکو بە هەڵە وەک زانیاری ڕاستەقینە وەرنەگیرێت.
        </p>

        <p style="margin:0 auto 28px;max-width:460px;color:#94a3b8;font-size:0.85rem;line-height:1.7;">
            ئەگەر پێویستت بەم بەشە هەیە، لەگەڵ تیمی گەشەپێدان پەیوەندی بکە.
        </p>

        <a href="{{ url()->previous() }}"
           style="display:inline-flex;align-items:center;justify-content:center;gap:8px;padding:11px 22px;border-radius:12px;background:#4f46e5;color:#fff;font-weight:700;font-size:0.9rem;text-decoration:none;">
            گەڕانەوە
        </a>
    </div>

</div>
@endsection
