<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class IsDoctor
{
    public function handle(Request $request, Closure $next): Response
    {
        if (!auth()->check() || !auth()->user()->is_doctor) {
            // Return JSON for API requests, redirect for web requests
            if ($request->expectsJson()) {
                return response()->json(['message' => 'Access denied. Doctor account required.'], 403);
            }
            return redirect('/staff/login');
        }

        if (auth()->user()->status === 'pending') {
            return redirect()->route('staff.waiting');
        }

        return $next($request);
    }
}
