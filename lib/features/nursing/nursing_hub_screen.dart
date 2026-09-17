import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import '../../core/providers/cart_provider.dart';
import '../../core/utils/currency.dart';
import '../checkout/checkout_details_screen.dart';
import '../requests/my_requests_screen.dart';
import '../emergency/sos_screen.dart';
import 'nurse_list_screen.dart';
import 'nursing_services_screen.dart';

class NursingHubScreen extends StatefulWidget {
  const NursingHubScreen({super.key});

  @override
  State<NursingHubScreen> createState() => _NursingHubScreenState();
}

class _NursingHubScreenState extends State<NursingHubScreen> {
  // Nursing Services Price List
  final List<Map<String, dynamic>> _nursingPriceList = [
    {
      'id': 'inj_im',
      'name': 'لێدانی دەرزی (ماسولکە یان دەمار)',
      'name_en': 'Injection (IM / IV)',
      'price': 10000.0,
      'duration': '١٥ خولەک',
      'icon': Iconsax.health,
    },
    {
      'id': 'cannula',
      'name': 'دانانی کانیۆلا و دەرزی دەمار',
      'name_en': 'IV Cannula Insertion',
      'price': 15000.0,
      'duration': '٢٠ خولەک',
      'icon': Iconsax.activity,
    },
    {
      'id': 'serum',
      'name': 'بەستنی موغەزی (سیرۆم)',
      'name_en': 'IV Fluid Infusion (Serum)',
      'price': 20000.0,
      'duration': '٤٥ خولەک',
      'icon': Iconsax.drop,
    },
    {
      'id': 'wound',
      'name': 'پاککردنەوە و پانسمانی برین',
      'name_en': 'Wound Cleaning & Dressing',
      'price': 25000.0,
      'duration': '٣٠ خولەک',
      'icon': Iconsax.shield_tick,
    },
    {
      'id': 'stitches',
      'name': 'لابردنی تەلی نەشتەرگەری (تەقەڵ)',
      'name_en': 'Suture / Stitch Removal',
      'price': 20000.0,
      'duration': '٢٥ خولەک',
      'icon': Iconsax.scissor,
    },
    {
      'id': 'catheter',
      'name': 'دانان و گۆڕینی سۆندەی میز (Catheter)',
      'name_en': 'Urinary Catheter Insertion',
      'price': 25000.0,
      'duration': '٣٠ خولەک',
      'icon': Iconsax.blend,
    },
    {
      'id': 'vitals',
      'name': 'پێوانی پەستان، شەکرە و ئۆکسجین',
      'name_en': 'Vital Signs Monitoring Check',
      'price': 10000.0,
      'duration': '١٥ خولەک',
      'icon': Iconsax.heart,
    },
  ];

  // Nursing Care Packages
  final List<Map<String, dynamic>> _carePackages = [
    {
      'id': 'pkg_post_op',
      'title': 'پاکێجی چاودێری پاش نەشتەرگەری',
      'title_en': 'Post-Operative Recovery Package',
      'desc': 'چاودێری برین، لێدانی دەرمانی ئازارشکێن و دژەهەوکردن، پێوانی نیشانە سەرەکییەکان (٥ سەردان)',
      'visits': '٥ سەردانی ماڵەوە',
      'original_price': 125000.0,
      'discount_price': 89000.0,
      'discount_percent': '28%',
      'color': const Color(0xFF0D9488),
    },
    {
      'id': 'pkg_elderly',
      'title': 'پاکێجی چاودێری بەساڵاچووان',
      'title_en': 'Elderly Routine Home Care',
      'desc': 'پێوانی ڕۆژانەی پەستان و شەکرە، دانان و بەڕێوەبردنی دەرمان، پاکوخاوێنی و چاودێری تەندروستی (٧ ڕۆژ)',
      'visits': '٧ سەردانی هەفتانە',
      'original_price': 175000.0,
      'discount_price': 119000.0,
      'discount_percent': '32%',
      'color': const Color(0xFF2563EB),
    },
    {
      'id': 'pkg_shift_12h',
      'title': 'پاکێجی مانەوەی پەرستار (١٢ کاتژمێری)',
      'title_en': '12-Hour Intensive Home Nursing Shift',
      'desc': 'مانەوەی تەواوی پەرستاری پسپۆڕ بۆ ماوەی ١٢ کاتژمێر بۆ چاودێری وردی نەخۆشی تایبەت',
      'visits': 'شەفتی ١٢ کاتژمێری',
      'original_price': 90000.0,
      'discount_price': 65000.0,
      'discount_percent': '27%',
      'color': const Color(0xFF8B5CF6),
    },
    {
      'id': 'pkg_diabetic_foot',
      'title': 'پاکێجی چاودێری برینی شەکرە (Diabetic Foot)',
      'title_en': 'Diabetic Wound Care Package',
      'desc': 'پاککردنەوەی برینی ئاڵۆز بە کەرەستەی ستەریل، چاودێری بەردەوامی شەکرە و پێشگیری لە هەوکردن (٦ سەردان)',
      'visits': '٦ سەردان',
      'original_price': 150000.0,
      'discount_price': 105000.0,
      'discount_percent': '30%',
      'color': const Color(0xFFE11D48),
    },
  ];

