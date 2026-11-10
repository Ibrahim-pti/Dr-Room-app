import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/cart_provider.dart';
import '../../core/utils/api_client.dart';
import '../../core/utils/localization_extensions.dart';
import '../lab/lab_details_screen.dart' show ProfileCardWavePainter;
import '../pharmacy/screens/cart_screen.dart';
import 'nurse_reviews_screen.dart';

class NurseDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> nurse;

  const NurseDetailsScreen({super.key, required this.nurse});

  @override
  State<NurseDetailsScreen> createState() => _NurseDetailsScreenState();
}

class _NurseDetailsScreenState extends State<NurseDetailsScreen> {
  bool _isFavorite = false;
  int _selectedTabIndex = 0; // 0: ناساندن, 1: خزمەتگوزاری و پسپۆڕی
  final Set<int> _selectedServiceIndices = {};
  Map<String, dynamic> _nurseData = {};
  double _rating = 0.0;
  int _totalReviews = 0;
  List<dynamic> _reviews = [];

  @override
  void initState() {
    super.initState();
    _nurseData = Map<String, dynamic>.from(widget.nurse);
    _rating = double.tryParse(_nurseData['rating']?.toString() ?? '') ?? 0.0;
    _totalReviews =
        int.tryParse(_nurseData['total_reviews']?.toString() ?? '') ?? 0;
    _fetchReviews();
    _fetchNurseDetails();
  }

