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

    public function create(Request $request)
    {
        $lab = Auth::user()->lab;
        $tests = LabTest::where('lab_id', $lab->id)->where('is_active', true)->get();
        $patients = \App\Models\User::where('role', 'patient')->get();
        
        $selectedPatientId = $request->get('patient_id');
        $selectedTestId = $request->get('test_id');
        $selectedOrderId = $request->get('order_id');

        return view('lab.results.create', compact('tests', 'patients', 'selectedPatientId', 'selectedTestId', 'selectedOrderId'));
    }

    public function store(Request $request)
    {
        $lab = Auth::user()->lab;
        $validated = $request->validate([
            'patient_id' => 'required|exists:users,id',
            'test_id' => 'required|exists:lab_tests,id',
            'result_value' => 'nullable|string',
            'status' => 'required|string|in:pending,completed',
            'file' => 'nullable|file|mimes:pdf,jpg,jpeg,png|max:5120',
            'notes' => 'nullable|string',
        ]);

        $validated['lab_id'] = $lab->id;

        if ($request->hasFile('file')) {
            $validated['file_path'] = $request->file('file')->store('lab_results', 'public');
        }

        $result = LabResult::create($validated);

        // If an order ID was linked or patient has pending lab order, mark as completed if status is completed
        if ($request->order_id) {
            $order = \App\Models\Order::find($request->order_id);
            if ($order && $request->status === 'completed') {
                $order->update(['status' => 'completed']);
            }
        }

        return redirect()->route('lab.results.index')->with('success', 'ئەنجامی پشکنین بە سەرکەوتوویی تۆمارکرا و بۆ نەخۆش نێردرا.');
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
