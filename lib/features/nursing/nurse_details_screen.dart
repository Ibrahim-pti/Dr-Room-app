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
                // ── 1. Unified Nurse Profile Hero Card ──
                _buildUnifiedProfileHero(
                  image: image,
                  isAvailable: isAvailable,
                  name: name,
                  city: city,
                  specialty: specialty.toString(),
                  serviceType: serviceType,
                  fee: fee,
                ),
                const SizedBox(height: 12),

                // ── 2. Quick Action Buttons (Call, Map, Request) ──
                _buildActionButtons(phone, lat, lng),
                const SizedBox(height: 14),

                // ── 3. Segmented Tab Bar ──
                _buildTabsHeader(allSpecialties.length),
                const SizedBox(height: 14),

                // ── 4. Dynamic Tab Content ──
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

  // ─── Clean Nurse Profile Hero Card ───
  Widget _buildUnifiedProfileHero({
    required dynamic image,
    required bool isAvailable,
    required String name,
    required String city,
    required String specialty,
    required String? serviceType,
    required dynamic fee,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Row: Status Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Availability Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isAvailable
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isAvailable
                        ? const Color(0xFFA7F3D0)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isAvailable
                            ? const Color(0xFF10B981)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isAvailable ? 'ئامادەیە بۆ وەرگرتنی داواکاری' : 'بەردەست نییە',
                      style: _kStyle(
                        color: isAvailable
                            ? const Color(0xFF047857)
                            : const Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Service Type Pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCCFBF1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.hospital,
                        color: Color(0xFF0D9488), size: 13),
                    const SizedBox(width: 4),
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

          const SizedBox(height: 16),

          // Nurse Avatar with Premium Double Ring
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D9488), Color(0xFF14B8A6), Color(0xFF5EEAD4)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: ClipOval(
                child: Container(
                  width: 104,
                  height: 104,
                  color: const Color(0xFFF8FAFC),
                  child: image != null && image.toString().isNotEmpty
                      ? (image.toString().startsWith('http')
                          ? Image.network(
                              image.toString(),
                              width: 104,
                              height: 104,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildHeroPlaceholder(name),
                            )
                          : Image.asset(
                              image.toString(),
                              width: 104,
                              height: 104,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildHeroPlaceholder(name),
                            ))
                      : _buildHeroPlaceholder(name),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Full Name
          Text(
            name.isNotEmpty ? name : 'پەرستار',
            textAlign: TextAlign.center,
            style: _kStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 5),

          // Specialty Title
          if (specialty.isNotEmpty)
            Text(
              specialty.split(RegExp(r'[،,]')).first.trim(),
              textAlign: TextAlign.center,
              style: _kStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0D9488),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

          const SizedBox(height: 12),

          // City & Fee Badges Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (city.isNotEmpty) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Iconsax.location,
                          color: Color(0xFF64748B), size: 13),
                      const SizedBox(width: 4),
                      Text(
                        _cityKurdish(city),
                        style: _kStyle(
                          color: const Color(0xFF334155),
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (fee != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Iconsax.card,
                          color: Color(0xFFD97706), size: 13),
                      const SizedBox(width: 4),
                      Text(
                        '${double.tryParse(fee.toString())?.toInt() ?? fee} د.ع',
                        style: _kStyle(
                          color: const Color(0xFFB45309),
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05);
  }

  Widget _buildHeroPlaceholder(String name) {
    return Container(
      color: const Color(0xFFF0FDFA),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.health, color: Color(0xFF0D9488), size: 36),
            if (name.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                name.split(' ').first,
                style: _kStyle(
                  color: const Color(0xFF0D9488),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
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
