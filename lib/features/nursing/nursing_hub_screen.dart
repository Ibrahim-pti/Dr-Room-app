import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import '../../core/providers/cart_provider.dart';
import '../../core/utils/currency.dart';
import '../../core/utils/api_client.dart';
import '../checkout/checkout_details_screen.dart';
import '../requests/my_requests_screen.dart';
import '../emergency/sos_screen.dart';
import 'nurse_list_screen.dart';

class NursingHubScreen extends StatefulWidget {
  const NursingHubScreen({super.key});

  @override
  State<NursingHubScreen> createState() => _NursingHubScreenState();
}

class _NursingHubScreenState extends State<NursingHubScreen> {
  bool _isLoading = false;

  // Dynamic lists fetched purely from API
  List<Map<String, dynamic>> _nursingPriceList = [];
  List<Map<String, dynamic>> _staffList = [];
  List<Map<String, dynamic>> _carePackages = [];

  @override
  void initState() {
    super.initState();
    _initFallbackData();
    _fetchDynamicData();
  }

  // Helper method to retrieve localized string for API items
  String _getLocalized(Map<String, dynamic> item, String key) {
    final lang = context.locale.languageCode;
    if (lang == 'ar' && item['${key}_ar'] != null && item['${key}_ar'].toString().trim().isNotEmpty) {
      return item['${key}_ar'].toString();
    }
    if (lang == 'en' && item['${key}_en'] != null && item['${key}_en'].toString().trim().isNotEmpty) {
      return item['${key}_en'].toString();
    }
    if (lang == 'ckb' && item['${key}_ku'] != null && item['${key}_ku'].toString().trim().isNotEmpty) {
      return item['${key}_ku'].toString();
    }
    return (item[key] ?? item['${key}_ku'] ?? item['${key}_en'] ?? '').toString();
  }

