<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LabReview extends Model
{
    protected $fillable = [
        'lab_id',
        'patient_id',
        'rating',
        'comment',
    ];

    protected $casts = [
        'rating' => 'integer',
    ];

    public function lab()
    {
        return $this->belongsTo(Lab::class);
    }

    public function patient()
    {
        return $this->belongsTo(User::class, 'patient_id');
    }
}
