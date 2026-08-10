<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use App\Models\User;
use App\Models\Doctor;
use App\Models\Nurse;

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
        $credentials = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required'],
        ]);

        if (Auth::attempt($credentials)) {
            $user = Auth::user();
            
            if ($user->status === 'pending') {
                return redirect()->route('staff.waiting');
            }
            
            if ($user->status === 'blocked') {
                Auth::logout();
                return back()->withErrors([
                    'email' => 'هەژمارەکەت بلۆک کراوە.',
                ]);
            }
            
            if (in_array($user->role, ['doctor', 'nurse', 'lab', 'pharmacy'])) {
                $request->session()->regenerate();
                return $this->redirectBasedOnRole($user->role);
            } else {
                Auth::logout();
                return back()->withErrors([
                    'email' => 'تۆ دەسەڵاتی ستافت نییە بۆ چوونەژوورەوە لێرە.',
                ]);
            }
        }

        return back()->withErrors([
            'email' => 'زانیارییەکان هەڵەن یان بوونیان نییە.',
        ])->onlyInput('email');
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
            'email' => ['required', 'string', 'email', 'max:255', 'unique:users'],
            'phone' => ['required', 'string', 'max:20', 'unique:users'],
            'password' => ['required', 'string', 'min:6', 'confirmed'],
            'role' => ['required', 'string', 'in:doctor,nurse,lab,pharmacy'],
        ]);

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'phone' => $request->phone,
            'password' => Hash::make($request->password),
            'role' => $request->role,
            'status' => 'pending',
        ]);

        Auth::login($user);
        return redirect()->route('staff.waiting');
    }

    public function logout(Request $request)
    {
        Auth::logout();
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
