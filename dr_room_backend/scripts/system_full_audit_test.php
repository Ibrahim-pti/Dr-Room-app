<?php

require __DIR__ . '/../vendor/autoload.php';
$app = require_once __DIR__ . '/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\User;
use App\Models\Lab;
use App\Models\Nurse;
use App\Models\Doctor;
use App\Models\Pharmacy;
use App\Models\Category;
use App\Models\ServiceCategory;
use App\Models\Transaction;
use App\Models\Order;
use App\Models\Appointment;
use Illuminate\Support\Facades\Hash;
use Illuminate\Http\Request;

echo "========================================================\n";
echo "🏥 DR. ROOM SYSTEM-WIDE COMPREHENSIVE AUDIT & TEST SUITE\n";
echo "========================================================\n\n";

$passCount = 0;
$failCount = 0;

function assertTest($name, $condition, $details = '') {
    global $passCount, $failCount;
    if ($condition) {
        echo "  ✅ [PASS] $name\n";
        $passCount++;
        return true;
    } else {
        echo "  ❌ [FAIL] $name: $details\n";
        $failCount++;
        return false;
    }
}

function sendReq($uri, $method = 'GET', $params = [], $token = null) {
    global $app;
    app('auth')->forgetGuards();
    $request = Request::create($uri, $method, $params);
    $request->headers->set('Accept', 'application/json');
    if ($token) {
        $request->headers->set('Authorization', 'Bearer ' . $token);
    }
    return $app->handle($request);
}

// ----------------------------------------------------
// SECTION 1: TRANSLATIONS & LOCALIZATION AUDIT
// ----------------------------------------------------
echo "\n--- [1] TRANSLATIONS & LOCALIZATION INTEGRITY ---\n";

$translationFiles = [
    'Flutter ckb' => __DIR__ . '/../../assets/translations/ckb.json',
    'Flutter ar'  => __DIR__ . '/../../assets/translations/ar.json',
    'Flutter en'  => __DIR__ . '/../../assets/translations/en.json',
    'Flutter kmr' => __DIR__ . '/../../assets/translations/kmr.json',
];

$parsedTranslations = [];
foreach ($translationFiles as $label => $path) {
    if (!file_exists($path)) {
        assertTest("File exists: $label", false, "Path not found: $path");
        continue;
    }
    $raw = file_get_contents($path);
    $data = json_decode($raw, true);
    $isValid = json_last_error() === JSON_ERROR_NONE && is_array($data);
    assertTest("JSON Valid: $label (" . count($data ?? []) . " keys)", $isValid, json_last_error_msg());
    if ($isValid) {
        $parsedTranslations[$label] = $data;
    }
}

// Compare key completeness across languages
if (isset($parsedTranslations['Flutter en'])) {
    $enKeys = array_keys($parsedTranslations['Flutter en']);
    foreach (['Flutter ckb', 'Flutter ar', 'Flutter kmr'] as $lang) {
        if (isset($parsedTranslations[$lang])) {
            $langKeys = array_keys($parsedTranslations[$lang]);
            $missing = array_diff($enKeys, $langKeys);
            $completeness = round(((count($enKeys) - count($missing)) / max(1, count($enKeys))) * 100, 1);
            assertTest("Completeness $lang vs en ($completeness%)", count($missing) === 0, count($missing) . " missing keys");
        }
    }
}

// Laravel landing translations
$laravelLangFiles = [
    'Landing ckb' => __DIR__ . '/../lang/ckb/landing.php',
    'Landing ar'  => __DIR__ . '/../lang/ar/landing.php',
    'Landing en'  => __DIR__ . '/../lang/en/landing.php',
    'Landing kmr' => __DIR__ . '/../lang/kmr/landing.php',
];

foreach ($laravelLangFiles as $label => $path) {
    if (file_exists($path)) {
        $data = include $path;
        assertTest("Laravel $label (" . count($data ?? []) . " keys)", is_array($data) && count($data) > 10);
    } else {
        assertTest("Laravel $label exists", false, "Not found");
    }
}

// ----------------------------------------------------
// SECTION 2: DATABASE & MODELS INTEGRITY
// ----------------------------------------------------
echo "\n--- [2] DATABASE MODELS & CORE DATA INTEGRITY ---\n";

