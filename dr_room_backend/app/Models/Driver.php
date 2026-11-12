<?php

namespace App\Models;

use App\Models\Concerns\LogsActivity;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Driver extends Model
{
    use HasFactory, LogsActivity;

    protected $guarded = [];

    protected $casts = [
        'current_lat' => 'float',
        'current_lng' => 'float',
        'last_location_at' => 'datetime',
        'completed_deliveries' => 'integer',
        'total_earnings' => 'float',
        'rating' => 'float',
        'experience_years' => 'integer',
        'clinical_skills' => 'array',
        'willing_to_travel' => 'boolean',
        'has_private_car' => 'boolean',
    ];

    /**
     * Extract normalized field-care profile merging dedicated columns with legacy JSON notes fallback.
     */
    public function resolvedFieldProfile(): array
    {
        $decodedNotes = [];
        if (is_string($this->notes) && str_starts_with(trim($this->notes), '{')) {
            $parsed = json_decode($this->notes, true);
            if (is_array($parsed)) {
                $decodedNotes = $parsed['field_profile'] ?? $parsed;
            }
        }

        $skills = $this->clinical_skills;
        if (empty($skills) && !empty($decodedNotes['clinical_skills']) && is_array($decodedNotes['clinical_skills'])) {
            $skills = $decodedNotes['clinical_skills'];
        }

        $toStorageUrl = static function (?string $path): ?string {
            if (!$path) {
                return null;
            }
            if (str_starts_with($path, 'http')) {
                return $path;
            }
            return asset('storage/' . ltrim($path, '/'));
        };

        $idPath = $this->id_document_path ?? ($decodedNotes['id_document_path'] ?? null);
        $certPath = $this->certificate_path ?? ($decodedNotes['certificate_path'] ?? null);
        $licPath = $this->license_path ?? ($decodedNotes['license_path'] ?? null);
        $cvPath = $this->cv_path ?? ($decodedNotes['cv_path'] ?? null);

        return [
            'applicant_role' => $this->applicant_role ?? ($decodedNotes['applicant_role'] ?? 'phlebotomist'),
            'gender' => $this->gender ?? ($decodedNotes['gender'] ?? null),
            'education_level' => $this->education_level ?? ($decodedNotes['education_level'] ?? null),
            'experience_years' => $this->experience_years ?? ($decodedNotes['experience_years'] ?? null),
            'clinical_skills' => is_array($skills) ? array_values($skills) : [],
            'service_areas' => $this->service_areas ?? ($decodedNotes['service_areas'] ?? null),
            'availability_shift' => $this->availability_shift ?? ($decodedNotes['availability_shift'] ?? null),
            'work_days' => $this->work_days ?? ($decodedNotes['work_days'] ?? null),
            'willing_to_travel' => $this->willing_to_travel ?? ($decodedNotes['willing_to_travel'] ?? true),
            'has_private_car' => $this->has_private_car ?? ($decodedNotes['has_private_car'] ?? false),
            'id_document_url' => $toStorageUrl($idPath),
            'certificate_url' => $toStorageUrl($certPath),
            'license_url' => $toStorageUrl($licPath),
            'cv_url' => $toStorageUrl($cvPath),
        ];
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Keep driver duty_status accurate ('busy' if active orders remain, otherwise
     * 'available') without forcing an offline driver online.
     */
    public static function syncDutyStatusForUser(?int $driverUserId): void
    {
        if (!$driverUserId) {
            return;
        }

        $driver = self::where('user_id', $driverUserId)->first();
        if (!$driver || $driver->duty_status === 'offline') {
            return;
        }

        $activeCount = Order::where('assigned_driver_id', $driverUserId)
            ->whereNotIn('status', ['completed', 'cancelled'])
            ->whereIn('delivery_status', ['accepted', 'picked_up', 'on_the_way', 'arrived'])
            ->count();

        $nextDuty = $activeCount > 0 ? 'busy' : 'available';
        if ($driver->duty_status !== $nextDuty) {
            $driver->update(['duty_status' => $nextDuty]);
        }
    }
}

