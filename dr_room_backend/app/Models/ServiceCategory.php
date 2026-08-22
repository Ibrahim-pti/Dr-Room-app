<?php

namespace App\Models;

use App\Models\Concerns\LogsActivity;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class ServiceCategory extends Model
{
    use LogsActivity;

    protected $guarded = [];

    protected $casts = [
        'is_active'  => 'boolean',
        'sort_order' => 'integer',
    ];

    /** Every list the admin app can manage, with its Kurdish label. */
    public const SCOPES = [
        'nursing'   => 'خزمەتگوزاری پەرستاری',
        'lab'       => 'پشکنینەکانی تاقیگە',
        'pharmacy'  => 'بەشەکانی دەرمانخانە',
        'doctor'    => 'پسپۆڕی پزیشکان',
        'xray'      => 'خزمەتگوزاری تیشک',
        'first_aid' => 'کەتەگۆری فریاگوزاری',
    ];

    protected static function booted(): void
    {
        static::saving(function (self $category) {
            if (blank($category->slug)) {
                $category->slug = Str::slug($category->name_en ?: $category->name, '-') ?: null;
            }
        });
    }

    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopeOfScope($query, string $scope)
    {
        return $query->where('scope', $scope);
    }
}
