<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class OtpService
{
    /**
     * Iraqi mobile numbers are stored locally as 11 digits starting with 0
     * (e.g. 07701234567). otpiq.com expects the international format
     * without a leading +, so the 0 is swapped for the 964 country code.
     */
    public static function toIraqPhone(string $localPhone): string
    {
        $clean = preg_replace('/[^0-9]/', '', $localPhone);
        if (str_starts_with($clean, '00964')) {
            $clean = substr($clean, 2);
        }
        if (str_starts_with($clean, '964')) {
            return $clean;
        }
        if (str_starts_with($clean, '0')) {
            return '964' . substr($clean, 1);
        }
        if (str_starts_with($clean, '7')) {
            return '964' . $clean;
        }
        return $clean;
    }

    /**
     * Converts any incoming Iraqi mobile number format (+9647..., 9647..., 7..., 07...)
     * to the standard local 11-digit database format: 07xxxxxxxxx
     */
    public static function toLocalPhone(string $phone): string
    {
        $clean = preg_replace('/[^0-9]/', '', $phone);

        if (str_starts_with($clean, '00964')) {
            $clean = substr($clean, 2);
        }

        if (str_starts_with($clean, '964')) {
            $withoutCountry = substr($clean, 3);
            if (str_starts_with($withoutCountry, '0')) {
                return $withoutCountry;
            }
            return '0' . $withoutCountry;
        }

        if (str_starts_with($clean, '7')) {
            return '0' . $clean;
        }

        return $clean;
    }

    /**
     * Find user by phone in multiple formats or by email.
     */
    public static function findUserByPhoneOrEmail(string $input): ?User
    {
        $input = trim($input);
        if (empty($input)) {
            return null;
        }

        // If it's an email
        if (filter_var($input, FILTER_VALIDATE_EMAIL)) {
            return User::where('email', $input)->first();
        }

        $cleanPhone = preg_replace('/[^0-9]/', '', $input);
        $localPhone = self::toLocalPhone($input);

        return User::where('phone', $localPhone)
            ->orWhere('phone', $cleanPhone)
            ->orWhere('phone', $input)
            ->orWhere('phone', ltrim($cleanPhone, '0'))
            ->orWhere('phone', '0' . ltrim($cleanPhone, '0'))
            ->orWhere('email', $input)
            ->first();
    }

    /**
     * Generates a 4-digit OTP, stores it on the user, and sends it via otpiq.com SMS.
     */
    public static function sendOtp(User $user, string $provider = 'sms', ?string &$errorMessage = null): bool
    {
        // Special reviewer / test accounts
        if (in_array($user->phone, ['07500000000', '07501112222'])) {
            $user->otp_code = '1234';
            $user->otp_expires_at = now()->addYears(1);
            $user->save();
            return true;
        }

        $configuredCode = config('services.otpiq.manual_code');
        $isProduction = app()->environment('production');

        if ($configuredCode && $isProduction) {
            Log::warning('OTP_MANUAL_CODE is set on a production server and was ignored');
        }

        $manualCode = $isProduction ? null : $configuredCode;

        $otp = $manualCode ? (string) $manualCode : (string) random_int(1000, 9999);
        $user->otp_code = $otp;
        $user->otp_expires_at = now()->addMinutes($manualCode ? 60 : 5);
        $user->save();

        if ($manualCode) {
            return true;
        }

        $apiKey = config('services.otpiq.key') ?: env('OTPIQ_API_KEY');

        $validProviders = ['auto', 'sms', 'whatsapp', 'telegram'];
        $chosenProvider = in_array(strtolower($provider), $validProviders)
            ? strtolower($provider)
            : (config('services.otpiq.provider') ?: 'sms');

        $payload = [
            'phoneNumber' => self::toIraqPhone($user->phone),
            'smsType' => 'verification',
            'provider' => $chosenProvider,
            'verificationCode' => (string) $otp,
            'customMessage' => 'فەرموون ئەوەش کۆدی ئۆتیپی ' . $otp,
        ];

        try {
            $response = Http::withToken($apiKey)
                ->timeout(15)
                ->post('https://api.otpiq.com/api/sms', $payload);

            if (!$response->successful()) {
                $rawError = $response->json('error') ?? $response->body();
                Log::error('OTPIQ SMS API error', [
                    'status' => $response->status(),
                    'response' => $response->json() ?? $response->body(),
                    'phone' => self::toIraqPhone($user->phone),
                    'provider' => $chosenProvider,
                ]);

                if (is_string($rawError) && stripos($rawError, 'trial mode') !== false) {
                    $errorMessage = 'ئەکاونتی OTPIQ لە دۆخی تاقیکاری (Trial) دایە؛ پێویستە باڵانس زیاد بکرێت.';
                } else {
                    $errorMessage = 'نەکرا کۆدی پشتڕاستکردنەوە بنێردرێت: ' . ($response->json('error') ?? 'هەڵەی سێرڤەری کورتەنامە');
                }
                return false;
            }

            Log::info('OTPIQ OTP sent successfully', [
                'phone' => self::toIraqPhone($user->phone),
                'provider' => $chosenProvider,
            ]);

            return true;
        } catch (\Throwable $e) {
            Log::error('OTPIQ request exception: ' . $e->getMessage(), [
                'phone' => self::toIraqPhone($user->phone),
                'provider' => $chosenProvider,
            ]);
            $errorMessage = 'نەتوانرا پەیوەندی بە سێرڤەری کورتەنامە (OTPIQ) بکرێت.';
            return false;
        }
    }

    /**
     * Send a custom SMS/WhatsApp notification message via otpiq.com.
     */
    public static function sendCustomMessage(
        string $phone,
        string $message,
        ?string $provider = null,
        ?string &$errorMessage = null
    ): bool {
        $apiKey = config('services.otpiq.key') ?: env('OTPIQ_API_KEY');
        if (empty($apiKey)) {
            $errorMessage = 'کلیلی OTPIQ دیاری نەکراوە.';
            Log::warning('OTPIQ custom message skipped: missing OTPIQ_API_KEY');
            return false;
        }

        $localPhone = self::toLocalPhone($phone);
        if (in_array($localPhone, ['07500000000', '07501112222'], true)) {
            return true;
        }

        $validProviders = ['auto', 'sms', 'whatsapp', 'telegram'];
        $rawProvider = $provider ?: (config('services.otpiq.provider') ?: 'sms');
        $chosenProvider = in_array(strtolower($rawProvider), $validProviders, true)
            ? strtolower($rawProvider)
            : 'sms';

        $iraqPhone = self::toIraqPhone($phone);
        $payload = [
            'phoneNumber' => $iraqPhone,
            'smsType' => 'custom',
            'provider' => $chosenProvider,
            'customMessage' => $message,
        ];

        $senderId = config('services.otpiq.sender_id');
        if (!empty($senderId)) {
            $payload['senderId'] = $senderId;
        }

        try {
            $response = Http::withToken($apiKey)
                ->timeout(10)
                ->post('https://api.otpiq.com/api/sms', $payload);

            if (!$response->successful()) {
                $rawError = $response->json('error') ?? $response->json('message') ?? $response->body();
                Log::error('OTPIQ custom message API error', [
                    'status' => $response->status(),
                    'response' => $response->json() ?? $response->body(),
                    'phone' => $iraqPhone,
                    'provider' => $chosenProvider,
                ]);
                $errorMessage = is_string($rawError) && $rawError !== ''
                    ? $rawError
                    : 'هەڵەی سێرڤەری کورتەنامە (OTPIQ)';
                return false;
            }

            Log::info('OTPIQ custom message sent successfully', [
                'phone' => $iraqPhone,
                'provider' => $chosenProvider,
            ]);

            return true;
        } catch (\Throwable $e) {
            Log::error('OTPIQ custom message exception: ' . $e->getMessage(), [
                'phone' => $iraqPhone,
                'provider' => $chosenProvider,
            ]);
            $errorMessage = 'نەتوانرا پەیوەندی بە سێرڤەری کورتەنامە (OTPIQ) بکرێت.';
            return false;
        }
    }

    /**
     * Verify OTP code for a user.
     */
    public static function verifyOtp(User $user, string $otpCode): bool
    {
        // Special test accounts
        if (in_array($user->phone, ['07500000000', '07501112222']) && $otpCode === '1234') {
            return true;
        }

        if (!$user->otp_code || $user->otp_code !== $otpCode) {
            return false;
        }

        if ($user->otp_expires_at && now()->gt($user->otp_expires_at)) {
            return false;
        }

        return true;
    }
}
