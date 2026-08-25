import os
import subprocess
from PIL import Image

output_dir = "/Users/ibrahimpti/Desktop/Dr-Room-/dr_room_backend/public/images"
temp_dir = "/Users/ibrahimpti/Desktop/Dr-Room-/dr_room_backend/scratch_mockups"
os.makedirs(temp_dir, exist_ok=True)
os.makedirs(output_dir, exist_ok=True)

# Generate an 800x844 page with centered 390x844 phone wrapper
common_head = """<!DOCTYPE html>
<html lang="ckb" dir="rtl">
<head>
<meta charset="UTF-8">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Noto+Kufi+Arabic:wght@400;500;600;700;800;900&family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<script src="https://cdn.tailwindcss.com"></script>
<style>
* { font-family: 'Noto Kufi Arabic', 'Plus Jakarta Sans', sans-serif; box-sizing: border-box; }
body { margin: 0; padding: 0; width: 800px; height: 844px; background: #f1f5f9; display: flex; justify-content: center; align-items: center; }
.phone-frame { width: 390px; height: 844px; background: #ffffff; overflow: hidden; display: flex; flex-direction: column; justify-content: space-between; }
</style>
</head>
<body class="select-none">
<div class="phone-frame bg-slate-50 text-slate-800 antialiased">
"""

