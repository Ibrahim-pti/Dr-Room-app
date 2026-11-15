<?php

namespace App\Models;

use App\Models\Concerns\LogsActivity;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

class RecruitmentOption extends Model
{
    use LogsActivity;

    public const TYPE_EDUCATION = 'education';
    public const TYPE_SKILL = 'skill';

    protected $guarded = [];

    protected $casts = [
        'sort_order' => 'integer',
        'is_active'  => 'boolean',
    ];

    public function labelForLocale(string $locale): string
    {
        $col = match ($locale) {
            'kmr' => 'label_kmr',
            'ar'  => 'label_ar',
            'en'  => 'label_en',
            default => 'label_ckb',
        };

        $val = trim((string) ($this->{$col} ?? ''));
        if ($val !== '') {
            return $val;
        }

        foreach (['label_ckb', 'label_en', 'label_ar', 'label_kmr'] as $fallbackCol) {
            $fb = trim((string) ($this->{$fallbackCol} ?? ''));
            if ($fb !== '') {
                return $fb;
            }
        }

        return (string) $this->option_key;
    }

    /**
     * Return [option_key => localized_label] for active options of the given type.
     * Falls back to static translation files if the table has not been migrated yet.
     */
    public static function optionsMapForLocale(string $type, string $locale = 'ckb'): array
    {
        if (!Schema::hasTable('recruitment_options')) {
            $langKey = $type === self::TYPE_EDUCATION ? 'delivery.education_options' : 'delivery.skills_options';
            $fallback = __($langKey);
            return is_array($fallback) ? $fallback : [];
        }

        return static::query()
            ->where('type', $type)
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->orderBy('id')
            ->get()
            ->mapWithKeys(fn (self $opt) => [$opt->option_key => $opt->labelForLocale($locale)])
            ->all();
    }

    /**
     * Return [option_key => localized_label] including inactive entries (for historical profiles).
     */
    public static function allLabelsByKey(string $type, string $locale = 'ckb'): array
    {
        if (!Schema::hasTable('recruitment_options')) {
            $langKey = $type === self::TYPE_EDUCATION ? 'delivery.education_options' : 'delivery.skills_options';
            $fallback = __($langKey);
            return is_array($fallback) ? $fallback : [];
        }

        return static::query()
            ->where('type', $type)
            ->orderBy('sort_order')
            ->orderBy('id')
            ->get()
            ->mapWithKeys(fn (self $opt) => [$opt->option_key => $opt->labelForLocale($locale)])
            ->all();
    }

    public static function generateUniqueKey(string $type, ?string $preferred, string $fallbackText): string
    {
        $base = Str::slug((string) ($preferred ?: $fallbackText), '_');
        if ($base === '') {
            $base = 'opt_' . substr(md5($fallbackText . microtime(true)), 0, 8);
        }
        $base = Str::limit($base, 65, '');

        $candidate = $base;
        $suffix = 2;
        while (static::where('type', $type)->where('option_key', $candidate)->exists()) {
            $candidate = Str::limit($base, 60, '') . '_' . $suffix;
            $suffix++;
        }

        return $candidate;
    }
}
