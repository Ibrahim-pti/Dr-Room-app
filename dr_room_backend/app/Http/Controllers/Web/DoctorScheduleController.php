<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\Rule;

class DoctorScheduleController extends Controller
{
    public function index()
    {
        $doctor = Auth::user()->doctor;
        
        $schedules = $doctor->schedules()
            ->orderBy('day_of_week')
            ->orderBy('start_time')
            ->get();

        return view('doctor.schedules.index', compact('schedules'));
    }

    private const DAYS = [
        'Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday',
    ];

    public function store(Request $request)
    {
        $doctor = Auth::user()->doctor;

        $request->validate([
            'days' => ['required', 'array', 'min:1'],
            'days.*' => ['string', Rule::in(self::DAYS)],
            'start_time' => 'required|date_format:H:i',
            'end_time' => 'required|date_format:H:i|after:start_time',
            'slot_minutes' => 'required|integer|min:5|max:180',
        ]);

        $start = $request->start_time;
        $end = $request->end_time;
        $createdCount = 0;

        foreach ($request->days as $day) {
            // Check for clash on this specific day
            $clash = $doctor->schedules()
                ->where('day_of_week', $day)
                ->where(fn ($q) => $q->where('start_time', '<', $end)
                    ->where('end_time', '>', $start))
                ->exists();

            if (! $clash) {
                $doctor->schedules()->create([
                    'day_of_week' => $day,
                    'start_time' => $start,
                    'end_time' => $end,
                    'slot_minutes' => $request->slot_minutes,
                ]);
                $createdCount++;
            }
        }

        if ($createdCount === 0) {
            return back()->with('error', 'ئەم کاتە لەگەڵ کاتێکی تر تێکەڵ دەبێت بۆ ڕۆژە دیاریکراوەکان.');
        }

        return back()->with('success', 'خشتەی کارکردن بە سەرکەوتوویی دیاریکرا.');
    }

    public function update(Request $request, $id)
    {
        $doctor = Auth::user()->doctor;
        $schedule = $doctor->schedules()->findOrFail($id);

        $request->validate([
            'start_time' => 'required|date_format:H:i',
            'end_time' => 'required|date_format:H:i|after:start_time',
            'slot_minutes' => 'required|integer|min:5|max:180',
            'is_available' => 'nullable|boolean',
            'reason' => 'nullable|string|max:255',
        ]);

        $start = $request->start_time;
        $end = $request->end_time;

        // Check for clash on this specific day (excluding current schedule)
        $clash = $doctor->schedules()
            ->where('day_of_week', $schedule->day_of_week)
            ->where('id', '!=', $id)
            ->where(fn ($q) => $q->where('start_time', '<', $end)
                ->where('end_time', '>', $start))
            ->exists();

        if ($clash) {
            return back()->with('error', 'ئەم کاتە لەگەڵ کاتێکی تری هەمان ڕۆژ تێکەڵ دەبێت.');
        }

        $schedule->update([
            'start_time' => $start,
            'end_time' => $end,
            'slot_minutes' => $request->slot_minutes,
            'is_available' => $request->has('is_available'),
            'reason' => $request->has('is_available') ? null : $request->reason,
        ]);

        return back()->with('success', 'خشتەی کارکردن بە سەرکەوتوویی نوێکرایەوە.');
    }

    public function destroy($id)
    {
        $doctor = Auth::user()->doctor;
        $schedule = $doctor->schedules()->findOrFail($id);
        $schedule->delete();

        return back()->with('success', 'کاتەکە سڕایەوە.');
    }
}