# Screen 1
screen1_html = common_head + """
  <!-- Top Bar -->
  <div class="pt-8 px-4 pb-3 bg-white border-b border-slate-100 flex items-center justify-between">
    <div class="flex items-center gap-2.5">
      <div class="w-10 h-10 rounded-full bg-gradient-to-tr from-blue-600 to-indigo-600 p-0.5 shadow-md">
        <img class="w-full h-full rounded-full object-cover border-2 border-white" src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80" alt="Avatar">
      </div>
      <div>
        <div class="text-[10px] text-slate-400 font-medium">سڵاو، بەخێربێیت 👋</div>
        <div class="text-xs font-extrabold text-slate-900">سارا ئەحمەد</div>
      </div>
    </div>
    <div class="flex items-center gap-2">
      <div class="w-8 h-8 rounded-xl bg-slate-50 border border-slate-100 flex items-center justify-center text-slate-600 relative">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"></path></svg>
        <span class="absolute top-1 end-1 w-2 h-2 rounded-full bg-blue-600 ring-2 ring-white"></span>
      </div>
    </div>
  </div>

  <!-- Main Content -->
  <div class="flex-1 px-4 py-3 space-y-3 flex flex-col justify-start overflow-hidden">
    <!-- Search Bar -->
    <div class="relative">
      <div class="absolute inset-y-0 start-0 ps-3 flex items-center pointer-events-none text-slate-400">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path></svg>
      </div>
      <div class="w-full py-2.5 ps-9 pe-3 bg-white border border-slate-200/90 rounded-2xl text-[11px] text-slate-400 shadow-sm flex items-center">
        گەڕان بۆ پزیشک، پەرستار، تاقیگە...
      </div>
    </div>

    <!-- Promo Banner -->
    <div class="rounded-2xl bg-gradient-to-r from-blue-600 to-indigo-600 p-3.5 text-white shadow-lg shadow-blue-500/20 flex items-center justify-between">
      <div class="max-w-[210px]">
        <span class="bg-white/20 backdrop-blur-md text-[9px] font-bold px-2 py-0.5 rounded-md">خزمەتگوزاری لە ماڵەوە</span>
        <h3 class="text-xs font-extrabold mt-1 leading-snug">پشکنینی گشتی خوێن (CBC)</h3>
        <p class="text-[10px] text-blue-100 mt-0.5">وەرگرتنی نموونە لە ماڵەوە بە خێرایی</p>
      </div>
      <div class="w-12 h-12 bg-white/10 rounded-2xl flex items-center justify-center text-2xl border border-white/20 shadow-inner flex-shrink-0">
        🧪
      </div>
    </div>

    <!-- Categories Grid -->
    <div>
      <div class="flex items-center justify-between mb-1.5 px-0.5">
        <h4 class="text-xs font-extrabold text-slate-900">بەشە سەرەکییەکان</h4>
        <span class="text-[10px] font-bold text-blue-600">هەمووی</span>
      </div>
      <div class="grid grid-cols-4 gap-2">
        <div class="bg-white p-2 rounded-2xl border border-slate-100 shadow-sm flex flex-col items-center text-center">
          <div class="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center text-lg mb-1 shadow-sm">🧪</div>
          <span class="text-[10px] font-bold text-slate-800">تاقیگە</span>
        </div>
        <div class="bg-white p-2 rounded-2xl border border-slate-100 shadow-sm flex flex-col items-center text-center">
          <div class="w-10 h-10 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center text-lg mb-1 shadow-sm">👩‍⚕️</div>
          <span class="text-[10px] font-bold text-slate-800">پەرستاری</span>
        </div>
        <div class="bg-white p-2 rounded-2xl border border-slate-100 shadow-sm flex flex-col items-center text-center">
          <div class="w-10 h-10 rounded-xl bg-purple-50 text-purple-600 flex items-center justify-center text-lg mb-1 shadow-sm">👨‍⚕️</div>
          <span class="text-[10px] font-bold text-slate-800">پزیشک</span>
        </div>
        <div class="bg-white p-2 rounded-2xl border border-slate-100 shadow-sm flex flex-col items-center text-center">
          <div class="w-10 h-10 rounded-xl bg-rose-50 text-rose-600 flex items-center justify-center text-lg mb-1 shadow-sm">💊</div>
          <span class="text-[10px] font-bold text-slate-800">دەرمانخانە</span>
        </div>
      </div>
    </div>

    <!-- Active Home Service Card -->
    <div class="bg-white rounded-2xl p-3 border border-blue-100 shadow-sm">
      <div class="flex items-center justify-between mb-1.5">
        <div class="flex items-center gap-1.5 text-blue-600 text-[10px] font-bold">
          <span class="w-2 h-2 rounded-full bg-blue-600"></span>
          نۆرەی داهاتوو لە ماڵەوە
        </div>
        <span class="text-[9px] bg-blue-50 text-blue-700 px-2 py-0.5 rounded-md font-bold">ئەمڕۆ ٤:٣٠ پ.ن</span>
      </div>
      <div class="flex items-center gap-2.5">
        <img src="https://images.unsplash.com/photo-1594824813589-322f7b8d4f40?w=150&auto=format&fit=crop&q=80" class="w-10 h-10 rounded-xl object-cover border border-slate-100 shadow-sm" alt="Nurse">
        <div class="flex-1">
          <div class="text-xs font-bold text-slate-900">پەرستار لەیلا کەریم</div>
          <div class="text-[9px] text-slate-500">دانانی کانیۆلا و دەرزی ماسولکە</div>
        </div>
        <div class="w-7 h-7 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center">
          <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"></path></svg>
        </div>
      </div>
    </div>

    <!-- Doctors Highlight -->
    <div class="bg-white rounded-2xl p-2.5 border border-slate-100 shadow-sm">
      <div class="flex items-center justify-between mb-1.5">
        <h4 class="text-xs font-extrabold text-slate-900">پزیشکانی متمانەپێکراو</h4>
        <span class="text-[9px] text-slate-400">هەولێر</span>
      </div>
      <div class="flex items-center gap-2">
        <img src="https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=120&auto=format&fit=crop&q=80" class="w-9 h-9 rounded-xl object-cover border border-slate-100" alt="Doctor">
        <div class="flex-1">
          <div class="text-xs font-bold text-slate-900">د. هێمن کاروان</div>
          <div class="text-[9px] text-slate-500">پسپۆڕی نەخۆشییەکانی دڵ</div>
        </div>
        <div class="text-xs font-bold text-amber-500 bg-amber-50 px-2 py-0.5 rounded-lg">4.9 ★</div>
      </div>
    </div>
  </div>

  <!-- Bottom Navigation -->
  <div class="bg-white border-t border-slate-100 px-6 py-2.5 flex items-center justify-between shadow-lg">
    <div class="flex flex-col items-center text-blue-600">
      <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20"><path d="M10.707 2.293a1 1 0 00-1.414 0l-7 7a1 1 0 001.414 1.414L4 10.414V17a1 1 0 001 1h2a1 1 0 001-1v-2a1 1 0 011-1h2a1 1 0 011 1v2a1 1 0 001 1h2a1 1 0 001-1v-6.586l.293.293a1 1 0 001.414-1.414l-7-7z"></path></svg>
      <span class="text-[9px] font-bold mt-0.5">سەرەکی</span>
    </div>
    <div class="flex flex-col items-center text-slate-400">
      <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"></path></svg>
      <span class="text-[9px] font-bold mt-0.5">نۆرەکان</span>
    </div>
    <div class="flex flex-col items-center text-slate-400">
      <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"></path></svg>
      <span class="text-[9px] font-bold mt-0.5">مەلەف</span>
    </div>
    <div class="flex flex-col items-center text-slate-400">
      <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path></svg>
      <span class="text-[9px] font-bold mt-0.5">هەژمار</span>
    </div>
  </div>
</div>
</body>
</html>
"""

