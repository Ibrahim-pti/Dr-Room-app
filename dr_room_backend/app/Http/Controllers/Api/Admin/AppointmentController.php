<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Appointment;

class AppointmentController extends Controller
{
    public function index()
    {
        return Appointment::latest()->get();
    }

    public function store(Request $request)
    {
        $request->validate([
            'patient_id' => 'required|exists:users,id',
            'doctor_id' => 'nullable|exists:doctors,id',
            'nurse_id' => 'nullable|exists:nurses,id',
            'appointment_date' => 'required|date',
            'status' => 'required|string',
            'notes' => 'nullable|string'
        ]);

        $appointment = Appointment::create($request->all());

        return response()->json($appointment, 201);
    }

    public function show(string $id)
    {
        return Appointment::findOrFail($id);
    }

    public function update(Request $request, string $id)
    {
        $appointment = Appointment::findOrFail($id);
        
        $request->validate([
            'patient_id' => 'nullable|exists:users,id',
            'doctor_id' => 'nullable|exists:doctors,id',
            'nurse_id' => 'nullable|exists:nurses,id',
            'appointment_date' => 'nullable|date',
            'status' => 'nullable|string',
            'notes' => 'nullable|string'
        ]);

        $appointment->update($request->all());

        return response()->json($appointment);
    }

    public function destroy(string $id)
    {
        $appointment = Appointment::findOrFail($id);
        $appointment->delete();

        return response()->json(null, 204);
    }
}