  void _addServiceToCart(Map<String, dynamic> service) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    cart.setServiceType('nursing');
    cart.addItem(CartItem(
      id: service['id'],
      name: service['name'],
      price: (service['price'] as num).toDouble(),
      quantity: 1,
      extraData: {'type': 'nursing_service'},
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
                '${service['name']} زیادکرا بۆ سەبەتە',
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
    cart.setServiceType('nursing');
    cart.addItem(CartItem(
      id: pkg['id'],
      name: pkg['title'],
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
                '${pkg['title']} زیادکرا بۆ سەبەتە',
                style: const TextStyle(fontFamily: 'Rabar', fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emergency_rounded, color: Color(0xFFEF4444), size: 32),
              ),
              const SizedBox(height: 14),
              Text(
                'nursing_item_2'.tr(),
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'داواکاری خێرای پەرستار بۆ ماڵەوە لە کاتی نائاسایی بە پێشینەی سەرەکی',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 12.5,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              // Rapid Dispatch Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.timer_rounded, color: Color(0xFFEF4444), size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'کاتی خەمڵێنراوی گەیشتن: ١٥ بۆ ٣٠ خولەک بەپێی شوێنەکەت',
                        style: TextStyle(
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
                      child: const Text('پەیوەندی کتوپڕ (SOS)', style: TextStyle(fontFamily: 'Rabar', fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: () {
                        final cart = Provider.of<CartProvider>(context, listen: false);
                        cart.setServiceType('nursing');
                        cart.addItem(CartItem(
                          id: 'urgent_nurse_dispatch',
                          name: 'ناردنی بەپەلەی پەرستار (فریاکەوتنی خێرا)',
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
                      child: const Text(
                        'ناردنی خێرا ئێستا',
                        style: TextStyle(fontFamily: 'Rabar', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
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

  void _showPriceListModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return Container(
          height: MediaQuery.of(context).size.height * 0.78,
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
              Text(
                'nursing_item_4'.tr(),
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'nursing_item_4_desc'.tr(),
                style: const TextStyle(fontFamily: 'Rabar', fontSize: 12.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: _nursingPriceList.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final item = _nursingPriceList[idx];

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
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
                              color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(item['icon'] as IconData, color: const Color(0xFF0D9488), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'],
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item['name_en']} • کات: ${item['duration']}',
                                  style: const TextStyle(fontFamily: 'Rabar', fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                Currency.format(item['price']),
                                style: const TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () => _addServiceToCart(item),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D9488),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    '+ داواکردن',
                                    style: TextStyle(fontFamily: 'Rabar', fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
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
  }

  void _showCarePackagesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

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
              Text(
                'nursing_item_5'.tr(),
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'nursing_item_5_desc'.tr(),
                style: const TextStyle(fontFamily: 'Rabar', fontSize: 12.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: _carePackages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, idx) {
                    final pkg = _carePackages[idx];

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
                                child: Text(
                                  pkg['title'],
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'داشکاندن ${pkg['discount_percent']}',
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
                            pkg['desc'],
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
                                ),
                                onPressed: () {
                                  _addPackageToCart(pkg);
                                  Navigator.pop(ctx);
                                },
                                child: const Text(
                                  'داواکردنی پاکێج',
                                  style: TextStyle(fontFamily: 'Rabar', fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cart = Provider.of<CartProvider>(context);

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
                        const Text(
                          'خزمەتگوزاری پەرستاری و چاودێری نەخۆش لە ماڵەوە',
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
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
                        children: const [
                          Icon(Iconsax.profile_2user, color: Color(0xFF0D9488), size: 16),
                          SizedBox(width: 6),
                          Text(
                            'پەرستاران',
                            style: TextStyle(
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

            // ── Main 7 Feature Cards List ──
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 100),
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NursingServicesScreen()),
                      );
                    },
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
                    badgeText: 'خێرا / بەپەلە',
                    onTap: _showFastEmergencyModal,
                  ),

                  // 3. هەڵبژاردنی ستاف
                  _buildFeatureCard(
                    context: context,
                    isDark: isDark,
                    number: '٣',
                    title: 'nursing_item_3'.tr(),
                    subtitle: 'nursing_item_3_desc'.tr(),
                    icon: Iconsax.profile_2user,
                    color: const Color(0xFF2563EB),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NurseListScreen()),
                      );
                    },
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
                    color: const Color(0xFF8B5CF6),
                    badgeText: 'داشکاندن',
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
                    badgeText: cart.items.isNotEmpty ? '${cart.items.length} بەردەست' : null,
                    onTap: () {
                      if (cart.items.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Color(0xFF0F172A),
                            content: Text(
                              'تکایە سەرەتا خزمەتگوزاری یان پاکێجێک دیاری بکە',
                              style: TextStyle(fontFamily: 'Rabar'),
                            ),
                          ),
                        );
                        _showPriceListModal();
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
          ],
        ),
      ),

      // ── Bottom Cart Floater ──
      bottomSheet: cart.items.isNotEmpty
          ? Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${cart.items.length} خزمەتگوزاری دیاریکراو',
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
                    label: const Text(
                      'تەواوکردنی داواکاری',
                      style: TextStyle(fontFamily: 'Rabar', fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
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
