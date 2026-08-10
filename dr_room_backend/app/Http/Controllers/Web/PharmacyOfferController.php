<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\PharmacyOffer;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;

class PharmacyOfferController extends Controller
{
    public function index()
    {
        $offers = PharmacyOffer::where('user_id', Auth::id())->latest()->paginate(10);
        return view('pharmacy.offers.index', compact('offers'));
    }

    public function create()
    {
        return view('pharmacy.offers.create');
    }

    public function store(Request $request)
    {
        $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'discount_percentage' => 'required|numeric|min:0|max:100',
            'image' => 'nullable|image|max:2048',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date|after_or_equal:start_date',
        ]);

        $data = $request->except('image');
        $data['user_id'] = Auth::id();
        $data['is_active'] = $request->has('is_active');

        if ($request->hasFile('image')) {
            $data['image_path'] = $request->file('image')->store('offers', 'public');
        }

        PharmacyOffer::create($data);

        return redirect()->route('pharmacy.offers.index')->with('success', 'ئۆفەرەکە بە سەرکەوتوویی زیادکرا.');
    }

    public function edit(PharmacyOffer $offer)
    {
        if ($offer->user_id !== Auth::id()) abort(403);
        return view('pharmacy.offers.edit', compact('offer'));
    }

    public function update(Request $request, PharmacyOffer $offer)
    {
        if ($offer->user_id !== Auth::id()) abort(403);

        $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'discount_percentage' => 'required|numeric|min:0|max:100',
            'image' => 'nullable|image|max:2048',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date|after_or_equal:start_date',
        ]);

        $data = $request->except('image');
        $data['is_active'] = $request->has('is_active');

        if ($request->hasFile('image')) {
            if ($offer->image_path) Storage::disk('public')->delete($offer->image_path);
            $data['image_path'] = $request->file('image')->store('offers', 'public');
        }

        $offer->update($data);

        return redirect()->route('pharmacy.offers.index')->with('success', 'ئۆفەرەکە نوێکرایەوە.');
    }

    public function destroy(PharmacyOffer $offer)
    {
        if ($offer->user_id !== Auth::id()) abort(403);
        
        if ($offer->image_path) Storage::disk('public')->delete($offer->image_path);
        
        $offer->delete();

        return redirect()->route('pharmacy.offers.index')->with('success', 'ئۆفەرەکە سڕدرایەوە.');
    }
}
