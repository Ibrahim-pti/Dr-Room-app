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

        $nurses = $query->get()->map(function ($nurse) use ($request) {
            return $this->formatNurse($nurse, $request);
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
    public function show(Request $request, $id)
    {
        $nurse = Nurse::where('is_approved', true)
            ->with(['user:id,name,name_en,name_ar,name_kmr,email,profile_image'])
            ->findOrFail($id);

        return response()->json([
            'success' => true,
            'nurse' => $this->formatNurse($nurse, $request),
        ]);
    }

    /**
     * Format and localize a nurse record.
     */
    public function formatNurse($nurse, $request = null)
    {
        $lang = 'ckb';
        if ($request) {
            $hdr = strtolower($request->header('Accept-Language', 'ckb'));
            if (str_contains($hdr, 'ar')) {
                $lang = 'ar';
            } elseif (str_contains($hdr, 'en')) {
                $lang = 'en';
            }
        }

        $rawName = $nurse->user->name ?? '';
        $rawNameEn = $nurse->user->name_en ?? $rawName;
        $rawNameAr = $nurse->user->name_ar ?? '';
        $rawNameKu = $nurse->user->name_kmr ?? ($nurse->user->name_ku ?? '');

        // Name translation mapping
        $nameMap = [
            'aesha fatih' => [
                'ku' => 'عائشە فاتیح',
                'ar' => 'عائشة فاتح',
                'en' => 'Aesha Fatih',
            ],
            'aesha' => [
                'ku' => 'عائشە',
                'ar' => 'عائشة',
                'en' => 'Aesha',
            ],
        ];

        $lowerName = strtolower(trim($rawName ?: $rawNameEn));
        if (isset($nameMap[$lowerName])) {
            $nameKu = $rawNameKu ?: $nameMap[$lowerName]['ku'];
            $nameAr = $rawNameAr ?: $nameMap[$lowerName]['ar'];
            $nameEn = $nameMap[$lowerName]['en'];
        } else {
            $nameKu = $rawNameKu ?: $rawName;
            $nameAr = $rawNameAr ?: $rawName;
            $nameEn = $rawNameEn ?: $rawName;
        }

        // Specialty translation mapping
        $rawSpec = $nurse->specialty ?? '';
        $rawSpecEn = $nurse->specialty_en ?? $rawSpec;
        $rawSpecAr = $nurse->specialty_ar ?? '';
        $rawSpecKu = $nurse->specialty_kmr ?? ($nurse->specialty_ku ?? '');

        $specLower = strtolower(trim($rawSpec . ' ' . $rawSpecEn));
        if (str_contains($specLower, 'general care') || str_contains($specLower, 'general') || str_contains($specLower, 'چاودێری گشتی') || str_contains($specLower, 'رعاية عامة')) {
            $specKu = $rawSpecKu ?: 'چاودێری گشتی';
            $specAr = $rawSpecAr ?: 'رعاية عامة';
            $specEn = 'General Care';
        } elseif (str_contains($specLower, 'sampling') || str_contains($specLower, 'نموونە') || str_contains($specLower, 'سحب')) {
            $specKu = $rawSpecKu ?: 'پسپۆڕی وەرگرتنی نموونە';
            $specAr = $rawSpecAr ?: 'أخصائي سحب عينات';
            $specEn = 'Sampling Specialist';
        } elseif (str_contains($specLower, 'wound') || str_contains($specLower, 'dressing') || str_contains($specLower, 'برین') || str_contains($specLower, 'جروح')) {
            $specKu = $rawSpecKu ?: 'چارەسەری برین';
            $specAr = $rawSpecAr ?: 'عناية بالجروح';
            $specEn = 'Wound Care';
        } elseif (str_contains($specLower, 'emergency') || str_contains($specLower, 'فریاکەوتن') || str_contains($specLower, 'طوارئ')) {
            $specKu = $rawSpecKu ?: 'فریاکەوتنی خێرا';
            $specAr = $rawSpecAr ?: 'طوارئ وإسعافات';
            $specEn = 'Emergency Care';
        } elseif (str_contains($specLower, 'elderly') || str_contains($specLower, 'بەساڵاچوو') || str_contains($specLower, 'مسنين')) {
            $specKu = $rawSpecKu ?: 'چاودێری بەساڵاچووان';
            $specAr = $rawSpecAr ?: 'رعاية كبار السن';
            $specEn = 'Elderly Care';
        } elseif (str_contains($specLower, 'pediatric') || str_contains($specLower, 'child') || str_contains($specLower, 'منداڵ') || str_contains($specLower, 'أطفال')) {
            $specKu = $rawSpecKu ?: 'چاودێری منداڵان';
            $specAr = $rawSpecAr ?: 'رعاية أطفال';
            $specEn = 'Pediatric Care';
        } elseif (str_contains($specLower, 'injection') || str_contains($specLower, 'cannula') || str_contains($specLower, 'دەرزی') || str_contains($specLower, 'حقن')) {
            $specKu = $rawSpecKu ?: 'لێدانی دەرزی و کانیۆلا';
            $specAr = $rawSpecAr ?: 'حقن وتركيب كانيولا';
            $specEn = 'Injections & Cannula';
        } else {
            $specKu = $rawSpecKu ?: $rawSpec;
            $specAr = $rawSpecAr ?: $rawSpec;
            $specEn = $rawSpecEn ?: $rawSpec;
        }

        // Bio translation
        $rawBio = $nurse->bio ?? '';
        $rawBioEn = $nurse->bio_en ?? $rawBio;
        $rawBioAr = $nurse->bio_ar ?? '';
        $rawBioKu = $nurse->bio_kmr ?? ($nurse->bio_ku ?? '');

        if (empty($rawBioKu) && (empty($rawBio) || preg_match('/^[a-zA-Z\s,.-]+$/', $rawBio))) {
            $bioKu = 'پەرستاری پسپۆڕ لە بواری پێشکەشکردنی چاودێری تەندروستی ماڵەوە، لێدانی دەرزی، کانیۆلا، و چاودێریکردنی وردی نەخۆش بە ئەزموونێکی بەرز.';
            $bioAr = 'ممرض متخصص في تقديم الرعاية الصحية المنزلية وإعطاء المحاليل والعناية بالمرضى بأعلى معايير الجودة.';
            $bioEn = $rawBioEn ?: 'Specialized registered nurse providing high quality home healthcare, IV infusions, injections, and patient monitoring.';
        } else {
            $bioKu = $rawBioKu ?: $rawBio;
            $bioAr = $rawBioAr ?: $rawBio;
            $bioEn = $rawBioEn ?: $rawBio;
        }

        // City translation
        $city = $nurse->city ?? 'Erbil';
        $cityMap = [
            'Erbil'         => ['ku' => 'هەولێر',     'en' => 'Erbil',         'ar' => 'أربيل'],
            'Sulaymaniyah'  => ['ku' => 'سلێمانی',    'en' => 'Sulaymaniyah',  'ar' => 'السليمانية'],
            'Duhok'         => ['ku' => 'دهۆک',       'en' => 'Duhok',         'ar' => 'دهوك'],
            'Kirkuk'        => ['ku' => 'کەرکووک',    'en' => 'Kirkuk',        'ar' => 'كركوك'],
            'Halabja'       => ['ku' => 'هەڵەبجە',    'en' => 'Halabja',       'ar' => 'حلبجة'],
            'Zakho'         => ['ku' => 'زاخۆ',       'en' => 'Zakho',         'ar' => 'زاخو'],
            'Soran'         => ['ku' => 'سۆران',      'en' => 'Soran',         'ar' => 'سوران'],
        ];
        $cityKu = $cityMap[$city]['ku'] ?? $city;
        $cityAr = $cityMap[$city]['ar'] ?? $city;
        $cityEn = $cityMap[$city]['en'] ?? $city;

        // Custom services translation
        $customServices = $nurse->custom_services ?? [];
        if (is_array($customServices)) {
            $customServices = array_map(function ($cs) use ($lang) {
                if (!is_array($cs)) return $cs;
                $n = $cs['name'] ?? '';
                $nLower = strtolower(trim($n));
                $nKu = $cs['name_ku'] ?? '';
                $nAr = $cs['name_ar'] ?? '';
                $nEn = $cs['name_en'] ?? $n;

                if (str_contains($nLower, 'cannula')) {
                    $nKu = $nKu ?: 'دانانی کانیۆلا و دەرزی دەمار';
                    $nAr = $nAr ?: 'تركيب كانيولا وريدية';
                    $nEn = 'IV Cannula Insertion';
                } elseif (str_contains($nLower, 'injection')) {
                    $nKu = $nKu ?: 'لێدانی دەرزی (ماسولکە یان دەمار)';
                    $nAr = $nAr ?: 'حقن (عضلي / وريدي)';
                    $nEn = 'Injections (IM / IV)';
                } elseif (str_contains($nLower, 'serum') || str_contains($nLower, 'fluid')) {
                    $nKu = $nKu ?: 'بەستنی موغەزی (سیرۆم)';
                    $nAr = $nAr ?: 'إعطاء مغذي ومحاليل وريدية';
                    $nEn = 'IV Fluid Infusion';
                } elseif (str_contains($nLower, 'dressing') || str_contains($nLower, 'wound')) {
                    $nKu = $nKu ?: 'پاککردنەوە و پانسمانی برین';
                    $nAr = $nAr ?: 'تضميد وتعقيم الجروح';
                    $nEn = 'Wound Dressing & Care';
                } elseif (str_contains($nLower, 'vitals') || str_contains($nLower, 'pressure')) {
                    $nKu = $nKu ?: 'پێوانی پەستان، شەکرە و ئۆکسجین';
                    $nAr = $nAr ?: 'قياس الضغط والسكر والعلامات الحيوية';
                    $nEn = 'Vital Signs Check';
                }

                $cs['name_ku'] = $nKu ?: $n;
                $cs['name_ar'] = $nAr ?: $n;
                $cs['name_en'] = $nEn ?: $n;
                $cs['name'] = $lang === 'ar' ? $cs['name_ar'] : ($lang === 'en' ? $cs['name_en'] : $cs['name_ku']);
                return $cs;
            }, $customServices);
        }

        $selectedName = $lang === 'ar' ? $nameAr : ($lang === 'en' ? $nameEn : $nameKu);
        $selectedSpecialty = $lang === 'ar' ? $specAr : ($lang === 'en' ? $specEn : $specKu);
        $selectedBio = $lang === 'ar' ? $bioAr : ($lang === 'en' ? $bioEn : $bioKu);
        $selectedCity = $lang === 'ar' ? $cityAr : ($lang === 'en' ? $cityEn : $cityKu);

        $image = $nurse->image_path
            ? (str_starts_with($nurse->image_path, 'http') ? $nurse->image_path : asset('storage/' . $nurse->image_path))
            : ($nurse->user && $nurse->user->profile_image
                ? asset('storage/' . $nurse->user->profile_image)
                : null);

        return [
            'id' => $nurse->id,
            'name' => $selectedName ?: $nameKu,
            'name_ku' => $nameKu,
            'name_ar' => $nameAr,
            'name_en' => $nameEn,
            'specialty' => $selectedSpecialty ?: $specKu,
            'specialty_ku' => $specKu,
            'specialty_ar' => $specAr,
            'specialty_en' => $specEn,
            'bio' => $selectedBio ?: $bioKu,
            'bio_ku' => $bioKu,
            'bio_ar' => $bioAr,
            'bio_en' => $bioEn,
            'phone' => $nurse->phone ?? '',
            'city' => $selectedCity ?: $cityKu,
            'city_ku' => $cityKu,
            'city_ar' => $cityAr,
            'city_en' => $cityEn,
            'address' => $nurse->address ?? '',
            'address_en' => $nurse->address_en ?? '',
            'address_ar' => $nurse->address_ar ?? '',
            'address_ku' => $nurse->address_kmr ?? ($cityKu . ' - کوردستان'),
            'latitude' => $nurse->latitude,
            'longitude' => $nurse->longitude,
            'service_type' => $nurse->service_type ?? 'home_nursing',
            'image' => $image,
            'is_available' => $nurse->is_available ?? true,
            'fee' => $nurse->fee,
            'rating' => (float) ($nurse->rating ?? 0),
            'total_reviews' => (int) ($nurse->total_reviews ?? 0),
            'experience_years' => $nurse->experience_years ?? 0,
            'offered_services' => $nurse->offered_services ?? [],
            'custom_services' => $customServices,
            'completed_appointments' => $nurse->nurseAppointments()
                ->where('status', 'completed')->count(),
        ];
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
