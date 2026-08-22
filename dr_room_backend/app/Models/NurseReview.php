<?php

namespace App\Models;

use App\Models\Concerns\HidesModeratedReviews;

use Illuminate\Database\Eloquent\Model;

class NurseReview extends Model
{
    use HidesModeratedReviews;

    protected $guarded = [];

    protected $casts = [
        'rating' => 'integer',
            'is_hidden' => 'boolean',
        'hidden_at' => 'datetime',
    ];

    public function nurse()
    {
        return $this->belongsTo(Nurse::class);
    }

    public function patient()
    {
        return $this->belongsTo(User::class, 'patient_id');
    }
}