  void _initFallbackData() {
    // Initial fallback data if network has not responded yet
    _nursingPriceList = [
      {
        'id': 'cat_inj_im',
        'name': 'لێدانی دەرزی (ماسولکە یان دەمار)',
        'name_en': 'Injection (IM / IV)',
        'name_ar': 'حقن (عضلي / وريدي)',
        'price': 10000.0,
        'duration': '١٥ خولەک',
        'duration_en': '15 min',
        'duration_ar': '١٥ دقيقة',
        'icon': Iconsax.health,
      },
      {
        'id': 'cat_cannula',
        'name': 'دانانی کانیۆلا و دەرزی دەمار',
        'name_en': 'IV Cannula Insertion',
        'name_ar': 'تركيب كانيولا وريدية',
        'price': 15000.0,
        'duration': '٢٠ خولەک',
        'duration_en': '20 min',
        'duration_ar': '٢٠ دقيقة',
        'icon': Iconsax.activity,
      },
      {
        'id': 'cat_serum',
        'name': 'بەستنی موغەزی (سیرۆم)',
        'name_en': 'IV Fluid Infusion (Serum)',
        'name_ar': 'إعطاء مغذي ومحاليل وريدية',
        'price': 20000.0,
        'duration': '٤٥ خولەک',
        'duration_en': '45 min',
        'duration_ar': '٤٥ دقيقة',
        'icon': Iconsax.drop,
      },
      {
        'id': 'cat_wound',
        'name': 'پاککردنەوە و پانسمانی برین',
        'name_en': 'Wound Cleaning & Dressing',
        'name_ar': 'تنظيف وتضميد الجروح',
        'price': 25000.0,
        'duration': '٣٠ خولەک',
        'duration_en': '30 min',
        'duration_ar': '٣٠ دقيقة',
        'icon': Iconsax.shield_tick,
      },
      {
        'id': 'cat_vitals',
        'name': 'پێوانی پەستان، شەکرە و ئۆکسجین',
        'name_en': 'Vital Signs Monitoring Check',
        'name_ar': 'فحص الضغط والسكر والأكسجين',
        'price': 10000.0,
        'duration': '١٥ خولەک',
        'duration_en': '15 min',
        'duration_ar': '١٥ دقيقة',
        'icon': Iconsax.heart,
      },
    ];

    _carePackages = [
      {
        'id': 'pkg_post_op',
        'title': 'پاکێجی چاودێری پاش نەشتەرگەری',
        'title_en': 'Post-Operative Recovery Package',
        'title_ar': 'باقة الرعاية ما بعد الجراحة',
        'desc': 'چاودێری برین، لێدانی دەرمانی ئازارشکێن و دژەهەوکردن، پێوانی نیشانە سەرەکییەکان (٥ سەردان)',
        'desc_en': 'Wound dressing, IV meds, pain management and vitals check (5 visits)',
        'desc_ar': 'غيار الجروح، أدوية مسكنة، ومتابعة العلامات الحيوية (٥ زيارات)',
        'visits': '٥ سەردانی ماڵەوە',
        'visits_en': '5 Home Visits',
        'visits_ar': '٥ زيارات منزلية',
        'original_price': 125000.0,
        'discount_price': 89000.0,
        'discount_percent': '28%',
        'color': const Color(0xFF0D9488),
      },
      {
        'id': 'pkg_elderly',
        'title': 'پاکێجی چاودێری بەساڵاچووان',
        'title_en': 'Elderly Routine Home Care',
        'title_ar': 'باقة رعاية كبار السن المنزلية',
        'desc': 'پێوانی ڕۆژانەی پەستان و شەکرە، دانان و بەڕێوەبردنی دەرمان، چاودێری تەندروستی (٧ ڕۆژ)',
        'desc_en': 'Daily vitals monitoring, medication schedule, and general home hygiene (7 days)',
        'desc_ar': 'متابعة السكر والضغط يومياً وتنظيم الأدوية والرعاية (٧ أيام)',
        'visits': '٧ سەردانی هەفتانە',
        'visits_en': '7 Weekly Visits',
        'visits_ar': '٧ زيارات أسبوعية',
        'original_price': 175000.0,
        'discount_price': 119000.0,
        'discount_percent': '32%',
        'color': const Color(0xFF2563EB),
      },
      {
        'id': 'pkg_shift_12h',
        'title': 'پاکێجی مانەوەی پەرستار (١٢ کاتژمێری)',
        'title_en': '12-Hour Intensive Home Nursing Shift',
        'title_ar': 'باقة شفت تمريض منزلي (١٢ ساعة)',
        'desc': 'مانەوەی تەواوی پەرستاری پسپۆڕ بۆ ماوەی ١٢ کاتژمێر بۆ چاودێری وردی نەخۆشی تایبەت',
        'desc_en': 'Full shift 12 hours dedicated certified nursing care at home',
        'desc_ar': 'ممرض متخصص متواجد ١٢ ساعة متواصلة لرعاية الحالات الحرجة',
        'visits': 'شەفتی ١٢ کاتژمێری',
        'visits_en': '12-Hour Shift',
        'visits_ar': 'شفت ١٢ ساعة',
        'original_price': 90000.0,
        'discount_price': 65000.0,
        'discount_percent': '27%',
        'color': const Color(0xFF8B5CF6),
      },
    ];
  }

