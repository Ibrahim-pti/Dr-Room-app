<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    // ─── Pill photo identification ────────────────────────────────────────
    // PillVisionService tries these three in the order written. Each has a
    // free tier with its own daily cap, so running one dry falls through to
    // the next instead of taking the scanner down. Any one of them working is
    // enough; keys that are left blank are simply skipped.

    // Free key, no credit card: https://aistudio.google.com
    // The largest free allowance and the best at reading packaging text.
    // Any of these keys may hold several keys separated by commas; each one
    // adds its own daily quota, and they are tried in the order written.
    'gemini' => [
        'key' => env('GEMINI_API_KEY'),
        // An alias rather than a pinned version: Google retires named models
        // ("no longer available to new users") while -latest keeps pointing at
        // the current one.
        'vision_model' => env('GEMINI_VISION_MODEL', 'gemini-flash-latest'),
    ],

    // Free key, no credit card: https://console.groq.com
    'groq' => [
        'key' => env('GROQ_API_KEY'),
        'endpoint' => 'https://api.groq.com/openai/v1/chat/completions',
        'vision_model' => env('GROQ_VISION_MODEL', 'meta-llama/llama-4-scout-17b-16e-instruct'),
    ],

    // Free key, phone verification: https://console.mistral.ai
    'mistral' => [
        'key' => env('MISTRAL_API_KEY'),
        'endpoint' => 'https://api.mistral.ai/v1/chat/completions',
        'vision_model' => env('MISTRAL_VISION_MODEL', 'pixtral-12b-2409'),
    ],

    // otpiq.com — sends the real login/register OTP as an SMS to Iraqi
    // numbers. See https://docs.otpiq.com/api-reference/messaging/post
    'otpiq' => [
        'key' => env('OTPIQ_API_KEY'),

        // Temporary manual mode: while the SMS credit is unpaid, no SMS is
        // sent and this fixed code is what every user types on the OTP screen.
        // Leave empty to go back to real, randomly generated SMS codes.
        'manual_code' => env('OTP_MANUAL_CODE'),
    ],

];
