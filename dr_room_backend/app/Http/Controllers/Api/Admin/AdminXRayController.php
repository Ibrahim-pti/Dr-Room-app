<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\XRay;
use App\Models\User;

class AdminXRayController extends Controller
{
    public function index()
    {
        $xrays = User::where('role', 'xray')->with('xray')->get();
        return response()->json($xrays);
    }

    public function approve($id)
    {
        $user = User::where('role', 'xray')->findOrFail($id);
        $user->update(['status' => 'approved']);
        
        if (!$user->xray) {
            $user->xray()->create([]);
        }

        return response()->json(['message' => 'XRay approved successfully', 'user' => $user->load('xray')]);
    }

    public function reject($id)
    {
        $user = User::where('role', 'xray')->findOrFail($id);
        $user->update(['status' => 'rejected']);
        
        return response()->json(['message' => 'XRay rejected successfully', 'user' => $user]);
    }

    public function destroy($id)
    {
        $user = User::where('role', 'xray')->findOrFail($id);
        if ($user->xray) {
            $user->xray->delete();
        }
        $user->delete();

        return response()->json(null, 204);
    }
}
