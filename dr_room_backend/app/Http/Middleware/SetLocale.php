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
        $locale = $request->header('Accept-Language')
            ?? $request->query('lang')
            ?? ($request->hasSession() && session()->has('locale') ? session()->get('locale') : null);

        if ($locale) {
            $primary = strtolower(trim(explode('-', explode(',', $locale)[0])[0]));
            if (in_array($primary, ['ckb', 'ku', 'ar', 'en'])) {
                app()->setLocale($primary === 'ku' ? 'ckb' : $primary);
            }
        }

        return $next($request);
    }

}
