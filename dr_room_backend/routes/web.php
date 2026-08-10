<?php

use Illuminate\Support\Facades\Route;

// Locale route moved to bottom

use App\Http\Controllers\Web\StaffAuthController;
use App\Http\Controllers\Web\StaffPasswordResetController;
use App\Http\Controllers\Web\DoctorDashboardController;
use App\Http\Controllers\Web\DoctorAppointmentController;
use App\Http\Controllers\Web\DoctorPatientController;
use App\Http\Controllers\Web\DoctorEarningsController;
use App\Http\Controllers\Web\DoctorProfileController;
use App\Http\Middleware\IsDoctor;

use App\Http\Controllers\Web\NurseDashboardController;
use App\Http\Controllers\Web\NurseAppointmentController;
use App\Http\Controllers\Web\NursePatientController;
use App\Http\Controllers\Web\NurseEarningsController;
use App\Http\Controllers\Web\NurseProfileController;
use App\Http\Middleware\IsNurse;

// Unified Staff Auth Routes
Route::prefix('staff')->group(function () {
    Route::get('/', function () {
        return view('auth.landing');
    })->name('staff.landing');

    Route::get('/login', [StaffAuthController::class, 'showLogin'])->name('staff.login');
    Route::post('/login', [StaffAuthController::class, 'login']);
    
    Route::get('/register', [StaffAuthController::class, 'showRegister'])->name('staff.register');
    Route::post('/register', [StaffAuthController::class, 'register']);

    // Password reset
    Route::get('/forgot-password', [StaffPasswordResetController::class, 'showLinkRequest'])->name('password.request');
    Route::post('/forgot-password', [StaffPasswordResetController::class, 'sendLink'])->name('password.email');
    Route::get('/reset-password/{token}', [StaffPasswordResetController::class, 'showResetForm'])->name('password.reset');
    Route::post('/reset-password', [StaffPasswordResetController::class, 'reset'])->name('password.update');

    Route::post('/logout', [StaffAuthController::class, 'logout'])->name('staff.logout')->middleware('auth');
    
    Route::get('/waiting', [StaffAuthController::class, 'waiting'])->name('staff.waiting')->middleware('auth');
    Route::get('/status', [StaffAuthController::class, 'status'])->name('staff.status')->middleware('auth');
});

// Global API for Staff/Web
Route::post('/api/translate', [\App\Http\Controllers\Api\TranslateController::class, 'translate'])->name('api.translate')->middleware('auth');

// Doctor Dashboard Routes
Route::prefix('doctor')->middleware(['auth', IsDoctor::class])->group(function () {
    Route::middleware('doctor.profile.complete')->group(function () {
        Route::get('/dashboard', [DoctorDashboardController::class, 'index'])->name('doctor.dashboard');
        
        // Appointments
        Route::get('/appointments', [DoctorAppointmentController::class, 'index'])->name('doctor.appointments.index');
        Route::patch('/appointments/{appointment}/status', [DoctorAppointmentController::class, 'updateStatus'])->name('doctor.appointments.update_status');
        
        // Patients
        Route::get('/patients', [DoctorPatientController::class, 'index'])->name('doctor.patients.index');
        
        // Earnings
        Route::get('/earnings', [DoctorEarningsController::class, 'index'])->name('doctor.earnings.index');

        // Reviews
        Route::get('/reviews', [\App\Http\Controllers\Web\DoctorReviewController::class, 'index'])->name('doctor.reviews.index');
    });
    
    // Profile
    Route::get('/profile', [DoctorProfileController::class, 'index'])->name('doctor.profile.index');
    Route::put('/profile', [DoctorProfileController::class, 'update'])->name('doctor.profile.update');
    
    // Services
    Route::get('/services', [\App\Http\Controllers\Web\DoctorServiceController::class, 'index'])->name('doctor.services.index');
    Route::post('/services', [\App\Http\Controllers\Web\DoctorServiceController::class, 'store'])->name('doctor.services.store');
    Route::put('/services/{id}', [\App\Http\Controllers\Web\DoctorServiceController::class, 'update'])->name('doctor.services.update');
    Route::patch('/services/{id}/toggle', [\App\Http\Controllers\Web\DoctorServiceController::class, 'toggle'])->name('doctor.services.toggle');
    Route::delete('/services/{id}', [\App\Http\Controllers\Web\DoctorServiceController::class, 'destroy'])->name('doctor.services.destroy');

    // Schedules
    Route::get('/schedules', [\App\Http\Controllers\Web\DoctorScheduleController::class, 'index'])->name('doctor.schedules.index');
    Route::post('/schedules', [\App\Http\Controllers\Web\DoctorScheduleController::class, 'store'])->name('doctor.schedules.store');
    Route::put('/schedules/{id}', [\App\Http\Controllers\Web\DoctorScheduleController::class, 'update'])->name('doctor.schedules.update');
    Route::delete('/schedules/{id}', [\App\Http\Controllers\Web\DoctorScheduleController::class, 'destroy'])->name('doctor.schedules.destroy');

});

