<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Nurse;

use App\Models\User;

class AdminNurseController extends Controller
{
    public function index()
    {
        $nurses = User::where('role', 'nurse')->with('nurse')->get();
        return response()->json($nurses);
    }

    public function approve($id)
    {
        $user = User::where('role', 'nurse')->findOrFail($id);
        $user->update(['status' => 'approved']);

        if (!$user->nurse) {
            $user->nurse()->create([
                // Add any default nurse fields if necessary
            ]);
        }

        \App\Models\AppNotification::create([
            'user_id' => $user->id,
            'title' => 'هەژمارەکەت پەسەندکرا',
            'title_en' => 'Account Approved',
            'title_ar' => 'تمت الموافقة على حسابك',
            'message' => 'پیرۆزە! هەژمارەکەت لەلایەن ئەدمینەوە پەسەندکرا. ئێستا دەتوانیت بچیتە ناو سیستەمەکە.',
            'message_en' => 'Congratulations! Your account has been approved by the admin.',
            'message_ar' => 'مبروك! تمت الموافقة على حسابك من قبل المسؤول.',
            'type' => 'system',
            'is_read' => false
        ]);

        return response()->json(['message' => 'Nurse approved successfully', 'user' => $user->load('nurse')]);
    }

    public function reject($id)
    {
        $user = User::where('role', 'nurse')->findOrFail($id);
        $user->update(['status' => 'rejected']);

        return response()->json(['message' => 'Nurse rejected successfully', 'user' => $user]);
    }

    public function destroy($id)
    {
        $user = User::where('role', 'nurse')->findOrFail($id);
        if ($user->nurse) {
            $user->nurse->delete();
        }
        $user->delete();

        return response()->json(null, 204);
    }
}
