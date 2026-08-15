<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;

class LabApiController extends Controller
{
    /**
     * Get a list of all active labs
     */
    public function index(Request $request)
    {
        $query = User::with('lab')
            ->where('role', 'lab')
            ->where('status', 'approved');

        $users = $query->get();
            
        $labs = $users->map(function($user) {
            $lab = $user->lab;
            $image = $lab && $lab->image_path ? $lab->image_path : ($user->profile_image ? 'storage/' . $user->profile_image : 'assets/images/laboratory.jpg');
            return [
                'id' => $user->id,
                'name' => $user->name,
                'name_ar' => $user->name_ar ?? $user->name,
                'name_en' => $user->name_en ?? $user->name,
                'phone' => $user->phone,
                'profile_image' => $image,
                'image' => $image,
                'city' => $lab ? ($lab->city ?? 'Erbil') : 'Erbil',
                'rating' => $lab && $lab->rating ? (float)$lab->rating : 4.8,
                'reviews' => $lab && $lab->reviews ? (int)$lab->reviews : 120,
                'is_verified' => $lab ? (bool)($lab->is_verified ?? true) : true,
                'isVerified' => $lab ? (bool)($lab->is_verified ?? true) : true,
                'type' => 'General',
                'home_sample_collection' => $lab ? (bool)$lab->home_sample_collection : false,
                'location' => $lab ? $lab->location : null,
                'location_ar' => $lab ? $lab->location_ar : null,
                'location_en' => $lab ? $lab->location_en : null,
            ];
        });

        // Dynamic distinct cities from the real labs data
        $dynamicCities = $labs->pluck('city')->unique()->filter()->values()->all();
        array_unshift($dynamicCities, 'All');

        // Dynamic rating thresholds
        $dynamicRatings = [
            ['key' => 'all', 'label' => 'All', 'min' => 0.0],
            ['key' => '4_5', 'label' => '4.5+', 'min' => 4.5],
            ['key' => '4_7', 'label' => '4.7+', 'min' => 4.7],
            ['key' => '4_9', 'label' => '4.9+', 'min' => 4.9],
        ];

        return response()->json([
            'success' => true,
            'data' => $labs,
            'filters' => [
                'cities' => $dynamicCities,
                'ratings' => $dynamicRatings,
                'total' => $labs->count(),
            ]
        ]);
    }

    /**
     * Get details for a specific lab
     */
    public function show($id)
    {
        $user = User::with('lab')
            ->where('role', 'lab')
            ->where('status', 'approved')
            ->find($id);

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Lab not found'
            ], 404);
        }

        $lab = $user->lab;
        
        $data = [
            'id' => $user->id,
            'name' => $user->name,
            'name_ar' => $user->name_ar,
            'name_en' => $user->name_en,
            'email' => $user->email,
            'phone' => $user->phone,
            'profile_image' => $lab && $lab->image_path ? asset($lab->image_path) : ($user->profile_image ? asset('storage/' . $user->profile_image) : null),
            'rating' => $lab ? (float)$lab->rating : 0.0,
            'home_sample_collection' => $lab ? (bool)$lab->home_sample_collection : false,
            'about_us' => $lab ? $lab->about_us : null,
            'about_us_ar' => $lab ? $lab->about_us_ar : null,
            'about_us_en' => $lab ? $lab->about_us_en : null,
            'latitude' => $lab ? $lab->latitude : null,
            'longitude' => $lab ? $lab->longitude : null,
        ];

        return response()->json([
            'success' => true,
            'data' => $data
        ]);
    }
}
