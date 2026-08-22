import os
import re

lib_dir = '/Users/ibrahimpti/Desktop/Dr-Room-/lib'

for root, _, files in os.walk(lib_dir):
    for f in files:
        if f.endswith('.dart'):
            path = os.path.join(root, f)
            with open(path, 'r', encoding='utf-8') as file:
                content = file.read()
            
            # If the file defines cardBg, textPrimary, textSecondary, borderColor, scaffoldBg but never uses them, clean up
            orig = content
            lines = content.splitlines()
            new_lines = []
            for line in lines:
                if re.match(r'^\s*final (cardBg|textPrimary|textSecondary|borderColor|scaffoldBg) = isDark \?', line):
                    var_name = line.strip().split()[1]
                    # Check occurrences of var_name in content
                    matches = len(re.findall(r'\b' + var_name + r'\b', content))
                    if matches <= 1:
                        # Only defined once, never referenced -> skip line
                        continue
                new_lines.append(line)
            
            new_content = '\n'.join(new_lines)
            if new_content != orig:
                with open(path, 'w', encoding='utf-8') as file:
                    file.write(new_content)
                print(f"Cleaned unused vars in {os.path.relpath(path, lib_dir)}")
