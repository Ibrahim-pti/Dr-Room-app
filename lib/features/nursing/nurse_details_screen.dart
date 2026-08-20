import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:url_launcher/url_launcher.dart';

import 'nursing_services_screen.dart';

class NurseDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> nurse;

  const NurseDetailsScreen({
    super.key,
    required this.nurse,
  });

  @override
  State<NurseDetailsScreen> createState() => _NurseDetailsScreenState();
}

class _NurseDetailsScreenState extends State<NurseDetailsScreen> {
  bool _isFavorite = false;
  int _selectedTabIndex = 0; // 0: ناساندن, 1: پسپۆڕییەکان, 2: ناونیشان

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
        return 'کلینیک';
      case 'hospital':
        return 'نەخۆشخانە';
      case 'home_nursing':
      default:
        return 'پەرستاری ماڵەوە';
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

  void _openDirections(double lat, double lng) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final isArabic = lang == 'ar';
    final isEnglish = lang == 'en';
    final nurse = widget.nurse;

    final name = (isArabic &&
                nurse['name_ar'] != null &&
                nurse['name_ar'].toString().isNotEmpty)
            ? nurse['name_ar']
            : (isEnglish &&
                    nurse['name_en'] != null &&
                    nurse['name_en'].toString().isNotEmpty)
                ? nurse['name_en']
                : (nurse['name'] ?? '');

    final specialty = (isArabic &&
                nurse['specialty_ar'] != null &&
                nurse['specialty_ar'].toString().isNotEmpty)
            ? nurse['specialty_ar']
            : (isEnglish &&
                    nurse['specialty_en'] != null &&
                    nurse['specialty_en'].toString().isNotEmpty)
                ? nurse['specialty_en']
                : (nurse['specialty'] ?? '');

    final bio = (isArabic &&
                nurse['bio_ar'] != null &&
                nurse['bio_ar'].toString().isNotEmpty)
            ? nurse['bio_ar']
            : (isEnglish &&
                    nurse['bio_en'] != null &&
                    nurse['bio_en'].toString().isNotEmpty)
                ? nurse['bio_en']
                : (nurse['bio'] ?? '');

    final address = (isArabic &&
                nurse['address_ar'] != null &&
                nurse['address_ar'].toString().isNotEmpty)
            ? nurse['address_ar']
            : (isEnglish &&
                    nurse['address_en'] != null &&
                    nurse['address_en'].toString().isNotEmpty)
                ? nurse['address_en']
                : (nurse['address'] ?? '');

    final image = nurse['image'];
    final phone = nurse['phone']?.toString() ?? '';
    final isAvailable = nurse['is_available'] == true;
    final fee = nurse['fee'];
    final city = nurse['city']?.toString() ?? '';
    final serviceType = nurse['service_type']?.toString();
    final customServices = nurse['custom_services'] as List<dynamic>? ?? [];

