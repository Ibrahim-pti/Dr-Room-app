<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Lab extends Model
{
    protected $guarded = [];

    protected $casts = [
        'available_days' => 'array',
        'rating' => 'decimal:1',
        'is_approved' => 'boolean',
        'home_sample_collection' => 'boolean',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function tests()
    {
        return $this->hasMany(LabTest::class);
    }

    public function packages()
    {
        return $this->hasMany(LabPackage::class);
    }

    public function reviews()
    {
        return $this->hasMany(LabReview::class);
    }

    public function recalculateRating()
    {
        $avg = $this->reviews()->avg('rating');
        $count = $this->reviews()->count();

        $this->update([
            'rating' => $avg ? round($avg, 1) : 5.0,
            'total_reviews' => $count,
        ]);
    }
}
