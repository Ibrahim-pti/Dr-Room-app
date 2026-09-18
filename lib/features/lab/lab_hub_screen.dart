import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import '../../core/utils/api_client.dart';
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
  bool _isLoading = false;
  List<Map<String, dynamic>> _labsList = [];

  // Dynamic lists fetched purely from API/Dashboard
  List<Map<String, dynamic>> _testsList = [];
  List<Map<String, dynamic>> _packagesList = [];
  List<Map<String, dynamic>> _staffList = [];

  @override
  void initState() {
    super.initState();
    _fetchDynamicData();
  }

  Future<void> _fetchDynamicData() async {
    setState(() => _isLoading = true);
    try {
      final resList = await Future.wait([
        ApiClient.get('/labs/tests'),
        ApiClient.get('/labs/packages'),
        ApiClient.get('/labs/staff'),
        ApiClient.get('/labs'),
      ]);

      final testsRes = resList[0];
      final packagesRes = resList[1];
      final staffRes = resList[2];
      final labsRes = resList[3];

      // 1. Labs from API
      if (labsRes.statusCode == 200) {
        final decoded = jsonDecode(labsRes.body);
        final list = (decoded['data'] as List? ?? []);
        if (list.isNotEmpty) {
          _labsList = list.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }

      // 2. Tests from API
      if (testsRes.statusCode == 200) {
        final decoded = jsonDecode(testsRes.body);
        final list = (decoded['data'] as List? ?? []);
        if (list.isNotEmpty) {
          _testsList = list.map((e) {
            final t = Map<String, dynamic>.from(e);
            return {
              'id': t['id'].toString(),
              'name': t['name'] ?? '',
              'name_ku': t['name_ku'] ?? t['name'] ?? '',
              'name_en': t['name_en'] ?? t['name'] ?? '',
              'name_ar': t['name_ar'] ?? t['name'] ?? '',
              'price': (t['price'] as num?)?.toDouble() ?? 15000.0,
              'original_price': (t['original_price'] as num?)?.toDouble(),
              'discount': t['discount'],
              'category': t['category'] ?? t['type'] ?? 'گشتی',
              'lab': t['lab'] ?? t['lab_name'] ?? 'تاقیگەی پزیشکی',
              'lab_id': t['lab_id'] ?? t['lab_user_id'],
              'lab_image': t['lab_image'],
              'city': t['city'] ?? '',
              'desc': t['desc'] ?? '',
              'home_sample_collection': t['home_sample_collection'] ?? true,
            };
          }).toList();
        }
      }

      // 3. Packages from API
      final colors = [
        const Color(0xFF2563EB),
        const Color(0xFF0D9488),
        const Color(0xFF8B5CF6),
        const Color(0xFFD97706),
        const Color(0xFFEC4899),
      ];

      if (packagesRes.statusCode == 200) {
        final decoded = jsonDecode(packagesRes.body);
        final list = (decoded['data'] as List? ?? []);
        if (list.isNotEmpty) {
          _packagesList = list.asMap().entries.map((entry) {
            final idx = entry.key;
            final p = Map<String, dynamic>.from(entry.value);
            final testsStr = p['tests'] is List
                ? (p['tests'] as List).join('، ')
                : (p['desc'] ?? '');
            return {
              'id': p['id'].toString(),
              'title': p['name'] ?? '',
              'title_en': p['name_en'] ?? p['name'] ?? '',
              'tests': testsStr,
              'tests_count': p['tests_count'] ?? 5,
              'original_price': (p['original_price'] as num?)?.toDouble() ??
                  ((p['price'] as num?)?.toDouble() ?? 50000.0) * 1.3,
              'discount_price': (p['price'] as num?)?.toDouble() ?? 50000.0,
              'discount_percent': '${p['discount'] ?? 25}%',
              'color': colors[idx % colors.length],
              'popular': idx == 0,
              'lab_id': p['lab_id'] ?? p['lab_user_id'],
              'lab_name': p['lab_name'] ?? 'تاقیگەی پزیشکی',
            };
          }).toList();
        }
      }

      // If backend /labs/packages is empty, fetch each lab's packages from API /labs/{id}
      if (_packagesList.isEmpty && _labsList.isNotEmpty) {
        final labResponses = await Future.wait(
          _labsList.map((l) => ApiClient.get('/labs/${l['id']}')),
        );
        final List<Map<String, dynamic>> gatheredPackages = [];
        int pkgIndex = 0;
        for (int i = 0; i < labResponses.length; i++) {
          final res = labResponses[i];
          if (res.statusCode == 200) {
            final decoded = jsonDecode(res.body);
            final data = decoded['data'];
            if (data != null && data['packages'] is List) {
              final pkgs = data['packages'] as List;
              final labName = data['name'] ?? _labsList[i]['name'] ?? 'تاقیگە';
              final labId = data['id'] ?? _labsList[i]['id'];
              for (final p in pkgs) {
                final pMap = Map<String, dynamic>.from(p);
                gatheredPackages.add({
                  'id': '${labId}_pkg_${pMap['id']}',
                  'title': pMap['name'] ?? '',
                  'title_en': pMap['name_en'] ?? pMap['name'] ?? '',
                  'tests': pMap['desc'] ?? (pMap['tests'] is List ? (pMap['tests'] as List).join('، ') : ''),
                  'tests_count': (pMap['test_ids'] as List?)?.length ?? 5,
                  'original_price': (pMap['original_price'] as num?)?.toDouble() ??
                      ((pMap['price'] as num?)?.toDouble() ?? 50000.0) * 1.3,
                  'discount_price': (pMap['price'] as num?)?.toDouble() ?? 50000.0,
                  'discount_percent': '${pMap['discount'] ?? 25}%',
                  'color': colors[pkgIndex % colors.length],
                  'popular': pkgIndex == 0,
                  'lab_id': labId,
                  'lab_name': labName,
                });
                pkgIndex++;
              }
            }
          }
        }
        if (gatheredPackages.isNotEmpty) {
          _packagesList = gatheredPackages;
        }
      }

      // 4. Staff from API
      if (staffRes.statusCode == 200) {
        final decoded = jsonDecode(staffRes.body);
        final list = (decoded['data'] as List? ?? []);
        if (list.isNotEmpty) {
          _staffList = list.map((e) {
            final s = Map<String, dynamic>.from(e);
            return {
              'id': s['id'].toString(),
              'name': s['name'] ?? '',
              'title': s['title'] ?? s['specialty'] ?? 'پسپۆڕی شیکاری نەخۆشییەکان',
              'lab': s['lab_name'] ?? 'تیمی پشکنینی دکتۆر ڕووم',
              'lab_id': s['lab_id'] ?? s['lab_user_id'] ?? s['id'],
              'rating': (s['rating'] as num?)?.toDouble() ?? 4.9,
              'reviews': s['reviews_count'] ?? 50,
              'city': s['city'] ?? 'هەولێر',
              'experience': s['city'] != null && s['city'].toString().isNotEmpty
                  ? s['city'].toString()
                  : 'پسپۆڕی ڕێگەپێدراو',
              'visit_fee': (s['fee'] as num?)?.toDouble() ?? 10000.0,
              'image': s['image'],
            };
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching dynamic lab data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _selectStaff(Map<String, dynamic> staff) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    // Remove previous staff if any so there is only one assigned staff
    cart.items.removeWhere((item) =>
        item.extraData?['type'] == 'staff' || item.id.startsWith('staff_'));

    cart.setServiceType('lab', extraFee: (staff['visit_fee'] as num?)?.toDouble() ?? 5000.0);
    cart.addItem(CartItem(
      id: 'staff_${staff['id']}',
      name: 'وەرگرتنی نموونە لە ماڵەوە (${staff['name']})',
      price: (staff['visit_fee'] as num?)?.toDouble() ?? 5000.0,
      quantity: 1,
      extraData: {
        'type': 'staff',
        'staff_id': staff['id'],
        'staff_name': staff['name'],
        'staff_title': staff['title'],
        'lab_id': staff['lab_id'],
        'lab_name': staff['lab'],
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
                '${staff['name']} وەک پسپۆڕی نموونەوەرگرتن هەڵبژێردرا',
                style: const TextStyle(fontFamily: 'Rabar', fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addTestToCart(Map<String, dynamic> test) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    cart.setServiceType('lab');
    cart.addItem(CartItem(
      id: test['id'].toString(),
      name: test['name_ku'] ?? test['name'],
      price: (test['price'] as num).toDouble(),
      quantity: 1,
      extraData: {
        'lab': test['lab'],
        'lab_id': test['lab_id'],
        'category': test['category'],
        'type': 'test',
      },
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
      id: pkg['id'].toString(),
      name: pkg['title'] ?? '',
      price: (pkg['discount_price'] as num).toDouble(),
      quantity: 1,
      extraData: {
        'type': 'package',
        'tests': pkg['tests'],
        'lab_id': pkg['lab_id'],
        'lab_name': pkg['lab_name'],
      },
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
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                          )
                        : filtered.isEmpty
                            ? const Center(
                                child: Text(
                                  'هیچ پشکنینێک نەدۆزرایەوە',
                                  style: TextStyle(fontFamily: 'Rabar', fontSize: 14, color: Color(0xFF94A3B8)),
                                ),
                              )
                            : ListView.separated(
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
        String query = '';

        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredStaff = _staffList.where((s) {
              final q = query.toLowerCase();
              return (s['name'] ?? '').toString().toLowerCase().contains(q) ||
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
                        'lab_item_3'.tr(),
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
                    'lab_item_3_desc'.tr(),
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
                        hintText: 'گەڕان بەپێی ناو یان شار (هەولێر، سلێمانی...)...',
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
                            child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                          )
                        : filteredStaff.isEmpty
                            ? const Center(
                                child: Text(
                                  'هیچ کارمەند یان پسپۆڕێک نەدۆزرایەوە',
                                  style: TextStyle(fontFamily: 'Rabar', fontSize: 14, color: Color(0xFF94A3B8)),
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
                                                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                                    child: const Icon(Iconsax.profile_circle, color: Color(0xFF2563EB), size: 28),
                                                  ),
                                                )
                                              : Container(
                                                  width: 52,
                                                  height: 52,
                                                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                                  child: const Icon(Iconsax.profile_circle, color: Color(0xFF2563EB), size: 28),
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
                                                      staff['name'],
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
                                                  if (staff['city'] != null && staff['city'].toString().isNotEmpty)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        staff['city'].toString(),
                                                        style: const TextStyle(
                                                          fontFamily: 'Rabar',
                                                          fontSize: 10.5,
                                                          fontWeight: FontWeight.bold,
                                                          color: Color(0xFF2563EB),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                staff['title'] ?? 'پسپۆڕی نموونەوەرگرتن',
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
                                                    '${staff['rating']} (${staff['reviews']})',
                                                    style: const TextStyle(fontFamily: 'Rabar', fontSize: 11, fontWeight: FontWeight.bold),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'کرێ: ${Currency.format(staff['visit_fee'])}',
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
                                            backgroundColor: isSelected ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            elevation: 0,
                                          ),
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            _selectStaff(staff);
                                          },
                                          child: Text(
                                            isSelected ? 'دیاریکراوە ✓' : 'دیاریکردن',
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

  void _showTestPricesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        String query = '';

        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredTests = _testsList.where((t) {
              final q = query.toLowerCase();
              return (t['name'] ?? '').toString().toLowerCase().contains(q) ||
                  (t['name_ku'] ?? '').toString().toLowerCase().contains(q) ||
                  (t['lab'] ?? '').toString().toLowerCase().contains(q);
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
                        'lab_item_4'.tr(),
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
                    'lab_item_4_desc'.tr(),
                    style: const TextStyle(fontFamily: 'Rabar', fontSize: 12.5, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 14),

                  // Search box for tests
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
                        hintText: 'گەڕان بۆ پشکنین یان تاقیگە...',
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
                            child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                          )
                        : filteredTests.isEmpty
                            ? const Center(
                                child: Text(
                                  'هیچ پشکنینێک نەدۆزرایەوە',
                                  style: TextStyle(fontFamily: 'Rabar', fontSize: 14, color: Color(0xFF94A3B8)),
                                ),
                              )
                            : ListView.separated(
                                itemCount: filteredTests.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 10),
                                itemBuilder: (context, idx) {
                                  final t = filteredTests[idx];

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
                                                Currency.format(t['price']),
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
                                              icon: const Icon(Iconsax.add_circle, color: Color(0xFF2563EB), size: 22),
                                              onPressed: () {
                                                _addTestToCart(t);
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

  void _showPackagesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        String query = '';

        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredPackages = _packagesList.where((p) {
              final q = query.toLowerCase();
              return (p['title'] ?? '').toString().toLowerCase().contains(q) ||
                  (p['lab_name'] ?? '').toString().toLowerCase().contains(q) ||
                  (p['tests'] ?? '').toString().toLowerCase().contains(q);
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
                        'lab_item_5'.tr(),
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
                    'lab_item_5_desc'.tr(),
                    style: const TextStyle(fontFamily: 'Rabar', fontSize: 12.5, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 14),

                  // Search box for packages
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
                        hintText: 'گەڕان بۆ پاکێج یان تاقیگە...',
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
                            child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                          )
                        : filteredPackages.isEmpty
                            ? const Center(
                                child: Text(
                                  'هیچ پاکێجێک نەدۆزرایەوە',
                                  style: TextStyle(fontFamily: 'Rabar', fontSize: 14, color: Color(0xFF94A3B8)),
                                ),
                              )
                            : ListView.separated(
                                itemCount: filteredPackages.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 14),
                                itemBuilder: (context, idx) {
                                  final pkg = filteredPackages[idx];

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
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    pkg['title'],
                                                    style: TextStyle(
                                                      fontFamily: 'Rabar',
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                  if (pkg['lab_name'] != null)
                                                    Text(
                                                      'تاقیگە: ${pkg['lab_name']}',
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
                        children: [
                          const Icon(Iconsax.buildings, color: Color(0xFF2563EB), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            _labsList.isNotEmpty ? 'تاقیگەکان (${_labsList.length})' : 'تاقیگەکان',
                            style: const TextStyle(
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

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: LinearProgressIndicator(
                  minHeight: 2.5,
                  backgroundColor: Colors.transparent,
                  color: Color(0xFF2563EB),
                ),
              ),

            // ── Main 8 Feature Cards Grid / List ──
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchDynamicData,
                color: const Color(0xFF2563EB),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
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
                    badgeText: _labsList.isNotEmpty ? '${_labsList.length} تاقیگە' : null,
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
                    badgeText: _testsList.isNotEmpty ? '${_testsList.length} پشکنین' : null,
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
                    badgeText: selectedStaffItem != null
                        ? (selectedStaffItem.extraData?['staff_name'] ?? 'دیاریکراوە')
                        : (_staffList.isNotEmpty ? '${_staffList.length} پسپۆڕ' : null),
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
                    badgeText: 'بەراوردکاری',
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
                    badgeText: _packagesList.isNotEmpty ? '${_packagesList.length} پاکێج' : 'داشکاندن',
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
          ),
          ],
        ),
      ),

      // ── Bottom Cart Floater if Cart has items ──
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
