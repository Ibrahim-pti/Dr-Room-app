<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AppSetting extends Model
{
    use HasFactory;

    protected $fillable = [
        'key',
        'value',
        'group',
        'description',
    ];

    public static function get(string $key, $default = null)
    {
        $setting = static::where('key', $key)->first();
        if (!$setting) return $default;
        
        $val = $setting->value;
        $decoded = json_decode($val, true);
        return (json_last_error() === JSON_ERROR_NONE) ? $decoded : $val;
    }

    public static function set(string $key, $value, string $group = 'general', ?string $description = null): self
    {
        $encoded = is_array($value) || is_object($value) ? json_encode($value) : (string) $value;
        return static::updateOrCreate(
            ['key' => $key],
            ['value' => $encoded, 'group' => $group, 'description' => $description]
        );
    }
}
