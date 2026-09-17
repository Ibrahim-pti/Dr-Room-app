import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import '../../core/providers/cart_provider.dart';
import '../../core/utils/currency.dart';
import '../checkout/checkout_details_screen.dart';
import '../requests/my_requests_screen.dart';
import '../ai_assistant/ai_symptom_checker_screen.dart';
import 'upload_prescription_screen.dart';
import 'all_labs_screen.dart';

class LabHubScreen extends StatefulWidget {
  const LabHubScreen({super.key});

  @override
  State<LabHubScreen> createState() => _LabHubScreenState();
}

class _LabHubScreenState extends State<LabHubScreen> {
  // Test Catalog
  final List<Map<String, dynamic>> _testsList = [
    {
      'id': 'cbc',
      'name': 'Complete Blood Count (CBC)',
      'name_ku': 'پشکنینی گشتی خوێن (CBC)',
      'price': 15000.0,
      'category': 'خوێن',
      'lab': 'تاقیگەی پزیشکی ڕازی',
    },
    {
      'id': 'lipid',
      'name': 'Lipid Profile',
      'name_ku': 'پشکنینی چەورییەکان (Lipid Profile)',
      'price': 25000.0,
      'category': 'دڵ و چەوری',
      'lab': 'تاقیگەی مۆدێرن',
    },
    {
      'id': 'fbs',
      'name': 'Fasting Blood Sugar (FBS)',
      'name_ku': 'پشکنینی شەکرە بە نەخواردن (FBS)',
      'price': 8000.0,
      'category': 'شەکرە',
      'lab': 'تاقیگەی پزیشکی هەولێر',
    },
    {
      'id': 'hba1c',
      'name': 'HbA1c (Cumulative Sugar)',
      'name_ku': 'تێکڕای شەکری سێ مانگ (HbA1c)',
      'price': 18000.0,
      'category': 'شەکرە',
      'lab': 'تاقیگەی پزیشکی ڕازی',
    },
    {
      'id': 'vit_d',
      'name': 'Vitamin D3 (25-OH)',
      'name_ku': 'پشکنینی ڤیتامین D3',
      'price': 35000.0,
      'category': 'ڤیتامینەکان',
      'lab': 'تاقیگەی مۆدێرن',
    },
    {
      'id': 'thyroid',
      'name': 'Thyroid Panel (TSH, Free T4)',
      'name_ku': 'پشکنینی غودە (TSH & Free T4)',
      'price': 30000.0,
      'category': 'هۆرمۆن',
      'lab': 'تاقیگەی پزیشکی هەولێر',
    },
    {
      'id': 'kft',
      'name': 'Kidney Function Test (Urea, Creatinine)',
      'name_ku': 'پشکنینی گورچیلە (KFT)',
      'price': 22000.0,
      'category': 'گورچیلە',
      'lab': 'تاقیگەی پزیشکی ڕازی',
    },
    {
      'id': 'lft',
      'name': 'Liver Function Test (ALT, AST, Bilirubin)',
      'name_ku': 'پشکنینی جگەر (LFT)',
      'price': 24000.0,
      'category': 'جگەر',
      'lab': 'تاقیگەی مۆدێرن',
    },
  ];

  // Lab Packages
  final List<Map<String, dynamic>> _packagesList = [
    {
      'id': 'pkg_general',
      'title': 'پاکێجی پشکنینی گشتی تەندروستی',
      'title_en': 'Comprehensive General Health Package',
      'tests': 'CBC, FBS, Lipid, KFT, LFT, Urine, Vit D',
      'tests_count': 7,
      'original_price': 146000.0,
      'discount_price': 99000.0,
      'discount_percent': '32%',
      'color': const Color(0xFF2563EB),
      'popular': true,
    },
    {
      'id': 'pkg_diabetes',
      'title': 'پاکێجی پشکنینی شەکرە و هەرس',
      'title_en': 'Diabetes & Metabolic Health Check',
      'tests': 'FBS, HbA1c, Lipid Profile, Creatinine',
      'tests_count': 4,
      'original_price': 73000.0,
      'discount_price': 49000.0,
      'discount_percent': '33%',
      'color': const Color(0xFF0D9488),
      'popular': false,
    },
    {
      'id': 'pkg_vitamins',
      'title': 'پاکێجی ڤیتامینەکان و کانزاکان',
      'title_en': 'Vitamins & Minerals Check',
      'tests': 'Vitamin D, Vitamin B12, Iron, Ferritin, Calcium',
      'tests_count': 5,
      'original_price': 115000.0,
      'discount_price': 79000.0,
      'discount_percent': '31%',
      'color': const Color(0xFF8B5CF6),
      'popular': false,
    },
  ];

