<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use App\Models\User;
use App\Services\OtpService;

class StaffAuthController extends Controller
{
    public function showLogin()
    {
        if (Auth::check()) {
            return $this->redirectBasedOnRole(Auth::user()->role);
        }
        return view('auth.login');
    }

    public function login(Request $request)
    {
        $request->validate([
            'phone' => ['required', 'string'],
            'password' => ['required', 'string'],
        ], [
            'phone.required' => 'تکایە ژمارەی مۆبایلەکەت بنووسە.',
            'password.required' => 'تکایە وشەی تێپەڕ بنووسە.',
        ]);

        $input = $request->phone;
        $user = OtpService::findUserByPhoneOrEmail($input);

        if (!$user || !Hash::check($request->password, $user->password)) {
            return back()->withErrors([
                'phone' => 'ژمارەی مۆبایل یان وشەی تێپەڕ هەڵەیە.',
            ])->withInput($request->except('password'));
        }

        if ($user->status === 'pending') {
            Auth::guard('web')->login($user, true);
            return redirect()->route('staff.waiting');
        }

        if ($user->status === 'blocked') {
            return back()->withErrors([
                'phone' => 'هەژمارەکەت بلۆک کراوە.',
            ])->withInput($request->except('password'));
        }

        if (in_array($user->role, ['doctor', 'nurse', 'lab', 'pharmacy', 'admin'])) {
            // Default remember to true so session never expires prematurely
            $remember = $request->boolean('remember', true);
            Auth::guard('web')->login($user, $remember);
            $request->session()->regenerate();
            return $this->redirectBasedOnRole($user->role);
        } else {
            return back()->withErrors([
                'phone' => 'تۆ دەسەڵاتی ستافت نییە بۆ چوونەژوورەوە لێرە.',
            ])->withInput($request->except('password'));
        }
    }

    public function showRegister()
    {
        if (Auth::check()) {
            return $this->redirectBasedOnRole(Auth::user()->role);
        }
        return view('auth.register');
    }

    public function register(Request $request)
    {
        $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'phone' => ['required', 'string', 'max:25'],
            'role' => ['required', 'string', 'in:doctor,nurse,lab,pharmacy'],
            'password' => ['required', 'string', 'min:6', 'confirmed'],
            'email' => ['nullable', 'string', 'email', 'max:255'],
        ], [
            'name.required' => 'تکایە ناوی تەواو بنووسە.',
            'phone.required' => 'تکایە ژمارەی مۆبایل بنووسە.',
            'role.required' => 'تکایە پیشەکەت دیاری بکە.',
            'password.required' => 'تکایە وشەی تێپەڕ بنووسە.',
            'password.min' => 'وشەی تێپەڕ دەبێت لانیکەم ٦ پیت بێت.',
            'password.confirmed' => 'دووبارەکردنەوەی وشەی تێپەڕ وەک یەک نییە.',
        ]);

        $localPhone = OtpService::toLocalPhone($request->phone);

        // Check if phone already registered
        $existing = OtpService::findUserByPhoneOrEmail($localPhone);
        if ($existing) {
            return back()->withErrors([
                'phone' => 'ئەم ژمارە مۆبایلە پێشتر تۆمارکراوە، تکایە بچۆ ژوورەوە.',
            ])->withInput($request->except('password', 'password_confirmation'));
        }

        if ($request->filled('email')) {
            if (User::where('email', $request->email)->exists()) {
                return back()->withErrors([
                    'email' => 'ئەم ئیمەیڵە پێشتر بەکارهاتووە.',
                ])->withInput($request->except('password', 'password_confirmation'));
            }
        }

        $user = User::create([
            'name' => $request->name,
            'phone' => $localPhone,
            'email' => $request->email ?: ($localPhone . '@drroom.com'),
            'password' => Hash::make($request->password),
            'role' => $request->role,
            'status' => 'pending',
        ]);

        Auth::guard('web')->login($user, true);
        return redirect()->route('staff.waiting');
    }

    public function logout(Request $request)
    {
        Auth::guard('web')->logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();
        return redirect()->route('staff.login');
    }

    private function redirectBasedOnRole($role)
    {
        if ($role === 'doctor') {
            return redirect('/doctor/dashboard');
        } elseif ($role === 'nurse') {
            return redirect('/nurse/dashboard');
        } elseif ($role === 'lab') {
            return redirect('/lab/dashboard');
        } elseif ($role === 'pharmacy') {
            return redirect('/pharmacy/dashboard');
        } elseif ($role === 'admin') {
            return redirect('/admin/dashboard');
        }
        return redirect()->route('staff.login');
    }

    public function waiting()
    {
        $user = Auth::user();
        if (!$user) {
            return redirect()->route('staff.login');
        }

        if ($user->status === 'approved') {
            return $this->redirectBasedOnRole($user->role);
        }

        return view('auth.waiting');
    }

    public function status()
    {
        $user = Auth::user();
        if (!$user) {
            return response()->json(['status' => 'unauthenticated'], 401);
        }

        return response()->json(['status' => $user->status]);
    }
}
