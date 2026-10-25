<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\Banner;
use App\Models\Article;
use App\Models\AppNotification;
use App\Models\Category;

class AppController extends Controller
{
    public function home()
    {
        $topDoctors = \App\Models\Doctor::whereHas('user', function($q) { $q->where('status', 'approved'); })
            ->whereNotNull('specialty')
            ->whereHas('services')
            ->whereHas('schedules')
            ->with(['user:id,name,name_en,name_ar,email,is_doctor', 'services' => fn ($q) => $q->where('is_active', true), 'schedules'])
            ->orderBy('rating', 'desc')
            ->take(5)
            ->get();

        $topNurses = \App\Models\Nurse::where('is_approved', true)
            ->with(['user:id,name,name_en,name_ar,name_kmr,email'])
            ->orderBy('rating', 'desc')
            ->take(6)
            ->get()
            ->map(function ($nurse) {
                $rawImg = $nurse->image_path ?: null;
                $imageUrl = null;
                if ($rawImg) {
                    $imageUrl = str_starts_with($rawImg, 'http') ? $rawImg : asset(ltrim($rawImg, '/'));
                }

                return [
                    'id' => $nurse->id,
                    'name' => $nurse->user->name ?? '',
                    'name_en' => $nurse->user->name_en ?? '',
                    'name_ar' => $nurse->user->name_ar ?? '',
                    'name_kmr' => $nurse->user->name_kmr ?? '',
                    'specialty' => $nurse->specialty ?? '',
                    'specialty_en' => $nurse->specialty_en ?? '',
                    'specialty_ar' => $nurse->specialty_ar ?? '',
                    'bio' => $nurse->bio ?? '',
                    'phone' => $nurse->phone ?? '',
                    'city' => $nurse->city ?? '',
                    'address' => $nurse->address ?? '',
                    'latitude' => $nurse->latitude,
                    'longitude' => $nurse->longitude,
                    'service_type' => $nurse->service_type ?? 'home_nursing',
                    'image' => $imageUrl,
                    'profile_image' => $imageUrl,
                    'is_available' => (bool)($nurse->is_available ?? true),
                    'rating' => ($nurse->rating !== null) ? (float)$nurse->rating : 0.0,
                    'total_reviews' => (int)($nurse->total_reviews ?? 0),
                    'fee' => $nurse->fee,
                    'experience_years' => $nurse->experience_years ?? 5,
                    'completed_appointments' => $nurse->completed_appointments ?? 0,
                ];
            });

        $topPharmacies = \App\Models\User::where('role', 'pharmacy')
            ->where('status', 'approved')
            ->with('pharmacy')
            ->take(6)
            ->get()
            ->map(function ($user) {
                $pharmacy = $user->pharmacy;
                $rawImg = $pharmacy && $pharmacy->image_path ? $pharmacy->image_path : null;
                $image = null;
                if ($rawImg) {
                    $image = str_starts_with($rawImg, 'http') ? $rawImg : asset(ltrim($rawImg, '/'));
                }

                $city = $pharmacy && !empty($pharmacy->city) 
                    ? $pharmacy->city 
                    : ($user->city ?? ($pharmacy && !empty($pharmacy->location) ? $pharmacy->location : 'هەولێر'));

                return [
                    'id' => $user->id,
                    'name' => $user->name,
                    'name_ar' => $user->name_ar ?? $user->name,
                    'name_en' => $user->name_en ?? $user->name,
                    'name_kmr' => $user->name_kmr ?? $user->name,
                    'email' => $user->email,
                    'phone' => $pharmacy && $pharmacy->phone ? $pharmacy->phone : ($user->phone ?? ''),
                    'city' => $city,
                    'address' => $pharmacy && $pharmacy->location ? $pharmacy->location : ($user->address ?? $city),
                    'profile_image' => $image,
                    'rating' => $pharmacy && $pharmacy->rating !== null ? (double)$pharmacy->rating : 0.0,
                    'total_reviews' => $pharmacy && $pharmacy->total_reviews ? (int)$pharmacy->total_reviews : 0,
                    'delivery_fee' => $pharmacy && $pharmacy->delivery_fee !== null ? (double)$pharmacy->delivery_fee : 1500.0,
                    'delivery_time' => $pharmacy && $pharmacy->delivery_time ? $pharmacy->delivery_time : '٢٠-٣٠ خولەک',
                    'working_hours' => $pharmacy && $pharmacy->working_hours ? $pharmacy->working_hours : '٢٤ کاتژمێر',
                    'is_open' => $pharmacy && $pharmacy->is_open !== null ? (bool)$pharmacy->is_open : true,
                ];
            });

        $topLabs = \App\Models\Lab::where('is_approved', true)
            ->with(['user:id,name,name_en,name_ar,name_kmr,email'])
            ->orderBy('rating', 'desc')
            ->take(6)
            ->get()
            ->map(function ($lab) {
                $rawImg = $lab->image_path ?: null;
                $imageUrl = 'assets/images/laboratory.jpg';
                if ($rawImg) {
                    $imageUrl = str_starts_with($rawImg, 'http') ? $rawImg : asset(ltrim($rawImg, '/'));
                }

                $ratingVal = ($lab->rating !== null) ? (float)$lab->rating : 0.0;
                $reviewsCount = ($lab->total_reviews !== null) ? (int)$lab->total_reviews : 0;

                return [
                    'id' => $lab->user_id ?? $lab->id,
                    'lab_id' => $lab->id,
                    'name' => $lab->user->name ?? ($lab->name ?? ''),
                    'name_en' => $lab->user->name_en ?? ($lab->name_en ?? ($lab->user->name ?? '')),
                    'name_ar' => $lab->user->name_ar ?? ($lab->name_ar ?? ($lab->user->name ?? '')),
                    'name_kmr' => $lab->user->name_kmr ?? ($lab->name_kmr ?? ($lab->user->name ?? '')),
                    'city' => $lab->city ?? 'Erbil',
                    'location' => $lab->location ?? '',
                    'location_ar' => $lab->location_ar ?? '',
                    'location_en' => $lab->location_en ?? '',
                    'location_kmr' => $lab->location_kmr ?? '',
                    'address' => $lab->location ?? '',
                    'phone' => $lab->phone ?? ($lab->user->phone ?? ''),
                    'rating' => $ratingVal,
                    'total_reviews' => $reviewsCount,
                    'image' => $imageUrl,
                    'profile_image' => $imageUrl,
                ];
            });

        return response()->json([
            'banners' => Banner::where('is_active', true)->orderBy('sort_order')->get(),
            'categories' => Category::all(),
            'latest_articles' => Article::where('is_published', true)->latest()->take(5)->get(),
            'top_doctors' => $topDoctors,
            'top_nurses' => $topNurses,
            'top_labs' => $topLabs,
            'top_pharmacies' => $topPharmacies,
        ]);
    }

