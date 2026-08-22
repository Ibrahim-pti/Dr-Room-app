import os
import re

def scan_dark_mode():
    lib_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'lib'))
    
    screen_files = []
    for root, _, files in os.walk(lib_dir):
        for f in files:
            if f.endswith('.dart') and not f.endswith('_models.dart') and not f.endswith('_model.dart'):
                path = os.path.join(root, f)
                rel_path = os.path.relpath(path, lib_dir)
                if any(k in f.lower() for k in ['screen', 'page', 'detail', 'view', 'dialog', 'bottom_sheet', 'modal']):
                    with open(path, 'r', encoding='utf-8') as pf:
                        code = pf.read()
                    if 'extends StatelessWidget' in code or 'extends StatefulWidget' in code:
                        screen_files.append((rel_path, path))

    missing = []
    supported = []

    for rel_path, full_path in screen_files:
        with open(full_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        has_is_dark = 'Brightness.dark' in content or 'isDarkMode' in content or 'isDark' in content
        has_app_colors = bool(re.search(r'AppColors\.(getBackground|getSurface|getTextTitle|getTextSubtitle|getBorder|getSurfaceSecondary)', content))
        
        lines_count = len(content.splitlines())
        
        if has_is_dark or has_app_colors:
            supported.append((rel_path, lines_count))
        else:
            missing.append((rel_path, lines_count))

    print("=" * 65)
    print(" 🌓 DR-ROOM DARK MODE COVERAGE AUDIT")
    print("=" * 65)
    print(f"\n📊 کورتەی دۆخ: سەرجەم {len(screen_files)} پەڕە پشکنران.")
    print(f"✅ پەڕەکانی خاوەن دارک مۆد: {len(supported)}")
    print(f"❌ ئەو پەڕانەی دارک مۆدیان تەواو نەکراوە: {len(missing)}")
    
    print("\n" + "─" * 65)
    print("❌ ئەو پەڕانەی پێویستیان بە دارک مۆدە (Missing Dark Mode):")
    print("─" * 65)
    
    # Categorize missing
    detail_screens = []
    user_screens = []
    admin_screens = []
    
    for rel_path, lines in missing:
        if 'admin' in rel_path:
            admin_screens.append((rel_path, lines))
        elif 'detail' in rel_path:
            detail_screens.append((rel_path, lines))
        else:
            user_screens.append((rel_path, lines))
            
    if detail_screens:
        print("\n🔹 پەڕەکانی وردەکاری (Detail Screens):")
        for p, l in sorted(detail_screens):
            print(f"   [ ] {p} ({l} دێڕ)")
            
    if user_screens:
        print("\n🔹 پەڕەکانی بەکارهێنەر (User App Screens):")
        for p, l in sorted(user_screens):
            print(f"   [ ] {p} ({l} دێڕ)")
            
    if admin_screens:
        print("\n🔹 پەڕەکانی بەڕێوەبەر (Admin Screens):")
        for p, l in sorted(admin_screens):
            print(f"   [ ] {p} ({l} دێڕ)")

    print("\n" + "=" * 65)

if __name__ == '__main__':
    scan_dark_mode()
