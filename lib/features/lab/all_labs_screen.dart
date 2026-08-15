import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'lab_details_screen.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/utils/api_client.dart';
import 'package:easy_localization/easy_localization.dart';

class AllLabsScreen extends StatefulWidget {
  const AllLabsScreen({super.key});

  @override
  State<AllLabsScreen> createState() => _AllLabsScreenState();
}

class _AllLabsScreenState extends State<AllLabsScreen> {
  List<dynamic> _allLabs = [];
  List<dynamic> _filteredLabs = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  final TextEditingController _searchCtrl = TextEditingController();

  final List<String> _filters = ['All', 'top_rated', 'nearest', 'open_now'];

  // Dynamic filter state from API
  List<String> _dynamicCities = ['All', 'Erbil', 'Sulaymaniyah', 'Duhok', 'Kirkuk', 'Halabja'];
  List<Map<String, dynamic>> _dynamicRatings = [
    {'key': 'all', 'label': 'All', 'min': 0.0},
    {'key': '4_5', 'label': '4.5+', 'min': 4.5},
    {'key': '4_7', 'label': '4.7+', 'min': 4.7},
    {'key': '4_9', 'label': '4.9+', 'min': 4.9},
  ];

  String _selectedCity = 'All';
  double _selectedMinRating = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchLabs();
  }

  String _tr(String key, BuildContext ctx) {
    final lang = ctx.locale.languageCode;
    final isKurdish = lang == 'ckb' || lang == 'ku';
    final isArabic = lang == 'ar';

    switch (key) {
      case 'filter_labs':
        if (isKurdish) return 'فلتەرکردنی تاقیگەکان';
        if (isArabic) return 'تصفية المختبرات';
        return 'Filter Laboratories';
      case 'reset_filter':
        if (isKurdish) return 'سڕینەوە';
        if (isArabic) return 'إعادة ضبط';
        return 'Reset';
      case 'filter_by_city':
        if (isKurdish) return 'بەپێی شار';
        if (isArabic) return 'حسب المدينة';
        return 'By City';
      case 'filter_by_rating':
        if (isKurdish) return 'بەپێی هەڵسەنگاندن';
        if (isArabic) return 'حسب التقييم';
        return 'By Rating';
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
      case 'rating_all':
        if (isKurdish) return 'هەموو نمرەکان';
        if (isArabic) return 'جميع التقييمات';
        return 'All Ratings';
      case 'rating_4_5':
        if (isKurdish) return '⭐ ٤.٥ و بەرزتر';
        if (isArabic) return '⭐ 4.5 وأعلى';
        return '⭐ 4.5 & up';
      case 'rating_4_7':
        if (isKurdish) return '⭐ ٤.٧ و بەرزتر';
        if (isArabic) return '⭐ 4.7 وأعلى';
        return '⭐ 4.7 & up';
      case 'rating_4_9':
        if (isKurdish) return '⭐ ٤.٩ و بەرزتر';
        if (isArabic) return '⭐ 4.9 وأعلى';
        return '⭐ 4.9 & up';
      case 'apply_filter':
        if (isKurdish) return 'جێبەجێکردنی فلتەر';
        if (isArabic) return 'تطبيق التصفية';
        return 'Apply Filter';
      case 'all_labs':
        if (isKurdish) return 'هەموو تاقیگە پزیشکییەکان';
        if (isArabic) return 'جميع المختبرات الطبية';
        return 'All Laboratories';
      case 'top_rated':
        if (isKurdish) return 'بەرزترین هەڵسەنگاندن';
        if (isArabic) return 'الأعلى تقييماً';
        return 'Top Rated';
      case 'nearest':
        if (isKurdish) return 'نزیکترین';
        if (isArabic) return 'الأقرب';
        return 'Nearest';
      case 'open_now':
        if (isKurdish) return 'کراوەیە ئێستا';
        if (isArabic) return 'مفتوح الآن';
        return 'Open Now';
      case 'closed_now':
        if (isKurdish) return 'داخراوە';
        if (isArabic) return 'مغلق';
        return 'Closed';
      case 'discount':
        if (isKurdish) return 'داشکاندن';
        if (isArabic) return 'خصم';
        return 'OFF';
      case 'search_labs':
        if (isKurdish) return 'گەڕان بۆ ناوی تاقیگە...';
        if (isArabic) return 'البحث عن المختبر...';
        return 'Search laboratories...';
      case 'no_labs_found':
        if (isKurdish) return 'هیچ تاقیگەیەک نەدۆزرایەوە';
        if (isArabic) return 'لم يتم العثور على مختبرات';
        return 'No laboratories found';
      case 'view_more':
        if (isKurdish) return 'زیاتر ببینە';
        if (isArabic) return 'عرض المزيد';
        return 'View Details';
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

  String _getLocalizedRatingName(double minRating, BuildContext ctx) {
    if (minRating <= 0.0) return _tr('rating_all', ctx);
    if (minRating == 4.5) return _tr('rating_4_5', ctx);
    if (minRating == 4.7) return _tr('rating_4_7', ctx);
    if (minRating == 4.9) return _tr('rating_4_9', ctx);
    return '⭐ $minRating+';
  }

  Future<void> _fetchLabs() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.get('/labs');
      if (response.statusCode == 200 && mounted) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> labs = decoded is Map && decoded.containsKey('data')
            ? decoded['data']
            : (decoded is List ? decoded : []);

        // Dynamic filters from API
        if (decoded is Map && decoded.containsKey('filters')) {
          final filtersMap = decoded['filters'];
          if (filtersMap['cities'] is List) {
            _dynamicCities = List<String>.from(filtersMap['cities']);
          }
          if (filtersMap['ratings'] is List) {
            _dynamicRatings = List<Map<String, dynamic>>.from(
              (filtersMap['ratings'] as List).map((r) => Map<String, dynamic>.from(r)),
            );
          }
        } else if (labs.isNotEmpty) {
          // Fallback: extract distinct cities from labs dynamically
          final extractedCities = labs
              .map((l) => l['city']?.toString())
              .where((c) => c != null && c.isNotEmpty)
              .toSet()
              .cast<String>()
              .toList();
          if (!extractedCities.contains('All')) {
            extractedCities.insert(0, 'All');
          }
          _dynamicCities = extractedCities;
        }

        setState(() {
          _allLabs = labs;
        });
      }
    } catch (e) {
      debugPrint('Error fetching labs: $e');
    } finally {
      if (mounted) {
        setState(() {
          _filteredLabs = _allLabs;
          _isLoading = false;
        });
      }
    }
  }

  void _filterLabs() {
    final query = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      var list = _allLabs.where((lab) {
        final name = lab['name']?.toString().toLowerCase() ?? '';
        final city = lab['city']?.toString().toLowerCase() ?? '';
        final type = lab['type']?.toString().toLowerCase() ?? '';
        final rating =
            double.tryParse(lab['rating']?.toString() ?? '0') ?? 0.0;
        final isOpen = lab['is_open'] == true;

        // Search text
        final matchesQuery = query.isEmpty ||
            name.contains(query) ||
            city.contains(query) ||
            type.contains(query);

        // Top quick horizontal tab
        bool matchesTopTab = true;
        if (_selectedFilter == 'top_rated') {
          matchesTopTab = rating >= 4.7;
        } else if (_selectedFilter == 'nearest') {
          matchesTopTab = city.contains('erbil') || city.contains('هەولێر');
        } else if (_selectedFilter == 'open_now') {
          matchesTopTab = isOpen;
        }

        // City filter from dynamic API cities
        bool matchesCity = true;
        if (_selectedCity != 'All' && _selectedCity.isNotEmpty) {
          matchesCity = city.contains(_selectedCity.toLowerCase()) ||
              _selectedCity.toLowerCase().contains(city);
        }

        // Rating filter from dynamic API ratings
        bool matchesRating = rating >= _selectedMinRating;

        return matchesQuery &&
            matchesTopTab &&
            matchesCity &&
            matchesRating;
      }).toList();

      if (_selectedFilter == 'top_rated' || _selectedMinRating > 0.0) {
        list.sort((a, b) {
          final rA =
              double.tryParse(a['rating']?.toString() ?? '0') ?? 0.0;
          final rB =
              double.tryParse(b['rating']?.toString() ?? '0') ?? 0.0;
          return rB.compareTo(rA);
        });
      }

      _filteredLabs = list;
    });
  }

  TextStyle _kurdishStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color color = const Color(0xFF0F172A),
    double? height,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: 'Rabar',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      decoration: decoration,
    );
  }

  void _showAdvancedFilterModal() {
    String tempCity = _selectedCity;
    double tempMinRating = _selectedMinRating;

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
                          _tr('filter_labs', context),
                          style: _kurdishStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setModalState(() {
                              tempCity = 'All';
                              tempMinRating = 0.0;
                            });
                          },
                          child: Text(
                            _tr('reset_filter', context),
                            style: _kurdishStyle(
                              color: const Color(0xFFEF4444),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // ── Section 1: By City (Dynamic from API) ──
                    Row(
                      children: [
                        const Icon(
                          Iconsax.location,
                          color: Color(0xFF3B82F6),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _tr('filter_by_city', context),
                          style: _kurdishStyle(
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
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSel
                                    ? const Color(0xFF3B82F6)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              _getLocalizedCityName(city, context),
                              style: _kurdishStyle(
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

                    // ── Section 2: By Rating (Dynamic from API) ──
                    Row(
                      children: [
                        const Icon(
                          Iconsax.star_1,
                          color: Color(0xFFF59E0B),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _tr('filter_by_rating', context),
                          style: _kurdishStyle(
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
                      children: _dynamicRatings.map((opt) {
                        final minVal = (opt['min'] as num).toDouble();
                        final isSel = (tempMinRating - minVal).abs() < 0.01;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() => tempMinRating = minVal);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSel
                                    ? const Color(0xFF3B82F6)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              _getLocalizedRatingName(minVal, context),
                              style: _kurdishStyle(
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
                            _selectedMinRating = tempMinRating;
                          });
                          Navigator.pop(context);
                          _filterLabs();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _tr('apply_filter', context),
                          style: _kurdishStyle(
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
        color: const Color(0xFF3B82F6),
        backgroundColor: Colors.white,
        displacement: 40,
        onRefresh: _fetchLabs,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
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
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    )
                  else if (_filteredLabs.isEmpty)
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
                              child: const Icon(
                                Iconsax.search_normal_1,
                                size: 48,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _tr('no_labs_found', context),
                              style: _kurdishStyle(
                                color: const Color(0xFF475569),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
                      ),
                    )
                  else
                    ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredLabs.length,
                      itemBuilder: (context, index) {
                        return _buildPremiumLabCard(_filteredLabs[index], index);
                      },
                    ),
                  const SizedBox(height: 40),
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
      expandedHeight: 110,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF0F172A),
            size: 18,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(start: 60, bottom: 16, end: 20),
        title: Text(
          _tr('all_labs', context),
          style: _kurdishStyle(
            color: const Color(0xFF0F172A),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
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
                      const Icon(
                        Iconsax.search_normal_1,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (_) => _filterLabs(),
                          style: _kurdishStyle(
                            color: const Color(0xFF0F172A),
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: _tr('search_labs', context),
                            hintStyle: _kurdishStyle(
                              color: const Color(0xFF94A3B8),
                              fontSize: 13,
                            ),
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
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.28),
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

          // Filters Row
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
                    _filterLabs();
                  },
                  child: Container(
                    margin: const EdgeInsetsDirectional.only(end: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      filter == 'All' ? _tr('all_labs', context) : _tr(filter, context),
                      style: _kurdishStyle(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF475569),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
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

  Widget _buildPremiumLabCard(dynamic lab, int index) {
    final bool isOpen = lab['is_open'] == true;
    final discount = lab['discount'];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LabDetailsScreen(lab: lab)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Left: Image + Discount Badge ──
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    (lab['image'] != null && lab['image'].toString().isNotEmpty)
                        ? lab['image'].toString()
                        : 'assets/images/laboratory.jpg',
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Iconsax.hospital, color: Color(0xFF3B82F6), size: 36),
                    ),
                  ),
                ),
                if (discount != null)
                  PositionedDirectional(
                    top: 6,
                    start: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '%$discount ${_tr('discount', context)}',
                        style: _kurdishStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // ── Right: Details ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Lab Name
                  Text(
                    '${lab['name'] ?? 'تاقیگە'}',
                    style: _kurdishStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 7),

                  // 2. Middle Row: Location Pin + City + Rating Badge beside it
                  Row(
                    children: [
                      const Icon(
                        Iconsax.location,
                        color: Color(0xFF3B82F6),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _getLocalizedCityName('${lab['city'] ?? 'Erbil'}', context),
                          style: _kurdishStyle(
                            color: const Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Rating Pill beside location
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFD97706),
                              size: 13,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${lab['rating'] ?? 4.8}',
                              style: _kurdishStyle(
                                color: const Color(0xFFB45309),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Bottom Row: [ Open/Closed Status ] & [ "زیاتر ببینە" Button ]
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Open / Closed Status Pill in the Bottom Row
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: isOpen
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isOpen
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isOpen
                                  ? _tr('open_now', context)
                                  : _tr('closed_now', context),
                              style: _kurdishStyle(
                                color: isOpen
                                    ? const Color(0xFF047857)
                                    : const Color(0xFF64748B),
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // "زیاتر ببینە" Button
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _tr('view_more', context),
                              style: _kurdishStyle(
                                color: const Color(0xFF2563EB),
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Color(0xFF2563EB),
                              size: 9,
                            ),
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
}
