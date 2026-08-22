<?php

namespace App\Models\Concerns;

use App\Models\ActivityLog;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Auth;

/**
 * Drop this on any model an admin edits and every create/update/delete lands
 * in the audit trail automatically — no call needed at each write site.
 */
trait LogsActivity
{
    public static function bootLogsActivity(): void
    {
        static::created(fn (Model $m) => self::writeLog('created', $m));

        static::updated(function (Model $m) {
            $changes = collect($m->getChanges())
                ->except(['updated_at', 'password', 'remember_token', 'otp_code'])
                ->toArray();

            if ($changes === []) {
                return;
            }

            self::writeLog('updated', $m, ['changed' => array_keys($changes)]);
        });

        static::deleted(fn (Model $m) => self::writeLog('deleted', $m));
    }

    private static function writeLog(string $action, Model $model, ?array $extra = null): void
    {
        // Only staff actions are worth a trail; a patient editing their own
        // profile is not an admin event.
        if (!Auth::check() || !Auth::user()->is_staff) {
            return;
        }

        ActivityLog::record($action, $model, $model->activityLabel(), $extra);
    }

    /** Override in the model for something more useful than the class name. */
    public function activityLabel(): string
    {
        $name = $this->name ?? $this->title ?? null;
        $short = class_basename($this);

        return $name ? "{$short}: {$name}" : "{$short} #{$this->getKey()}";
    }
}