# Screen 2
screen2_html = common_head + """
  <!-- Top Bar -->
  <div class="pt-8 px-4 pb-3 bg-white flex items-center justify-between border-b border-slate-100">
    <div class="w-8 h-8 rounded-xl bg-slate-100 flex items-center justify-center text-slate-700">
      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path></svg>
    </div>
    <div class="text-xs font-extrabold text-slate-900">پڕۆفایلی پزیشک</div>
    <div class="w-8 h-8 rounded-xl bg-rose-50 text-rose-500 flex items-center justify-center">
      <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M3.172 5.172a4 4 0 015.656 0L10 6.343l1.172-1.171a4 4 0 115.656 5.656L10 17.657l-6.828-6.829a4 4 0 010-5.656z" clip-rule="evenodd"></path></svg>
    </div>
  </div>

  <!-- Content -->
  <div class="flex-1 px-4 py-3 space-y-3 overflow-hidden flex flex-col justify-start">
    <div class="bg-white rounded-3xl p-3.5 border border-slate-100 shadow-sm flex flex-col items-center text-center">
      <div class="w-14 h-14 rounded-2xl overflow-hidden shadow-md border-2 border-blue-500/30 mb-2">
        <img src="https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=200&auto=format&fit=crop&q=80" class="w-full h-full object-cover" alt="Doctor">
      </div>
      <h3 class="text-xs font-extrabold text-slate-900">د. سارا کەمال</h3>
      <p class="text-[10px] text-blue-600 font-bold mt-0.5">پسپۆڕی نەخۆشییەکانی پێست و جوانکاری</p>
      
      <div class="grid grid-cols-3 gap-2 w-full mt-2.5 pt-2 border-t border-slate-100">
        <div class="text-center">
          <div class="text-xs font-extrabold text-slate-900">+1.8K</div>
          <div class="text-[8px] text-slate-400">نەخۆش</div>
        </div>
        <div class="text-center border-x border-slate-100">
          <div class="text-xs font-extrabold text-slate-900">٩ ساڵ</div>
          <div class="text-[8px] text-slate-400">ئەزموون</div>
        </div>
        <div class="text-center">
          <div class="text-xs font-extrabold text-amber-500">4.9 ★</div>
          <div class="text-[8px] text-slate-400">هەڵسەنگاندن</div>
        </div>
      </div>
    </div>

    <div>
      <h4 class="text-xs font-extrabold text-slate-900 mb-1">دەربارەی پزیشک</h4>
      <p class="text-[10px] text-slate-600 leading-relaxed bg-white p-2.5 rounded-2xl border border-slate-100">
        خاوەنی بڕوانامەی بۆردی عەرەبی لە نەخۆشییەکانی پێست و جوانکاری، بەردەستە بۆ ڕاوێژی ئۆنلاین و بینینی نەخۆش لە ماڵەوە لە شاری هەولێر.
      </p>
    </div>

    <div>
      <div class="flex items-center justify-between mb-1">
        <h4 class="text-xs font-extrabold text-slate-900">دیاریکردنی بەروار</h4>
        <span class="text-[9px] font-bold text-blue-600">ئاب ٢٠٢٦</span>
      </div>
      <div class="flex gap-2 justify-between">
        <div class="flex-1 bg-blue-600 text-white rounded-2xl py-1.5 flex flex-col items-center shadow-md shadow-blue-500/20">
          <span class="text-[8px] opacity-80">دووشەممە</span>
          <span class="text-xs font-extrabold">٢٥</span>
        </div>
        <div class="flex-1 bg-white text-slate-700 rounded-2xl py-1.5 flex flex-col items-center border border-slate-100">
          <span class="text-[8px] text-slate-400">سێشەممە</span>
          <span class="text-xs font-extrabold">٢٦</span>
        </div>
        <div class="flex-1 bg-white text-slate-700 rounded-2xl py-1.5 flex flex-col items-center border border-slate-100">
          <span class="text-[8px] text-slate-400">چوارشەممە</span>
          <span class="text-xs font-extrabold">٢٧</span>
        </div>
        <div class="flex-1 bg-white text-slate-700 rounded-2xl py-1.5 flex flex-col items-center border border-slate-100">
          <span class="text-[8px] text-slate-400">پێنجشەممە</span>
          <span class="text-xs font-extrabold">٢٨</span>
        </div>
      </div>
    </div>

    <div>
      <h4 class="text-xs font-extrabold text-slate-900 mb-1">کاتی بەردەست</h4>
      <div class="grid grid-cols-3 gap-2 text-center">
        <div class="py-1.5 bg-blue-50 text-blue-600 rounded-xl text-[10px] font-bold border border-blue-200">١٠:٠٠ بەیانی</div>
        <div class="py-1.5 bg-white text-slate-700 rounded-xl text-[10px] font-bold border border-slate-100">١١:٣٠ بەیانی</div>
        <div class="py-1.5 bg-white text-slate-700 rounded-xl text-[10px] font-bold border border-slate-100">٠٤:٠٠ ئێوارە</div>
      </div>
    </div>
  </div>

  <!-- Bottom CTA -->
  <div class="p-3 bg-white border-t border-slate-100 shadow-xl flex items-center gap-2.5">
    <div class="w-9 h-9 rounded-2xl bg-emerald-50 text-emerald-600 flex items-center justify-center flex-shrink-0">
      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"></path></svg>
    </div>
    <button class="flex-1 py-2.5 bg-blue-600 text-white rounded-2xl font-extrabold text-[11px] shadow-lg shadow-blue-500/25">
      حجزکردنی نۆرە (٣٠,٠٠٠ د.ع)
    </button>
  </div>
</div>
</body>
</html>
"""