$admin = User::where('role', 'admin')->first();
assertTest("Admin User exists", $admin !== null, "No admin user found");

$labsCount = User::where('role', 'lab')->where('status', 'approved')->count();
assertTest("Approved Labs in DB: $labsCount", $labsCount >= 5, "Fewer than 5 labs");

$nursesCount = User::where('role', 'nurse')->where('status', 'approved')->count();
assertTest("Approved Nurses in DB: $nursesCount", $nursesCount >= 1, "No approved nurses");

$doctorsCount = User::where('role', 'doctor')->where('status', 'approved')->count();
assertTest("Approved Doctors in DB: $doctorsCount", $doctorsCount >= 1, "No approved doctors");

$pharmaciesCount = User::where('role', 'pharmacy')->where('status', 'approved')->count();
assertTest("Approved Pharmacies in DB: $pharmaciesCount", $pharmaciesCount >= 1, "No approved pharmacies");

$categoriesCount = Category::count();
assertTest("Specialty Categories in DB: $categoriesCount", $categoriesCount >= 5);

$serviceCategories = ServiceCategory::active()->count();
assertTest("Service Categories (Active): $serviceCategories", $serviceCategories >= 1);

// ----------------------------------------------------
// SECTION 3: PUBLIC API ENDPOINTS TEST
// ----------------------------------------------------
echo "\n--- [3] PUBLIC API ENDPOINTS (MOBILE APP & GUEST) ---\n";

$testEndpoints = [
    '/api/app-version'       => ['latest_version', 'force_update'],
    '/api/home'              => ['banners'],
    '/api/banners'           => [],
    '/api/articles'          => [],
    '/api/service-categories'=> [],
    '/api/emergency-contacts'=> [],
    '/api/emergency-reels'   => [],
    '/api/labs'              => ['success'],
    '/api/nurses'            => ['success'],
    '/api/pharmacies'        => ['success'],
    '/api/doctors'           => [],
];

foreach ($testEndpoints as $uri => $expectedKeys) {
    $response = sendReq($uri, 'GET');
    $status = $response->getStatusCode();
    $content = json_decode($response->getContent(), true);
    
    $valid = ($status === 200);
    if ($valid && !empty($expectedKeys)) {
        foreach ($expectedKeys as $k) {
            if (!isset($content[$k])) {
                $valid = false;
                break;
            }
        }
    }
    assertTest("GET $uri (HTTP $status)", $valid, "Status $status or missing keys");
}

// ----------------------------------------------------
// SECTION 4: AUTHENTICATION FLOW (OTP & SANCTUM TOKENS)
// ----------------------------------------------------
echo "\n--- [4] AUTHENTICATION APIS (PATIENT & ADMIN OTP 2FA) ---\n";

// 4.1 Admin Login Request -> OTP
$adminLoginResp = sendReq('/api/login', 'POST', [
    'phone' => '07500000000',
    'password' => 'admin123456',
]);
$adminLoginData = json_decode($adminLoginResp->getContent(), true);
assertTest("Admin Login Request (/api/login)", $adminLoginResp->getStatusCode() === 200 && isset($adminLoginData['phone']));

// 4.2 Admin Verify OTP -> Bearer Token
$adminVerifyResp = sendReq('/api/verify-otp', 'POST', [
    'phone' => '07500000000',
    'otp_code' => '1234',
]);
$adminVerifyData = json_decode($adminVerifyResp->getContent(), true);
$adminToken = $adminVerifyData['access_token'] ?? $adminVerifyData['token'] ?? null;
assertTest("Admin Verify OTP (/api/verify-otp) -> Bearer Token", $adminVerifyResp->getStatusCode() === 200 && !empty($adminToken));

// 4.3 Patient Login Request & Verify OTP
$patientLoginResp = sendReq('/api/login', 'POST', [
    'phone' => '07501112222',
    'password' => 'user123456',
]);
assertTest("Patient Login Request (/api/login)", $patientLoginResp->getStatusCode() === 200);

$patientVerifyResp = sendReq('/api/verify-otp', 'POST', [
    'phone' => '07501112222',
    'otp_code' => '1234',
]);
$patientVerifyData = json_decode($patientVerifyResp->getContent(), true);
$patientToken = $patientVerifyData['access_token'] ?? $patientVerifyData['token'] ?? null;
assertTest("Patient Verify OTP (/api/verify-otp) -> Bearer Token", $patientVerifyResp->getStatusCode() === 200 && !empty($patientToken));

