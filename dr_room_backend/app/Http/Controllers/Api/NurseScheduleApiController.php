<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\ProviderSlotService;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class NurseScheduleApiController extends Controller
{
    public function getSchedule(Request $request, $nurseId = null)
    {
        $rawId = $request->query('nurse_id', $nurseId);
        $userId = $rawId
            ? ProviderSlotService::resolveUserId('nurse', $rawId)
            : Auth::id();

        if (!$userId) {
            return response()->json(['success' => false, 'message' => 'پەرستار نەدۆزرایەوە'], 404);
        }

        return response()->json([
            'success' => true,
            'data' => ProviderSlotService::week($userId, 'nurse'),
        ]);
    }

    public function updateSchedule(Request $request)
    {
        $rawId = $request->input('nurse_id');
        $userId = $rawId
            ? ProviderSlotService::resolveUserId('nurse', $rawId)
            : Auth::id();

        if (!$userId) {
            return response()->json(['success' => false, 'message' => 'پەرستار نەدۆزرایەوە'], 404);
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
            'schedules.*.max_daily_visits' => 'nullable|integer|min:1|max:200',
        ]);

        $days = array_map(function ($row) {
            if (!isset($row['max_daily_orders']) && isset($row['max_daily_visits'])) {
                $row['max_daily_orders'] = $row['max_daily_visits'];
            }
            return $row;
        }, $validated['schedules']);

        ProviderSlotService::saveWeek($userId, 'nurse', $days);

        return response()->json([
            'success' => true,
            'message' => 'خشتەی دەوام نوێکرایەوە',
        ]);
    }

    public function checkCollision(Request $request)
    {
        $request->validate([
            'nurse_id' => 'required',
            'scheduled_time' => 'required|date',
        ]);

        $userId = ProviderSlotService::resolveUserId('nurse', $request->nurse_id) ?? Auth::id();
        $targetTime = Carbon::parse($request->scheduled_time);
        $available = ProviderSlotService::isBookable('nurse', $userId, $targetTime);

        return response()->json([
            'success' => true,
            'is_available' => $available,
            'message' => $available ? 'کاتەکە بەردەستە' : 'پەرستارەکە لەم کاتەدا داواکارییەکی تری هەیە',
        ]);
    }
}
