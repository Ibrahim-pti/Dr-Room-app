import os
import re

lib_dir = '/Users/ibrahimpti/Desktop/Dr-Room-/lib'

# Helper function to upgrade a file with Dark Mode
def upgrade_screen(rel_path):
    full_path = os.path.join(lib_dir, rel_path)
    if not os.path.exists(full_path):
        print(f"File not found: {rel_path}")
        return

    with open(full_path, 'r', encoding='utf-8') as f:
        content = f.read()

    orig_content = content

    # 1. Check if isDark is defined inside build(BuildContext context)
    # If not, let's inject it at the beginning of build(BuildContext context) {
    if 'final isDark =' not in content and 'bool isDark =' not in content:
        # Match 'Widget build(BuildContext context) {'
        pattern = r'(Widget\s+build\s*\(\s*BuildContext\s+context\s*\)\s*\{)'
        replacement = r'\1\n    final isDark = Theme.of(context).brightness == Brightness.dark;\n    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;\n    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);\n    final textSecondary = isDark ? Colors.white60 : const Color(0xFF64748B);\n    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);\n    final scaffoldBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);'
        content = re.sub(pattern, replacement, content, count=1)

    # 2. Upgrade Scaffold backgroundColor
    content = re.sub(
        r'backgroundColor:\s*const\s*Color\(0xFFF8FAFC\)',
        'backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)',
        content
    )
    content = re.sub(
        r'backgroundColor:\s*const\s*Color\(0xFFF1F5F9\)',
        'backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)',
        content
    )
    content = re.sub(
        r'backgroundColor:\s*const\s*Color\(0xFFF6F9FF\)',
        'backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A) : const Color(0xFFF6F9FF)',
        content
    )
    content = re.sub(
        r'backgroundColor:\s*Colors\.white([,\)])',
        r'backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A) : Colors.white\1',
        content
    )

    # 3. Upgrade AppBars
    content = re.sub(
        r'AppBar\(\s*backgroundColor:\s*const\s*Color\(0xFFF8FAFC\)',
        'AppBar(\n      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)',
        content
    )
    content = re.sub(
        r'AppBar\(\s*backgroundColor:\s*Colors\.white',
        'AppBar(\n      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white',
        content
    )

    with open(full_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"✅ Processed {rel_path}")

# Run upgrade on all remaining screens
target_screens = [
    'features/lab/lab_details_screen.dart',
    'features/nursing/nurse_details_screen.dart',
    'features/home/doctor_details_screen.dart',
    'features/body_map/organ_details_screen.dart',
    'features/body_map/body_map_screen.dart',
    'features/categories/all_categories_screen.dart',
    'features/checkout/payment_screen.dart',
    'features/doctors/all_doctors_screen.dart',
    'features/doctors/appointment_confirmation_screen.dart',
    'features/doctors/booking_slot_screen.dart',
    'features/doctors/doctor_list_screen.dart',
    'features/doctors/doctor_profile_screen.dart',
    'features/doctors/video_call_screen.dart',
    'features/lab/all_labs_screen.dart',
    'features/lab/lab_map_screen.dart',
    'features/nursing/nurse_list_screen.dart',
    'features/pharmacy/pill_scanner_screen.dart',
    'features/pharmacy/screens/pharmacy_payment_screen.dart',
    'features/auth/splash_screen.dart',
    'features/auth/widgets/terms_privacy_modal.dart',
    'features/admin/admin_articles_screen.dart',
    'features/admin/admin_doctors_screen.dart',
    'features/admin/admin_labs_screen.dart',
    'features/admin/admin_nurses_screen.dart',
    'features/admin/admin_pharmacies_screen.dart',
    'features/admin/admin_categories_screen.dart',
    'features/admin/admin_staff_screen.dart',
    'features/admin/admin_transactions_screen.dart',
    'features/admin/admin_reviews_screen.dart',
    'features/admin/admin_xrays_screen.dart',
    'features/admin/admin_activity_log_screen.dart',
]

for s in target_screens:
    upgrade_screen(s)
