<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\User;

class DoctorPatientController extends Controller
{
    public function index()
    {
        $doctor = Auth::user()->doctor;
        // Get patients who have appointments with this doctor
        $patients = User::whereHas('appointments', function($q) use ($doctor) {
            $q->where('doctor_id', $doctor->id);
        })
        ->withCount(['appointments as total_visits' => function($q) use ($doctor) {
            $q->where('doctor_id', $doctor->id);
        }])
        ->with(['appointments' => function($q) use ($doctor) {
            $q->where('doctor_id', $doctor->id)->orderBy('appointment_date', 'desc')->take(1);
        }])
        ->paginate(15);

        return view('doctor.patients.index', compact('patients'));
    }
}
