<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Nurse extends Model
{
    protected $guarded = [];

    protected $casts = [
        'is_approved' => 'boolean',
        'is_available' => 'boolean',
        'offered_services' => 'array',
        'fee' => 'decimal:2',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function nurseAppointments()
    {
        return $this->hasMany(NurseAppointment::class);
    }
}
