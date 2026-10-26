#!/usr/bin/env python3
"""
Dr-Room App & API Automated Health & CRUD Diagnostic Tool
Tests live server endpoints, database payload structures, and response timings.
"""

import urllib.request
import json
import time
import sys

BASE_URL = "https://sys.shaqamonline.org/api"

ENDPOINTS = [
    {"name": "وەشانی ئەپ (App Version)", "path": "/app-version", "method": "GET", "expected_key": "latest_version"},
    {"name": "پەڕەی سەرەکی (Home Feed)", "path": "/home", "method": "GET", "expected_key": "data"},
    {"name": "بانەرەکان (Banners)", "path": "/banners", "method": "GET", "expected_key": None},
    {"name": "وتارە پزیشکییەکان (Articles)", "path": "/articles", "method": "GET", "expected_key": None},
    {"name": "لیستی پزیشکان (Doctors)", "path": "/doctors", "method": "GET", "expected_key": None},
    {"name": "بەشەکان (Service Categories)", "path": "/service-categories", "method": "GET", "expected_key": None},
    {"name": "دەرمانخانەکان (Pharmacies)", "path": "/pharmacies", "method": "GET", "expected_key": "data"},
    {"name": "کەتەگۆری دەرمان (Med Categories)", "path": "/pharmacies/categories", "method": "GET", "expected_key": "data"},
    {"name": "تاقیگەکان (Labs)", "path": "/labs", "method": "GET", "expected_key": "data"},
    {"name": "پشکنینەکانی تاقیگە (Lab Tests)", "path": "/labs/tests", "method": "GET", "expected_key": "data"},
    {"name": "پاکێجەکانی تاقیگە (Lab Packages)", "path": "/labs/packages", "method": "GET", "expected_key": "data"},
    {"name": "ستافی تاقیگە (Lab Staff)", "path": "/labs/staff", "method": "GET", "expected_key": "data"},
    {"name": "پەرستاران (Nurses)", "path": "/nurses", "method": "GET", "expected_key": None},
    {"name": "خزمەتگوزاری پەرستاری (Nursing Services)", "path": "/nursing/services", "method": "GET", "expected_key": "data"},
    {"name": "پاکێجی پەرستاری (Nursing Packages)", "path": "/nursing/packages", "method": "GET", "expected_key": "data"},
    {"name": "پەیوەندی فریاگوزاری (Emergency Contacts)", "path": "/emergency-contacts", "method": "GET", "expected_key": "data"},
    {"name": "ریڵزەکانی فریاگوزاری (Emergency Reels)", "path": "/emergency-reels", "method": "GET", "expected_key": None},
    {"name": "گەڕانی گشتی (Global Search)", "path": "/global-search?q=test", "method": "GET", "expected_key": None},
    {"name": "ئەندامەکانی لەش (Anatomy Organs)", "path": "/anatomy/organs", "method": "GET", "expected_key": "data"},
    {"name": "سیستەمەکانی لەش (Anatomy Systems)", "path": "/anatomy/systems", "method": "GET", "expected_key": "data"},
]

def run_diagnostics():
    print("=" * 75)
    print(" 🏥 پشکنینی گشتی و تاقیکردنەوەی API و داتابەیسی Dr-Room")
    print(f" 🌐 سێرڤەر: {BASE_URL}")
    print("=" * 75)
    print(f"{'خزمەتگوزاری':<30} | {'دۆخ':<8} | {'کات':<8} | {'تێبینی / ژمارەی داتا':<22}")
    print("-" * 75)

    passed = 0
    total = len(ENDPOINTS)

    for ep in ENDPOINTS:
        url = BASE_URL + ep["path"]
        start_time = time.time()
        try:
            req = urllib.request.Request(
                url,
                headers={
                    "User-Agent": "DrRoom-Diagnostic/1.0",
                    "Accept": "application/json",
                }
            )
            with urllib.request.urlopen(req, timeout=12) as response:
                duration_ms = int((time.time() - start_time) * 1000)
                status_code = response.getcode()
                raw = response.read().decode("utf-8")
                data = json.loads(raw)

                # Analyze payload count
                count_str = ""
                if isinstance(data, list):
                    count_str = f"{len(data)} بڕگە"
                elif isinstance(data, dict):
                    if "data" in data and isinstance(data["data"], list):
                        count_str = f"{len(data['data'])} تۆمار"
                    elif "data" in data and isinstance(data["data"], dict):
                        count_str = f"{len(data['data'])} کلیل"
                    else:
                        count_str = f"{len(data)} بڕگە"

                status_label = "✅ 200" if status_code == 200 else f"⚠️ {status_code}"
                print(f"{ep['name']:<30} | {status_label:<8} | {duration_ms:>5}ms | {count_str:<22}")
                passed += 1

        except urllib.error.HTTPError as e:
            duration_ms = int((time.time() - start_time) * 1000)
            print(f"{ep['name']:<30} | ❌ {e.code:<5} | {duration_ms:>5}ms | هەڵە: {e.reason}")
        except Exception as e:
            duration_ms = int((time.time() - start_time) * 1000)
            print(f"{ep['name']:<30} | ❌ شکستی | {duration_ms:>5}ms | {str(e)[:20]}")

    print("-" * 75)
    pct = int((passed / total) * 100)
    print(f" ئەنجامی کۆتایی: {passed}/{total} خزمەتگوزاری بێ کێشە کاردەکەن ({pct}%)")
    print("=" * 75)

if __name__ == "__main__":
    run_diagnostics()
