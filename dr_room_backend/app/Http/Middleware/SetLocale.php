<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class SetLocale
{
    /**
     * Handle an incoming request.
     *
     * @param  Closure(Request): (Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $locale = $request->query('lang')
            ?? ($request->hasSession() && session()->has('locale') ? session()->get('locale') : null)
            ?? $request->header('Accept-Language');

        if ($locale) {
            $primary = strtolower(trim(explode('-', explode(',', $locale)[0])[0]));
            if (in_array($primary, ['ckb', 'kmr', 'bdn', 'ku', 'ar', 'en'])) {
                $target = $primary === 'ku' ? 'ckb' : ($primary === 'bdn' ? 'kmr' : $primary);
                app()->setLocale($target);
                if ($request->hasSession()) {
                    session()->put('locale', $target);
                }
            }
        }

        return $next($request);
    }

}
