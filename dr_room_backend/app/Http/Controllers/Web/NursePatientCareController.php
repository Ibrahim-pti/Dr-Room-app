<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\NursePatientCare;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class NursePatientCareController extends Controller
{
    public function index()
    {
        $nurse = Auth::user()->nurse;
        $cares = NursePatientCare::where('nurse_id', $nurse->id)->latest()->get();
        return view('nurse.patient_cares.index', compact('cares'));
    }

    public function create()
    {
        return view('nurse.patient_cares.create');
    }

    public function store(Request $request)
    {
        $nurse = Auth::user()->nurse;
        $validated = $request->validate([
            'patient_id' => 'required|exists:users,id',
            'symptoms' => 'nullable|string',
            'notes' => 'nullable|string',
            'medication_given' => 'nullable|string',
            'date' => 'required|date',
        ]);

        $validated['nurse_id'] = $nurse->id;
        
        // Handle vitals as json
        $vitals = [];
        if ($request->blood_pressure) $vitals['blood_pressure'] = $request->blood_pressure;
        if ($request->heart_rate) $vitals['heart_rate'] = $request->heart_rate;
        if ($request->temperature) $vitals['temperature'] = $request->temperature;
        
        $validated['vitals'] = $vitals;

        NursePatientCare::create($validated);
        
        return redirect()->route('nurse.patient_cares.index')->with('success', 'Care record added successfully.');
    }

    public function edit(NursePatientCare $care)
    {
        if ($care->nurse_id !== Auth::user()->nurse->id) { abort(403); }
        return view('nurse.patient_cares.edit', compact('care'));
    }

    public function update(Request $request, NursePatientCare $care)
    {
        if ($care->nurse_id !== Auth::user()->nurse->id) { abort(403); }

        $validated = $request->validate([
            'symptoms' => 'nullable|string',
            'notes' => 'nullable|string',
            'medication_given' => 'nullable|string',
            'date' => 'required|date',
        ]);

        $vitals = $care->vitals ?? [];
        if ($request->has('blood_pressure')) $vitals['blood_pressure'] = $request->blood_pressure;
        if ($request->has('heart_rate')) $vitals['heart_rate'] = $request->heart_rate;
        if ($request->has('temperature')) $vitals['temperature'] = $request->temperature;
        
        $validated['vitals'] = $vitals;

        $care->update($validated);
        
        return redirect()->route('nurse.patient_cares.index')->with('success', 'Care record updated successfully.');
    }

    public function destroy(NursePatientCare $care)
    {
        if ($care->nurse_id !== Auth::user()->nurse->id) { abort(403); }
        $care->delete();
        return redirect()->route('nurse.patient_cares.index')->with('success', 'Care record deleted successfully.');
    }
}
