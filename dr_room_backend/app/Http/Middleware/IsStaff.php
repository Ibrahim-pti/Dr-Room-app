<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Lets admin, staff and moderator reach the dashboard. What each may actually
 * do is decided per-route by [HasPermission].
 */
class IsStaff
{
    public function handle(Request $request, Closure $next): Response
    {
        if (!$request->user() || !$request->user()->is_staff) {
            return response()->json(['message' => 'Unauthorized. Staff access required.'], 403);
        }

        if ($request->user()->status === 'blocked') {
            return response()->json(['message' => 'ئەم هەژمارە ڕاگیراوە.'], 403);
        }

        return $next($request);
    }
}
