import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/utils/api_client.dart';
import 'package:easy_localization/easy_localization.dart';
import 'nursing_services_screen.dart';

class NurseListScreen extends StatefulWidget {
  const NurseListScreen({super.key});

  @override
  State<NurseListScreen> createState() => _NurseListScreenState();
}

class _NurseListScreenState extends State<NurseListScreen> {
  List<Map<String, dynamic>> _allNurses = [];
  List<Map<String, dynamic>> _filteredNurses = [];
  bool _isLoading = true;
  
  final TextEditingController _searchCtrl = TextEditingController();
  
  // Quick filters (Horizontal tabs)
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'top_experience', 'nearest', 'available_now'];

  // Advanced filters (from Bottom Sheet)
  String _selectedCity = 'All';
  String _selectedServiceType = 'All';
  
  List<String> _dynamicCities = ['All'];
  List<Map<String, dynamic>> _dynamicServiceTypes = [
    {'id': 'all', 'name': 'All', 'name_en': 'All', 'name_ar': 'الكل'},
    {'id': 'home_nursing', 'name': 'پەرستاری ماڵ', 'name_en': 'Home Nursing', 'name_ar': 'تمريض منزلي'},
    {'id': 'clinic', 'name': 'کلینیک', 'name_en': 'Clinic', 'name_ar': 'عيادة'},
    {'id': 'hospital', 'name': 'نەخۆشخانە', 'name_en': 'Hospital', 'name_ar': 'مستشفى'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchNurses();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _tr(String key, BuildContext context) {
    final lang = context.locale.languageCode;
    final isKurdish = lang == 'ckb' || lang == 'ku';
    final isArabic = lang == 'ar';

    switch (key) {
      case 'all_nurses':
        if (isKurdish) return 'هەموو پەرستارەکان';
        if (isArabic) return 'جميع الممرضين';
        return 'All Nurses';
      case 'All':
        if (isKurdish) return 'هەمووی';
        if (isArabic) return 'الكل';
        return 'All';
      case 'search':
        if (isKurdish) return 'گەڕان بۆ ناوی پەرستار...';
        if (isArabic) return 'البحث عن ممرض...';
        return 'Search nurses...';
      case 'no_nurses':
        if (isKurdish) return 'هیچ پەرستارێک نەدۆزرایەوە';
        if (isArabic) return 'لم يتم العثور على ممرضين';
        return 'No nurses found';
      case 'request_service':
        if (isKurdish) return 'داواکردن';
        if (isArabic) return 'طلب خدمة';
        return 'Request';
      case 'available':
        if (isKurdish) return 'ئامادەیە';
        if (isArabic) return 'متاح';
        return 'Available';
      case 'unavailable':
        if (isKurdish) return 'ئامادە نییە';
        if (isArabic) return 'غير متاح';
        return 'Unavailable';
      case 'top_experience':
        if (isKurdish) return 'بە ئەزموونترین';
        if (isArabic) return 'الأكثر خبرة';
        return 'Top Experienced';
      case 'nearest':
        if (isKurdish) return 'نزیکترین';
        if (isArabic) return 'الأقرب';
        return 'Nearest';
      case 'available_now':
        if (isKurdish) return 'ئامادەیە ئێستا';
        if (isArabic) return 'متاح الآن';
        return 'Available Now';
      case 'filter_nurses':
        if (isKurdish) return 'فلتەرکردنی پەرستارەکان';
        if (isArabic) return 'تصفية الممرضين';
        return 'Filter Nurses';
      case 'reset_filter':
        if (isKurdish) return 'سڕینەوە';
        if (isArabic) return 'إعادة ضبط';
        return 'Reset';
      case 'filter_by_city':
        if (isKurdish) return 'بەپێی شار';
        if (isArabic) return 'حسب المدينة';
        return 'By City';
      case 'filter_by_service_type':
        if (isKurdish) return 'بەپێی جۆری خزمەتگوزاری';
        if (isArabic) return 'حسب نوع الخدمة';
        return 'By Service Type';
      case 'city_all':
        if (isKurdish) return 'هەموو شارەکان';
        if (isArabic) return 'جميع المدن';
        return 'All Cities';
      case 'city_erbil':
        if (isKurdish) return 'هەولێر';
        if (isArabic) return 'أربيل';
        return 'Erbil';
      case 'city_sulaymaniyah':
        if (isKurdish) return 'سلێمانی';
        if (isArabic) return 'السليمانية';
        return 'Sulaymaniyah';
      case 'city_duhok':
        if (isKurdish) return 'دهۆک';
        if (isArabic) return 'دهوك';
        return 'Duhok';
      case 'city_kirkuk':
        if (isKurdish) return 'کەرکووک';
        if (isArabic) return 'كركوك';
        return 'Kirkuk';
      case 'city_halabja':
        if (isKurdish) return 'هەڵەبجە';
        if (isArabic) return 'حلبجة';
        return 'Halabja';
      default:
        return key.tr();
    }
  }

  String _getLocalizedCityName(String city, BuildContext ctx) {
    final lower = city.toLowerCase().trim();
    if (lower == 'all') return _tr('city_all', ctx);
    if (lower.contains('erbil') || lower.contains('هەولێر') || lower.contains('أربيل')) return _tr('city_erbil', ctx);
    if (lower.contains('sulaymaniyah') || lower.contains('سلێمانی') || lower.contains('السليمانية')) return _tr('city_sulaymaniyah', ctx);
    if (lower.contains('duhok') || lower.contains('دهۆک') || lower.contains('دهوك')) return _tr('city_duhok', ctx);
    if (lower.contains('kirkuk') || lower.contains('کەرکووک') || lower.contains('كركوك')) return _tr('city_kirkuk', ctx);
    if (lower.contains('halabja') || lower.contains('هەڵەبجە') || lower.contains('حلبجة')) return _tr('city_halabja', ctx);
    return city;
  }

  String _getLocalizedServiceTypeName(Map<String, dynamic> type, BuildContext ctx) {
    if (type['id'] == 'all') return _tr('All', ctx);
    final lang = ctx.locale.languageCode;
    final isKurdish = lang == 'ckb' || lang == 'ku';
    final isArabic = lang == 'ar';
    if (isArabic) return type['name_ar'] ?? type['name'] ?? '';
    if (!isKurdish) return type['name_en'] ?? type['name'] ?? '';
    return type['name'] ?? '';
  }

  TextStyle _kStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color color = const Color(0xFF0F172A),
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'Rabar',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  Future<void> _fetchNurses() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.get('/nurses');
      if (response.statusCode == 200 && mounted) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> nurses = decoded['nurses'] ?? [];
        
        // Extract cities dynamically from the nurses list if not provided by API
        final extractedCities = nurses
            .map((n) => n['city']?.toString())
            .where((c) => c != null && c.isNotEmpty)
            .toSet()
            .cast<String>()
            .toList();
        if (!extractedCities.contains('All')) {
          extractedCities.insert(0, 'All');
        }

        setState(() {
          _allNurses = nurses.cast<Map<String, dynamic>>();
          _dynamicCities = extractedCities;
          _isLoading = false;
        });
        _filterNurses();
      }
    } catch (e) {
      debugPrint('Error fetching nurses: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterNurses() {
    final query = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      var list = _allNurses.where((n) {
        final name = (n['name'] ?? '').toString().toLowerCase();
        final specialty = (n['specialty'] ?? '').toString().toLowerCase();
        final specialtyEn = (n['specialty_en'] ?? '').toString().toLowerCase();
        final city = (n['city'] ?? '').toString().toLowerCase();
        final serviceType = (n['service_type'] ?? '').toString().toLowerCase();
        final isAvailable = n['is_available'] == true;
        final completed = n['completed_appointments'] ?? 0;

        // Search text
        final matchesQuery = query.isEmpty ||
            name.contains(query) ||
            specialty.contains(query) ||
            specialtyEn.contains(query);

        // Quick horizontal tab
        bool matchesTopTab = true;
        if (_selectedFilter == 'top_experience') {
          matchesTopTab = completed > 0;
        } else if (_selectedFilter == 'nearest') {
          matchesTopTab = city.contains('erbil') || city.contains('هەولێر');
        } else if (_selectedFilter == 'available_now') {
          matchesTopTab = isAvailable;
        }

        // City filter from advanced modal
        bool matchesCity = true;
        if (_selectedCity != 'All' && _selectedCity.isNotEmpty) {
          matchesCity = city == _selectedCity.toLowerCase();
        }

        // Service Type filter from advanced modal
        bool matchesServiceType = true;
        if (_selectedServiceType != 'All' && _selectedServiceType != 'all' && _selectedServiceType.isNotEmpty) {
          matchesServiceType = serviceType == _selectedServiceType.toLowerCase();
        }

        return matchesQuery && matchesTopTab && matchesCity && matchesServiceType;
      }).toList();

      if (_selectedFilter == 'top_experience') {
        list.sort((a, b) {
          final cA = a['completed_appointments'] ?? 0;
          final cB = b['completed_appointments'] ?? 0;
          return cB.compareTo(cA);
        });
      }

      _filteredNurses = list;
    });
  }

  void _showAdvancedFilterModal() {
    String tempCity = _selectedCity;
    String tempServiceType = _selectedServiceType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Header: Title & Reset Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _tr('filter_nurses', context),
                          style: _kStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setModalState(() {
                              tempCity = 'All';
                              tempServiceType = 'all';
                            });
                          },
                          child: Text(
                            _tr('reset_filter', context),
                            style: _kStyle(
                              color: const Color(0xFFEF4444),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // ── Section 1: By City ──
                    Row(
                      children: [
                        const Icon(
                          Iconsax.location,
                          color: Color(0xFF0D9488),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _tr('filter_by_city', context),
                          style: _kStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _dynamicCities.map((city) {
                        final isSel = tempCity.toLowerCase() == city.toLowerCase();
                        return GestureDetector(
                          onTap: () {
                            setModalState(() => tempCity = city);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? const Color(0xFF0D9488)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSel
                                    ? const Color(0xFF0D9488)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              _getLocalizedCityName(city, context),
                              style: _kStyle(
                                color: isSel
                                    ? Colors.white
                                    : const Color(0xFF334155),
                                fontWeight: isSel
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // ── Section 2: By Service Type ──
                    Row(
                      children: [
                        const Icon(
                          Iconsax.category,
                          color: Color(0xFF0D9488),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _tr('filter_by_service_type', context),
                          style: _kStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _dynamicServiceTypes.map((type) {
                        final typeId = type['id'] as String;
                        final isSel = tempServiceType == typeId;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() => tempServiceType = typeId);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? const Color(0xFF0D9488)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSel
                                    ? const Color(0xFF0D9488)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              _getLocalizedServiceTypeName(type, context),
                              style: _kStyle(
                                color: isSel
                                    ? Colors.white
                                    : const Color(0xFF334155),
                                fontWeight: isSel
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 26),

                    // ── Apply Button ──
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedCity = tempCity;
                            _selectedServiceType = tempServiceType;
                          });
                          _filterNurses();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _tr('apply_filter', context),
                          style: _kStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        color: const Color(0xFF0D9488),
        backgroundColor: Colors.white,
        displacement: 40,
        onRefresh: _fetchNurses,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchAndFilters(),
                  if (_isLoading)
                    const SizedBox(
                      height: 300,
                      child: Center(child: CircularProgressIndicator(color: Color(0xFF0D9488))),
                    )
                  else if (_filteredNurses.isEmpty)
                    SizedBox(
                      height: 300,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(Iconsax.search_normal_1, size: 48, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _tr('no_nurses', context),
                              style: _kStyle(color: const Color(0xFF475569), fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
                      ),
                    )
                  else
                    ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredNurses.length,
                      itemBuilder: (context, index) {
                        return _buildPremiumNurseCard(_filteredNurses[index], index);
                      },
                    ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsetsDirectional.only(start: 16),
        child: Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 16),
            ),
          ),
        ),
      ),
      title: Text(
        _tr('all_nurses', context),
        style: _kStyle(color: const Color(0xFF0F172A), fontSize: 17, fontWeight: FontWeight.bold),
      ),
      actions: const [SizedBox(width: 64)],
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search Bar ──
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      const Icon(Iconsax.search_normal_1, color: Color(0xFF94A3B8), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (_) => _filterNurses(),
                          style: _kStyle(color: const Color(0xFF0F172A), fontSize: 14),
                          decoration: InputDecoration(
                            hintText: _tr('search', context),
                            hintStyle: _kStyle(color: const Color(0xFF94A3B8), fontSize: 13),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _showAdvancedFilterModal,
                child: Container(
                  height: 54,
                  width: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.28),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Iconsax.setting_4, color: Colors.white),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

          const SizedBox(height: 18),

          // ── Quick Filter Tabs (Horizontal) ──
          SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedFilter = filter);
                    _filterNurses();
                  },
                  child: Container(
                    margin: const EdgeInsetsDirectional.only(end: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF0D9488) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      _tr(filter, context),
                      style: _kStyle(
                        color: isSelected ? Colors.white : const Color(0xFF475569),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildPremiumNurseCard(Map<String, dynamic> nurse, int index) {
    final lang = context.locale.languageCode;
    final isArabic = lang == 'ar';
    final isEnglish = lang == 'en';

    final name = (isArabic && nurse['name_ar'] != null && nurse['name_ar'].toString().isNotEmpty)
        ? nurse['name_ar']
        : (isEnglish && nurse['name_en'] != null && nurse['name_en'].toString().isNotEmpty)
            ? nurse['name_en']
            : (nurse['name'] ?? '');

    final specialty = (isArabic && nurse['specialty_ar'] != null && nurse['specialty_ar'].toString().isNotEmpty)
        ? nurse['specialty_ar']
        : (isEnglish && nurse['specialty_en'] != null && nurse['specialty_en'].toString().isNotEmpty)
            ? nurse['specialty_en']
            : (nurse['specialty'] ?? '');

    final address = (isArabic && nurse['address_ar'] != null && nurse['address_ar'].toString().isNotEmpty)
        ? nurse['address_ar']
        : (isEnglish && nurse['address_en'] != null && nurse['address_en'].toString().isNotEmpty)
            ? nurse['address_en']
            : (nurse['address'] ?? '');

    final bio = (isArabic && nurse['bio_ar'] != null && nurse['bio_ar'].toString().isNotEmpty)
        ? nurse['bio_ar']
        : (isEnglish && nurse['bio_en'] != null && nurse['bio_en'].toString().isNotEmpty)
            ? nurse['bio_en']
            : (nurse['bio'] ?? '');

    final image = nurse['image'];
    final phone = nurse['phone'] ?? '';
    final isAvailable = nurse['is_available'] == true;
    final customServices = nurse['custom_services'] as List<dynamic>? ?? [];
    final fee = nurse['fee'];
    final city = nurse['city'] ?? '';

    // Prioritize specialties as badges
    final List<String> allServiceBadges = [];
    if (specialty.isNotEmpty) {
      final parts = specialty.split(RegExp(r'[،,]')).map((e) => e.trim()).where((e) => e.isNotEmpty);
      allServiceBadges.addAll(parts);
    }
    for (var cs in customServices) {
      if (cs is Map && cs['name'] != null && cs['name'].toString().isNotEmpty) {
        final csName = (isArabic && cs['name_ar'] != null && cs['name_ar'].toString().isNotEmpty)
            ? cs['name_ar']
            : (isEnglish && cs['name_en'] != null && cs['name_en'].toString().isNotEmpty)
                ? cs['name_en']
                : cs['name'].toString();
        if (!allServiceBadges.contains(csName)) {
          allServiceBadges.add(csName);
        }
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NursingServicesScreen(
              nurse: nurse,
              nurseId: nurse['id'],
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.8), width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar ──
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                    ),
                    image: image != null ? DecorationImage(image: NetworkImage(image), fit: BoxFit.cover) : null,
                  ),
                  child: image == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Iconsax.health, color: Colors.white, size: 32),
                              const SizedBox(height: 4),
                              Text(
                                name.isNotEmpty ? name.split(' ').first : 'ن',
                                style: _kStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        )
                      : null,
                ),
                // Badge
                PositionedDirectional(
                  top: 6,
                  start: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isAvailable
                            ? [const Color(0xFF10B981), const Color(0xFF059669)]
                            : [const Color(0xFF94A3B8), const Color(0xFF64748B)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: (isAvailable ? const Color(0xFF10B981) : const Color(0xFF94A3B8)).withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      isAvailable ? _tr('available', context) : _tr('unavailable', context),
                      style: _kStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // ── Details ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    name,
                    style: _kStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),

                  // Specialty + city
                  Row(
                    children: [
                      const Icon(Iconsax.health, color: Color(0xFF0D9488), size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          specialty,
                          style: _kStyle(color: const Color(0xFF64748B), fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (city.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDFA),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Iconsax.location, color: Color(0xFF0D9488), size: 11),
                              const SizedBox(width: 3),
                              Text(
                                _cityKurdish(city),
                                style: _kStyle(color: const Color(0xFF0D9488), fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, color: Color(0xFF94A3B8), size: 12),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            address,
                            style: _kStyle(color: const Color(0xFF94A3B8), fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      bio,
                      style: _kStyle(color: const Color(0xFF64748B), fontSize: 11.5, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),

                  // Service / Specialty tags
                  if (allServiceBadges.isNotEmpty)
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: allServiceBadges.take(4).map<Widget>((s) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            s,
                            style: _kStyle(color: const Color(0xFF475569), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 10),

                  // Bottom: fee/phone + request
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (fee != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${double.tryParse(fee.toString())?.toInt() ?? fee} د.ع',
                            style: _kStyle(color: const Color(0xFFB45309), fontSize: 10.5, fontWeight: FontWeight.bold),
                          ),
                        )
                      else if (phone.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Iconsax.call, color: Color(0xFF64748B), size: 12),
                              const SizedBox(width: 4),
                              Text(phone, style: _kStyle(color: const Color(0xFF64748B), fontSize: 10.5, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      else
                        const SizedBox.shrink(),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_tr('request_service', context), style: _kStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 9),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (60 * index).ms).slideY(begin: 0.08, end: 0);
  }

  String _cityKurdish(String city) {
    final map = {
      'Erbil': 'هەولێر',
      'Sulaymaniyah': 'سلێمانی',
      'Duhok': 'دهۆک',
      'Kirkuk': 'کەرکووک',
      'Halabja': 'هەڵەبجە',
    };
    return map[city] ?? city;
  }
}
