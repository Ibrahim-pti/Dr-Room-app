<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Medication;
use App\Models\MedicationCategory;
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
        $categories = MedicationCategory::where('is_active', true)->where('name', '!=', 'هەمووی')->orderBy('sort_order')->get();
        return view('pharmacy.medications.create', compact('categories'));
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'category' => 'nullable|string|max:255',
            'description' => 'nullable|string',
            'price' => 'required|numeric|min:0',
            'original_price' => 'nullable|numeric|min:0',
            'discount_percent' => 'nullable|integer|min:0|max:100',
            'badge' => 'nullable|string|max:100',
            'dosage_form' => 'nullable|string|max:100',
            'stock' => 'required|integer|min:0',
            'requires_prescription' => 'nullable|boolean',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif,webp|max:2048',
        ]);

        $data = $request->except(['image', 'requires_prescription', 'is_active']);
        $data['user_id'] = Auth::id();
        $data['requires_prescription'] = $request->has('requires_prescription');
        $data['is_active'] = $request->has('is_active') ? true : true;

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
        
        $categories = MedicationCategory::where('is_active', true)->where('name', '!=', 'هەمووی')->orderBy('sort_order')->get();
        return view('pharmacy.medications.edit', compact('medication', 'categories'));
    }

    public function update(Request $request, Medication $medication)
    {
        if ($medication->user_id !== Auth::id()) abort(403);

        $request->validate([
            'name' => 'required|string|max:255',
            'category' => 'nullable|string|max:255',
            'description' => 'nullable|string',
            'price' => 'required|numeric|min:0',
            'original_price' => 'nullable|numeric|min:0',
            'discount_percent' => 'nullable|integer|min:0|max:100',
            'badge' => 'nullable|string|max:100',
            'dosage_form' => 'nullable|string|max:100',
            'stock' => 'required|integer|min:0',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif,webp|max:2048',
        ]);

        $data = $request->except(['image', 'requires_prescription', 'is_active']);
        $data['requires_prescription'] = $request->has('requires_prescription');
        $data['is_active'] = $request->has('is_active');

        if ($request->hasFile('image')) {
            // Delete old image if exists
            if ($medication->image_path && !str_starts_with($medication->image_path, 'http')) {
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

        if ($medication->image_path && !str_starts_with($medication->image_path, 'http')) {
            Storage::disk('public')->delete($medication->image_path);
        }

        $medication->delete();

        return redirect()->route('pharmacy.medications.index')->with('success', 'دەرمانەکە سڕدرایەوە.');
    }
}
