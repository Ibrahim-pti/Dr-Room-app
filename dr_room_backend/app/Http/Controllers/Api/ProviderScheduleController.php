<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\ProviderSlotService;
use Carbon\Carbon;
use Illuminate\Http\Request;

class ProviderScheduleController extends Controller
{
    private function normalizeType(?string $raw): ?string
    {
        $t = strtolower(trim((string) $raw));
        if (str_contains($t, 'nurs')) {
            return 'nurse';
        }
        if (str_contains($t, 'lab')) {
            return 'lab';
        }
        if (str_contains($t, 'driv') || str_contains($t, 'deliv')) {
            return 'driver';
        }
        return ProviderSlotService::isValidType($t) ? $t : null;
    }

    // ─── Admin: section-by-section (nurse | lab | driver) ──────────────────

    public function adminProviders(Request $request)
    {
        $type = $this->normalizeType($request->query('type', 'driver'));
        if (!$type) {
            return response()->json(['success' => false, 'message' => 'جۆری ستاف نادروستە'], 422);
        }

        $category = $request->query('category');
        $normalizedCategory = $category ? $this->normalizeType($category) : null;

        return response()->json([
            'success' => true,
            'type' => $type,
            'data' => ProviderSlotService::providerSummaries($type, $normalizedCategory),
        ]);
    }

    public function adminShow(string $type, int $userId)
    {
        $type = $this->normalizeType($type);
        if (!$type) {
            return response()->json(['success' => false, 'message' => 'جۆری ستاف نادروستە'], 422);
        }

        $resolvedId = ProviderSlotService::resolveUserId($type, $userId);
        if (!$resolvedId) {
            return response()->json(['success' => false, 'message' => 'ستاف نەدۆزرایەوە'], 404);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'user_id' => $resolvedId,
                'type' => $type,
                'week' => ProviderSlotService::week($resolvedId, $type),
                'availability' => ProviderSlotService::availability($type, $resolvedId, Carbon::today(), 7),
                'upcoming' => ProviderSlotService::upcoming($resolvedId, $type, 14),
            ],
        ]);
    }

    public function adminUpdate(Request $request, string $type, int $userId)
    {
        $type = $this->normalizeType($type);
        if (!$type) {
            return response()->json(['success' => false, 'message' => 'جۆری ستاف نادروستە'], 422);
        }

        $resolvedId = ProviderSlotService::resolveUserId($type, $userId);
        if (!$resolvedId) {
            return response()->json(['success' => false, 'message' => 'ستاف نەدۆزرایەوە'], 404);
        }

        $validated = $request->validate([
            'schedules' => 'required|array|min:1',
            'schedules.*.day_of_week' => 'required|string',
            'schedules.*.start_time' => 'required|string',
            'schedules.*.end_time' => 'required|string',
            'schedules.*.is_available' => 'required',
            'schedules.*.slot_minutes' => 'nullable|integer|min:10|max:240',
            'schedules.*.slot_capacity' => 'nullable|integer|min:1|max:50',
            'schedules.*.max_daily_orders' => 'nullable|integer|min:1|max:200',
        ]);

        ProviderSlotService::saveWeek($resolvedId, $type, $validated['schedules']);

        return response()->json([
            'success' => true,
            'message' => 'خشتەی دەوام بە سەرکەوتوویی پاشەکەوتکرا',
            'data' => [
                'week' => ProviderSlotService::week($resolvedId, $type),
                'availability' => ProviderSlotService::availability($type, $resolvedId, Carbon::today(), 7),
            ],
        ]);
    }

    // ─── User App: public availability & slot validation ────────────────────

    public function availability(Request $request)
    {
        $type = $this->normalizeType($request->query('type', 'nurse'));
        if (!$type) {
            return response()->json(['success' => false, 'message' => 'جۆری خزمەتگوزاری نادروستە'], 422);
        }

        $days = max(1, min(ProviderSlotService::HORIZON_DAYS, (int) $request->query('days', 14)));
        $rawProviderId = $request->query('provider_id');
        $providerUserId = null;

        if ($rawProviderId !== null && $rawProviderId !== '' && $rawProviderId !== '0') {
            $providerUserId = ProviderSlotService::resolveUserId($type, $rawProviderId);
            if (!$providerUserId) {
                return response()->json([
                    'success' => true,
                    'data' => [
                        'type' => $type,
                        'provider_user_id' => null,
                        'days' => [],
                    ],
                ]);
            }
        }

        return response()->json([
            'success' => true,
            'data' => [
                'type' => $type,
                'provider_user_id' => $providerUserId,
                'days' => ProviderSlotService::availability($type, $providerUserId, Carbon::today(), $days),
            ],
        ]);
    }

    public function checkSlot(Request $request)
    {
        $request->validate([
            'type' => 'required|string',
            'scheduled_at' => 'required|date',
            'provider_id' => 'nullable',
        ]);

        $type = $this->normalizeType($request->input('type'));
        if (!$type) {
            return response()->json(['success' => false, 'available' => false, 'message' => 'جۆری خزمەتگوزاری نادروستە'], 422);
        }

        $providerUserId = $request->filled('provider_id')
            ? ProviderSlotService::resolveUserId($type, $request->input('provider_id'))
            : null;

        $at = Carbon::parse($request->input('scheduled_at'));
        $available = ProviderSlotService::isBookable($type, $providerUserId, $at);

        return response()->json([
            'success' => true,
            'available' => $available,
            'message' => $available ? 'کاتەکە بەردەستە' : 'ئەم کاتە پڕبووەتەوە (گیراوە) یان بەردەست نییە',
        ]);
    }

    // ─── Driver App: own schedule, booked/free slots & upcoming deliveries ──

    public function driverSchedule(Request $request)
    {
        /** @var User $user */
        $user = $request->user();

        return response()->json([
            'success' => true,
            'data' => [
                'user_id' => $user->id,
                'is_on_shift_now' => ProviderSlotService::isOnShift($user->id),
                'week' => ProviderSlotService::week($user->id, 'driver'),
                'availability' => ProviderSlotService::availability('driver', $user->id, Carbon::today(), 7),
                'upcoming' => ProviderSlotService::upcoming($user->id, 'driver', 14),
            ],
        ]);
    }

    public function updateDriverSchedule(Request $request)
    {
        /** @var User $user */
        $user = $request->user();

        $validated = $request->validate([
            'schedules' => 'required|array|min:1',
            'schedules.*.day_of_week' => 'required|string',
            'schedules.*.start_time' => 'required|string',
            'schedules.*.end_time' => 'required|string',
            'schedules.*.is_available' => 'required',
            'schedules.*.slot_minutes' => 'nullable|integer|min:10|max:240',
            'schedules.*.slot_capacity' => 'nullable|integer|min:1|max:50',
            'schedules.*.max_daily_orders' => 'nullable|integer|min:1|max:200',
        ]);

        ProviderSlotService::saveWeek($user->id, 'driver', $validated['schedules']);

        return response()->json([
            'success' => true,
            'message' => 'خشتەی دەوامت نوێکرایەوە',
            'data' => [
                'is_on_shift_now' => ProviderSlotService::isOnShift($user->id),
                'week' => ProviderSlotService::week($user->id, 'driver'),
                'availability' => ProviderSlotService::availability('driver', $user->id, Carbon::today(), 7),
                'upcoming' => ProviderSlotService::upcoming($user->id, 'driver', 14),
            ],
        ]);
    }
}
