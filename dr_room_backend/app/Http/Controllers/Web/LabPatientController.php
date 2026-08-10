<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\User;

class LabPatientController extends Controller
{
    public function index()
    {
        $patients = User::where('role', 'patient')->paginate(10);
        return view('lab.patients.index', compact('patients'));
    }
}
