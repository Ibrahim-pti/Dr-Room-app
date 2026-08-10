<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Lab;
use App\Models\User;

class AdminLabController extends Controller
{
    public function index()
    {
        $labs = User::where('role', 'lab')->with('lab')->get();
        return response()->json($labs);
    }

    public function approve($id)
    {
        $user = User::where('role', 'lab')->findOrFail($id);
        $user->update(['status' => 'approved']);
        
        if (!$user->lab) {
            $user->lab()->create([]);
        }

        return response()->json(['message' => 'Lab approved successfully', 'user' => $user->load('lab')]);
    }

    public function reject($id)
    {
        $user = User::where('role', 'lab')->findOrFail($id);
        $user->update(['status' => 'rejected']);
        
        return response()->json(['message' => 'Lab rejected successfully', 'user' => $user]);
    }

    public function destroy($id)
    {
        $user = User::where('role', 'lab')->findOrFail($id);
        if ($user->lab) {
            $user->lab->delete();
        }
        $user->delete();

        return response()->json(null, 204);
    }
}
