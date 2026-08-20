import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:url_launcher/url_launcher.dart';

import 'nursing_services_screen.dart';

class NurseDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> nurse;

  const NurseDetailsScreen({
    super.key,
    required this.nurse,
  });

  TextStyle _kStyle({
    Color? color,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'Rabar',
      color: color ?? const Color(0xFF0F172A),
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
    );
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

  String _serviceTypeKurdish(String? type) {
    switch (type) {
      case 'clinic':
        return 'کلینیک (Clinic)';
      case 'hospital':
        return 'نەخۆشخانە (Hospital)';
      case 'home_nursing':
      default:
        return 'پەرستاری ماڵەوە (Home)';
    }
  }

  @override
  Widget build(BuildContext context) {
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

    final bio = (isArabic && nurse['bio_ar'] != null && nurse['bio_ar'].toString().isNotEmpty)
        ? nurse['bio_ar']
        : (isEnglish && nurse['bio_en'] != null && nurse['bio_en'].toString().isNotEmpty)
            ? nurse['bio_en']
            : (nurse['bio'] ?? '');

    final address = (isArabic && nurse['address_ar'] != null && nurse['address_ar'].toString().isNotEmpty)
        ? nurse['address_ar']
        : (isEnglish && nurse['address_en'] != null && nurse['address_en'].toString().isNotEmpty)
            ? nurse['address_en']
            : (nurse['address'] ?? '');

    final image = nurse['image'];
    final phone = nurse['phone']?.toString() ?? '';
    final isAvailable = nurse['is_available'] == true;
    final fee = nurse['fee'];
    final city = nurse['city']?.toString() ?? '';
    final serviceType = nurse['service_type']?.toString();
    final customServices = nurse['custom_services'] as List<dynamic>? ?? [];

    final double? lat = nurse['latitude'] != null ? double.tryParse(nurse['latitude'].toString()) : null;
    final double? lng = nurse['longitude'] != null ? double.tryParse(nurse['longitude'].toString()) : null;

    // Collect all specialty chips
    final List<String> allSpecialties = [];
    final String specialtyStr = (specialty ?? '').toString();
    if (specialtyStr.isNotEmpty) {
      final parts = specialtyStr
          .split(RegExp(r'[،,]'))
          .map((e) => e.trim())
          .where((String e) => e.isNotEmpty);
      allSpecialties.addAll(parts);
    }
    for (var cs in customServices) {
      if (cs is Map && cs['name'] != null && cs['name'].toString().isNotEmpty) {
        final csName = (isArabic && cs['name_ar'] != null && cs['name_ar'].toString().isNotEmpty)
            ? cs['name_ar']
            : (isEnglish && cs['name_en'] != null && cs['name_en'].toString().isNotEmpty)
                ? cs['name_en']
                : cs['name'].toString();
        if (!allSpecialties.contains(csName)) {
          allSpecialties.add(csName);
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar ──
          SliverAppBar(
            pinned: true,
            expandedHeight: 280,
            backgroundColor: const Color(0xFF0D9488),
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsetsDirectional.only(start: 16),
              child: Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
                      ],
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 16),
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF0D9488), Color(0xFF115E59)],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.1,
                      child: CustomPaint(
                        painter: _PatternPainter(),
                      ),
                    ),
                  ),
                  // Nurse Hero Content
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Avatar
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            color: Colors.white,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 6)),
                            ],
                            image: image != null
                                ? DecorationImage(image: NetworkImage(image), fit: BoxFit.cover)
                                : null,
                          ),
                          child: image == null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Iconsax.health, color: Color(0xFF0D9488), size: 40),
                                      const SizedBox(height: 4),
                                      Text(
                                        name.isNotEmpty ? name.split(' ').first : 'پەرستار',
                                        style: _kStyle(color: const Color(0xFF0D9488), fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        // Name & Status
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isAvailable ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isAvailable ? 'ئامادەیە بۆ وەرگرتنی داواکاری' : 'لە ئێستادا بەردەست نییە',
                                  style: _kStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                name,
                                style: _kStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (city.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Iconsax.location, color: Colors.white70, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      _cityKurdish(city),
                                      style: _kStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Main Content ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Quick Info Grid ──
                  Row(
                    children: [
                      // Fee Card
                      Expanded(
                        child: _buildInfoCard(
                          icon: Iconsax.card,
                          iconColor: const Color(0xFFF59E0B),
                          bgColor: const Color(0xFFFEF3C7),
                          title: 'نرخی خزمەتگوزاری',
                          value: fee != null ? '${double.tryParse(fee.toString())?.toInt() ?? fee} د.ع' : 'دیارینەکراوە',
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Service Type Card
                      Expanded(
                        child: _buildInfoCard(
                          icon: Iconsax.hospital,
                          iconColor: const Color(0xFF0D9488),
                          bgColor: const Color(0xFFCCFBF1),
                          title: 'جۆری خزمەتگوزاری',
                          value: _serviceTypeKurdish(serviceType),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1),

                  const SizedBox(height: 20),

                  // ── About / Biography ──
                  if (bio.isNotEmpty) ...[
                    _buildSectionHeader(title: 'دەربارەی پەرستار و ئەزموون', icon: Iconsax.user),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Text(
                        bio,
                        style: _kStyle(color: const Color(0xFF334155), fontSize: 13.5, height: 1.6),
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                    const SizedBox(height: 24),
                  ],

                  // ── Specialties & Skills ──
                  if (allSpecialties.isNotEmpty) ...[
                    _buildSectionHeader(title: 'پسپۆڕی و بوارەکان', icon: Iconsax.health),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: allSpecialties.map((s) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDFA),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF99F6E4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle, color: Color(0xFF0D9488), size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  s,
                                  style: _kStyle(color: const Color(0xFF0F766E), fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                    const SizedBox(height: 24),
                  ],

                  // ── Location & Address ──
                  if (address.isNotEmpty) ...[
                    _buildSectionHeader(title: 'ناونیشان و شوێن', icon: Iconsax.location),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
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
                                  color: const Color(0xFFF0FDFA),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Iconsax.map_1, color: Color(0xFF0D9488), size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  address,
                                  style: _kStyle(color: const Color(0xFF1E293B), fontSize: 13.5, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          if (lat != null && lng != null) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  }
                                },
                                icon: const Icon(Icons.directions, color: Color(0xFF0D9488), size: 16),
                                label: Text(
                                  'کردنەوە لەسەر نەخشە (Directions)',
                                  style: _kStyle(color: const Color(0xFF0D9488), fontSize: 12.5, fontWeight: FontWeight.bold),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF99F6E4)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                    const SizedBox(height: 24),
                  ],

                  // ── Contact Phone Card ──
                  if (phone.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDFA),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFCCFBF1)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D9488),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Iconsax.call, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ژمارەی پەیوەندی',
                                  style: _kStyle(color: const Color(0xFF64748B), fontSize: 11),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  phone,
                                  style: _kStyle(color: const Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.bold),
                                  textDirection: TextDirection.ltr,
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final uri = Uri.parse('tel:$phone');
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D9488),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            child: Text(
                              'پەیوەندی',
                              style: _kStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                    const SizedBox(height: 20),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Sticky Bottom Request Button ──
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, -6)),
          ],
        ),
        child: Row(
          children: [
            if (fee != null) ...[
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('نرخی خزمەتگوزاری', style: _kStyle(color: const Color(0xFF64748B), fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(
                    '${double.tryParse(fee.toString())?.toInt() ?? fee} د.ع',
                    style: _kStyle(color: const Color(0xFF0D9488), fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(width: 20),
            ],
            Expanded(
              child: ElevatedButton(
                onPressed: () {
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  shadowColor: const Color(0xFF0D9488).withValues(alpha: 0.4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Iconsax.calendar_tick, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'داواکردنی خزمەتگوزاری',
                      style: _kStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required IconData icon}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFCCFBF1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF0D9488), size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: _kStyle(color: const Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: _kStyle(color: const Color(0xFF64748B), fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: _kStyle(color: const Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i + 20, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
