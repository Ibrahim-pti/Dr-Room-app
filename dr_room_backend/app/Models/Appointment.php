<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Appointment extends Model
{
    protected $fillable = [
        'doctor_id',
        'patient_id',
        'appointment_date',
        'status',
        'type',
        'notes',
        'fee',
    ];

    protected $casts = [
        'appointment_date' => 'datetime',
        'fee' => 'decimal:2',
    ];

    /** The doctor this appointment belongs to */
    public function doctor()
    {
        return $this->belongsTo(Doctor::class);
    }

    /** The patient (User) who booked this appointment */
    public function patient()
    {
        return $this->belongsTo(User::class, 'patient_id');
    }

    /** Scope: only today's appointments */
    public function scopeToday($query)
    {
        return $query->whereDate('appointment_date', today());
    }

    /** Scope: upcoming (not cancelled/completed) */
    public function scopeUpcoming($query)
    {
        return $query->whereIn('status', ['pending', 'confirmed'])
                     ->where('appointment_date', '>=', now());
    }
}
