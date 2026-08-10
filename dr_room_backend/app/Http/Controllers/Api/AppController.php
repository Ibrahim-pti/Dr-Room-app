<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\Banner;
use App\Models\Article;
use App\Models\AppNotification;
use App\Models\Category;

class AppController extends Controller
{
    public function home()
    {
        $topDoctors = \App\Models\Doctor::whereHas('user', function($q) { $q->where('status', 'approved'); })
            ->whereNotNull('specialty')
            ->whereHas('services')
            ->whereHas('schedules')
            ->with(['user:id,name,name_en,name_ar,email,is_doctor', 'services' => fn ($q) => $q->where('is_active', true), 'schedules'])
            ->orderBy('rating', 'desc')
            ->take(5)
            ->get();

        return response()->json([
            'banners' => Banner::where('is_active', true)->orderBy('sort_order')->get(),
            'categories' => Category::all(),
            'latest_articles' => Article::where('is_published', true)->latest()->take(5)->get(),
            'top_doctors' => $topDoctors,
            'top_pharmacies' => \App\Models\User::where('role', 'pharmacy')->where('status', 'approved')->take(4)->get(),
        ]);
    }

    public function banners()
    {
        return Banner::where('is_active', true)->orderBy('sort_order')->get();
    }

    public function articles()
    {
        return Article::where('is_published', true)->latest()->get();
    }

    public function notifications(Request $request)
    {
        $userId = $request->user() ? $request->user()->id : null;
        
        return AppNotification::whereNull('user_id')
            ->orWhere('user_id', $userId)
            ->latest()
            ->get();
    }

    public function doctors(Request $request)
    {
        $query = \App\Models\Doctor::whereHas('user', function($q) { $q->where('status', 'approved'); })
            ->whereNotNull('specialty')
            ->whereHas('services')
            ->whereHas('schedules')
            ->with(['user:id,name,name_en,name_ar,email,is_doctor', 'services' => fn ($q) => $q->where('is_active', true), 'schedules']);

        if ($request->has('specialty')) {
            $query->where('specialty', $request->specialty);
        }

        return $query->get();
    }

    public function doctor($id)
    {
        $doctor = \App\Models\Doctor::with(['user:id,name,name_en,name_ar,email,is_doctor', 'services' => fn ($q) => $q->where('is_active', true), 'schedules'])->findOrFail($id);
        return response()->json($doctor);
    }
}
