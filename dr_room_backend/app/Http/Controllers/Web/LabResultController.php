<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\LabResult;
use App\Models\LabTest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class LabResultController extends Controller
{
    public function index()
    {
        $lab = Auth::user()->lab;
        $results = LabResult::where('lab_id', $lab->id)->latest()->get();
        return view('lab.results.index', compact('results'));
    }

    public function create()
    {
        $lab = Auth::user()->lab;
        $tests = LabTest::where('lab_id', $lab->id)->where('is_active', true)->get();
        // Assume patient logic is handled or selected via UI.
        return view('lab.results.create', compact('tests'));
    }

    public function store(Request $request)
    {
        $lab = Auth::user()->lab;
        $validated = $request->validate([
            'patient_id' => 'required|exists:users,id',
            'test_id' => 'required|exists:lab_tests,id',
            'result_value' => 'nullable|string',
            'status' => 'required|string|in:pending,completed',
            'file' => 'nullable|file|mimes:pdf,jpg,png|max:2048',
            'notes' => 'nullable|string',
        ]);

        $validated['lab_id'] = $lab->id;

        if ($request->hasFile('file')) {
            $validated['file_path'] = $request->file('file')->store('lab_results', 'public');
        }

        LabResult::create($validated);
        return redirect()->route('lab.results.index')->with('success', 'Result added successfully.');
    }

    public function edit(LabResult $result)
    {
        $lab = Auth::user()->lab;
        if ($result->lab_id !== $lab->id) { abort(403); }
        $tests = LabTest::where('lab_id', $lab->id)->where('is_active', true)->get();
        return view('lab.results.edit', compact('result', 'tests'));
    }

    public function update(Request $request, LabResult $result)
    {
        if ($result->lab_id !== Auth::user()->lab->id) { abort(403); }

        $validated = $request->validate([
            'test_id' => 'required|exists:lab_tests,id',
            'result_value' => 'nullable|string',
            'status' => 'required|string|in:pending,completed',
            'file' => 'nullable|file|mimes:pdf,jpg,png|max:2048',
            'notes' => 'nullable|string',
        ]);

        if ($request->hasFile('file')) {
            $validated['file_path'] = $request->file('file')->store('lab_results', 'public');
        }

        $result->update($validated);
        return redirect()->route('lab.results.index')->with('success', 'Result updated successfully.');
    }
}