# Screen 3
screen3_html = common_head + """
  <!-- Top Bar -->
  <div class="pt-8 px-4 pb-2.5 bg-white flex items-center justify-between border-b border-slate-100 z-20">
    <div class="w-7 h-7 rounded-xl bg-slate-100 flex items-center justify-center text-slate-700">
      <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path></svg>
    </div>
    <div class="text-[11px] font-extrabold text-slate-900">چاودێری ڕاستەوخۆی تیمی پزیشکی</div>
    <div class="w-2 h-2 rounded-full bg-emerald-500 animate-ping"></div>
  </div>

  <!-- Map Graphic Area -->
  <div class="flex-1 relative bg-[#e2e8f0] overflow-hidden flex flex-col justify-between">
    <div class="absolute inset-0 bg-[#e8ecf0]">
      <svg class="w-full h-full" xmlns="http://www.w3.org/2000/svg">
        <path d="M-50,160 L450,180" stroke="#ffffff" stroke-width="18" fill="none"/>
        <path d="M100,-50 L120,900" stroke="#ffffff" stroke-width="20" fill="none"/>
        <path d="M240,-50 L260,900" stroke="#ffffff" stroke-width="16" fill="none"/>
        <path d="M-50,380 L450,360" stroke="#ffffff" stroke-width="14" fill="none"/>
        <path d="M110,120 Q160,200 240,280" stroke="#2563eb" stroke-width="5" stroke-dasharray="6 4" fill="none"/>
      </svg>
      
      <div class="absolute top-[260px] end-[80px] flex flex-col items-center">
        <div class="bg-blue-600 text-white text-[8px] font-bold px-1.5 py-0.5 rounded shadow mb-0.5">ماڵی تۆ 🏠</div>
        <div class="w-6 h-6 rounded-full bg-blue-600/30 flex items-center justify-center">
          <div class="w-3 h-3 rounded-full bg-blue-600 border-2 border-white shadow"></div>
        </div>
      </div>

      <div class="absolute top-[100px] start-[90px] flex flex-col items-center">
        <div class="bg-slate-900 text-white text-[8px] font-bold px-1.5 py-0.5 rounded shadow mb-0.5 flex items-center gap-1">
          <span>پەرستار ئەحمەد</span>
          <span class="text-emerald-400 font-bold">• ١٢ خولەک</span>
        </div>
        <div class="w-8 h-8 rounded-xl bg-white shadow-xl border-2 border-blue-600 flex items-center justify-center text-sm">
          🛵
        </div>
      </div>
    </div>

    <!-- Live ETA Floating Card -->
    <div class="p-3 z-10">
      <div class="bg-white/95 backdrop-blur-md rounded-2xl p-3 border border-slate-200 shadow-xl space-y-2">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-1.5">
            <span class="w-2 h-2 rounded-full bg-emerald-500"></span>
            <span class="text-[10px] font-extrabold text-slate-900">تیمی پەرستاری لە ڕێگایە بۆ ماڵەکەت</span>
          </div>
          <span class="text-[9px] font-black text-blue-600 bg-blue-50 px-2 py-0.5 rounded-md">١٢ خولەک ماوە</span>
        </div>

        <div class="w-full bg-slate-100 h-1.5 rounded-full overflow-hidden">
          <div class="bg-blue-600 h-full w-3/4 rounded-full"></div>
        </div>

        <div class="flex items-center justify-between pt-1.5 border-t border-slate-100">
          <div class="flex items-center gap-2">
            <img src="https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=120&auto=format&fit=crop&q=80" class="w-8 h-8 rounded-xl object-cover border border-slate-100 shadow-sm" alt="Staff">
            <div>
              <div class="text-[11px] font-bold text-slate-900">پەرستار ئەحمەد ڕەزا</div>
              <div class="text-[8px] text-slate-500">وەرگرتنی نموونەی پشکنینی خوێن (CBC)</div>
            </div>
          </div>
          <div class="w-7 h-7 rounded-xl bg-blue-600 text-white flex items-center justify-center shadow">
            <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"></path></svg>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
</body>
</html>
"""

