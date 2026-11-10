<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class IsDriver
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (!$user || $user->role !== 'driver') {
            return response()->json(['message' => 'ئەم بەشە تەنها بۆ کارمەندانی گەیاندنە.'], 403);
        }

        if ($user->status === 'pending') {
            return response()->json(['message' => 'هەژمارەکەت هێشتا لەژێر پێداچوونەوەی ئەدمیندایە.'], 403);
        }

        if ($user->status === 'blocked') {
            return response()->json(['message' => 'هەژمارەکەت بلۆک کراوە.'], 403);
        }

        return $next($request);
    }
}

