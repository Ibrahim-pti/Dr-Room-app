<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use App\Services\ReportBrandingService;
use Illuminate\Http\Request;

class ReportSettingsController extends Controller
{
    public function index()
    {
        return response()->json([
            'success' => true,
            'data' => ReportBrandingService::get(),
        ]);
    }

    public function publicBranding()
    {
        return response()->json([
            'success' => true,
            'data' => ReportBrandingService::get(),
        ]);
    }

    public function update(Request $request)
    {
        $validated = $request->validate([
            'header_title' => 'required|string|max:255',
            'header_subtitle' => 'nullable|string|max:255',
            'footer_text' => 'nullable|string',
            'emergency_phone' => 'nullable|string|max:50',
            'show_watermark' => 'nullable',
            'show_stamp' => 'nullable',
            'show_signature' => 'nullable',
            'signature_name' => 'nullable|string|max:120',
            'signature_title' => 'nullable|string|max:120',
            'logo' => 'nullable|file|mimes:jpg,jpeg,png,webp|max:5120',
            'signature' => 'nullable|file|mimes:jpg,jpeg,png,webp|max:5120',
            'clear_logo' => 'nullable',
            'clear_signature' => 'nullable',
        ]);

        AppSetting::set('report_header_title', $validated['header_title'], 'report_branding');

        if ($request->has('header_subtitle')) {
            AppSetting::set('report_header_subtitle', (string) ($validated['header_subtitle'] ?? ''), 'report_branding');
        }
        if ($request->has('footer_text')) {
            AppSetting::set('report_footer_text', (string) ($validated['footer_text'] ?? ''), 'report_branding');
        }
        if ($request->has('emergency_phone')) {
            AppSetting::set('report_emergency_phone', (string) ($validated['emergency_phone'] ?? ''), 'report_branding');
        }
        if ($request->has('show_watermark')) {
            $val = filter_var($request->input('show_watermark'), FILTER_VALIDATE_BOOLEAN);
            AppSetting::set('report_show_watermark', $val ? '1' : '0', 'report_branding');
        }
        if ($request->has('show_stamp')) {
            $val = filter_var($request->input('show_stamp'), FILTER_VALIDATE_BOOLEAN);
            AppSetting::set('report_show_stamp', $val ? '1' : '0', 'report_branding');
        }
        if ($request->has('show_signature')) {
            $val = filter_var($request->input('show_signature'), FILTER_VALIDATE_BOOLEAN);
            AppSetting::set('report_show_signature', $val ? '1' : '0', 'report_branding');
        }
        if ($request->has('signature_name')) {
            AppSetting::set('report_signature_name', (string) ($validated['signature_name'] ?? ''), 'report_branding');
        }
        if ($request->has('signature_title')) {
            AppSetting::set('report_signature_title', (string) ($validated['signature_title'] ?? ''), 'report_branding');
        }

        if (filter_var($request->input('clear_logo', false), FILTER_VALIDATE_BOOLEAN)) {
            AppSetting::where('key', 'report_logo_url')->delete();
        }
        if ($request->hasFile('logo')) {
            $logoPath = $request->file('logo')->store('report_branding', 'public');
            AppSetting::set('report_logo_url', url('storage/' . $logoPath), 'report_branding');
        }

        if (filter_var($request->input('clear_signature', false), FILTER_VALIDATE_BOOLEAN)) {
            AppSetting::where('key', 'report_signature_url')->delete();
        }
        if ($request->hasFile('signature')) {
            $sigPath = $request->file('signature')->store('report_branding', 'public');
            AppSetting::set('report_signature_url', url('storage/' . $sigPath), 'report_branding');
        }

        return response()->json([
            'success' => true,
            'message' => 'دیزاین و واژوو و ڕێکخستنی ڕاپۆرتەکان بە سەرکەوتوویی نوێکرایەوە',
            'data' => ReportBrandingService::get(),
        ]);
    }
}