# Screen 4
screen4_html = common_head + """
  <!-- Top Bar -->
  <div class="pt-8 px-4 pb-3 bg-white flex items-center justify-between border-b border-slate-100">
    <div class="text-xs font-extrabold text-slate-900">مەلەفی پزیشکی دیجیتاڵی</div>
    <div class="w-6 h-6 rounded-lg bg-blue-50 text-blue-600 flex items-center justify-center font-bold text-xs">
      +
    </div>
  </div>

  <div class="flex-1 px-4 py-3 space-y-2.5 overflow-hidden flex flex-col justify-start">
    <div class="bg-white rounded-2xl p-2.5 border border-slate-100 shadow-sm flex items-center justify-between">
      <div class="flex items-center gap-2">
        <div class="w-8 h-8 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center text-sm">🧪</div>
        <div>
          <div class="text-[11px] font-bold text-slate-900">پشکنینی گشتی (Full Checkup)</div>
          <div class="text-[8px] text-slate-400">تاقیگەی نێودەوڵەتی • دوێنێ</div>
        </div>
      </div>
      <span class="text-[8px] font-bold text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded-md">ئامادەیە PDF</span>
    </div>

    <div class="bg-white rounded-2xl p-2.5 border border-slate-100 shadow-sm flex items-center justify-between">
      <div class="flex items-center gap-2">
        <div class="w-8 h-8 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center text-sm">📋</div>
        <div>
          <div class="text-[11px] font-bold text-slate-900">ڕەچەتەی پزیشکی ئەلیکترۆنی</div>
          <div class="text-[8px] text-slate-400">د. هیوا عەلی • گەیاندراوە</div>
        </div>
      </div>
      <span class="text-[8px] font-bold text-blue-600 bg-blue-50 px-2 py-0.5 rounded-md">دەرمانخانە</span>
    </div>

    <div class="bg-white rounded-2xl p-2.5 border border-slate-100 shadow-sm flex items-center justify-between">
      <div class="flex items-center gap-2">
        <div class="w-8 h-8 rounded-xl bg-purple-50 text-purple-600 flex items-center justify-center text-sm">🩻</div>
        <div>
          <div class="text-[11px] font-bold text-slate-900">تیشکی سنگی (Chest X-Ray)</div>
          <div class="text-[8px] text-slate-400">سەنتەری تیشکی هەولێر</div>
        </div>
      </div>
      <span class="text-[8px] font-bold text-purple-600 bg-purple-50 px-2 py-0.5 rounded-md">بینین</span>
    </div>

    <div class="bg-gradient-to-tr from-slate-900 to-slate-800 rounded-2xl p-3 text-white shadow-md">
      <div class="text-[11px] font-extrabold text-blue-400 mb-1.5">کورتەی تەندروستی تۆ</div>
      <div class="grid grid-cols-2 gap-2">
        <div class="bg-white/10 rounded-xl p-2">
          <div class="text-[8px] text-slate-300">گروپی خوێن</div>
          <div class="text-[11px] font-extrabold text-white mt-0.5">O+ پۆزەتیڤ</div>
        </div>
        <div class="bg-white/10 rounded-xl p-2">
          <div class="text-[8px] text-slate-300">پەستانی خوێن</div>
          <div class="text-[11px] font-extrabold text-emerald-400 mt-0.5">120 / 80 mmHg</div>
        </div>
      </div>
    </div>
  </div>
</div>
</body>
</html>
"""

