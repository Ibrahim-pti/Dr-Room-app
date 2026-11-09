<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PatientEmrRecord extends Model
{
    use HasFactory;

    protected $fillable = [
        'patient_id',
        'blood_type',
        'chronic_diseases',
        'allergies',
        'current_medications',
        'past_surgeries',
        'emergency_notes',
        'height_cm',
        'weight_kg',
        'last_updated_by',
    ];

    protected $casts = [
        'chronic_diseases' => 'array',
        'allergies' => 'array',
        'current_medications' => 'array',
        'past_surgeries' => 'array',
        'height_cm' => 'decimal:2',
        'weight_kg' => 'decimal:2',
    ];

    public function patient()
    {
        return $this->belongsTo(User::class, 'patient_id');
    }

    public function lastUpdatedBy()
    {
        return $this->belongsTo(User::class, 'last_updated_by');
    }
}
