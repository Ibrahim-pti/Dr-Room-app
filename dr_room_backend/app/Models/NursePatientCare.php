<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class NursePatientCare extends Model
{
    protected $fillable = [
        'nurse_id',
        'patient_id',
        'appointment_id',
        'symptoms',
        'vitals',
        'notes',
        'medication_given',
        'date',
    ];

    protected $casts = [
        'vitals' => 'array',
        'date' => 'date',
    ];

    public function nurse()
    {
        return $this->belongsTo(Nurse::class);
    }

    public function patient()
    {
        return $this->belongsTo(User::class, 'patient_id');
    }

    public function appointment()
    {
        return $this->belongsTo(NurseAppointment::class, 'appointment_id');
    }
}