files = [
    ("app-screen-front.html", screen1_html, "app-screen-front.png"),
    ("app-screen-back.html", screen2_html, "app-screen-back.png"),
    ("app-screen-map.html", screen3_html, "app-screen-map.png"),
    ("app-screen-banner.html", screen4_html, "app-screen-banner.png"),
]

for html_name, content, png_name in files:
    html_path = os.path.join(temp_dir, html_name)
    with open(html_path, "w", encoding="utf-8") as f:
        f.write(content)
    
    raw_png = os.path.join(temp_dir, f"raw_{png_name}")
    final_png = os.path.join(output_dir, png_name)
    
    cmd = [
        "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
        "--headless",
        "--disable-gpu",
        "--window-size=800,844",
        f"--screenshot={raw_png}",
        f"file://{html_path}"
    ]
    subprocess.run(cmd, check=True)
    
    # Open with PIL and crop center 390x844
    img = Image.open(raw_png)
    # The center is ((800-390)//2, 0, (800+390)//2, 844) -> (205, 0, 595, 844)
    cropped = img.crop((205, 0, 595, 844))
    cropped.save(final_png, "PNG")
    print(f"Perfect crop saved: {final_png} ({cropped.size})")

print("All 4 screens are now perfectly rendered and cropped at 390x844!")
