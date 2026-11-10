<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use App\Models\Driver;
use App\Models\Order;
use App\Models\User;
use App\Services\FcmService;
use App\Services\OtpService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class AdminDriverController extends Controller
{
    public function index(Request $request)
    {
        $baseQuery = User::where('role', 'driver')->with(['driver']);

        $query = clone $baseQuery;

        if ($request->filled('search')) {
            $term = '%' . trim((string) $request->search) . '%';
            $query->where(function ($q) use ($term) {
                $q->where('name', 'like', $term)
                  ->orWhere('phone', 'like', $term)
                  ->orWhereHas('driver', function ($dq) use ($term) {
                      $dq->where('city', 'like', $term)
                         ->orWhere('plate_number', 'like', $term);
                  });
            });
        }

        if ($request->filled('status') && $request->status !== 'all') {
            $query->where('status', $request->status);
        }

        if ($request->filled('duty_status') && $request->duty_status !== 'all') {
            $duty = $request->duty_status;
            $query->whereHas('driver', fn ($dq) => $dq->where('duty_status', $duty));
        }

        if ($request->filled('service_scope') && $request->service_scope !== 'all') {
            $scope = $request->service_scope;
            $query->whereHas('driver', fn ($dq) => $dq->where('service_scope', $scope));
        }

        $drivers = $query->orderByRaw("CASE status WHEN 'pending' THEN 0 WHEN 'approved' THEN 1 WHEN 'blocked' THEN 2 WHEN 'rejected' THEN 3 ELSE 4 END")
            ->orderByDesc('created_at')
            ->get()
            ->map(function ($u) {
                $d = $u->driver;
                $activeOrders = Order::where('assigned_driver_id', $u->id)
                    ->whereNotIn('status', ['completed', 'cancelled'])
                    ->orderByDesc('id')
                    ->get(['id', 'service_type', 'delivery_status', 'location_details']);

                return [
                    'id' => $u->id,
                    'driver_id' => $d?->id,
                    'name' => $u->name,
                    'phone' => $u->phone,
                    'status' => $u->status,
                    'avatar_url' => $u->avatar_url,
                    'city' => $d?->city ?? 'هەولێر',
                    'vehicle_type' => $d?->vehicle_type ?? 'motorcycle',
                    'plate_number' => $d?->plate_number,
                    'service_scope' => $d?->service_scope ?? 'both',
                    'duty_status' => $d?->duty_status ?? 'offline',
                    'current_lat' => $d?->current_lat,
                    'current_lng' => $d?->current_lng,
                    'last_location_at' => $d?->last_location_at?->toIso8601String(),
                    'last_seen_seconds' => $d?->last_location_at ? now()->diffInSeconds($d->last_location_at) : null,
                    'completed_deliveries' => (int) ($d?->completed_deliveries ?? 0),
                    'total_earnings' => (float) ($d?->total_earnings ?? 0),
                    'rating' => (float) ($d?->rating ?? 5.0),
                    'active_orders_count' => $activeOrders->count(),
                    'active_orders' => $activeOrders->map(fn ($o) => [
                        'id' => $o->id,
                        'service_type' => $o->service_type,
                        'delivery_status' => $o->delivery_status,
                    ])->values(),
                    'created_at' => $u->created_at?->format('Y-m-d H:i'),
                ];
            })
            ->values();

        $allDrivers = User::where('role', 'driver')->with('driver')->get();

        return response()->json([
            'success' => true,
            'data' => $drivers,
            'meta' => [
                'total' => $allDrivers->count(),
                'pending_count' => $allDrivers->where('status', 'pending')->count(),
                'approved_count' => $allDrivers->where('status', 'approved')->count(),
                'blocked_count' => $allDrivers->whereIn('status', ['blocked', 'rejected'])->count(),
                'online_count' => $allDrivers->where('status', 'approved')->filter(fn ($u) => in_array($u->driver?->duty_status, ['available', 'busy'], true))->count(),
                'available_count' => $allDrivers->where('status', 'approved')->filter(fn ($u) => $u->driver?->duty_status === 'available')->count(),
                'busy_count' => $allDrivers->where('status', 'approved')->filter(fn ($u) => $u->driver?->duty_status === 'busy')->count(),
            ],
        ]);
    }

    public function liveMap()
    {
        $drivers = User::where('role', 'driver')
            ->where('status', 'approved')
            ->with('driver')
            ->get()
            ->map(function ($u) {
                $d = $u->driver;
                $activeOrder = Order::where('assigned_driver_id', $u->id)
                    ->whereNotIn('status', ['completed', 'cancelled'])
                    ->orderByDesc('id')
                    ->first();

                $loc = $activeOrder && is_array($activeOrder->location_details)
                    ? $activeOrder->location_details
                    : [];

                return [
                    'id' => $u->id,
                    'name' => $u->name,
                    'phone' => $u->phone,
                    'avatar_url' => $u->avatar_url,
                    'city' => $d?->city ?? 'هەولێر',
                    'vehicle_type' => $d?->vehicle_type ?? 'motorcycle',
                    'plate_number' => $d?->plate_number,
                    'service_scope' => $d?->service_scope ?? 'both',
                    'duty_status' => $d?->duty_status ?? 'offline',
                    'current_lat' => $d?->current_lat,
                    'current_lng' => $d?->current_lng,
                    'last_location_at' => $d?->last_location_at?->toIso8601String(),
                    'last_seen_seconds' => $d?->last_location_at ? now()->diffInSeconds($d->last_location_at) : null,
                    'completed_deliveries' => (int) ($d?->completed_deliveries ?? 0),
                    'active_order' => $activeOrder ? [
                        'id' => $activeOrder->id,
                        'service_type' => $activeOrder->service_type,
                        'delivery_status' => $activeOrder->delivery_status,
                        'dest_lat' => $loc['latitude'] ?? $loc['lat'] ?? null,
                        'dest_lng' => $loc['longitude'] ?? $loc['lng'] ?? null,
                        'dest_address' => $loc['address'] ?? ($loc['full_address'] ?? ''),
                    ] : null,
                ];
            })
            ->values();

        return response()->json(['success' => true, 'data' => $drivers]);
    }

    public function store(Request $request)
    {
        $localPhone = OtpService::toLocalPhone((string) $request->phone);
        $request->merge(['phone' => $localPhone]);

        $request->validate([
            'name' => 'required|string|max:255',
            'phone' => 'required|string|max:25|unique:users,phone',
            'password' => 'required|string|min:6',
            'city' => 'nullable|string|max:100',
            'vehicle_type' => 'nullable|in:motorcycle,car,refrigerated_van',
            'plate_number' => 'nullable|string|max:50',
            'service_scope' => 'nullable|in:pharmacy,lab_sample,both',
        ]);

        $user = DB::transaction(function () use ($request, $localPhone) {
            $u = User::create([
                'name' => trim($request->name),
                'phone' => $localPhone,
                'password' => Hash::make($request->password),
                'role' => 'driver',
                'status' => 'approved',
            ]);

            Driver::create([
                'user_id' => $u->id,
                'city' => $request->city ?: 'هەولێر',
                'vehicle_type' => $request->vehicle_type ?: 'motorcycle',
                'plate_number' => $request->plate_number,
                'service_scope' => $request->service_scope ?: 'both',
                'duty_status' => 'offline',
            ]);

            return $u;
        });

        return response()->json([
            'message' => 'کارمەندی گەیاندن بە سەرکەوتوویی زیادکرا',
            'user' => $user->load('driver'),
        ], 201);
    }

    public function approve($id)
    {
        $user = User::where('role', 'driver')->findOrFail($id);
        $user->update(['status' => 'approved']);
        Driver::firstOrCreate(['user_id' => $user->id]);

        try {
            $title = 'هەژماری گەیاندنەکەت پەسەندکرا 🎉';
            $msg = 'پیرۆزە! ئێستا دەتوانیت بە ژمارەی مۆبایل و وشەی تێپەڕەکەت بچیتە ناو ئەپی دکتۆر ڕۆم.';
            AppNotification::create([
                'user_id' => $user->id,
                'title' => $title,
                'title_ar' => 'تمت الموافقة على حساب التوصيل 🎉',
                'title_en' => 'Driver Account Approved 🎉',
                'message' => $msg,
                'message_ar' => 'مبارك! يمكنك الآن الدخول إلى تطبيق دكتور روم برقم هاتفك وكلمة المرور.',
                'message_en' => 'Congrats! You can now sign in to Dr. Room with your phone number and password.',
                'type' => 'system',
                'is_read' => false,
            ]);

            app(FcmService::class)->sendToUsers([$user->id], $title, $msg, ['type' => 'driver_approved']);
        } catch (\Throwable $e) {}

        return response()->json([
            'message' => 'کارمەندی گەیاندن پەسەندکرا',
            'user' => $user->load('driver'),
        ]);
    }

    public function reject($id)
    {
        $user = User::where('role', 'driver')->findOrFail($id);
        $user->update(['status' => 'blocked']);
        if ($user->driver) {
            $user->driver->update(['duty_status' => 'offline']);
        }

        return response()->json([
            'message' => 'داواکارییەکە ڕەتکرایەوە',
            'user' => $user->load('driver'),
        ]);
    }

    public function toggleBlock($id)
    {
        $user = User::where('role', 'driver')->findOrFail($id);
        $isBlocked = in_array($user->status, ['blocked', 'rejected'], true);
        $newStatus = $isBlocked ? 'approved' : 'blocked';
        $user->update(['status' => $newStatus]);

        if ($newStatus === 'blocked' && $user->driver) {
            $user->driver->update(['duty_status' => 'offline']);
        }

        return response()->json([
            'message' => $newStatus === 'blocked' ? 'کارمەند بلۆککرا' : 'کارمەند چالاککرایەوە',
            'status' => $newStatus,
        ]);
    }
}
