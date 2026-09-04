import base64
import os
import subprocess
from PIL import Image

def get_b64(path):
    with open(path, "rb") as f:
        return base64.b64encode(f.read()).decode('utf-8')

font_bold_b64 = get_b64("fonts/Vazirmatn-Bold.ttf")
font_black_b64 = get_b64("fonts/Vazirmatn-Black.ttf")

home_b64 = f"data:image/png;base64,{get_b64('dr_room_backend/public/images/raw/app_home.png')}"
labs_b64 = f"data:image/png;base64,{get_b64('dr_room_backend/public/images/raw/app_labs.png')}"

# 4K HTML template: 4096 x 2000
# Centered title, centered store badges, bigger & bolder texts, exactly 2 phones
html = f"""<!DOCTYPE html>
<html lang="ckb">
<head>
<meta charset="UTF-8">
<style>
@font-face {{
    font-family: 'Vazirmatn';
    src: url('data:font/truetype;charset=utf-8;base64,{font_bold_b64}') format('truetype');
    font-weight: 700;
}}
@font-face {{
    font-family: 'Vazirmatn';
    src: url('data:font/truetype;charset=utf-8;base64,{font_black_b64}') format('truetype');
    font-weight: 900;
}}

* {{
    box-sizing: border-box;
    margin: 0;
    padding: 0;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
    text-rendering: optimizeLegibility;
}}

body {{
    width: 4096px;
    height: 2000px;
    overflow: hidden;
    background: radial-gradient(circle at 68% 42%, #225a64 0%, #17454e 35%, #0f3037 70%, #081a1d 100%);
    font-family: 'Vazirmatn', -apple-system, sans-serif;
    position: relative;
    user-select: none;
    direction: ltr;
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 85px 160px 130px 160px;
}}

/* Geometric pattern overlay */
.pattern-overlay {{
    position: absolute;
    inset: 0;
    opacity: 0.055;
    background-image: url("data:image/svg+xml,%3Csvg width='120' height='120' viewBox='0 0 120 120' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M60 0 L75 45 L120 60 L75 75 L60 120 L45 75 L0 60 L45 45 Z' fill='%23ffffff' fill-rule='evenodd'/%3E%3Ccircle cx='60' cy='60' r='18' fill='none' stroke='%23ffffff' stroke-width='3'/%3E%3C/svg%3E");
    background-size: 120px 120px;
    pointer-events: none;
}}

/* Atmospheric light glows */
.glow-left {{
    position: absolute;
    top: -150px;
    left: 200px;
    width: 1700px;
    height: 1700px;
    border-radius: 50%;
    background: radial-gradient(circle, rgba(45, 212, 191, 0.22) 0%, transparent 65%);
    filter: blur(140px);
    pointer-events: none;
}}
.glow-right {{
    position: absolute;
    top: -60px;
    right: 250px;
    width: 2000px;
    height: 2000px;
    border-radius: 50%;
    background: radial-gradient(circle, rgba(20, 184, 166, 0.35) 0%, transparent 65%);
    filter: blur(140px);
    pointer-events: none;
}}

/* ========================================================
   LEFT PANEL: CENTERED TYPOGRAPHY, 6 FEATURES, BADGES
======================================================== */
.left-panel {{
    z-index: 20;
    width: 2000px;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    text-align: center;
    direction: rtl;
}}

.main-title {{
    margin-bottom: 75px;
    display: flex;
    flex-direction: column;
    align-items: center;
    text-align: center;
    gap: 14px;
    width: 100%;
}}
.title-row-1 {{
    font-size: 154px;
    font-weight: 900;
    color: #ffffff;
    line-height: 1.18;
    text-shadow: 0 10px 48px rgba(0, 0, 0, 0.75);
    letter-spacing: -0.5px;
}}
.title-row-2 {{
    font-size: 126px;
    font-weight: 800;
    color: #5eead4;
    line-height: 1.18;
    text-shadow: 0 8px 36px rgba(0, 0, 0, 0.55);
}}

/* 2 Columns: Centered Icon on Top, Text Below (Larger & clearer) */
.features-grid {{
    display: grid;
    grid-template-columns: 1fr 1fr;
    column-gap: 90px;
    row-gap: 70px;
    width: 100%;
    max-width: 1850px;
    margin-bottom: 95px;
    direction: ltr; /* Keeps Col 1 on left, Col 2 on right */
}}

.feature-card {{
    display: flex;
    flex-direction: column;
    align-items: center;
    text-align: center;
    gap: 22px;
    direction: rtl;
}}
.feature-icon {{
    width: 160px;
    height: 160px;
    display: flex;
    align-items: center;
    justify-content: center;
}}
.feature-icon svg {{
    width: 150px;
    height: 150px;
    fill: none;
    stroke: #ffffff;
    stroke-width: 2.3;
    stroke-linecap: round;
    stroke-linejoin: round;
    filter: drop-shadow(0 7px 20px rgba(0, 0, 0, 0.55));
}}
.feature-label {{
    font-size: 70px;
    font-weight: 800;
    color: #ffffff;
    line-height: 1.25;
    text-shadow: 0 5px 26px rgba(0, 0, 0, 0.7);
    white-space: pre-line;
}}

/* Store Badges - CENTERED */
.store-badges {{
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 45px;
    width: 100%;
    direction: ltr;
}}
.store-btn {{
    height: 144px;
    padding: 0 56px;
    background: #000000;
    border: 3.5px solid rgba(255, 255, 255, 0.38);
    border-radius: 36px;
    display: flex;
    align-items: center;
    gap: 28px;
    box-shadow: 0 24px 60px rgba(0, 0, 0, 0.65);
}}
.store-btn svg {{
    height: 72px;
    width: 72px;
}}
.store-text {{
    display: flex;
    flex-direction: column;
    text-align: left;
}}
.store-text .top {{
    font-size: 28px;
    font-weight: 600;
    color: #cbd5e1;
    text-transform: uppercase;
    letter-spacing: 1.3px;
    font-family: -apple-system, sans-serif;
}}
.store-text .bottom {{
    font-size: 48px;
    font-weight: 800;
    color: #ffffff;
    font-family: -apple-system, sans-serif;
    letter-spacing: -0.5px;
}}

/* ========================================================
   RIGHT PANEL: EXACTLY 2 BIGGER, PROMINENT 3D PHONES
======================================================== */
.phones-stage {{
    z-index: 15;
    position: relative;
    width: 1720px;
    height: 1680px;
    display: flex;
    align-items: center;
    justify-content: center;
    direction: ltr;
}}

.phone-mockup {{
    position: absolute;
    background: #090e15;
    border-radius: 106px;
    padding: 22px;
    overflow: hidden;
}}
.phone-inner {{
    width: 100%;
    height: 100%;
    border-radius: 86px;
    overflow: hidden;
    position: relative;
    background: #ffffff;
}}
.phone-inner img {{
    width: 100%;
    height: 100%;
    object-fit: cover;
    object-position: top center;
    display: block;
}}

/* Phone 1 (Left / Back): Labs Screen */
.phone-labs {{
    width: 720px;
    height: 1510px;
    left: 80px;
    top: 90px;
    transform: rotate(-9deg) perspective(1500px) rotateY(12deg) scale(0.93);
    z-index: 5;
    box-shadow: 
        -40px 65px 150px rgba(0, 0, 0, 0.85),
        0 25px 80px rgba(13, 148, 136, 0.45),
        inset 0 0 0 3.5px rgba(255, 255, 255, 0.35),
        inset 0 0 0 12px #1e293b;
    opacity: 0.98;
}}

/* Phone 2 (Right / Front Hero): Home Screen */
.phone-home {{
    width: 770px;
    height: 1610px;
    left: 700px;
    top: 30px;
    transform: rotate(5deg) perspective(1500px) rotateY(-7deg);
    z-index: 10;
    box-shadow: 
        -35px 75px 180px rgba(0, 0, 0, 0.92),
        0 35px 100px rgba(45, 212, 191, 0.55),
        inset 0 0 0 4.5px rgba(255, 255, 255, 0.45),
        inset 0 0 0 13px #1e293b;
}}

/* Dynamic Island */
.dynamic-island {{
    position: absolute;
    top: 42px;
    left: 50%;
    transform: translateX(-50%);
    width: 165px;
    height: 50px;
    background: #000000;
    border-radius: 35px;
    z-index: 30;
}}

/* BOTTOM RIGHT SLOGAN BAR (Bigger & Clearer) */
.bottom-bar {{
    position: absolute;
    bottom: 50px;
    right: 180px;
    z-index: 25;
    font-size: 82px;
    font-weight: 800;
    color: #ffffff;
    text-shadow: 0 8px 38px rgba(0, 0, 0, 0.85);
    letter-spacing: -0.5px;
    direction: rtl;
}}
.bottom-bar span.accent {{
    color: #5eead4;
}}
</style>
</head>
<body>
    <div class="pattern-overlay"></div>
    <div class="glow-left"></div>
    <div class="glow-right"></div>

    <!-- LEFT PANEL: Centered Content, Features, Badges -->
    <div class="left-panel">
        <div class="main-title">
            <div class="title-row-1">دکتۆر ڕووم (DrRoom)</div>
            <div class="title-row-2">پلاتفۆرمی تەندروستی</div>
        </div>

        <div class="features-grid">
            <!-- Col 1, Row 1: Real Stethoscope Icon -->
            <div class="feature-card">
                <div class="feature-icon">
                    <svg viewBox="0 0 24 24">
                        <path d="M4.5 3v5a4.5 4.5 0 0 0 9 0V3"/>
                        <path d="M9 12.5v3a5 5 0 0 0 10 0v-2"/>
                        <circle cx="19" cy="11.5" r="2.5"/>
                        <path d="M3 3h3"/>
                        <path d="M12 3h3"/>
                    </svg>
                </div>
                <div class="feature-label">نۆرەگرتنی پزیشک</div>
            </div>

            <!-- Col 2, Row 1: Real Nurse Icon -->
            <div class="feature-card">
                <div class="feature-icon">
                    <svg viewBox="0 0 24 24">
                        <path d="M12 2a4 4 0 0 0-4 4v1h8V6a4 4 0 0 0-4-4z"/>
                        <path d="M10 4h4"/>
                        <path d="M12 2v4"/>
                        <circle cx="12" cy="11" r="3.5"/>
                        <path d="M5 21v-2a7 7 0 0 1 14 0v2"/>
                    </svg>
                </div>
                <div class="feature-label">پەرستاری لە ماڵەوە</div>
            </div>

            <!-- Col 1, Row 2: 3 Test Tubes Rack -->
            <div class="feature-card">
                <div class="feature-icon">
                    <svg viewBox="0 0 24 24">
                        <path d="M6 3v14a2.5 2.5 0 0 0 5 0V3"/>
                        <path d="M13 3v14a2.5 2.5 0 0 0 5 0V3"/>
                        <path d="M4 6h16"/>
                        <path d="M4 14h16"/>
                        <path d="M5 3h7"/>
                        <path d="M12 3h7"/>
                    </svg>
                </div>
                <div class="feature-label">تاقیگەی پزیشکی</div>
            </div>

            <!-- Col 2, Row 2: Medical Shield / Folder -->
            <div class="feature-card">
                <div class="feature-icon">
                    <svg viewBox="0 0 24 24">
                        <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
                        <path d="M9 12h6"/>
                        <path d="M12 9v6"/>
                    </svg>
                </div>
                <div class="feature-label">مەلەفی پزیشکی</div>
            </div>

            <!-- Col 1, Row 3: Ambulance (Exact Kurdish wording: فریاگوزاری و هاوکاری کتوپڕ) -->
            <div class="feature-card">
                <div class="feature-icon">
                    <svg viewBox="0 0 24 24">
                        <path d="M10 10H6"/>
                        <path d="M14 18V6a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2v11a1 1 0 0 0 1 1h2"/>
                        <circle cx="7" cy="18" r="2"/>
                        <circle cx="17" cy="18" r="2"/>
                        <path d="M19 18h2a1 1 0 0 0 1-1v-3.28a1 1 0 0 0-.684-.948l-2.434-.811a2 2 0 0 1-1.382-1.9V8a2 2 0 0 0-2-2h-1v12z"/>
                        <path d="M8 8v4"/>
                    </svg>
                </div>
                <div class="feature-label">فریاگوزاری و هاوکاری کتوپڕ</div>
            </div>

            <!-- Col 2, Row 3: AI Brain Scanner -->
            <div class="feature-card">
                <div class="feature-icon">
                    <svg viewBox="0 0 24 24">
                        <path d="M12 2a7 7 0 0 0-7 7c0 2.38 1.19 4.47 3 5.74V17a2 2 0 0 0 2 2h4a2 2 0 0 0 2-2v-2.26c1.81-1.27 3-3.36 3-5.74a7 7 0 0 0-7-7z"/>
                        <path d="M9 21h6"/>
                        <path d="M10 12h4"/>
                        <path d="M12 10v4"/>
                    </svg>
                </div>
                <div class="feature-label">سکانەری زیرەکی
دەستکرد</div>
            </div>
        </div>

        <!-- Store Badges (Centered) -->
        <div class="store-badges">
            <!-- Google Play -->
            <div class="store-btn">
                <svg viewBox="0 0 512 512">
                    <path fill="#4285F4" d="M325.3 234.3L104.6 13l280.8 161.2-60.1 60.1z"/>
                    <path fill="#34A853" d="M47 0C34 6.8 25.3 19.2 25.3 35.3v441.3c0 16.1 8.7 28.5 21.7 35.3l256-256L47 0z"/>
                    <path fill="#FBBC04" d="M471.2 225.2L385.4 174 325.3 234.3l60.1 60.1 85.8-51.2c15.1-9 24.8-24.8 24.8-42.5 0-17.7-9.7-33.5-24.8-42.5z"/>
                    <path fill="#EA4335" d="M104.6 499L325.3 277.7l60.1 60.1L104.6 499z"/>
                </svg>
                <div class="store-text">
                    <span class="top">GET IT ON</span>
                    <span class="bottom">Google Play</span>
                </div>
            </div>

            <!-- Apple App Store -->
            <div class="store-btn">
                <svg viewBox="0 0 384 512" fill="#ffffff">
                    <path d="M318.7 268.7c-.2-36.7 16.4-64.4 50-84.8-18.8-26.9-47.2-41.7-84.7-44.6-35.5-2.8-74.3 20.7-88.5 20.7-15 0-49.4-19.7-76.4-19.7C63.3 141.2 4 184.8 4 273.5q0 66.2 35.5 137.9c17.5 35.2 40.5 73.6 74.3 72.8 28.5-.7 39.5-18.6 73.6-18.6 33.3 0 43.6 18.6 73.6 18.6 33.8 0 54.8-34.9 72.5-70.2 20.7-40.4 29.2-79.6 29.6-81.5-.7-.4-54.4-20.9-54.4-63.8zM249.2 92.5c15.2-18.6 25.6-44.4 22.8-70.5-22.3 1-48.4 14.8-63.9 33.2-13.6 16-25.7 42.4-22.5 67.9 25 2 48.4-12 63.6-30.6z"/>
                </svg>
                <div class="store-text">
                    <span class="top">Download on the</span>
                    <span class="bottom">App Store</span>
                </div>
            </div>
        </div>
    </div>

    <!-- RIGHT PANEL: EXACTLY 2 PHONES -->
    <div class="phones-stage">
        <!-- Phone 1 (Labs Screen) -->
        <div class="phone-mockup phone-labs">
            <div class="dynamic-island"></div>
            <div class="phone-inner">
                <img src="{labs_b64}" alt="Labs">
            </div>
        </div>

        <!-- Phone 2 (Home Screen - Front Hero) -->
        <div class="phone-mockup phone-home">
            <div class="dynamic-island"></div>
            <div class="phone-inner">
                <img src="{home_b64}" alt="Home">
            </div>
        </div>
    </div>

    <!-- BOTTOM RIGHT SLOGAN -->
    <div class="bottom-bar">
        دکتۆر ڕووم: <span class="accent">تەندروستی و دڵنیایی لەبەر دەرگای ماڵەکەت</span>
    </div>
</body>
</html>
"""

