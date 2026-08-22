import os
import re

lib_dir = '/Users/ibrahimpti/Desktop/Dr-Room-/lib'

def deep_refactor_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        c = f.read()

    orig = c

    # 1. Containers / Cards with pure white background -> dynamic slate card
    # Matches decoration: BoxDecoration(color: Colors.white, ...
    c = re.sub(
        r'(\bcolor:\s*)Colors\.white([,\s\n]+borderRadius:)',
        r'\1(Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white)\2',
        c
    )

    # 2. Light grey card borders -> dynamic dark border
    c = re.sub(
        r'Border\.all\(\s*color:\s*const\s*Color\(0xFFE2E8F0\)\s*\)',
        'Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))',
        c
    )
    c = re.sub(
        r'BorderSide\(\s*color:\s*const\s*Color\(0xFFE2E8F0\)\s*\)',
        'BorderSide(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))',
        c
    )

    # 3. Soft background containers Color(0xFFF8FAFC) or Color(0xFFF1F5F9)
    c = re.sub(
        r'(\bcolor:\s*)const\s*Color\(0xFFF1F5F9\)([,\s\n]+borderRadius:)',
        r'\1(Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))\2',
        c
    )

    # 4. Input decoration fillColor
    c = re.sub(
        r'fillColor:\s*const\s*Color\(0xFFF8FAFC\)',
        'fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)',
        c
    )
    c = re.sub(
        r'fillColor:\s*Colors\.white',
        'fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white',
        c
    )

    # 5. Primary text colors Color(0xFF0F172A) or Color(0xFF1E293B) in Text / TextStyles
    c = re.sub(
        r'(\bcolor:\s*)const\s*Color\(0xFF0F172A\)',
        r'\1(Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A))',
        c
    )
    
    # 6. Secondary text colors Color(0xFF64748B) or Color(0xFF475569) in Text / TextStyles
    c = re.sub(
        r'(\bcolor:\s*)const\s*Color\(0xFF64748B\)',
        r'\1(Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))',
        c
    )
    c = re.sub(
        r'(\bcolor:\s*)const\s*Color\(0xFF475569\)',
        r'\1(Theme.of(context).brightness == Brightness.dark ? const Color(0xFFCBD5E1) : const Color(0xFF475569))',
        c
    )

    if c != orig:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(c)
        print(f"Deep refactored: {os.path.relpath(filepath, lib_dir)}")

# Process all dart files in features/
for root, _, files in os.walk(os.path.join(lib_dir, 'features')):
    for f in files:
        if f.endswith('.dart'):
            deep_refactor_file(os.path.join(root, f))
