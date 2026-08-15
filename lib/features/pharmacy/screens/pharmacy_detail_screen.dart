import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/pharmacy_model.dart';
import '../models/medication_model.dart';
import '../data/pharmacy_repository.dart';
import '../providers/cart_provider.dart';
import 'cart_screen.dart';
import 'pharmacy_chat_screen.dart';

class PharmacyDetailScreen extends ConsumerStatefulWidget {
  final Pharmacy pharmacy;

  const PharmacyDetailScreen({super.key, required this.pharmacy});

  @override
  ConsumerState<PharmacyDetailScreen> createState() => _PharmacyDetailScreenState();
}

class _PharmacyDetailScreenState extends ConsumerState<PharmacyDetailScreen> {
  final PharmacyRepository _repository = PharmacyRepository();
  final TextEditingController _searchMedController = TextEditingController();
  final PageController _carouselController = PageController();
  int _currentCarouselIndex = 0;
  Timer? _carouselTimer;

  List<Medication> _medications = [];
  bool _isLoading = true;

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

  late final List<String> _pharmacyGallery = [
    widget.pharmacy.profileImage ?? 'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=800',
    'https://images.unsplash.com/photo-1576602976047-174e57a47881?w=800',
    'https://images.unsplash.com/photo-1631549916768-4119b2e5f926?w=800',
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
    _startCarouselTimer();
  }

