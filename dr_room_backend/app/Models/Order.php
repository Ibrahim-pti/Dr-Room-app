<?php

namespace App\Models;

use App\Models\Concerns\LogsActivity;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Order extends Model
{
    use HasFactory, LogsActivity;

    protected $guarded = [];

    protected $casts = [
        'patient_details' => 'array',
        'location_details' => 'array',
    ];

    public function patient()
    {
        return $this->belongsTo(User::class, 'patient_id');
    }

    public function items()
    {
        return $this->hasMany(OrderItem::class);
    }

    public function assignedNurse()
    {
        return $this->belongsTo(User::class, 'assigned_nurse_id');
    }

    public function assignedPharmacy()
    {
        return $this->belongsTo(User::class, 'assigned_pharmacy_id');
    }

    public function assignedLab()
    {
        return $this->belongsTo(User::class, 'assigned_lab_id');
    }
}
