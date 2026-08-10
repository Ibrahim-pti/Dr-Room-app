<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class XRay extends Model
{
    protected $guarded = [];

    protected $casts = [
        'available_days' => 'array',
        'rating' => 'decimal:1',
        'is_approved' => 'boolean',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
