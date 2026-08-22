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

#[Fillable(['name', 'name_en', 'name_ar', 'email', 'phone', 'password', 'role', 'status', 'profile_image', 'otp_code', 'otp_expires_at', 'permissions', 'last_login_at'])]
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
}
