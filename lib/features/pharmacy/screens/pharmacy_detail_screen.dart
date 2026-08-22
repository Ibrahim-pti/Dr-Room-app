import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/pharmacy_model.dart';
import '../models/medication_model.dart';
import '../data/pharmacy_repository.dart';
import '../providers/cart_provider.dart';
import 'cart_screen.dart';

class PharmacyDetailScreen extends ConsumerStatefulWidget {
  final Pharmacy pharmacy;

  const PharmacyDetailScreen({super.key, required this.pharmacy});

  @override
  ConsumerState<PharmacyDetailScreen> createState() =>
      _PharmacyDetailScreenState();
}

class _PharmacyDetailScreenState extends ConsumerState<PharmacyDetailScreen> {
  final PharmacyRepository _repository = PharmacyRepository();
  final TextEditingController _searchMedController = TextEditingController();
  final PageController _carouselController = PageController();
  int _currentCarouselIndex = 0;
  Timer? _carouselTimer;

  List<Medication> _medications = [];
  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, String>> _categories = [
    {'name': 'هەمووی', 'icon': '💊'},
    {'name': 'ئازارشکێن', 'icon': '⚡'},
    {'name': 'دژەهەوکردن', 'icon': '🛡️'},
    {'name': 'ڤیتامین', 'icon': '🍊'},
    {'name': 'گەدە و هەرس', 'icon': '🫀'},
    {'name': 'منداڵان', 'icon': '👶'},
  ];
  List<String> _pharmacyGallery = [];
  bool _isLoading = true;
  String _selectedCategory = 'هەمووی';

