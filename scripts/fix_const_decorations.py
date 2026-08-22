import os
import re

lib_dir = '/Users/ibrahimpti/Desktop/Dr-Room-/lib'

for root, _, files in os.walk(os.path.join(lib_dir, 'features')):
    for f in files:
        if f.endswith('.dart'):
            p = os.path.join(root, f)
            with open(p, 'r', encoding='utf-8') as file:
                content = file.read()
            
            orig = content
            # Fix const BoxDecoration(...) that contains Theme.of
            content = re.sub(r'const\s+(BoxDecoration\([^;]*?Theme\.of)', r'\1', content, flags=re.DOTALL)
            # Fix const Border.all(color: Theme.of...)
            content = re.sub(r'const\s+(Border\.[a-zA-Z]+\([^;]*?Theme\.of)', r'\1', content, flags=re.DOTALL)
            # Fix const BorderSide(...)
            content = re.sub(r'const\s+(BorderSide\([^;]*?Theme\.of)', r'\1', content, flags=re.DOTALL)
            # Fix const Icon(..., color: (Theme.of...))
            content = re.sub(r'const\s+(Icon\([^;]*?Theme\.of)', r'\1', content, flags=re.DOTALL)
            # Fix const TextStyle(..., color: (Theme.of...))
            content = re.sub(r'const\s+(TextStyle\([^;]*?Theme\.of)', r'\1', content, flags=re.DOTALL)
            
            if content != orig:
                with open(p, 'w', encoding='utf-8') as file:
                    file.write(content)
                print(f"Fixed const in {os.path.relpath(p, lib_dir)}")