os.makedirs("scratch", exist_ok=True)
tmp_html = "/Users/ibrahimpti/Desktop/Dr-Room-/scratch/render_final_banner.html"
tmp_png_4k = "/Users/ibrahimpti/Desktop/Dr-Room-/scratch/banner_4k_final.png"
final_4k_png = "/Users/ibrahimpti/Desktop/Dr-Room-/playstore_assets/banner_4k_ultra.png"
final_playstore_png = "/Users/ibrahimpti/Desktop/Dr-Room-/playstore_assets/2_feature_graphic_1024x500.png"
assets_img_png = "/Users/ibrahimpti/Desktop/Dr-Room-/assets/images/playstore_feature_graphic.png"

with open(tmp_html, "w", encoding="utf-8") as f:
    f.write(html)

print("Rendering 4K banner with Chrome...")
cmd = [
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "--headless",
    "--disable-gpu",
    f"--screenshot={tmp_png_4k}",
    "--window-size=4096,2000",
    f"file://{tmp_html}"
]
subprocess.run(cmd, check=True)
print("Saved 4K screenshot:", tmp_png_4k)

im = Image.open(tmp_png_4k)
print("Raw 4K Size:", im.size)
im.save(final_4k_png, quality=100, optimize=True)

im_500 = im.resize((1024, 500), Image.Resampling.LANCZOS)
im_500.save(final_playstore_png, quality=98, optimize=True)
im_500.save(assets_img_png, quality=98, optimize=True)
print("SUCCESS: All target files updated!")
