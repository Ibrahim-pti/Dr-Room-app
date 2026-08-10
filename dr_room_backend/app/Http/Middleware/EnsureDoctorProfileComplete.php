<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureDoctorProfileComplete
{
    /**
     * Handle an incoming request.
     *
     * @param  Closure(Request): (Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if ($user && $user->is_doctor) {
            $doctor = $user->doctor;

            if (!$doctor) {
                return redirect()->route('doctor.profile.index')
                    ->with('error', 'تکایە سەرەتا زانیارییەکانی پرۆفایلەکەت بە تەواوی پڕبکەرەوە بۆ ئەوەی بتوانیت داشبۆرد بەکاربهێنیت.');
            }

            // Check if profile fields are filled
            $isProfileComplete = $doctor->specialty && $doctor->bio ;
            
            // Check if they have at least one service and one schedule
            $hasServices = $doctor->services()->exists();
            $hasSchedules = $doctor->schedules()->exists();

            if (!$isProfileComplete || !$hasServices || !$hasSchedules) {
                return redirect()->route('doctor.profile.index')
                    ->with('error', 'تکایە سەرەتا زانیارییەکانی پرۆفایلەکەت، خزمەتگوزارییەکان، وە خشتەی کارکردنت بە تەواوی پڕبکەرەوە بۆ ئەوەی بتوانیت داشبۆرد بەکاربهێنیت.');
            }
        }

        return $next($request);
    }
}
