<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class NurseScheduleController extends Controller
{
    public function index()
    {
        $nurse = Auth::user()->nurse;
        // Assume schedule logic here. For now just passing nurse object.
        return view('nurse.schedule.index', compact('nurse'));
    }
}
