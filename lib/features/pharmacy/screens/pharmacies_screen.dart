import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../data/pharmacy_repository.dart';
import '../models/pharmacy_model.dart';
import 'pharmacy_detail_screen.dart';

class PharmaciesScreen extends StatefulWidget {
  const PharmaciesScreen({super.key});

  @override
  State<PharmaciesScreen> createState() => _PharmaciesScreenState();
}

class _PharmaciesScreenState extends State<PharmaciesScreen> {
  final PharmacyRepository _repository = PharmacyRepository();
  final TextEditingController _searchCtrl = TextEditingController();
  List<Pharmacy> _pharmacies = [];
  bool _isLoading = true;
  String _selectedFilter = 'هەمووی';

  final List<String> _filters = [
    'هەمووی',
    'ئێشکگر (٢٤/٧)',
    'ناودارترین',
    'نزیکترین',
    'گەیاندنی خێرا',
  ];

  final List<String> _cities = ['هەموو شارەکان', 'هەولێر', 'سلێمانی', 'دهۆک', 'کەرکووک', 'هەڵەبجە'];
  String _selectedCity = 'هەموو شارەکان';
  double _selectedMinRating = 0.0;

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

  @override
  void initState() {
    super.initState();
    _fetchPharmacies();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchPharmacies() async {
    setState(() => _isLoading = true);
    try {
      final pharmacies = await _repository.getPharmacies();
      if (mounted) {
        setState(() {
          _pharmacies = pharmacies;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Pharmacy> get _fallbackPharmacies => [
        Pharmacy(
          id: 1,
          name: 'دەرمانخانەی شاری پزیشکی (City Pharmacy)',
          address: 'هەولێر، شەقامی ٤٠ مەتری - نزیک نەخۆشخانەی نانەکەلی',
          phone: '07501234567',
          rating: 4.9,
          deliveryFee: 2500,
          isOpen: true,
          profileImage: 'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=600',
        ),
        Pharmacy(
          id: 2,
          name: 'دەرمانخانەی ژیان (Zhyan 24/7 Pharmacy)',
          address: 'سلێمانی، شەقامی تووی مەلیك - بەرامبەر پارکی ئازادی',
          phone: '07701234567',
          rating: 4.8,
          deliveryFee: 3000,
          isOpen: true,
          profileImage: 'https://images.unsplash.com/photo-1576602976047-174e57a47881?w=600',
        ),
        Pharmacy(
          id: 3,
          name: 'دەرمانخانەی ڕۆژ (Rozh Pharmacy)',
          address: 'دهۆک، شەقامی گشتی کاوە - تەنیشت سەنتەری پزیشکی',
          phone: '07509876543',
          rating: 4.7,
          deliveryFee: 2000,
          isOpen: false,
          profileImage: 'https://images.unsplash.com/photo-1631549916768-4119b2e5f926?w=600',
        ),
        Pharmacy(
          id: 4,
          name: 'دەرمانخانەی شیفا (Shifa Pharmacy)',
          address: 'هەولێر، شەقامی ٦٠ مەتری - گەڕەکی وەزیران',
          phone: '07503332211',
          rating: 4.9,
          deliveryFee: 2500,
          isOpen: true,
          profileImage: 'https://images.unsplash.com/photo-1586015555751-63bb77f4322a?w=600',
        ),
      ];

  List<Pharmacy> _getFilteredPharmacies() {
    final displayList = _pharmacies.isNotEmpty ? _pharmacies : _fallbackPharmacies;
    final query = _searchCtrl.text.trim().toLowerCase();

    return displayList.where((pharmacy) {
      final matchesSearch = query.isEmpty ||
          pharmacy.name.toLowerCase().contains(query) ||
          (pharmacy.address?.toLowerCase().contains(query) ?? false);

      if (!matchesSearch) return false;

      // City filter
      if (_selectedCity != 'هەموو شارەکان') {
        final address = pharmacy.address?.toLowerCase() ?? '';
        final city = _selectedCity.toLowerCase();
        if (!address.contains(city)) return false;
      }

      // Rating filter
      if (_selectedMinRating > 0.0) {
        if (pharmacy.rating < _selectedMinRating) return false;
      }

      // Quick filter chips
      if (_selectedFilter == 'ئێشکگر (٢٤/٧)' || _selectedFilter == 'کراوەیە ئێستا') {
        return pharmacy.isOpen;
      } else if (_selectedFilter == 'ناودارترین' || _selectedFilter == 'بەرزترین هەڵسەنگاندن') {
        return pharmacy.rating >= 4.8;
      } else if (_selectedFilter == 'گەیاندنی خێرا' || _selectedFilter == 'کەمترین کرێ') {
        return pharmacy.deliveryFee <= 3000;
      } else if (_selectedFilter == 'نزیکترین') {
        return true;
      }

      return true;
    }).toList();
  }

  void _showAdvancedFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;

            return Container(
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'فلتەرکردنی دەرمانخانەکان',
                        style: _kStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedCity = 'هەموو شارەکان';
                            _selectedMinRating = 0.0;
                          });
                          setState(() {});
                        },
                        child: Text(
                          'سڕینەوە',
                          style: _kStyle(
                            color: const Color(0xFFEF4444),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // By City
                  Text(
                    'بەپێی شار',
                    style: _kStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _cities.map((city) {
                      final isSelected = _selectedCity == city;
                      return ChoiceChip(
                        label: Text(
                          city,
                          style: _kStyle(
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: const Color(0xFF3B82F6),
                        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF3B82F6)
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          ),
                        ),
                        onSelected: (val) {
                          setModalState(() => _selectedCity = city);
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // By Rating
                  Text(
                    'بەپێی هەڵسەنگاندن',
                    style: _kStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      {'label': 'هەموو نمرەکان', 'min': 0.0},
                      {'label': '⭐ ٤.٥ و بەرزتر', 'min': 4.5},
                      {'label': '⭐ ٤.٧ و بەرزتر', 'min': 4.7},
                      {'label': '⭐ ٤.٩ و بەرزتر', 'min': 4.9},
                    ].map((item) {
                      final double minVal = item['min'] as double;
                      final bool isSelected = _selectedMinRating == minVal;
                      return ChoiceChip(
                        label: Text(
                          item['label'] as String,
                          style: _kStyle(
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: const Color(0xFF3B82F6),
                        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF3B82F6)
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          ),
                        ),
                        onSelected: (val) {
                          setModalState(() => _selectedMinRating = minVal);
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'جێبەجێکردنی فلتەر',
                        style: _kStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredPharmacies = _getFilteredPharmacies();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        color: const Color(0xFF3B82F6),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        displacement: 40,
        onRefresh: _fetchPharmacies,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            _buildSliverAppBar(isDark),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchAndFilters(isDark),

                  if (_isLoading)
                    const SizedBox(
                      height: 300,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    )
                  else if (filteredPharmacies.isEmpty)
                    SizedBox(
                      height: 320,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Iconsax.search_normal_1,
                                size: 44,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'هیچ دەرمانخانەیەک نەدۆزرایەوە',
                              style: _kStyle(
                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                      ),
                    )
                  else
                    ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredPharmacies.length,
                      itemBuilder: (context, index) {
                        return _buildPremiumPharmacyCard(
                          filteredPharmacies[index],
                          index,
                          isDark,
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
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
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                size: 16,
              ),
            ),
          ),
        ),
      ),
      title: Text(
        'دەرمانخانەکان',
        style: _kStyle(
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          fontSize: 17.5,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: const [
        SizedBox(width: 64),
      ],
    );
  }

  Widget _buildSearchAndFilters(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
      color: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar + Settings Filter Button
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
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
                          onChanged: (_) => setState(() {}),
                          style: _kStyle(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 13.5,
                          ),
                          decoration: InputDecoration(
                            hintText: 'گەڕان بۆ ناوی دەرمانخانە، گەڕەک...',
                            hintStyle: _kStyle(
                              color: const Color(0xFF94A3B8),
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (_searchCtrl.text.isNotEmpty)
                        GestureDetector(
                          onTap: () => setState(() => _searchCtrl.clear()),
                          child: const Padding(
                            padding: EdgeInsetsDirectional.only(end: 12),
                            child: Icon(Icons.close, color: Color(0xFF94A3B8), size: 18),
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
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Iconsax.setting_4, color: Colors.white, size: 22),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.08),

          const SizedBox(height: 16),

          // Filters Row
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;

                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedFilter = filter);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF3B82F6)
                            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF3B82F6)
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
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
                        filter,
                        style: _kStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : const Color(0xFF475569)),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ).animate().fadeIn(delay: 150.ms).slideX(begin: 0.05),
        ],
      ),
    );
  }

  String _getDisplayCity(Pharmacy pharmacy) {
    if (pharmacy.city != null && pharmacy.city!.trim().isNotEmpty) {
      final c = pharmacy.city!.trim().toLowerCase();
      if (c.contains('erbil') || c.contains('هەولێر') || c.contains('اربيل')) return 'هەولێر';
      if (c.contains('sulayman') || c.contains('سلێمانی') || c.contains('سليمانية')) return 'سلێمانی';
      if (c.contains('duhok') || c.contains('دهۆک') || c.contains('دهوك')) return 'دهۆک';
      if (c.contains('kirkuk') || c.contains('کەرکووک') || c.contains('كركوك')) return 'کەرکووک';
      if (c.contains('halabja') || c.contains('هەڵەبجە') || c.contains('حلبجة')) return 'هەڵەبجە';
      return pharmacy.city!;
    }
    if (pharmacy.address != null && pharmacy.address!.isNotEmpty) {
      final parts = pharmacy.address!.split(RegExp(r'[,،-]'));
      if (parts.isNotEmpty && parts.first.trim().isNotEmpty) {
        return parts.first.trim();
      }
    }
    return 'هەولێر';
  }

  Widget _buildPremiumPharmacyCard(Pharmacy pharmacy, int index, bool isDark) {
    final isOpen = pharmacy.isOpen;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0).withValues(alpha: 0.8);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PharmacyDetailScreen(pharmacy: pharmacy),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Left: Pharmacy Image ──
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 92,
                height: 92,
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEFF6FF),
                child: pharmacy.profileImage != null && pharmacy.profileImage!.isNotEmpty
                    ? Image.network(
                        pharmacy.profileImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(
                            Icons.local_pharmacy_rounded,
                            color: Color(0xFF3B82F6),
                            size: 36,
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.local_pharmacy_rounded,
                          color: Color(0xFF3B82F6),
                          size: 36,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 13),

            // ── Right: Pharmacy Details ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Pharmacy Name
                  Text(
                    pharmacy.name,
                    style: _kStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 7),

                  // 2. Middle Row: Location Pin + City + Rating Badge
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
                          _getDisplayCity(pharmacy),
                          style: _kStyle(
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
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
                              pharmacy.rating > 0
                                  ? pharmacy.rating.toStringAsFixed(1)
                                  : '4.9',
                              style: _kStyle(
                                color: const Color(0xFFB45309),
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),

                  // 3. Bottom Row: [ Open Status Pill ] & [ "بینینی دەرمان" Action Pill ]
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: isOpen
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFFEF2F2),
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
                                    : const Color(0xFFEF4444),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isOpen ? 'کراوەیە ئێستا' : 'داخراوە',
                              style: _kStyle(
                                color: isOpen
                                    ? const Color(0xFF047857)
                                    : const Color(0xFFDC2626),
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 5.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'بینینی دەرمان',
                              style: _kStyle(
                                color: const Color(0xFF2563EB),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Color(0xFF2563EB),
                              size: 12,
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
    ).animate().fadeIn(delay: (index * 45).ms).slideY(begin: 0.04, end: 0);
  }
}
