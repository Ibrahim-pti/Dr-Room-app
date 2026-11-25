<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class IsLab
{
    public function handle(Request $request, Closure $next): Response
    {
        if (!auth()->check() || !auth()->user()->is_lab) {
            if ($request->expectsJson()) {
                return response()->json(['message' => 'Access denied. Lab account required.'], 403);
            }
            return redirect('/staff/login');
        }

        $status = auth()->user()->status;
        if (in_array($status, ['blocked', 'rejected'], true)) {
            if ($request->expectsJson()) {
                return response()->json(['message' => 'هەژمارەکەت بلۆک کراوە.'], 403);
            }
            return redirect('/staff/login');
        }

        if ($status === 'pending') {
            if ($request->expectsJson()) {
                return response()->json(['message' => 'هەژمارەکەت لەژێر پێداچوونەوەی ئەدمیندایە.'], 403);
            }
            return redirect()->route('staff.waiting');
        }

        return $next($request);
    }
}
