<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
// use App\Models\Prescription; // Assuming the model exists or will be fleshed out
use Illuminate\Support\Facades\Auth;

class PharmacyPrescriptionController extends Controller
{
    public function index()
    {
        // For now, this is a placeholder since the prescriptions table is empty
        // In the future, this would fetch prescriptions assigned to this pharmacy or pending global ones
        $prescriptions = collect([]); 
        
        return view('pharmacy.prescriptions.index', compact('prescriptions'));
    }

    public function dispense(Request $request, $id)
    {
        // Logic to mark prescription as dispensed
        return back()->with('success', 'ڕەچەتەکە بە سەرکەوتوویی ئامادەکرا.');
    }
}
