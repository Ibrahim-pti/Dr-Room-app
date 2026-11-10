<?php

namespace App\Models;

use App\Models\Concerns\LogsActivity;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Driver extends Model
{
    use HasFactory, LogsActivity;

    protected $guarded = [];

    protected $casts = [
        'current_lat' => 'float',
        'current_lng' => 'float',
        'last_location_at' => 'datetime',
        'completed_deliveries' => 'integer',
        'total_earnings' => 'float',
        'rating' => 'float',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
