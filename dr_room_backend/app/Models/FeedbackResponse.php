<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FeedbackResponse extends Model
{
    use HasFactory;

    protected $fillable = [
        'survey_id',
        'user_id',
        'rating',
        'is_satisfied',
        'suggestion',
        'locale',
    ];

    protected $casts = [
        'rating' => 'integer',
    ];

    public function survey()
    {
        return $this->belongsTo(FeedbackSurvey::class, 'survey_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