  String _getCategoryDisplayName(Map<String, String> cat, BuildContext context) {
    final lang = context.locale.languageCode;
    if (lang == 'ar' && cat['name_ar'] != null && cat['name_ar']!.isNotEmpty) {
      return cat['name_ar']!;
    }
    if (lang == 'en' && cat['name_en'] != null && cat['name_en']!.isNotEmpty) {
      return cat['name_en']!;
    }
    return cat['name'] ?? '';
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

  @override
  void initState() {
    super.initState();
    _initGallery();
    _fetchData();
    _startCarouselTimer();
  }

  void _initGallery() {
    if (widget.pharmacy.galleryImages.isNotEmpty) {
      _pharmacyGallery = List<String>.from(widget.pharmacy.galleryImages);
    } else {
      _pharmacyGallery = [
        widget.pharmacy.profileImage ??
            'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=800',
        'https://images.unsplash.com/photo-1576602976047-174e57a47881?w=800',
        'https://images.unsplash.com/photo-1631549916768-4119b2e5f926?w=800',
      ];
    }
  }

  void _startCarouselTimer() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_carouselController.hasClients && _pharmacyGallery.isNotEmpty) {
        int nextIndex = (_currentCarouselIndex + 1) % _pharmacyGallery.length;
        _carouselController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _carouselController.dispose();
    _searchMedController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final results = await Future.wait([
        _repository.getMedications(widget.pharmacy.id),
        _repository.getCategories(),
        _repository.getReviews(widget.pharmacy.id),
      ]);
      final meds = results[0] as List<Medication>;
      final rawReviews = results[2] as List<dynamic>;

      final activeMeds = meds.isNotEmpty ? meds : _fallbackMedications;

      // Extract distinct categories dynamically with translations from medications!
      final Map<String, Map<String, String>> distinctCategories = {};
      for (final m in activeMeds) {
        if (m.category != null && m.category!.trim().isNotEmpty && m.category != 'هەمووی') {
          final catKey = m.category!.trim();
          if (!distinctCategories.containsKey(catKey)) {
            distinctCategories[catKey] = {
              'name': catKey,
              'name_ar': (m.categoryAr != null && m.categoryAr!.isNotEmpty) ? m.categoryAr! : catKey,
              'name_en': (m.categoryEn != null && m.categoryEn!.isNotEmpty) ? m.categoryEn! : catKey,
            };
          }
        }
      }

      List<Map<String, String>> dynamicCats = [
        {'name': 'هەمووی', 'name_ar': 'الكل', 'name_en': 'All'},
        ...distinctCategories.values,
      ];

      if (mounted) {
        setState(() {
          _categories = dynamicCats;
          _medications = activeMeds;
          if (rawReviews.isNotEmpty) {
            _reviews = rawReviews.map((r) => Map<String, dynamic>.from(r as Map)).toList();
          } else {
            _reviews = _fallbackReviews;
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        final activeMeds = _fallbackMedications;
        final Map<String, Map<String, String>> distinctCategories = {};
        for (final m in activeMeds) {
          if (m.category != null && m.category!.trim().isNotEmpty && m.category != 'هەمووی') {
            final catKey = m.category!.trim();
            if (!distinctCategories.containsKey(catKey)) {
              distinctCategories[catKey] = {
                'name': catKey,
                'name_ar': (m.categoryAr != null && m.categoryAr!.isNotEmpty) ? m.categoryAr! : catKey,
                'name_en': (m.categoryEn != null && m.categoryEn!.isNotEmpty) ? m.categoryEn! : catKey,
              };
            }
          }
        }
        List<Map<String, String>> dynamicCats = [
          {'name': 'هەمووی', 'name_ar': 'الكل', 'name_en': 'All'},
          ...distinctCategories.values,
        ];
        setState(() {
          _categories = dynamicCats;
          _medications = activeMeds;
          _reviews = _fallbackReviews;
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _fallbackReviews => [
    {
      'user_name': 'ڕەوەند عەلی',
      'rating': 5.0,
      'comment': 'دەرمانخانەیەکی زۆر بەڕێز و خێران، دەرمانەکانیان ئۆرجیناڵە و گەیاندنەکەی لە کاتی خۆیدا گەیشت.',
      'created_at': 'دوو رۆژ لەمەوبەر',
    },
    {
      'user_name': 'د. بەرهەم کەریم',
      'rating': 5.0,
      'comment': 'پێداویستی و دەرمانە دەگمەنەکانم لە لای ئەوان دەستکەوت، نرخەکانیان زۆر گونجاوە و داشکاندنەکەیان ڕاستەقینەیە.',
      'created_at': 'هەفتەیەک لەمەوبەر',
    },
    {
      'user_name': 'سۆزان ئەحمەد',
      'rating': 4.8,
      'comment': 'گەیاندنی زۆر خێرا، لە ماوەی کەمتر لە نیو کاتژمێردا دەرمانەکانم پێگەیشت. دەستان خۆش بێت.',
      'created_at': 'دوو هەفتە لەمەوبەر',
    },
  ];

  List<Medication> get _fallbackMedications => [
    Medication(
      id: 101,
      name: 'Panadol Extra (500mg)',
      category: 'ئازارشکێن',
      categoryAr: 'مسكنات الألم',
      categoryEn: 'Pain Relief',
      description: 'ئازارشکێن و دابەزێنەری پلەی گەرمی و ئازاری سەر',
      price: 2000,
      originalPrice: 2750,
      discountPercent: 27,
      stock: 45,
      imageUrl:
          'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400',
    ),
    Medication(
      id: 102,
      name: 'Augmentin (1g)',
      category: 'دژەهەوکردن',
      categoryAr: 'مضادات الالتهاب',
      categoryEn: 'Anti-inflammatory',
      description: 'دژە هەوکردن بۆ بەکتریای بەهێز',
      price: 9500,
      originalPrice: 12000,
      discountPercent: 20,
      stock: 30,
      imageUrl:
          'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?w=400',
    ),
    Medication(
      id: 103,
      name: 'Vitamin C 1000mg',
      category: 'ڤیتامین',
      categoryAr: 'فيتامينات',
      categoryEn: 'Vitamins',
      description: 'تەقێنراو - بەهێزکەری بەرگری جەستە و ڤیتامین',
      price: 4500,
      originalPrice: 6000,
      discountPercent: 25,
      stock: 25,
      imageUrl:
          'https://images.unsplash.com/photo-1550572017-ed24c5208f60?w=400',
    ),
    Medication(
      id: 104,
      name: 'Omeprazole 20mg',
      category: 'گەدە و هەرس',
      categoryAr: 'المعدة والجهاز الهضمي',
      categoryEn: 'Stomach & Digestion',
      description: 'چارەسەری ترشەڵۆک و کەمکردنەوەی سوزش',
      price: 3500,
      stock: 0, // Out of stock
      imageUrl:
          'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=400',
    ),
    Medication(
      id: 105,
      name: 'Baby Care Milk',
      category: 'دایک و منداڵ',
      categoryAr: 'الأم والطفل',
      categoryEn: 'Mother & Baby',
      description: 'شیری تەواوکەری خۆراکی منداڵان و کۆرپە',
      price: 14000,
      originalPrice: 16500,
      discountPercent: 15,
      stock: 12,
      imageUrl:
          'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?w=400',
    ),
    Medication(
      id: 106,
      name: 'Ibuprofen 400mg',
      category: 'ئازارشکێن',
      categoryAr: 'مسكنات الألم',
      categoryEn: 'Pain Relief',
      description: 'بۆ ئازاری جومگە، ماسولکە و سەرئێشە',
      price: 3000,
      stock: 0, // Out of stock
      imageUrl:
          'https://images.unsplash.com/photo-1576602976047-174e57a47881?w=400',
    ),
  ];

  Future<void> _makeCall() async {
    final phone = widget.pharmacy.phone ?? '07501234567';
    final Uri uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openFacebook() async {
    final url = widget.pharmacy.facebookUrl ?? 'https://facebook.com';
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openMap() async {
    Uri uri;
    if (widget.pharmacy.latitude != null && widget.pharmacy.longitude != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${widget.pharmacy.latitude},${widget.pharmacy.longitude}',
      );
    } else {
      final address = widget.pharmacy.address ?? 'Erbil Kurdistan';
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
      );
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showMedicationDetailBottomSheet(Medication med) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String selectedUnit = 'پاکەت';
        int quantity = 1;
        final bool isOut = med.isOutOfStock;
        final double boxPrice = med.price;
        final double boxOriginalPrice = med.effectiveOriginalPrice;

        // Piece/strip price calculated accurately (e.g. 1/3 or 1/2 of box price rounded to nearest 250 IQD)
        final double piecePrice = (med.price > 2500)
            ? (((med.price / 3) / 250).round() * 250.0).clamp(500.0, med.price)
            : (((med.price / 2) / 250).round() * 250.0).clamp(500.0, med.price);

        final double pieceOriginalPrice = (boxOriginalPrice > 2500)
            ? (((boxOriginalPrice / 3) / 250).round() * 250.0).clamp(
                500.0,
                boxOriginalPrice,
              )
            : (((boxOriginalPrice / 2) / 250).round() * 250.0).clamp(
                500.0,
                boxOriginalPrice,
              );

        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;
            final borderColor = isDark
                ? const Color(0xFF334155)
                : const Color(0xFFE2E8F0);
            final unitPrice = (selectedUnit == 'پاکەت') ? boxPrice : piecePrice;
            final unitOriginalPrice = (selectedUnit == 'پاکەت')
                ? boxOriginalPrice
                : pieceOriginalPrice;
            final totalPrice = unitPrice * quantity;
            final totalOriginalPrice = unitOriginalPrice * quantity;
            final double totalSavings = (totalOriginalPrice > totalPrice)
                ? (totalOriginalPrice - totalPrice)
                : 0;

            return Container(
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 28,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 44,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white24
                              : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'details_and_quantity'.tr(),
                          style: _kStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),

                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Medication Info Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 80,
                              height: 80,
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                              child: Opacity(
                                opacity: isOut ? 0.5 : 1.0,
                                child: Image.network(
                                  med.imageUrl ??
                                      'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=300',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(
                                      Icons.medication_rounded,
                                      size: 36,
                                      color: Color(0xFF3B82F6),
                                    ),
                                  ),
                                ),
                              ),
                            ),
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
                                        med.name,
                                        style: _kStyle(
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
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isOut
                                            ? const Color(
                                                0xFFEF4444,
                                              ).withValues(alpha: 0.15)
                                            : const Color(
                                                0xFF10B981,
                                              ).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isOut
                                            ? 'نەماوە ❌'
                                            : 'بەردەستە (${med.stock})',
                                        style: _kStyle(
                                          color: isOut
                                              ? const Color(0xFFEF4444)
                                              : const Color(0xFF10B981),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  med.description ??
                                      'دەرمانی باوەڕپێکراو بە کوالیتی بەرز و گەرەنتی کراو',
                                  style: _kStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white60
                                        : const Color(0xFF64748B),
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (isOut) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFEF4444,
                          ).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(
                              0xFFEF4444,
                            ).withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFFEF4444),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'ببورە، ئەم دەرمانە لە ئێستادا لە کۆگای ئەم دەرمانخانەیە نەماوە و ناتوانرێت داوا بکرێت.',
                                style: _kStyle(
                                  color: const Color(0xFFEF4444),
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (med.hasDiscount && !isOut) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFEF4444).withValues(alpha: 0.12),
                              const Color(0xFFF59E0B).withValues(alpha: 0.12),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(
                              0xFFEF4444,
                            ).withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_offer_rounded,
                              color: Color(0xFFEF4444),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'داشکاندنی تایبەت بە ڕێژەی ${med.calculatedDiscountPercent}٪ بۆ ئەم دەرمانە 🎉',
                              style: _kStyle(
                                color: const Color(0xFFDC2626),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),

                    // Unit Selection Label
                    Text(
                      'select_purchase_type'.tr(),
                      style: _kStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Unit Selection Row
                    Row(
                      children: [
                        // Option 1: Box / Packet
                        Expanded(
                          child: GestureDetector(
                            onTap: isOut
                                ? null
                                : () {
                                    setModalState(() {
                                      selectedUnit = 'پاکەت';
                                    });
                                  },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isOut
                                    ? (isDark
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFFF1F5F9))
                                    : (selectedUnit == 'پاکەت'
                                          ? const Color(
                                              0xFF3B82F6,
                                            ).withValues(alpha: 0.12)
                                          : sheetBg),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: selectedUnit == 'پاکەت' && !isOut
                                      ? const Color(0xFF3B82F6)
                                      : borderColor,
                                  width: selectedUnit == 'پاکەت' && !isOut
                                      ? 1.8
                                      : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.inventory_2_outlined,
                                        size: 18,
                                        color: isOut
                                            ? Colors.grey
                                            : const Color(0xFF3B82F6),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'by_box'.tr(),
                                        style: _kStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: isOut
                                              ? Colors.grey
                                              : (selectedUnit == 'پاکەت'
                                                    ? const Color(0xFF3B82F6)
                                                    : (isDark
                                                          ? Colors.white
                                                          : const Color(
                                                              0xFF0F172A,
                                                            ))),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (med.hasDiscount) ...[
                                        Text(
                                          '${boxOriginalPrice.toInt()} ${'currency_iqd'.tr()}',
                                          style:
                                              _kStyle(
                                                fontSize: 10.5,
                                                color: const Color(0xFF94A3B8),
                                              ).copyWith(
                                                decoration:
                                                    TextDecoration.lineThrough,
                                              ),
                                        ),
                                        const SizedBox(width: 5),
                                      ],
                                      Text(
                                        '${boxPrice.toInt()} ${'currency_iqd'.tr()}',
                                        style: _kStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isOut
                                              ? Colors.grey
                                              : (selectedUnit == 'پاکەت'
                                                    ? const Color(0xFF2563EB)
                                                    : const Color(0xFF64748B)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Option 2: Piece / Strip
                        Expanded(
                          child: GestureDetector(
                            onTap: isOut
                                ? null
                                : () {
                                    setModalState(() {
                                      selectedUnit = 'دانە / شریت';
                                    });
                                  },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isOut
                                    ? (isDark
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFFF1F5F9))
                                    : (selectedUnit == 'دانە / شریت'
                                          ? const Color(
                                              0xFF3B82F6,
                                            ).withValues(alpha: 0.12)
                                          : sheetBg),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: selectedUnit == 'دانە / شریت' && !isOut
                                      ? const Color(0xFF3B82F6)
                                      : borderColor,
                                  width: selectedUnit == 'دانە / شریت' && !isOut
                                      ? 1.8
                                      : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.medication_liquid_rounded,
                                        size: 18,
                                        color: isOut
                                            ? Colors.grey
                                            : const Color(0xFF10B981),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'by_piece_strip'.tr(),
                                        style: _kStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: isOut
                                              ? Colors.grey
                                              : (selectedUnit == 'دانە / شریت'
                                                    ? const Color(0xFF3B82F6)
                                                    : (isDark
                                                          ? Colors.white
                                                          : const Color(
                                                              0xFF0F172A,
                                                            ))),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (med.hasDiscount) ...[
                                        Text(
                                          '${pieceOriginalPrice.toInt()} ${'currency_iqd'.tr()}',
                                          style:
                                              _kStyle(
                                                fontSize: 10.5,
                                                color: const Color(0xFF94A3B8),
                                              ).copyWith(
                                                decoration:
                                                    TextDecoration.lineThrough,
                                              ),
                                        ),
                                        const SizedBox(width: 5),
                                      ],
                                      Text(
                                        '${piecePrice.toInt()} ${'currency_iqd'.tr()}',
                                        style: _kStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isOut
                                              ? Colors.grey
                                              : (selectedUnit == 'دانە / شریت'
                                                    ? const Color(0xFF2563EB)
                                                    : const Color(0xFF64748B)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),


                    if (!isOut) ...[
                      const SizedBox(height: 20),

                      // Quantity Counter Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ژمارەی داواکراو:',
                            style: _kStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (quantity > 1) {
                                      setModalState(() => quantity--);
                                    }
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: quantity > 1
                                          ? (isDark
                                                ? const Color(0xFF334155)
                                                : Colors.white)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.remove,
                                      size: 16,
                                      color: quantity > 1
                                          ? (isDark
                                                ? Colors.white
                                                : const Color(0xFF0F172A))
                                          : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    '$quantity $selectedUnit',
                                    style: _kStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    if (quantity < med.stock) {
                                      setModalState(() => quantity++);
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          backgroundColor: const Color(
                                            0xFFE11D48,
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          content: Text(
                                            'تەنها ${med.stock} دانە لە کۆگادا بەردەستە',
                                            style: _kStyle(color: Colors.white),
                                          ),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3B82F6),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Calculation Summary Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'حیساباتی نرخ:',
                                      style: _kStyle(
                                        fontSize: 11.5,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$quantity × ${unitPrice.toInt()} د.ع ($selectedUnit)',
                                      style: _kStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white70
                                            : const Color(0xFF475569),
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'کۆی گشتی:',
                                      style: _kStyle(
                                        fontSize: 11.5,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${totalPrice.toInt()} د.ع',
                                      style: _kStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF2563EB),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (totalSavings > 0) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.savings_outlined,
                                      color: Color(0xFF10B981),
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'پاشەکەوت دەکەیت: ${totalSavings.toInt()} د.ع 🎉',
                                      style: _kStyle(
                                        color: const Color(0xFF10B981),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Action Button (Add or Disabled)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isOut
                            ? null
                            : () {
                                ref
                                    .read(cartProvider.notifier)
                                    .addItem(
                                      med,
                                      widget.pharmacy,
                                      quantity: quantity,
                                      unit: selectedUnit,
                                      unitPrice: unitPrice,
                                    );
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: const Color(0xFF10B981),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    content: Text(
                                      '$quantity $selectedUnit لە ${med.name} بە سەرکەوتوویی زیادکرا بۆ سەبەتە 🎉',
                                      style: _kStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isOut
                              ? (isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFCBD5E1))
                              : const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                          disabledForegroundColor: const Color(0xFF94A3B8),
                          elevation: isOut ? 0 : 3,
                          shadowColor: const Color(
                            0xFF2563EB,
                          ).withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isOut
                                  ? Icons.block_rounded
                                  : Iconsax.shopping_cart,
                              color: isOut
                                  ? const Color(0xFF94A3B8)
                                  : Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isOut
                                  ? 'لە کۆگادا بەردەست نییە'
                                  : 'زیادکردن بۆ سەبەتە • ${totalPrice.toInt()} د.ع',
                              style: _kStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: isOut
                                    ? const Color(0xFF94A3B8)
                                    : Colors.white,
                              ),
                            ),
                          ],
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

  void _showReviewBottomSheet() {
    int selectedStars = 5;
    final TextEditingController commentController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;
          final txtColor = isDark ? Colors.white : const Color(0xFF0F172A);

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
              color: sheetBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'هەڵسەنگاندنی دەرمانخانە',
                  style: _kStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: txtColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'تکایە ئەستێرە دیاری بکە و ڕا و بۆچوونی خۆت بنووسە دەربارەی خزمەتگوزاری و دەرمانەکان:',
                  style: _kStyle(fontSize: 12, color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
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
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
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
                  style: _kStyle(fontSize: 13, color: txtColor),
                  decoration: InputDecoration(
                    hintText: 'review_input_hint'.tr(),
                    hintStyle: _kStyle(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                    ),
                    filled: true,

                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            setModalState(() {
                              isSubmitting = true;
                            });

                            final comment = commentController.text.trim();
                            await _repository.addReview(
                              widget.pharmacy.id,
                              rating: selectedStars.toDouble(),
                              comment: comment,
                            );

                            if (mounted) {
                              setState(() {
                                _reviews.insert(0, {
                                  'user_name': 'بەکارھێنەر',
                                  'rating': selectedStars.toDouble(),
                                  'comment': comment.isNotEmpty ? comment : 'خزمەتگوزارییەکی زۆر باشە.',
                                  'created_at': 'ئێستا',
                                });
                              });
                            }

                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  content: Text(
                                    'سوپاس! هەڵسەنگاندنەکەت بە سەرکەوتوویی تۆمارکرا ⭐',
                                    style: _kStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'ناردنی هەڵسەنگاندن',
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
      ),
    );
  }

  Widget _buildReviewsSection(bool isDark, Color cardBg, Color borderColor) {
    final double ratingVal = (widget.pharmacy.rating > 0) ? widget.pharmacy.rating : 4.9;
    final int reviewsCount = _reviews.isNotEmpty ? _reviews.length : 12;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
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
                    size: 22,
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
                    vertical: 5.5,
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
                          fontSize: 11.5,
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

          // Rating summary card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Text(
                        ratingVal.toStringAsFixed(1),
                        style: _kStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          5,
                          (i) => const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFF59E0B),
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'بەپێی $reviewsCount هەڵسەنگاندن',
                        style: _kStyle(
                          fontSize: 10.5,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 60,
                  width: 1,
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildRatingProgressBar('٥', 0.85, isDark),
                      const SizedBox(height: 3),
                      _buildRatingProgressBar('٤', 0.12, isDark),
                      const SizedBox(height: 3),
                      _buildRatingProgressBar('٣', 0.03, isDark),
                      const SizedBox(height: 3),
                      _buildRatingProgressBar('٢', 0.0, isDark),
                      const SizedBox(height: 3),
                      _buildRatingProgressBar('١', 0.0, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Reviews List
          Column(
            children: _reviews.map((review) {
              final String name = review['user_name'] ?? review['user']?['name'] ?? 'بەکارھێنەر';
              final double rating = double.tryParse('${review['rating'] ?? 5.0}') ?? 5.0;
              final String comment = review['comment'] ?? '';
              final String date = review['created_at'] != null 
                  ? review['created_at'].toString().split('T').first 
                  : (review['date'] ?? 'پێش چەند ڕۆژێک');

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
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
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                              child: Text(
                                name.isNotEmpty ? name.substring(0, 1) : 'U',
                                style: _kStyle(
                                  color: const Color(0xFF3B82F6),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: _kStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  date,
                                  style: _kStyle(
                                    fontSize: 10,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 12),
                              const SizedBox(width: 2),
                              Text(
                                rating.toStringAsFixed(1),
                                style: _kStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (comment.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        comment,
                        style: _kStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingProgressBar(String starLabel, double percentage, bool isDark) {
    return Row(
      children: [
        Text(
          starLabel,
          style: _kStyle(
            fontSize: 10,
            color: const Color(0xFF94A3B8),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 10),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 5,
              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    final medList = _medications.isNotEmpty
        ? _medications
        : _fallbackMedications;
    final filteredMeds = medList.where((med) {
      final query = _searchMedController.text.trim().toLowerCase();
      final matchesQuery = query.isEmpty ||
          med.name.toLowerCase().contains(query) ||
          (med.nameAr?.toLowerCase().contains(query) ?? false) ||
          (med.nameEn?.toLowerCase().contains(query) ?? false) ||
          (med.description?.toLowerCase().contains(query) ?? false) ||
          (med.category?.toLowerCase().contains(query) ?? false);
      if (!matchesQuery) return false;

      if (_selectedCategory != 'هەمووی' && _selectedCategory.isNotEmpty) {
        final medCat = (med.category ?? '').trim();
        final selCat = _selectedCategory.trim();
        if (medCat != selCat) {
          return false;
        }
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
            )
          : RefreshIndicator(
              onRefresh: _fetchData,
              color: const Color(0xFF3B82F6),
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              displacement: 40,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                // 1. Full Grand Top Carousel Header (Radius 32, Height 250)
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      // Carousel Image
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(32),
                        ),
                        child: Container(
                          height: 250,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              PageView.builder(
                                controller: _carouselController,
                                itemCount: _pharmacyGallery.length,
                                onPageChanged: (idx) =>
                                    setState(() => _currentCarouselIndex = idx),
                                itemBuilder: (context, index) {
                                  return Image.network(
                                    _pharmacyGallery[index],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: const Color(0xFF3B82F6),
                                      child: const Center(
                                        child: Icon(
                                          Icons.local_pharmacy,
                                          color: Colors.white,
                                          size: 60,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // Gradient Overlay
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withValues(alpha: 0.6),
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.7),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),

                              // Dots Indicator
                              Positioned(
                                bottom: 14,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    _pharmacyGallery.length,
                                    (idx) {
                                      final isSel =
                                          _currentCarouselIndex == idx;
                                      return AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 3,
                                        ),
                                        width: isSel ? 22 : 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: isSel
                                              ? Colors.white
                                              : Colors.white.withValues(
                                                  alpha: 0.4,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Top App Bar (Back Button)
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back_ios_new,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                              const SizedBox(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Full Info, Badges, Location, Actions, Offer, Categories & Search
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pharmacy Name & Rating Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                widget.pharmacy.name,
                                style: _kStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: _showReviewBottomSheet,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Color(0xFFD97706),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      (widget.pharmacy.rating > 0)
                                          ? '${widget.pharmacy.rating}'
                                          : '4.9',
                                      style: _kStyle(
                                        color: const Color(0xFFD97706),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Badges Row (Open Status, Verified, Delivery Fee)
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: widget.pharmacy.isOpen
                                    ? const Color(
                                        0xFF10B981,
                                      ).withValues(alpha: 0.12)
                                    : const Color(
                                        0xFFEF4444,
                                      ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.pharmacy.isOpen
                                    ? 'کراوەیە 🟢'
                                    : 'داخراوە 🔴',
                                style: _kStyle(
                                  color: widget.pharmacy.isOpen
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF3B82F6,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.verified_rounded,
                                    color: Color(0xFF3B82F6),
                                    size: 13,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'باوەڕپێکراو',
                                    style: _kStyle(
                                      color: const Color(0xFF3B82F6),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF8B5CF6,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'گەیاندن: ${widget.pharmacy.deliveryFee.toInt()} د.ع',
                                style: _kStyle(
                                  color: const Color(0xFF8B5CF6),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Location Row
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: Color(0xFF3B82F6),
                              size: 17,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.pharmacy.address ??
                                    'هەولێر، شەقامی ٤٠ مەتری - نزیک نەخۆشخانەی نانەکەلی',
                                style: _kStyle(
                                  fontSize: 12.5,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Delivery Time Row
                        Row(
                          children: [
                            const Icon(
                              Icons.delivery_dining_outlined,
                              color: Color(0xFF10B981),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'گەیاندنی خێرا: ${widget.pharmacy.deliveryFee.toInt()} د.ع (٢٠-٣٠ خولەک)',
                              style: _kStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF64748B),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Action Chips Row (Call, Facebook, Map)
                        Row(
                          children: [
                            // Call Button
                            Expanded(
                              child: GestureDetector(
                                onTap: _makeCall,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF10B981,
                                      ).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.phone_in_talk_rounded,
                                        color: Color(0xFF10B981),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'پەیوەندی',
                                        style: _kStyle(
                                          color: const Color(0xFF10B981),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Facebook Button
                            Expanded(
                              child: GestureDetector(
                                onTap: _openFacebook,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF1877F2,
                                    ).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF1877F2,
                                      ).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.facebook,
                                        color: Color(0xFF1877F2),
                                        size: 17,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'فەیسبووک',
                                        style: _kStyle(
                                          color: const Color(0xFF1877F2),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Map Button
                            Expanded(
                              child: GestureDetector(
                                onTap: _openMap,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF3B82F6,
                                    ).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF3B82F6,
                                      ).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.location_on_rounded,
                                        color: Color(0xFF3B82F6),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'نەخشە',
                                        style: _kStyle(
                                          color: const Color(0xFF3B82F6),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Categories Horizontal Scroll
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: _categories.map((cat) {
                              final isSel = _selectedCategory == cat['name'];
                              return Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                      end: 8,
                                    ),
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => _selectedCategory = cat['name']!,
                                      ),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSel
                                              ? const Color(0xFF3B82F6)
                                              : cardBg,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: isSel
                                                ? const Color(0xFF3B82F6)
                                                : borderColor,
                                          ),
                                          boxShadow: isSel
                                              ? [
                                                  BoxShadow(
                                                    color: const Color(
                                                      0xFF3B82F6,
                                                    ).withValues(alpha: 0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Text(
                                          _getCategoryDisplayName(cat, context),
                                          style: _kStyle(
                                            color: isSel
                                                ? Colors.white
                                                : (isDark
                                                      ? Colors.white70
                                                      : const Color(
                                                          0xFF475569,
                                                        )),
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Search Medicines Bar
                        Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Iconsax.search_normal_1,
                                color: Color(0xFF94A3B8),
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _searchMedController,
                                  onChanged: (val) => setState(() {}),
                                  style: _kStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                    fontSize: 13,
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        'گەڕان لەناو دەرمانەکانی ئەم دەرمانخانەیە...',
                                    hintStyle: _kStyle(
                                      color: const Color(0xFF94A3B8),
                                      fontSize: 12.5,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              if (_searchMedController.text.isNotEmpty)
                                GestureDetector(
                                  onTap: () => setState(
                                    () => _searchMedController.clear(),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Color(0xFF94A3B8),
                                    size: 16,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        Text(
                          'دەرمان و پێداویستییەکان (${filteredMeds.length})',
                          style: _kStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Medicines 2-Column Grid Layout
                filteredMeds.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.medication_outlined,
                                  size: 50,
                                  color: Colors.grey.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'هیچ دەرمانێک نەدۆزرایەوە',
                                  style: _kStyle(
                                    color: const Color(0xFF94A3B8),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 14,
                                childAspectRatio: 0.91,
                              ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final med = filteredMeds[index];
                            final inCartItem = cartState.items
                                .where((i) => i.medication.id == med.id)
                                .firstOrNull;
                            final int qty = inCartItem?.quantity ?? 0;
                            final bool hasDiscount = med.hasDiscount;
                            final int discountPercent = med.calculatedDiscountPercent;
                            final double crossedPrice = med.effectiveOriginalPrice;
                            final double currentPrice = med.price;

                            return GestureDetector(
                              onTap: () =>
                                  _showMedicationDetailBottomSheet(med),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: borderColor),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: isDark ? 0.2 : 0.04,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.5),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Image Container with dosage badge
                                      Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Container(
                                              height: 96,
                                              width: double.infinity,
                                              color: isDark
                                                  ? const Color(0xFF0F172A)
                                                  : const Color(0xFFF8FAFC),
                                              child: Opacity(
                                                opacity: med.isOutOfStock
                                                    ? 0.45
                                                    : 1.0,
                                                child: Image.network(
                                                  med.imageUrl ??
                                                      'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=300',
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      Center(
                                                        child: Icon(
                                                          Icons
                                                              .medication_rounded,
                                                          color:
                                                              const Color(
                                                                0xFF3B82F6,
                                                              ).withValues(
                                                                alpha: 0.7,
                                                              ),
                                                          size: 40,
                                                        ),
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Badges (Out of stock / Discount / Original)
                                          PositionedDirectional(
                                            top: 6,
                                            start: 6,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2.5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: med.isOutOfStock
                                                    ? const Color(0xFFEF4444)
                                                    : (hasDiscount
                                                          ? const Color(
                                                              0xFFDC2626,
                                                            )
                                                          : Colors.black
                                                                .withValues(
                                                                  alpha: 0.65,
                                                                )),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                boxShadow:
                                                    hasDiscount ||
                                                        med.isOutOfStock
                                                    ? [
                                                        BoxShadow(
                                                          color:
                                                              (med.isOutOfStock
                                                                      ? const Color(
                                                                          0xFFEF4444,
                                                                        )
                                                                      : const Color(
                                                                          0xFFDC2626,
                                                                        ))
                                                                  .withValues(
                                                                    alpha: 0.35,
                                                                  ),
                                                          blurRadius: 4,
                                                          offset: const Offset(
                                                            0,
                                                            1,
                                                          ),
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                              child: Text(
                                                med.isOutOfStock
                                                    ? 'نەماوە ❌'
                                                    : (hasDiscount
                                                          ? 'داشکاندن $discountPercent٪'
                                                          : 'ئۆرجیناڵ ⭐'),
                                                style: _kStyle(
                                                  color: Colors.white,
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 5),

                                      // Medicine Name
                                      Text(
                                        med.name,
                                        style: _kStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                          color: med.isOutOfStock
                                              ? (isDark
                                                    ? Colors.white38
                                                    : const Color(0xFF94A3B8))
                                              : (isDark
                                                    ? Colors.white
                                                    : const Color(0xFF0F172A)),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                      const SizedBox(height: 2),

                                      // Description Subtext
                                      Text(
                                        med.description ??
                                            'دەرمانی باوەڕپێکراو',
                                        style: _kStyle(
                                          fontSize: 11,
                                          color: isDark
                                              ? Colors.white60
                                              : const Color(0xFF64748B),
                                          height: 1.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                      const Spacer(),

                                      // Price and Add/Counter Row
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          // Price in IQD
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (hasDiscount &&
                                                  !med.isOutOfStock)
                                                Text(
                                                  '${crossedPrice.toInt()} د.ع',
                                                  style:
                                                      _kStyle(
                                                        fontSize: 10,
                                                        color: const Color(
                                                          0xFF94A3B8,
                                                        ),
                                                      ).copyWith(
                                                        decoration:
                                                            TextDecoration
                                                                .lineThrough,
                                                      ),
                                                ),
                                              Text(
                                                '${currentPrice.toInt()}',
                                                style: _kStyle(
                                                  fontSize: 14.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: med.isOutOfStock
                                                      ? const Color(0xFF94A3B8)
                                                      : (hasDiscount
                                                          ? const Color(0xFF10B981)
                                                          : const Color(0xFF2563EB)),
                                                ),
                                              ),
                                              Text(
                                                'دیناری عێراقی',
                                                style: _kStyle(
                                                  fontSize: 9.5,
                                                  color: isDark
                                                      ? Colors.white54
                                                      : const Color(0xFF94A3B8),
                                                ),
                                              ),
                                            ],
                                          ),

                                          // Modern Floating Add / Out of Stock / Stepper Button
                                          if (med.isOutOfStock)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? const Color(
                                                        0xFF334155,
                                                      ).withValues(alpha: 0.5)
                                                    : const Color(0xFFF1F5F9),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: isDark
                                                      ? const Color(0xFF475569)
                                                      : const Color(0xFFE2E8F0),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.block_rounded,
                                                    size: 11,
                                                    color: Color(0xFF94A3B8),
                                                  ),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    'نەماوە',
                                                    style: _kStyle(
                                                      color: const Color(
                                                        0xFF94A3B8,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 10.5,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          else if (qty == 0)
                                            GestureDetector(
                                              onTap: () {
                                                _showMedicationDetailBottomSheet(
                                                  med,
                                                );
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF2563EB,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(
                                                        0xFF2563EB,
                                                      ).withValues(alpha: 0.3),
                                                      blurRadius: 6,
                                                      offset: const Offset(
                                                        0,
                                                        2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.add,
                                                      color: Colors.white,
                                                      size: 14,
                                                    ),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      'کڕین',
                                                      style: _kStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                          else
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFF2563EB,
                                                ).withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFF2563EB,
                                                  ).withValues(alpha: 0.3),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  GestureDetector(
                                                    onTap: () {
                                                      ref
                                                          .read(
                                                            cartProvider
                                                                .notifier,
                                                          )
                                                          .updateQuantity(
                                                            med.id,
                                                            qty - 1,
                                                          );
                                                    },
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: cardBg,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(
                                                        Icons.remove,
                                                        size: 12,
                                                        color: Color(
                                                          0xFF2563EB,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                        ),
                                                    child: Text(
                                                      '$qty',
                                                      style: _kStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12,
                                                        color: const Color(
                                                          0xFF2563EB,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  GestureDetector(
                                                    onTap: () {
                                                      ref
                                                          .read(
                                                            cartProvider
                                                                .notifier,
                                                          )
                                                          .updateQuantity(
                                                            med.id,
                                                            qty + 1,
                                                          );
                                                    },
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                          0xFF2563EB,
                                                        ),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(
                                                        Icons.add,
                                                        size: 12,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(delay: (index * 30).ms).slideY(begin: 0.03, end: 0);
                          }, childCount: filteredMeds.length),
                        ),
                      ),

                // 4. Customer Reviews & Ratings Section (هاوشێوەی تاقیگە)
                SliverToBoxAdapter(
                  child: _buildReviewsSection(isDark, cardBg, borderColor),
                ),

                SliverToBoxAdapter(
                  child: SizedBox(
                    height: cartState.items.isNotEmpty ? 85 : 20,
                  ),
                ),
              ],
            ),
          ),

      // Sticky Bottom Cart Bar
      bottomSheet: cartState.items.isNotEmpty
          ? Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: cardBg,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'کۆی گشتی (${cartState.totalItems} دەرمان):',
                        style: _kStyle(
                          fontSize: 11.5,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      Text(
                        '${cartState.subtotal.toInt()} د.ع',
                        style: _kStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CartScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Iconsax.shopping_cart,
                      color: Colors.white,
                      size: 16,
                    ),
                    label: Text(
                      'تەواوکردنی کڕین',
                      style: _kStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}