<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use App\Models\User;
use App\Services\OtpService;

class StaffPasswordResetController extends Controller
{
    public function showForgotForm(Request $request)
    {
        $step = $request->query('step', 'phone');
        $phone = $request->query('phone', session('reset_phone', ''));

        return view('auth.forgot-password', [
            'step' => $step,
            'phone' => $phone,
        ]);
    }

    public function sendOtp(Request $request)
    {
        $request->validate([
            'phone' => ['required', 'string'],
        ], [
            'phone.required' => 'تکایە ژمارەی مۆبایل بنووسە.',
        ]);

        $user = OtpService::findUserByPhoneOrEmail($request->phone);

        if (!$user) {
            return back()->withErrors([
                'phone' => 'هیچ هەژمارێک بەم ژمارە مۆبایلە نەدۆزرایەوە.',
            ])->withInput();
        }

        if ($user->status === 'blocked') {
            return back()->withErrors([
                'phone' => 'هەژمارەکەت بلۆک کراوە.',
            ])->withInput();
        }

        $errorMsg = null;
        if (!OtpService::sendOtp($user, 'sms', $errorMsg)) {
            return back()->withErrors([
                'phone' => $errorMsg ?: 'نەکرا کۆدی پشتڕاستکردنەوە بنێردرێت، تکایە دووبارە هەوڵبدەرەوە.',
            ])->withInput();
        }

        return redirect()->route('password.request', [
            'step' => 'verify',
            'phone' => $user->phone,
        ])->with('success', 'کۆدی ٤ ژمارەیی پشتڕاستکردنەوە بۆ ژمارەی ' . $user->phone . ' نێردرا.');
    }

    public function resetPassword(Request $request)
    {
        $request->validate([
            'phone' => ['required', 'string'],
            'otp_code' => ['required', 'string'],
            'password' => ['required', 'string', 'min:6', 'confirmed'],
        ], [
            'phone.required' => 'تکایە ژمارەی مۆبایل بنووسە.',
            'otp_code.required' => 'تکایە کۆدی ٤ ژمارەیی بنووسە.',
            'password.required' => 'تکایە وشەی تێپەڕی نوێ بنووسە.',
            'password.min' => 'وشەی تێپەڕ دەبێت لانیکەم ٦ پیت بێت.',
            'password.confirmed' => 'دووبارەکردنەوەی وشەی تێپەڕ وەک یەک نییە.',
        ]);

        $user = OtpService::findUserByPhoneOrEmail($request->phone);

        if (!$user) {
            return back()->withErrors([
                'otp_code' => 'بەکارهێنەر نەدۆزرایەوە.',
            ])->withInput();
        }

        if (!OtpService::verifyOtp($user, $request->otp_code)) {
            return back()->withErrors([
                'otp_code' => 'کۆدەکە هەڵەیە یان بەسەرچووە.',
            ])->withInput();
        }

        $user->password = Hash::make($request->password);
        $user->otp_code = null;
        $user->otp_expires_at = null;
        $user->save();

        return redirect()->route('staff.login')
            ->with('success', 'وشەی تێپەڕ بە سەرکەوتوویی نوێکرایەوە. ئێستا دەتوانیت بچیتە ژوورەوە.');
    }
}
