<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\User;

class NursePatientController extends Controller
{
    public function index()
    {
        $nurse = Auth::user()->nurse;
        // Get patients who have appointments with this nurse
        $patients = User::whereHas('nurseAppointments', function($q) use ($nurse) {
            $q->where('nurse_id', $nurse->id);
        })
        ->withCount(['nurseAppointments as total_visits' => function($q) use ($nurse) {
            $q->where('nurse_id', $nurse->id);
        }])
        ->with(['nurseAppointments' => function($q) use ($nurse) {
            $q->where('nurse_id', $nurse->id)->orderBy('appointment_date', 'desc')->take(1);
        }])
        ->paginate(15);

        return view('nurse.patients.index', compact('patients'));
    }
}