// 4.4 Patient Profile with Token
if ($patientToken) {
    $profileResp = sendReq('/api/user', 'GET', [], $patientToken);
    assertTest("Patient Auth Token Profile (/api/user)", $profileResp->getStatusCode() === 200);
}

// ----------------------------------------------------
// SECTION 5: ADMIN CRUD & APPROVAL FLOW (LAB & NURSE)
// ----------------------------------------------------
echo "\n--- [5] ADMIN LAB & NURSE CREATION, APPROVAL & SYNC TEST ---\n";

if ($adminToken) {
    // 5.1 Admin adds a new Lab
    $randomLabName = 'تاقیگەی نوێی تێست ' . rand(100, 999);
    $createLabResp = sendReq('/api/admin/labs', 'POST', [
        'name' => $randomLabName,
        'name_en' => 'Test Lab ' . rand(100, 999),
        'phone' => '0750' . rand(8100000, 8999999),
        'email' => 'test_lab_' . rand(10000, 99999) . '@drroom.test',
        'city' => 'هەولێر',
        'status' => 'pending',
    ], $adminToken);
    $createdLabData = json_decode($createLabResp->getContent(), true);
    $newLabUserId = $createdLabData['user']['id'] ?? null;

    assertTest("Admin Create Lab (pending status)", $createLabResp->getStatusCode() === 201 && $newLabUserId !== null, $createLabResp->getContent());

    // 5.2 Verify pending lab does NOT appear in public API
    $publicLabsBeforeRaw = json_decode(sendReq('/api/labs', 'GET')->getContent(), true);
    $publicLabsBefore = $publicLabsBeforeRaw['data'] ?? $publicLabsBeforeRaw;
    $foundBefore = false;
    foreach ($publicLabsBefore as $l) {
        if (($l['id'] ?? 0) === $newLabUserId || ($l['name'] ?? '') === $randomLabName) {
            $foundBefore = true;
            break;
        }
    }
    assertTest("Pending Lab hidden from Public /api/labs (Mobile App)", !$foundBefore);

    // 5.3 Admin Approves the Lab
    $approveLabResp = sendReq("/api/admin/labs/{$newLabUserId}/approve", 'PATCH', [], $adminToken);
    assertTest("Admin Approve Lab (/api/admin/labs/{id}/approve)", $approveLabResp->getStatusCode() === 200, $approveLabResp->getContent());

    // 5.4 Verify approved lab NOW appears in public API for Mobile App
    $publicLabsAfterRaw = json_decode(sendReq('/api/labs', 'GET')->getContent(), true);
    $publicLabsAfter = $publicLabsAfterRaw['data'] ?? $publicLabsAfterRaw;
    $foundAfter = false;
    foreach ($publicLabsAfter as $l) {
        if (($l['id'] ?? 0) === $newLabUserId || ($l['name'] ?? '') === $randomLabName) {
            $foundAfter = true;
            break;
        }
    }
    assertTest("Approved Lab now visible in Public /api/labs (Mobile App)", $foundAfter);

    // 5.5 Admin adds a new Nurse
    $randomNurseName = 'پەرستار تێست ' . rand(100, 999);
    $createNurseResp = sendReq('/api/admin/nurses', 'POST', [
        'name' => $randomNurseName,
        'phone' => '0750' . rand(7100000, 7999999),
        'email' => 'test_nurse_' . rand(10000, 99999) . '@drroom.test',
        'specialty' => 'چاوەدێری گشتی و دەرزی',
        'status' => 'pending',
    ], $adminToken);
    $createdNurseData = json_decode($createNurseResp->getContent(), true);
    $newNurseUserId = $createdNurseData['user']['id'] ?? null;

    assertTest("Admin Create Nurse (pending status)", $createNurseResp->getStatusCode() === 201 && $newNurseUserId !== null, $createNurseResp->getContent());

    // 5.6 Admin Approves the Nurse
    $approveNurseResp = sendReq("/api/admin/nurses/{$newNurseUserId}/approve", 'PATCH', [], $adminToken);
    assertTest("Admin Approve Nurse (/api/admin/nurses/{id}/approve)", $approveNurseResp->getStatusCode() === 200, $approveNurseResp->getContent());

    // 5.7 Verify approved Nurse in public /api/nurses for Mobile App
    $publicNursesRaw = json_decode(sendReq('/api/nurses', 'GET')->getContent(), true);
    $publicNurses = $publicNursesRaw['nurses'] ?? $publicNursesRaw['data'] ?? $publicNursesRaw;
    $foundNurse = false;
    foreach ($publicNurses as $n) {
        if (($n['name'] ?? '') === $randomNurseName) {
            $foundNurse = true;
            break;
        }
    }
    assertTest("Approved Nurse visible in Public /api/nurses (Mobile App)", $foundNurse);

    // Cleanup the test lab and test nurse
    User::whereIn('id', array_filter([$newLabUserId, $newNurseUserId]))->delete();
    Lab::where('user_id', $newLabUserId)->delete();
    Nurse::where('user_id', $newNurseUserId)->delete();
    echo "  🧹 Cleaned up test lab & nurse entries to maintain pristine DB.\n";
}

