<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\AppController;
use App\Http\Controllers\Api\DoctorController;
use App\Http\Controllers\Api\AppointmentBookingController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\GlobalSearchController;
use App\Http\Controllers\Api\Admin\BannerController;
use App\Http\Controllers\Api\Admin\ArticleController;
use App\Http\Controllers\Api\Admin\NotificationController;
use App\Http\Controllers\Api\Admin\AppointmentController;
use App\Http\Controllers\Api\Admin\DashboardController;
use App\Http\Controllers\Api\Admin\AdminDoctorController;
use App\Http\Controllers\Api\Admin\AdminNurseController;
use App\Http\Controllers\Api\Admin\AdminUserController;
use App\Http\Controllers\Api\Admin\AdminLabController;
use App\Http\Controllers\Api\Admin\AdminPharmacyController;
use App\Http\Controllers\Api\Admin\AdminXRayController;

Route::post('/login', [AuthController::class, 'login']);
Route::post('/register', [AuthController::class, 'register']);
Route::post('/verify-otp', [AuthController::class, 'verifyOtp']);

// Public User App Routes
Route::get('/home', [AppController::class, 'home']);
Route::get('/banners', [AppController::class, 'banners']);
Route::get('/articles', [AppController::class, 'articles']);
Route::get('/notifications', [AppController::class, 'notifications']);
Route::get('/doctors', [AppController::class, 'doctors']);
Route::get('/doctors/{id}', [AppController::class, 'doctor']);
Route::get('/doctors/{id}/reviews', [\App\Http\Controllers\Api\DoctorReviewController::class, 'index']);
Route::get('/doctors/{id}/availability', [AppointmentBookingController::class, 'availability']);
Route::get('/global-search', [GlobalSearchController::class, 'search']);

// ─── GetBodySmart Medical Anatomy & Muscular System API ───────────
Route::get('/anatomy/systems', [\App\Http\Controllers\Api\AnatomyController::class, 'systems']);
Route::get('/anatomy/organs', [\App\Http\Controllers\Api\AnatomyController::class, 'organs']);

// ─── Emergency Reels API ──────────────────────────────────────────────
Route::get('/emergency-reels', [\App\Http\Controllers\Api\EmergencyReelController::class, 'index']);

// ─── Pharmacy Mobile App API ──────────────────────────────────────────────
Route::get('/pharmacies', [\App\Http\Controllers\Api\PharmacyApiController::class, 'index']);
Route::get('/pharmacies/{id}/medications', [\App\Http\Controllers\Api\PharmacyApiController::class, 'medications']);
Route::get('/pharmacies/{id}/offers', [\App\Http\Controllers\Api\PharmacyApiController::class, 'offers']);

// ─── Lab Mobile App API ─────────────────────────────────────────────────
Route::get('/labs', [\App\Http\Controllers\Api\LabApiController::class, 'index']);
Route::get('/labs/{id}', [\App\Http\Controllers\Api\LabApiController::class, 'show']);

