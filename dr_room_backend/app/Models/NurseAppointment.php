<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class NurseAppointment extends Model
{
    protected $fillable = [
        'nurse_id',
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

    public function nurse()
    {
        return $this->belongsTo(Nurse::class);
    }

    public function patient()
    {
        return $this->belongsTo(User::class, 'patient_id');
    }

    public function scopeToday($query)
    {
        return $query->whereDate('appointment_date', today());
    }

    public function scopeUpcoming($query)
    {
        return $query->whereIn('status', ['pending', 'confirmed'])
                     ->where('appointment_date', '>=', now());
    }
}