// ----------------------------------------------------
// SECTION 6: PAYMENTS & ORDERS FLOW TEST
// ----------------------------------------------------
echo "\n--- [6] PAYMENTS & ORDERS TRANSACTION FLOW ---\n";

if ($patientToken) {
    // 6.1 Create Payment Intent
    $intentResp = sendReq('/api/payments/create-intent', 'POST', [
        'amount' => 25000,
        'currency' => 'IQD',
        'description' => 'Home Nursing Care Test',
        'method' => 'cash',
    ], $patientToken);
    $intentData = json_decode($intentResp->getContent(), true);
    $intentId = $intentData['id'] ?? null;
    assertTest("Create Payment Intent (/api/payments/create-intent)", $intentResp->getStatusCode() === 201 && !empty($intentId));

    // 6.2 Confirm Payment
    if ($intentId) {
        $confirmResp = sendReq('/api/payments/confirm', 'POST', [
            'paymentIntentId' => $intentId,
            'paymentMethodId' => 'pm_cash_delivery',
            'method' => 'cash',
        ], $patientToken);
        $confirmData = json_decode($confirmResp->getContent(), true);
        assertTest("Confirm Payment (/api/payments/confirm)", $confirmResp->getStatusCode() === 200 && ($confirmData['status'] ?? '') === 'completed');
    }

    // 6.3 Fetch Payment History
    $historyResp = sendReq('/api/payments/history', 'GET', [], $patientToken);
    assertTest("Payment History (/api/payments/history)", $historyResp->getStatusCode() === 200);

    // 6.4 Clean up test transaction record
    if (!empty($intentId)) {
        Transaction::where('intent_id', $intentId)->delete();
        echo "  🧹 Cleaned up test transaction.\n";
    }
}

// ----------------------------------------------------
// SECTION 7: WEB ROUTES & LANDING PAGES
// ----------------------------------------------------
echo "\n--- [7] WEB PORTAL & ROUTE VERIFICATION ---\n";

// Ensure guest state for testing guest portal routes
app('auth')->forgetGuards();

$webRoutes = [
    '/' => 200,
    '/ckb' => 200,
    '/en' => 200,
    '/ar' => 200,
    '/staff' => 200,
    '/staff/login' => 200,
    '/staff/register' => 200,
    '/privacy-policy' => 200,
];

foreach ($webRoutes as $uri => $expectedStatus) {
    $resp = sendReq($uri, 'GET');
    assertTest("Web Route $uri (HTTP {$resp->getStatusCode()})", $resp->getStatusCode() === $expectedStatus);
}

// ----------------------------------------------------
// SUMMARY
// ----------------------------------------------------
echo "\n========================================================\n";
echo "📊 AUDIT RESULTS SUMMARY:\n";
echo "  ✅ TOTAL PASSED: $passCount\n";
echo "  ❌ TOTAL FAILED: $failCount\n";
echo "========================================================\n";

if ($failCount === 0) {
    echo "🎉 ALL SYSTEMS, APIS, WORKFLOWS, AND LOCALIZATIONS ARE 100% OPERATIONAL!\n";
    exit(0);
} else {
    echo "⚠️ SOME TESTS FAILED. PLEASE REVIEW ABOVE LOGS.\n";
    exit(1);
}
