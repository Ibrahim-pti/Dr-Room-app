<?php
namespace App\Http\Controllers\Web;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
class PharmacySettingsController extends Controller {
    public function index() { return view('pharmacy.settings.index'); }
    public function update(Request $request) {
        return back()->with('success', 'ڕێکخستنەکان پاشەکەوتکران.');
    }
}
