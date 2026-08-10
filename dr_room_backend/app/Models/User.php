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

#[Fillable(['name', 'name_en', 'name_ar', 'email', 'phone', 'password', 'role', 'status', 'otp_code', 'otp_expires_at'])]
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
        ];
    }

    public function getIsAdminAttribute(): bool
    {
        return $this->role === 'admin';
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