    public function banners()
    {
        return Banner::where('is_active', true)->orderBy('sort_order')->get();
    }

    public function articles()
    {
        return Article::where('is_published', true)->latest()->get();
    }

    public function notifications(Request $request = null)
    {
        $request = $request ?: request();
        $user = $request->user('sanctum') ?? auth('sanctum')->user();
        $userId = $user ? $user->id : null;
        
        return AppNotification::where(function($q) use ($userId) {
            $q->whereNull('user_id');
            if ($userId) {
                $q->orWhere('user_id', $userId);
            }
        })
        ->latest()
        ->get();
    }

    public function markNotificationsRead(Request $request)
    {
        $user = $request->user('sanctum') ?? auth('sanctum')->user();
        if ($user) {
            AppNotification::where('user_id', $user->id)->update(['is_read' => true]);
        }
        return response()->json(['message' => 'All marked as read']);
    }

    public function deleteNotification(Request $request, $id)
    {
        $user = $request->user('sanctum') ?? auth('sanctum')->user();
        if ($user) {
            AppNotification::where('id', $id)->where('user_id', $user->id)->delete();
        }
        return response()->json(null, 204);
    }


    public function doctors(Request $request)
    {
        $query = \App\Models\Doctor::whereHas('user', function($q) { $q->where('status', 'approved'); })
            ->whereNotNull('specialty')
            ->whereHas('services')
            ->whereHas('schedules')
            ->with(['user:id,name,name_en,name_ar,email,is_doctor', 'services' => fn ($q) => $q->where('is_active', true), 'schedules']);

        if ($request->has('specialty')) {
            $query->where('specialty', $request->specialty);
        }

        return $query->get();
    }

    public function doctor($id)
    {
        $doctor = \App\Models\Doctor::with(['user:id,name,name_en,name_ar,email,is_doctor', 'services' => fn ($q) => $q->where('is_active', true), 'schedules'])->findOrFail($id);
        return response()->json($doctor);
    }
}
