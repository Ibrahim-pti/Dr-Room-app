<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class NurseProfileController extends Controller
{
    public function index()
    {
        $user = Auth::user();
        $nurse = $user->nurse;
        return view('nurse.profile.index', compact('user', 'nurse'));
    }

    public function update(Request $request)
    {
        $user = Auth::user();
        $nurse = $user->nurse;

        $request->validate([
            'name' => 'required|string|max:255',
            'phone' => 'required|string|max:20',
            'specialty' => 'nullable|string|max:255',
            'bio' => 'nullable|string',
        ]);

        $user->update([
            'name' => $request->name,
            'phone' => $request->phone,
        ]);

        if ($nurse) {
            $updateData = [
                'specialty' => $request->specialty,
                'bio' => $request->bio,
            ];

            try {
                $tr = new \Stichoza\GoogleTranslate\GoogleTranslate();
                if ($request->specialty) {
                    $updateData['specialty_en'] = $tr->setTarget('en')->translate($request->specialty);
                    $updateData['specialty_ar'] = $tr->setTarget('ar')->translate($request->specialty);
                }
                if ($request->bio) {
                    $updateData['bio_en'] = $tr->setTarget('en')->translate($request->bio);
                    $updateData['bio_ar'] = $tr->setTarget('ar')->translate($request->bio);
                }
            } catch (\Exception $e) {
                \Illuminate\Support\Facades\Log::error('Translation failed: ' . $e->getMessage());
            }

            $nurse->update($updateData);
        }

        return back()->with('success', 'زانیارییەکانی پڕۆفایل نوێکرانەوە.');
    }
}