  Future<void> _fetchNurseDetails() async {
    final nurseId = _nurseData['id'] ?? widget.nurse['id'];
    if (nurseId == null) return;
    try {
      final res = await ApiClient.get('/nurses/$nurseId');
      if (res.statusCode == 200 && mounted) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['nurse'] is Map) {
          setState(() {
            _nurseData = Map<String, dynamic>.from(decoded['nurse']);
            _rating =
                double.tryParse(_nurseData['rating']?.toString() ?? '') ??
                    _rating;
            _totalReviews =
                int.tryParse(_nurseData['total_reviews']?.toString() ?? '') ??
                    _totalReviews;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching nurse details: $e');
    }
  }

  Future<void> _fetchReviews() async {
    final nurseId = _nurseData['id'] ?? widget.nurse['id'];
    if (nurseId == null) return;
    try {
      final res = await ApiClient.get('/nurses/$nurseId/reviews');
      if (res.statusCode == 200 && mounted) {
        final decoded = jsonDecode(res.body);
        setState(() {
          _rating =
              double.tryParse(decoded['rating']?.toString() ?? '') ?? _rating;
          _totalReviews =
              int.tryParse(decoded['total_reviews']?.toString() ?? '') ??
                  _totalReviews;
          _reviews = decoded['reviews'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching nurse reviews: $e');
    }
  }

  TextStyle _kStyle({
    Color? color,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    double? height,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: 'Rabar',
      color: color ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
    );
  }

  String _tr(String key, BuildContext context) {
    final lang = context.locale.languageCode;
    final isBadini = lang == 'kmr';
    final isKurdish = lang == 'ckb' || isBadini;
    final isArabic = lang == 'ar';

    switch (key) {
      case 'nurse_details':
        if (isBadini) return 'هویرکاریێن پەرستاری';
        if (isKurdish) return 'وردەکاری پەرستار';
        if (isArabic) return 'تفاصيل الممرض';
        return 'Nurse Details';
      case 'available':
        if (isBadini) return 'بەردەستە';
        if (isKurdish) return 'ئامادەیە';
        if (isArabic) return 'متاح الآن';
        return 'Available';
      case 'unavailable':
        if (isBadini) return 'بەردەست نینە';
        if (isKurdish) return 'بەردەست نییە';
        if (isArabic) return 'غير متاح';
        return 'Unavailable';
      case 'reviews':
        if (isBadini) return 'هەلسەنگاندن';
        if (isKurdish) return 'هەڵسەنگاندن';
        if (isArabic) return 'تقييم';
        return 'Reviews';
      case 'rating':
        if (isBadini) return 'هەلسەنگاندن';
        if (isKurdish) return 'هەڵسەنگاندن';
        if (isArabic) return 'التقييم';
        return 'Rating';
      case 'services_short':
        if (isBadini) return 'خزمەتگوزاری';
        if (isKurdish) return 'خزمەتگوزاری';
        if (isArabic) return 'خدمة متاحة';
        return 'Services';
      case 'high_quality':
        if (isBadini) return 'کوالیتییا بلند';
        if (isKurdish) return 'کوالیتی بەرز';
        if (isArabic) return 'جودة عالية';
        return 'High Quality';
      case 'fast_in_time':
        if (isBadini) return 'چاڤدێرییا بلەز';
        if (isKurdish) return 'چاودێری خێرا';
        if (isArabic) return 'رعاية منزلية';
        return 'Home Care';
      case 'experience_years':
        if (isBadini) return 'ئەزموون';
        if (isKurdish) return 'ساڵ ئەزموون';
        if (isArabic) return 'سنوات خبرة';
        return 'Years Exp.';
      case 'tab_about':
        if (isBadini) return 'ناساندن';
        if (isKurdish) return 'ناساندن';
        if (isArabic) return 'التعريف';
        return 'About';
      case 'tab_services':
        if (isBadini) return 'خزمەتگوزاری و تایبەتمەندی';
        if (isKurdish) return 'خزمەتگوزاری و پسپۆڕی';
        if (isArabic) return 'الخدمات والتخصصات';
        return 'Services';
      case 'about_nurse':
        if (isBadini) return 'دەربارەی پەرستاری';
        if (isKurdish) return 'دەربارەی پەرستار';
        if (isArabic) return 'نبذة عن الممرض';
        return 'About Nurse';
      case 'phone_number':
        if (isBadini) return 'ژمارا تەلەفۆنێ';
        if (isKurdish) return 'ژمارەی پەیوەندی';
        if (isArabic) return 'رقم الهاتف';
        return 'Phone Number';
      case 'call':
        if (isBadini) return 'پەیوەندی';
        if (isKurdish) return 'پەیوەندی';
        if (isArabic) return 'اتصال';
        return 'Call';
      case 'visit_fee':
        if (isBadini) return 'بهایێ سەرەدانێ';
        if (isKurdish) return 'نرخی خزمەتگوزاری';
        if (isArabic) return 'سعر الخدمة';
        return 'Service Fee';
      case 'book_service':
        if (isBadini) return 'داواکرنا خزمەتگوزاریێ';
        if (isKurdish) return 'داواکردنی خزمەتگوزاری';
        if (isArabic) return 'طلب الخدمة';
        return 'Request Service';
      case 'order_now':
        if (isBadini) return 'داواکرن';
        if (isKurdish) return 'داواکردن';
        if (isArabic) return 'اطلب الآن';
        return 'Request';
      case 'select_prompt':
        if (isBadini) return 'بهەلبژێرە';
        if (isKurdish) return 'هەڵبژێرە';
        if (isArabic) return 'اختر خدمة';
        return 'Select';
      case 'clear_selection':
        if (isBadini) return 'لابردن';
        if (isKurdish) return 'لابردن';
        if (isArabic) return 'إزالة';
        return 'Clear';
      case 'home_care_service':
        if (isBadini) return 'خزمەتگوزارییا پەرستاری ل مال';
        if (isKurdish) return 'خزمەتگوزاری پەرستاری ماڵەوە';
        if (isArabic) return 'خدمة تمريض منزلي';
        return 'Home Nursing Service';
      case 'total':
        if (isBadini) return 'کۆیا گشتی';
        if (isKurdish) return 'کۆی گشتی';
        if (isArabic) return 'الإجمالي';
        return 'Total';
      case 'currency':
        if (isArabic) return 'د.ع';
        if (isKurdish) return 'د.ع';
        return 'IQD';
      default:
        return key.tr();
    }
  }

  String _cityKurdish(String city) {
    switch (city.toLowerCase()) {
      case 'erbil':
        return 'هەولێر';
      case 'sulaymaniyah':
        return 'سلێمانی';
      case 'duhok':
        return 'دهۆک';
      case 'kirkuk':
        return 'کەرکووک';
      case 'halabja':
        return 'هەڵەبجە';
      case 'zakho':
        return 'زاخۆ';
      case 'soran':
        return 'سۆران';
      case 'koya':
        return 'کۆیە';
      case 'ranya':
        return 'ڕانیە';
      default:
        return city;
    }
  }

  void _makePhoneCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri url = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url);
      }
    } catch (e) {
      debugPrint('Error making call: $e');
    }
  }

  void _checkoutSelectedServices(
    List<Map<String, dynamic>> serviceOptions,
    Map<String, dynamic> nurse,
  ) {
    if (_selectedServiceIndices.isEmpty) return;

    final cart = context.read<CartProvider>();
    cart.setServiceType('nursing', extraFee: 0.0);

    final nurseName = nurse['user'] != null
        ? (nurse['user']['name'] ?? 'پەرستاری ماڵەوە')
        : (nurse['name'] ?? 'پەرستاری ماڵەوە');
    final nurseId = nurse['id'];

    final sortedIndices = _selectedServiceIndices.toList()..sort();
    for (final idx in sortedIndices) {
      if (idx < 0 || idx >= serviceOptions.length) continue;
      final item = serviceOptions[idx];
      final sName = item['name']?.toString() ?? 'چاودێری گشتی';
      final sPrice = (item['price'] as num?)?.toDouble() ?? 25000.0;
      cart.addItem(
        CartItem(
          id: item['id']?.toString() ?? 'nurse_${nurseId ?? 1}_srv_$idx',
          name: '$nurseName ($sName)',
          price: sPrice,
          extraData: nurseId != null
              ? {'nurse_id': nurseId, 'service_name': sName}
              : {'service_name': sName},
        ),
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CartScreen(),
      ),
    );
  }

  void _openReviews(int nurseId, String nurseName, double rating) {
    if (nurseId <= 0) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NurseReviewsScreen(
          nurseId: nurseId,
          nurseName: nurseName,
          rating: rating.toStringAsFixed(1),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nurse = _nurseData.isNotEmpty ? _nurseData : widget.nurse;

    final userObj = nurse['user'] is Map ? nurse['user'] as Map : nurse;
    final String name =
        context.localizedField(userObj, 'name', fallback: 'پەرستار'.tr());
    final String specialty = context.localizedField(
      nurse,
      'specialty',
      fallback: 'nursing_verified_nurse'.tr(),
    );
    final String bio = context.localizedField(nurse, 'bio', fallback: '');

    final image = nurse['image'];
    final String phone = nurse['phone']?.toString() ?? '';
    final bool isAvailable = nurse['is_available'] == true;
    final experienceYears = nurse['experience_years'];
    final fee = nurse['fee'];
    final double rawRating = _rating > 0
        ? _rating
        : (double.tryParse(nurse['rating']?.toString() ?? '') ?? 0.0);
    final double displayRating = rawRating > 0 ? rawRating : 5.0;
    final int reviewsCount = _reviews.isNotEmpty
        ? _reviews.length
        : (_totalReviews > 0
            ? _totalReviews
            : (int.tryParse(nurse['total_reviews']?.toString() ?? '') ?? 0));
    final int nurseId = int.tryParse(nurse['id']?.toString() ?? '0') ?? 0;
    final String rawCity =
        context.localizedField(nurse, 'city', fallback: 'Erbil');
    final String city = _cityKurdish(rawCity);
    final List<dynamic> customServices =
        nurse['custom_services'] as List<dynamic>? ?? [];

    // Collect all specialty chips
    final List<String> allSpecialties = [];
    final String specialtyStr = specialty.trim();
    if (specialtyStr.isNotEmpty) {
      final parts = specialtyStr
          .split(RegExp(r'[،,]'))
          .map((e) => e.trim())
          .where((String e) => e.isNotEmpty);
      allSpecialties.addAll(parts);
    }
    for (var cs in customServices) {
      if (cs is Map) {
        final csName = context.localizedField(cs, 'name');
        if (csName.isNotEmpty && !allSpecialties.contains(csName)) {
          allSpecialties.add(csName);
        }
      }
    }

    final validServices = customServices.where((cs) {
      if (cs is Map) {
        final n = cs['name']?.toString() ?? '';
        return n.trim().isNotEmpty;
      }
      return false;
    }).toList();

    final double defaultFee = fee != null
        ? (double.tryParse(fee.toString()) ?? 25000.0)
        : 25000.0;

    final List<Map<String, dynamic>> serviceOptions = validServices.isNotEmpty
        ? validServices.asMap().entries.map((entry) {
            final idx = entry.key;
            final cs = entry.value as Map;
            final sName = context.localizedField(
              cs,
              'name',
              fallback: cs['name']?.toString() ?? '',
            );
            final sPrice = cs['price'] != null
                ? (double.tryParse(cs['price'].toString()) ?? defaultFee)
                : defaultFee;
            return {
              'id': 'nurse_${nurseId > 0 ? nurseId : 1}_srv_$idx',
              'name': sName.toString(),
              'subtitle': specialty.trim().isNotEmpty
                  ? specialty.trim()
                  : _tr('home_care_service', context),
              'price': sPrice,
            };
          }).toList()
        : [
            {
              'id': 'nurse_${nurseId > 0 ? nurseId : 1}',
              'name': specialty.trim().isNotEmpty
                  ? specialty.trim()
                  : 'چاودێری گشتی',
              'subtitle': _tr('home_care_service', context),
              'price': defaultFee,
            },
          ];

    final int servicesTabCount = serviceOptions.length;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              4,
              16,
              _selectedServiceIndices.isNotEmpty
                  ? MediaQuery.of(context).padding.bottom + 96
                  : MediaQuery.of(context).padding.bottom + 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1 & 2. Integrated Hero Banner & Waved Master Profile Card ──
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _buildHeroBanner(
                      image: image,
                      isAvailable: isAvailable,
                      isDark: isDark,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 210),
                      child: _buildMasterProfileCard(
                        name: name,
                        city: city,
                        specialty: specialty,
                        profileImage: image?.toString() ?? '',
                        rating: displayRating.toStringAsFixed(1),
                        reviewsCount: reviewsCount,
                        servicesCount: servicesTabCount,
                        experienceYears: experienceYears,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── 3. Segmented Tab Bar (ناساندن / خزمەتگوزاری و پسپۆڕی) ──
                _buildTabsHeader(servicesTabCount),
                const SizedBox(height: 14),

                // ── 4. Dynamic Tab Content ──
                if (_selectedTabIndex == 0) ...[
                  if (bio.isNotEmpty) ...[
                    _buildAboutSection(bio),
                    const SizedBox(height: 14),
                  ],
                  if (phone.isNotEmpty) ...[
                    _buildContactSection(phone),
                    const SizedBox(height: 14),
                  ],
                  _buildReviewsSection(
                    nurseId: nurseId,
                    name: name,
                    ratingVal: displayRating,
                    reviewsCount: reviewsCount,
                  ),
                ] else ...[
                  _buildSpecialtiesSection(allSpecialties),
                  const SizedBox(height: 14),
                  _buildServicesAndPricingSection(serviceOptions),
                ],
              ],
            ),
          ),

          // ── 5. Sticky Bottom Booking Bar (Only shown when at least 1 service is selected) ──
          if (_selectedServiceIndices.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 12,
              child: _buildBottomBookingBar(
                serviceOptions: serviceOptions,
                nurse: nurse,
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
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
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
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
        _tr('nurse_details', context),
        style: _kStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 16),
          child: GestureDetector(
            onTap: () {
              setState(() => _isFavorite = !_isFavorite);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _isFavorite ? Icons.favorite_rounded : Iconsax.heart,
                color: _isFavorite
                    ? const Color(0xFFEF4444)
                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
                size: 19,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBanner({
    required dynamic image,
    required bool isAvailable,
    required bool isDark,
  }) {
    final String imgUrl =
        image != null ? ApiClient.getImageUrl(image.toString()) : '';

    return Container(
      height: 260,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Nurse Banner Photo or Branded Medical Backdrop
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: imgUrl.isNotEmpty && imgUrl.startsWith('http')
                ? Image.network(
                    imgUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _buildHeroFallbackBackdrop(isDark),
                  )
                : _buildHeroFallbackBackdrop(isDark),
          ),

          // 2. Top Subtle Dark Vignette
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 70,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.16),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Bottom Blue Glow Overlay (Matches LabDetailsScreen)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 110,
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF2563EB).withValues(alpha: 0.28),
                        const Color(0xFF1D4ED8).withValues(alpha: 0.60),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 4. Availability Badge (Top Start - Matching Lab Badge Position)
          PositionedDirectional(
            top: 12,
            start: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isAvailable
                      ? const [Color(0xFF10B981), Color(0xFF059669)]
                      : const [Color(0xFF64748B), Color(0xFF475569)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: (isAvailable
                            ? const Color(0xFF10B981)
                            : const Color(0xFF64748B))
                        .withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isAvailable
                        ? Icons.check_circle_rounded
                        : Icons.schedule_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isAvailable
                        ? _tr('available', context)
                        : _tr('unavailable', context),
                    style: _kStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scaleXY(begin: 0.98);
  }

  Widget _buildHeroFallbackBackdrop(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF1E3A8A), Color(0xFF1E293B), Color(0xFF0F172A)]
              : const [Color(0xFFDBEAFE), Color(0xFFEFF6FF), Color(0xFFBFDBFE)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -36,
            right: -36,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.12 : 0.10),
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: -24,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.12 : 0.08),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 34),
              child: Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.14),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Iconsax.health,
                  color: Color(0xFF2563EB),
                  size: 36,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterProfileCard({
    required String name,
    required String city,
    required String specialty,
    required String profileImage,
    required String rating,
    required int reviewsCount,
    required int servicesCount,
    required dynamic experienceYears,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedImg = ApiClient.getImageUrl(profileImage);

    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final bool hasExp =
        (int.tryParse(experienceYears?.toString().trim() ?? '') ?? 0) > 0;

    return CustomPaint(
      painter: ProfileCardWavePainter(
        cardColor: cardColor,
        borderColor: borderColor,
        isDark: isDark,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── 1. Centered Nurse Avatar with Verified Badge (Cradled in wave dip) ──
            const SizedBox(height: 12),
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFEFF6FF),
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                        width: 1.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF3B82F6).withValues(alpha: 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: resolvedImg.isNotEmpty &&
                              resolvedImg.startsWith('http')
                          ? Image.network(
                              resolvedImg,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(
                                Iconsax.user_octagon,
                                color: Color(0xFF3B82F6),
                                size: 32,
                              ),
                            )
                          : const Icon(
                              Iconsax.user_octagon,
                              color: Color(0xFF3B82F6),
                              size: 32,
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF3B82F6),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── 2. Centered Nurse Name ──
            Text(
              name,
              textAlign: TextAlign.center,
              style: _kStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 5),

            // ── Subtitle: City & Primary Specialty ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Iconsax.location,
                  color: Color(0xFF3B82F6),
                  size: 13.5,
                ),
                const SizedBox(width: 4),
                Text(
                  city,
                  style: _kStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (specialty.trim().isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF94A3B8).withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      specialty,
                      style: _kStyle(
                        fontSize: 12,
                        color: const Color(0xFF2563EB),
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 14),

            // ── 3. Quick Stats Integrated Inside (Matches LabDetailsScreen) ──
            Row(
              children: [
                // Rating Stat Card
                Expanded(
                  child: GestureDetector(
                    onTap: _showReviewBottomSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 9,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                            : const Color(0xFFFEF3C7).withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFF59E0B),
                                size: 16,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                rating,
                                style: _kStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2.5),
                          Text(
                            reviewsCount > 0
                                ? '$reviewsCount ${_tr('reviews', context)}'
                                : _tr('rating', context),
                            style: _kStyle(
                              fontSize: 10.5,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Services Count Stat Card
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTabIndex = 1;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 9,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                            : const Color(0xFFEFF6FF).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Iconsax.health,
                                color: Color(0xFF3B82F6),
                                size: 15,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$servicesCount',
                                style: _kStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2.5),
                          Text(
                            _tr('services_short', context),
                            style: _kStyle(
                              fontSize: 10.5,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Experience / High Quality Stat Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 9,
                      horizontal: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                          : const Color(0xFFECFDF5).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.25),
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Iconsax.shield_tick,
                              color: Color(0xFF10B981),
                              size: 15,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                hasExp
                                    ? '$experienceYears+'
                                    : _tr('high_quality', context),
                                style: _kStyle(
                                  fontSize: hasExp ? 13.5 : 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2.5),
                        Text(
                          hasExp
                              ? _tr('experience_years', context)
                              : _tr('fast_in_time', context),
                          style: _kStyle(
                            fontSize: 10.5,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05);
  }

  Widget _buildTabsHeader(int servicesTabCount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabs = [
      {'id': 0, 'title': _tr('tab_about', context), 'icon': Iconsax.info_circle},
      {
        'id': 1,
        'title': '${_tr('tab_services', context)} ($servicesTabCount)',
        'icon': Iconsax.health,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(4.5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: tabs.map((t) {
          final int id = t['id'] as int;
          final bool isSelected = _selectedTabIndex == id;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 9.5),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color:
                                const Color(0xFF2563EB).withValues(alpha: 0.30),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      t['icon'] as IconData,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B)),
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        t['title'] as String,
                        style: _kStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B)),
                          fontSize: 11.5,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAboutSection(String bio) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Iconsax.info_circle,
                color: Color(0xFF3B82F6),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                _tr('about_nurse', context),
                style: _kStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            bio,
            style: _kStyle(
              fontSize: 13.5,
              color:
                  isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(String phone) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2563EB).withValues(alpha: 0.18)
                  : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Iconsax.call,
              color: Color(0xFF3B82F6),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tr('phone_number', context),
                  style: _kStyle(
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  phone,
                  style: _kStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _makePhoneCall(phone),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                _tr('call', context),
                style: _kStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection({
    required int nurseId,
    required String name,
    required double ratingVal,
    required int reviewsCount,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFD97706),
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'هەڵسەنگاندن و فیدباک ($reviewsCount)',
                    style: _kStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _showReviewBottomSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.add_comment_rounded,
                        color: Color(0xFFB45309),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'سەرنج بنووسە',
                        style: _kStyle(
                          color: const Color(0xFFB45309),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Rating summary badge (Matches LabDetailsScreen)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Text(
                    ratingVal.toStringAsFixed(1),
                    style: _kStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      5,
                      (i) => Icon(
                        Icons.star_rounded,
                        color: i < ratingVal.round()
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFFCBD5E1),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'لە کۆی $reviewsCount فیدباک',
                    style: _kStyle(
                      fontSize: 11.5,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Reviews List
          if (_reviews.isNotEmpty) ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _reviews.take(5).length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final rev = _reviews[index];
                final String patientName =
                    rev['patient_name']?.toString() ?? 'نەخۆش';
                final int stars = (rev['rating'] as num?)?.toInt() ?? 5;
                final String? comment = rev['comment']?.toString();
                final String date = rev['formatted_date']?.toString() ?? '';

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFF1F5F9),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: isDark
                                    ? const Color(0xFF1E3A8A)
                                    : const Color(0xFFE0F2FE),
                                child: Text(
                                  patientName.isNotEmpty ? patientName[0] : 'ن',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? const Color(0xFF93C5FD)
                                        : const Color(0xFF0284C7),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    patientName,
                                    style: _kStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  if (date.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      date,
                                      style: _kStyle(
                                        fontSize: 10,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFFF59E0B)
                                        .withValues(alpha: 0.35)
                                    : const Color(0xFFFDE68A),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '$stars.0',
                                  style: _kStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFB45309),
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFF59E0B),
                                  size: 13,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (comment != null && comment.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          comment,
                          style: _kStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF475569),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            if (_reviews.length > 3) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _openReviews(nurseId, name, ratingVal),
                child: Center(
                  child: Text(
                    'بینینی هەموو هەڵسەنگاندنەکان ←',
                    style: _kStyle(
                      fontSize: 12.5,
                      color: const Color(0xFF2563EB),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.forum_rounded,
                    color: Color(0xFF94A3B8),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'هێشتا هیچ فیدباکێک نییە',
                    style: _kStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'یەکەم کەس بە کە ڕا و بۆچوونی خۆت دەنووسیت',
                    style: _kStyle(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showReviewBottomSheet() {
    int selectedStars = 5;
    final commentController = TextEditingController();
    bool isSubmitting = false;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom +
                  MediaQuery.of(context).padding.bottom +
                  24,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'هەڵسەنگاندنی پەرستار',
                  style: _kStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'تکایە ئەستێرە دیاری بکە و ڕا و بۆچوونی خۆت بنووسە دەربارەی خزمەتگوزارییەکان:',
                  style: _kStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),

                // Star Selector
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            selectedStars = starIndex;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.star_rounded,
                            size: 38,
                            color: starIndex <= selectedStars
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 16),

                // Comment Input
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  style: _kStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'سەرنج و بۆچوونی خۆت لێرە بنووسە (ئارەزوومەندانە)...',
                    hintStyle: _kStyle(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF3B82F6),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final nurseId =
                                _nurseData['id'] ?? widget.nurse['id'];
                            if (nurseId == null) return;

                            setModalState(() => isSubmitting = true);

                            try {
                              final res = await ApiClient.post(
                                '/nurses/$nurseId/reviews',
                                body: {
                                  'rating': selectedStars,
                                  'comment': commentController.text.trim(),
                                },
                              );

                              if (res.statusCode == 200 ||
                                  res.statusCode == 201) {
                                nav.pop();
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'هەڵسەنگاندنەکەت بە سەرکەوتوویی نێردرا، سوپاس!',
                                    ),
                                    backgroundColor: Color(0xFF059669),
                                  ),
                                );
                                _fetchReviews();
                              } else {
                                final decoded = jsonDecode(res.body);
                                final msg =
                                    decoded['message'] ?? 'نەتوانرا بنێردرێت';
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(msg.toString()),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } catch (e) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('هەڵەیەک ڕوویدا'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } finally {
                              if (context.mounted) {
                                setModalState(() => isSubmitting = false);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'ناردنی هەڵسەنگاندن',
                            style: _kStyle(
                              fontSize: 15,
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
      ),
    );
  }

  // ─── Tab 2: پسپۆڕییەکان (Specialties) ───
  Widget _buildSpecialtiesSection(List<String> allSpecialties) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (allSpecialties.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          children: [
            const Icon(Iconsax.health, color: Color(0xFF94A3B8), size: 40),
            const SizedBox(height: 12),
            Text(
              'هیچ پسپۆڕییەک زیادنەکراوە',
              style: _kStyle(color: const Color(0xFF94A3B8), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.health, color: Color(0xFF3B82F6), size: 18),
              const SizedBox(width: 8),
              Text(
                'پسپۆڕی و بوارەکان (${allSpecialties.length})',
                style: _kStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...allSpecialties.asMap().entries.map((entry) {
            final idx = entry.key;
            final s = entry.value;
            final colors = [
              const Color(0xFF3B82F6),
              const Color(0xFF2563EB),
              const Color(0xFF0EA5E9),
              const Color(0xFF10B981),
              const Color(0xFF8B5CF6),
              const Color(0xFFF59E0B),
            ];
            final color = colors[idx % colors.length];

            return Container(
              width: double.infinity,
              margin: EdgeInsets.only(
                bottom: idx < allSpecialties.length - 1 ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Iconsax.health, color: color, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s,
                      style: _kStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: (idx * 60).ms).slideX(begin: -0.05);
          }),
        ],
      ),
    );
  }

  // ─── Tab 2: خزمەتگوزارییەکان و نرخ (Services & Pricing - Selectable like Lab Tests) ───
  Widget _buildServicesAndPricingSection(
    List<Map<String, dynamic>> serviceOptions,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Iconsax.activity,
                    color: Color(0xFF3B82F6),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'خزمەتگوزارییەکان و نرخ (${serviceOptions.length})',
                    style: _kStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              if (_selectedServiceIndices.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() => _selectedServiceIndices.clear()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFFEF4444).withValues(alpha: 0.16)
                          : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.close_rounded,
                          color: Color(0xFFDC2626),
                          size: 13,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _tr('clear_selection', context),
                          style: _kStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Text(
                  _tr('select_prompt', context),
                  style: _kStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: serviceOptions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final item = serviceOptions[idx];
              final bool isSelected = _selectedServiceIndices.contains(idx);
              final String sName = item['name']?.toString() ?? '';
              final String sSub = item['subtitle']?.toString() ?? '';
              final int sPrice = (item['price'] as num?)?.toInt() ?? 25000;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedServiceIndices.remove(idx);
                    } else {
                      _selectedServiceIndices.add(idx);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                            ? const Color(0xFF1E3A8A).withValues(alpha: 0.28)
                            : const Color(0xFFEFF6FF))
                        : (isDark
                            ? const Color(0xFF0F172A)
                            : Colors.white),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF3B82F6)
                          : (isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0)),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? const Color(0xFF3B82F6).withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Checkbox indicator (matches LabDetailsScreen)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF3B82F6)
                              : (isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF3B82F6)
                                : (isDark
                                    ? const Color(0xFF475569)
                                    : const Color(0xFFCBD5E1)),
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),

                      // Service title & subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sName,
                              style: _kStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            if (sSub.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                sSub,
                                style: _kStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Price badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF3B82F6)
                              : (isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${NumberFormat('#,###').format(sPrice)} ${_tr('currency', context)}',
                          style: _kStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? Colors.white
                                    : const Color(0xFF1E293B)),
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBookingBar({
    required List<Map<String, dynamic>> serviceOptions,
    required Map<String, dynamic> nurse,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double selectedTotal = 0.0;
    for (final idx in _selectedServiceIndices) {
      if (idx >= 0 && idx < serviceOptions.length) {
        selectedTotal += (serviceOptions[idx]['price'] as num?)?.toDouble() ?? 0.0;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => setState(() => _selectedServiceIndices.clear()),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFFEF4444).withValues(alpha: 0.16)
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFFDC2626),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_tr('total', context)} (${_selectedServiceIndices.length})',
                    style: _kStyle(
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        NumberFormat('#,###').format(selectedTotal.toInt()),
                        style: _kStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _tr('currency', context),
                        style: _kStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () =>
                _checkoutSelectedServices(serviceOptions, nurse),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Iconsax.calendar_tick,
                  color: Colors.white,
                  size: 17,
                ),
                const SizedBox(width: 6),
                Text(
                  _tr('book_service', context),
                  style: _kStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
