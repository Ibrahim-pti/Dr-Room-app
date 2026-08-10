<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureLabProfileComplete
{
    /**
     * Handle an incoming request.
     *
     * @param  Closure(Request): (Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if ($user && $user->is_lab) {
            $lab = $user->lab;

            if (!$lab) {
                return redirect()->route('lab.profile.index')
                    ->with('error', 'تکایە سەرەتا زانیارییەکانی پرۆفایلەکەت بە تەواوی پڕبکەرەوە بۆ ئەوەی بتوانیت داشبۆرد بەکاربهێنیت.');
            }

            // Check if profile fields are filled
            $isProfileComplete = $lab->about_us && $lab->location;

            if (!$isProfileComplete) {
                return redirect()->route('lab.profile.index')
                    ->with('error', 'تکایە سەرەتا زانیارییەکانی پرۆفایلی تاقیگە بە تەواوی پڕبکەرەوە بۆ ئەوەی بتوانیت داشبۆرد بەکاربهێنیت.');
            }
        }

        return $next($request);
    }
}
