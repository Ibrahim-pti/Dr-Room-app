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
Route::post('/login-otp', [AuthController::class, 'loginWithOtp']);
Route::post('/register', [AuthController::class, 'register']);
Route::post('/verify-otp', [AuthController::class, 'verifyOtp']);
Route::post('/resend-otp', [AuthController::class, 'resendOtp']);
Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);
Route::post('/reset-password', [AuthController::class, 'resetPassword']);
Route::post('/translate', [\App\Http\Controllers\Api\TranslateController::class, 'translate']);

// App Version & Force Update Config
Route::get('/app-version', function () {
    return response()->json([
        'latest_version' => '1.0.2',
        'min_required_version' => '1.0.0',
        'force_update' => false,
        'update_title' => 'وەشانی نوێ بەردەستە',
        'update_message' => 'تکایە ئەپەکە نوێبکەرەوە بۆ بەدەستهێنانی نوێترین تایبەتمەندی و خزمەتگوزارییە تەندروستییەکان.',
        'android_store_url' => 'https://play.google.com/store/apps/details?id=com.drroom.app',
        'ios_store_url' => 'https://apps.apple.com/app/id6400000000',
    ]);
});

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

// ─── Medicine reference info (openFDA — free, no API key) ─────────────
Route::get('/medicines/lookup', [\App\Http\Controllers\Api\MedicineInfoController::class, 'lookup']);

// ─── GetBodySmart Medical Anatomy & Muscular System API ───────────
Route::get('/anatomy/systems', [\App\Http\Controllers\Api\AnatomyController::class, 'systems']);
Route::get('/anatomy/organs', [\App\Http\Controllers\Api\AnatomyController::class, 'organs']);

// ─── Service Categories (nursing, lab, pharmacy, doctor, first aid) ───
Route::get('/service-categories', function (\Illuminate\Http\Request $request) {
    return \App\Models\ServiceCategory::active()
        ->when($request->filled('scope'), fn ($q) => $q->ofScope($request->scope))
        ->orderBy('sort_order')
        ->orderBy('name')
        ->get();
});

// ─── Emergency SOS & Contacts API ───────────────────────────────────
Route::get('/emergency-contacts', [\App\Http\Controllers\Api\EmergencyContactController::class, 'index']);
Route::get('/emergency-reels', [\App\Http\Controllers\Api\EmergencyReelController::class, 'index']);

// ─── Pharmacy Mobile App API ──────────────────────────────────────────────
Route::get('/pharmacies/categories', [\App\Http\Controllers\Api\PharmacyApiController::class, 'categories']);
Route::get('/medications/categories', [\App\Http\Controllers\Api\PharmacyApiController::class, 'categories']);
Route::get('/pharmacies', [\App\Http\Controllers\Api\PharmacyApiController::class, 'index']);
Route::get('/pharmacies/{id}', [\App\Http\Controllers\Api\PharmacyApiController::class, 'show']);
Route::get('/pharmacies/{id}/medications', [\App\Http\Controllers\Api\PharmacyApiController::class, 'medications']);
Route::get('/pharmacies/{id}/offers', [\App\Http\Controllers\Api\PharmacyApiController::class, 'offers']);
Route::get('/pharmacies/{id}/reviews', [\App\Http\Controllers\Api\PharmacyApiController::class, 'reviews']);
Route::post('/pharmacies/{id}/reviews', [\App\Http\Controllers\Api\PharmacyApiController::class, 'storeReview']);

// ─── Lab Mobile App API ─────────────────────────────────────────────────
Route::get('/labs', [\App\Http\Controllers\Api\LabApiController::class, 'index']);
Route::get('/labs/tests', [\App\Http\Controllers\Api\LabApiController::class, 'allTests']);
Route::get('/labs/packages', [\App\Http\Controllers\Api\LabApiController::class, 'allPackages']);
Route::get('/labs/staff', [\App\Http\Controllers\Api\LabApiController::class, 'staff']);
Route::get('/labs/{id}', [\App\Http\Controllers\Api\LabApiController::class, 'show']);
Route::get('/labs/{id}/reviews', [\App\Http\Controllers\Api\LabReviewController::class, 'index']);
Route::post('/upload/prescription', [\App\Http\Controllers\Api\OrderController::class, 'uploadPrescription']);

