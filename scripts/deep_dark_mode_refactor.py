import os
import re

lib_dir = '/Users/ibrahimpti/Desktop/Dr-Room-/lib'

def refactor_nurse_details():
    p = os.path.join(lib_dir, 'features/nursing/nurse_details_screen.dart')
    with open(p, 'r', encoding='utf-8') as f:
        c = f.read()

    # 1. Update _buildHeroCurvedTop inner container
    c = c.replace(
        'ClipPath(\n                clipper: const HeroCurveClipper(),\n                child: Container(\n                  color: Colors.white,',
        'ClipPath(\n                clipper: const HeroCurveClipper(),\n                child: Container(\n                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A) : Colors.white,'
    )
    
    # 2. Back and Favorite buttons
    c = c.replace(
        'color: Colors.white.withValues(alpha: 0.95),',
        'color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white.withValues(alpha: 0.95),'
    )
    c = c.replace(
        'color: const Color(\n                              0xFFE2E8F0,\n                            ).withValues(alpha: 0.8),',
        'color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0).withValues(alpha: 0.8),'
    )
    c = c.replace(
        ': const Color(0xFF0F172A),\n                          size: 19,',
        ': (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A)),\n                          size: 19,'
    )
    c = c.replace(
        'color: const Color(0xFF0F172A),\n                          size: 16,',
        'color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A)),\n                          size: 16,'
    )

    # 3. Name & Location & Badges
    c = re.sub(
        r'Text\(\s*name\.isNotEmpty \? name : \'پەرستار\',\s*textAlign: TextAlign\.center,\s*style: _kStyle\(\s*fontSize: 18\.5,\s*fontWeight: FontWeight\.bold,\s*color: const Color\(0xFF0F172A\),\s*\),\s*\),',
        'Text(name.isNotEmpty ? name : \'پەرستار\', textAlign: TextAlign.center, style: _kStyle(fontSize: 18.5, fontWeight: FontWeight.bold)),',
        c
    )
    c = c.replace(
        'style: _kStyle(color: const Color(0xFF475569), fontSize: 12),',
        'style: _kStyle(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFCBD5E1) : const Color(0xFF475569), fontSize: 12),'
    )

    # 4. _heroPill
    c = re.sub(
        r'Widget _heroPill\({\s*required IconData icon,\s*required String label,\s*required Color color,\s*required Color bgColor,\s*required Color borderColor,\s*}\) {',
        'Widget _heroPill({\n    required IconData icon,\n    required String label,\n    required Color color,\n    required Color bgColor,\n    required Color borderColor,\n  }) {\n    final isDark = Theme.of(context).brightness == Brightness.dark;',
        c
    )
    c = c.replace(
        'color: bgColor,',
        'color: isDark ? color.withValues(alpha: 0.15) : bgColor,'
    )
    c = c.replace(
        'border: Border.all(color: borderColor),',
        'border: Border.all(color: isDark ? color.withValues(alpha: 0.35) : borderColor),'
    )

    # 5. Action Buttons (Call, Review)
    c = re.sub(
        r'Widget _buildActionButton\({\s*required IconData icon,\s*required String label,\s*required Color color,\s*required Color bgColor,\s*required VoidCallback onTap,\s*}\) {',
        'Widget _buildActionButton({\n    required IconData icon,\n    required String label,\n    required Color color,\n    required Color bgColor,\n    required VoidCallback onTap,\n  }) {\n    final isDark = Theme.of(context).brightness == Brightness.dark;',
        c
    )
    c = c.replace(
        'color: bgColor,\n          borderRadius: BorderRadius.circular(14),\n          border: Border.all(color: color.withValues(alpha: 0.2)),',
        'color: isDark ? const Color(0xFF1E293B) : bgColor,\n          borderRadius: BorderRadius.circular(14),\n          border: Border.all(color: isDark ? const Color(0xFF334155) : color.withValues(alpha: 0.2)),'
    )

    # 6. Tab bar
    c = c.replace(
        'color: const Color(0xFFF1F5F9),\n        borderRadius: BorderRadius.circular(16),\n        border: Border.all(color: const Color(0xFFE2E8F0)),',
        'color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),\n        borderRadius: BorderRadius.circular(16),\n        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),'
    )
    c = c.replace(
        'color: isSelected ? Colors.white : Colors.transparent,',
        'color: isSelected ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : Colors.white) : Colors.transparent,'
    )
    c = c.replace(
        'color: isSelected\n                              ? const Color(0xFF0F172A)\n                              : const Color(0xFF64748B),',
        'color: isSelected\n                              ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A))\n                              : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),'
    )

    # 7. Card background and borders
    c = c.replace(
        'color: Colors.white,\n        borderRadius: BorderRadius.circular(20),\n        border: Border.all(color: const Color(0xFFE2E8F0)),',
        'color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,\n        borderRadius: BorderRadius.circular(20),\n        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),'
    )
    c = c.replace(
        'color: Colors.white,\n      borderRadius: BorderRadius.circular(20),\n      border: Border.all(color: const Color(0xFFE2E8F0)),',
        'color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,\n      borderRadius: BorderRadius.circular(20),\n      border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),'
    )

    # 8. Text colors inside cards
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
    c = c.replace(
        'color: const Color(0xFFEFF6FF),',
        'color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2563EB).withValues(alpha: 0.18) : const Color(0xFFEFF6FF),'
    )

    with open(p, 'w', encoding='utf-8') as f:
        f.write(c)
    print("✅ Nurse details screen fully refactored for Dark Mode")

refactor_nurse_details()
