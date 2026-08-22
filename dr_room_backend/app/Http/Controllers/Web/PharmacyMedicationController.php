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
        $existingCategories = Medication::where('user_id', Auth::id())
            ->whereNotNull('category')
            ->where('category', '!=', '')
            ->distinct()
            ->pluck('category');
        return view('pharmacy.medications.create', compact('existingCategories'));
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'name_ar' => 'nullable|string|max:255',
            'name_en' => 'nullable|string|max:255',
            'category' => 'nullable|string|max:255',
            'category_ar' => 'nullable|string|max:255',
            'category_en' => 'nullable|string|max:255',
            'description' => 'nullable|string',
            'description_ar' => 'nullable|string',
            'description_en' => 'nullable|string',
            'price' => 'required|numeric|min:0',
            'original_price' => 'nullable|numeric|min:0',
            'discount_percent' => 'nullable|integer|min:0|max:100',
            'dosage_form' => 'nullable|string|max:100',
            'stock' => 'required|integer|min:0',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif,webp|max:4096',
        ]);

        $data = $request->except(['image', 'is_active']);
        $data['user_id'] = Auth::id();
        $data['category'] = trim($request->category ?? '');
        $data['category_ar'] = trim($request->category_ar ?? '');
        $data['category_en'] = trim($request->category_en ?? '');
        $data['is_active'] = $request->has('is_active') ? true : true;

        $price = floatval($request->price ?? 0);
        $originalPrice = !empty($request->original_price) ? floatval($request->original_price) : null;
        $discountPercent = !empty($request->discount_percent) ? intval($request->discount_percent) : null;

        if ($originalPrice && $originalPrice > $price) {
            $data['original_price'] = $originalPrice;
            $data['price'] = $price;
            $data['discount_percent'] = round((($originalPrice - $price) / $originalPrice) * 100);
        } elseif ($discountPercent && $discountPercent > 0) {
            $data['original_price'] = $price;
            $data['discount_percent'] = $discountPercent;
            $data['price'] = round($price * (1 - ($discountPercent / 100)));
        } else {
            $data['original_price'] = null;
            $data['discount_percent'] = null;
            $data['price'] = $price;
        }

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
        
        $existingCategories = Medication::where('user_id', Auth::id())
            ->whereNotNull('category')
            ->where('category', '!=', '')
            ->distinct()
            ->pluck('category');
        return view('pharmacy.medications.edit', compact('medication', 'existingCategories'));
    }

    public function update(Request $request, Medication $medication)
    {
        if ($medication->user_id !== Auth::id()) abort(403);

        $request->validate([
            'name' => 'required|string|max:255',
            'name_ar' => 'nullable|string|max:255',
            'name_en' => 'nullable|string|max:255',
            'category' => 'nullable|string|max:255',
            'category_ar' => 'nullable|string|max:255',
            'category_en' => 'nullable|string|max:255',
            'description' => 'nullable|string',
            'description_ar' => 'nullable|string',
            'description_en' => 'nullable|string',
            'price' => 'required|numeric|min:0',
            'original_price' => 'nullable|numeric|min:0',
            'discount_percent' => 'nullable|integer|min:0|max:100',
            'dosage_form' => 'nullable|string|max:100',
            'stock' => 'required|integer|min:0',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif,webp|max:4096',
        ]);

        $data = $request->except(['image', 'is_active']);
        $data['category'] = trim($request->category ?? '');
        $data['category_ar'] = trim($request->category_ar ?? '');
        $data['category_en'] = trim($request->category_en ?? '');
        $data['is_active'] = $request->has('is_active');

        $price = floatval($request->price ?? 0);
        $originalPrice = !empty($request->original_price) ? floatval($request->original_price) : null;
        $discountPercent = !empty($request->discount_percent) ? intval($request->discount_percent) : null;

        if ($originalPrice && $originalPrice > $price) {
            $data['original_price'] = $originalPrice;
            $data['price'] = $price;
            $data['discount_percent'] = round((($originalPrice - $price) / $originalPrice) * 100);
        } elseif ($discountPercent && $discountPercent > 0) {
            $data['original_price'] = $price;
            $data['discount_percent'] = $discountPercent;
            $data['price'] = round($price * (1 - ($discountPercent / 100)));
        } else {
            $data['original_price'] = null;
            $data['discount_percent'] = null;
            $data['price'] = $price;
        }

        if ($request->hasFile('image')) {
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
