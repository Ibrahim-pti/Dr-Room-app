<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LabResult extends Model
{
    protected $fillable = [
        'lab_id',
        'patient_id',
        'test_id',
        'result_value',
        'status',
        'file_path',
        'notes',
    ];

    public function lab()
    {
        return $this->belongsTo(Lab::class);
    }

    public function patient()
    {
        return $this->belongsTo(User::class, 'patient_id');
    }

    public function test()
    {
        return $this->belongsTo(LabTest::class, 'test_id');
    }
}