  void _startCarouselTimer() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_carouselController.hasClients) {
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
      final meds = await _repository.getMedications(widget.pharmacy.id);
      if (mounted) {
        setState(() {
          _medications = meds;
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

  List<Medication> get _fallbackMedications => [
        Medication(
          id: 101,
          name: 'Panadol Extra (پانادۆڵ ئێکسسترا)',
          description: 'ئازارشکێن و دابەزێنەری پلەی گەرمی جەستە',
          price: 2500,
          stock: 45,
          imageUrl: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400',
        ),
        Medication(
          id: 102,
          name: 'Amoxicillin 500mg (ئامۆکسیسیلین)',
          description: 'دژەهەوکردن و ئەنتی بایۆتیکی بەهێز بۆ هەوکردنی قوڕگ و سییەکان',
          price: 4500,
          stock: 30,
          imageUrl: 'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?w=400',
        ),
        Medication(
          id: 103,
          name: 'Vitamin C 1000mg (ڤیتامین سی تەقێنراو)',
          description: 'بەهێزکەری بەرگری جەستە و پڕ لە دژەئۆکسان',
          price: 5000,
          stock: 25,
          imageUrl: 'https://images.unsplash.com/photo-1550572017-ed24c5208f60?w=400',
        ),
        Medication(
          id: 104,
          name: 'Omeprazole 20mg (ئۆمیپرازۆڵ)',
          description: 'چارەسەری ترشەڵۆکی گەدە و کەمکردنەوەی سوزشی سنگ',
          price: 3500,
          stock: 18,
          imageUrl: 'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=400',
        ),
        Medication(
          id: 105,
          name: 'Baby Care Milk (شیری منداڵان)',
          description: 'شیری تەواوکەری خۆراکی دەوڵەمەند بە ڤیتامین و ماددە کانزاییەکان',
          price: 14000,
          stock: 12,
          imageUrl: 'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?w=400',
        ),
        Medication(
          id: 106,
          name: 'Ibuprofen 400mg (ئیبۆپرۆفین)',
          description: 'بۆ ئازاری جومگە، ماسولکە و سەرئێشەی توند',
          price: 3000,
          stock: 20,
          imageUrl: 'https://images.unsplash.com/photo-1576602976047-174e57a47881?w=400',
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
    final Uri uri = Uri.parse('https://facebook.com');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openMap() async {
    final address = widget.pharmacy.address ?? 'Erbil Kurdistan';
    final Uri uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final medList = _medications.isNotEmpty ? _medications : _fallbackMedications;
    final filteredMeds = medList.where((med) {
      final query = _searchMedController.text.trim().toLowerCase();
      return med.name.toLowerCase().contains(query) || (med.description?.toLowerCase().contains(query) ?? false);
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Top Carousel Header with Rounded Bottom Radius
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      // Image Carousel
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
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
                                onPageChanged: (idx) => setState(() => _currentCarouselIndex = idx),
                                itemBuilder: (context, index) {
                                  return Image.network(
                                    _pharmacyGallery[index],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: const Color(0xFF3B82F6),
                                      child: const Center(
                                        child: Icon(Icons.local_pharmacy, color: Colors.white, size: 60),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // Gradient Overlays
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withValues(alpha: 0.6),
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.75),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),

                              // Carousel Indicators (Dots)
                              Positioned(
                                bottom: 14,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(_pharmacyGallery.length, (idx) {
                                    final isSel = _currentCarouselIndex == idx;
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      margin: const EdgeInsets.symmetric(horizontal: 3),
                                      width: isSel ? 20 : 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: isSel ? Colors.white : Colors.white.withValues(alpha: 0.4),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Top App Bar Buttons (Back)
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.white),
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

                // 2. Pharmacy Info, Badges, Location, Phone, Social & Offer
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pharmacy Name & Rating
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
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 16),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${widget.pharmacy.rating}',
                                    style: _kStyle(
                                      color: const Color(0xFFD97706),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Badges Row (Open Status, Verified, Delivery Time)
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: widget.pharmacy.isOpen
                                    ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                    : const Color(0xFFEF4444).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.pharmacy.isOpen ? 'کراوەیە 🟢' : 'داخراوە 🔴',
                                style: _kStyle(
                                  color: widget.pharmacy.isOpen ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.verified_rounded, color: Color(0xFF3B82F6), size: 13),
                                  const SizedBox(width: 4),
                                  Text(
                                    'باوەڕپێکراو',
                                    style: _kStyle(color: const Color(0xFF3B82F6), fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'گەیاندن: ${widget.pharmacy.deliveryFee.toInt()} د.ع',
                                style: _kStyle(color: const Color(0xFF8B5CF6), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Location Row
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: Color(0xFF3B82F6), size: 17),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.pharmacy.address ?? 'هەولێر، شەقامی ٤٠ مەتری - نزیک نەخۆشخانەی نانەکەلی',
                                style: _kStyle(
                                  fontSize: 12.5,
                                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Delivery & Time Row
                        Row(
                          children: [
                            const Icon(Icons.delivery_dining_outlined, color: Color(0xFF10B981), size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'گەیاندنی خێرا: ${widget.pharmacy.deliveryFee.toInt()} د.ع (٢٠-٣٠ خولەک)',
                              style: _kStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Action Chips (Call, Facebook, Chat)
                        Row(
                          children: [
                            // Call Button
                            Expanded(
                              child: GestureDetector(
                                onTap: _makeCall,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF10B981), size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        'پەیوەندی',
                                        style: _kStyle(color: const Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Facebook / Social Button
                            Expanded(
                              child: GestureDetector(
                                onTap: _openFacebook,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1877F2).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFF1877F2).withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 17),
                                      const SizedBox(width: 6),
                                      Text(
                                        'فەیسبووک',
                                        style: _kStyle(color: const Color(0xFF1877F2), fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Map / Location Button
                            Expanded(
                              child: GestureDetector(
                                onTap: _openMap,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.location_on_rounded, color: Color(0xFF3B82F6), size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        'نەخشە',
                                        style: _kStyle(color: const Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Special Offer Banner
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.discount_rounded, color: Colors.white, size: 24),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ئۆفەری داشکاندنی دەرمانەکان 🎉',
                                      style: _kStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    Text(
                                      'داشکاندنی ١٠٪ بە کۆدی PHARMA10 لە کاتی کڕین',
                                      style: _kStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

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
                              const Icon(Iconsax.search_normal_1, color: Color(0xFF94A3B8), size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _searchMedController,
                                  onChanged: (val) => setState(() {}),
                                  style: _kStyle(
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    fontSize: 13,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'گەڕان لەناو دەرمانەکانی ئەم دەرمانخانەیە...',
                                    hintStyle: _kStyle(color: const Color(0xFF94A3B8), fontSize: 12.5),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              if (_searchMedController.text.isNotEmpty)
                                GestureDetector(
                                  onTap: () => setState(() => _searchMedController.clear()),
                                  child: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 16),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          'دەرمان و پێداویستییەکان (${filteredMeds.length})',
                          style: _kStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Medicines List
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final med = filteredMeds[index];
                        final inCartItem = cartState.items.where((i) => i.medication.id == med.id).firstOrNull;
                        final int qty = inCartItem?.quantity ?? 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  med.imageUrl ?? 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=300',
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 72,
                                    height: 72,
                                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                    child: const Icon(Icons.medication_rounded, color: Color(0xFF3B82F6), size: 30),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      med.name,
                                      style: _kStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      med.description ?? 'دەرمانی پزیشکی بە کوالێتی بەرز',
                                      style: _kStyle(fontSize: 11.5, color: const Color(0xFF94A3B8), height: 1.3),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${med.price.toInt()} د.ع',
                                          style: _kStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF3B82F6),
                                          ),
                                        ),

                                        // Add to Cart Button or Counter
                                        if (qty == 0)
                                          GestureDetector(
                                            onTap: () {
                                              ref.read(cartProvider.notifier).addItem(med, widget.pharmacy);
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF3B82F6),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.add, color: Colors.white, size: 15),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'زیادکردن',
                                                    style: _kStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        else
                                          Container(
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                                            ),
                                            child: Row(
                                              children: [
                                                GestureDetector(
                                                  onTap: () {
                                                    ref.read(cartProvider.notifier).updateQuantity(med.id, qty - 1);
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.all(6),
                                                    child: const Icon(Icons.remove, size: 14, color: Color(0xFF3B82F6)),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                                  child: Text(
                                                    '$qty',
                                                    style: _kStyle(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF3B82F6)),
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () {
                                                    ref.read(cartProvider.notifier).updateQuantity(med.id, qty + 1);
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets.all(6),
                                                    child: const Icon(Icons.add, size: 14, color: Color(0xFF3B82F6)),
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
                            ],
                          ),
                        ).animate().fadeIn(delay: (index * 40).ms).slideY(begin: 0.04, end: 0);
                      },
                      childCount: filteredMeds.length,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
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
                        style: _kStyle(fontSize: 11.5, color: const Color(0xFF94A3B8)),
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
                        MaterialPageRoute(builder: (context) => const CartScreen()),
                      );
                    },
                    icon: const Icon(Iconsax.shopping_cart, color: Colors.white, size: 16),
                    label: Text(
                      'تەواوکردنی کڕین',
                      style: _kStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
