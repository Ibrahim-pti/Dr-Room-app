<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\LabTest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class LabTestController extends Controller
{
    public function index(Request $request)
    {
        $lab = Auth::user()->lab;
        $type = $request->get('type');

        $query = LabTest::where('lab_id', $lab->id);
        
        if ($type) {
            $query->where('type', $type);
        }

        $tests = $query->latest()->paginate(10)->withQueryString();

        return view('lab.tests.index', compact('tests', 'type'));
    }

    public function create()
    {
        return view('lab.tests.create');
    }

    public function store(Request $request)
    {
        $lab = Auth::user()->lab;
        
        if ($request->has('price')) {
            $request->merge(['price' => str_replace(',', '', (string)$request->input('price'))]);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'name_en' => 'nullable|string|max:255',
            'name_ar' => 'nullable|string|max:255',
            'name_kmr' => 'nullable|string|max:255',
            'type' => 'nullable|string|max:255',
            'price' => 'required|numeric|min:0',
            'discount' => 'nullable|integer|min:0|max:100',
            'description' => 'nullable|string',
            'description_ar' => 'nullable|string',
            'description_en' => 'nullable|string',
            'description_kmr' => 'nullable|string',
            'is_active' => 'boolean',
        ]);

        $validated['lab_id'] = $lab->id;
        $validated['type'] = $request->input('type') ?? 'general';
        $validated['is_active'] = $request->has('is_active');

        if (empty($validated['name_kmr']) && !empty($validated['name'])) {
            try {
                $validated['name_kmr'] = \App\Services\TranslationService::translate($validated['name'], 'ku');
            } catch (\Exception $e) {}
        }
        if (empty($validated['description_kmr']) && !empty($validated['description'])) {
            try {
                $validated['description_kmr'] = \App\Services\TranslationService::translate($validated['description'], 'ku');
            } catch (\Exception $e) {}
        }

        LabTest::create($validated);

        return redirect()->route('lab.tests.index')->with('success', 'پشکنین بە سەرکەوتوویی زیادکرا.');
    }

    public function edit(LabTest $test)
    {
        if ($test->lab_id !== Auth::user()->lab->id) {
            abort(403);
        }
        
        return view('lab.tests.edit', compact('test'));
    }

    public function update(Request $request, LabTest $test)
    {
        if ($test->lab_id !== Auth::user()->lab->id) {
            abort(403);
        }

        if ($request->has('price')) {
            $request->merge(['price' => str_replace(',', '', (string)$request->input('price'))]);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'name_en' => 'nullable|string|max:255',
            'name_ar' => 'nullable|string|max:255',
            'name_kmr' => 'nullable|string|max:255',
            'type' => 'nullable|string|max:255',
            'price' => 'required|numeric|min:0',
            'discount' => 'nullable|integer|min:0|max:100',
            'description' => 'nullable|string',
            'description_ar' => 'nullable|string',
            'description_en' => 'nullable|string',
            'description_kmr' => 'nullable|string',
        ]);

        if (empty($validated['name_kmr']) && !empty($validated['name'])) {
            try {
                $validated['name_kmr'] = \App\Services\TranslationService::translate($validated['name'], 'ku');
            } catch (\Exception $e) {}
        }
        if (empty($validated['description_kmr']) && !empty($validated['description'])) {
            try {
                $validated['description_kmr'] = \App\Services\TranslationService::translate($validated['description'], 'ku');
            } catch (\Exception $e) {}
        }

        $validated['type'] = $request->input('type') ?? $test->type ?? 'general';
        $validated['is_active'] = $request->has('is_active');
        $test->update($validated);

        return redirect()->route('lab.tests.index')->with('success', 'پشکنین بە سەرکەوتوویی نوێکرایەوە.');
    }

    public function destroy(LabTest $test)
    {
        if ($test->lab_id !== Auth::user()->lab->id) {
            abort(403);
        }

        $test->delete();

        return redirect()->route('lab.tests.index')->with('success', 'پشکنین بە سەرکەوتوویی سڕایەوە.');
    }
}
