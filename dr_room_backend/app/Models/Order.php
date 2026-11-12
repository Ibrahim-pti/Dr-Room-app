<?php

namespace App\Models;

use App\Models\Concerns\LogsActivity;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Order extends Model
{
    use HasFactory, LogsActivity;

    protected $guarded = [];

    public const LAB_SERVICE_TYPES = [
        'lab', 'Lab', 'lab_test', 'Lab Tests', 'Lab Test', 'تاقیگە',
    ];

    public const NURSING_SERVICE_TYPES = [
        'nursing', 'Nursing', 'Nursing Services', 'home_nursing', 'Home Nursing', 'nurse', 'nursing_care',
    ];

    public const PHARMACY_SERVICE_TYPES = [
        'pharmacy', 'Pharmacy', 'medication', 'medications', 'دەرمان', 'دەرمانخانە',
    ];

    protected $casts = [
        'patient_details' => 'array',
        'location_details' => 'array',
        'driver_assigned_at' => 'datetime',
        'driver_picked_up_at' => 'datetime',
        'driver_delivered_at' => 'datetime',
        'delivery_fee' => 'float',
    ];

    public function patient()
    {
        return $this->belongsTo(User::class, 'patient_id');
    }

    public function items()
    {
        return $this->hasMany(OrderItem::class);
    }

    public function assignedNurse()
    {
        return $this->belongsTo(User::class, 'assigned_nurse_id');
    }

    public function assignedPharmacy()
    {
        return $this->belongsTo(User::class, 'assigned_pharmacy_id');
    }

    public function assignedLab()
    {
        return $this->belongsTo(User::class, 'assigned_lab_id');
    }

    public function assignedDriver()
    {
        return $this->belongsTo(User::class, 'assigned_driver_id');
    }

    /**
     * Normalize patient delivery/pickup address & GPS coordinates across
     * pharmacy orders (location_details.address_text) and lab/nursing orders
     * (patient_details.location + patient_details.lat/lng).
     */
    public function resolvePatientLocation(): array
    {
        $patientDetails = is_array($this->patient_details)
            ? $this->patient_details
            : (json_decode((string) $this->patient_details, true) ?: []);
        $locationDetails = is_array($this->location_details)
            ? $this->location_details
            : (json_decode((string) $this->location_details, true) ?: []);

        $pickFirstText = static function (array $candidates): string {
            foreach ($candidates as $val) {
                $str = trim((string) ($val ?? ''));
                if ($str !== '' && $str !== 'ناونیشان دیاری نەکراوە') {
                    return $str;
                }
            }
            return '';
        };

        $address = $pickFirstText([
            $locationDetails['address'] ?? null,
            $locationDetails['address_text'] ?? null,
            $locationDetails['full_address'] ?? null,
            $locationDetails['location'] ?? null,
            $patientDetails['address'] ?? null,
            $patientDetails['address_text'] ?? null,
            $patientDetails['location'] ?? null,
            $locationDetails['city'] ?? null,
            $patientDetails['city'] ?? null,
        ]);

        $rawLat = $locationDetails['latitude']
            ?? $locationDetails['lat']
            ?? $patientDetails['latitude']
            ?? $patientDetails['lat']
            ?? null;
        $rawLng = $locationDetails['longitude']
            ?? $locationDetails['lng']
            ?? $patientDetails['longitude']
            ?? $patientDetails['lng']
            ?? null;

        $lat = is_numeric($rawLat) ? (float) $rawLat : null;
        $lng = is_numeric($rawLng) ? (float) $rawLng : null;

        $notes = $pickFirstText([
            $locationDetails['instructions'] ?? null,
            $patientDetails['notes'] ?? null,
            $patientDetails['note'] ?? null,
        ]);

        return [
            'address' => $address,
            'lat'     => $lat,
            'lng'     => $lng,
            'notes'   => $notes,
        ];
    }

    /**
     * Delivery drivers handle Pharmacy medication deliveries and unassigned home/work
     * Lab sample transport — NOT nursing visits, doctor appointments, in-person lab
     * visits, or lab bookings where a dedicated phlebotomist/nurse is already assigned.
     */
    public function needsDeliveryDriver(): bool
    {
        $serviceType = strtolower(trim((string) $this->service_type));

        if (str_contains($serviceType, 'pharmac') || str_contains($serviceType, 'medic') || str_contains($serviceType, 'دەرمان')) {
            return true;
        }

        if (str_contains($serviceType, 'lab') || str_contains($serviceType, 'تاقیگە')) {
            if (!empty($this->assigned_nurse_id)) {
                return false;
            }

            $patientDetails = is_array($this->patient_details)
                ? $this->patient_details
                : (json_decode((string) $this->patient_details, true) ?: []);
            $method = strtolower(trim((string) ($patientDetails['collection_method'] ?? '')));

            return $method !== 'lab' && $method !== 'visit_lab';
        }

        return false;
    }

    /**
     * Resolve effective courier payout fee while respecting free-delivery pharmacy orders.
     */
    public function resolveDeliveryFee(): float
    {
        if ((float) ($this->delivery_fee ?? 0) > 0) {
            return (float) $this->delivery_fee;
        }

        if ((float) ($this->extra_fee ?? 0) > 0) {
            return (float) $this->extra_fee;
        }

        $serviceType = strtolower((string) $this->service_type);
        if (str_contains($serviceType, 'pharmac') || str_contains($serviceType, 'medic')) {
            return 0.0;
        }

        return 2500.0;
    }

    public function scopeForLab($query)
    {
        return $query->where(function ($q) {
            $q->whereIn('service_type', self::LAB_SERVICE_TYPES)
              ->orWhere('service_type', 'like', '%lab%')
              ->orWhere('service_type', 'like', '%تاقیگە%');
        });
    }

    public function scopeForNursing($query)
    {
        return $query->where(function ($q) {
            $q->whereIn('service_type', self::NURSING_SERVICE_TYPES)
              ->orWhere('service_type', 'like', '%nurs%');
        });
    }

    public function scopeForPharmacy($query)
    {
        return $query->where(function ($q) {
            $q->whereIn('service_type', self::PHARMACY_SERVICE_TYPES)
              ->orWhere('service_type', 'like', '%pharmac%')
              ->orWhere('service_type', 'like', '%medic%')
              ->orWhere('service_type', 'like', '%دەرمان%');
        });
    }

    public function isLabService(): bool
    {
        $st = strtolower(trim((string) $this->service_type));
        return str_contains($st, 'lab') || str_contains($st, 'تاقیگە');
    }

    public function isNursingService(): bool
    {
        $st = strtolower(trim((string) $this->service_type));
        return str_contains($st, 'nurs');
    }

    public function isPharmacyService(): bool
    {
        $st = strtolower(trim((string) $this->service_type));
        return str_contains($st, 'pharmac') || str_contains($st, 'medic') || str_contains($st, 'دەرمان');
    }

    /**
     * Mark an order completed, settle pending cash/online transactions,
     * and award patient loyalty points once (idempotent).
     */
    public function markCompletedWithFinancials(): void
    {
        $this->status = 'completed';
        $this->payment_status = 'paid';

        Transaction::where('payable_type', self::class)
            ->where('payable_id', $this->id)
            ->where('status', 'pending')
            ->update([
                'status' => 'completed',
                'paid_at' => now(),
            ]);

        if (($this->loyalty_points_earned ?? 0) <= 0 && $this->patient) {
            $enabled = AppSetting::get('loyalty_enabled', true);
            if ($enabled) {
                $ptsPer1000 = (float) AppSetting::get('loyalty_points_per_1000_iqd', 1);
                $earned = (int) floor(($this->total_price / 1000) * $ptsPer1000);
                if ($earned > 0) {
                    $this->loyalty_points_earned = $earned;
                    $this->patient->increment('loyalty_points', $earned);
                    LoyaltyTransaction::create([
                        'user_id' => $this->patient_id,
                        'points' => $earned,
                        'type' => 'earned_order',
                        'description' => "پاداشتی خاڵەکان بۆ داواکاری #{$this->id}",
                        'order_id' => $this->id,
                    ]);
                }
            }
        }

        $this->save();
    }
}
