<?php

namespace App\Models\Concerns;

use Illuminate\Database\Eloquent\Builder;

/**
 * A review hidden by a moderator drops out of every public listing, rating
 * average and star breakdown by default. The admin moderation screen opts
 * back in with `withoutGlobalScope('visible')`.
 */
trait HidesModeratedReviews
{
    public static function bootHidesModeratedReviews(): void
    {
        static::addGlobalScope('visible', function (Builder $query) {
            $query->where($query->getModel()->getTable() . '.is_hidden', false);
        });
    }
}
