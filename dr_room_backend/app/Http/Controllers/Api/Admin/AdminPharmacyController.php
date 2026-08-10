<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Pharmacy;
use App\Models\User;

class AdminPharmacyController extends Controller
{
    public function index()
    {
        $pharmacies = User::where('role', 'pharmacy')->with('pharmacy')->get();
        return response()->json($pharmacies);
    }

    public function approve($id)
    {
        $user = User::where('role', 'pharmacy')->findOrFail($id);
        $user->update(['status' => 'approved']);
        
        if (!$user->pharmacy) {
            $user->pharmacy()->create([]);
        }

        return response()->json(['message' => 'Pharmacy approved successfully', 'user' => $user->load('pharmacy')]);
    }

    public function reject($id)
    {
        $user = User::where('role', 'pharmacy')->findOrFail($id);
        $user->update(['status' => 'rejected']);
        
        return response()->json(['message' => 'Pharmacy rejected successfully', 'user' => $user]);
    }

    public function destroy($id)
    {
        $user = User::where('role', 'pharmacy')->findOrFail($id);
        if ($user->pharmacy) {
            $user->pharmacy->delete();
        }
        $user->delete();

        return response()->json(null, 204);
    }
}
