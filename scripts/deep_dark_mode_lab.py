import os
import re

lib_dir = '/Users/ibrahimpti/Desktop/Dr-Room-/lib'

def refactor_lab_details():
    p = os.path.join(lib_dir, 'features/lab/lab_details_screen.dart')
    with open(p, 'r', encoding='utf-8') as f:
        c = f.read()

    # 1. Back and Favorite buttons in AppBar
    c = c.replace(
        'color: Colors.white,\n                borderRadius: BorderRadius.circular(12),\n                border: Border.all(color: const Color(0xFFE2E8F0)),',
        'color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,\n                borderRadius: BorderRadius.circular(12),\n                border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),'
    )
    c = c.replace(
        'color: const Color(0xFF0F172A),\n                size: 16,',
        'color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A),\n                size: 16,'
    )
    c = c.replace(
        ': const Color(0xFF0F172A),\n                size: 19,',
        ': (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A)),\n                size: 19,'
    )

    # 2. Main Identity Card & all Cards
    c = c.replace(
        'color: Colors.white,\n        borderRadius: BorderRadius.circular(20),',
        'color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,\n        borderRadius: BorderRadius.circular(20),'
    )
    c = c.replace(
        'color: Colors.white,\n      borderRadius: BorderRadius.circular(20),',
        'color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,\n      borderRadius: BorderRadius.circular(20),'
    )
    c = c.replace(
        'color: Colors.white,\n        borderRadius: BorderRadius.circular(18),',
        'color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,\n        borderRadius: BorderRadius.circular(18),'
    )
    c = c.replace(
        'color: Colors.white,\n      borderRadius: BorderRadius.circular(18),',
        'color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,\n      borderRadius: BorderRadius.circular(18),'
    )
    c = c.replace(
        'color: Colors.white,\n        borderRadius: BorderRadius.circular(16),',
        'color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,\n        borderRadius: BorderRadius.circular(16),'
    )
    c = c.replace(
        'color: Colors.white,\n      borderRadius: BorderRadius.circular(16),',
        'color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,\n      borderRadius: BorderRadius.circular(16),'
    )

    # 3. Card borders
    c = c.replace(
        'border: Border.all(color: const Color(0xFFE2E8F0)),',
        'border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),'
    )

    # 4. Tab Bar Header
    c = c.replace(
        'color: const Color(0xFFF1F5F9),\n        borderRadius: BorderRadius.circular(16),\n        border: Border.all(color: const Color(0xFFE2E8F0)),',
        'color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),\n        borderRadius: BorderRadius.circular(16),\n        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),'
    )
    c = c.replace(
        'color: isSelected ? Colors.white : Colors.transparent,',
        'color: isSelected ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : Colors.white) : Colors.transparent,'
    )
    c = c.replace(
        'color: isSelected\n                            ? const Color(0xFF0F172A)\n                            : const Color(0xFF64748B),',
        'color: isSelected\n                            ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A))\n                            : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),'
    )

    # 5. Text colors
    c = c.replace(
        'color: const Color(0xFF0F172A),',
        'color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A),'
    )
    c = c.replace(
        'color: const Color(0xFF475569),',
        'color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),'
    )
    c = c.replace(
        'color: const Color(0xFF64748B),',
        'color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),'
    )

    with open(p, 'w', encoding='utf-8') as f:
        f.write(c)
    print("✅ Lab details screen fully refactored for Dark Mode")

refactor_lab_details()
