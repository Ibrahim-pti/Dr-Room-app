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
        $pharmacies = User::where('role', 'pharmacy')
            ->where('status', 'approved')
            ->select('id', 'name', 'email', 'phone', 'profile_image')
            ->get();
            
        // Map the image paths properly
        $pharmacies->transform(function($pharmacy) {
            $pharmacy->profile_image = $pharmacy->profile_image ? asset('storage/' . $pharmacy->profile_image) : null;
            $pharmacy->delivery_fee = 3000; // Mock default
            $pharmacy->rating = 4.8; // Mock rating
            $pharmacy->is_open = true; // Mock status
            return $pharmacy;
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
            $medication->image_url = $medication->image_path ? asset('storage/' . $medication->image_path) : null;
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
            $offer->image_url = $offer->image_path ? asset('storage/' . $offer->image_path) : null;
            return $offer;
        });

        return response()->json([
            'success' => true,
            'data' => $offers
        ]);
    }
}
