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
    public function index()
    {
        $labs = User::with('lab')
            ->where('role', 'lab')
            ->where('status', 'approved')
            ->select('id', 'name', 'name_ar', 'name_en', 'email', 'phone', 'profile_image')
            ->get();
            
        $labs->transform(function($user) {
            $lab = $user->lab;
            return [
                'id' => $user->id,
                'name' => $user->name,
                'name_ar' => $user->name_ar,
                'name_en' => $user->name_en,
                'phone' => $user->phone,
                'profile_image' => $lab && $lab->image_path ? asset($lab->image_path) : ($user->profile_image ? asset('storage/' . $user->profile_image) : null),
                'rating' => $lab ? (float)$lab->rating : 0.0,
                'home_sample_collection' => $lab ? (bool)$lab->home_sample_collection : false,
                'location' => $lab ? $lab->location : null,
                'location_ar' => $lab ? $lab->location_ar : null,
                'location_en' => $lab ? $lab->location_en : null,
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $labs
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
