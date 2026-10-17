<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Nurse;
use App\Models\NurseAppointment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class NurseApiController extends Controller
{
    /**
     * List all approved nurses (like the doctor listing).
     */
    public function index(Request $request)
    {
        $query = Nurse::where('is_approved', true)
            ->with(['user:id,name,name_en,name_ar,email,profile_image']);

        if ($request->has('specialty') && $request->specialty) {
            $query->where('specialty', 'like', '%' . $request->specialty . '%');
        }

        // Filter by city
        if ($request->has('city') && $request->city) {
            $query->where('city', $request->city);
        }

        // Filter by service_type (home_nursing, clinic, hospital)
        if ($request->has('service_type') && $request->service_type) {
            $query->where('service_type', $request->service_type);
        }

        $nurses = $query->get()->map(function ($nurse) {
            return [
                'id' => $nurse->id,
                'name' => $nurse->user->name ?? '',
                'name_en' => $nurse->user->name_en ?? '',
                'name_ar' => $nurse->user->name_ar ?? '',
                'specialty' => $nurse->specialty ?? '',
                'specialty_en' => $nurse->specialty_en ?? '',
                'specialty_ar' => $nurse->specialty_ar ?? '',
                'bio' => $nurse->bio ?? '',
                'bio_en' => $nurse->bio_en ?? '',
                'bio_ar' => $nurse->bio_ar ?? '',
                'phone' => $nurse->phone ?? '',
                'city' => $nurse->city ?? '',
                'address' => $nurse->address ?? '',
                'address_en' => $nurse->address_en ?? '',
                'address_ar' => $nurse->address_ar ?? '',
                'latitude' => $nurse->latitude,
                'longitude' => $nurse->longitude,
                'service_type' => $nurse->service_type ?? 'home_nursing',
                'image' => $nurse->image_path
                    ? (str_starts_with($nurse->image_path, 'http') ? $nurse->image_path : asset('storage/' . $nurse->image_path))
                    : ($nurse->user->profile_image
                        ? asset('storage/' . $nurse->user->profile_image)
                        : null),
                'is_available' => $nurse->is_available ?? true,
                'fee' => $nurse->fee,
                'rating' => (float) ($nurse->rating ?? 0),
                'total_reviews' => (int) ($nurse->total_reviews ?? 0),
                'experience_years' => $nurse->experience_years ?? 0,
                'offered_services' => $nurse->offered_services ?? [],
                'custom_services' => $nurse->custom_services ?? [],
                'completed_appointments' => $nurse->nurseAppointments()
                    ->where('status', 'completed')->count(),
            ];
        });

        // Dynamic city categories from database
        $cities = Nurse::where('is_approved', true)
            ->whereNotNull('city')
            ->where('city', '!=', '')
            ->distinct()
            ->pluck('city')
            ->toArray();

        // Build city categories with Kurdish/Arabic/English names
        $cityMap = [
            'Erbil'         => ['name' => 'هەولێر',     'name_en' => 'Erbil',         'name_ar' => 'أربيل'],
            'Sulaymaniyah'  => ['name' => 'سلێمانی',    'name_en' => 'Sulaymaniyah',  'name_ar' => 'السليمانية'],
            'Duhok'         => ['name' => 'دهۆک',       'name_en' => 'Duhok',         'name_ar' => 'دهوك'],
            'Kirkuk'        => ['name' => 'کەرکووک',    'name_en' => 'Kirkuk',        'name_ar' => 'كركوك'],
            'Halabja'       => ['name' => 'هەڵەبجە',    'name_en' => 'Halabja',       'name_ar' => 'حلبجة'],
        ];

        $categories = [];

        // Always include "Home Nursing" category
        $categories[] = [
            'id' => 'home_nursing',
            'name' => 'پەرستاری ماڵ',
            'name_en' => 'Home Nursing',
            'name_ar' => 'تمريض منزلي',
            'type' => 'service_type',
            'icon' => 'home',
        ];

        // Add dynamic city categories from DB
        foreach ($cities as $city) {
            $mapped = $cityMap[$city] ?? ['name' => $city, 'name_en' => $city, 'name_ar' => $city];
            $categories[] = [
                'id' => $city,
                'name' => $mapped['name'],
                'name_en' => $mapped['name_en'],
                'name_ar' => $mapped['name_ar'],
                'type' => 'city',
                'icon' => 'location',
            ];
        }

        return response()->json([
            'success' => true,
            'nurses' => $nurses,
            'categories' => $categories,
        ]);
    }

    /**
     * Show a single nurse's details.
     */
    public function show($id)
    {
        $nurse = Nurse::where('is_approved', true)
            ->with(['user:id,name,name_en,name_ar,email,profile_image'])
            ->findOrFail($id);

        return response()->json([
            'success' => true,
            'nurse' => [
                'id' => $nurse->id,
                'name' => $nurse->user->name ?? '',
                'name_en' => $nurse->user->name_en ?? '',
                'name_ar' => $nurse->user->name_ar ?? '',
                'specialty' => $nurse->specialty ?? '',
                'specialty_en' => $nurse->specialty_en ?? '',
                'specialty_ar' => $nurse->specialty_ar ?? '',
                'bio' => $nurse->bio ?? '',
                'bio_en' => $nurse->bio_en ?? '',
                'bio_ar' => $nurse->bio_ar ?? '',
                'phone' => $nurse->phone ?? '',
                'city' => $nurse->city ?? '',
                'address' => $nurse->address ?? '',
                'address_en' => $nurse->address_en ?? '',
                'address_ar' => $nurse->address_ar ?? '',
                'latitude' => $nurse->latitude,
                'longitude' => $nurse->longitude,
                'service_type' => $nurse->service_type ?? 'home_nursing',
                'fee' => $nurse->fee,
                'rating' => (float) ($nurse->rating ?? 0),
                'total_reviews' => (int) ($nurse->total_reviews ?? 0),
                'experience_years' => $nurse->experience_years ?? 0,
                'is_available' => $nurse->is_available ?? true,
                'offered_services' => $nurse->offered_services ?? [],
                'custom_services' => $nurse->custom_services ?? [],
                'image' => $nurse->image_path
                    ? asset('storage/' . $nurse->image_path)
                    : ($nurse->user->profile_image
                        ? asset('storage/' . $nurse->user->profile_image)
                        : null),
                'completed_appointments' => $nurse->nurseAppointments()
                    ->where('status', 'completed')->count(),
            ],
        ]);
    }

    /**
     * Get the list of available nursing services.
     */
    public function getServices()
    {
        $services = [
            [
                'id' => 'injection',
                'name' => 'لێدانی دەرزی (ماسولکە یان دەمار)',
                'name_en' => 'Injections (IM / IV)',
                'name_ar' => 'حقن (عضلي / وريدي)',
                'description' => 'دەرزی ماسولکە، دەمار، یان ژێر پێست لە ماڵەوە',
                'icon' => 'health',
                'price' => 15000,
                'duration' => '١٥ خولەک',
                'duration_en' => '15 min',
                'duration_ar' => '١٥ دقيقة',
            ],
            [
                'id' => 'cannula',
                'name' => 'دانانی کانیۆلا و دەرزی دەمار',
                'name_en' => 'IV Cannula Insertion',
                'name_ar' => 'تركيب كانيولا وريدية',
                'description' => 'دانان و چاودێریکردنی کانیۆلای دەمار بە شێوەیەکی پڕۆفیشناڵ',
                'icon' => 'activity',
                'price' => 20000,
                'duration' => '٢٠ خولەک',
                'duration_en' => '20 min',
                'duration_ar' => '٢٠ دقيقة',
            ],
            [
                'id' => 'serum',
                'name' => 'بەستنی موغەزی (سیرۆم)',
                'name_en' => 'IV Fluid Infusion (Serum)',
                'name_ar' => 'إعطاء مغذي ومحاليل وريدية',
                'description' => 'بەستنی سیرۆم و چاودێری ڤیتامین و دەرمان بە دەمار',
                'icon' => 'drop',
                'price' => 20000,
                'duration' => '٤٥ خولەک',
                'duration_en' => '45 min',
                'duration_ar' => '٤٥ دقيقة',
            ],
            [
                'id' => 'dressing',
                'name' => 'پاککردنەوە و پانسمانی برین',
                'name_en' => 'Wound Cleaning & Dressing',
                'name_ar' => 'تنظيف وتضميد الجروح',
                'description' => 'پاککردنەوە و پێچانەوەی برین و دوای نەشتەرگەری',
                'icon' => 'shield_tick',
                'price' => 25000,
                'duration' => '٣٠ خولەک',
                'duration_en' => '30 min',
                'duration_ar' => '٣٠ دقيقة',
            ],
            [
                'id' => 'checkup',
                'name' => 'پێوانی پەستان، شەکرە و ئۆکسجین',
                'name_en' => 'Vital Signs Monitoring Check',
                'name_ar' => 'فحص الضغط والسكر والأكسجين',
                'description' => 'پشکنینی سەرەتایی، پەستانی خوێن، و چاودێری نیشانە ژیانییەکان',
                'icon' => 'heart',
                'price' => 10000,
                'duration' => '١٥ خولەک',
                'duration_en' => '15 min',
                'duration_ar' => '١٥ دقيقة',
            ],
            [
                'id' => 'catheter',
                'name' => 'دانان یان گۆڕینی سۆندەی میز (کاسیتەر)',
                'name_en' => 'Urinary Catheter Care',
                'name_ar' => 'تركيب أو تبديل القسطرة البولية',
                'description' => 'دانان و چاودێری سۆندەی میز بە شێوازێکی پزیشکی و پاکژ',
                'icon' => 'activity',
                'price' => 25000,
                'duration' => '٣٠ خولەک',
                'duration_en' => '30 min',
                'duration_ar' => '٣٠ دقيقة',
            ],
            [
                'id' => 'physiotherapy',
                'name' => 'ڕاهێنانی فیزیۆتێراپی و چارەسەری سروشتی',
                'name_en' => 'Physical Therapy & Rehabilitation',
                'name_ar' => 'العلاج الطبيعي والتأهيل البدني',
                'description' => 'ڕاهێنانی جەستەیی بۆ دوای نەشتەرگەری و جەڵتە و لاوازی ماسولکە',
                'icon' => 'blend',
                'price' => 35000,
                'duration' => '٤٥ خولەک',
                'duration_en' => '45 min',
                'duration_ar' => '٤٥ دقيقة',
            ],
            [
                'id' => 'elderly_hygiene',
                'name' => 'چاودێری پاکوخاوێنی و خۆشوشتنی نەخۆش لە جێگە',
                'name_en' => 'Bedbound Patient Hygiene & Bathing',
                'name_ar' => 'العناية بالنظافة والاستحمام للمريض طريح الفراش',
                'description' => 'خۆشوشتن و خاوێنکردنەوەی نەخۆشی بێدەسەڵات لەناو جێگە',
                'icon' => 'scissor',
                'price' => 30000,
                'duration' => '٤٥ خولەک',
                'duration_en' => '45 min',
                'duration_ar' => '٤٥ دقيقة',
            ],
        ];

        // Ensure unique services by name and id
        $uniqueServices = [];
        $seenNames = [];
        foreach ($services as $s) {
            $normalizedName = trim(mb_strtolower($s['name']));
            if (!isset($seenNames[$normalizedName])) {
                $seenNames[$normalizedName] = true;
                $uniqueServices[] = $s;
            }
        }
        $services = $uniqueServices;

        return response()->json([
            'success' => true,
            'services' => $services,
            'data' => $services,
            'total' => count($services),
        ]);
    }

    /**
     * Get the list of nursing care packages.
     */
    public function packages(Request $request)
    {
        $packages = [
            [
                'id' => 'pkg_post_op',
                'title' => 'پاکێجی چاودێری پاش نەشتەرگەری',
                'title_en' => 'Post-Operative Recovery Package',
                'title_ar' => 'باقة الرعاية ما بعد الجراحة',
                'desc' => 'چاودێری برین، لێدانی دەرمانی ئازارشکێن و دژەهەوکردن، پێوانی نیشانە سەرەکییەکان (٥ سەردان)',
                'desc_en' => 'Wound dressing, IV meds, pain management and vitals check (5 visits)',
                'desc_ar' => 'غيار الجروح، أدوية مسكنة، ومتابعة العلامات الحيوية (٥ زيارات)',
                'visits' => '٥ سەردانی ماڵەوە',
                'visits_en' => '5 Home Visits',
                'visits_ar' => '٥ زيارات منزلية',
                'original_price' => 125000.0,
                'discount_price' => 89000.0,
                'discount_percent' => '28%',
                'services_count' => 5,
            ],
            [
                'id' => 'pkg_elderly',
                'title' => 'پاکێجی چاودێری بەساڵاچووان',
                'title_en' => 'Elderly Routine Home Care',
                'title_ar' => 'باقة رعاية كبار السن المنزلية',
                'desc' => 'پێوانی ڕۆژانەی پەستان و شەکرە، دانان و بەڕێوەبردنی دەرمان، چاودێری تەندروستی (٧ ڕۆژ)',
                'desc_en' => 'Daily vitals monitoring, medication schedule, and general home hygiene (7 days)',
                'desc_ar' => 'متابعة السكر والضغط يومياً وتنظيم الأدوية والرعاية (٧ أيام)',
                'visits' => '٧ سەردانی هەفتانە',
                'visits_en' => '7 Weekly Visits',
                'visits_ar' => '٧ زيارات أسبوعية',
                'original_price' => 175000.0,
                'discount_price' => 119000.0,
                'discount_percent' => '32%',
                'services_count' => 7,
            ],
            [
                'id' => 'pkg_shift_12h',
                'title' => 'پاکێجی مانەوەی پەرستار (١٢ کاتژمێری)',
                'title_en' => '12-Hour Intensive Home Nursing Shift',
                'title_ar' => 'باقة شفت تمريض منزلي (١٢ ساعة)',
                'desc' => 'مانەوەی تەواوی پەرستاری پسپۆڕ بۆ ماوەی ١٢ کاتژمێر بۆ چاودێری وردی نەخۆشی تایبەت',
                'desc_en' => 'Full shift 12 hours dedicated certified nursing care at home',
                'desc_ar' => 'ممرض متخصص متواجد ١٢ ساعة متواصلة لرعاية الحالات الحرجة',
                'visits' => 'شەفتی ١٢ کاتژمێری',
                'visits_en' => '12-Hour Shift',
                'visits_ar' => 'شفت ١٢ ساعة',
                'original_price' => 90000.0,
                'discount_price' => 65000.0,
                'discount_percent' => '27%',
                'services_count' => 12,
            ],
        ];

        return response()->json([
            'success' => true,
            'data' => $packages,
            'packages' => $packages,
            'total' => count($packages),
        ]);
    }

    /**
     * Book a nursing service.
     */
    public function book(Request $request)
    {
        $request->validate([
            'nurse_id' => 'nullable|exists:nurses,id',
            'services' => 'required|array',
            'address' => 'required|string',
            'phone' => 'required|string',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'appointment_date' => 'required|date',
            'notes' => 'nullable|string',
        ]);

        $nurseId = $request->nurse_id;
        $fee = 0;

        if ($nurseId) {
            $nurse = Nurse::find($nurseId);
            // In a real app, fee calculation might be more complex. For now, use the nurse's base fee.
            $fee = $nurse->fee ?? $this->calculateTotalFee($request->services);
        } else {
            $fee = $this->calculateTotalFee($request->services);
        }

        $appointment = NurseAppointment::create([
            'patient_id' => Auth::id(),
            'nurse_id' => $nurseId,
            'services' => $request->services, // ['injection', 'cannula']
            'address' => $request->address,
            'phone' => $request->phone,
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'appointment_date' => $request->appointment_date,
            'notes' => $request->notes,
            'status' => 'pending',
            'type' => 'home_visit', // Usually home visit from the app
            'fee' => $fee,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'داواکارییەکەت بە سەرکەوتوویی نێردرا',
            'appointment' => $appointment,
        ]);
    }

    private function calculateTotalFee(array $serviceIds)
    {
        $prices = [
            'injection' => 15000,
            'cannula' => 20000,
            'dressing' => 25000,
            'checkup' => 10000,
        ];

        $total = 0;
        foreach ($serviceIds as $id) {
            if (isset($prices[$id])) {
                $total += $prices[$id];
            }
        }
        return $total;
    }
}
