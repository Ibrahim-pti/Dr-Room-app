import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import '../../core/providers/cart_provider.dart';
import '../../core/utils/currency.dart';
import '../../core/utils/api_client.dart';
import '../checkout/checkout_details_screen.dart';
import '../lab/upload_prescription_screen.dart';
import '../requests/my_requests_screen.dart';


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
    return 'nursing_verified_nurse'.tr();
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
    final initial = staffName.isNotEmpty ? staffName[0] : 'N';

    return Stack(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF0D9488).withValues(alpha: 0.2),
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
                        color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                        child: const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF0D9488),
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
          colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
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

  Future<void> _fetchDynamicData() async {
    setState(() => _isLoading = true);
    try {
      final resList = await Future.wait([
        ApiClient.get('/nursing/services'),
        ApiClient.get('/nurses'),
        ApiClient.get('/nursing/packages'),
      ]);

      final servicesRes = resList[0];
      final nursesRes = resList[1];
      final packagesRes = resList[2];

      // 1. Dynamic Nursing Services from API (/nursing/services)
      if (servicesRes.statusCode == 200) {
        final decoded = jsonDecode(servicesRes.body);
        final list = (decoded is Map && decoded['services'] is List)
            ? decoded['services'] as List
            : ((decoded is Map && decoded['data'] is List)
                ? decoded['data'] as List
                : (decoded is List ? decoded : []));

        if (list.isNotEmpty) {
          final List<Map<String, dynamic>> dynamicServices = [];
          for (final item in list) {
            final s = Map<String, dynamic>.from(item);
            final iconStr = (s['icon'] ?? '').toString().toLowerCase();
            IconData icon = Iconsax.health;
            if (iconStr.contains('activity') || iconStr.contains('cannula')) {
              icon = Iconsax.activity;
            } else if (iconStr.contains('drop') || iconStr.contains('serum') || iconStr.contains('fluid')) {
              icon = Iconsax.drop;
            } else if (iconStr.contains('shield') || iconStr.contains('dressing') || iconStr.contains('wound') || iconStr.contains('healing')) {
              icon = Iconsax.shield_tick;
            } else if (iconStr.contains('heart') || iconStr.contains('vitals') || iconStr.contains('checkup') || iconStr.contains('monitor')) {
              icon = Iconsax.heart;
            }

            final price = (s['price'] as num?)?.toDouble() ?? 15000.0;
            dynamicServices.add({
              'id': s['id']?.toString() ?? 'nurse_svc_${dynamicServices.length}',
              'name': s['name'] ?? '',
              'name_en': s['name_en'] ?? s['name'] ?? '',
              'name_ar': s['name_ar'] ?? s['name'] ?? '',
              'price': price,
              'duration': s['duration'] ?? '٢٠ خولەک',
              'duration_en': s['duration_en'] ?? '20 min',
              'duration_ar': s['duration_ar'] ?? '٢٠ دقيقة',
              'icon': icon,
              'description': s['description'] ?? '',
            });
          }
          if (dynamicServices.isNotEmpty) {
            _nursingPriceList = dynamicServices;
          }
        }
      }

      // Fallback check to /service-categories?scope=nursing if services list is empty
      if (_nursingPriceList.isEmpty) {
        final catRes = await ApiClient.get('/service-categories?scope=nursing');
        if (catRes.statusCode == 200) {
          final decoded = jsonDecode(catRes.body);
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
      }

      // 2. Dynamic Specialist Nurse Staff from API (/nurses or /labs/staff)
      List<dynamic> rawStaff = [];
      if (nursesRes.statusCode == 200) {
        final decoded = jsonDecode(nursesRes.body);
        if (decoded is Map && decoded['nurses'] is List && (decoded['nurses'] as List).isNotEmpty) {
          rawStaff = decoded['nurses'] as List;
        } else if (decoded is Map && decoded['data'] is List && (decoded['data'] as List).isNotEmpty) {
          rawStaff = decoded['data'] as List;
        }
      }

      // If /nurses is empty, fallback to /labs/staff
      if (rawStaff.isEmpty) {
        final staffRes = await ApiClient.get('/labs/staff');
        if (staffRes.statusCode == 200) {
          final decoded = jsonDecode(staffRes.body);
          if (decoded is Map && decoded['data'] is List && (decoded['data'] as List).isNotEmpty) {
            rawStaff = decoded['data'] as List;
          }
        }
      }

      if (rawStaff.isNotEmpty) {
        _staffList = rawStaff.map((e) {
          final s = Map<String, dynamic>.from(e);
          final fee = (s['fee'] as num?)?.toDouble() ?? 15000.0;
          return {
            'id': s['id'].toString(),
            'nurse_id': s['nurse_id']?.toString() ?? s['id'].toString(),
            'name': s['name'] ?? '',
            'name_en': s['name_en'] ?? s['name'] ?? '',
            'name_ar': s['name_ar'] ?? s['name'] ?? '',
            'title': s['title'] ?? s['specialty'] ?? 'nursing_verified_nurse'.tr(),
            'title_en': s['title_en'] ?? s['specialty_en'] ?? 'Specialist Nurse',
            'title_ar': s['title_ar'] ?? s['specialty_ar'] ?? 'ممرض معتمد',
            'specialty': s['specialty'] ?? s['title'] ?? '',
            'lab': s['lab_name'] ?? 'تیمی پەرستاری دکتۆر ڕووم',
            'lab_id': s['lab_id'] ?? s['lab_user_id'] ?? s['id'],
            'rating': (s['rating'] as num?)?.toDouble() ?? 5.0,
            'reviews': (s['total_reviews'] ?? s['reviews_count'] ?? s['reviews'] as num?)?.toInt() ?? 0,
            'city': s['city'] ?? '',
            'city_en': s['city_en'] ?? s['city'] ?? '',
            'city_ar': s['city_ar'] ?? s['city'] ?? '',
            'visit_fee': fee,
            'image': s['image'],
          };
        }).toList();
      }

      // 3. Dynamic Nursing Packages from API (/nursing/packages)
      final colors = [
        const Color(0xFF0D9488),
        const Color(0xFF2563EB),
        const Color(0xFF8B5CF6),
        const Color(0xFFEC4899),
        const Color(0xFFD97706),
      ];

      if (packagesRes.statusCode == 200) {
        final decoded = jsonDecode(packagesRes.body);
        final list = (decoded is Map && decoded['data'] is List)
            ? decoded['data'] as List
            : ((decoded is Map && decoded['packages'] is List)
                ? decoded['packages'] as List
                : (decoded is List ? decoded : []));

        if (list.isNotEmpty) {
          _carePackages = list.asMap().entries.map((entry) {
            final idx = entry.key;
            final p = Map<String, dynamic>.from(entry.value);
            final origPrice = (p['original_price'] as num?)?.toDouble();
            final discPrice = (p['discount_price'] ?? p['price'] as num?)?.toDouble() ?? 50000.0;
            final discount = p['discount_percent']?.toString() ??
                (p['discount'] != null ? '${p['discount']}%' : '25%');

            return {
              'id': p['id']?.toString() ?? 'nurse_pkg_$idx',
              'title': p['title'] ?? p['name'] ?? '',
              'title_en': p['title_en'] ?? p['name_en'] ?? p['title'] ?? '',
              'title_ar': p['title_ar'] ?? p['name_ar'] ?? p['title'] ?? '',
              'desc': p['desc'] ?? p['description'] ?? '',
              'desc_en': p['desc_en'] ?? p['description_en'] ?? '',
              'desc_ar': p['desc_ar'] ?? p['description_ar'] ?? '',
              'visits': p['visits'] ?? '${p['services_count'] ?? 5} سەردانی ماڵەوە',
              'visits_en': p['visits_en'] ?? '${p['services_count'] ?? 5} Home Visits',
              'visits_ar': p['visits_ar'] ?? '${p['services_count'] ?? 5} زيارات منزلية',
              'original_price': origPrice,
              'discount_price': discPrice,
              'discount_percent': discount,
              'color': colors[idx % colors.length],
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
    final staffName = _getStaffName(staff);
    final staffTitle = _formatStaffSpecialty(staff['title']);
    final staffCity = _formatStaffCity(staff['city']);

    cart.setServiceType('nursing', extraFee: fee);
    cart.addItem(CartItem(
      id: 'staff_${staff['id']}',
      name: '${'nursing_verified_nurse'.tr()} ($staffName)',
      price: fee,
      quantity: 1,
      extraData: {
        'type': 'staff',
        'staff_id': staff['id'],
        // Nurse model id — the backend resolves it to users.id so the order
        // lands in this nurse's dashboard.
        'nurse_id': staff['nurse_id'],
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

  void _removeStaff(Map<String, dynamic> staff) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    cart.items.removeWhere(
      (item) =>
          item.extraData?['type'] == 'staff' || item.id.startsWith('staff_'),
    );
    cart.setServiceType('nursing', extraFee: 0.0);
    setState(() {});

    final staffName = _getStaffName(staff);
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
                '$staffName: ${'staff_deselected_msg'.tr()}',
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

  // ── 2. Select Specialist Staff Modal (Live from API) ──
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
                                          ? (isSelected ? const Color(0xFF132822) : const Color(0xFF0F172A))
                                          : (isSelected ? const Color(0xFFF0FDF4) : Colors.white),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF10B981)
                                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
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
                                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 5),
                                                      const Icon(
                                                        Icons.verified_rounded,
                                                        color: Color(0xFF0D9488),
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
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Iconsax.location,
                                                      size: 12,
                                                      color: Color(0xFF0D9488),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      localizedStaffCity,
                                                      style: const TextStyle(
                                                        fontFamily: 'Rabar',
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        color: Color(0xFF0D9488),
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
                                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
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
                                                        color: isNew ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        isNew ? 'staff_new'.tr() : '$rating ($reviews)',
                                                        style: TextStyle(
                                                          fontFamily: 'Rabar',
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.bold,
                                                          color: isNew ? const Color(0xFF10B981) : const Color(0xFFD97706),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Iconsax.wallet_3,
                                                        size: 13,
                                                        color: Color(0xFF0D9488),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        isFree
                                                            ? 'free_fee'.tr()
                                                            : '${'nursing_visit_fee'.tr()} ${Currency.format(visitFee)}',
                                                        style: const TextStyle(
                                                          fontFamily: 'Rabar',
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.bold,
                                                          color: Color(0xFF0D9488),
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
                                                      side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
                                                      backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.08),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                                    ),
                                                    onPressed: () {
                                                      _removeStaff(staff);
                                                      setModalState(() {});
                                                    },
                                                    icon: const Icon(Icons.close_rounded, size: 15, color: Color(0xFFEF4444)),
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
                                                      backgroundColor: const Color(0xFF0D9488),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                                      elevation: 0,
                                                    ),
                                                    onPressed: () {
                                                      _selectStaff(staff);
                                                      setModalState(() {});
                                                    },
                                                    icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                                                    label: Text(
                                                      'nursing_select_service_btn'.tr(),
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
                                            if (pkg['original_price'] != null &&
                                                (pkg['original_price'] as num) > (pkg['discount_price'] as num))
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

            // ── Main 6 Feature Cards List ──
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchDynamicData,
                color: const Color(0xFF0D9488),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                  children: [
                    // 1. هەڵبژاردنی ڕەچەتە
                    _buildFeatureCard(
                      context: context,
                      isDark: isDark,
                      number: '١',
                      title: 'nursing_item_1'.tr(),
                      subtitle: 'nursing_item_1_desc'.tr(),
                      icon: Iconsax.document_upload,
                      color: const Color(0xFF0D9488),
                      badgeText: _staffList.isNotEmpty
                          ? '${_staffList.length} ${'nursing_staff_count'.tr()}'
                          : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UploadPrescriptionScreen(serviceType: 'nursing'),
                          ),
                        );
                      },
                    ),

                    // 2. نرخی خزمەتگوزارییەکان
                    _buildFeatureCard(
                      context: context,
                      isDark: isDark,
                      number: '٢',
                      title: 'nursing_item_4'.tr(),
                      subtitle: 'nursing_item_4_desc'.tr(),
                      icon: Iconsax.tag,
                      color: const Color(0xFFF59E0B),
                      badgeText: 'nursing_transparent_prices'.tr(),
                      onTap: _showPriceListModal,
                    ),

                    // 3. پاکێجی چاودێریکردنی نەخۆش
                    _buildFeatureCard(
                      context: context,
                      isDark: isDark,
                      number: '٣',
                      title: 'nursing_item_5'.tr(),
                      subtitle: 'nursing_item_5_desc'.tr(),
                      icon: Iconsax.shield_security,
                      color: const Color(0xFFEC4899),
                      badgeText: _carePackages.isNotEmpty
                          ? '${_carePackages.length} ${'nursing_packages_count'.tr()}'
                          : null,
                      onTap: _showCarePackagesModal,
                    ),

                    // 4. ئەرشیفی داواکارییەکانم
                    _buildFeatureCard(
                      context: context,
                      isDark: isDark,
                      number: '٤',
                      title: 'nursing_item_6'.tr(),
                      subtitle: 'nursing_item_6_desc'.tr(),
                      icon: Iconsax.archive_book,
                      color: const Color(0xFF3B82F6),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const MyRequestsScreen(fixedCategory: 'nursing'),
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
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
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
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
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
                          backgroundColor: const Color(0xFF0D9488),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CheckoutDetailsScreen()),
                          );
                        },
                        icon: const Icon(Iconsax.arrow_left_3, size: 15, color: Colors.white),
                        label: Text(
                          'nursing_checkout_action'.tr(),
                          style: const TextStyle(fontFamily: 'Rabar', fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
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
