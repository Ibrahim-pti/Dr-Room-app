<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

#[Fillable(['name', 'name_en', 'name_ar', 'name_kmr', 'email', 'phone', 'password', 'role', 'status', 'profile_image', 'otp_code', 'otp_expires_at', 'permissions', 'last_login_at'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasFactory, Notifiable, HasApiTokens;

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'permissions' => 'array',
            'last_login_at' => 'datetime',
        ];
    }

    protected $appends = ['avatar_url'];

    public function getAvatarUrlAttribute(): ?string
    {
        $raw = $this->profile_image;
        if (!$raw && $this->relationLoaded('nurse') && $this->nurse) {
            $raw = $this->nurse->image_path;
        } elseif (!$raw && $this->relationLoaded('doctor') && $this->doctor) {
            $raw = $this->doctor->image_path;
        } elseif (!$raw && $this->relationLoaded('lab') && $this->lab) {
            $raw = $this->lab->image_path;
        } elseif (!$raw && $this->relationLoaded('pharmacy') && $this->pharmacy) {
            $raw = $this->pharmacy->image_path;
        }

        if (empty($raw)) return null;
        if (str_starts_with($raw, 'http://') || str_starts_with($raw, 'https://')) {
            return $raw;
        }
        $clean = ltrim($raw, '/');
        if (str_starts_with($clean, 'storage/')) {
            return asset($clean);
        }
        return asset('storage/' . $clean);
    }

    public function getIsAdminAttribute(): bool
    {
        return $this->role === 'admin';
    }

    /** Anyone who may sign in to the admin dashboard, at any permission level. */
    public function getIsStaffAttribute(): bool
    {
        return in_array($this->role, \App\Support\Permissions::STAFF_ROLES, true);
    }

    /**
     * Effective permissions: the per-user override when one is set, otherwise
     * whatever the role grants by default. A main admin always has everything.
     */
    public function getPermissionListAttribute(): array
    {
        if ($this->role === 'admin') {
            return \App\Support\Permissions::ALL;
        }

        if (is_array($this->permissions) && $this->permissions !== []) {
            return array_values(array_intersect($this->permissions, \App\Support\Permissions::ALL));
        }

        return \App\Support\Permissions::defaultsFor($this->role);
    }

    public function hasPermission(string $permission): bool
    {
        return in_array($permission, $this->permission_list, true);
    }

    public function getIsDoctorAttribute(): bool
    {
        return $this->role === 'doctor';
    }

    public function getIsNurseAttribute(): bool
    {
        return $this->role === 'nurse';
    }

    public function getIsLabAttribute(): bool
    {
        return $this->role === 'lab';
    }

    public function getIsPharmacyAttribute(): bool
    {
        return $this->role === 'pharmacy';
    }

    public function getIsXrayAttribute(): bool
    {
        return $this->role === 'xray';
    }

    public function getIsBlockedAttribute(): bool
    {
        return $this->status === 'blocked';
    }

    public function doctor()
    {
        return $this->hasOne(Doctor::class);
    }

    public function nurse()
    {
        return $this->hasOne(Nurse::class);
    }

    public function appointments()
    {
        return $this->hasMany(Appointment::class, 'patient_id');
    }

    public function lab()
    {
        return $this->hasOne(Lab::class);
    }

    public function pharmacy()
    {
        return $this->hasOne(Pharmacy::class);
    }

    public function xray()
    {
        return $this->hasOne(XRay::class);
    }

    public function nurseAppointments()
    {
        return $this->hasMany(NurseAppointment::class, 'patient_id');
    }

    public function orders()
    {
        return $this->hasMany(Order::class, 'patient_id');
    }

    public function assignedNurseOrders()
    {
        return $this->hasMany(Order::class, 'assigned_nurse_id');
    }

    public function assignedPharmacyOrders()
    {
        return $this->hasMany(Order::class, 'assigned_pharmacy_id');
    }

    public function assignedLabOrders()
    {
        return $this->hasMany(Order::class, 'assigned_lab_id');
    }
}
