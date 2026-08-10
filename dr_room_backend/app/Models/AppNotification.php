<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AppNotification extends Model
{
    use HasFactory;
    
    protected $fillable = ['title', 'title_en', 'title_ar', 'message', 'message_en', 'message_ar', 'type', 'user_id', 'is_read', 'image_path'];
    
    protected $casts = [
        'is_read' => 'boolean',
    ];
    
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
