<?php
namespace App\Http\Controllers\Web;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
class PharmacyProfileController extends Controller {
    public function index() { $user = Auth::user(); return view('pharmacy.profile.index', compact('user')); }
    public function update(Request $request) {
        $request->validate(['name' => 'required', 'phone' => 'required']);
        $user = Auth::user(); $user->update($request->only('name', 'phone'));
        return back()->with('success', 'پرۆفایل بە سەرکەوتوویی تازەکرایەوە.');
    }
}
