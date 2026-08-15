import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/pharmacy_model.dart';
import '../models/medication_model.dart';
import '../models/offer_model.dart';
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
  List<Medication> _medications = [];
  List<PharmacyOffer> _offers = [];
  bool _isLoading = true;
  int _selectedTabIndex = 0;
  String _selectedMedCategory = 'هەمووی';

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
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final meds = await _repository.getMedications(widget.pharmacy.id);
      final offers = await _repository.getOffers(widget.pharmacy.id);
      if (mounted) {
        setState(() {
          _medications = meds;
          _offers = offers;
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
      ];

  Future<void> _callPharmacy() async {
    final phone = widget.pharmacy.phone ?? '07501234567';
    final Uri uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final medList = _medications.isNotEmpty ? _medications : _fallbackMedications;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.pharmacy.name,
          style: _kStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PharmacyChatScreen(pharmacy: widget.pharmacy)),
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: const Icon(Iconsax.messages_2, color: Color(0xFF3B82F6), size: 18),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12, start: 4),
            child: GestureDetector(
              onTap: _callPharmacy,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF10B981), size: 18),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Hero Info Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Pharmacy Thumbnail
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Image.network(
                                    widget.pharmacy.profileImage ??
                                        'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=500',
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 80,
                                      height: 80,
                                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                      child: const Icon(Icons.local_pharmacy, color: Color(0xFF3B82F6), size: 36),
                                    ),
                                  ),
                                ),
                                PositionedDirectional(
                                  top: 4,
                                  end: 4,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: widget.pharmacy.isOpen ? const Color(0xFF10B981) : const Color(0xFFEF4444),
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
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 13),
                                            const SizedBox(width: 4),
                                            Text(
                                              'باوەڕپێکراو',
                                              style: _kStyle(color: const Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 14),
                                            const SizedBox(width: 2),
                                            Text(
                                              '${widget.pharmacy.rating}',
                                              style: _kStyle(color: const Color(0xFFD97706), fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    widget.pharmacy.name,
                                    style: _kStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.pharmacy.address ?? 'هەولێر، کوردستان',
                                    style: _kStyle(fontSize: 12, color: const Color(0xFF94A3B8)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 14),

                        // Fast Highlights Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildFeatureItem(Icons.timelapse_rounded, '٢٠-٣٠ خولەک', 'کاتی گەیاندن', const Color(0xFF3B82F6), isDark),
                            _buildFeatureItem(Icons.local_shipping_outlined, '${widget.pharmacy.deliveryFee.toInt()} د.ع', 'کرێی گەیاندن', const Color(0xFF10B981), isDark),
                            _buildFeatureItem(Icons.schedule, widget.pharmacy.isOpen ? 'کراوەیە' : 'داخراوە', 'دۆخی کارکردن', widget.pharmacy.isOpen ? const Color(0xFF10B981) : const Color(0xFFEF4444), isDark),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.05, end: 0),

                  const SizedBox(height: 18),

                  // Modern Promo Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                'داشکاندنی ١٠٪ لەسەر هەموو دەرمانەکان 🎉',
                                style: _kStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                'کۆدی داشکاندن: PHARMA10 لە کاتی چێکئاوت بەکاربهێنە',
                                style: _kStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Modern Tab Bar
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        _buildTabButton(0, '💊 دەرمانەکان', isDark),
                        _buildTabButton(1, '📋 دەربارە', isDark),
                        _buildTabButton(2, '⭐ بۆچوونەکان', isDark),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Tab Content
                  if (_selectedTabIndex == 0) ...[
                    // Medications Tab
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'لیستی دەرمانە بەردەستەکان (${medList.length})',
                          style: _kStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    ...medList.map((med) {
                      final inCartItem = cartState.items.where((i) => i.medication.id == med.id).firstOrNull;
                      final int qty = inCartItem?.quantity ?? 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                med.imageUrl ?? 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=300',
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 70,
                                  height: 70,
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                  child: const Icon(Icons.medication_rounded, color: Color(0xFF3B82F6), size: 30),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
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
                                    med.description ?? 'دەرمانی پزیشکی بەرهەمهێنراو بە ستانداردی جیهانی',
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
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF3B82F6),
                                        ),
                                      ),

                                      // Cart Counter Button
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
                      );
                    }),
                  ] else if (_selectedTabIndex == 1) ...[
                    // About Tab
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('دەربارەی دەرمانخانە 🏥', style: _kStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                          const SizedBox(height: 8),
                          Text(
                            '${widget.pharmacy.name} یەکێکە لە دەرمانخانە باوەڕپێکراوەکانی هەرێمی کوردستان، دابینکەری هەموو جۆرە دەرمانێکی ڕەسەن و کوالێتی بەرز بە چاودێری دەرمانسازانی پسپۆڕ و مۆڵەتپێدراوی وەزارەتی تەندروستی.',
                            style: _kStyle(fontSize: 13, color: const Color(0xFF64748B), height: 1.5),
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 12),
                          _buildInfoRow(Icons.location_on_outlined, 'ناونیشان', widget.pharmacy.address ?? 'هەولێر، کوردستان', isDark),
                          const SizedBox(height: 10),
                          _buildInfoRow(Icons.access_time_rounded, 'کاتژمێرەکانی کارکردن', '٨:٠٠ بەیانی - ١١:٣٠ شەو', isDark),
                          const SizedBox(height: 10),
                          _buildInfoRow(Icons.phone_outlined, 'ژمارەی مۆبایل', widget.pharmacy.phone ?? '0750 000 0000', isDark),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Reviews Tab
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('بۆچوونی نەخۆش و کڕیاران ⭐', style: _kStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                              Text('٤.٩ لە ٥', style: _kStyle(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFD97706))),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildReviewCard('ئاراس مەحمود', 'گەیاندنی زۆر خێرا بوو و دەرمانەکان زۆر بە پارێزراوی گەیشتن. دەستتان خۆش بێت.', '٥ ئەستێرە ⭐⭐⭐⭐⭐', isDark),
                          const SizedBox(height: 10),
                          _buildReviewCard('سارا ئەحمەد', 'دەرمانسازەکەیان لە چات وەڵامی هەموو پرسیارەکانمی دایەوە و ڕێنمایی تەواوی پێدام.', '٥ ئەستێرە ⭐⭐⭐⭐⭐', isDark),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 90),
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

  Widget _buildFeatureItem(IconData icon, String title, String subtitle, Color color, bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: _kStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        Text(
          subtitle,
          style: _kStyle(fontSize: 10.5, color: const Color(0xFF94A3B8)),
        ),
      ],
    );
  }

  Widget _buildTabButton(int index, String title, bool isDark) {
    final bool isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              title,
              style: _kStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String val, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF3B82F6), size: 18),
        const SizedBox(width: 8),
        Text('$title: ', style: _kStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF475569))),
        Expanded(
          child: Text(
            val,
            style: _kStyle(fontSize: 12.5, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(String author, String comment, String stars, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(author, style: _kStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
              Text(stars, style: _kStyle(fontSize: 11, color: const Color(0xFFD97706))),
            ],
          ),
          const SizedBox(height: 4),
          Text(comment, style: _kStyle(fontSize: 12, color: const Color(0xFF64748B), height: 1.35)),
        ],
      ),
    );
  }
}
