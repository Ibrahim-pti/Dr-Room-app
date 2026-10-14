#!/usr/bin/env python3
import json
import time
import base64
import urllib.request
import urllib.error
import re
import os

API_KEY_B64 = "QVEuQWI4Uk42Sk1UUnR4emRYeDRpbkVNQ1hvdXZkRmIzSzN1RXAxZUp4TWRBcjV1Z3czSXc="
API_KEY = base64.b64decode(API_KEY_B64).decode("utf-8")
MODELS = ["gemini-3.5-flash-lite", "gemini-flash-latest", "gemini-3.8-flash"]

def call_gemini(prompt: str) -> str:
    payload = {
        "contents": [
            {
                "parts": [{"text": prompt}]
            }
        ],
        "generationConfig": {
            "response_mime_type": "application/json",
            "temperature": 0.2
        }
    }
    data = json.dumps(payload).encode("utf-8")

    for model in MODELS:
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={API_KEY}"
        req = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json"})
        for attempt in range(3):
            try:
                with urllib.request.urlopen(req, timeout=40) as resp:
                    res_json = json.loads(resp.read().decode("utf-8"))
                    candidates = res_json.get("candidates", [])
                    if candidates:
                        text = candidates[0]["content"]["parts"][0]["text"]
                        return text
            except Exception as e:
                print(f"Model {model} attempt {attempt+1} error: {e}")
                time.sleep(2)
    raise RuntimeError("All models failed")

def clean_json(text: str) -> dict:
    t = text.strip()
    if t.startswith("```json"):
        t = t[7:]
    elif t.startswith("```"):
        t = t[3:]
    if t.endswith("```"):
        t = t[:-3]
    return json.loads(t.strip())

def main():
    src_file = "assets/translations/ckb.json"
    dst_file = "assets/translations/kmr.json"

    with open(src_file, "r", encoding="utf-8") as f:
        ckb_data = json.load(f)

    # Resume if exists
    kmr_data = {}
    if os.path.exists(dst_file):
        try:
            with open(dst_file, "r", encoding="utf-8") as f:
                kmr_data = json.load(f)
            print(f"Resuming: {len(kmr_data)} already translated.")
        except Exception:
            kmr_data = {}

    keys_to_translate = [k for k in ckb_data.keys() if k not in kmr_data]
    print(f"Total keys: {len(ckb_data)}. Remaining: {len(keys_to_translate)}.")

    BATCH_SIZE = 45
    for i in range(0, len(keys_to_translate), BATCH_SIZE):
        batch_keys = keys_to_translate[i:i + BATCH_SIZE]
        batch_dict = {k: ckb_data[k] for k in batch_keys}

        prompt = f"""You are a professional Kurdish linguist specializing in Northern Kurdish (Badini / Kurmanji in Arabic-Kurdish script as written in Duhok, Zakho, and the Badinan region of Iraqi Kurdistan).
Translate the values of this JSON dictionary from Central Kurdish (Sorani) to authentic Badini Kurdish (ب ئەلفوبێیا کوردی-عەرەبی).

Rules:
1. Keep the exact same JSON keys.
2. Translate only the values into natural, standard Badini Kurdish (Arabic script).
   Examples:
   - "دەکەین" -> "دکەین"
   - "دەتوانیت" -> "تۆ دشێی" / "دشێی"
   - "پێویستە" -> "پێدڤیە"
   - "ئەمڕۆ" -> "ئەڤرۆ"
   - "دوێنێ" -> "دوهی"
   - "بەیانی" -> "سپێدێ"
   - "ئێوارە" -> "ئێڤاری"
   - "پزیشک" -> "نوژدار"
   - "هەڵبژاردن" -> "هەڵبژارتن"
   - "سڕینەوە" -> "ژێبرن"
   - "تکایە" -> "هیڤیدارین" / "تکایە"
   - "لەگەڵ" -> "دگەل"
   - "چوونەژوورەوە" -> "چوونەژوور"
   - "سەرکەوتوو" -> "سەرکەفتی"
   - "سەرکەوتوو نەبوو" -> "سەرنەکەفت"
3. Preserve all placeholders like %s, numbers, emojis, punctuation, and URLs.
4. Return ONLY valid JSON.

Input JSON:
{json.dumps(batch_dict, ensure_ascii=False, indent=2)}
"""
        print(f"Translating batch {i//BATCH_SIZE + 1} of {(len(keys_to_translate) + BATCH_SIZE - 1)//BATCH_SIZE}...")
        try:
            raw_res = call_gemini(prompt)
            translated_batch = clean_json(raw_res)
            for k in batch_keys:
                if k in translated_batch:
                    kmr_data[k] = translated_batch[k]
                else:
                    # fallback
                    kmr_data[k] = ckb_data[k]
            
            # Save progress
            with open(dst_file, "w", encoding="utf-8") as f:
                json.dump(kmr_data, f, ensure_ascii=False, indent=2)
            time.sleep(1)
        except Exception as e:
            print(f"Error on batch: {e}. Falling back to ckb for this batch.")
            for k in batch_keys:
                kmr_data[k] = ckb_data[k]
            with open(dst_file, "w", encoding="utf-8") as f:
                json.dump(kmr_data, f, ensure_ascii=False, indent=2)

    print(f"Done! {len(kmr_data)} keys saved in {dst_file}.")

if __name__ == "__main__":
    main()
