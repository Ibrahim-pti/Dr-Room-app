<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LabPackage extends Model
{
    protected $fillable = [
        'lab_id',
        'name',
        'name_ar',
        'name_en',
        'description',
        'description_ar',
        'description_en',
        'price',
        'original_price',
        'discount',
        'test_ids',
        'is_active',
    ];

    protected $casts = [
        'price' => 'decimal:2',
        'original_price' => 'decimal:2',
        'discount' => 'integer',
        'test_ids' => 'array',
        'is_active' => 'boolean',
    ];

    public function lab()
    {
        return $this->belongsTo(Lab::class);
    }

    public function getTestsAttribute()
    {
        if (empty($this->test_ids) || !is_array($this->test_ids)) {
            return collect();
        }
        return LabTest::whereIn('id', $this->test_ids)->get();
    }
}