// Nurse Dashboard Routes
Route::prefix('nurse')->middleware(['auth', IsNurse::class])->group(function () {
    Route::get('/dashboard', [NurseDashboardController::class, 'index'])->name('nurse.dashboard');
    
    // Appointments
    Route::get('/appointments', [NurseAppointmentController::class, 'index'])->name('nurse.appointments.index');
    Route::patch('/appointments/{appointment}/status', [NurseAppointmentController::class, 'updateStatus'])->name('nurse.appointments.update_status');
    
    // Patients (Patient Care)
    Route::get('/patients', [NursePatientController::class, 'index'])->name('nurse.patients.index');
    
    // Earnings
    Route::get('/earnings', [NurseEarningsController::class, 'index'])->name('nurse.earnings.index');
    
    // Profile
    Route::get('/profile', [NurseProfileController::class, 'index'])->name('nurse.profile.index');
    Route::put('/profile', [NurseProfileController::class, 'update'])->name('nurse.profile.update');
    
    // New Feature Placeholders (Nurse)
    $nursePlaceholder = function ($title) {
        return view('shared.placeholder', ['layout' => 'nurse.layouts.app', 'title' => $title]);
    };
    
    // Patient Care sub-routes (converted to resource)
    Route::resource('/patient_cares', \App\Http\Controllers\Web\NursePatientCareController::class, ['as' => 'nurse']);
    
    // Appointments sub-routes
    Route::get('/appointments/confirm', fn() => $nursePlaceholder('دڵنیابوونەوە لە کات'))->name('nurse.appointments.confirm');
    Route::get('/appointments/prepare', fn() => $nursePlaceholder('ئامادەکردنی نەخۆش'))->name('nurse.appointments.prepare');
    
    // Communication
    Route::get('/communication', fn() => $nursePlaceholder('پەیوەندی'))->name('nurse.communication.index');
    Route::get('/communication/doctor', fn() => $nursePlaceholder('چات لەگەڵ دکتۆر'))->name('nurse.communication.doctor');
    Route::get('/communication/patient', fn() => $nursePlaceholder('چات لەگەڵ نەخۆش'))->name('nurse.communication.patient');
    
    // Reports
    Route::get('/reports', fn() => $nursePlaceholder('ڕاپۆرتەکان'))->name('nurse.reports.index');
    Route::get('/reports/progress', fn() => $nursePlaceholder('بەرەوپێشچوونی نەخۆش'))->name('nurse.reports.progress');
    
    // Profile sub-routes
    Route::get('/profile/schedule', [\App\Http\Controllers\Web\NurseScheduleController::class, 'index'])->name('nurse.profile.schedule');
});