// ─── Nursing Services ─────────────────────────────────────────────────
Route::get('/nurses', [\App\Http\Controllers\Api\NurseApiController::class, 'index']);
Route::get('/nurses/{id}', [\App\Http\Controllers\Api\NurseApiController::class, 'show']);
Route::get('/nurses/{id}/reviews', [\App\Http\Controllers\Api\NurseReviewController::class, 'index']);
Route::get('/nursing/services', [\App\Http\Controllers\Api\NurseApiController::class, 'getServices']);
Route::get('/nursing/packages', [\App\Http\Controllers\Api\NurseApiController::class, 'packages']);

// ─── Push notification device registration ────────────────────────────
// Unauthenticated too: a guest device registers on first launch and the row
// is claimed once they sign in.
Route::post('/device-tokens', [\App\Http\Controllers\Api\DeviceTokenController::class, 'store']);
Route::delete('/device-tokens', [\App\Http\Controllers\Api\DeviceTokenController::class, 'destroy']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/user', [AuthController::class, 'user']);
    Route::match(['put', 'post'], '/user', [AuthController::class, 'updateProfile']);
    Route::delete('/user', [AuthController::class, 'destroy']);

    // ─── Patient: Notifications ───────────────────────────────────────────
    Route::post('/notifications/mark-read', [AppController::class, 'markNotificationsRead']);
    Route::delete('/notifications/{id}', [AppController::class, 'deleteNotification']);

    // ─── Patient: Appointment Booking ──────────────────────────────────────
    Route::get('/appointments', [AppointmentBookingController::class, 'index']);
    Route::post('/appointments', [AppointmentBookingController::class, 'store']);
    Route::delete('/appointments/{id}', [AppointmentBookingController::class, 'destroy']);

    // ─── Patient: Doctor, Lab, Nurse Reviews ───────────────────────────────
    Route::post('/doctors/{id}/reviews', [\App\Http\Controllers\Api\DoctorReviewController::class, 'store']);
    Route::post('/labs/{id}/reviews', [\App\Http\Controllers\Api\LabReviewController::class, 'store']);
    Route::post('/nurses/{id}/reviews', [\App\Http\Controllers\Api\NurseReviewController::class, 'store']);

    // ─── Patient: Orders (Labs, Pharmacy, Nursing) ──────────────────────────
    Route::post('/nursing/book', [\App\Http\Controllers\Api\NurseApiController::class, 'book']);
    Route::get('/orders', [OrderController::class, 'index']);
    Route::get('/orders/{id}', [OrderController::class, 'show']);
    Route::post('/orders', [OrderController::class, 'store']);

    // ─── Patient: Lab and Nurse Records ─────────────────────────────────────
    Route::get('/lab-results', [\App\Http\Controllers\Api\PatientRecordController::class, 'labResults']);
    Route::get('/nurse-cares', [\App\Http\Controllers\Api\PatientRecordController::class, 'nurseCares']);

    // ─── Patient: AI Pill Scanner ───────────────────────────────────────────
    Route::post('/pills/identify', [\App\Http\Controllers\Api\PillIdentifierController::class, 'identify']);

    // ─── Patient: Payments ─────────────────────────────────────────────────
    Route::post('/payments/create-intent', [\App\Http\Controllers\Api\PaymentController::class, 'createIntent']);
    Route::post('/payments/confirm', [\App\Http\Controllers\Api\PaymentController::class, 'confirm']);
    Route::get('/payments/history', [\App\Http\Controllers\Api\PaymentController::class, 'history']);
    Route::get('/payments/transaction/{id}', [\App\Http\Controllers\Api\PaymentController::class, 'show']);
    Route::get('/payments/methods', [\App\Http\Controllers\Api\PaymentController::class, 'methods']);
    Route::post('/payments/methods', [\App\Http\Controllers\Api\PaymentController::class, 'storeMethod']);
    Route::delete('/payments/methods/{id}', [\App\Http\Controllers\Api\PaymentController::class, 'deleteMethod']);
    Route::get('/payments/receipt/{id}', [\App\Http\Controllers\Api\PaymentController::class, 'receipt']);

    // ─── Patient: Coupons & Discounts ──────────────────────────────────────
    Route::post('/coupons/validate', [\App\Http\Controllers\Api\CouponController::class, 'validateCoupon']);

    // ─── Patient: Support & Tickets ─────────────────────────────────────────
    Route::get('/support-tickets', [\App\Http\Controllers\Api\SupportTicketController::class, 'index']);
    Route::post('/support-tickets', [\App\Http\Controllers\Api\SupportTicketController::class, 'store']);
    Route::get('/support-tickets/{id}', [\App\Http\Controllers\Api\SupportTicketController::class, 'show']);
    Route::post('/support-tickets/{id}/reply', [\App\Http\Controllers\Api\SupportTicketController::class, 'reply']);

    // ─── Patient: Comprehensive EMR ─────────────────────────────────────────
    Route::get('/patient/emr', [\App\Http\Controllers\Api\PatientEmrController::class, 'show']);
    Route::post('/patient/emr', [\App\Http\Controllers\Api\PatientEmrController::class, 'update']);
    Route::get('/patients/{id}/emr', [\App\Http\Controllers\Api\PatientEmrController::class, 'patientEmr']);

    // ─── Patient: Loyalty Program & Points ──────────────────────────────────
    Route::get('/loyalty/balance', [\App\Http\Controllers\Api\LoyaltyController::class, 'balance']);
    Route::get('/loyalty/history', [\App\Http\Controllers\Api\LoyaltyController::class, 'history']);
    Route::post('/loyalty/redeem', [\App\Http\Controllers\Api\LoyaltyController::class, 'redeem']);

    // ─── Staff / Nurse Schedule & Collision Check ───────────────────────────
    Route::get('/nurse/schedule', [\App\Http\Controllers\Api\NurseScheduleApiController::class, 'getSchedule']);
    Route::post('/nurse/schedule', [\App\Http\Controllers\Api\NurseScheduleApiController::class, 'updateSchedule']);
    Route::post('/nurse/check-collision', [\App\Http\Controllers\Api\NurseScheduleApiController::class, 'checkCollision']);

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
    Route::middleware('staff')->prefix('admin')->group(function () {
        Route::get('/dashboard', [DashboardController::class, 'index']);

        // Who am I and what may I touch — the admin app builds its menu from this.
        Route::get('/me', function (\Illuminate\Http\Request $request) {
            $user = $request->user();
            return response()->json([
                'id'          => $user->id,
                'name'        => $user->name,
                'email'       => $user->email,
                'role'        => $user->role,
                'role_label'  => \App\Support\Permissions::ROLE_LABELS[$user->role] ?? $user->role,
                'permissions' => $user->permission_list,
            ]);
        });

        // ── Staff accounts, roles and the audit trail ──────────────────────
        Route::middleware('permission:manage_staff')->group(function () {
            Route::get('/staff/meta', [\App\Http\Controllers\Api\Admin\StaffController::class, 'meta']);
            Route::get('/staff', [\App\Http\Controllers\Api\Admin\StaffController::class, 'index']);
            Route::post('/staff', [\App\Http\Controllers\Api\Admin\StaffController::class, 'store']);
            Route::put('/staff/{id}', [\App\Http\Controllers\Api\Admin\StaffController::class, 'update']);
            Route::delete('/staff/{id}', [\App\Http\Controllers\Api\Admin\StaffController::class, 'destroy']);
        });

        Route::middleware('permission:view_logs')
            ->get('/activity-logs', [\App\Http\Controllers\Api\Admin\ActivityLogController::class, 'index']);

        // ── Review moderation ──────────────────────────────────────────────
        Route::middleware('permission:manage_reviews')->group(function () {
            Route::get('/reviews', [\App\Http\Controllers\Api\Admin\AdminReviewController::class, 'index']);
            Route::patch('/reviews/{type}/{id}/hide', [\App\Http\Controllers\Api\Admin\AdminReviewController::class, 'hide']);
            Route::patch('/reviews/{type}/{id}/restore', [\App\Http\Controllers\Api\Admin\AdminReviewController::class, 'restore']);
            Route::delete('/reviews/{type}/{id}', [\App\Http\Controllers\Api\Admin\AdminReviewController::class, 'destroy']);
        });

        // ── Service categories ─────────────────────────────────────────────
        Route::middleware('permission:manage_categories')->group(function () {
            Route::get('/service-categories/scopes', [\App\Http\Controllers\Api\Admin\ServiceCategoryController::class, 'scopes']);
            Route::post('/service-categories/reorder', [\App\Http\Controllers\Api\Admin\ServiceCategoryController::class, 'reorder']);
            Route::get('/service-categories', [\App\Http\Controllers\Api\Admin\ServiceCategoryController::class, 'index']);
            Route::post('/service-categories', [\App\Http\Controllers\Api\Admin\ServiceCategoryController::class, 'store']);
            Route::put('/service-categories/{id}', [\App\Http\Controllers\Api\Admin\ServiceCategoryController::class, 'update']);
            Route::delete('/service-categories/{id}', [\App\Http\Controllers\Api\Admin\ServiceCategoryController::class, 'destroy']);
        });

        // ── Payments and revenue ───────────────────────────────────────────
        Route::middleware('permission:view_payments')->group(function () {
            Route::get('/transactions/summary', [\App\Http\Controllers\Api\Admin\AdminTransactionController::class, 'summary']);
            Route::get('/transactions/statement', [\App\Http\Controllers\Api\Admin\AdminTransactionController::class, 'statement']);
            Route::get('/transactions/providers', [\App\Http\Controllers\Api\Admin\AdminTransactionController::class, 'providers']);
            Route::get('/transactions', [\App\Http\Controllers\Api\Admin\AdminTransactionController::class, 'index']);
            Route::patch('/transactions/{id}/status', [\App\Http\Controllers\Api\Admin\AdminTransactionController::class, 'updateStatus']);
        });

        Route::middleware('permission:manage_content')->group(function () {
            Route::apiResource('banners', BannerController::class);
            Route::apiResource('articles', ArticleController::class);
            Route::apiResource('notifications', NotificationController::class);

            // Emergency Contacts (SOS)
            Route::get('/emergency-contacts', [\App\Http\Controllers\Api\EmergencyContactController::class, 'adminIndex']);
            Route::post('/emergency-contacts', [\App\Http\Controllers\Api\EmergencyContactController::class, 'store']);
            Route::put('/emergency-contacts/{id}', [\App\Http\Controllers\Api\EmergencyContactController::class, 'update']);
            Route::patch('/emergency-contacts/{id}/toggle', [\App\Http\Controllers\Api\EmergencyContactController::class, 'toggle']);
            Route::delete('/emergency-contacts/{id}', [\App\Http\Controllers\Api\EmergencyContactController::class, 'destroy']);
        });

        Route::middleware('permission:manage_orders')
            ->get('/appointments', [AppointmentController::class, 'index']);

        // Orders
        Route::middleware('permission:manage_orders')->group(function () {
        Route::get('/orders', [\App\Http\Controllers\Api\Admin\AdminOrderController::class, 'index']);
        Route::patch('/orders/{id}/assign-nurse', [\App\Http\Controllers\Api\Admin\AdminOrderController::class, 'assignNurse']);
        Route::patch('/orders/{id}/assign-pharmacy', [\App\Http\Controllers\Api\Admin\AdminOrderController::class, 'assignPharmacy']);
        Route::patch('/orders/{id}/status', [\App\Http\Controllers\Api\Admin\AdminOrderController::class, 'updateStatus']);
        Route::delete('/orders/{id}', [\App\Http\Controllers\Api\Admin\AdminOrderController::class, 'destroy']);
        });

        // Providers: doctors, nurses, labs, pharmacies, x-rays
        Route::middleware('permission:manage_providers')->group(function () {

        // Doctors
        Route::get('/doctors', [\App\Http\Controllers\Api\Admin\AdminDoctorController::class, 'index']);
        Route::patch('/doctors/{id}/approve', [\App\Http\Controllers\Api\Admin\AdminDoctorController::class, 'approve']);
        Route::patch('/doctors/{id}/reject', [\App\Http\Controllers\Api\Admin\AdminDoctorController::class, 'reject']);
        Route::delete('/doctors/{id}', [\App\Http\Controllers\Api\Admin\AdminDoctorController::class, 'destroy']);

        // Nurses
        Route::get('/nurses', [\App\Http\Controllers\Api\Admin\AdminNurseController::class, 'index']);
        Route::post('/nurses', [\App\Http\Controllers\Api\Admin\AdminNurseController::class, 'store']);
        Route::put('/nurses/{id}', [\App\Http\Controllers\Api\Admin\AdminNurseController::class, 'update']);
        Route::patch('/nurses/{id}/approve', [\App\Http\Controllers\Api\Admin\AdminNurseController::class, 'approve']);
        Route::patch('/nurses/{id}/reject', [\App\Http\Controllers\Api\Admin\AdminNurseController::class, 'reject']);
        Route::delete('/nurses/{id}', [\App\Http\Controllers\Api\Admin\AdminNurseController::class, 'destroy']);

        // Labs
        Route::get('/labs', [\App\Http\Controllers\Api\Admin\AdminLabController::class, 'index']);
        Route::post('/labs', [\App\Http\Controllers\Api\Admin\AdminLabController::class, 'store']);
        Route::put('/labs/{id}', [\App\Http\Controllers\Api\Admin\AdminLabController::class, 'update']);
        Route::patch('/labs/{id}/approve', [\App\Http\Controllers\Api\Admin\AdminLabController::class, 'approve']);
        Route::patch('/labs/{id}/reject', [\App\Http\Controllers\Api\Admin\AdminLabController::class, 'reject']);
        Route::delete('/labs/{id}', [\App\Http\Controllers\Api\Admin\AdminLabController::class, 'destroy']);

        // Pharmacies
        Route::get('/pharmacies', [\App\Http\Controllers\Api\Admin\AdminPharmacyController::class, 'index']);
        Route::post('/pharmacies', [\App\Http\Controllers\Api\Admin\AdminPharmacyController::class, 'store']);
        Route::put('/pharmacies/{id}', [\App\Http\Controllers\Api\Admin\AdminPharmacyController::class, 'update']);
        Route::patch('/pharmacies/{id}/approve', [\App\Http\Controllers\Api\Admin\AdminPharmacyController::class, 'approve']);
        Route::patch('/pharmacies/{id}/reject', [\App\Http\Controllers\Api\Admin\AdminPharmacyController::class, 'reject']);
        Route::delete('/pharmacies/{id}', [\App\Http\Controllers\Api\Admin\AdminPharmacyController::class, 'destroy']);

        // X-Rays
        Route::get('/xrays', [\App\Http\Controllers\Api\Admin\AdminXRayController::class, 'index']);
        Route::post('/xrays', [\App\Http\Controllers\Api\Admin\AdminXRayController::class, 'store']);
        Route::put('/xrays/{id}', [\App\Http\Controllers\Api\Admin\AdminXRayController::class, 'update']);
        Route::patch('/xrays/{id}/approve', [\App\Http\Controllers\Api\Admin\AdminXRayController::class, 'approve']);
        Route::patch('/xrays/{id}/reject', [\App\Http\Controllers\Api\Admin\AdminXRayController::class, 'reject']);
        Route::delete('/xrays/{id}', [\App\Http\Controllers\Api\Admin\AdminXRayController::class, 'destroy']);

        });

        // Users
        Route::middleware('permission:manage_users')->group(function () {
            Route::get('/users', [\App\Http\Controllers\Api\Admin\AdminUserController::class, 'index']);
            Route::put('/users/{id}', [\App\Http\Controllers\Api\Admin\AdminUserController::class, 'update']);
            Route::delete('/users/{id}', [\App\Http\Controllers\Api\Admin\AdminUserController::class, 'destroy']);
            Route::patch('/users/{id}/block', [\App\Http\Controllers\Api\Admin\AdminUserController::class, 'block']);
            Route::patch('/users/{id}/unblock', [\App\Http\Controllers\Api\Admin\AdminUserController::class, 'unblock']);
        });

        // ─── Coupons Management ───────────────────────────────────────────
        Route::get('/coupons', [\App\Http\Controllers\Api\Admin\CouponController::class, 'index']);
        Route::post('/coupons', [\App\Http\Controllers\Api\Admin\CouponController::class, 'store']);
        Route::put('/coupons/{id}', [\App\Http\Controllers\Api\Admin\CouponController::class, 'update']);
        Route::patch('/coupons/{id}/toggle', [\App\Http\Controllers\Api\Admin\CouponController::class, 'toggleStatus']);
        Route::delete('/coupons/{id}', [\App\Http\Controllers\Api\Admin\CouponController::class, 'destroy']);

        // ─── Support Tickets Management ───────────────────────────────────
        Route::get('/tickets', [\App\Http\Controllers\Api\Admin\AdminTicketController::class, 'index']);
        Route::get('/tickets/{id}', [\App\Http\Controllers\Api\Admin\AdminTicketController::class, 'show']);
        Route::post('/tickets/{id}/reply', [\App\Http\Controllers\Api\Admin\AdminTicketController::class, 'reply']);
        Route::patch('/tickets/{id}/status', [\App\Http\Controllers\Api\Admin\AdminTicketController::class, 'updateStatus']);
        Route::delete('/tickets/{id}', [\App\Http\Controllers\Api\Admin\AdminTicketController::class, 'destroy']);

        // ─── Commission Management ─────────────────────────────────────────
        Route::get('/commission/settings', [\App\Http\Controllers\Api\Admin\CommissionController::class, 'settings']);
        Route::post('/commission/settings', [\App\Http\Controllers\Api\Admin\CommissionController::class, 'updateSettings']);
        Route::get('/commission/summary', [\App\Http\Controllers\Api\Admin\CommissionController::class, 'summary']);

        // ─── Expenses & Budget Management ──────────────────────────────────
        Route::get('/expenses', [\App\Http\Controllers\Api\Admin\AdminExpenseController::class, 'index']);
        Route::post('/expenses', [\App\Http\Controllers\Api\Admin\AdminExpenseController::class, 'store']);
        Route::put('/expenses/{id}', [\App\Http\Controllers\Api\Admin\AdminExpenseController::class, 'update']);
        Route::delete('/expenses/{id}', [\App\Http\Controllers\Api\Admin\AdminExpenseController::class, 'destroy']);
        Route::get('/expenses/summary', [\App\Http\Controllers\Api\Admin\AdminExpenseController::class, 'summary']);

        // ─── Lab Results Monitor ───────────────────────────────────────────
        Route::get('/lab-results', [\App\Http\Controllers\Api\Admin\AdminLabResultController::class, 'index']);
        Route::get('/lab-results/{id}', [\App\Http\Controllers\Api\Admin\AdminLabResultController::class, 'show']);
        Route::patch('/lab-results/{id}/verify', [\App\Http\Controllers\Api\Admin\AdminLabResultController::class, 'verify']);

        // ─── Loyalty Program Admin ─────────────────────────────────────────
        Route::get('/loyalty/stats', [\App\Http\Controllers\Api\Admin\AdminLoyaltyController::class, 'stats']);
        Route::post('/loyalty/settings', [\App\Http\Controllers\Api\Admin\AdminLoyaltyController::class, 'updateSettings']);

        // ─── Advanced Analytics & Categories ───────────────────────────────
        Route::get('/analytics/overview', [\App\Http\Controllers\Api\Admin\AdminAnalyticsController::class, 'overview']);

        // ─── Report Branding & Settings ────────────────────────────────────
        Route::get('/report-settings', [\App\Http\Controllers\Api\Admin\ReportSettingsController::class, 'index']);
        Route::post('/report-settings', [\App\Http\Controllers\Api\Admin\ReportSettingsController::class, 'update']);

        Route::middleware('permission:manage_staff')
            ->post('/add-admin', [\App\Http\Controllers\Api\Admin\AdminUserController::class, 'storeAdmin']);
    });
});
