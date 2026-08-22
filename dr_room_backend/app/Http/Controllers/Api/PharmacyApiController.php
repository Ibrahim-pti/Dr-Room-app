<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Medication;
use App\Models\PharmacyOffer;
use App\Models\PharmacyReview;
use Illuminate\Support\Facades\Auth;

class PharmacyApiController extends Controller
{
    /**
     * Get a list of all active pharmacies with filters and search
     */
    public function index(Request $request)
    {
        $query = User::with(['pharmacy'])
            ->where('role', 'pharmacy')
            ->where('status', 'approved');

        if ($request->filled('city')) {
            $city = $request->query('city');
            $query->whereHas('pharmacy', function($q) use ($city) {
                $q->where('city', $city)->orWhere('location', 'like', "%{$city}%");
            });
        }

        if ($request->filled('search')) {
            $search = $request->query('search');
            $query->where(function($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('name_ar', 'like', "%{$search}%")
                  ->orWhere('name_en', 'like', "%{$search}%")
                  ->orWhereHas('pharmacy', function($pq) use ($search) {
                      $pq->where('location', 'like', "%{$search}%")
                         ->orWhere('city', 'like', "%{$search}%");
                  });
            });
        }

        $users = $query->get();
            
        $pharmacies = $users->map(function($user) {
            $pharmacy = $user->pharmacy;
            $image = $pharmacy && $pharmacy->image_path 
                ? (str_starts_with($pharmacy->image_path, 'http') ? $pharmacy->image_path : asset('storage/' . $pharmacy->image_path)) 
                : ($user->profile_image ? (str_starts_with($user->profile_image, 'http') ? $user->profile_image : asset('storage/' . $user->profile_image)) : null);

            $gallery = [];
            if ($pharmacy && !empty($pharmacy->gallery_images)) {
                $rawGallery = is_array($pharmacy->gallery_images) ? $pharmacy->gallery_images : json_decode($pharmacy->gallery_images, true);
                if (is_array($rawGallery)) {
                    $gallery = array_map(function($img) {
                        return str_starts_with($img, 'http') ? $img : asset('storage/' . $img);
                    }, $rawGallery);
                }
            }

            return [
                'id' => $user->id,
                'name' => $user->name,
                'name_ar' => $user->name_ar ?? $user->name,
                'name_en' => $user->name_en ?? $user->name,
                'email' => $user->email,
                'phone' => $pharmacy && $pharmacy->phone ? $pharmacy->phone : ($user->phone ?? '07501234567'),
                'address' => $pharmacy && $pharmacy->location ? $pharmacy->location : 'هەولێر، شەقامی ١٠٠ مەتری',
                'location' => $pharmacy && $pharmacy->location ? $pharmacy->location : 'هەولێر، شەقامی ١٠٠ مەتری',
                'city' => $pharmacy && $pharmacy->city ? $pharmacy->city : 'هەولێر',
                'profile_image' => $image,
                'gallery_images' => $gallery,
                'delivery_fee' => $pharmacy && $pharmacy->delivery_fee !== null ? (double)$pharmacy->delivery_fee : 3000.0,
                'delivery_time' => $pharmacy && $pharmacy->delivery_time ? $pharmacy->delivery_time : '۲۰-۳۰ خولەک',
                'rating' => $pharmacy && $pharmacy->rating ? (double)$pharmacy->rating : 4.9,
                'total_reviews' => $pharmacy && $pharmacy->total_reviews ? (int)$pharmacy->total_reviews : 0,
                'is_open' => $pharmacy && $pharmacy->is_open !== null ? (bool)$pharmacy->is_open : true,
                'is_verified' => true,
                'facebook_url' => $pharmacy ? $pharmacy->facebook_url : null,
                'latitude' => $pharmacy && $pharmacy->latitude ? (double)$pharmacy->latitude : null,
                'longitude' => $pharmacy && $pharmacy->longitude ? (double)$pharmacy->longitude : null,
                'bio' => $pharmacy ? $pharmacy->bio : null,
                'available_days' => $pharmacy ? $pharmacy->available_days : null,
            ];
        });

        // Filter by open or rating if requested
        if ($request->query('is_open') === 'true' || $request->query('is_open') === '1') {
            $pharmacies = $pharmacies->where('is_open', true)->values();
        }

        return response()->json([
            'success' => true,
            'data' => $pharmacies
        ]);
    }

