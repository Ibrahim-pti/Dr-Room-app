<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Medication;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Storage;

class PharmacyMedicationController extends Controller
{
    public function index()
    {
        $medications = Medication::where('user_id', Auth::id())->latest()->paginate(10);
        return view('pharmacy.medications.index', compact('medications'));
    }

    public function create()
    {
        return view('pharmacy.medications.create');
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'price' => 'required|numeric|min:0',
            'stock' => 'required|integer|min:0',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
        ]);

        $data = $request->except('image');
        $data['user_id'] = Auth::id();

        if ($request->hasFile('image')) {
            $path = $request->file('image')->store('medications', 'public');
            $data['image_path'] = $path;
        }

        Medication::create($data);

        return redirect()->route('pharmacy.medications.index')->with('success', 'دەرمانەکە بە سەرکەوتوویی زیادکرا.');
    }

    public function edit(Medication $medication)
    {
        if ($medication->user_id !== Auth::id()) abort(403);
        
        return view('pharmacy.medications.edit', compact('medication'));
    }

    public function update(Request $request, Medication $medication)
    {
        if ($medication->user_id !== Auth::id()) abort(403);

        $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'price' => 'required|numeric|min:0',
            'stock' => 'required|integer|min:0',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
        ]);

        $data = $request->except('image');

        if ($request->hasFile('image')) {
            // Delete old image if exists
            if ($medication->image_path) {
                Storage::disk('public')->delete($medication->image_path);
            }
            $path = $request->file('image')->store('medications', 'public');
            $data['image_path'] = $path;
        }

        $medication->update($data);

        return redirect()->route('pharmacy.medications.index')->with('success', 'دەرمانەکە بە سەرکەوتوویی تازەکرایەوە.');
    }

    public function destroy(Medication $medication)
    {
        if ($medication->user_id !== Auth::id()) abort(403);

        if ($medication->image_path) {
            Storage::disk('public')->delete($medication->image_path);
        }

        $medication->delete();

        return redirect()->route('pharmacy.medications.index')->with('success', 'دەرمانەکە سڕدرایەوە.');
    }
}