// Lab Dashboard Routes
Route::prefix('lab')->middleware(['auth', \App\Http\Middleware\IsLab::class])->group(function () {
    
    // Profile
    Route::get('/profile', [\App\Http\Controllers\Web\LabProfileController::class, 'index'])->name('lab.profile.index');
    Route::put('/profile', [\App\Http\Controllers\Web\LabProfileController::class, 'update'])->name('lab.profile.update');

    Route::middleware('lab.profile.complete')->group(function () {
        Route::get('/dashboard', [\App\Http\Controllers\Web\LabDashboardController::class, 'index'])->name('lab.dashboard');
        
        // Patients
        Route::get('/patients', [\App\Http\Controllers\Web\LabPatientController::class, 'index'])->name('lab.patients.index');
        
        // Tests
        Route::resource('/tests', \App\Http\Controllers\Web\LabTestController::class, ['as' => 'lab']);
        
        // Results
        Route::resource('/results', \App\Http\Controllers\Web\LabResultController::class, ['as' => 'lab']);
        
        // Management
        Route::get('/management/approve', [\App\Http\Controllers\Web\LabManagementController::class, 'approve'])->name('lab.management.approve');
        Route::get('/management/complete', [\App\Http\Controllers\Web\LabManagementController::class, 'complete'])->name('lab.management.complete');
        Route::patch('/management/{result}/status', [\App\Http\Controllers\Web\LabManagementController::class, 'updateStatus'])->name('lab.management.status');

        $labPlaceholder = function ($title) {
            return view('shared.placeholder', ['layout' => 'lab.layouts.app', 'title' => $title]);
        };
        
        // Reports
        Route::get('/reports', fn() => $labPlaceholder('ڕاپۆرتەکان'))->name('lab.reports.index');
        
        // Communication
        Route::get('/communication', fn() => $labPlaceholder('پەیوەندی'))->name('lab.communication.index');
        
        // Profile sub-routes
        Route::get('/profile/staff', fn() => $labPlaceholder('ستافی تاقیگە'))->name('lab.profile.staff');
    });
});

// Pharmacy Dashboard Routes
Route::prefix('pharmacy')->middleware(['auth', \App\Http\Middleware\IsPharmacy::class])->group(function () {
    Route::get('/dashboard', [\App\Http\Controllers\Web\PharmacyDashboardController::class, 'index'])->name('pharmacy.dashboard');

    // Medications CRUD
    Route::resource('/medications', \App\Http\Controllers\Web\PharmacyMedicationController::class, [
        'as' => 'pharmacy'
    ]);
    
    // Offers CRUD
    Route::resource('/offers', \App\Http\Controllers\Web\PharmacyOfferController::class, [
        'as' => 'pharmacy'
    ]);
    
    // Orders
    Route::get('/orders', [\App\Http\Controllers\Web\PharmacyOrderController::class, 'index'])->name('pharmacy.orders.index');
    Route::get('/orders/{id}', [\App\Http\Controllers\Web\PharmacyOrderController::class, 'show'])->name('pharmacy.orders.show');
    Route::post('/orders/{id}/status', [\App\Http\Controllers\Web\PharmacyOrderController::class, 'updateStatus'])->name('pharmacy.orders.status');
    
    // Prescriptions
    Route::get('/prescriptions', [\App\Http\Controllers\Web\PharmacyPrescriptionController::class, 'index'])->name('pharmacy.prescriptions.index');
    Route::post('/prescriptions/{id}/dispense', [\App\Http\Controllers\Web\PharmacyPrescriptionController::class, 'dispense'])->name('pharmacy.prescriptions.dispense');
    
    // Customers
    Route::get('/customers', [\App\Http\Controllers\Web\PharmacyCustomerController::class, 'index'])->name('pharmacy.customers.index');
    
    // Earnings
    Route::get('/earnings', [\App\Http\Controllers\Web\PharmacyEarningsController::class, 'index'])->name('pharmacy.earnings.index');
    
    // Notifications
    Route::get('/notifications', [\App\Http\Controllers\Web\PharmacyNotificationController::class, 'index'])->name('pharmacy.notifications.index');
    
    // Profile
    Route::get('/profile', [\App\Http\Controllers\Web\PharmacyProfileController::class, 'index'])->name('pharmacy.profile.index');
    Route::post('/profile', [\App\Http\Controllers\Web\PharmacyProfileController::class, 'update'])->name('pharmacy.profile.update');
    
    // Settings
    Route::get('/settings', [\App\Http\Controllers\Web\PharmacySettingsController::class, 'index'])->name('pharmacy.settings.index');
    Route::post('/settings', [\App\Http\Controllers\Web\PharmacySettingsController::class, 'update'])->name('pharmacy.settings.update');
});

Route::get('/{locale?}', function ($locale = 'ckb') {
    if (!in_array($locale, ['en', 'ar', 'ckb'])) {
        abort(404);
    }
    app()->setLocale($locale);
    return view('welcome', ['locale' => $locale]);
});