  // Staff list for home sampling
  final List<Map<String, dynamic>> _staffList = [
    {
      'id': 'st_1',
      'name': 'ئاراس عەبدولڕەحمان',
      'title': 'پسپۆڕی شیکاری نەخۆشییەکان (تاقیگە)',
      'lab': 'تاقیگەی پزیشکی ڕازی',
      'rating': 4.9,
      'reviews': 128,
      'experience': '٨ ساڵ ئەزموون',
      'visit_fee': 10000.0,
    },
    {
      'id': 'st_2',
      'name': 'لانە هیمداد ئەحمەد',
      'title': 'کارمەندی باوەڕپێکراوی خوێن ڕاکێشان',
      'lab': 'تاقیگەی مۆدێرن',
      'rating': 4.8,
      'reviews': 94,
      'experience': '٦ ساڵ ئەزموون',
      'visit_fee': 10000.0,
    },
    {
      'id': 'st_3',
      'name': 'دیار سەردار محەمەد',
      'title': 'تەکنیکاری تاقیگەی باڵا',
      'lab': 'تاقیگەی پزیشکی هەولێر',
      'rating': 4.9,
      'reviews': 156,
      'experience': '١٠ ساڵ ئەزموون',
      'visit_fee': 10000.0,
    },
  ];

  void _addTestToCart(Map<String, dynamic> test) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    cart.setServiceType('lab');
    cart.addItem(CartItem(
      id: test['id'],
      name: test['name_ku'] ?? test['name'],
      price: (test['price'] as num).toDouble(),
      quantity: 1,
      extraData: {'lab': test['lab'], 'type': 'test'},
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
                '${test['name_ku'] ?? test['name']} زیادکرا بۆ سەبەتە',
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
    cart.setServiceType('lab');
    cart.addItem(CartItem(
      id: pkg['id'],
      name: pkg['title'],
      price: (pkg['discount_price'] as num).toDouble(),
      quantity: 1,
      extraData: {'type': 'package', 'tests': pkg['tests']},
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

  void _showSelectTestsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        String query = '';

        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = _testsList.where((t) {
              final q = query.toLowerCase();
              return t['name'].toString().toLowerCase().contains(q) ||
                  (t['name_ku'] ?? '').toString().contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Handle
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
                          'lab_item_2'.tr(),
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
                          hintText: 'گەڕان بۆ پشکنین (CBC, Sugar, Lipid)...',
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
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, idx) {
                        final t = filtered[idx];
                        final cart = Provider.of<CartProvider>(context);
                        final inCart = cart.items.any((i) => i.id == t['id']);

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: inCart
                                  ? const Color(0xFF2563EB)
                                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              width: inCart ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Iconsax.health, color: Color(0xFF2563EB), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t['name_ku'] ?? t['name'],
                                      style: TextStyle(
                                        fontFamily: 'Rabar',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${t['name']} • ${t['lab']}',
                                      style: const TextStyle(
                                        fontFamily: 'Rabar',
                                        fontSize: 11.5,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      Currency.format(t['price']),
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
                                  backgroundColor: inCart ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                                onPressed: () {
                                  _addTestToCart(t);
                                  setModalState(() {});
                                },
                                child: Text(
                                  inCart ? 'زیادکراوە' : 'زیادکردن',
                                  style: const TextStyle(fontFamily: 'Rabar', fontSize: 12, color: Colors.white),
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

  void _showStaffSelectionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
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
                'lab_item_3'.tr(),
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'lab_item_3_desc'.tr(),
                style: const TextStyle(fontFamily: 'Rabar', fontSize: 12.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: _staffList.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final staff = _staffList[idx];

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
                            child: const Icon(Iconsax.profile_circle, color: Color(0xFF2563EB), size: 30),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  staff['name'],
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  staff['title'],
                                  style: const TextStyle(fontFamily: 'Rabar', fontSize: 11.5, color: Color(0xFF64748B)),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${staff['rating']} (${staff['reviews']})',
                                      style: const TextStyle(fontFamily: 'Rabar', fontSize: 11.5, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      staff['experience'],
                                      style: const TextStyle(fontFamily: 'Rabar', fontSize: 11.5, color: Color(0xFF10B981)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF2563EB)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF0F172A),
                                  content: Text(
                                    'ستاف "${staff['name']}" هەڵبژێردرا بۆ داواکارییەکەت',
                                    style: const TextStyle(fontFamily: 'Rabar'),
                                  ),
                                ),
                              );
                            },
                            child: const Text('دیاریکردن', style: TextStyle(fontFamily: 'Rabar', fontSize: 12)),
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

  void _showTestPricesModal() {
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
                'lab_item_4'.tr(),
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'lab_item_4_desc'.tr(),
                style: const TextStyle(fontFamily: 'Rabar', fontSize: 12.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: _testsList.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final t = _testsList[idx];

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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t['name_ku'] ?? t['name'],
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'تاقیگە: ${t['lab']}',
                                  style: const TextStyle(fontFamily: 'Rabar', fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              Currency.format(t['price']),
                              style: const TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
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
  }

  void _showPackagesModal() {
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
                'lab_item_5'.tr(),
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'lab_item_5_desc'.tr(),
                style: const TextStyle(fontFamily: 'Rabar', fontSize: 12.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: _packagesList.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, idx) {
                    final pkg = _packagesList[idx];

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
                                child: Icon(Iconsax.box_1, color: pkg['color'], size: 20),
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
                            'پشکنینەکان: ${pkg['tests']}',
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
                          'lab_hub_title'.tr(),
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const Text(
                          'پشکنین، ڕەچەتە، ستاف و شیکاریی AI',
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
                        MaterialPageRoute(builder: (_) => const AllLabsScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Iconsax.buildings, color: Color(0xFF2563EB), size: 16),
                          SizedBox(width: 6),
                          Text(
                            'تاقیگەکان',
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Main 8 Feature Cards Grid / List ──
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 100),
                children: [
                  // 1. بارکردنی وێنەی ڕەچەتە
                  _buildFeatureCard(
                    context: context,
                    isDark: isDark,
                    number: '١',
                    title: 'lab_item_1'.tr(),
                    subtitle: 'lab_item_1_desc'.tr(),
                    icon: Iconsax.document_upload,
                    color: const Color(0xFF2563EB),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const UploadPrescriptionScreen()),
                      );
                    },
                  ),

                  // 2. هەڵبژاردنی پشکنینەکان
                  _buildFeatureCard(
                    context: context,
                    isDark: isDark,
                    number: '٢',
                    title: 'lab_item_2'.tr(),
                    subtitle: 'lab_item_2_desc'.tr(),
                    icon: Iconsax.health,
                    color: const Color(0xFF0D9488),
                    onTap: _showSelectTestsModal,
                  ),

                  // 3. هەڵبژاردنی ستاف
                  _buildFeatureCard(
                    context: context,
                    isDark: isDark,
                    number: '٣',
                    title: 'lab_item_3'.tr(),
                    subtitle: 'lab_item_3_desc'.tr(),
                    icon: Iconsax.people,
                    color: const Color(0xFF8B5CF6),
                    onTap: _showStaffSelectionModal,
                  ),

                  // 4. نرخی پشکنینەکان لە تاقیگەکان
                  _buildFeatureCard(
                    context: context,
                    isDark: isDark,
                    number: '٤',
                    title: 'lab_item_4'.tr(),
                    subtitle: 'lab_item_4_desc'.tr(),
                    icon: Iconsax.tag,
                    color: const Color(0xFFF59E0B),
                    onTap: _showTestPricesModal,
                  ),

                  // 5. پاکێجی پشکنینەکان لە تاقیگەکان
                  _buildFeatureCard(
                    context: context,
                    isDark: isDark,
                    number: '٥',
                    title: 'lab_item_5'.tr(),
                    subtitle: 'lab_item_5_desc'.tr(),
                    icon: Iconsax.box_1,
                    color: const Color(0xFFEC4899),
                    badgeText: 'داشکاندن',
                    onTap: _showPackagesModal,
                  ),

                  // 6. ئەرشیفی داواکارییەکانم
                  _buildFeatureCard(
                    context: context,
                    isDark: isDark,
                    number: '٦',
                    title: 'lab_item_6'.tr(),
                    subtitle: 'lab_item_6_desc'.tr(),
                    icon: Iconsax.archive_book,
                    color: const Color(0xFF3B82F6),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyRequestsScreen()),
                      );
                    },
                  ),

                  // 7. شیکردنەوەی پشکنینەکانم بە AI
                  _buildFeatureCard(
                    context: context,
                    isDark: isDark,
                    number: '٧',
                    title: 'lab_item_7'.tr(),
                    subtitle: 'lab_item_7_desc'.tr(),
                    icon: Icons.auto_awesome_rounded,
                    color: const Color(0xFF7C3AED),
                    badgeText: 'AI زیرەک',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AiSymptomCheckerScreen(initialMode: 'lab')),
                      );
                    },
                  ),

                  // 8. پوختەی داواکاری و ناردن
                  _buildFeatureCard(
                    context: context,
                    isDark: isDark,
                    number: '٨',
                    title: 'lab_item_8'.tr(),
                    subtitle: 'lab_item_8_desc'.tr(),
                    icon: Iconsax.send_2,
                    color: const Color(0xFF10B981),
                    badgeText: cart.items.isNotEmpty ? '${cart.items.length} بەردەست' : null,
                    onTap: () {
                      if (cart.items.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Color(0xFF0F172A),
                            content: Text(
                              'تکایە سەرەتا پشکنین یان پاکێجێک هەڵبژێرە',
                              style: TextStyle(fontFamily: 'Rabar'),
                            ),
                          ),
                        );
                        _showSelectTestsModal();
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

      // ── Bottom Cart Floater if Cart has items ──
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
                      backgroundColor: const Color(0xFF2563EB),
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
                // Number & Icon Badge
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
