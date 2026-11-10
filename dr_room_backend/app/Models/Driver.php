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

    /**
     * Keep driver duty_status accurate ('busy' if active orders remain, otherwise
     * 'available') without forcing an offline driver online.
     */
    public static function syncDutyStatusForUser(?int $driverUserId): void
    {
        if (!$driverUserId) {
            return;
        }

        $driver = self::where('user_id', $driverUserId)->first();
        if (!$driver || $driver->duty_status === 'offline') {
            return;
        }

        $activeCount = Order::where('assigned_driver_id', $driverUserId)
            ->whereNotIn('status', ['completed', 'cancelled'])
            ->whereIn('delivery_status', ['accepted', 'picked_up', 'on_the_way', 'arrived'])
            ->count();

        $nextDuty = $activeCount > 0 ? 'busy' : 'available';
        if ($driver->duty_status !== $nextDuty) {
            $driver->update(['duty_status' => $nextDuty]);
        }
    }
}

