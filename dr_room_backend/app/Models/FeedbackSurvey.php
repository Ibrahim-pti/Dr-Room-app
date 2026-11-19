<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FeedbackSurvey extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'title_kmr',
        'title_ar',
        'title_en',
        'rating_question',
        'rating_question_kmr',
        'rating_question_ar',
        'rating_question_en',
        'suggestion_question',
        'suggestion_question_kmr',
        'suggestion_question_ar',
        'suggestion_question_en',
        'is_active',
        'created_by',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function responses()
    {
        return $this->hasMany(FeedbackResponse::class, 'survey_id');
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
