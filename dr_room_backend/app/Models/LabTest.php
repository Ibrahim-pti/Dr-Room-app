<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LabTest extends Model
{
    protected $fillable = [
        'lab_id',
        'name',
        'name_en',
        'name_ar',
        'type',
        'price',
        'discount',
        'description',
        'description_ar',
        'description_en',
        'is_active',
    ];

    protected $casts = [
        'price' => 'decimal:2',
        'is_active' => 'boolean',
    ];

    public function lab()
    {
        return $this->belongsTo(Lab::class);
    }
}
