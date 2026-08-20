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
        'custom_services' => 'array',
        'fee' => 'decimal:2',
        'latitude' => 'float',
        'longitude' => 'float',
        'rating' => 'decimal:1',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function nurseAppointments()
    {
        return $this->hasMany(NurseAppointment::class);
    }

    /** Patient reviews left for this nurse */
    public function reviews()
    {
        return $this->hasMany(NurseReview::class);
    }

    /**
     * Recalculates the cached `rating` / `total_reviews` columns from the
     * reviews table. Call after any review is created, changed or removed.
     */
    public function refreshRating(): void
    {
        $this->update([
            'rating' => round((float) $this->reviews()->avg('rating'), 1),
            'total_reviews' => $this->reviews()->count(),
        ]);
    }
}

