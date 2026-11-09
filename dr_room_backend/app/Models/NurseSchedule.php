<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class NurseSchedule extends Model
{
    use HasFactory;

    protected $fillable = [
        'nurse_id',
        'day_of_week',
        'start_time',
        'end_time',
        'is_available',
        'max_daily_visits',
    ];

    protected $casts = [
        'is_available' => 'boolean',
        'max_daily_visits' => 'integer',
    ];

    public function nurse()
    {
        return $this->belongsTo(Nurse::class);
    }
}
