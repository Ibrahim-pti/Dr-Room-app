<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Article extends Model
{
    protected $guarded = [];

    protected $casts = [
        'is_published' => 'boolean',
        'symptoms' => 'array',
        'steps' => 'array',
        'dos' => 'array',
        'donts' => 'array',
    ];
}
