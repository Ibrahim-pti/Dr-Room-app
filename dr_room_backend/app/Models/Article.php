<?php

namespace App\Models;

use App\Models\Concerns\LogsActivity;

use Illuminate\Database\Eloquent\Model;

class Article extends Model
{
    use LogsActivity;

    protected $guarded = [];

    protected $casts = [
        'is_published' => 'boolean',
        'symptoms' => 'array',
        'steps' => 'array',
        'dos' => 'array',
        'donts' => 'array',
    ];
}
