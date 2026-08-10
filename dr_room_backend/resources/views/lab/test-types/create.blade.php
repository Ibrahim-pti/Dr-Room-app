@extends('lab.layouts.app')

@section('content')
<div class="fade-up" style="display:flex;flex-direction:column;gap:24px;padding-bottom:40px;max-width:800px;margin:0 auto;">

    <!-- Header -->
    <div style="display:flex;align-items:center;justify-content:space-between;background:#fff;padding:24px 28px;border-radius:16px;border:1px solid #e2e8f0;">
        <div style="display:flex;align-items:center;gap:16px;">
            <div style="width:48px;height:48px;border-radius:12px;background:#f5f3ff;color:#7c3aed;display:flex;align-items:center;justify-content:center;">
                <svg width="24" height="24" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"/></svg>
            </div>
            <div>
                <h1 style="font-size:1.5rem;font-weight:800;color:#0f172a;margin:0 0 4px;">زیادکردنی جۆری پشکنین</h1>
                <p style="margin:0;color:#64748b;font-size:0.9rem;font-weight:500;">جۆرێکی نوێی پشکنین بۆ سیستەمەکە زیاد بکە</p>
            </div>
        </div>
        <a href="{{ route('lab.dashboard') }}" style="display:flex;align-items:center;gap:8px;padding:10px 16px;border-radius:10px;background:#f1f5f9;color:#475569;font-weight:700;font-size:0.9rem;text-decoration:none;transition:all 0.2s;" onmouseover="this.style.background='#e2e8f0';this.style.color='#0f172a'" onmouseout="this.style.background='#f1f5f9';this.style.color='#475569'">
            <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"/></svg>
            گەڕانەوە
        </a>
    </div>

    <!-- Form Container -->
    <div style="background:#fff;border-radius:16px;border:1px solid #e2e8f0;overflow:hidden;">
        <form action="#" method="POST" style="display:flex;flex-direction:column;">
            @csrf
            
            <div style="padding:28px;display:flex;flex-direction:column;gap:24px;">
                
                <div style="display:grid;grid-template-columns:1fr 1fr;gap:20px;">
                    <!-- Test Name -->
                    <div>
                        <label style="display:block;font-size:0.9rem;font-weight:700;color:#1e293b;margin-bottom:8px;">ناوی پشکنین (بە کوردی)</label>
                        <input type="text" placeholder="بۆ نموونە: پشکنینی شەکرە..." style="width:100%;padding:14px 16px;border-radius:12px;border:1px solid #e2e8f0;background:#f8fafc;font-family:inherit;font-size:0.95rem;outline:none;transition:border 0.2s;box-sizing:border-box;" onfocus="this.style.borderColor='#7c3aed';this.style.background='#fff'" onblur="this.style.borderColor='#e2e8f0';this.style.background='#f8fafc'">
                    </div>

                    <!-- English Name -->
                    <div>
                        <label style="display:block;font-size:0.9rem;font-weight:700;color:#1e293b;margin-bottom:8px;">کورتکراوە / ناوی ئینگلیزی</label>
                        <input type="text" placeholder="بۆ نموونە: FBS..." dir="ltr" style="width:100%;padding:14px 16px;border-radius:12px;border:1px solid #e2e8f0;background:#f8fafc;font-family:inherit;font-size:0.95rem;outline:none;transition:border 0.2s;box-sizing:border-box;" onfocus="this.style.borderColor='#7c3aed';this.style.background='#fff'" onblur="this.style.borderColor='#e2e8f0';this.style.background='#f8fafc'">
                    </div>
                </div>

                <div style="display:grid;grid-template-columns:1fr 1fr;gap:20px;">
                    <!-- Category -->
                    <div>
                        <label style="display:block;font-size:0.9rem;font-weight:700;color:#1e293b;margin-bottom:8px;">پۆلێن (Category)</label>
                        <select style="width:100%;padding:14px 16px;border-radius:12px;border:1px solid #e2e8f0;background:#f8fafc;font-family:inherit;font-size:0.95rem;font-weight:600;color:#475569;outline:none;transition:border 0.2s;box-sizing:border-box;cursor:pointer;" onfocus="this.style.borderColor='#7c3aed';this.style.background='#fff'" onblur="this.style.borderColor='#e2e8f0';this.style.background='#f8fafc'">
                            <option value="blood">پشکنینی خوێن</option>
                            <option value="urine">پشکنینی میز / پیسایی</option>
                            <option value="hormone">هۆرمۆنات</option>
                            <option value="virus">ڤایرۆسات</option>
                            <option value="other">تر...</option>
                        </select>
                    </div>

                    <!-- Price -->
                    <div>
                        <label style="display:block;font-size:0.9rem;font-weight:700;color:#1e293b;margin-bottom:8px;">نرخی پشکنین (دینار)</label>
                        <input type="number" placeholder="0" style="width:100%;padding:14px 16px;border-radius:12px;border:1px solid #e2e8f0;background:#f8fafc;font-family:inherit;font-size:0.95rem;outline:none;transition:border 0.2s;box-sizing:border-box;" onfocus="this.style.borderColor='#7c3aed';this.style.background='#fff'" onblur="this.style.borderColor='#e2e8f0';this.style.background='#f8fafc'">
                    </div>
                </div>

                <!-- Normal Range -->
                <div>
                    <label style="display:block;font-size:0.9rem;font-weight:700;color:#1e293b;margin-bottom:8px;">ڕێژەی ئاسایی (Normal Range)</label>
                    <textarea rows="3" placeholder="ڕێژەی ئاسایی بۆ ئەم پشکنینە بنووسە... بۆ نموونە: 70 - 110 mg/dL" dir="ltr" style="width:100%;padding:14px 16px;border-radius:12px;border:1px solid #e2e8f0;background:#f8fafc;font-family:inherit;font-size:0.95rem;outline:none;transition:border 0.2s;box-sizing:border-box;resize:vertical;" onfocus="this.style.borderColor='#7c3aed';this.style.background='#fff'" onblur="this.style.borderColor='#e2e8f0';this.style.background='#f8fafc'"></textarea>
                </div>

                <!-- Description -->
                <div>
                    <label style="display:block;font-size:0.9rem;font-weight:700;color:#1e293b;margin-bottom:8px;">تێبینی و ڕێنمایی بۆ نەخۆش</label>
                    <textarea rows="2" placeholder="بۆ نموونە: پێویستە نەخۆش بۆ ماوەی ٨ کاتژمێر نانی نەخواردبێت..." style="width:100%;padding:14px 16px;border-radius:12px;border:1px solid #e2e8f0;background:#f8fafc;font-family:inherit;font-size:0.95rem;outline:none;transition:border 0.2s;box-sizing:border-box;resize:vertical;" onfocus="this.style.borderColor='#7c3aed';this.style.background='#fff'" onblur="this.style.borderColor='#e2e8f0';this.style.background='#f8fafc'"></textarea>
                </div>

            </div>

            <!-- Footer Buttons -->
            <div style="padding:20px 28px;background:#f8fafc;border-top:1px solid #e2e8f0;display:flex;justify-content:flex-end;gap:12px;">
                <button type="button" style="padding:12px 24px;border-radius:12px;background:#fff;border:1px solid #cbd5e1;color:#64748b;font-weight:700;font-size:0.95rem;cursor:pointer;transition:all 0.2s;font-family:inherit;" onmouseover="this.style.background='#f1f5f9';this.style.color='#0f172a'" onmouseout="this.style.background='#fff';this.style.color='#64748b'">
                    پاشگەزبوونەوە
                </button>
                <button type="button" onclick="alert('جۆری پشکنینەکە بە سەرکەوتوویی زیادکرا!')" style="padding:12px 28px;border-radius:12px;background:#7c3aed;border:none;color:#fff;font-weight:700;font-size:0.95rem;cursor:pointer;transition:all 0.2s;font-family:inherit;display:flex;align-items:center;gap:8px;" onmouseover="this.style.background='#6d28d9'" onmouseout="this.style.background='#7c3aed'">
                    <svg width="18" height="18" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
                    زیادکردن
                </button>
            </div>
        </form>
    </div>
</div>
@endsection
