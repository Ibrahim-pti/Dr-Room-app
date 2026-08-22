import os
import re
import json

def run_translation_audit():
    print("=" * 60)
    print("🔍 DR-ROOM ADVANCED TRANSLATION & LOCALIZATION AUDITOR")
    print("=" * 60)

    # 1. Load Translation Files
    trans_dir = 'assets/translations'
    langs = ['ckb', 'ar', 'en']
    trans_data = {}

    for lang in langs:
        file_path = os.path.join(trans_dir, f'{lang}.json')
        if os.path.exists(file_path):
            with open(file_path, 'r', encoding='utf-8') as f:
                trans_data[lang] = json.load(f)
            print(f"✅ Loaded {lang}.json ({len(trans_data[lang])} keys)")
        else:
            print(f"❌ Missing {file_path}!")

    # 2. Check Key Consistency across languages
    print("\n--- 1. Checking Key Consistency Across Language Files ---")
    all_keys = set()
    for keys in trans_data.values():
        all_keys.update(keys.keys())

    missing_keys_per_lang = {lang: [] for lang in langs}
    for key in all_keys:
        for lang in langs:
            if key not in trans_data[lang]:
                missing_keys_per_lang[lang].append(key)

    has_mismatch = False
    for lang, m_keys in missing_keys_per_lang.items():
        if m_keys:
            has_mismatch = True
            print(f"⚠️  {lang}.json is missing {len(m_keys)} keys: {m_keys[:10]}...")
    if not has_mismatch:
        print("✅ All translation JSON files are 100% synchronized with each other!")

    # 3. Find All .tr() Calls in lib/
    print("\n--- 2. Scanning Codebase for .tr() Usage ---")
    tr_pattern = re.compile(r"['\"]([a-zA-Z0-9_\-]+)['\"]\s*\.tr\(")
    used_tr_keys = set()
    tr_locations = {}

    # Regex for hardcoded Kurdish / Arabic characters in string literals
    kurdish_arabic_pattern = re.compile(r"['\"]([\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF\s\d\.,!؟:\-\(\)\/\+]+)['\"]")

    # Files to exclude from hardcoded string checks
    excluded_files = ['home_mock_data.dart', 'seed', '.g.dart']

    hardcoded_strings = []

    for root, _, files in os.walk('lib'):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                relpath = os.path.relpath(filepath, '.')

                is_excluded = any(ex in relpath for ex in excluded_files)

                with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                    lines = f.readlines()

                for line_idx, line in enumerate(lines, 1):
                    # Check tr keys
                    tr_matches = tr_pattern.findall(line)
                    for k in tr_matches:
                        used_tr_keys.add(k)
                        if k not in tr_locations:
                            tr_locations[k] = []
                        tr_locations[k].append(f"{relpath}:{line_idx}")

                    # Check hardcoded Kurdish/Arabic strings (ignore imports, comments, tr calls, font names)
                    clean_line = line.strip()
                    if clean_line.startswith('//') or clean_line.startswith('/*') or 'import ' in clean_line:
                        continue
                    if '.tr(' in clean_line or 'localizedField' in clean_line or 'locale' in clean_line:
                        continue
                    if 'fontFamily' in clean_line or 'Rabar' in clean_line:
                        continue
                    if is_excluded:
                        continue

                    # Look for Text('...') or similar UI strings with Kurdish/Arabic
                    if any(kw in clean_line for kw in ['Text(', 'hintText:', 'title:', 'subtitle:', 'label:', 'tooltip:', 'SnackBar(']):
                        ka_matches = kurdish_arabic_pattern.findall(clean_line)
                        for text in ka_matches:
                            t = text.strip()
                            # Filter out very short/numeric symbols
                            if len(t) > 2 and any('\u0600' <= char <= '\u06FF' for char in t):
                                hardcoded_strings.append({
                                    'file': relpath,
                                    'line': line_idx,
                                    'text': t,
                                    'code': clean_line
                                })

    # Missing tr keys in json files
    missing_used_keys = [k for k in sorted(used_tr_keys) if any(k not in trans_data[lang] for lang in langs)]
    if missing_used_keys:
        print(f"⚠️  Found {len(missing_used_keys)} .tr() keys used in code but MISSING in translation JSON files:")
        for k in missing_used_keys:
            print(f"   - '{k}' in {tr_locations.get(k, ['unknown'])[0]}")
    else:
        print(f"✅ All {len(used_tr_keys)} .tr() keys used in code exist in translation files!")

    # 4. Report Hardcoded Strings
    print("\n--- 3. Hardcoded Kurdish / Arabic Strings in UI Widgets ---")
    if hardcoded_strings:
        print(f"⚠️  Found {len(hardcoded_strings)} potential hardcoded strings:")
        for idx, item in enumerate(hardcoded_strings[:30], 1):
            print(f"  {idx}. [{item['file']}:{item['line']}] -> \"{item['text']}\"")
        if len(hardcoded_strings) > 30:
            print(f"  ... and {len(hardcoded_strings) - 30} more.")
    else:
        print("✅ No hardcoded Kurdish/Arabic UI strings found! Everything is properly localized.")

    print("\n" + "=" * 60)

if __name__ == '__main__':
    run_translation_audit()
