<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;

class AdminUserController extends Controller
{
    public function index()
    {
        $users = User::where('role', 'patient')->get();
        return response()->json($users);
    }

    public function block($id)
    {
        $user = User::findOrFail($id);
        $user->update(['status' => 'blocked']);

        return response()->json(['message' => 'User blocked successfully', 'user' => $user]);
    }

    public function unblock($id)
    {
        $user = User::findOrFail($id);
        // Assuming unblocking a user returns them to approved status, 
        // if they were pending, maybe they shouldn't be blocked in the first place, or should go back to pending.
        // For simplicity, we assume unblock -> approved.
        $user->update(['status' => 'approved']);

        return response()->json(['message' => 'User unblocked successfully', 'user' => $user]);
    }

    public function storeAdmin(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'phone' => 'required|string|unique:users',
            'password' => 'required|string|min:6',
        ]);

        $admin = User::create([
            'name' => $request->name,
            'phone' => $request->phone,
            'password' => \Illuminate\Support\Facades\Hash::make($request->password),
            'role' => 'admin',
            'status' => 'approved',
            'is_admin' => true,
        ]);

        return response()->json([
            'message' => 'ئەدمین بە سەرکەوتوویی زیادکرا',
            'admin' => $admin
        ], 201);
    }
}
