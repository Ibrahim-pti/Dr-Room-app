#!/usr/bin/env python3
import base64
import urllib.request
import json

API_KEY = base64.b64decode('QVEuQWI4Uk42Sk1UUnR4emRYeDRpbkVNQ1hvdXZkRmIzSzN1RXAxZUp4TWRBcjV1Z3czSXc=').decode('utf-8')

def main():
    with open('dr_room_backend/lang/ckb/landing.php', 'r', encoding='utf-8') as f:
        ckb_php = f.read()

    prompt = f"""You are an expert Kurdish linguist. Translate this PHP language array file from Central Kurdish (Sorani) into natural, authentic Badini Kurdish (کرمانجییا ژۆری / بادینی ب ئەلفوبێیا کوردی-عەرەبی وەک دهۆک و زاخۆ).
Preserve all PHP syntax, array keys, and structure exactly. Only translate the string values into authentic Badini Kurdish.

Source PHP:
{ckb_php}

Output valid PHP code starting with <?php and returning the array."""

    url = f'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent?key={API_KEY}'
    data = json.dumps({'contents': [{'parts': [{'text': prompt}]}]}).encode('utf-8')
    req = urllib.request.Request(url, data=data, headers={'Content-Type': 'application/json'})

    with urllib.request.urlopen(req, timeout=60) as resp:
        res = json.loads(resp.read().decode('utf-8'))
        txt = res['candidates'][0]['content']['parts'][0]['text'].strip()
        if txt.startswith('```php'):
            txt = txt[6:]
        elif txt.startswith('```'):
            txt = txt[3:]
        if txt.endswith('```'):
            txt = txt[:-3]
        txt = txt.strip()
        with open('dr_room_backend/lang/kmr/landing.php', 'w', encoding='utf-8') as out:
            out.write(txt + '\n')
        print(f"landing.php in kmr successfully created! Length: {len(txt)}")

if __name__ == '__main__':
    main()
