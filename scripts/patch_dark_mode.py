import os
import re

lib_dir = '/Users/ibrahimpti/Desktop/Dr-Room-/lib'

def update_file_dark_mode(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Check if already has isDark or Brightness.dark
    has_is_dark = 'Brightness.dark' in content or 'isDarkMode' in content
    
    # We will make sure Theme.of(context).brightness == Brightness.dark is added to build methods
    # and common static colors are made dynamic
    
    # Step 1: Ensure imports if AppColors is used or needed
    # (Not strictly needed if we use Color(0xFF0F172A) and Color(0xFF1E293B))

    modified = False

    # Common replacements in build / widget methods:
    # 1. Scaffold background
    if 'backgroundColor: const Color(0xFFF8FAFC)' in content or 'backgroundColor: const Color(0xfff8fafc)' in content:
        content = re.sub(
            r'backgroundColor:\s*const\s*Color\(0xFFF8FAFC\)',
            'backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)',
            content,
            flags=re.IGNORECASE
        )
        modified = True

    if 'backgroundColor: const Color(0xFFF1F5F9)' in content:
        content = re.sub(
            r'backgroundColor:\s*const\s*Color\(0xFFF1F5F9\)',
            'backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)',
            content,
            flags=re.IGNORECASE
        )
        modified = True

    if 'backgroundColor: const Color(0xFFF6F9FF)' in content:
        content = re.sub(
            r'backgroundColor:\s*const\s*Color\(0xFFF6F9FF\)',
            'backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A) : const Color(0xFFF6F9FF)',
            content,
            flags=re.IGNORECASE
        )
        modified = True

    if 'backgroundColor: Colors.white' in content:
        content = re.sub(
            r'backgroundColor:\s*Colors\.white',
            'backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A) : Colors.white',
            content
        )
        modified = True

    # If file was modified or needs specific treatment, save it
    if modified:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated: {os.path.relpath(filepath, lib_dir)}")

# Let's run a test on missing files
