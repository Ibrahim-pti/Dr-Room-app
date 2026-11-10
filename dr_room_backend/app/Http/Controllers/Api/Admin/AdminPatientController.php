<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use App\Models\User;
use App\Services\FcmService;
use Illuminate\Http\Request;

class AdminPatientController extends Controller
{
    /**
     * List all registered patients with search, filter, and quick stats
     */
    public function index(Request $request)
    {
        $nonPatientRoles = ['admin', 'staff', 'moderator', 'doctor', 'nurse', 'lab', 'pharmacy', 'xray', 'driver'];
        $baseQuery = User::where(function ($q) use ($nonPatientRoles) {
            $q->whereNull('role')->orWhereNotIn('role', $nonPatientRoles);
        });
        $query = clone $baseQuery;

        // Search by name, phone or email
        if ($request->filled('search')) {
            $term = '%' . $request->search . '%';
            $query->where(function ($q) use ($term) {
                $q->where('name', 'like', $term)
                  ->orWhere('phone', 'like', $term)
                  ->orWhere('email', 'like', $term);
            });
        }

        // Status Filter
        if ($request->status === 'active') {
            $query->where(function ($q) {
                $q->where('status', 'approved')->orWhereNull('status');
            });
        } elseif ($request->status === 'blocked') {
            $query->where('status', 'blocked');
        } elseif ($request->status === 'new') {
            $query->where('created_at', '>=', now()->subDays(30));
        }

        // Aggregated orders count and total spent
        $query->withCount('orders')
              ->withSum(['orders as total_spent' => function ($q) {
                  $q->where('status', 'completed');
              }], 'total_price');

        $paginator = $query->latest()->paginate((int) $request->input('per_page', 25));

        $patients = $paginator->through(function ($u) {
            return [
                'id' => $u->id,
                'name' => $u->name,
                'phone' => $u->phone,
                'email' => $u->email,
                'avatar_url' => $u->avatar_url,
                'status' => $u->status ?? 'approved',
                'is_blocked' => ($u->status === 'blocked'),
                'orders_count' => (int) ($u->orders_count ?? 0),
                'total_spent' => (float) ($u->total_spent ?? 0.0),
                'loyalty_points' => (int) ($u->loyalty_points ?? 0),
                'created_at' => $u->created_at ? $u->created_at->format('Y-m-d') : '',
                'created_at_human' => $u->created_at ? $u->created_at->diffForHumans() : '',
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $patients,
            'meta' => [
                'total' => $paginator->total(),
                'active_count' => (clone $baseQuery)->where(function ($q) {
                    $q->where('status', 'approved')->orWhereNull('status');
                })->count(),
                'blocked_count' => (clone $baseQuery)->where('status', 'blocked')->count(),
            ],
        ]);
    }

    /**
     * Get single patient full profile: details, address, stats, and complete order history
     */
    public function show($id)
    {
        $patient = User::with([
            'emrRecord',
            'orders' => function ($q) {
                $q->with('items')->latest();
            }
        ])->findOrFail($id);

        // Extract latest address & location coordinates from orders or emr
        $address = null;
        $location = null;
        $latestOrder = $patient->orders->first();

        if ($latestOrder) {
            $loc = $latestOrder->location_details;
            if (is_array($loc)) {
                $address = $loc['address'] ?? $loc['name'] ?? null;
                $location = [
                    'lat' => $loc['latitude'] ?? $loc['lat'] ?? null,
                    'lng' => $loc['longitude'] ?? $loc['lng'] ?? null,
                    'city' => $loc['city'] ?? null,
                ];
            }
            if (!$address && is_array($latestOrder->patient_details)) {
                $address = $latestOrder->patient_details['address'] ?? null;
            }
        }

        // Summary stats
        $totalOrders = $patient->orders->count();
        $completedOrders = $patient->orders->where('status', 'completed')->count();
        $pendingOrders = $patient->orders->where('status', 'pending')->count();
        $cancelledOrders = $patient->orders->where('status', 'cancelled')->count();
        $totalSpent = (float) $patient->orders->where('status', 'completed')->sum('total_price');

        // Orders list
        $ordersList = $patient->orders->map(function ($ord) {
            $serviceTitle = match ($ord->service_type) {
                'home_nursing' => 'پەرستاری ماڵەوە',
                'lab_test' => 'پشکنینی تاقیگە',
                'pharmacy' => 'دەرمانخانە',
                default => 'خزمەتگوزاری پزیشکی',
            };

            if ($ord->items && $ord->items->isNotEmpty()) {
                $itemsNames = $ord->items->pluck('item_name')->filter()->join('، ');
                if (!empty($itemsNames)) {
                    $serviceTitle = $itemsNames;
                }
            }

            return [
                'id' => $ord->id,
                'order_number' => '#ORD-' . str_pad($ord->id, 5, '0', STR_PAD_LEFT),
                'service_type' => $ord->service_type,
                'service_title' => $serviceTitle,
                'status' => $ord->status,
                'payment_status' => $ord->payment_status ?? 'pending',
                'payment_method' => $ord->payment_method ?? 'کاش',
                'total_price' => (float) $ord->total_price,
                'date' => $ord->created_at ? $ord->created_at->format('Y-m-d H:i') : '',
                'date_human' => $ord->created_at ? $ord->created_at->diffForHumans() : '',
            ];
        });

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $patient->id,
                'name' => $patient->name,
                'phone' => $patient->phone,
                'email' => $patient->email,
                'avatar_url' => $patient->avatar_url,
                'status' => $patient->status ?? 'approved',
                'is_blocked' => ($patient->status === 'blocked'),
                'created_at' => $patient->created_at ? $patient->created_at->format('Y-m-d') : '',
                'created_at_human' => $patient->created_at ? $patient->created_at->diffForHumans() : '',
                'loyalty_points' => (int) ($patient->loyalty_points ?? 0),
                'address' => $address ?? 'ناونیشان لە دواین داواکاری تۆمارنەکراوە',
                'location' => $location,
                'stats' => [
                    'total_orders' => $totalOrders,
                    'completed_orders' => $completedOrders,
                    'pending_orders' => $pendingOrders,
                    'cancelled_orders' => $cancelledOrders,
                    'total_spent' => $totalSpent,
                ],
                'emr' => $patient->emrRecord ? [
                    'blood_type' => $patient->emrRecord->blood_type,
                    'chronic_diseases' => $patient->emrRecord->chronic_diseases ?? [],
                    'allergies' => $patient->emrRecord->allergies ?? [],
                    'emergency_notes' => $patient->emrRecord->emergency_notes,
                ] : null,
                'orders' => $ordersList,
            ],
        ]);
    }

    /**
     * Send direct Push Notification + in-app notification to this patient
     */
    public function notify(Request $request, $id)
    {
        $request->validate([
            'title' => 'required|string|max:150',
            'message' => 'required|string|max:1000',
        ]);

        $patient = User::findOrFail($id);

        // 1. Create in-app notification
        AppNotification::create([
            'user_id' => $patient->id,
            'title' => $request->title,
            'title_ar' => $request->title,
            'title_en' => $request->title,
            'message' => $request->message,
            'message_ar' => $request->message,
            'message_en' => $request->message,
            'type' => 'admin_notice',
            'is_read' => false,
        ]);

        // 2. Dispatch FCM push notification
        try {
            app(FcmService::class)->sendToUsers(
                [$patient->id],
                $request->title,
                $request->message,
                ['type' => 'admin_notice']
            );
        } catch (\Throwable $e) {}

        return response()->json([
            'success' => true,
            'message' => 'ئاگاداری بە سەرکەوتوویی بۆ نەخۆشەکە نێردرا',
        ]);
    }

    /**
     * Toggle Block/Unblock for a patient account
     */
    public function toggleBlock($id)
    {
        $patient = User::findOrFail($id);
        $isBlocked = ($patient->status === 'blocked');
        $newStatus = $isBlocked ? 'approved' : 'blocked';

        $patient->status = $newStatus;
        $patient->save();

        return response()->json([
            'success' => true,
            'is_blocked' => ($newStatus === 'blocked'),
            'status' => $newStatus,
            'message' => $newStatus === 'blocked'
                ? 'ئەکاونتی نەخۆشەکە بە سەرکەوتوویی ڕاگیرا (بلۆک کرا)'
                : 'بلۆکی سەر ئەکاونتی نەخۆشەکە لابرا و چالاککرایەوە',
        ]);
    }
}

