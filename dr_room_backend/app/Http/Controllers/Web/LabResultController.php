<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\LabResult;
use App\Models\LabTest;
use App\Models\Order;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class LabResultController extends Controller
{
    public function index()
    {
        $lab = Auth::user()->lab;
        $results = LabResult::where('lab_id', $lab->id)->with(['patient', 'test'])->latest()->paginate(15);
        return view('lab.results.index', compact('results'));
    }

    public function create(Request $request)
    {
        $lab = Auth::user()->lab;
        $tests = LabTest::where('lab_id', $lab->id)->where('is_active', true)->get();
        $patients = User::where('role', 'patient')->get();
        
        $selectedOrderId = $request->get('order_id');
        $selectedPatientId = $request->get('patient_id');
        $order = null;

        if ($selectedOrderId) {
            $order = Order::with(['items', 'patient'])->find($selectedOrderId);
            if ($order && !$selectedPatientId) {
                $selectedPatientId = $order->patient_id ?? $order->user_id;
            }
        }

        return view('lab.results.create', compact('tests', 'patients', 'selectedPatientId', 'selectedOrderId', 'order'));
    }

    public function store(Request $request)
    {
        $lab = Auth::user()->lab;
        $request->validate([
            'patient_id' => 'required|exists:users,id',
            'status' => 'required|string|in:pending,completed',
            'file' => 'nullable|file|mimes:pdf,jpg,jpeg,png|max:10240',
            'notes' => 'nullable|string',
        ]);

        $filePath = null;
        if ($request->hasFile('file')) {
            $filePath = $request->file('file')->store('lab_results', 'public');
        }

        $order = $request->order_id ? Order::with('items')->find($request->order_id) : null;

        // If multiple tests submitted from order items
        if ($request->has('test_results') && is_array($request->test_results)) {
            foreach ($request->test_results as $testId => $val) {
                LabResult::create([
                    'lab_id' => $lab->id,
                    'patient_id' => $request->patient_id,
                    'test_id' => $testId,
                    'result_value' => $val,
                    'status' => $request->status,
                    'file_path' => $filePath,
                    'notes' => $request->notes,
                ]);
            }
        } elseif ($request->filled('test_id')) {
            // Single test selection
            LabResult::create([
                'lab_id' => $lab->id,
                'patient_id' => $request->patient_id,
                'test_id' => $request->test_id,
                'result_value' => $request->result_value,
                'status' => $request->status,
                'file_path' => $filePath,
                'notes' => $request->notes,
            ]);
        } else {
            // General lab result attached to first available test or null
            $firstTest = LabTest::where('lab_id', $lab->id)->first();
            LabResult::create([
                'lab_id' => $lab->id,
                'patient_id' => $request->patient_id,
                'test_id' => $firstTest?->id,
                'result_value' => $request->result_value ?? 'تەواوکراو',
                'status' => $request->status,
                'file_path' => $filePath,
                'notes' => $request->notes,
            ]);
        }

        // If linked to an order, automatically mark order as completed if status is completed
        if ($order && $request->status === 'completed') {
            $order->update(['status' => 'completed']);
        }

        return redirect()->route('lab.patients.index')->with('success', 'ئەنجامی پشکنین بە سەرکەوتوویی تۆمارکرا و ڕاستەوخۆ بۆ نەخۆش نێردرا.');
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
            'file' => 'nullable|file|mimes:pdf,jpg,jpeg,png|max:10240',
            'notes' => 'nullable|string',
        ]);

        if ($request->hasFile('file')) {
            $validated['file_path'] = $request->file('file')->store('lab_results', 'public');
        }

        $result->update($validated);
        return redirect()->route('lab.results.index')->with('success', 'ئەنجام نوێکرایەوە.');
    }

    public function destroy(LabResult $result)
    {
        if ($result->lab_id !== Auth::user()->lab->id) { abort(403); }
        $result->delete();
        return redirect()->route('lab.results.index')->with('success', 'ئەنجام سڕایەوە.');
    }
}
