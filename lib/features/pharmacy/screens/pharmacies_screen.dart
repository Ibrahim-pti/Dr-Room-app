import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final TextEditingController _searchController = TextEditingController();
  List<Pharmacy> _pharmacies = [];
  bool _isLoading = true;
  String _selectedFilter = 'هەمووی';

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

  Future<void> _fetchPharmacies() async {
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

  Future<void> _makeCall(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final Uri uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final displayList = _pharmacies.isNotEmpty ? _pharmacies : _fallbackPharmacies;

    final filteredList = displayList.where((pharmacy) {
      final query = _searchController.text.trim().toLowerCase();
      final matchesSearch = pharmacy.name.toLowerCase().contains(query) ||
          (pharmacy.address?.toLowerCase().contains(query) ?? false);

      if (!matchesSearch) return false;

      if (_selectedFilter == 'کراوەکان') {
        return pharmacy.isOpen;
      } else if (_selectedFilter == 'بەرزترین هەڵسەنگاندن') {
        return pharmacy.rating >= 4.8;
      } else if (_selectedFilter == 'کەمترین کرێ') {
        return pharmacy.deliveryFee <= 2500;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'دەرمانخانەکان',
          style: _kStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modern Promo Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'گەیاندنی خێرا 🛵',
                                  style: _kStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'دەرمانخانەکانی هەموو کوردستان',
                                style: _kStyle(
                                  color: Colors.white,
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'دەرمان و پێداویستییە پزیشکییەکان ڕاستەوخۆ بگەیەنە بەردەم ماڵەکەت',
                                style: _kStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_pharmacy_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.05, end: 0),

                  const SizedBox(height: 20),

                  // Search Bar
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Iconsax.search_normal_1, color: Color(0xFF3B82F6), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() {}),
                            style: _kStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 13.5,
                            ),
                            decoration: InputDecoration(
                              hintText: 'گەڕان بەدوای ناوی دەرمانخانە، گەڕەک یان دەرمان...',
                              hintStyle: _kStyle(color: const Color(0xFF94A3B8), fontSize: 13),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () => setState(() => _searchController.clear()),
                            child: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 18),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: ['هەمووی', 'کراوەکان', 'بەرزترین هەڵسەنگاندن', 'کەمترین کرێ'].map((filter) {
                        final isSel = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: ChoiceChip(
                            label: Text(
                              filter,
                              style: _kStyle(
                                color: isSel ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            selected: isSel,
                            selectedColor: const Color(0xFF3B82F6),
                            backgroundColor: cardBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: isSel ? const Color(0xFF3B82F6) : borderColor),
                            ),
                            onSelected: (val) => setState(() => _selectedFilter = filter),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 22),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'دەرمانخانە چالاکەکان (${filteredList.length})',
                        style: _kStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, color: Color(0xFF3B82F6), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'نزیکترینت',
                              style: _kStyle(
                                fontSize: 11.5,
                                color: const Color(0xFF3B82F6),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (filteredList.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(Icons.local_pharmacy_outlined, size: 50, color: Colors.grey.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            Text('هیچ دەرمانخانەیەک نەدۆزرایەوە', style: _kStyle(color: const Color(0xFF94A3B8))),
                          ],
                        ),
                      ),
                    )
                  else
                    ...List.generate(filteredList.length, (index) {
                      final pharmacy = filteredList[index];

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
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Pharmacy Image / Icon with online ring
                                    Stack(
                                      children: [
                                        Container(
                                          width: 70,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(18),
                                            image: pharmacy.profileImage != null
                                                ? DecorationImage(
                                                    image: NetworkImage(pharmacy.profileImage!),
                                                    fit: BoxFit.cover,
                                                  )
                                                : null,
                                          ),
                                          child: pharmacy.profileImage == null
                                              ? const Icon(Icons.local_pharmacy, color: Color(0xFF3B82F6), size: 34)
                                              : null,
                                        ),
                                        PositionedDirectional(
                                          top: 4,
                                          end: 4,
                                          child: Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: pharmacy.isOpen ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 2),
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
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  pharmacy.name,
                                                  style: _kStyle(
                                                    fontSize: 15.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFEF3C7),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 14),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      '${pharmacy.rating}',
                                                      style: _kStyle(
                                                        color: const Color(0xFFD97706),
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            pharmacy.address ?? 'کوردستان',
                                            style: _kStyle(
                                              fontSize: 12,
                                              color: const Color(0xFF94A3B8),
                                              height: 1.3,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: pharmacy.isOpen
                                                      ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                                      : const Color(0xFFEF4444).withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  pharmacy.isOpen ? 'کراوەیە 🟢' : 'داخراوە 🔴',
                                                  style: _kStyle(
                                                    color: pharmacy.isOpen ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'گەیاندن: ${pharmacy.deliveryFee.toInt()} د.ع',
                                                style: _kStyle(
                                                  fontSize: 11.5,
                                                  color: const Color(0xFF64748B),
                                                  fontWeight: FontWeight.w600,
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

                              // Bottom Action Row inside Card
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
                                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
                                  border: Border(top: BorderSide(color: borderColor)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () => _makeCall(pharmacy.phone),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF10B981), size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              'پەیوەندی',
                                              style: _kStyle(
                                                color: const Color(0xFF10B981),
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          'بینینی دەرمان و کڕین',
                                          style: _kStyle(
                                            color: const Color(0xFF3B82F6),
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Iconsax.arrow_left_2, color: Color(0xFF3B82F6), size: 14),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: (index * 60).ms).slideY(begin: 0.04, end: 0);
                    }),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}
