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

        $tests = $query->latest()->get();

        return view('lab.tests.index', compact('tests', 'type'));
    }

    public function create()
    {
        return view('lab.tests.create');
    }

    public function store(Request $request)
    {
        $lab = Auth::user()->lab;
        
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'type' => 'required|string|in:blood,urine,hormone,other',
            'price' => 'required|numeric|min:0',
            'description' => 'nullable|string',
            'is_active' => 'boolean',
        ]);

        $validated['lab_id'] = $lab->id;
        $validated['is_active'] = $request->has('is_active');

        LabTest::create($validated);

        return redirect()->route('lab.tests.index')->with('success', 'Test created successfully.');
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

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'type' => 'required|string|in:blood,urine,hormone,other',
            'price' => 'required|numeric|min:0',
            'description' => 'nullable|string',
        ]);

        $validated['is_active'] = $request->has('is_active');
        $test->update($validated);

        return redirect()->route('lab.tests.index')->with('success', 'Test updated successfully.');
    }

    public function destroy(LabTest $test)
    {
        if ($test->lab_id !== Auth::user()->lab->id) {
            abort(403);
        }

        $test->delete();

        return redirect()->route('lab.tests.index')->with('success', 'Test deleted successfully.');
    }
}
