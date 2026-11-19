<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ProviderSchedule extends Model
{
    protected $fillable = [
        'user_id',
        'provider_type',
        'day_of_week',
        'start_time',
        'end_time',
        'is_available',
        'slot_minutes',
        'slot_capacity',
        'max_daily_orders',
    ];

    protected $casts = [
        'is_available' => 'boolean',
        'slot_minutes' => 'integer',
        'slot_capacity' => 'integer',
        'max_daily_orders' => 'integer',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