    /**
     * Get specific pharmacy profile detail
     */
    public function show($id)
    {
        $user = User::with(['pharmacy'])->where('role', 'pharmacy')->findOrFail($id);
        $pharmacy = $user->pharmacy;

        $image = $pharmacy && $pharmacy->image_path 
            ? (str_starts_with($pharmacy->image_path, 'http') ? $pharmacy->image_path : asset('storage/' . $pharmacy->image_path)) 
            : ($user->profile_image ? (str_starts_with($user->profile_image, 'http') ? $user->profile_image : asset('storage/' . $user->profile_image)) : null);

        $gallery = [];
        if ($pharmacy && !empty($pharmacy->gallery_images)) {
            $rawGallery = is_array($pharmacy->gallery_images) ? $pharmacy->gallery_images : json_decode($pharmacy->gallery_images, true);
            if (is_array($rawGallery)) {
                $gallery = array_map(function($img) {
                    return str_starts_with($img, 'http') ? $img : asset('storage/' . $img);
                }, $rawGallery);
            }
        }

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $user->id,
                'name' => $user->name,
                'name_ar' => $user->name_ar ?? $user->name,
                'name_en' => $user->name_en ?? $user->name,
                'email' => $user->email,
                'phone' => $pharmacy && $pharmacy->phone ? $pharmacy->phone : ($user->phone ?? '07501234567'),
                'address' => $pharmacy && $pharmacy->location ? $pharmacy->location : 'هەولێر، شەقامی ١٠٠ مەتری',
                'city' => $pharmacy && $pharmacy->city ? $pharmacy->city : 'هەولێر',
                'profile_image' => $image,
                'gallery_images' => $gallery,
                'delivery_fee' => $pharmacy && $pharmacy->delivery_fee !== null ? (double)$pharmacy->delivery_fee : 3000.0,
                'delivery_time' => $pharmacy && $pharmacy->delivery_time ? $pharmacy->delivery_time : '۲۰-۳۰ خولەک',
                'rating' => $pharmacy && $pharmacy->rating ? (double)$pharmacy->rating : 4.9,
                'total_reviews' => $pharmacy && $pharmacy->total_reviews ? (int)$pharmacy->total_reviews : 0,
                'is_open' => $pharmacy && $pharmacy->is_open !== null ? (bool)$pharmacy->is_open : true,
                'is_verified' => true,
                'facebook_url' => $pharmacy ? $pharmacy->facebook_url : null,
                'latitude' => $pharmacy && $pharmacy->latitude ? (double)$pharmacy->latitude : null,
                'longitude' => $pharmacy && $pharmacy->longitude ? (double)$pharmacy->longitude : null,
                'bio' => $pharmacy ? $pharmacy->bio : null,
                'available_days' => $pharmacy ? $pharmacy->available_days : null,
            ]
        ]);
    }

    /**
     * Get medications for a specific pharmacy with category & search filtering
     */
    public function medications(Request $request, $id)
    {
        $query = Medication::where('user_id', $id)
            ->where('is_active', true);

        if ($request->filled('category') && $request->query('category') !== 'هەمووی') {
            $category = $request->query('category');
            $query->where('category', $category);
        }

        if ($request->filled('search')) {
            $search = $request->query('search');
            $query->where(function($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('description', 'like', "%{$search}%");
            });
        }

        $medications = $query->orderBy('id', 'asc')->get();

        $medications->transform(function($medication) {
            $medication->image_url = $medication->image_path 
                ? (str_starts_with($medication->image_path, 'http') ? $medication->image_path : asset('storage/' . $medication->image_path)) 
                : null;
            return $medication;
        });

        return response()->json([
            'success' => true,
            'data' => $medications
        ]);
    }

    /**
     * Get offers for a specific pharmacy
     */
    public function offers($id)
    {
        $offers = PharmacyOffer::where('user_id', $id)
            ->where('is_active', true)
            ->where(function ($query) {
                $query->whereNull('start_date')
                      ->orWhere('start_date', '<=', now());
            })
            ->where(function ($query) {
                $query->whereNull('end_date')
                      ->orWhere('end_date', '>=', now());
            })
            ->orderBy('id', 'desc')
            ->get();

        $offers->transform(function($offer) {
            $offer->image_url = $offer->image_path 
                ? (str_starts_with($offer->image_path, 'http') ? $offer->image_path : asset('storage/' . $offer->image_path)) 
                : null;
            return $offer;
        });

        return response()->json([
            'success' => true,
            'data' => $offers
        ]);
    }

    /**
     * Get reviews for a pharmacy
     */
    public function reviews($id)
    {
        $reviews = PharmacyReview::with('user:id,name,profile_image')
            ->where('pharmacy_id', $id)
            ->latest()
            ->get();

        $reviews->transform(function($review) {
            if ($review->user && $review->user->profile_image) {
                $review->user->profile_image_url = str_starts_with($review->user->profile_image, 'http')
                    ? $review->user->profile_image
                    : asset('storage/' . $review->user->profile_image);
            }
            return $review;
        });

        return response()->json([
            'success' => true,
            'data' => $reviews
        ]);
    }

    /**
     * Store a new review for pharmacy
     */
    public function storeReview(Request $request, $id)
    {
        $request->validate([
            'rating' => 'required|numeric|min:1|max:5',
            'comment' => 'nullable|string|max:1000',
        ]);

        $pharmacyUser = User::where('role', 'pharmacy')->findOrFail($id);

        $review = PharmacyReview::create([
            'user_id' => Auth::id(),
            'pharmacy_id' => $pharmacyUser->id,
            'rating' => $request->rating,
            'comment' => $request->comment,
        ]);

        // Recalculate pharmacy rating & total reviews
        $avgRating = PharmacyReview::where('pharmacy_id', $pharmacyUser->id)->avg('rating');
        $totalReviews = PharmacyReview::where('pharmacy_id', $pharmacyUser->id)->count();

        $pharmacy = $pharmacyUser->pharmacy;
        if ($pharmacy) {
            $pharmacy->rating = round($avgRating, 1);
            $pharmacy->total_reviews = $totalReviews;
            $pharmacy->save();
        }

        return response()->json([
            'success' => true,
            'message' => 'Review submitted successfully',
            'data' => $review->load('user:id,name,profile_image')
        ], 201);
    }
}
