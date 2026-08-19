<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Medication;
use App\Models\PharmacyOffer;

class PharmacyApiController extends Controller
{
    /**
     * Get a list of all active pharmacies
     */
    public function index()
    {
        $users = User::with('pharmacy')
            ->where('role', 'pharmacy')
            ->where('status', 'approved')
            ->get();
            
        $pharmacies = $users->map(function($user) {
            $pharmacy = $user->pharmacy;
            $image = $pharmacy && $pharmacy->image_path 
                ? (str_starts_with($pharmacy->image_path, 'http') ? $pharmacy->image_path : asset('storage/' . $pharmacy->image_path)) 
                : ($user->profile_image ? (str_starts_with($user->profile_image, 'http') ? $user->profile_image : asset('storage/' . $user->profile_image)) : null);

            return [
                'id' => $user->id,
                'name' => $user->name,
                'name_ar' => $user->name_ar ?? $user->name,
                'name_en' => $user->name_en ?? $user->name,
                'email' => $user->email,
                'phone' => $user->phone ?? ($pharmacy ? $pharmacy->phone : null),
                'address' => $pharmacy ? ($pharmacy->location ?? 'هەولێر') : 'هەولێر',
                'location' => $pharmacy ? ($pharmacy->location ?? 'هەولێر') : 'هەولێر',
                'profile_image' => $image,
                'delivery_fee' => 3000,
                'rating' => $pharmacy && $pharmacy->rating ? (float)$pharmacy->rating : 4.8,
                'is_open' => true,
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $pharmacies
        ]);
    }

    /**
     * Get medications for a specific pharmacy
     */
    public function medications($id)
    {
        $medications = Medication::where('user_id', $id)
            ->where('is_active', true)
            ->get();

        $medications->transform(function($medication) {
            $medication->image_url = $medication->image_path ? (str_starts_with($medication->image_path, 'http') ? $medication->image_path : asset('storage/' . $medication->image_path)) : null;
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
            ->get();

        $offers->transform(function($offer) {
            $offer->image_url = $offer->image_path ? (str_starts_with($offer->image_path, 'http') ? $offer->image_path : asset('storage/' . $offer->image_path)) : null;
            return $offer;
        });

        return response()->json([
            'success' => true,
            'data' => $offers
        ]);
    }
}
