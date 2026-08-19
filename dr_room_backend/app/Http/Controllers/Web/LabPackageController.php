<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\LabPackage;
use App\Models\LabTest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class LabPackageController extends Controller
{
    public function index()
    {
        $lab = Auth::user()->lab;
        if (!$lab) {
            return redirect()->route('lab.profile.index')->with('error', 'تکایە سەرەتا پرۆفایلی تاقیگەکەت تەواو بکە.');
        }

        $packages = $lab->packages()->latest()->paginate(10);

        return view('lab.packages.index', compact('packages'));
    }

    public function create()
    {
        $lab = Auth::user()->lab;
        if (!$lab) {
            return redirect()->route('lab.profile.index')->with('error', 'تکایە سەرەتا پرۆفایلی تاقیگەکەت تەواو بکە.');
        }

        $tests = $lab->tests()->where('is_active', true)->get();

        return view('lab.packages.create', compact('tests'));
    }

    public function store(Request $request)
    {
        $lab = Auth::user()->lab;
        if (!$lab) {
            abort(403);
        }

        if ($request->has('price')) {
            $request->merge(['price' => str_replace(',', '', (string)$request->input('price'))]);
        }
        if ($request->has('original_price')) {
            $request->merge(['original_price' => str_replace(',', '', (string)$request->input('original_price'))]);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'name_en' => 'nullable|string|max:255',
            'name_ar' => 'nullable|string|max:255',
            'description' => 'nullable|string',
            'description_ar' => 'nullable|string',
            'description_en' => 'nullable|string',
            'price' => 'required|numeric|min:0',
            'original_price' => 'nullable|numeric|min:0',
            'discount' => 'nullable|integer|min:0|max:100',
            'test_ids' => 'nullable|array',
            'test_ids.*' => 'integer|exists:lab_tests,id',
            'is_active' => 'boolean',
        ]);

        $validated['lab_id'] = $lab->id;
        $validated['is_active'] = $request->has('is_active');

        // Auto calculate discount percentage if original_price is provided
        if (!empty($validated['original_price']) && $validated['original_price'] > $validated['price']) {
            $diff = $validated['original_price'] - $validated['price'];
            $validated['discount'] = round(($diff / $validated['original_price']) * 100);
        }

        LabPackage::create($validated);

        return redirect()->route('lab.packages.index')->with('success', 'پاکێجی نوێ بە سەرکەوتوویی زیادکرا.');
    }

    public function edit(LabPackage $package)
    {
        if ($package->lab_id !== Auth::user()->lab->id) {
            abort(403);
        }

        $lab = Auth::user()->lab;
        $tests = $lab->tests()->get();

        return view('lab.packages.edit', compact('package', 'tests'));
    }

    public function update(Request $request, LabPackage $package)
    {
        if ($package->lab_id !== Auth::user()->lab->id) {
            abort(403);
        }

        if ($request->has('price')) {
            $request->merge(['price' => str_replace(',', '', (string)$request->input('price'))]);
        }
        if ($request->has('original_price')) {
            $request->merge(['original_price' => str_replace(',', '', (string)$request->input('original_price'))]);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'name_en' => 'nullable|string|max:255',
            'name_ar' => 'nullable|string|max:255',
            'description' => 'nullable|string',
            'description_ar' => 'nullable|string',
            'description_en' => 'nullable|string',
            'price' => 'required|numeric|min:0',
            'original_price' => 'nullable|numeric|min:0',
            'discount' => 'nullable|integer|min:0|max:100',
            'test_ids' => 'nullable|array',
            'test_ids.*' => 'integer|exists:lab_tests,id',
        ]);

        $validated['is_active'] = $request->has('is_active');

        if (!empty($validated['original_price']) && $validated['original_price'] > $validated['price']) {
            $diff = $validated['original_price'] - $validated['price'];
            $validated['discount'] = round(($diff / $validated['original_price']) * 100);
        }

        $package->update($validated);

        return redirect()->route('lab.packages.index')->with('success', 'پاکێجەکە بە سەرکەوتوویی نوێکرایەوە.');
    }

    public function destroy(LabPackage $package)
    {
        if ($package->lab_id !== Auth::user()->lab->id) {
            abort(403);
        }

        $package->delete();

        return redirect()->route('lab.packages.index')->with('success', 'پاکێجەکە بە سەرکەوتوویی سڕایەوە.');
    }
}
