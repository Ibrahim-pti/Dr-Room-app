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

  String _getStaffName(Map<String, dynamic> staff) {
    final lang = context.locale.languageCode;
    String name = '';
    if (lang == 'ar' && staff['name_ar'] != null && staff['name_ar'].toString().trim().isNotEmpty) {
      name = staff['name_ar'].toString().trim();
    } else if (lang == 'en' && staff['name_en'] != null && staff['name_en'].toString().trim().isNotEmpty) {
      name = staff['name_en'].toString().trim();
    } else if ((lang == 'ckb' || lang == 'kmr') && staff['name_ku'] != null && staff['name_ku'].toString().trim().isNotEmpty) {
      name = staff['name_ku'].toString().trim();
    } else {
      name = (staff['name'] ?? staff['name_en'] ?? '').toString().trim();
    }

    if (name.toLowerCase() == 'aesha fatih') {
      if (lang == 'ar') return 'عائشة فاتح';
      if (lang == 'ckb' || lang == 'kmr') return 'عائشە فاتیح';
      return 'Aesha Fatih';
    }

    if (RegExp(r'^[a-zA-Z\s]+$').hasMatch(name)) {
      return name
          .split(' ')
          .where((w) => w.isNotEmpty)
          .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
          .join(' ');
    }
    return name;
  }

  String _formatStaffSpecialty(dynamic rawTitle) {
    final t = (rawTitle ?? '').toString().trim();
    final lower = t.toLowerCase();
    if (lower.contains('general care') || lower.contains('چاودێری گشتی') || lower.contains('رعاية عامة')) {
      return 'spec_general_care'.tr();
    }
    if (lower.contains('sampling') || lower.contains('phlebotom') || lower.contains('نموونە') || lower.contains('سحب')) {
      return 'spec_sampling_specialist'.tr();
    }
    if (lower.contains('wound') || lower.contains('برین')) {
      return 'wound_care'.tr();
    }
    if (lower.contains('elderly') || lower.contains('بەساڵاچوو')) {
      return 'elderly_care'.tr();
    }
    if (lower.contains('pediatric') || lower.contains('منداڵ')) {
      return 'pediatric_care'.tr();
    }
    if (lower.contains('icu') || lower.contains('چڕ')) {
      return 'icu_care'.tr();
    }
    if (t.isNotEmpty) {
      return t;
    }
    return 'lab_hub_default_staff_title'.tr();
  }

  String _formatStaffCity(dynamic rawCity) {
    final c = (rawCity ?? '').toString().trim().toLowerCase();
    if (c.contains('erbil') || c.contains('hewler') || c.contains('هەولێر') || c.contains('أربيل')) {
      return 'city_erbil'.tr();
    }
    if (c.contains('sula') || c.contains('slemani') || c.contains('سلێمانی') || c.contains('السليمانية')) {
      return 'city_sulaymaniyah'.tr();
    }
    if (c.contains('duhok') || c.contains('دهۆک') || c.contains('دهوك')) {
      return 'city_duhok'.tr();
    }
    if (c.contains('kirkuk') || c.contains('کەرکووک') || c.contains('كركوك')) {
      return 'city_kirkuk'.tr();
    }
    if (c.contains('halabja') || c.contains('هەڵەبجە') || c.contains('حلبجة')) {
      return 'city_halabja'.tr();
    }
    return (rawCity ?? '').toString().trim();
  }

  Widget _buildStaffAvatar(Map<String, dynamic> staff, String? imgUrl, bool isDark) {
    final hasImage = imgUrl != null && imgUrl.isNotEmpty;
    final staffName = _getStaffName(staff);
    final initial = staffName.isNotEmpty ? staffName[0] : 'S';

    return Stack(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF2563EB).withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14.5),
            child: hasImage
                ? Image.network(
                    imgUrl,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 52,
                        height: 52,
                        color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                        child: const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, _, _) => _buildAvatarPlaceholder(initial, isDark),
                  )
                : _buildAvatarPlaceholder(initial, isDark),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarPlaceholder(String initial, bool isDark) {
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontFamily: 'Rabar',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

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
        _labsList = list.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      // 2. Tests from API
      if (testsRes.statusCode == 200) {
        final decoded = jsonDecode(testsRes.body);
        final list = (decoded['data'] as List? ?? []);
        _testsList = list.map((e) {
          final t = Map<String, dynamic>.from(e);
          return {
            'id': t['id'].toString(),
            'name': t['name'] ?? '',
            'name_ku': t['name_ku'] ?? t['name'] ?? '',
            'name_en': t['name_en'] ?? t['name'] ?? '',
            'name_ar': t['name_ar'] ?? t['name'] ?? '',
            'price': (t['price'] as num?)?.toDouble() ?? 0.0,
            'original_price': (t['original_price'] as num?)?.toDouble(),
            'discount': t['discount'],
            'category': t['category'] ?? t['type'] ?? '',
            'lab': t['lab'] ?? t['lab_name'] ?? '',
            'lab_id': t['lab_id'] ?? t['lab_user_id'],
            'lab_image': t['lab_image'],
            'city': t['city'] ?? '',
            'desc': t['desc'] ?? '',
            'home_sample_collection': t['home_sample_collection'] ?? true,
          };
        }).toList();
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
        _packagesList = list.asMap().entries.map((entry) {
          final idx = entry.key;
          final p = Map<String, dynamic>.from(entry.value);
          final testsStr = p['tests'] is List
              ? (p['tests'] as List).join('، ')
              : (p['desc'] ?? '');
          final price = (p['price'] as num?)?.toDouble() ?? 0.0;
          final originalPrice = (p['original_price'] as num?)?.toDouble();
          final discount = (p['discount'] as num?)?.toInt() ?? 0;
          return {
            'id': p['id'].toString(),
            'title': p['name'] ?? '',
            'title_en': p['name_en'] ?? p['name'] ?? '',
            'title_ar': p['name_ar'] ?? p['name'] ?? '',
            'tests': testsStr,
            'tests_count': p['tests_count'] ?? (p['tests'] is List ? (p['tests'] as List).length : 0),
            'original_price': originalPrice,
            'discount_price': price,
            'discount': discount,
            'discount_percent': discount > 0 ? '$discount%' : null,
            'color': colors[idx % colors.length],
            'popular': idx == 0,
            'lab_id': p['lab_id'] ?? p['lab_user_id'],
            'lab_name': p['lab_name'] ?? '',
          };
        }).toList();
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
              final labName = data['name'] ?? _labsList[i]['name'] ?? '';
              final labId = data['id'] ?? _labsList[i]['id'];
              for (final p in pkgs) {
                final pMap = Map<String, dynamic>.from(p);
                final price = (pMap['price'] as num?)?.toDouble() ?? 0.0;
                final originalPrice = (pMap['original_price'] as num?)?.toDouble();
                final discount = (pMap['discount'] as num?)?.toInt() ?? 0;
                gatheredPackages.add({
                  'id': '${labId}_pkg_${pMap['id']}',
                  'title': pMap['name'] ?? '',
                  'title_en': pMap['name_en'] ?? pMap['name'] ?? '',
                  'title_ar': pMap['name_ar'] ?? pMap['name'] ?? '',
                  'tests':
                      pMap['desc'] ??
                      (pMap['tests'] is List
                          ? (pMap['tests'] as List).join('، ')
                          : ''),
                  'tests_count': (pMap['test_ids'] as List?)?.length ?? 0,
                  'original_price': originalPrice,
                  'discount_price': price,
                  'discount': discount,
                  'discount_percent': discount > 0 ? '$discount%' : null,
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
        _staffList = list.map((e) {
          final s = Map<String, dynamic>.from(e);
          return {
            'id': s['id'].toString(),
            'nurse_id': s['nurse_id']?.toString() ?? s['id'].toString(),
            'name': s['name'] ?? '',
            'name_en': s['name_en'] ?? s['name'] ?? '',
            'name_ar': s['name_ar'] ?? s['name'] ?? '',
            'title': s['title'] ?? s['specialty'] ?? '',
            'lab': s['lab_name'] ?? '',
            'lab_id': s['lab_id'] ?? s['lab_user_id'] ?? s['id'],
            'rating': (s['rating'] as num?)?.toDouble() ?? 5.0,
            'reviews': (s['reviews_count'] as num?)?.toInt() ?? 0,
            'city': s['city'] ?? '',
            'experience': s['city'] != null && s['city'].toString().isNotEmpty
                ? s['city'].toString()
                : '',
            'visit_fee': (s['fee'] as num?)?.toDouble() ?? 0.0,
            'image': s['image'],
          };
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetching dynamic lab data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }



  void _addTestToCart(Map<String, dynamic> test) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    cart.setServiceType('lab');
    final testName = _getLocalized(test, 'name');
    cart.addItem(
      CartItem(
        id: test['id'].toString(),
        name: testName,
        price: (test['price'] as num).toDouble(),
        quantity: 1,
        extraData: {
          'lab': test['lab'],
          'lab_id': test['lab_id'],
          'category': test['category'],
          'type': 'test',
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF10B981),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$testName ${'nursing_added_to_cart'.tr()}',
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
    final pkgTitle = _getLocalized(pkg, 'title');
    cart.addItem(
      CartItem(
        id: pkg['id'].toString(),
        name: pkgTitle,
        price: (pkg['discount_price'] as num).toDouble(),
        quantity: 1,
        extraData: {
          'type': 'package',
          'tests': pkg['tests'],
          'lab_id': pkg['lab_id'],
          'lab_name': pkg['lab_name'],
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF10B981),
              size: 20,
            ),
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



  void _removeTestFromCart(Map<String, dynamic> test) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    cart.removeItem(test['id'].toString());
    setState(() {});

    final testName = _getLocalized(test, 'name');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            const Icon(
              Icons.remove_circle_outline_rounded,
              color: Color(0xFFEF4444),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$testName ${'item_removed_msg'.tr()}',
                style: const TextStyle(fontFamily: 'Rabar', fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removePackageFromCart(Map<String, dynamic> pkg) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    cart.removeItem(pkg['id'].toString());
    setState(() {});

    final pkgTitle = _getLocalized(pkg, 'title');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            const Icon(
              Icons.remove_circle_outline_rounded,
              color: Color(0xFFEF4444),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$pkgTitle ${'item_removed_msg'.tr()}',
                style: const TextStyle(fontFamily: 'Rabar', fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCancelSelection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFFEF4444),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'cancel_selection_title'.tr(),
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'cancel_selection_confirm'.tr(),
          style: TextStyle(
            fontFamily: 'Rabar',
            fontSize: 13,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'keep_selection'.tr(),
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 13,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    final cart = Provider.of<CartProvider>(context, listen: false);
                    cart.clearCart();
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF0F172A),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        content: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF10B981),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'selection_cancelled_msg'.tr(),
                                style: const TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'yes_cancel'.tr(),
                    style: const TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSelectedItemsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Consumer<CartProvider>(
          builder: (context, cart, child) {
            if (cart.items.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Navigator.canPop(ctx)) {
                  Navigator.pop(ctx);
                }
              });
              return const SizedBox.shrink();
            }

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                        'selected_services_breakdown'.tr(),
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _confirmCancelSelection();
                        },
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: Text(
                          'cancel_all_selections'.tr(),
                          style: const TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: cart.items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, idx) {
                        final item = cart.items[idx];
                        final isStaff = item.extraData?['type'] == 'staff' || item.id.startsWith('staff_');
                        final isPkg = item.extraData?['type'] == 'package';

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isStaff
                                      ? const Color(0xFF8B5CF6).withValues(alpha: 0.12)
                                      : isPkg
                                          ? const Color(0xFFEC4899).withValues(alpha: 0.12)
                                          : const Color(0xFF2563EB).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isStaff
                                      ? Iconsax.people
                                      : isPkg
                                          ? Iconsax.box_1
                                          : Iconsax.document_text,
                                  size: 18,
                                  color: isStaff
                                      ? const Color(0xFF8B5CF6)
                                      : isPkg
                                          ? const Color(0xFFEC4899)
                                          : const Color(0xFF2563EB),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: TextStyle(
                                        fontFamily: 'Rabar',
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      Currency.format(item.price),
                                      style: const TextStyle(
                                        fontFamily: 'Rabar',
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'cancel_selection'.tr(),
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFFEF4444),
                                  size: 20,
                                ),
                                onPressed: () {
                                  if (isStaff) {
                                    cart.items.removeWhere((i) => i.id == item.id);
                                    cart.setServiceType('lab', extraFee: 0.0);
                                  } else {
                                    cart.removeItem(item.id);
                                  }
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${'total'.tr()}:',
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          Currency.format(cart.total),
                          style: const TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CheckoutDetailsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Iconsax.arrow_right_3, size: 16, color: Colors.white),
                      label: Text(
                        'lab_hub_complete_order'.tr(),
                        style: const TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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

  // ignore: unused_element
  void _selectStaff(dynamic staff) {}
  // ignore: unused_element
  void _removeStaff(dynamic staff) {}

  // ignore: unused_element
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
              final q = query.trim().toLowerCase();
              if (q.isEmpty) return true;
              final name = _getStaffName(s).toLowerCase();
              final rawName = (s['name'] ?? '').toString().toLowerCase();
              final city = _formatStaffCity(s['city']).toLowerCase();
              final rawCity = (s['city'] ?? '').toString().toLowerCase();
              final spec = _formatStaffSpecialty(s['title']).toLowerCase();
              final rawSpec = (s['title'] ?? '').toString().toLowerCase();
              return name.contains(q) ||
                  rawName.contains(q) ||
                  city.contains(q) ||
                  rawCity.contains(q) ||
                  spec.contains(q) ||
                  rawSpec.contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
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
                        color: isDark
                            ? Colors.white24
                            : const Color(0xFFE2E8F0),
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
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
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
                    style: const TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Search box for staff
                  Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      onChanged: (v) => setModalState(() => query = v),
                      style: const TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 13.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'lab_hub_search_staff'.tr(),
                        hintStyle: const TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(
                          Iconsax.search_normal_1,
                          size: 18,
                          color: Color(0xFF94A3B8),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF2563EB),
                            ),
                          )
                        : filteredStaff.isEmpty
                        ? Center(
                            child: Text(
                              'lab_hub_no_staff'.tr(),
                              style: const TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 14,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filteredStaff.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, idx) {
                              final staff = filteredStaff[idx];
                              final cart = Provider.of<CartProvider>(
                                context,
                                listen: false,
                              );
                              final isSelected = cart.items.any(
                                (item) =>
                                    (item.extraData?['type'] == 'staff' ||
                                        item.id.startsWith('staff_')) &&
                                    item.extraData?['staff_id'] == staff['id'],
                              );
                              final imgUrl = staff['image'] != null &&
                                      staff['image'].toString().isNotEmpty
                                  ? ApiClient.getImageUrl(
                                      staff['image'].toString(),
                                    )
                                  : null;
                              final localizedStaffName = _getStaffName(staff);
                              final localizedStaffTitle = _formatStaffSpecialty(staff['title']);
                              final localizedStaffCity = _formatStaffCity(staff['city']);
                              final rating = (staff['rating'] as num?)?.toDouble() ?? 0.0;
                              final reviews = (staff['reviews'] as num?)?.toInt() ?? 0;
                              final isNew = rating <= 0 || reviews <= 0;
                              final visitFee = (staff['visit_fee'] as num?)?.toDouble() ?? 0.0;
                              final isFree = visitFee <= 0;

                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? (isSelected
                                          ? const Color(0xFF132822)
                                          : const Color(0xFF0F172A))
                                      : (isSelected
                                          ? const Color(0xFFF0FDF4)
                                          : Colors.white),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF10B981)
                                        : (isDark
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFE2E8F0)),
                                    width: isSelected ? 1.8 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected
                                          ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                          : Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        _buildStaffAvatar(staff, imgUrl, isDark),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      localizedStaffName,
                                                      style: TextStyle(
                                                        fontFamily: 'Rabar',
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.bold,
                                                        color: isDark
                                                            ? Colors.white
                                                            : const Color(0xFF0F172A),
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 5),
                                                  const Icon(
                                                    Icons.verified_rounded,
                                                    color: Color(0xFF2563EB),
                                                    size: 16,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                localizedStaffTitle,
                                                style: const TextStyle(
                                                  fontFamily: 'Rabar',
                                                  fontSize: 12,
                                                  color: Color(0xFF64748B),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (localizedStaffCity.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Iconsax.location,
                                                  size: 12,
                                                  color: Color(0xFF2563EB),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  localizedStaffCity,
                                                  style: const TextStyle(
                                                    fontFamily: 'Rabar',
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF2563EB),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      height: 1,
                                      color: isDark
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFFF1F5F9),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3.5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isNew
                                                    ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                                    : const Color(0xFFF59E0B).withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    isNew ? Icons.auto_awesome : Icons.star_rounded,
                                                    size: 13,
                                                    color: isNew
                                                        ? const Color(0xFF10B981)
                                                        : const Color(0xFFF59E0B),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    isNew ? 'staff_new'.tr() : '$rating ($reviews)',
                                                    style: TextStyle(
                                                      fontFamily: 'Rabar',
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: isNew
                                                          ? const Color(0xFF10B981)
                                                          : const Color(0xFFD97706),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3.5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Iconsax.wallet_3,
                                                    size: 13,
                                                    color: Color(0xFF2563EB),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    isFree
                                                        ? 'free_fee'.tr()
                                                        : '${'lab_hub_fee'.tr()} ${Currency.format(visitFee)}',
                                                    style: const TextStyle(
                                                      fontFamily: 'Rabar',
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF2563EB),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        isSelected
                                            ? OutlinedButton.icon(
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: const Color(0xFFEF4444),
                                                  side: const BorderSide(
                                                    color: Color(0xFFFCA5A5),
                                                    width: 1.2,
                                                  ),
                                                  backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.08),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 7,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  _removeStaff(staff);
                                                  setModalState(() {});
                                                },
                                                icon: const Icon(
                                                  Icons.close_rounded,
                                                  size: 15,
                                                  color: Color(0xFFEF4444),
                                                ),
                                                label: Text(
                                                  'cancel_selection'.tr(),
                                                  style: const TextStyle(
                                                    fontFamily: 'Rabar',
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFFEF4444),
                                                  ),
                                                ),
                                              )
                                            : ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF2563EB),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 7,
                                                  ),
                                                  elevation: 0,
                                                ),
                                                onPressed: () {
                                                  _selectStaff(staff);
                                                  setModalState(() {});
                                                },
                                                icon: const Icon(
                                                  Icons.add_rounded,
                                                  size: 16,
                                                  color: Colors.white,
                                                ),
                                                label: Text(
                                                  'lab_hub_select'.tr(),
                                                  style: const TextStyle(
                                                    fontFamily: 'Rabar',
                                                    fontSize: 12,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
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
                        color: isDark
                            ? Colors.white24
                            : const Color(0xFFE2E8F0),
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
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
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
                    style: const TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Search box for tests
                  Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      onChanged: (v) => setModalState(() => query = v),
                      style: const TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 13.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'lab_hub_search_tests'.tr(),
                        hintStyle: const TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(
                          Iconsax.search_normal_1,
                          size: 18,
                          color: Color(0xFF94A3B8),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF2563EB),
                            ),
                          )
                        : filteredTests.isEmpty
                        ? Center(
                            child: Text(
                              'lab_hub_no_tests'.tr(),
                              style: const TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 14,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filteredTests.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, idx) {
                              final t = filteredTests[idx];
                              final localizedTestName = _getLocalized(t, 'name');
                              final cart = Provider.of<CartProvider>(
                                context,
                                listen: false,
                              );
                              final isTestInCart = cart.items.any(
                                (item) => item.id == t['id'].toString(),
                              );

                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isTestInCart
                                        ? const Color(0xFF10B981)
                                        : (isDark
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFE2E8F0)),
                                    width: isTestInCart ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            localizedTestName,
                                            style: TextStyle(
                                              fontFamily: 'Rabar',
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${'lab_hub_lab_label'.tr()} ${t['lab']}',
                                            style: const TextStyle(
                                              fontFamily: 'Rabar',
                                              fontSize: 11,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF10B981,
                                            ).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
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
                                        isTestInCart
                                            ? IconButton(
                                                constraints: const BoxConstraints(),
                                                padding: const EdgeInsets.all(4),
                                                tooltip: 'cancel_selection'.tr(),
                                                icon: const Icon(
                                                  Icons.remove_circle_rounded,
                                                  color: Color(0xFFEF4444),
                                                  size: 22,
                                                ),
                                                onPressed: () {
                                                  _removeTestFromCart(t);
                                                  setModalState(() {});
                                                },
                                              )
                                            : IconButton(
                                                constraints: const BoxConstraints(),
                                                padding: const EdgeInsets.all(4),
                                                tooltip: 'lab_hub_select'.tr(),
                                                icon: const Icon(
                                                  Iconsax.add_circle,
                                                  color: Color(0xFF2563EB),
                                                  size: 22,
                                                ),
                                                onPressed: () {
                                                  _addTestToCart(t);
                                                  setModalState(() {});
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
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
                        color: isDark
                            ? Colors.white24
                            : const Color(0xFFE2E8F0),
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
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
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
                    style: const TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Search box for packages
                  Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      onChanged: (v) => setModalState(() => query = v),
                      style: const TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 13.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'lab_hub_search_packages'.tr(),
                        hintStyle: const TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(
                          Iconsax.search_normal_1,
                          size: 18,
                          color: Color(0xFF94A3B8),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF2563EB),
                            ),
                          )
                        : filteredPackages.isEmpty
                        ? Center(
                            child: Text(
                              'lab_hub_no_packages'.tr(),
                              style: const TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 14,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filteredPackages.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, idx) {
                              final pkg = filteredPackages[idx];
                              final localizedTitle = _getLocalized(pkg, 'title');
                              final cart = Provider.of<CartProvider>(
                                context,
                                listen: false,
                              );
                              final isPkgInCart = cart.items.any(
                                (item) => item.id == pkg['id'].toString(),
                              );

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF0F172A)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isPkgInCart
                                        ? const Color(0xFF10B981)
                                        : (pkg['color'] as Color).withValues(
                                            alpha: 0.35,
                                          ),
                                    width: isPkgInCart ? 2 : 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: isDark ? 0.2 : 0.04,
                                      ),
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
                                            color: (pkg['color'] as Color)
                                                .withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Icon(
                                            Iconsax.box_1,
                                            color: pkg['color'],
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                localizedTitle,
                                                style: TextStyle(
                                                  fontFamily: 'Rabar',
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark
                                                      ? Colors.white
                                                      : const Color(0xFF0F172A),
                                                ),
                                              ),
                                              if (pkg['lab_name'] != null)
                                                Text(
                                                  '${'lab_hub_lab_label'.tr()} ${pkg['lab_name']}',
                                                  style: const TextStyle(
                                                    fontFamily: 'Rabar',
                                                    fontSize: 11,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (pkg['discount_percent'] != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFFEF4444,
                                              ).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(
                                                8,
                                              ),
                                            ),
                                            child: Text(
                                              '${'lab_hub_discount'.tr()} ${pkg['discount_percent']}',
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
                                      '${'lab_hub_tests_label'.tr()} ${pkg['tests']}',
                                      style: const TextStyle(
                                        fontFamily: 'Rabar',
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (pkg['original_price'] != null &&
                                                (pkg['original_price'] as num) >
                                                    (pkg['discount_price'] as num))
                                              Text(
                                                Currency.format(
                                                  pkg['original_price'],
                                                ),
                                                style: const TextStyle(
                                                  fontFamily: 'Rabar',
                                                  fontSize: 12,
                                                  decoration:
                                                      TextDecoration.lineThrough,
                                                  color: Color(0xFF94A3B8),
                                                ),
                                              ),
                                            Text(
                                              Currency.format(
                                                pkg['discount_price'],
                                              ),
                                              style: TextStyle(
                                                fontFamily: 'Rabar',
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: pkg['color'],
                                              ),
                                            ),
                                          ],
                                        ),
                                        isPkgInCart
                                            ? OutlinedButton.icon(
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor:
                                                      const Color(0xFFEF4444),
                                                  side: const BorderSide(
                                                    color: Color(0xFFFCA5A5),
                                                  ),
                                                  backgroundColor:
                                                      const Color(0xFFEF4444)
                                                          .withValues(
                                                              alpha: 0.08),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 10,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  _removePackageFromCart(pkg);
                                                  setModalState(() {});
                                                },
                                                icon: const Icon(
                                                  Icons.close_rounded,
                                                  size: 16,
                                                  color: Color(0xFFEF4444),
                                                ),
                                                label: Text(
                                                  'cancel_selection'.tr(),
                                                  style: const TextStyle(
                                                    fontFamily: 'Rabar',
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color: Color(0xFFEF4444),
                                                  ),
                                                ),
                                              )
                                            : ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: pkg['color'],
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(12),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 18,
                                                    vertical: 10,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  _addPackageToCart(pkg);
                                                  setModalState(() {});
                                                },
                                                child: Text(
                                                  'lab_hub_order_package'.tr(),
                                                  style: const TextStyle(
                                                    fontFamily: 'Rabar',
                                                    fontSize: 13,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
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
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                      ),
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
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'lab_hub_subtitle'.tr(),
                          style: const TextStyle(
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
                        MaterialPageRoute(
                          builder: (_) => const AllLabsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Iconsax.buildings,
                            color: Color(0xFF2563EB),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _labsList.isNotEmpty
                                ? '${'lab_hub_labs'.tr()} (${_labsList.length})'
                                : 'lab_hub_labs'.tr(),
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

            // ── Main Feature Cards List ──
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchDynamicData,
                color: const Color(0xFF2563EB),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
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
                      badgeText: _labsList.isNotEmpty
                          ? '${_labsList.length} ${'lab_hub_labs_count'.tr()}'
                          : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UploadPrescriptionScreen(),
                          ),
                        );
                      },
                    ),

                    // 2. نرخی پشکنینەکان لە تاقیگەکان
                    _buildFeatureCard(
                      context: context,
                      isDark: isDark,
                      number: '٢',
                      title: 'lab_item_4'.tr(),
                      subtitle: 'lab_item_4_desc'.tr(),
                      icon: Iconsax.tag,
                      color: const Color(0xFFF59E0B),
                      badgeText: 'lab_hub_compare_badge'.tr(),
                      onTap: _showTestPricesModal,
                    ),

                    // 3. پاکێجی پشکنینەکان لە تاقیگەکان
                    _buildFeatureCard(
                      context: context,
                      isDark: isDark,
                      number: '٣',
                      title: 'lab_item_5'.tr(),
                      subtitle: 'lab_item_5_desc'.tr(),
                      icon: Iconsax.box_1,
                      color: const Color(0xFFEC4899),
                      badgeText: _packagesList.isNotEmpty
                          ? '${_packagesList.length} ${'lab_hub_packages_count'.tr()}'
                          : null,
                      onTap: _showPackagesModal,
                    ),

                    // 4. ئەرشیفی داواکارییەکانم
                    _buildFeatureCard(
                      context: context,
                      isDark: isDark,
                      number: '٤',
                      title: 'lab_item_6'.tr(),
                      subtitle: 'lab_item_6_desc'.tr(),
                      icon: Iconsax.archive_book,
                      color: const Color(0xFF3B82F6),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const MyRequestsScreen(fixedCategory: 'lab'),
                          ),
                        );
                      },
                    ),

                    // 5. شیکردنەوەی پشکنینەکانم بە AI
                    _buildFeatureCard(
                      context: context,
                      isDark: isDark,
                      number: '۵',
                      title: 'lab_item_7'.tr(),
                      subtitle: 'lab_item_7_desc'.tr(),
                      icon: Icons.auto_awesome_rounded,
                      color: const Color(0xFF7C3AED),
                      badgeText: 'lab_hub_ai_badge'.tr(),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AiSymptomCheckerScreen(
                              initialMode: 'lab',
                            ),
                          ),
                        );
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
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
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: _showSelectedItemsModal,
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${cart.items.length} ${'lab_hub_selected_services'.tr()}',
                                    style: const TextStyle(
                                      fontFamily: 'Rabar',
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  const Icon(
                                    Icons.keyboard_arrow_up_rounded,
                                    size: 14,
                                    color: Color(0xFF64748B),
                                  ),
                                ],
                              ),
                              Text(
                                Currency.format(cart.total),
                                style: const TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: BorderSide(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                          ),
                          backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                        ),
                        onPressed: _confirmCancelSelection,
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 15,
                          color: Color(0xFFEF4444),
                        ),
                        label: Text(
                          'cancel_selection'.tr(),
                          style: const TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CheckoutDetailsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Iconsax.arrow_right_3,
                          size: 15,
                          color: Colors.white,
                        ),
                        label: Text(
                          'lab_hub_complete_order'.tr(),
                          style: const TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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
      margin: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: isDark ? 0.12 : 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                // Number & Icon Badge
                Stack(
                  clipBehavior: Clip.none,
                  alignment: AlignmentDirectional.topStart,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withValues(alpha: isDark ? 0.22 : 0.14),
                            color.withValues(alpha: isDark ? 0.10 : 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: color.withValues(alpha: isDark ? 0.35 : 0.2),
                          width: 1.2,
                        ),
                      ),
                      child: Icon(icon, color: color, size: 26),
                    ),
                    PositionedDirectional(
                      top: -4,
                      start: -4,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            width: 2.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.45),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          number,
                          style: const TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1,
                          ),
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
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          if (badgeText != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(
                                  alpha: isDark ? 0.2 : 0.1,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.25),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                badgeText,
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          height: 1.38,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF334155).withValues(alpha: 0.5)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
