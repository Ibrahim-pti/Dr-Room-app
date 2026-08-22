<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Pharmacy extends Model
{
    protected $guarded = [];

    protected $casts = [
        'available_days' => 'array',
        'gallery_images' => 'array',
        'rating' => 'decimal:1',
        'delivery_fee' => 'decimal:2',
        'is_approved' => 'boolean',
        'is_open' => 'boolean',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
