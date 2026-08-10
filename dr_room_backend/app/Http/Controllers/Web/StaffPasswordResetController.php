<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Auth\Events\PasswordReset;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Str;

/**
 * "Forgot password" for dashboard users (doctors, labs, pharmacies, nurses).
 *
 * Uses Laravel's password broker, so tokens are hashed, single-use and expire
 * on their own — see config/auth.php `passwords.users`.
 */
class StaffPasswordResetController extends Controller
{
    public function showLinkRequest()
    {
        return view('auth.forgot-password');
    }

    public function sendLink(Request $request)
    {
        $request->validate(['email' => 'required|email']);

        $status = Password::sendResetLink($request->only('email'));

        // Always report success: telling a stranger which addresses exist
        // hands them a list of accounts to attack.
        if ($status === Password::RESET_LINK_SENT || $status === Password::INVALID_USER) {
            return back()->with('status', 'ئەگەر ئەم ئیمێلە تۆمارکرابێت، بەستەرێکی گەڕاندنەوەمان بۆ ناردیت.');
        }

        return back()->withErrors(['email' => __($status)]);
    }

    public function showResetForm(Request $request, string $token)
    {
        return view('auth.reset-password', [
            'token' => $token,
            'email' => $request->query('email'),
        ]);
    }

    public function reset(Request $request)
    {
        $request->validate([
            'token' => 'required',
            'email' => 'required|email',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $status = Password::reset(
            $request->only('email', 'password', 'password_confirmation', 'token'),
            function ($user, string $password) {
                $user->forceFill([
                    'password' => Hash::make($password),
                    'remember_token' => Str::random(60),
                ])->save();

                event(new PasswordReset($user));
            },
        );

        if ($status === Password::PASSWORD_RESET) {
            return redirect()->route('staff.login')
                ->with('success', 'وشەی نهێنییەکەت گۆڕدرا. ئێستا دەتوانیت بچیتە ژوورەوە.');
        }

        return back()->withErrors(['email' => __($status)]);
    }
}
