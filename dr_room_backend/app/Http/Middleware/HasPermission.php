<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Route middleware: `permission:manage_reviews`. Assumes IsStaff already ran.
 */
class HasPermission
{
    public function handle(Request $request, Closure $next, string $permission): Response
    {
        $user = $request->user();

        if (!$user || !$user->is_staff) {
            return response()->json(['message' => 'دەسەڵاتت نییە بۆ ئەم بەشە.'], 403);
        }

        if (!$user->hasPermission($permission)) {
            return response()->json([
                'message' => 'دەسەڵاتی پێویستت نییە بۆ ئەم کارە.',
                'required_permission' => $permission,
            ], 403);
        }

        return $next($request);
    }
}