  Future<void> _fetchDynamicData() async {
    setState(() => _isLoading = true);
    try {
      final resList = await Future.wait([
        ApiClient.get('/service-categories?scope=nursing'),
        ApiClient.get('/labs/staff'),
      ]);

      final categoriesRes = resList[0];
      final staffRes = resList[1];

      // 1. Dynamic Nursing Categories / Procedures from Live API
      if (categoriesRes.statusCode == 200) {
        final decoded = jsonDecode(categoriesRes.body);
        if (decoded is List && decoded.isNotEmpty) {
          final icons = [
            Iconsax.health,
            Iconsax.activity,
            Iconsax.drop,
            Iconsax.shield_tick,
            Iconsax.scissor,
            Iconsax.blend,
            Iconsax.heart,
            Iconsax.firstline,
          ];
          final durations = ['١٥ خولەک', '٢٠ خولەک', '٣٠ خولەک', '٤٥ خولەک', '١ کاتژمێر'];
          final durationsEn = ['15 min', '20 min', '30 min', '45 min', '1 hr'];
          final durationsAr = ['١٥ دقيقة', '٢٠ دقيقة', '٣٠ دقيقة', '٤٥ دقيقة', 'ساعة'];
          final prices = [10000.0, 15000.0, 20000.0, 25000.0, 30000.0, 12000.0, 18000.0];

          final List<Map<String, dynamic>> dynamicServices = [];
          for (int i = 0; i < decoded.length; i++) {
            final cat = decoded[i];
            final id = 'cat_nurse_${cat['id']}';
            final name = cat['name']?.toString() ?? '';
            final nameEn = cat['name_en']?.toString() ?? name;
            final nameAr = cat['name_ar']?.toString() ?? name;

            dynamicServices.add({
              'id': id,
              'api_id': cat['id'],
              'name': name,
              'name_en': nameEn,
              'name_ar': nameAr,
              'price': prices[i % prices.length],
              'duration': durations[i % durations.length],
              'duration_en': durationsEn[i % durationsEn.length],
              'duration_ar': durationsAr[i % durationsAr.length],
              'icon': icons[i % icons.length],
            });
          }
          if (dynamicServices.isNotEmpty) {
            _nursingPriceList = dynamicServices;
          }
        }
      }

      // 2. Dynamic Specialist Nurse Staff from Live API
      if (staffRes.statusCode == 200) {
        final decoded = jsonDecode(staffRes.body);
        final list = (decoded['data'] as List? ?? []);
        if (list.isNotEmpty) {
          _staffList = list.map((e) {
            final s = Map<String, dynamic>.from(e);
            return {
              'id': s['id'].toString(),
              'nurse_id': s['nurse_id']?.toString() ?? s['id'].toString(),
              'name': s['name'] ?? '',
              'name_en': s['name_en'] ?? s['name'] ?? '',
              'name_ar': s['name_ar'] ?? s['name'] ?? '',
              'title': s['title'] ?? s['specialty'] ?? 'nursing_verified_nurse'.tr(),
              'title_en': s['name_en'] != null ? 'Certified Specialist Nurse' : 'Specialist Nurse',
              'title_ar': s['name_ar'] != null ? (s['title'] ?? 'ممرض مرخص ومعتمد') : 'ممرض معتمد',
              'specialty': s['specialty'] ?? s['title'] ?? '',
              'lab': s['lab_name'] ?? 'تیمی پەرستاری دکتۆر ڕووم',
              'lab_id': s['lab_id'] ?? s['lab_user_id'] ?? s['id'],
              'rating': (s['rating'] as num?)?.toDouble() ?? 4.9,
              'reviews': s['reviews_count'] ?? 50,
              'city': s['city'] ?? 'هەولێر',
              'city_en': s['city'] == 'هەولێر' ? 'Erbil' : (s['city'] == 'سلێمانی' ? 'Sulaymaniyah' : (s['city'] ?? '')),
              'city_ar': s['city'] == 'هەولێر' ? 'أربيل' : (s['city'] == 'سلێمانی' ? 'السليمانية' : (s['city'] ?? '')),
              'visit_fee': (s['fee'] as num?)?.toDouble() ?? 15000.0,
              'image': s['image'],
            };
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching nursing API data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleServiceInCart(Map<String, dynamic> service) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final isAdded = cart.items.any((i) => i.id == service['id']);
    final serviceName = _getLocalized(service, 'name');

    if (isAdded) {
      cart.removeItem(service['id']);
    } else {
      cart.setServiceType('nursing');
      cart.addItem(CartItem(
        id: service['id'],
        name: serviceName,
        price: (service['price'] as num).toDouble(),
        quantity: 1,
        extraData: {'type': 'nursing_service'},
      ));
    }
    setState(() {});

    final msg = isAdded
        ? '$serviceName ${'nursing_removed_from_cart'.tr()}'
        : '$serviceName ${'nursing_added_to_cart'.tr()}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            Icon(
              isAdded ? Icons.remove_circle_outline_rounded : Icons.check_circle_rounded,
              color: isAdded ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(fontFamily: 'Rabar', fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addPackageToCart(Map<String, dynamic> pkg) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final pkgTitle = _getLocalized(pkg, 'title');

    cart.setServiceType('nursing');
    cart.addItem(CartItem(
      id: pkg['id'],
      name: pkgTitle,
      price: (pkg['discount_price'] as num).toDouble(),
      quantity: 1,
      extraData: {'type': 'care_package', 'visits': pkg['visits']},
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$pkgTitle ${'nursing_added_to_cart'.tr()}',
                style: const TextStyle(fontFamily: 'Rabar', fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectStaff(Map<String, dynamic> staff) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    cart.items.removeWhere((item) =>
        item.extraData?['type'] == 'staff' || item.id.startsWith('staff_'));

    final fee = (staff['visit_fee'] as num?)?.toDouble() ?? 15000.0;
    final staffName = _getLocalized(staff, 'name');
    final staffTitle = _getLocalized(staff, 'title');
    final staffCity = _getLocalized(staff, 'city');

    cart.setServiceType('nursing', extraFee: fee);
    cart.addItem(CartItem(
      id: 'staff_${staff['id']}',
      name: '${'nursing_verified_nurse'.tr()} ($staffName)',
      price: fee,
      quantity: 1,
      extraData: {
        'type': 'staff',
        'staff_id': staff['id'],
        'staff_name': staffName,
        'staff_title': staffTitle,
        'city': staffCity,
      },
    ));
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$staffName ${'nursing_staff_selected_msg'.tr()}',
                style: const TextStyle(fontFamily: 'Rabar', fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 1. Select Services Modal (Dynamic from API) ──
  void _showSelectServicesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        String query = '';

        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = _nursingPriceList.where((s) {
              final q = query.toLowerCase();
              return s['name'].toString().toLowerCase().contains(q) ||
                  (s['name_en'] ?? '').toString().toLowerCase().contains(q) ||
                  (s['name_ar'] ?? '').toString().toLowerCase().contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'nursing_item_1'.tr(),
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        onChanged: (v) => setModalState(() => query = v),
                        style: const TextStyle(fontFamily: 'Rabar', fontSize: 13.5),
                        decoration: InputDecoration(
                          hintText: 'nursing_search_service'.tr(),
                          hintStyle: const TextStyle(fontFamily: 'Rabar', fontSize: 13, color: Color(0xFF94A3B8)),
                          prefixIcon: const Icon(Iconsax.search_normal_1, size: 18, color: Color(0xFF94A3B8)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              'no_results_found'.tr(),
                              style: const TextStyle(fontFamily: 'Rabar', fontSize: 14, color: Color(0xFF94A3B8)),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, idx) {
                              final item = filtered[idx];
                              final cart = Provider.of<CartProvider>(context);
                              final inCart = cart.items.any((i) => i.id == item['id']);
                              final localizedName = _getLocalized(item, 'name');
                              final localizedDuration = _getLocalized(item, 'duration');

                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: inCart
                                        ? const Color(0xFF0D9488)
                                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                    width: inCart ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(item['icon'] as IconData, color: const Color(0xFF0D9488), size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            localizedName,
                                            style: TextStyle(
                                              fontFamily: 'Rabar',
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${'nursing_duration'.tr()} $localizedDuration',
                                            style: const TextStyle(fontFamily: 'Rabar', fontSize: 11.5, color: Color(0xFF64748B)),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            Currency.format(item['price']),
                                            style: const TextStyle(
                                              fontFamily: 'Rabar',
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF10B981),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: inCart ? const Color(0xFF10B981) : const Color(0xFF0D9488),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        elevation: 0,
                                      ),
                                      onPressed: () {
                                        _toggleServiceInCart(item);
                                        setModalState(() {});
                                      },
                                      child: Text(
                                        inCart
                                            ? '${'nursing_selected_service_badge'.tr()} ✓'
                                            : 'nursing_select_service_btn'.tr(),
                                        style: const TextStyle(fontFamily: 'Rabar', fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── 2. Emergency & Rapid Request Modal (Translated) ──
  void _showFastEmergencyModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emergency_rounded, color: Color(0xFFEF4444), size: 34),
              ),
              const SizedBox(height: 16),
              Text(
                'nursing_item_2'.tr(),
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'nursing_fast_dispatch_desc'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 12.5,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_rounded, color: Color(0xFFEF4444), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${'nursing_est_arrival'.tr()} ${'nursing_arrival_time_val'.tr()}',
                        style: const TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SosScreen()),
                        );
                      },
                      child: Text(
                        'nursing_sos_call'.tr(),
                        style: const TextStyle(fontFamily: 'Rabar', fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                      ),
                      onPressed: () {
                        final cart = Provider.of<CartProvider>(context, listen: false);
                        cart.setServiceType('nursing');
                        cart.addItem(CartItem(
                          id: 'urgent_nurse_dispatch',
                          name: 'nursing_urgent_dispatch'.tr(),
                          price: 25000.0,
                          quantity: 1,
                          extraData: {'urgent': true},
                        ));
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CheckoutDetailsScreen()),
                        );
                      },
                      child: Text(
                        'nursing_urgent_send_now'.tr(),
                        style: const TextStyle(fontFamily: 'Rabar', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── 3. Select Specialist Staff Modal (Live from API) ──
  void _showStaffSelectionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        String query = '';

        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredStaff = _staffList.where((s) {
              final q = query.toLowerCase();
              return (s['name'] ?? '').toString().toLowerCase().contains(q) ||
                  (s['name_en'] ?? '').toString().toLowerCase().contains(q) ||
                  (s['name_ar'] ?? '').toString().toLowerCase().contains(q) ||
                  (s['city'] ?? '').toString().toLowerCase().contains(q) ||
                  (s['title'] ?? '').toString().toLowerCase().contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'nursing_item_3'.tr(),
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'nursing_item_3_desc'.tr(),
                    style: const TextStyle(fontFamily: 'Rabar', fontSize: 12.5, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 14),

                  // Search box for staff
                  Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      onChanged: (v) => setModalState(() => query = v),
                      style: const TextStyle(fontFamily: 'Rabar', fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'nursing_search_staff'.tr(),
                        hintStyle: const TextStyle(fontFamily: 'Rabar', fontSize: 13, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Iconsax.search_normal_1, size: 18, color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(color: Color(0xFF0D9488)),
                          )
                        : filteredStaff.isEmpty
                            ? Center(
                                child: Text(
                                  'no_results_found'.tr(),
                                  style: const TextStyle(fontFamily: 'Rabar', fontSize: 14, color: Color(0xFF94A3B8)),
                                ),
                              )
                            : ListView.separated(
                                itemCount: filteredStaff.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 12),
                                itemBuilder: (context, idx) {
                                  final staff = filteredStaff[idx];
                                  final cart = Provider.of<CartProvider>(context, listen: false);
                                  final isSelected = cart.items.any((item) =>
                                      (item.extraData?['type'] == 'staff' || item.id.startsWith('staff_')) &&
                                      item.extraData?['staff_id'] == staff['id']);
                                  final imgUrl = staff['image'] != null && staff['image'].toString().isNotEmpty
                                      ? ApiClient.getImageUrl(staff['image'].toString())
                                      : null;
                                  final localizedStaffName = _getLocalized(staff, 'name');
                                  final localizedStaffTitle = _getLocalized(staff, 'title');
                                  final localizedStaffCity = _getLocalized(staff, 'city');

                                  return Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF10B981)
                                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(14),
                                          child: imgUrl != null
                                              ? Image.network(
                                                  imgUrl,
                                                  width: 52,
                                                  height: 52,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, _, _) => Container(
                                                    width: 52,
                                                    height: 52,
                                                    color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                                                    child: const Icon(Iconsax.profile_circle, color: Color(0xFF0D9488), size: 28),
                                                  ),
                                                )
                                              : Container(
                                                  width: 52,
                                                  height: 52,
                                                  color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                                                  child: const Icon(Iconsax.profile_circle, color: Color(0xFF0D9488), size: 28),
                                                ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      localizedStaffName,
                                                      style: TextStyle(
                                                        fontFamily: 'Rabar',
                                                        fontSize: 14.5,
                                                        fontWeight: FontWeight.bold,
                                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (localizedStaffCity.isNotEmpty)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        localizedStaffCity,
                                                        style: const TextStyle(
                                                          fontFamily: 'Rabar',
                                                          fontSize: 10.5,
                                                          fontWeight: FontWeight.bold,
                                                          color: Color(0xFF0D9488),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                localizedStaffTitle.isNotEmpty
                                                    ? localizedStaffTitle
                                                    : 'nursing_verified_nurse'.tr(),
                                                style: const TextStyle(fontFamily: 'Rabar', fontSize: 11.5, color: Color(0xFF64748B)),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 15),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    '${staff['rating']} (${staff['reviews']} ${'nursing_reviews'.tr()})',
                                                    style: const TextStyle(fontFamily: 'Rabar', fontSize: 11, fontWeight: FontWeight.bold),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '${'nursing_visit_fee'.tr()} ${Currency.format(staff['visit_fee'])}',
                                                    style: const TextStyle(
                                                      fontFamily: 'Rabar',
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF10B981),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isSelected ? const Color(0xFF10B981) : const Color(0xFF0D9488),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            elevation: 0,
                                          ),
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            _selectStaff(staff);
                                          },
                                          child: Text(
                                            isSelected
                                                ? 'nursing_staff_already_selected'.tr()
                                                : 'nursing_select_service_btn'.tr(),
                                            style: const TextStyle(fontFamily: 'Rabar', fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── 4. Service Price Schedule Modal (From Dynamic API) ──
  void _showPriceListModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        String query = '';

        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = _nursingPriceList.where((item) {
              final q = query.toLowerCase();
              return item['name'].toString().toLowerCase().contains(q) ||
                  (item['name_en'] ?? '').toString().toLowerCase().contains(q) ||
                  (item['name_ar'] ?? '').toString().toLowerCase().contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'nursing_item_4'.tr(),
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'nursing_item_4_desc'.tr(),
                    style: const TextStyle(fontFamily: 'Rabar', fontSize: 12.5, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 14),

                  Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      onChanged: (v) => setModalState(() => query = v),
                      style: const TextStyle(fontFamily: 'Rabar', fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'nursing_search_service'.tr(),
                        hintStyle: const TextStyle(fontFamily: 'Rabar', fontSize: 13, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Iconsax.search_normal_1, size: 18, color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              'no_results_found'.tr(),
                              style: const TextStyle(fontFamily: 'Rabar', fontSize: 14, color: Color(0xFF94A3B8)),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, idx) {
                              final item = filtered[idx];
                              final localizedName = _getLocalized(item, 'name');
                              final localizedDuration = _getLocalized(item, 'duration');

                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(item['icon'] as IconData, color: const Color(0xFFF59E0B), size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            localizedName,
                                            style: TextStyle(
                                              fontFamily: 'Rabar',
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${'nursing_duration'.tr()} $localizedDuration',
                                            style: const TextStyle(fontFamily: 'Rabar', fontSize: 11, color: Color(0xFF64748B)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            Currency.format(item['price']),
                                            style: const TextStyle(
                                              fontFamily: 'Rabar',
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF10B981),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        IconButton(
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(4),
                                          icon: const Icon(Iconsax.add_circle, color: Color(0xFF0D9488), size: 22),
                                          onPressed: () {
                                            _toggleServiceInCart(item);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── 5. Patient Care Packages Modal (Translated) ──
  void _showCarePackagesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        String query = '';

        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = _carePackages.where((pkg) {
              final q = query.toLowerCase();
              return pkg['title'].toString().toLowerCase().contains(q) ||
                  (pkg['title_en'] ?? '').toString().toLowerCase().contains(q) ||
                  (pkg['title_ar'] ?? '').toString().toLowerCase().contains(q) ||
                  (pkg['desc'] ?? '').toString().toLowerCase().contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'nursing_item_5'.tr(),
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'nursing_item_5_desc'.tr(),
                    style: const TextStyle(fontFamily: 'Rabar', fontSize: 12.5, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 14),

                  Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      onChanged: (v) => setModalState(() => query = v),
                      style: const TextStyle(fontFamily: 'Rabar', fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'nursing_search_packages'.tr(),
                        hintStyle: const TextStyle(fontFamily: 'Rabar', fontSize: 13, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Iconsax.search_normal_1, size: 18, color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              'no_results_found'.tr(),
                              style: const TextStyle(fontFamily: 'Rabar', fontSize: 14, color: Color(0xFF94A3B8)),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 14),
                            itemBuilder: (context, idx) {
                              final pkg = filtered[idx];
                              final localizedTitle = _getLocalized(pkg, 'title');
                              final localizedVisits = _getLocalized(pkg, 'visits');
                              final localizedDesc = _getLocalized(pkg, 'desc');

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: (pkg['color'] as Color).withValues(alpha: 0.35),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: (pkg['color'] as Color).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(Iconsax.shield_security, color: pkg['color'], size: 20),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                localizedTitle,
                                                style: TextStyle(
                                                  fontFamily: 'Rabar',
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                ),
                                              ),
                                              Text(
                                                localizedVisits,
                                                style: const TextStyle(
                                                  fontFamily: 'Rabar',
                                                  fontSize: 11,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '-${pkg['discount_percent']}',
                                            style: const TextStyle(
                                              fontFamily: 'Rabar',
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFEF4444),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      localizedDesc,
                                      style: const TextStyle(
                                        fontFamily: 'Rabar',
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              Currency.format(pkg['original_price']),
                                              style: const TextStyle(
                                                fontFamily: 'Rabar',
                                                fontSize: 12,
                                                decoration: TextDecoration.lineThrough,
                                                color: Color(0xFF94A3B8),
                                              ),
                                            ),
                                            Text(
                                              Currency.format(pkg['discount_price']),
                                              style: TextStyle(
                                                fontFamily: 'Rabar',
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: pkg['color'],
                                              ),
                                            ),
                                          ],
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: pkg['color'],
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                            elevation: 0,
                                          ),
                                          onPressed: () {
                                            _addPackageToCart(pkg);
                                            Navigator.pop(ctx);
                                          },
                                          child: Text(
                                            'nursing_order_package_btn'.tr(),
                                            style: const TextStyle(fontFamily: 'Rabar', fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cart = Provider.of<CartProvider>(context);

    CartItem? selectedStaffItem;
    for (final item in cart.items) {
      if (item.extraData?['type'] == 'staff' || item.id.startsWith('staff_')) {
        selectedStaffItem = item;
        break;
      }
    }

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'nursing_hub_title'.tr(),
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'nursing_hub_subtitle'.tr(),
                          style: const TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NurseListScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Iconsax.profile_2user, color: Color(0xFF0D9488), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            _staffList.isNotEmpty
                                ? '${'nursing_all_nurses'.tr()} (${_staffList.length})'
                                : 'nursing_all_nurses'.tr(),
                            style: const TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D9488),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: LinearProgressIndicator(
                  minHeight: 2.5,
                  backgroundColor: Colors.transparent,
                  color: Color(0xFF0D9488),
                ),
              ),

            // ── Main 7 Feature Cards List ──
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchDynamicData,
                color: const Color(0xFF0D9488),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
                  children: [
                    // 1. هەڵبژاردنی خزمەتگوزاری
                    _buildFeatureCard(
                      context: context,
                      isDark: isDark,
                      number: '١',
                      title: 'nursing_item_1'.tr(),
                      subtitle: 'nursing_item_1_desc'.tr(),
                      icon: Iconsax.health,
                      color: const Color(0xFF0D9488),
                      badgeText: '${_nursingPriceList.length} ${'nursing_services_count'.tr()}',
                      onTap: _showSelectServicesModal,
                    ),

                    // 2. فریاکەوتن و داواکاری خێرا
                    _buildFeatureCard(
                      context: context,
                      isDark: isDark,
                      number: '٢',
                      title: 'nursing_item_2'.tr(),
                      subtitle: 'nursing_item_2_desc'.tr(),
                      icon: Icons.emergency_rounded,
                      color: const Color(0xFFEF4444),
                      badgeText: 'nursing_urgent_badge'.tr(),
                      onTap: _showFastEmergencyModal,
                    ),

                    // 3. هەڵبژاردنی ستاف
                    _buildFeatureCard(
                      context: context,
                      isDark: isDark,
                      number: '٣',
                      title: 'nursing_item_3'.tr(),
                      subtitle: 'nursing_item_3_desc'.tr(),
                      icon: Iconsax.people,
                      color: const Color(0xFF8B5CF6),
                      badgeText: selectedStaffItem != null
                          ? (selectedStaffItem.extraData?['staff_name'] ?? 'nursing_selected_service_badge'.tr())
                          : (_staffList.isNotEmpty ? '${_staffList.length} ${'nursing_staff_count'.tr()}' : null),
                      onTap: _showStaffSelectionModal,
                    ),

                    // 4. نرخی خزمەتگوزارییەکان
                    _buildFeatureCard(
                      context: context,
                      isDark: isDark,
                      number: '٤',
                      title: 'nursing_item_4'.tr(),
                      subtitle: 'nursing_item_4_desc'.tr(),
                      icon: Iconsax.tag,
                      color: const Color(0xFFF59E0B),
                      badgeText: 'nursing_transparent_prices'.tr(),
                      onTap: _showPriceListModal,
                    ),

                    // 5. پاکێجی چاودێریکردنی نەخۆش
                    _buildFeatureCard(
                      context: context,
                      isDark: isDark,
                      number: '٥',
                      title: 'nursing_item_5'.tr(),
                      subtitle: 'nursing_item_5_desc'.tr(),
                      icon: Iconsax.shield_security,
                      color: const Color(0xFFEC4899),
                      badgeText: '${_carePackages.length} ${'nursing_packages_count'.tr()}',
                      onTap: _showCarePackagesModal,
                    ),

                    // 6. ئەرشیفی داواکارییەکانم
                    _buildFeatureCard(
                      context: context,
                      isDark: isDark,
                      number: '٦',
                      title: 'nursing_item_6'.tr(),
                      subtitle: 'nursing_item_6_desc'.tr(),
                      icon: Iconsax.archive_book,
                      color: const Color(0xFF3B82F6),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MyRequestsScreen()),
                        );
                      },
                    ),

                    // 7. پوختەی داواکاری و ناردن
                    _buildFeatureCard(
                      context: context,
                      isDark: isDark,
                      number: '٧',
                      title: 'nursing_item_7'.tr(),
                      subtitle: 'nursing_item_7_desc'.tr(),
                      icon: Iconsax.send_2,
                      color: const Color(0xFF10B981),
                      badgeText: cart.items.isNotEmpty
                          ? '${cart.items.length} ${'nursing_available_count'.tr()}'
                          : null,
                      onTap: () {
                        if (cart.items.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF0F172A),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              content: Text(
                                'nursing_select_service_first'.tr(),
                                style: const TextStyle(fontFamily: 'Rabar'),
                              ),
                            ),
                          );
                          _showSelectServicesModal();
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CheckoutDetailsScreen()),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ── Bottom Cart Floater ──
      bottomNavigationBar: cart.items.isNotEmpty
          ? Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Row(
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${cart.items.length} ${'nursing_selected_services_count'.tr()}',
                            style: const TextStyle(fontFamily: 'Rabar', fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                          Text(
                            Currency.format(cart.total),
                            style: const TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CheckoutDetailsScreen()),
                          );
                        },
                        icon: const Icon(Iconsax.arrow_right_3, size: 16, color: Colors.white),
                        label: Text(
                          'nursing_checkout_action'.tr(),
                          style: const TextStyle(fontFamily: 'Rabar', fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required bool isDark,
    required String number,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.topLeft,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        number,
                        style: const TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          if (badgeText != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                badgeText,
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
