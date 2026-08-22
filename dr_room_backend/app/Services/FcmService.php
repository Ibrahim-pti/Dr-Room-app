<?php

namespace App\Services;

use App\Models\DeviceToken;
use Google\Auth\Credentials\ServiceAccountCredentials;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Firebase Cloud Messaging over the HTTP v1 API.
 *
 * Needs two things in .env:
 *   FCM_PROJECT_ID=your-firebase-project-id
 *   FCM_CREDENTIALS=storage/app/firebase-service-account.json
 *
 * Without them every send is a no-op that logs a warning, so the rest of the
 * app keeps working while Firebase is not configured yet.
 */
class FcmService
{
    private const ENDPOINT = 'https://fcm.googleapis.com/v1/projects/%s/messages:send';
    private const SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';

    public function isConfigured(): bool
    {
        return filled(config('services.fcm.project_id'))
            && file_exists($this->credentialsPath());
    }

    /**
     * Send to a set of device tokens. Returns [sent, failed, invalid tokens].
     */
    public function sendToTokens(array $tokens, string $title, string $body, array $data = [], ?string $imageUrl = null): array
    {
        $tokens = array_values(array_filter(array_unique($tokens)));

        if ($tokens === []) {
            return ['sent' => 0, 'failed' => 0, 'invalid' => []];
        }

        if (!$this->isConfigured()) {
            Log::warning('FCM is not configured; notification not delivered.', [
                'title' => $title,
                'tokens' => count($tokens),
            ]);
            return ['sent' => 0, 'failed' => count($tokens), 'invalid' => [], 'reason' => 'not_configured'];
        }

        $accessToken = $this->accessToken();
        $url = sprintf(self::ENDPOINT, config('services.fcm.project_id'));

        $sent = 0;
        $failed = 0;
        $invalid = [];

        $notificationPayload = [
            'title' => $title,
            'body'  => $body,
        ];
        if (!empty($imageUrl)) {
            $notificationPayload['image'] = $imageUrl;
            $data['image'] = $imageUrl;
        }

        foreach ($tokens as $token) {
            $message = [
                'token' => $token,
                'notification' => $notificationPayload,
                'data' => array_map(fn ($v) => (string)$v, $data),
                'android' => [
                    'priority' => 'high',
                ],
                'apns' => [
                    'payload' => [
                        'aps' => ['sound' => 'default'],
                    ],
                ],
            ];

            if (!empty($imageUrl)) {
                $message['android']['notification'] = ['image' => $imageUrl];
                $message['apns']['fcm_options'] = ['image' => $imageUrl];
                $message['apns']['payload']['aps']['mutable-content'] = 1;
            }

            $response = Http::withToken($accessToken)
                ->acceptJson()
                ->post($url, ['message' => $message]);

            if ($response->successful()) {
                $sent++;
                continue;
            }

            $failed++;

            // 404/UNREGISTERED/INVALID_ARGUMENT means the token is invalid or app uninstalled — drop the token.
            if ($response->status() === 404 || 
                str_contains($response->body(), 'UNREGISTERED') || 
                str_contains($response->body(), 'INVALID_ARGUMENT') ||
                str_contains($response->body(), 'SENDER_ID_MISMATCH')) {
                $invalid[] = $token;
            } else {
                Log::warning('FCM send failed', ['status' => $response->status(), 'body' => $response->body()]);
            }

        }

        if ($invalid !== []) {
            DeviceToken::whereIn('token', $invalid)->delete();
        }

        return ['sent' => $sent, 'failed' => $failed, 'invalid' => $invalid];
    }

    /** Broadcast to every registered device, or just one user's devices. */
    public function sendToUsers(?array $userIds, string $title, string $body, array $data = [], ?string $imageUrl = null): array
    {
        $query = DeviceToken::query();

        if ($userIds !== null) {
            $query->whereIn('user_id', $userIds);
        }

        return $this->sendToTokens($query->pluck('token')->all(), $title, $body, $data, $imageUrl);
    }

    /** OAuth token for the service account, cached until just before it expires. */
    private function accessToken(): string
    {
        return Cache::remember('fcm.access_token', 3300, function () {
            $credentials = new ServiceAccountCredentials(self::SCOPE, $this->credentialsPath());

            return $credentials->fetchAuthToken()['access_token'];
        });
    }

    private function credentialsPath(): string
    {
        $path = (string)config('services.fcm.credentials');

        return str_starts_with($path, '/') ? $path : base_path($path);
    }
}
