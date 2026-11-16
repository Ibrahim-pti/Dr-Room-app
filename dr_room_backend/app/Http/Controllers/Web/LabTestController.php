<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\LabTest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class LabTestController extends Controller
{
    public const DEFAULT_LAB_CATEGORIES = [
        'پشکنینی خوێن',
        'بایۆکیمیستری و چەوری',
        'هۆرمۆنات',
        'ڤیتامین و کانزاکان',
        'میز و پیسایی',
        'بەکتریا و چاندن',
        'بەرگری و ڤایرۆس',
        'گورچیلە و جگەر',
        'شەکرە',
        'پشکنینی گشتی',
    ];

    protected function categoriesForLab(int $labId): array
    {
        $saved = LabTest::where('lab_id', $labId)
            ->whereNotNull('type')
            ->where('type', '!=', '')
            ->where('type', '!=', 'general')
            ->distinct()
            ->pluck('type')
            ->map(fn ($v) => trim((string) $v))
            ->filter();

        return collect(self::DEFAULT_LAB_CATEGORIES)
            ->merge($saved)
            ->unique()
            ->values()
            ->all();
    }

    protected function resolveCategoryType(Request $request, ?string $fallback = null): string
    {
        $selected = trim((string) $request->input('type', ''));
        $custom = trim((string) $request->input('custom_type', ''));

        if ($selected === '__custom__') {
            return $custom !== '' ? $custom : ($fallback ?: 'پشکنینی گشتی');
        }

        if ($selected !== '') {
            return $selected;
        }

        return $fallback ?: 'پشکنینی گشتی';
    }

    public function index(Request $request)
    {
        $lab = Auth::user()->lab;
        $type = $request->get('type');
        $labCategories = $this->categoriesForLab($lab->id);

        $query = LabTest::where('lab_id', $lab->id);
        
        if ($type) {
            $query->where('type', $type);
        }

        $tests = $query->latest()->paginate(10)->withQueryString();

        return view('lab.tests.index', compact('tests', 'type', 'labCategories'));
    }

    public function create()
    {
        $lab = Auth::user()->lab;
        $labCategories = $this->categoriesForLab($lab->id);

        return view('lab.tests.create', compact('labCategories'));
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
            'custom_type' => 'nullable|string|max:255',
            'price' => 'required|numeric|min:0',
            'discount' => 'nullable|integer|min:0|max:100',
            'description' => 'nullable|string',
            'description_ar' => 'nullable|string',
            'description_en' => 'nullable|string',
            'description_kmr' => 'nullable|string',
            'is_active' => 'boolean',
        ]);

        unset($validated['custom_type']);
        $validated['lab_id'] = $lab->id;
        $validated['type'] = $this->resolveCategoryType($request);
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

        $labCategories = $this->categoriesForLab(Auth::user()->lab->id);

        return view('lab.tests.edit', compact('test', 'labCategories'));
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
            'custom_type' => 'nullable|string|max:255',
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

        unset($validated['custom_type']);
        $validated['type'] = $this->resolveCategoryType($request, $test->type);
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
