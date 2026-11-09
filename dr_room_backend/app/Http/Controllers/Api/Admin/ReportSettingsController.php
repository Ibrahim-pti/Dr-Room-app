<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use Illuminate\Http\Request;

class ReportSettingsController extends Controller
{
    public function index()
    {
        $settings = [
            'header_title' => AppSetting::get('report_header_title', 'دکتۆر ڕۆم - دۆسیەی پزیشکی و ئەنجامی پشکنین'),
            'header_subtitle' => AppSetting::get('report_header_subtitle', 'Dr. Room Healthcare System & Lab Diagnostics'),
            'footer_text' => AppSetting::get('report_footer_text', 'ئەم ڕاپۆرتە بە فەرمی لەلایەن تاقیگەی باوەڕپێکراو پەسەندکراوە و پارێزراوە بە مۆری ئەلیکترۆنی.'),
            'emergency_phone' => AppSetting::get('report_emergency_phone', '+964 750 000 0000'),
            'show_watermark' => AppSetting::get('report_show_watermark', true),
            'show_stamp' => AppSetting::get('report_show_stamp', true),
            'logo_url' => AppSetting::get('report_logo_url', null),
        ];

        return response()->json([
            'success' => true,
            'data' => $settings,
        ]);
    }

    public function update(Request $request)
    {
        $validated = $request->validate([
            'header_title' => 'required|string|max:255',
            'header_subtitle' => 'nullable|string|max:255',
            'footer_text' => 'nullable|string',
            'emergency_phone' => 'nullable|string|max:50',
            'show_watermark' => 'nullable|boolean',
            'show_stamp' => 'nullable|boolean',
            'logo' => 'nullable|file|mimes:jpg,jpeg,png,webp|max:5120',
        ]);

        AppSetting::set('report_header_title', $validated['header_title'], 'report_branding');
        if (isset($validated['header_subtitle'])) {
            AppSetting::set('report_header_subtitle', $validated['header_subtitle'], 'report_branding');
        }
        if (isset($validated['footer_text'])) {
            AppSetting::set('report_footer_text', $validated['footer_text'], 'report_branding');
        }
        if (isset($validated['emergency_phone'])) {
            AppSetting::set('report_emergency_phone', $validated['emergency_phone'], 'report_branding');
        }
        if (isset($validated['show_watermark'])) {
            AppSetting::set('report_show_watermark', $validated['show_watermark'], 'report_branding');
        }
        if (isset($validated['show_stamp'])) {
            AppSetting::set('report_show_stamp', $validated['show_stamp'], 'report_branding');
        }

        if ($request->hasFile('logo')) {
            $logoPath = $request->file('logo')->store('report_branding', 'public');
            AppSetting::set('report_logo_url', url('storage/' . $logoPath), 'report_branding');
        }

        return response()->json([
            'success' => true,
            'message' => 'دیزاین و ڕێکخستنی ڕاپۆرتەکان بە سەرکەوتوویی نوێکرایەوە',
            'data' => $this->index()->original['data'],
        ]);
    }
}

