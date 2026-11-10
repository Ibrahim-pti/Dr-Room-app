<?php

namespace App\Services;

use App\Models\Driver;
use App\Models\Order;
use App\Models\User;

class DriverDispatchService
{
    /**
     * Great-circle distance in kilometers between two GPS coordinates.
     */
    public static function distanceKm(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $earthRadiusKm = 6371.0;
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);

        $a = sin($dLat / 2) * sin($dLat / 2)
            + cos(deg2rad($lat1)) * cos(deg2rad($lat2))
            * sin($dLng / 2) * sin($dLng / 2);
        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return round($earthRadiusKm * $c, 2);
    }

    /**
     * Resolve origin coordinates (pickup pharmacy/lab first, falling back to patient coords).
     */
    public function resolveOrderOriginCoords(Order $order): array
    {
        $order->loadMissing(['assignedPharmacy.pharmacy', 'assignedLab.lab']);
        $serviceType = strtolower((string) $order->service_type);
        $lat = null;
        $lng = null;
        $city = '';

        if (str_contains($serviceType, 'lab') && $order->assignedLab?->lab) {
            $l = $order->assignedLab->lab;
            $lat = is_numeric($l->latitude) ? (float) $l->latitude : null;
            $lng = is_numeric($l->longitude) ? (float) $l->longitude : null;
            $city = (string) ($l->city ?? '');
        } elseif ($order->assignedPharmacy?->pharmacy) {
            $p = $order->assignedPharmacy->pharmacy;
            $lat = is_numeric($p->latitude) ? (float) $p->latitude : null;
            $lng = is_numeric($p->longitude) ? (float) $p->longitude : null;
            $city = (string) ($p->city ?? '');
        }

        $patientLoc = $order->resolvePatientLocation();
        if ($lat === null || $lng === null) {
            $lat = $patientLoc['lat'];
            $lng = $patientLoc['lng'];
        }

        return [
            'lat'  => $lat,
            'lng'  => $lng,
            'city' => trim($city),
        ];
    }

    /**
     * Compute distance (km) from a driver's current GPS to the order's pickup/origin point.
     */
    public function distanceForDriver(Order $order, ?Driver $driver): ?float
    {
        if (!$driver || $driver->current_lat === null || $driver->current_lng === null) {
            return null;
        }

        $origin = $this->resolveOrderOriginCoords($order);
        if ($origin['lat'] === null || $origin['lng'] === null) {
            return null;
        }

        return self::distanceKm(
            (float) $driver->current_lat,
            (float) $driver->current_lng,
            (float) $origin['lat'],
            (float) $origin['lng']
        );
    }

    /**
     * Track drivers who already rejected/declined an order so re-dispatch moves to the next nearest.
     */
    public function recordDeclinedDriver(Order $order, int $driverUserId): void
    {
        $loc = is_array($order->location_details)
            ? $order->location_details
            : (json_decode((string) $order->location_details, true) ?: []);

        $declined = array_map('intval', $loc['_declined_driver_ids'] ?? []);
        if (!in_array($driverUserId, $declined, true)) {
            $declined[] = $driverUserId;
        }
        $loc['_declined_driver_ids'] = array_values($declined);

        $order->location_details = $loc;
        $order->save();
    }

    public function getDeclinedDriverIds(Order $order): array
    {
        $loc = is_array($order->location_details)
            ? $order->location_details
            : (json_decode((string) $order->location_details, true) ?: []);

        return array_values(array_unique(array_map('intval', $loc['_declined_driver_ids'] ?? [])));
    }

    /**
     * Automatically dispatch a delivery-eligible order to the single nearest available
     * approved driver matching the service scope, without requiring admin approval.
     */
    public function dispatchNearest(Order $order, array $extraExcludeIds = []): ?User
    {
        if (!$order->needsDeliveryDriver()) {
            return null;
        }

        if (in_array($order->status, ['completed', 'cancelled'], true)) {
            return null;
        }

        $serviceType = strtolower((string) $order->service_type);
        $isLab = str_contains($serviceType, 'lab');
        $allowedScopes = $isLab ? ['lab_sample', 'both'] : ['pharmacy', 'both'];

        $excludedIds = array_values(array_unique(array_merge(
            $this->getDeclinedDriverIds($order),
            array_map('intval', $extraExcludeIds)
        )));

        $origin = $this->resolveOrderOriginCoords($order);

        $candidates = User::where('role', 'driver')
            ->where('status', 'approved')
            ->when(!empty($excludedIds), fn ($q) => $q->whereNotIn('id', $excludedIds))
            ->whereHas('driver', function ($q) use ($allowedScopes) {
                $q->where('duty_status', 'available')
                  ->whereIn('service_scope', $allowedScopes);
            })
            // Skip drivers who already hold an active or offered order
            ->whereDoesntHave('assignedDriverOrders', function ($q) {
                $q->whereNotIn('status', ['completed', 'cancelled'])
                  ->whereIn('delivery_status', ['assigned', 'accepted', 'picked_up', 'on_the_way', 'arrived']);
            })
            ->with('driver')
            ->get();

        if ($candidates->isEmpty()) {
            return null;
        }

        $ranked = $candidates->map(function (User $u) use ($origin) {
            $d = $u->driver;
            $hasGps = $d && $d->current_lat !== null && $d->current_lng !== null;
            $distKm = ($hasGps && $origin['lat'] !== null && $origin['lng'] !== null)
                ? self::distanceKm((float) $d->current_lat, (float) $d->current_lng, (float) $origin['lat'], (float) $origin['lng'])
                : null;

            $sameCity = ($origin['city'] !== '' && $d && trim((string) $d->city) === $origin['city']) ? 0 : 1;

            return [
                'user'      => $u,
                'has_gps'   => $hasGps ? 0 : 1,
                'same_city' => $sameCity,
                'dist'      => $distKm ?? 999999.0,
            ];
        })->sort(function ($a, $b) {
            if ($a['has_gps'] !== $b['has_gps']) {
                return $a['has_gps'] <=> $b['has_gps'];
            }
            if ($a['dist'] !== $b['dist']) {
                return $a['dist'] <=> $b['dist'];
            }
            return $a['same_city'] <=> $b['same_city'];
        })->values();

        // If origin GPS exists and top candidate has GPS, ignore drivers absurdly far (> 60 km) if possible
        $winner = $ranked->first();
        if (!$winner) {
            return null;
        }
        if ($origin['lat'] !== null && $winner['has_gps'] === 0 && $winner['dist'] > 60.0) {
            return null;
        }

        /** @var User $driverUser */
        $driverUser = $winner['user'];

        $order->assigned_driver_id = $driverUser->id;
        $order->delivery_status = 'assigned';
        $order->driver_assigned_at = now();
        if ((float) ($order->delivery_fee ?? 0) <= 0) {
            $order->delivery_fee = $order->resolveDeliveryFee();
        }
        $order->save();

        OrderNotificationService::notifyDriverOffer($order, $driverUser);

        return $driverUser;
    }

    /**
     * When a driver switches Online, automatically offer them the nearest unassigned
     * order waiting in the pool (if any matches their scope).
     */
    public function autoAssignWaitingOrdersForDriver(User $driverUser, Driver $driver): void
    {
        if ($driver->duty_status !== 'available' || $driverUser->status !== 'approved') {
            return;
        }

        $hasExistingOffer = Order::where('assigned_driver_id', $driverUser->id)
            ->whereNotIn('status', ['completed', 'cancelled'])
            ->whereIn('delivery_status', ['assigned', 'accepted', 'picked_up', 'on_the_way', 'arrived'])
            ->exists();
        if ($hasExistingOffer) {
            return;
        }

        $waitingOrders = Order::whereNull('assigned_driver_id')
            ->whereIn('status', ['pending', 'processing', 'accepted', 'confirmed', 'approved', 'in_progress'])
            ->with(['assignedPharmacy.pharmacy', 'assignedLab.lab'])
            ->latest()
            ->take(20)
            ->get()
            ->filter(function (Order $o) use ($driverUser, $driver) {
                if (!$o->needsDeliveryDriver()) {
                    return false;
                }
                $st = strtolower((string) $o->service_type);
                if ($driver->service_scope === 'pharmacy' && !str_contains($st, 'pharmac') && !str_contains($st, 'medic')) {
                    return false;
                }
                if ($driver->service_scope === 'lab_sample' && !str_contains($st, 'lab')) {
                    return false;
                }
                return !in_array((int) $driverUser->id, $this->getDeclinedDriverIds($o), true);
            })
            ->sortBy(fn (Order $o) => $this->distanceForDriver($o, $driver) ?? 999999.0);

        $first = $waitingOrders->first();
        if ($first) {
            $this->dispatchNearest($first);
        }
    }
}
