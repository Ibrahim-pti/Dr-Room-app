<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;

class AdminUserController extends Controller
{
    public function index()
    {
        $users = User::latest()->get()->map(function ($u) {
            $u->is_blocked = ($u->status === 'blocked');
            return $u;
        });
        return response()->json($users);
    }

    public function update(Request $request, $id)
    {
        $user = User::findOrFail($id);

        $request->validate([
            'name' => 'required|string|max:255',
            'phone' => 'required|string|unique:users,phone,' . $user->id,
            'role' => 'nullable|string|in:patient,doctor,nurse,lab,pharmacy,admin',
            'status' => 'nullable|string|in:approved,pending,blocked',
            'password' => 'nullable|string|min:6',
        ]);

        $user->name = $request->name;
        $user->phone = $request->phone;

        if ($request->filled('role')) {
            $user->role = $request->role;
            $user->is_admin = ($request->role === 'admin');
        }

        if ($request->filled('status')) {
            $user->status = $request->status;
        }

        if ($request->filled('password')) {
            $user->password = \Illuminate\Support\Facades\Hash::make($request->password);
        }

        $user->save();

        $user->is_blocked = ($user->status === 'blocked');

        return response()->json([
            'message' => 'بەکارهێنەر بە سەرکەوتوویی نوێکرایەوە',
            'user' => $user
        ]);
    }

    public function destroy($id)
    {
        $user = User::findOrFail($id);

        // Protect primary admin from deletion
        if ($user->phone === '07500000000') {
            return response()->json([
                'message' => 'ناتوانیت ئەم ئەکاونتە سەرەکییە بسڕیتەوە'
            ], 403);
        }

        $user->delete();

        return response()->json([
            'message' => 'بەکارهێنەر بە سەرکەوتوویی سڕایەوە'
        ]);
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
