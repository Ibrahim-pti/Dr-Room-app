import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/utils/api_client.dart';
import '../../core/utils/currency.dart';
import '../../core/utils/localization_extensions.dart';
import '../../core/providers/cart_provider.dart';
import '../checkout/checkout_details_screen.dart';

class UploadPrescriptionScreen extends StatefulWidget {
  final String serviceType; // 'lab' or 'nursing'

  const UploadPrescriptionScreen({
    super.key,
    this.serviceType = 'lab',
  });

  bool get isNursing => serviceType == 'nursing';

  @override
  State<UploadPrescriptionScreen> createState() =>
      _UploadPrescriptionScreenState();
}

class _UploadPrescriptionScreenState extends State<UploadPrescriptionScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  bool _isUploading = false;
  List<Map<String, dynamic>> _providers = [];
  Map<String, dynamic>? _selectedProvider;

  // Lab Tests State
  bool _isLoadingTests = false;
  List<Map<String, dynamic>> _tests = [];
  final Set<String> _selectedTestIds = {};
  String _testsSearchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static final List<Map<String, dynamic>> _defaultLabTests = [
    {
      'id': 'cbc',
      'name': 'پشکنینی گشتی خوێن (CBC)',
      'name_en': 'Complete Blood Count (CBC)',
      'name_ar': 'تعداد الدم الكامل (CBC)',
      'desc': 'شیکاری تەواوی خڕۆکەکانی خوێن و هیمۆگلۆبین',
      'price': 15000.0,
    },
    {
      'id': 'lipid',
      'name': 'چەوری خوێن (Lipid Profile)',
      'name_en': 'Lipid Profile',
      'name_ar': 'فحص الدهون الشامل',
      'desc': 'کۆلیسترۆل و چەوری سیانی',
      'price': 25000.0,
    },
    {
      'id': 'fbs',
      'name': 'شەکری خوێن (Fasting Blood Sugar)',
      'name_en': 'Fasting Blood Sugar (FBS)',
      'name_ar': 'سكر الدم الصائم',
      'desc': 'پێوانەکردنی ڕێژەی شەکری خوێن بە بێ نان خواردن',
      'price': 10000.0,
    },
    {
      'id': 'kft',
      'name': 'پشکنینی گورچیلە (KFT)',
      'name_en': 'Kidney Function Test (KFT)',
      'name_ar': 'وظائف الكلى',
      'desc': 'یوریا و کریاتینین',
      'price': 25000.0,
    },
    {
      'id': 'lft',
      'name': 'پشکنینی جگەر (LFT)',
      'name_en': 'Liver Function Test (LFT)',
      'name_ar': 'وظائف الكبد',
      'desc': 'ئەنزیمەکانی جگەر و بیلرۆبین',
      'price': 30000.0,
    },
    {
      'id': 'vit_d',
      'name': 'ڤیتامین دی (Vitamin D3)',
      'name_en': 'Vitamin D3',
      'name_ar': 'فيتامين د3',
      'desc': 'پێوانەکردنی ئاستی ڤیتامین D لە لەشدا',
      'price': 35000.0,
    },
    {
      'id': 'tsh',
      'name': 'هۆرمۆنی غودە (TSH / Thyroid)',
      'name_en': 'Thyroid Profile (TSH)',
      'name_ar': 'هرمون الغدة الدرقية',
      'desc': 'چالاکی و ڕژانی غودەی دەرەقی',
      'price': 25000.0,
    },
    {
      'id': 'b12',
      'name': 'ڤیتامین بی ١٢ (Vitamin B12)',
      'name_en': 'Vitamin B12',
      'name_ar': 'فيتامين ب12',
      'desc': 'پێوانەکردنی ڕێژەی ڤیتامین B12',
      'price': 30000.0,
    },
    {
      'id': 'gfr',
      'name': 'پشکنینی گشتی میز (GUE)',
      'name_en': 'General Urine Exam (GUE)',
      'name_ar': 'فحص الإدرار العام',
      'desc': 'شیکاری مایکرۆسکۆپی و کیمیایی میز',
      'price': 10000.0,
    },
    {
      'id': 'crp',
      'name': 'پشکنینی هەوکردن (CRP)',
      'name_en': 'C-Reactive Protein (CRP)',
      'name_ar': 'فحص بروتين سي التفاعلي',
      'desc': 'نیشاندەری ڕادەی هەوکردن لە لەشدا',
      'price': 15000.0,
    },
  ];

  Color get _themeColor =>
      widget.isNursing ? const Color(0xFF0D9488) : const Color(0xFF2563EB);

  double get _totalTestsPrice {
    double total = 0.0;
    for (final t in _tests) {
      if (_selectedTestIds.contains(t['id'].toString())) {
        total += (t['price'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    _fetchProviders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onProviderSelected(Map<String, dynamic> provider) {
    if (_selectedProvider?['id'] == provider['id']) return;
    setState(() {
      _selectedProvider = provider;
    });
    if (!widget.isNursing) {
      _fetchTestsForLab(provider['id']);
    }
  }

  void _toggleTest(String id) {
    setState(() {
      if (_selectedTestIds.contains(id)) {
        _selectedTestIds.remove(id);
      } else {
        _selectedTestIds.add(id);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedTestIds.length == _tests.length) {
        _selectedTestIds.clear();
      } else {
        _selectedTestIds.addAll(_tests.map((t) => t['id'].toString()));
      }
    });
  }

  Future<void> _fetchTestsForLab(dynamic labId) async {
    if (widget.isNursing || labId == null) return;
    setState(() {
      _isLoadingTests = true;
      _selectedTestIds.clear();
      _tests = [];
    });

    try {
      // 1. Try to fetch from /labs/$labId
      final res = await ApiClient.get('/labs/$labId');
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final data = decoded is Map ? (decoded['data'] ?? decoded) : null;
        if (data != null && data['tests'] is List && (data['tests'] as List).isNotEmpty) {
          final list = (data['tests'] as List).map((t) => Map<String, dynamic>.from(t)).toList();
          if (mounted) {
            setState(() {
              _tests = list;
              _isLoadingTests = false;
            });
            return;
          }
        }
      }

      // 2. Fallback to /labs/tests filtered by lab_id or all tests
      final allTestsRes = await ApiClient.get('/labs/tests');
      if (allTestsRes.statusCode == 200) {
        final decoded = jsonDecode(allTestsRes.body);
        final list = decoded is Map && decoded['data'] is List
            ? (decoded['data'] as List)
            : (decoded is List ? decoded : []);
        final parsed = list.map((t) => Map<String, dynamic>.from(t)).toList();
        final labSpecific = parsed.where((t) => t['lab_id']?.toString() == labId.toString()).toList();
        final finalTests = labSpecific.isNotEmpty ? labSpecific : parsed;
        if (finalTests.isNotEmpty && mounted) {
          setState(() {
            _tests = finalTests;
            _isLoadingTests = false;
          });
          return;
        }
      }

      // 3. Fallback catalogue of standard tests if backend has none configured
      if (mounted) {
        setState(() {
          _tests = _defaultLabTests;
          _isLoadingTests = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching tests for lab $labId: $e');
      if (mounted) {
        setState(() {
          _tests = _defaultLabTests;
          _isLoadingTests = false;
        });
      }
    }
  }

  Future<void> _fetchProviders() async {
    setState(() => _isLoading = true);
    try {
      if (widget.isNursing) {
        // Fetch specialist nurses from /nurses (fallback to /labs/staff)
        List<dynamic> rawStaff = [];
        final nursesRes = await ApiClient.get('/nurses');
        if (nursesRes.statusCode == 200) {
          final decoded = jsonDecode(nursesRes.body);
          if (decoded is Map && decoded['nurses'] is List && (decoded['nurses'] as List).isNotEmpty) {
            rawStaff = decoded['nurses'] as List;
          } else if (decoded is Map && decoded['data'] is List && (decoded['data'] as List).isNotEmpty) {
            rawStaff = decoded['data'] as List;
          }
        }

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
          _providers = rawStaff.map((e) {
            final s = Map<String, dynamic>.from(e);
            final fee = (s['fee'] as num?)?.toDouble() ??
                (s['visit_fee'] as num?)?.toDouble() ??
                15000.0;
            return {
              'id': s['id'].toString(),
              'nurse_id': s['nurse_id']?.toString() ?? s['id'].toString(),
              'name': s['name'] ?? '',
              'name_en': s['name_en'] ?? s['name'] ?? '',
              'name_ar': s['name_ar'] ?? s['name'] ?? '',
              'title': s['title'] ?? s['specialty'] ?? 'nursing_verified_nurse'.tr(),
              'title_en': s['title_en'] ?? s['specialty_en'] ?? 'Specialist Nurse',
              'title_ar': s['title_ar'] ?? s['specialty_ar'] ?? 'ممرض معتمد',
              'specialty': s['specialty'] ?? s['title'] ?? 'nursing_verified_nurse'.tr(),
              'specialty_en': s['specialty_en'] ?? s['title_en'] ?? 'Specialist Nurse',
              'specialty_ar': s['specialty_ar'] ?? s['title_ar'] ?? 'ممرض معتمد',
              'city': s['city'] ?? '',
              'city_en': s['city_en'] ?? s['city'] ?? '',
              'city_ar': s['city_ar'] ?? s['city'] ?? '',
              'rating': (s['rating'] as num?)?.toDouble() ?? 5.0,
              'fee': fee,
              'image': s['image'] ?? s['profile_image'] ?? s['image_path'],
            };
          }).toList();

          if (_providers.isNotEmpty) {
            _selectedProvider = _providers.first;
          }
        }
      } else {
        // Fetch laboratories
        final res = await ApiClient.get('/labs');
        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);
          final list = decoded is Map && decoded.containsKey('data')
              ? (decoded['data'] as List? ?? [])
              : (decoded is List ? decoded : []);
          if (list.isNotEmpty) {
            _providers = list.map((e) => Map<String, dynamic>.from(e)).toList();
            if (_providers.isNotEmpty) {
              _selectedProvider = _providers.first;
              _fetchTestsForLab(_selectedProvider!['id']);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading providers: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatCity(dynamic cityRaw) {
    final city = cityRaw?.toString().trim() ?? '';
    final lower = city.toLowerCase();
    if (lower == 'erbil' || lower == 'hawler' || lower == 'hewler' || lower == 'هەولێر' || lower == 'أربيل') {
      return 'city_erbil'.tr();
    }
    if (lower == 'sulaymaniyah' || lower == 'slemany' || lower == 'slemani' || lower == 'سلێمانی' || lower == 'السليمانية') {
      return 'city_sulaymaniyah'.tr();
    }
    if (lower == 'duhok' || lower == 'dohuk' || lower == 'دهۆک' || lower == 'دهوك') {
      return 'city_duhok'.tr();
    }
    if (lower == 'kirkuk' || lower == 'کەرکووک' || lower == 'كركوك') {
      return 'city_kirkuk'.tr();
    }
    if (lower == 'halabja' || lower == 'هەڵەبجە' || lower == 'حلبجة') {
      return 'city_halabja'.tr();
    }
    return city.isNotEmpty ? city : 'city_erbil'.tr();
  }

  Widget _buildProviderAvatar(Map<String, dynamic> provider, bool isDark) {
    final imageRaw = provider['image'] ?? provider['profile_image'] ?? provider['image_path'];
    final String imagePath =
        (imageRaw != null && imageRaw.toString().trim().isNotEmpty)
            ? imageRaw.toString().trim()
            : '';

    Widget imageWidget;
    if (imagePath.startsWith('assets/')) {
      imageWidget = Image.asset(
        imagePath,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildFallbackIcon(isDark),
      );
    } else if (imagePath.isNotEmpty) {
      final fullUrl = ApiClient.getImageUrl(imagePath);
      imageWidget = Image.network(
        fullUrl,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildFallbackIcon(isDark),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 52,
            height: 52,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      );
    } else {
      imageWidget = _buildFallbackIcon(isDark);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 52,
        height: 52,
        child: imageWidget,
      ),
    );
  }

  Widget _buildFallbackIcon(bool isDark) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: _themeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        widget.isNursing ? Iconsax.user : Iconsax.hospital,
        color: _themeColor,
        size: 26,
      ),
    );
  }

  Widget _buildLabTestsSection(bool isDark, Color cardBg, Color borderColor) {
    final filteredTests = _tests.where((t) {
      if (_testsSearchQuery.isEmpty) return true;
      final q = _testsSearchQuery.toLowerCase().trim();
      final name = (t['name'] ?? '').toString().toLowerCase();
      final nameEn = (t['name_en'] ?? '').toString().toLowerCase();
      final nameAr = (t['name_ar'] ?? '').toString().toLowerCase();
      final desc = (t['desc'] ?? '').toString().toLowerCase();
      return name.contains(q) ||
          nameEn.contains(q) ||
          nameAr.contains(q) ||
          desc.contains(q);
    }).toList();

    final isAllSelected =
        _tests.isNotEmpty && _selectedTestIds.length == _tests.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Iconsax.health,
                color: Color(0xFF2563EB),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'lab_tests_section_title'.tr(),
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'lab_tests_section_desc'.tr(),
                    style: const TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            if (_tests.isNotEmpty) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: _toggleSelectAll,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isAllSelected
                        ? const Color(0xFF2563EB).withValues(alpha: 0.1)
                        : (isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isAllSelected
                          ? const Color(0xFF2563EB).withValues(alpha: 0.4)
                          : borderColor,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAllSelected
                            ? Iconsax.close_circle
                            : Iconsax.tick_circle,
                        size: 14,
                        color: isAllSelected
                            ? const Color(0xFF2563EB)
                            : (isDark
                                ? Colors.white70
                                : const Color(0xFF475569)),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isAllSelected ? 'deselect_all'.tr() : 'select_all'.tr(),
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isAllSelected
                              ? const Color(0xFF2563EB)
                              : (isDark
                                  ? Colors.white70
                                  : const Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 14),

        // Search Box (if tests available)
        if (_tests.isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _testsSearchQuery = val;
                });
              },
              style: TextStyle(
                fontFamily: 'Rabar',
                fontSize: 13.5,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: 'search_tests_hint'.tr(),
                hintStyle: const TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 12.5,
                  color: Color(0xFF94A3B8),
                ),
                prefixIcon: const Icon(
                  Iconsax.search_normal_1,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _testsSearchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Loading or List
        if (_isLoadingTests)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(
              color: Color(0xFF2563EB),
              strokeWidth: 2.5,
            ),
          )
        else if (filteredTests.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                Icon(
                  Iconsax.health,
                  size: 36,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
                const SizedBox(height: 8),
                Text(
                  'no_tests_for_lab'.tr(),
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 13,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else ...[
          // Test Items
          ...filteredTests.map((test) {
            final testId = test['id'].toString();
            final isSelected = _selectedTestIds.contains(testId);
            final price = (test['price'] as num?)?.toDouble() ?? 0.0;
            final name = context.localizedField(
              test,
              'name',
              fallback: test['name'] ?? '',
            );
            final desc = context.localizedField(
              test,
              'desc',
              fallback: test['desc'] ?? '',
            );

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark
                        ? const Color(0xFF2563EB).withValues(alpha: 0.12)
                        : const Color(0xFFEFF6FF))
                    : cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2563EB).withValues(alpha: 0.7)
                      : borderColor,
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? const Color(0xFF2563EB).withValues(alpha: 0.08)
                        : Colors.black.withValues(
                            alpha: isDark ? 0.2 : 0.02,
                          ),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _toggleTest(testId),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(13),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Checkbox
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : borderColor,
                              width: 1.5,
                            ),
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),

                        // Title & Description
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              if (desc.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  desc,
                                  style: const TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Price Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            Currency.format(price),
                            style: const TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D9488),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],

        // Explanatory Note
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor.withValues(alpha: 0.7)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Iconsax.info_circle,
                size: 16,
                color: Color(0xFF3B82F6),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'optional_tests_note'.tr(),
                  style: const TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'select_image_source'.tr(),
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _themeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Iconsax.gallery,
                    color: _themeColor,
                    size: 22,
                  ),
                ),
                title: Text(
                  'choose_gallery'.tr(),
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 6),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Iconsax.camera,
                    color: Color(0xFF10B981),
                    size: 22,
                  ),
                ),
                title: Text(
                  'camera'.tr(),
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    }
  }

  Future<void> _proceedToCheckout() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text(
            'please_upload_image_first'.tr(),
            style: const TextStyle(fontFamily: 'Rabar', fontSize: 13.5),
          ),
        ),
      );
      return;
    }

    if (_selectedProvider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text(
            widget.isNursing
                ? 'please_select_nurse_first'.tr()
                : 'please_select_lab_first'.tr(),
            style: const TextStyle(fontFamily: 'Rabar', fontSize: 13.5),
          ),
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    String? uploadedUrl;
    String? uploadedPath;

    try {
      final uploadRes = await ApiClient.uploadMultipart(
        '/upload/prescription',
        fileField: 'image',
        filePath: _imageFile!.path,
      );

      if (uploadRes.statusCode == 200) {
        final decoded = jsonDecode(uploadRes.body);
        if (decoded['success'] == true) {
          uploadedUrl = decoded['url'];
          uploadedPath = decoded['path'];
        }
      }
    } catch (e) {
      debugPrint('Error uploading prescription image to server: $e');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }

    if (!mounted) return;

    final cart = context.read<CartProvider>();
    cart.clearCart();

    final finalUrl = uploadedUrl ?? _imageFile?.path;
    final finalPath = uploadedPath ?? _imageFile?.path;

    if (widget.isNursing) {
      final fee = (_selectedProvider!['fee'] as num?)?.toDouble() ?? 15000.0;
      final staffName = _selectedProvider!['name'] ?? '';
      cart.setServiceType('nursing', extraFee: fee);
      cart.addItem(
        CartItem(
          id: 'prescription_${DateTime.now().millisecondsSinceEpoch}',
          name: '${'prescription_order_name'.tr()} ($staffName)',
          price: fee,
          quantity: 1,
          extraData: {
            'prescription_path': finalPath,
            'prescription_url': finalUrl,
            'prescription_image': finalUrl,
            'is_prescription': true,
            'type': 'nursing_prescription',
            'nurse_id': _selectedProvider!['nurse_id'] ?? _selectedProvider!['id'],
            'staff_id': _selectedProvider!['id'],
            'staff_name': staffName,
            'staff_title': _selectedProvider!['specialty'] ?? _selectedProvider!['title'],
          },
        ),
      );
    } else {
      cart.setServiceType('lab', extraFee: 0.0);
      final selectedTests = _tests
          .where((t) => _selectedTestIds.contains(t['id'].toString()))
          .toList();

      if (selectedTests.isNotEmpty) {
        for (final t in selectedTests) {
          final tPrice = (t['price'] as num?)?.toDouble() ?? 0.0;
          final tName = context.localizedField(
            t,
            'name',
            fallback: t['name'] ?? 'lab_test'.tr(),
          );
          cart.addItem(
            CartItem(
              id: 'test_${t['id']}_${DateTime.now().millisecondsSinceEpoch}',
              name: tName,
              price: tPrice,
              quantity: 1,
              extraData: {
                'prescription_path': finalPath,
                'prescription_url': finalUrl,
                'prescription_image': finalUrl,
                'lab_id': _selectedProvider!['id'],
                'lab_name': _selectedProvider!['name'],
                'lab_user_id': _selectedProvider!['user_id'] ?? _selectedProvider!['id'],
                'test_id': t['id'],
                'test_name': tName,
                'is_prescription': true,
              },
            ),
          );
        }
      } else {
        cart.addItem(
          CartItem(
            id: 'prescription_${DateTime.now().millisecondsSinceEpoch}',
            name: 'prescription_order_name'.tr(),
            price: 0.0,
            quantity: 1,
            extraData: {
              'prescription_path': finalPath,
              'prescription_url': finalUrl,
              'prescription_image': finalUrl,
              'lab_id': _selectedProvider!['id'],
              'lab_name': _selectedProvider!['name'],
              'lab_user_id': _selectedProvider!['user_id'] ?? _selectedProvider!['id'],
              'is_prescription': true,
            },
          ),
        );
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CheckoutDetailsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              size: 16,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isNursing ? 'nursing_item_1'.tr() : 'upload_prescription'.tr(),
          style: TextStyle(
            fontFamily: 'Rabar',
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: _themeColor),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top Title & Description ──
                  Text(
                    'upload_your_doc'.tr(),
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.isNursing
                        ? 'nursing_item_1_desc'.tr()
                        : 'upload_doc_subtitle'.tr(),
                    style: const TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── 1. Upload Card / Preview ──
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _imageFile != null
                              ? const Color(0xFF10B981)
                              : borderColor,
                          width: _imageFile != null ? 2 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.3 : 0.04,
                            ),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: _imageFile == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: _themeColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Iconsax.camera,
                                    color: _themeColor,
                                    size: 38,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'tap_to_capture_or_upload'.tr(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'jpg_png_pdf_hint'.tr(),
                                  style: const TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 12,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.file(
                                    _imageFile!,
                                    height: 240,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: Color(0xFF10B981),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'change_image'.tr(),
                                      style: TextStyle(
                                        fontFamily: 'Rabar',
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: _themeColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── 2. Select Provider (Nurse or Lab) ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isNursing
                                ? 'select_nurse_step'.tr()
                                : 'select_lab_step'.tr(),
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.isNursing
                                ? 'select_nurse_subtitle'.tr()
                                : 'select_lab_subtitle'.tr(),
                            style: const TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      if (_selectedProvider != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'selected'.tr(),
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFF059669),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Provider List (Nurses or Laboratories)
                  if (_providers.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          widget.isNursing
                              ? 'no_nurses_found'.tr()
                              : 'no_labs_found'.tr(),
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _providers.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, idx) {
                        final provider = _providers[idx];
                        final isSelected =
                            _selectedProvider?['id'] == provider['id'];

                        return GestureDetector(
                          onTap: () => _onProviderSelected(provider),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark
                                      ? _themeColor.withValues(alpha: 0.12)
                                      : _themeColor.withValues(alpha: 0.05))
                                  : cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? _themeColor.withValues(alpha: 0.55)
                                    : borderColor,
                                width: isSelected ? 1.5 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? _themeColor.withValues(alpha: 0.08)
                                      : Colors.black.withValues(
                                          alpha: isDark ? 0.2 : 0.02,
                                        ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                _buildProviderAvatar(provider, isDark),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        context.localizedField(
                                          provider,
                                          'name',
                                          fallback: widget.isNursing
                                              ? (provider['name'] ?? '')
                                              : 'cat_lab'.tr(),
                                        ),
                                        style: TextStyle(
                                          fontFamily: 'Rabar',
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF0F172A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          if (widget.isNursing) ...[
                                            Flexible(
                                              child: Text(
                                                context.localizedField(
                                                  provider,
                                                  'specialty',
                                                  fallback: provider['title'] ??
                                                      'nursing_verified_nurse'.tr(),
                                                ),
                                                style: const TextStyle(
                                                  fontFamily: 'Rabar',
                                                  fontSize: 12,
                                                  color: Color(0xFF64748B),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (provider['city'] != null &&
                                                provider['city'].toString().isNotEmpty) ...[
                                              const SizedBox(width: 6),
                                              const Icon(
                                                Iconsax.location,
                                                size: 11,
                                                color: Color(0xFF64748B),
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                _formatCity(provider['city']),
                                                style: const TextStyle(
                                                  fontFamily: 'Rabar',
                                                  fontSize: 11,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 7,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0D9488)
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                Currency.format(
                                                  provider['fee'] ?? 15000,
                                                ),
                                                style: const TextStyle(
                                                  fontFamily: 'Rabar',
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF0D9488),
                                                ),
                                              ),
                                            ),
                                          ] else ...[
                                            const Icon(
                                              Iconsax.location,
                                              size: 13,
                                              color: Color(0xFF64748B),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatCity(
                                                provider['city'] ??
                                                    provider['location'],
                                              ),
                                              style: const TextStyle(
                                                fontFamily: 'Rabar',
                                                fontSize: 12,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Icon(
                                              Icons.star_rounded,
                                              color: Color(0xFFF59E0B),
                                              size: 14,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              '${provider['rating'] ?? 4.8}',
                                              style: const TextStyle(
                                                fontFamily: 'Rabar',
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? _themeColor
                                          : borderColor,
                                      width: 1.5,
                                    ),
                                    color: isSelected
                                        ? _themeColor
                                        : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          size: 14,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  // ── 3. Lab Tests Selection Section (فحسەکان و نرخەکان) ──
                  if (!widget.isNursing && _selectedProvider != null) ...[
                    const SizedBox(height: 28),
                    _buildLabTestsSection(isDark, cardBg, borderColor),
                  ],
                ],
              ),
            ),

      // ── Bottom Continue Button & Summary ──
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!widget.isNursing && _selectedTestIds.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Iconsax.receipt_2,
                              size: 17,
                              color: Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_selectedTestIds.length} ${'selected_tests_count'.tr()}',
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          Currency.format(_totalTestsPrice),
                          style: const TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _proceedToCheckout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _themeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isUploading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'uploading_image_to_server'.tr(),
                                style: const TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Iconsax.tick_circle,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _selectedTestIds.isNotEmpty && !widget.isNursing
                                      ? '${'continue_checkout'.tr()} • ${Currency.format(_totalTestsPrice)}'
                                      : 'continue_checkout'.tr(),
                                  style: const TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
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
