<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DoctorService extends Model
{
    protected $guarded = [];

    protected $casts = [
        'discount_until' => 'date',
        'is_active' => 'boolean',
    ];

    /** Sent to the app so it never has to work the discount out itself. */
    protected $appends = ['has_discount', 'discount_percent'];

    public function doctor()
    {
        return $this->belongsTo(Doctor::class);
    }

    /**
     * A discount counts only while `old_price` is genuinely higher and the
     * offer has not expired. An empty `discount_until` means it never expires.
     */
    public function getHasDiscountAttribute(): bool
    {
        if (! $this->old_price || $this->old_price <= $this->price) {
            return false;
        }

        return ! $this->discount_until
            || $this->discount_until->endOfDay()->isFuture();
    }

    public function getDiscountPercentAttribute(): ?int
    {
        if (! $this->has_discount) {
            return null;
        }

        return (int) round((($this->old_price - $this->price) / $this->old_price) * 100);
    }

    /** Offers that ran out, so the dashboard can flag them. */
    public function getDiscountExpiredAttribute(): bool
    {
        return $this->old_price
            && $this->old_price > $this->price
            && $this->discount_until
            && $this->discount_until->endOfDay()->isPast();
    }

    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }
}
