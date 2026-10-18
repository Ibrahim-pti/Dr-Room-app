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
use App\Models\OrderItem;
use App\Models\Appointment;
use App\Models\LabResult;
use App\Models\Banner;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Hash;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

echo "======================================================================\n";
echo "🏥 DR. ROOM SYSTEM-WIDE COMPREHENSIVE PRODUCTION AUDIT & TEST SUITE\n";
echo "======================================================================\n\n";

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
    Auth::forgetGuards();
    Auth::setDefaultDriver($token ? 'sanctum' : 'web');
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

// Compare key completeness and non-empty values across languages
if (isset($parsedTranslations['Flutter en'])) {
    $enKeys = array_keys($parsedTranslations['Flutter en']);
    foreach (['Flutter ckb', 'Flutter ar', 'Flutter kmr'] as $lang) {
        if (isset($parsedTranslations[$lang])) {
            $langKeys = array_keys($parsedTranslations[$lang]);
            $missing = array_diff($enKeys, $langKeys);
            $completeness = round(((count($enKeys) - count($missing)) / max(1, count($enKeys))) * 100, 1);
            assertTest("Completeness $lang vs en ($completeness%)", count($missing) === 0, count($missing) . " missing keys");

            $emptyKeys = array_filter($parsedTranslations[$lang], fn($v) => $v === '' || $v === null);
            assertTest("Zero empty translations in $lang", count($emptyKeys) === 0, count($emptyKeys) . " empty keys");
        }
    }
}