    final double? lat = nurse['latitude'] != null
        ? double.tryParse(nurse['latitude'].toString())
        : null;
    final double? lng = nurse['longitude'] != null
        ? double.tryParse(nurse['longitude'].toString())
        : null;

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
      if (cs is Map &&
          cs['name'] != null &&
          cs['name'].toString().isNotEmpty) {
        final csName = (isArabic &&
                    cs['name_ar'] != null &&
                    cs['name_ar'].toString().isNotEmpty)
                ? cs['name_ar']
                : (isEnglish &&
                        cs['name_en'] != null &&
                        cs['name_en'].toString().isNotEmpty)
                    ? cs['name_en']
                    : cs['name'].toString();
        if (!allSpecialties.contains(csName)) {
          allSpecialties.add(csName);
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Hero Image Banner ──
                _buildHeroBanner(image, isAvailable, name),
                const SizedBox(height: 12),

                // ── 2. Nurse Main Identity Card ──
                _buildIdentityCard(
                    name, city, specialty.toString(), serviceType, fee),
                const SizedBox(height: 10),

                // ── 3. Quick Action Buttons (Call, Map, Request) ──
                _buildActionButtons(phone, lat, lng),
                const SizedBox(height: 14),

                // ── 4. Segmented Tab Bar ──
                _buildTabsHeader(allSpecialties.length),
                const SizedBox(height: 14),

                // ── 5. Dynamic Tab Content ──
                if (_selectedTabIndex == 0) ...[
                  // 📋 Tab 1: ناساندن (About)
                  _buildHighlightFeatures(fee, serviceType, isAvailable),
                  const SizedBox(height: 12),
                  if (bio.isNotEmpty) ...[
                    _buildAboutSection(bio),
                    const SizedBox(height: 14),
                  ],
                  if (phone.isNotEmpty) ...[
                    _buildContactSection(phone),
                    const SizedBox(height: 14),
                  ],
                ] else if (_selectedTabIndex == 1) ...[
                  // 🩺 Tab 2: پسپۆڕییەکان (Specialties)
                  _buildSpecialtiesSection(allSpecialties),
                ] else ...[
                  // 📍 Tab 3: ناونیشان (Location)
                  _buildLocationSection(
                      address, city, lat, lng),
                ],
              ],
            ),
          ),

          // ── Sticky Bottom Request Button ──
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _buildBottomRequestBar(fee, nurse),
          ),
        ],
      ),
    );
  }

  // ─── AppBar (same style as lab) ───
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF8FAFC),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF0F172A),
                size: 16,
              ),
            ),
          ),
        ),
      ),
      title: Text(
        'وردەکاریی پەرستار',
        style: _kStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF0F172A),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
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
                    : const Color(0xFF0F172A),
                size: 19,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Hero Image Banner ───
  Widget _buildHeroBanner(dynamic image, bool isAvailable, String name) {
    return Container(
      height: 190,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image or Gradient Placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: image != null && image.toString().isNotEmpty
                ? Image.network(
                    image.toString(),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildHeroPlaceholder(name),
                  )
                : _buildHeroPlaceholder(name),
          ),

          // Bottom Gradient Shadow
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.5),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Availability Badge (Top Start)
          PositionedDirectional(
            top: 12,
            start: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isAvailable
                      ? [const Color(0xFF10B981), const Color(0xFF059669)]
                      : [const Color(0xFF94A3B8), const Color(0xFF64748B)],
                ),
                borderRadius: BorderRadius.circular(9),
                boxShadow: [
                  BoxShadow(
                    color: (isAvailable
                            ? const Color(0xFF10B981)
                            : const Color(0xFF94A3B8))
                        .withValues(alpha: 0.4),
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
                        ? Icons.check_circle
                        : Icons.cancel_rounded,
                    color: Colors.white,
                    size: 11,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isAvailable ? 'ئامادەیە' : 'بەردەست نییە',
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

          // Nurse Name on image (Bottom Start)
          PositionedDirectional(
            bottom: 14,
            start: 16,
            end: 16,
            child: Text(
              name,
              style: _kStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scaleXY(begin: 0.98);
  }

  Widget _buildHeroPlaceholder(String name) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D9488), Color(0xFF115E59)],
        ),
      ),
      child: Stack(
        children: [
          // Pattern overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(painter: _PatternPainter()),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Iconsax.health,
                      color: Colors.white, size: 32),
                ),
                const SizedBox(height: 8),
                Text(
                  name.isNotEmpty
                      ? name.split(' ').first
                      : 'پەرستار',
                  style: _kStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
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

  // ─── Identity Card ───
  Widget _buildIdentityCard(
    String name,
    String city,
    String specialty,
    String? serviceType,
    dynamic fee,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Name Centered
          Text(
            name,
            textAlign: TextAlign.center,
            style: _kStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),

          // Location & Service Type Centered Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (city.isNotEmpty) ...[
                const Icon(Iconsax.location,
                    color: Color(0xFF0D9488), size: 14),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    _cityKurdish(city),
                    style: _kStyle(
                        color: const Color(0xFF475569), fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Iconsax.hospital,
                      color: Color(0xFF0D9488),
                      size: 13,
                    ),
                    const SizedBox(width: 2.5),
                    Text(
                      _serviceTypeKurdish(serviceType),
                      style: _kStyle(
                        color: const Color(0xFF0F766E),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Specialty subtitle
          if (specialty.isNotEmpty)
            Text(
              specialty.split(RegExp(r'[،,]')).first.trim(),
              textAlign: TextAlign.center,
              style: _kStyle(
                color: const Color(0xFF64748B),
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05);
  }

  // ─── Action Buttons Row ───
  Widget _buildActionButtons(String phone, double? lat, double? lng) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Iconsax.call,
            label: 'پەیوەندی',
            color: const Color(0xFF3B82F6),
            bgColor: const Color(0xFFEFF6FF),
            onTap: () {
              if (phone.isNotEmpty) _makePhoneCall(phone);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            icon: Iconsax.map,
            label: 'نەخشە',
            color: const Color(0xFF8B5CF6),
            bgColor: const Color(0xFFF5F3FF),
            onTap: () {
              if (lat != null && lng != null) {
                _openDirections(lat, lng);
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            icon: Iconsax.calendar_tick,
            label: 'داواکردن',
            color: const Color(0xFF0D9488),
            bgColor: const Color(0xFFF0FDFA),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NursingServicesScreen(
                    nurse: widget.nurse,
                    nurseId: widget.nurse['id'],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 3),
            Text(
              label,
              style: _kStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tab Bar ───
  Widget _buildTabsHeader(int specialtiesCount) {
    final tabs = [
      {'id': 0, 'title': 'ناساندن', 'icon': Iconsax.info_circle},
      {
        'id': 1,
        'title': 'پسپۆڕییەکان ($specialtiesCount)',
        'icon': Iconsax.health,
      },
      {
        'id': 2,
        'title': 'ناونیشان',
        'icon': Iconsax.location,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: tabs.map((t) {
          final int id = t['id'] as int;
          final bool isSelected = _selectedTabIndex == id;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
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
                          ? const Color(0xFF0D9488)
                          : const Color(0xFF64748B),
                      size: 15,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        t['title'] as String,
                        style: _kStyle(
                          color: isSelected
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF64748B),
                          fontSize: 11.5,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
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

  // ─── Tab 1: ناساندن (About) ───

  Widget _buildHighlightFeatures(
      dynamic fee, String? serviceType, bool isAvailable) {
    final feeStr = fee != null
        ? '${double.tryParse(fee.toString())?.toInt() ?? fee} د.ع'
        : 'دیارینەکراوە';

    final highlights = [
      {
        'icon': Iconsax.card,
        'title': feeStr,
        'desc': 'نرخی خزمەتگوزاری',
        'color': const Color(0xFFF59E0B),
      },
      {
        'icon': Iconsax.home_2,
        'title': _serviceTypeKurdish(serviceType),
        'desc': 'جۆری خزمەتگوزاری',
        'color': const Color(0xFF0D9488),
      },
    ];

    return Row(
      children: highlights.map((h) {
        final color = h['color'] as Color;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(h['icon'] as IconData,
                      color: color, size: 17),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        h['title'] as String,
                        style: _kStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        h['desc'] as String,
                        style: _kStyle(
                          fontSize: 10,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAboutSection(String bio) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Iconsax.user,
                color: Color(0xFF0D9488),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'دەربارەی پەرستار و ئەزموون',
                style: _kStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            bio,
            style: _kStyle(
              fontSize: 13.5,
              color: const Color(0xFF475569),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(String phone) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Iconsax.call,
                color: Color(0xFF3B82F6), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ژمارەی پەیوەندی',
                  style: _kStyle(
                      color: const Color(0xFF64748B), fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  phone,
                  style: _kStyle(
                    color: const Color(0xFF0F172A),
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6)
                        .withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                'پەیوەندی',
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

  // ─── Tab 2: پسپۆڕییەکان (Specialties) ───
  Widget _buildSpecialtiesSection(List<String> allSpecialties) {
    if (allSpecialties.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Icon(Iconsax.health,
                color: Color(0xFF94A3B8), size: 40),
            const SizedBox(height: 12),
            Text(
              'هیچ پسپۆڕییەک زیادنەکراوە',
              style: _kStyle(
                  color: const Color(0xFF94A3B8), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.health,
                  color: Color(0xFF0D9488), size: 18),
              const SizedBox(width: 8),
              Text(
                'پسپۆڕی و بوارەکان (${allSpecialties.length})',
                style: _kStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...allSpecialties.asMap().entries.map((entry) {
            final idx = entry.key;
            final s = entry.value;
            final colors = [
              const Color(0xFF0D9488),
              const Color(0xFF3B82F6),
              const Color(0xFF8B5CF6),
              const Color(0xFFF59E0B),
              const Color(0xFFEF4444),
              const Color(0xFF10B981),
            ];
            final color = colors[idx % colors.length];

            return Container(
              width: double.infinity,
              margin: EdgeInsets.only(
                  bottom: idx < allSpecialties.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: color.withValues(alpha: 0.2)),
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
                    child: Icon(Icons.check_circle,
                        color: color, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s,
                      style: _kStyle(
                        color: const Color(0xFF0F172A),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(Iconsax.arrow_left_2,
                      color: color.withValues(alpha: 0.5), size: 16),
                ],
              ),
            ).animate().fadeIn(delay: (idx * 80).ms).slideX(begin: -0.05);
          }),
        ],
      ),
    );
  }

  // ─── Tab 3: ناونیشان (Location) ───
  Widget _buildLocationSection(
    String address,
    String city,
    double? lat,
    double? lng,
  ) {
    return Column(
      children: [
        // Address Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Iconsax.location,
                      color: Color(0xFF8B5CF6), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'ناونیشان و شوێن',
                    style: _kStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // City
              if (city.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFF8B5CF6)
                            .withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6)
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Iconsax.building_3,
                            color: Color(0xFF8B5CF6), size: 16),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'شار: ',
                        style: _kStyle(
                          color: const Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _cityKurdish(city),
                        style: _kStyle(
                          color: const Color(0xFF0F172A),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              // Address
              if (address.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDFA),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFF0D9488)
                            .withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488)
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Iconsax.map_1,
                            color: Color(0xFF0D9488), size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          address,
                          style: _kStyle(
                            color: const Color(0xFF1E293B),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Map Directions Button
              if (lat != null && lng != null) ...[
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => _openDirections(lat, lng),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF8B5CF6),
                          Color(0xFF7C3AED),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6)
                              .withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.directions,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'کردنەوە لەسەر نەخشە',
                          style: _kStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ─── Sticky Bottom Request Bar ───
  Widget _buildBottomRequestBar(dynamic fee, Map<String, dynamic> nurse) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (fee != null) ...[
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'نرخی خزمەتگوزاری',
                  style: _kStyle(
                      color: const Color(0xFF64748B), fontSize: 10),
                ),
                const SizedBox(height: 2),
                Text(
                  '${double.tryParse(fee.toString())?.toInt() ?? fee} د.ع',
                  style: _kStyle(
                    color: const Color(0xFF0D9488),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: GestureDetector(
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
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D9488)
                          .withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Iconsax.calendar_tick,
                        color: Colors.white, size: 17),
                    const SizedBox(width: 8),
                    Text(
                      'داواکردنی خزمەتگوزاری',
                      style: _kStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
