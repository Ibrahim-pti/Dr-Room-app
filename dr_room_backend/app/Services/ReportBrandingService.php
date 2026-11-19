<?php

namespace App\Services;

use App\Models\AppSetting;

class ReportBrandingService
{
    public static function get(): array
    {
        return [
            'header_title' => (string) AppSetting::get(
                'report_header_title',
                'دکتۆر ڕۆم - دۆسیەی پزیشکی و ئەنجامی پشکنین'
            ),
            'header_subtitle' => (string) AppSetting::get(
                'report_header_subtitle',
                'Dr. Room Healthcare System & Lab Diagnostics'
            ),
            'footer_text' => (string) AppSetting::get(
                'report_footer_text',
                'ئەم ڕاپۆرتە بە فەرمی لەلایەن تاقیگەی باوەڕپێکراو پەسەندکراوە و پارێزراوە بە مۆری ئەلیکترۆنی.'
            ),
            'emergency_phone' => (string) AppSetting::get(
                'report_emergency_phone',
                '+964 750 000 0000'
            ),
            'show_watermark' => filter_var(
                AppSetting::get('report_show_watermark', true),
                FILTER_VALIDATE_BOOLEAN
            ),
            'show_stamp' => filter_var(
                AppSetting::get('report_show_stamp', true),
                FILTER_VALIDATE_BOOLEAN
            ),
            'show_signature' => filter_var(
                AppSetting::get('report_show_signature', true),
                FILTER_VALIDATE_BOOLEAN
            ),
            'signature_name' => (string) AppSetting::get(
                'report_signature_name',
                'بەڕێوەبەری پزیشکی و تاقیگە'
            ),
            'signature_title' => (string) AppSetting::get(
                'report_signature_title',
                'واژووی فەرمی پەسەندکردن'
            ),
            'logo_url' => AppSetting::get('report_logo_url', null),
            'signature_url' => AppSetting::get('report_signature_url', null),
        ];
    }
}
