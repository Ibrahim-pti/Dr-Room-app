<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Nurse;
use App\Models\NurseSchedule;
use App\Models\Order;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class NurseScheduleApiController extends Controller
{
    /**
     * Get nurse schedule
     */
    public function getSchedule(Request $request, $nurseId = null)
    {
        if (!$nurseId) {
            $user = Auth::user();
            $nurse = $user->nurse;
            if (!$nurse) {
                return response()->json(['success' => false, 'message' => 'پەرستار نەدۆزرایەوە'], 404);
            }
            $nurseId = $nurse->id;
        }

        $days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
        $existing = NurseSchedule::where('nurse_id', $nurseId)->get()->keyBy('day_of_week');

        $schedule = collect($days)->map(function ($day) use ($existing, $nurseId) {
            if ($existing->has($day)) {
                return $existing->get($day);
            }
            return [
                'nurse_id' => $nurseId,
                'day_of_week' => $day,
                'start_time' => '08:00:00',
                'end_time' => '20:00:00',
                'is_available' => true,
                'max_daily_visits' => 6,
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $schedule,
        ]);
    }

    /**
     * Save weekly schedule
     */
    public function updateSchedule(Request $request)
    {
        $nurse = Auth::user()->nurse;
        if (!$nurse) {
            return response()->json(['success' => false, 'message' => 'تەنها پەرستار دەتوانێت دەستکاری بکات'], 403);
        }

        $request->validate([
            'schedules' => 'required|array',
            'schedules.*.day_of_week' => 'required|string',
            'schedules.*.start_time' => 'required|string',
            'schedules.*.end_time' => 'required|string',
            'schedules.*.is_available' => 'required|boolean',
            'schedules.*.max_daily_visits' => 'nullable|integer|min:1',
        ]);

        foreach ($request->schedules as $item) {
            NurseSchedule::updateOrCreate(
                ['nurse_id' => $nurse->id, 'day_of_week' => $item['day_of_week']],
                [
                    'start_time' => $item['start_time'],
                    'end_time' => $item['end_time'],
                    'is_available' => $item['is_available'],
                    'max_daily_visits' => $item['max_daily_visits'] ?? 6,
                ]
            );
        }

        return response()->json([
            'success' => true,
            'message' => 'خشتەی دەوام نوێکرایەوە',
        ]);
    }

    /**
     * Check if a nurse is available at a given time or if they have collision
     */
    public function checkCollision(Request $request)
    {
        $request->validate([
            'nurse_id' => 'required',
            'scheduled_time' => 'required|date',
        ]);

        $nurseUser = Nurse::find($request->nurse_id)?->user ?? Auth::user();
        $targetTime = Carbon::parse($request->scheduled_time);

        // Check buffer of 90 minutes before and after
        $windowStart = $targetTime->copy()->subMinutes(90);
        $windowEnd = $targetTime->copy()->addMinutes(90);

        $hasCollision = Order::where('assigned_nurse_id', $nurseUser->id)
            ->whereIn('status', ['pending', 'accepted', 'in_progress'])
            ->whereBetween('created_at', [$windowStart, $windowEnd])
            ->exists();

        return response()->json([
            'success' => true,
            'is_available' => !$hasCollision,
            'message' => $hasCollision ? 'پەرستارەکە لەم کاتەدا داواکارییەکی تری هەیە' : 'کاتەکە بەردەستە',
        ]);
    }
}
