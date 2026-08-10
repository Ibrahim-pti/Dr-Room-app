<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\LabResult;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class LabManagementController extends Controller
{
    public function approve()
    {
        $lab = Auth::user()->lab;
        $results = LabResult::where('lab_id', $lab->id)->where('status', 'pending')->latest()->get();
        return view('lab.management.approve', compact('results'));
    }

    public function complete()
    {
        $lab = Auth::user()->lab;
        $results = LabResult::where('lab_id', $lab->id)->where('status', 'completed')->latest()->get();
        return view('lab.management.complete', compact('results'));
    }

    public function updateStatus(Request $request, LabResult $result)
    {
        if ($result->lab_id !== Auth::user()->lab->id) { abort(403); }

        $validated = $request->validate([
            'status' => 'required|string|in:pending,completed',
        ]);

        $result->update(['status' => $validated['status']]);
        
        return back()->with('success', 'Status updated successfully.');
    }
}