// Telegram OTP translation keys check
$telegramOtpKeys = ['receive_via_telegram', 'send_code_via_telegram', 'channel_telegram'];
foreach ($telegramOtpKeys as $k) {
    $hasCkb = isset($parsedTranslations['Flutter ckb'][$k]);
    $hasEn = isset($parsedTranslations['Flutter en'][$k]);
    assertTest("Telegram OTP key '$k' translated in ckb and en", $hasCkb && $hasEn);
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
// SECTION 2: DATABASE SCHEMA & CORE STRUCTURE INTEGRITY
// ----------------------------------------------------
echo "\n--- [2] DATABASE TABLES & SCHEMA INTEGRITY ---\n";

$requiredTables = [
    'users' => ['id', 'name', 'phone', 'role', 'status'],
    'labs' => ['id', 'user_id', 'city', 'location', 'rating', 'is_approved'],
    'doctors' => ['id', 'user_id', 'specialty', 'consultation_fee'],
    'nurses' => ['id', 'user_id', 'specialty', 'fee', 'is_approved'],
    'pharmacies' => ['id', 'user_id', 'city', 'location', 'delivery_fee'],
    'orders' => ['id', 'patient_id', 'service_type', 'total_price', 'status', 'payment_method'],
    'order_items' => ['id', 'order_id', 'item_name', 'price', 'quantity'],
    'transactions' => ['id', 'reference', 'user_id', 'amount', 'currency', 'status', 'method'],
    'banners' => ['id', 'title', 'image_path', 'is_active', 'sort_order'],
    'categories' => ['id', 'name', 'icon'],
    'lab_results' => ['id', 'lab_id', 'patient_id', 'status'],
    'app_notifications' => ['id', 'title', 'message', 'type'],
];

foreach ($requiredTables as $table => $columns) {
    $tableExists = Schema::hasTable($table);
    assertTest("Table exists: $table", $tableExists);
    if ($tableExists) {
        $missingCols = [];
        foreach ($columns as $col) {
            if (!Schema::hasColumn($table, $col)) {
                $missingCols[] = $col;
            }
        }
        assertTest("Columns in $table (" . implode(', ', $columns) . ")", empty($missingCols), "Missing: " . implode(', ', $missingCols));
    }
}

// Check admin user existence
$admin = User::where('role', 'admin')->first();
assertTest("Admin User exists in DB", $admin !== null, "No admin user found");

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
    '/api/home'              => ['banners', 'categories', 'top_doctors', 'top_nurses', 'top_labs', 'top_pharmacies'],
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

// 4.3 Ensure Patient User exists & authenticate
$patient = User::firstOrCreate(
    ['phone' => '07501112222'],
    [
        'name' => 'نەخۆش / بەکارهێنەر',
        'email' => 'patient_test@drroom.com',
        'role' => 'patient',
        'status' => 'approved',
        'password' => Hash::make('user123456'),
    ]
);

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

if ($patientToken) {
    $profileResp = sendReq('/api/user', 'GET', [], $patientToken);
    assertTest("Patient Auth Token Profile (/api/user)", $profileResp->getStatusCode() === 200);
}

// ----------------------------------------------------
// SECTION 5: LAB SELF-REGISTRATION, APPROVAL & DASHBOARD
// ----------------------------------------------------
echo "\n--- [5] LAB SELF-REGISTRATION, APPROVAL & DASHBOARD VERIFICATION ---\n";

$testLabPhone = '0750' . rand(8000000, 8999999);
$testLabEmail = 'test_lab_' . rand(10000, 99999) . '@drroom.app';

// 5.1 Lab Self-Registration via StaffAuthController
$staffAuthController = new \App\Http\Controllers\Web\StaffAuthController();
$labRegReq = Request::create('/staff/register', 'POST', [
    'name' => 'تاقیگەی نیشتمان بۆ تێست',
    'email' => $testLabEmail,
    'phone' => $testLabPhone,
    'password' => 'password123',
    'password_confirmation' => 'password123',
    'role' => 'lab',
]);
$labRegResp = $staffAuthController->register($labRegReq);

$registeredLabUser = User::where('phone', $testLabPhone)->first();
assertTest("Lab Self-Registration created user with pending status", 
    $registeredLabUser !== null && $registeredLabUser->status === 'pending' && $registeredLabUser->role === 'lab',
    "Status: " . ($registeredLabUser?->status ?? 'null')
);

// 5.2 Lab User cannot view dashboard while pending
if ($registeredLabUser) {
    $isLabMiddleware = new \App\Http\Middleware\IsLab();
    Auth::guard('web')->setUser($registeredLabUser);
    Auth::shouldUse('web');
    $reqBeforeApproval = Request::create('/lab/dashboard', 'GET');
    $reqBeforeApproval->setUserResolver(fn() => $registeredLabUser);
    $respBeforeApproval = $isLabMiddleware->handle($reqBeforeApproval, fn() => response('OK', 200));
    // IsLab middleware redirects pending users to /staff/waiting (HTTP 302)
    assertTest("Pending Lab redirected from /lab/dashboard to /staff/waiting", 
        $respBeforeApproval->getStatusCode() === 302 && str_contains($respBeforeApproval->headers->get('Location') ?? '', 'waiting'),
        "Status: " . $respBeforeApproval->getStatusCode()
    );
    Auth::guard('web')->logout();
}

// 5.3 Admin Approves the Lab
if ($adminToken && $registeredLabUser) {
    $approveResp = sendReq("/api/admin/labs/{$registeredLabUser->id}/approve", 'PATCH', [], $adminToken);
    $approveData = json_decode($approveResp->getContent(), true);
    $registeredLabUser->refresh()->load('lab');
    assertTest("Admin approves lab via API (/api/admin/labs/{id}/approve)", 
        $approveResp->getStatusCode() === 200 && $registeredLabUser->status === 'approved' && (bool)$registeredLabUser->lab?->is_approved === true
    );

    // 5.4 EnsureLabProfileComplete middleware check
    // Lab has no about_us and location yet -> should redirect to /lab/profile
    $profileMiddleware = new \App\Http\Middleware\EnsureLabProfileComplete();
    $reqIncomplete = Request::create('/lab/dashboard', 'GET');
    $reqIncomplete->setUserResolver(fn() => $registeredLabUser);
    $respIncomplete = $profileMiddleware->handle($reqIncomplete, fn() => response('OK', 200));
    assertTest("Lab without complete profile redirected to /lab/profile", 
        $respIncomplete->getStatusCode() === 302 && str_contains($respIncomplete->headers->get('Location') ?? '', 'profile')
    );

    // 5.5 Lab completes profile (about_us, location)
    $labModel = $registeredLabUser->lab;
    if ($labModel) {
        $labModel->update([
            'about_us' => 'ئێمە باشترین تاقیگەی پێشکەوتووی پشکنینی پزیشکیین بە ئامێری مۆدێرن.',
            'location' => 'هەولێر - شەقامی پزیشکان',
            'city' => 'هەولێر',
        ]);
        $registeredLabUser->load('lab');
    }

    // 5.6 Lab accesses /lab/dashboard successfully after profile complete
    $reqComplete = Request::create('/lab/dashboard', 'GET');
    $reqComplete->setUserResolver(fn() => $registeredLabUser);
    $respComplete = $profileMiddleware->handle($reqComplete, fn() => response('OK', 200));
    assertTest("Approved lab with complete profile accesses /lab/dashboard (HTTP 200)", 
        $respComplete->getStatusCode() === 200,
        "Status: " . $respComplete->getStatusCode()
    );

    // 5.7 Verify LabDashboardController correctly queries by lab_id
    if ($labModel) {
        $testLabResult = LabResult::create([
            'lab_id' => $labModel->id,
            'patient_id' => $patient->id,
            'test_id' => null,
            'status' => 'pending',
            'notes' => 'Test Lab Result for Audit',
        ]);

        Auth::guard('web')->setUser($registeredLabUser);
        Auth::shouldUse('web');
        $dashboardController = new \App\Http\Controllers\Web\LabDashboardController();
        $view = $dashboardController->index();
        $viewData = $view->getData();
        assertTest("LabDashboardController correctly counts pending tests using lab_id", 
            isset($viewData['pendingTests']) && $viewData['pendingTests'] >= 1,
            "pendingTests: " . ($viewData['pendingTests'] ?? 'null')
        );

        $testLabResult->delete();
    }

    Auth::guard('web')->logout();
}

// ----------------------------------------------------
// SECTION 6: USER ORDERS, APPOINTMENTS & PAYMENTS
// ----------------------------------------------------
echo "\n--- [6] USER REQUESTS, ORDERING & TRANSACTIONS FLOW ---\n";

if ($patientToken) {
    // 6.1 User orders a Lab Test
    $labOrderResp = sendReq('/api/orders', 'POST', [
        'service_type' => 'lab_test',
        'subtotal' => 30000,
        'extra_fee' => 5000,
        'total_price' => 35000,
        'payment_method' => 'cash',
        'patient_details' => [
            'name' => 'نەخۆش تێست',
            'phone' => '07501112222',
            'address' => 'هەولێر - وەزیران',
        ],
        'items' => [
            [
                'name' => 'Complete Blood Count (CBC)',
                'price' => 30000,
                'quantity' => 1,
                'extra_data' => ['lab_id' => $registeredLabUser?->lab?->id],
            ]
        ],
    ], $patientToken);

    $labOrderData = json_decode($labOrderResp->getContent(), true);
    $labOrderId = $labOrderData['order']['id'] ?? null;
    assertTest("User places Lab Test order (/api/orders)", 
        $labOrderResp->getStatusCode() === 201 && !empty($labOrderId),
        $labOrderResp->getContent()
    );

    // Verify Transaction was automatically generated for this order
    $labOrderTx = Transaction::where('payable_type', Order::class)->where('payable_id', $labOrderId)->first();
    assertTest("Automated Transaction created for Lab order with normalized method (cash)", 
        $labOrderTx !== null && (float)$labOrderTx->amount === 35000.0 && $labOrderTx->method === 'cash'
    );

    // 6.2 User places Home Nursing order with FIB online gateway
    $nurseOrderResp = sendReq('/api/orders', 'POST', [
        'service_type' => 'home_nursing',
        'subtotal' => 20000,
        'extra_fee' => 0,
        'total_price' => 20000,
        'payment_method' => 'fib',
        'transaction_reference' => 'FIB-AUDIT-TEST-12345',
        'patient_details' => [
            'name' => 'نەخۆش تێست',
            'phone' => '07501112222',
        ],
        'items' => [
            [
                'name' => 'بەستنی سیرۆم لە ماڵەوە',
                'price' => 20000,
                'quantity' => 1,
            ]
        ],
    ], $patientToken);

    $nurseOrderData = json_decode($nurseOrderResp->getContent(), true);
    $nurseOrderId = $nurseOrderData['order']['id'] ?? null;
    assertTest("User places Home Nursing order with online gateway FIB", 
        $nurseOrderResp->getStatusCode() === 201 && !empty($nurseOrderId)
    );

    $nurseOrderTx = Transaction::where('payable_type', Order::class)->where('payable_id', $nurseOrderId)->first();
    assertTest("Automated Transaction created for Nursing order with method (fib)", 
        $nurseOrderTx !== null && (float)$nurseOrderTx->amount === 20000.0 && $nurseOrderTx->method === 'fib'
    );

    // 6.3 User places Pharmacy order with FastPay gateway
    $pharmacyOrderResp = sendReq('/api/orders', 'POST', [
        'service_type' => 'pharmacy',
        'subtotal' => 15000,
        'extra_fee' => 2000,
        'total_price' => 17000,
        'payment_method' => 'fastpay',
        'transaction_reference' => 'FASTPAY-AUDIT-9988',
        'items' => [
            [
                'name' => 'Panadol Extra 500mg',
                'price' => 7500,
                'quantity' => 2,
            ]
        ],
    ], $patientToken);

    $pharmacyOrderData = json_decode($pharmacyOrderResp->getContent(), true);
    $pharmacyOrderId = $pharmacyOrderData['order']['id'] ?? null;
    assertTest("User places Pharmacy order with FastPay gateway", 
        $pharmacyOrderResp->getStatusCode() === 201 && !empty($pharmacyOrderId)
    );

    // 6.4 User fetches Orders List
    $myOrdersResp = sendReq('/api/orders', 'GET', [], $patientToken);
    $myOrdersData = json_decode($myOrdersResp->getContent(), true);
    assertTest("User fetches orders list (/api/orders)", 
        $myOrdersResp->getStatusCode() === 200 && count($myOrdersData['data'] ?? []) >= 3
    );

    // 6.5 Admin manages orders: Admin updates status to completed
    if ($adminToken && $labOrderId) {
        $updateStatusResp = sendReq("/api/admin/orders/{$labOrderId}/status", 'PATCH', [
            'status' => 'completed',
        ], $adminToken);
        
        $labOrderTx->refresh();
        assertTest("Admin completes order -> Transaction status automatically completed and marked paid", 
            $updateStatusResp->getStatusCode() === 200 && $labOrderTx->status === 'completed' && $labOrderTx->paid_at !== null
        );
    }

    // 6.6 Payment Gateways & Methods listing
    $methodsResp = sendReq('/api/payments/methods', 'GET', [], $patientToken);
    $methodsData = json_decode($methodsResp->getContent(), true);
    $methodTypes = array_column($methodsData['data'] ?? [], 'type');
    $hasRequiredGateways = in_array('cash', $methodTypes) && 
                           in_array('fib', $methodTypes) && 
                           in_array('fastpay', $methodTypes) && 
                           in_array('zaincash', $methodTypes) && 
                           in_array('qi_card', $methodTypes);
    assertTest("Payment Methods include (cash, fib, fastpay, zaincash, qi_card)", $hasRequiredGateways);

    // 6.7 Payment History
    $payHistoryResp = sendReq('/api/payments/history', 'GET', [], $patientToken);
    assertTest("Payment History (/api/payments/history) returns HTTP 200", $payHistoryResp->getStatusCode() === 200);

    // Cleanup created test orders & transactions
    OrderItem::whereIn('order_id', array_filter([$labOrderId, $nurseOrderId, $pharmacyOrderId]))->delete();
    Transaction::whereIn('payable_id', array_filter([$labOrderId, $nurseOrderId, $pharmacyOrderId]))->delete();
    Order::whereIn('id', array_filter([$labOrderId, $nurseOrderId, $pharmacyOrderId]))->delete();
    echo "  🧹 Cleaned up test orders, items, and transactions.\n";
}

// ----------------------------------------------------
// SECTION 7: IN-APP ADMIN DASHBOARD & CAROUSEL/BANNER
// ----------------------------------------------------
echo "\n--- [7] IN-APP ADMIN DASHBOARD & BANNER PUBLISHING ---\n";

if ($adminToken) {
    // 7.1 Admin Dashboard Stats Endpoint (/api/admin/dashboard)
    $dashResp = sendReq('/api/admin/dashboard', 'GET', [], $adminToken);
    $dashData = json_decode($dashResp->getContent(), true);
    $expectedDashKeys = [
        'total_users', 'total_doctors', 'total_nurses', 'total_labs', 
        'total_pharmacies', 'total_orders', 'total_appointments'
    ];
    $hasDashKeys = true;
    foreach ($expectedDashKeys as $dk) {
        if (!array_key_exists($dk, $dashData)) {
            $hasDashKeys = false;
            break;
        }
    }
    assertTest("In-App Admin Dashboard (/api/admin/dashboard) returns stats", 
        $dashResp->getStatusCode() === 200 && $hasDashKeys,
        "Status: " . $dashResp->getStatusCode()
    );

    // 7.2 Admin Orders list (/api/admin/orders)
    $adminOrdersResp = sendReq('/api/admin/orders', 'GET', [], $adminToken);
    assertTest("Admin Orders List (/api/admin/orders)", $adminOrdersResp->getStatusCode() === 200);

    // 7.3 Admin Transactions list (/api/admin/transactions)
    $adminTxResp = sendReq('/api/admin/transactions', 'GET', [], $adminToken);
    assertTest("Admin Transactions List (/api/admin/transactions)", $adminTxResp->getStatusCode() === 200);

    // 7.4 Banner Publishing & Carousel Flow
    $testBanner = Banner::create([
        'title' => 'داشکاندنی تایبەت بە پشکنینی پزیشکی',
        'title_en' => 'Special Discount on Medical Checkups',
        'title_ar' => 'خصم خاص على الفحوصات الطبية',
        'image_path' => 'banners/test_audit_banner.jpg',
        'is_active' => true,
        'sort_order' => 1,
    ]);

    // Check banner in public /api/banners
    $publicBanners = json_decode(sendReq('/api/banners', 'GET')->getContent(), true);
    $foundInPublic = false;
    foreach ($publicBanners as $b) {
        if (($b['id'] ?? 0) === $testBanner->id) {
            $foundInPublic = true;
            break;
        }
    }
    assertTest("Published active Banner appears in public /api/banners", $foundInPublic);

    // Check banner in /api/home banners carousel payload
    $homeData = json_decode(sendReq('/api/home', 'GET')->getContent(), true);
    $foundInHome = false;
    foreach ($homeData['banners'] ?? [] as $b) {
        if (($b['id'] ?? 0) === $testBanner->id) {
            $foundInHome = true;
            break;
        }
    }
    assertTest("Published Banner appears in /api/home Carousel payload", $foundInHome);

    // Deactivate banner
    $testBanner->update(['is_active' => false]);
    $publicBannersAfter = json_decode(sendReq('/api/banners', 'GET')->getContent(), true);
    $foundAfterDeactivate = false;
    foreach ($publicBannersAfter as $b) {
        if (($b['id'] ?? 0) === $testBanner->id) {
            $foundAfterDeactivate = true;
            break;
        }
    }
    assertTest("Deactivated Banner is hidden from public /api/banners & Carousel", !$foundAfterDeactivate);

    // Cleanup test banner
    $testBanner->delete();
    echo "  🧹 Cleaned up test banner.\n";
}

// Cleanup the test lab user
if ($registeredLabUser) {
    if ($registeredLabUser->lab) {
        $registeredLabUser->lab->delete();
    }
    $registeredLabUser->delete();
    echo "  🧹 Cleaned up test self-registered lab user.\n";
}

// ----------------------------------------------------
// SECTION 8: WEB PORTAL ROUTES & SSR PAGES
// ----------------------------------------------------
echo "\n--- [8] WEB PORTAL & MULTILINGUAL LANDING ROUTES ---\n";

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
// SECTION 9: REMOTE SERVER CONNECTIVITY & HEALTH CHECK
// ----------------------------------------------------
echo "\n--- [9] REMOTE PRODUCTION SERVER (sys.shaqamonline.org) HEALTH ---\n";

$remoteEndpoints = [
    'https://sys.shaqamonline.org/api/app-version' => 'latest_version',
    'https://sys.shaqamonline.org/api/home' => 'banners',
    'https://sys.shaqamonline.org/api/banners' => null,
];

foreach ($remoteEndpoints as $url => $keyCheck) {
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_IPRESOLVE, CURL_IPRESOLVE_V4);
    curl_setopt($ch, CURLOPT_TIMEOUT, 15);
    curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 10);
    curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
    curl_setopt($ch, CURLOPT_USERAGENT, 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)');
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, false);
    $res = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    $isOk = ($httpCode === 200);
    if ($isOk && $keyCheck) {
        $data = json_decode($res, true);
        $isOk = isset($data[$keyCheck]);
    }
    assertTest("Remote API $url (HTTP $httpCode)", $isOk);
}

// ----------------------------------------------------
// SUMMARY
// ----------------------------------------------------
echo "\n======================================================================\n";
echo "📊 FULL SYSTEM AUDIT RESULTS SUMMARY:\n";
echo "  ✅ TOTAL PASSED: $passCount\n";
echo "  ❌ TOTAL FAILED: $failCount\n";
echo "======================================================================\n";

if ($failCount === 0) {
    echo "🎉 ALL 9 CORE SUBSYSTEMS ARE 100% OPERATIONAL, INTEGRATED, AND PRODUCTION-READY!\n";
    exit(0);
} else {
    echo "⚠️ SOME TESTS FAILED. PLEASE REVIEW LOGS ABOVE.\n";
    exit(1);
}