// ─── Patient: Orders (Labs, Pharmacy, Nursing) ──────────────────────────
Route::post('/orders', [OrderController::class, 'store']); // Moved outside for testing Without Login

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/user', [AuthController::class, 'user']);
    Route::delete('/user', [AuthController::class, 'destroy']);

    // ─── Patient: Appointment Booking ──────────────────────────────────────
    Route::get('/appointments', [AppointmentBookingController::class, 'index']);
    Route::post('/appointments', [AppointmentBookingController::class, 'store']);
    Route::delete('/appointments/{id}', [AppointmentBookingController::class, 'destroy']);

    // ─── Patient: Doctor Reviews ────────────────────────────────────────────
    Route::post('/doctors/{id}/reviews', [\App\Http\Controllers\Api\DoctorReviewController::class, 'store']);

    // ─── Patient: Orders (Labs, Pharmacy, Nursing) ──────────────────────────
    Route::get('/orders', [OrderController::class, 'index']);

    // ─── Patient: Lab and Nurse Records ─────────────────────────────────────
    Route::get('/lab-results', [\App\Http\Controllers\Api\PatientRecordController::class, 'labResults']);
    Route::get('/nurse-cares', [\App\Http\Controllers\Api\PatientRecordController::class, 'nurseCares']);

    // ─── Patient: AI Pill Scanner ───────────────────────────────────────────
    Route::post('/pills/identify', [\App\Http\Controllers\Api\PillIdentifierController::class, 'identify']);

    // ─── Doctor: Dashboard API ─────────────────────────────────────────────
    Route::middleware([\App\Http\Middleware\IsDoctor::class])->prefix('doctor')->group(function () {
        Route::get('/profile', [DoctorController::class, 'profile']);
        Route::put('/profile', [DoctorController::class, 'updateProfile']);
        Route::get('/stats', [DoctorController::class, 'stats']);
        Route::get('/appointments', [DoctorController::class, 'appointments']);
        Route::patch('/appointments/{id}/status', [DoctorController::class, 'updateAppointmentStatus']);
        Route::get('/patients', [DoctorController::class, 'patients']);
        
        // Time Offs
        Route::get('/time-offs', [\App\Http\Controllers\Api\DoctorTimeOffController::class, 'index']);
        Route::post('/time-offs', [\App\Http\Controllers\Api\DoctorTimeOffController::class, 'store']);
        Route::delete('/time-offs/{id}', [\App\Http\Controllers\Api\DoctorTimeOffController::class, 'destroy']);
    });

    // ─── Admin Routes ───────────────────────────────────────────────────────
    Route::middleware([\App\Http\Middleware\IsAdmin::class])->prefix('admin')->group(function () {
        Route::get('/dashboard', [DashboardController::class, 'index']);
        Route::apiResource('banners', BannerController::class);
        Route::apiResource('articles', ArticleController::class);
        Route::apiResource('notifications', NotificationController::class);
        Route::get('/appointments', [AppointmentController::class, 'index']);

        // Orders
        Route::get('/orders', [\App\Http\Controllers\Api\Admin\AdminOrderController::class, 'index']);
        Route::patch('/orders/{id}/assign-nurse', [\App\Http\Controllers\Api\Admin\AdminOrderController::class, 'assignNurse']);
        Route::patch('/orders/{id}/status', [\App\Http\Controllers\Api\Admin\AdminOrderController::class, 'updateStatus']);

        // Doctors
        Route::get('/doctors', [\App\Http\Controllers\Api\Admin\AdminDoctorController::class, 'index']);
        Route::patch('/doctors/{id}/approve', [\App\Http\Controllers\Api\Admin\AdminDoctorController::class, 'approve']);
        Route::patch('/doctors/{id}/reject', [\App\Http\Controllers\Api\Admin\AdminDoctorController::class, 'reject']);
        Route::delete('/doctors/{id}', [\App\Http\Controllers\Api\Admin\AdminDoctorController::class, 'destroy']);

        // Nurses
        Route::get('/nurses', [\App\Http\Controllers\Api\Admin\AdminNurseController::class, 'index']);
        Route::patch('/nurses/{id}/approve', [\App\Http\Controllers\Api\Admin\AdminNurseController::class, 'approve']);
        Route::patch('/nurses/{id}/reject', [\App\Http\Controllers\Api\Admin\AdminNurseController::class, 'reject']);
        Route::delete('/nurses/{id}', [\App\Http\Controllers\Api\Admin\AdminNurseController::class, 'destroy']);

        // Labs
        Route::get('/labs', [\App\Http\Controllers\Api\Admin\AdminLabController::class, 'index']);
        Route::patch('/labs/{id}/approve', [\App\Http\Controllers\Api\Admin\AdminLabController::class, 'approve']);
        Route::patch('/labs/{id}/reject', [\App\Http\Controllers\Api\Admin\AdminLabController::class, 'reject']);
        Route::delete('/labs/{id}', [\App\Http\Controllers\Api\Admin\AdminLabController::class, 'destroy']);

        // Pharmacies
        Route::get('/pharmacies', [\App\Http\Controllers\Api\Admin\AdminPharmacyController::class, 'index']);
        Route::patch('/pharmacies/{id}/approve', [\App\Http\Controllers\Api\Admin\AdminPharmacyController::class, 'approve']);
        Route::patch('/pharmacies/{id}/reject', [\App\Http\Controllers\Api\Admin\AdminPharmacyController::class, 'reject']);
        Route::delete('/pharmacies/{id}', [\App\Http\Controllers\Api\Admin\AdminPharmacyController::class, 'destroy']);

        // X-Rays
        Route::get('/xrays', [\App\Http\Controllers\Api\Admin\AdminXRayController::class, 'index']);
        Route::patch('/xrays/{id}/approve', [\App\Http\Controllers\Api\Admin\AdminXRayController::class, 'approve']);
        Route::patch('/xrays/{id}/reject', [\App\Http\Controllers\Api\Admin\AdminXRayController::class, 'reject']);
        Route::delete('/xrays/{id}', [\App\Http\Controllers\Api\Admin\AdminXRayController::class, 'destroy']);

        // Users
        Route::get('/users', [\App\Http\Controllers\Api\Admin\AdminUserController::class, 'index']);
        Route::patch('/users/{id}/block', [\App\Http\Controllers\Api\Admin\AdminUserController::class, 'block']);
        Route::patch('/users/{id}/unblock', [\App\Http\Controllers\Api\Admin\AdminUserController::class, 'unblock']);
        Route::post('/add-admin', [\App\Http\Controllers\Api\Admin\AdminUserController::class, 'storeAdmin']);
    });
});
