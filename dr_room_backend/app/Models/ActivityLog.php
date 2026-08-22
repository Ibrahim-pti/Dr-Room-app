<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Auth;

class ActivityLog extends Model
{
    protected $guarded = [];

    protected $casts = [
        'changes' => 'array',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Record one staff action. The actor's name and role are copied in so the
     * trail survives the account being deleted later.
     */
    public static function record(
        string $action,
        ?Model $subject = null,
        ?string $label = null,
        ?array $changes = null
    ): ?self {
        $user = Auth::user();

        return self::create([
            'user_id'       => $user?->id,
            'user_name'     => $user?->name,
            'user_role'     => $user?->role,
            'action'        => $action,
            'subject_type'  => $subject ? get_class($subject) : null,
            'subject_id'    => $subject?->getKey(),
            'subject_label' => $label,
            'changes'       => $changes,
            'ip_address'    => request()->ip(),
        ]);
    }
}
