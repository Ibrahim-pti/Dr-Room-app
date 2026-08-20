import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/api_client.dart';
import 'nurse_reviews_screen.dart';
import 'nursing_services_screen.dart';

class NurseDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> nurse;

  const NurseDetailsScreen({super.key, required this.nurse});

  @override
  State<NurseDetailsScreen> createState() => _NurseDetailsScreenState();
}

class _NurseDetailsScreenState extends State<NurseDetailsScreen> {
  bool _isFavorite = false;
  int _selectedTabIndex = 0; // 0: ناساندن, 1: پسپۆڕییەکان, 2: ناونیشان
  Map<String, dynamic> _nurseData = {};
  double _rating = 0.0;
  int _totalReviews = 0;
  List<dynamic> _reviews = [];

  @override
  void initState() {
    super.initState();
    _nurseData = Map<String, dynamic>.from(widget.nurse);
    _rating = double.tryParse(_nurseData['rating']?.toString() ?? '') ?? 0.0;
    _totalReviews = int.tryParse(_nurseData['total_reviews']?.toString() ?? '') ?? 0;
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    final nurseId = _nurseData['id'] ?? widget.nurse['id'];
    if (nurseId == null) return;
    try {
      final res = await ApiClient.get('/nurses/$nurseId/reviews');
      if (res.statusCode == 200 && mounted) {
        final decoded = jsonDecode(res.body);
        setState(() {
          _rating = double.tryParse(decoded['rating']?.toString() ?? '') ?? _rating;
          _totalReviews = int.tryParse(decoded['total_reviews']?.toString() ?? '') ?? _totalReviews;
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



  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final isArabic = lang == 'ar';
    final isEnglish = lang == 'en';
    final nurse = widget.nurse;

    final name =
        (isArabic &&
            nurse['name_ar'] != null &&
            nurse['name_ar'].toString().isNotEmpty)
        ? nurse['name_ar']
        : (isEnglish &&
              nurse['name_en'] != null &&
              nurse['name_en'].toString().isNotEmpty)
        ? nurse['name_en']
        : (nurse['name'] ?? '');

    final specialty =
        (isArabic &&
            nurse['specialty_ar'] != null &&
            nurse['specialty_ar'].toString().isNotEmpty)
        ? nurse['specialty_ar']
        : (isEnglish &&
              nurse['specialty_en'] != null &&
              nurse['specialty_en'].toString().isNotEmpty)
        ? nurse['specialty_en']
        : (nurse['specialty'] ?? '');

    final bio =
        (isArabic &&
            nurse['bio_ar'] != null &&
            nurse['bio_ar'].toString().isNotEmpty)
        ? nurse['bio_ar']
        : (isEnglish &&
              nurse['bio_en'] != null &&
              nurse['bio_en'].toString().isNotEmpty)
        ? nurse['bio_en']
        : (nurse['bio'] ?? '');

    final image = nurse['image'];
    final phone = nurse['phone']?.toString() ?? '';
    final isAvailable = nurse['is_available'] == true;
    final experienceYears = nurse['experience_years'];
    final fee = nurse['fee'];
    final rating = double.tryParse(nurse['rating']?.toString() ?? '') ?? 0.0;
    final totalReviews = int.tryParse(nurse['total_reviews']?.toString() ?? '') ?? 0;
    final nurseId = int.tryParse(nurse['id']?.toString() ?? '0') ?? 0;
    final city = nurse['city']?.toString() ?? '';
    final customServices = nurse['custom_services'] as List<dynamic>? ?? [];



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
        final csName =
            (isArabic &&
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Curved Hero Photo Header ──
            _buildHeroCurvedTop(
              image: image,
              isAvailable: isAvailable,
              name: name,
              city: city,
              specialty: specialty.toString(),
              experienceYears: experienceYears,
              rating: rating,
              totalReviews: totalReviews,
              nurseId: nurseId,
            ),
            const SizedBox(height: 18),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 2. Quick Action Buttons (Call, Review) ──
                  _buildActionButtons(phone),
                  const SizedBox(height: 14),

                  // ── 3. Segmented Tab Bar ──
                  _buildTabsHeader(allSpecialties.length),
                  const SizedBox(height: 14),

                  // ── 4. Dynamic Tab Content ──
                  if (_selectedTabIndex == 0) ...[
                    // 📋 Tab 1: دەربارەی پەرستار (About)
                    if (bio.isNotEmpty) ...[
                      _buildAboutSection(bio),
                      const SizedBox(height: 14),
                    ],
                    if (phone.isNotEmpty) ...[
                      _buildContactSection(phone),
                      const SizedBox(height: 14),
                    ],
                    _buildReviewsSection(nurseId, name),
                  ] else ...[
                    // 🩺 Tab 2: پسپۆڕییەکان (Specialties)
                    _buildSpecialtiesSection(allSpecialties),
                    const SizedBox(height: 14),
                    _buildServiceRequestCard(fee, nurse),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openReviews(int nurseId, String nurseName, dynamic rating) {
    if (nurseId <= 0) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NurseReviewsScreen(
          nurseId: nurseId,
          nurseName: nurseName,
          rating: (double.tryParse(rating?.toString() ?? '') ?? 0).toStringAsFixed(1),
        ),
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
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 16,
            left: 20,
            right: 20,
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
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'تکایە ئەستێرە دیاری بکە و ڕا و بۆچوونی خۆت بنووسە دەربارەی خزمەتگوزارییەکان:',
                style: _kStyle(fontSize: 12, color: const Color(0xFF64748B)),
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
                style: _kStyle(fontSize: 13, color: const Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText:
                      'سەرنج و بۆچوونی خۆت لێرە بنووسە (ئارەزوومەندانە)...',
                  hintStyle: _kStyle(
                    fontSize: 12,
                    color: const Color(0xFF94A3B8),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF0D9488),
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
                          final nurseId = _nurseData['id'] ?? widget.nurse['id'];
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

                            if ((res.statusCode == 200 || res.statusCode == 201)) {
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
                    backgroundColor: const Color(0xFF0D9488),
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
        ),
      ),
    );
  }

  // ─── Curved Hero Photo Header (Doctor Style with Perfect Notch Clearance) ───
  Widget _buildHeroCurvedTop({
    required dynamic image,
    required bool isAvailable,
    required String name,
    required String city,
    required String specialty,
    required dynamic experienceYears,
    required double rating,
    required int totalReviews,
    required int nurseId,
  }) {
    final topPadding = MediaQuery.of(context).padding.top;
    final heroHeight = 325.0 + topPadding;

    return Column(
      children: [
        // ── Curved Photo Container ──
        SizedBox(
          height: heroHeight,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Curved Image with top offset so head starts safely below the notch
              ClipPath(
                clipper: const HeroCurveClipper(),
                child: Container(
                  color: Colors.white,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Nurse image positioned slightly higher up
                      Positioned(
                        top: topPadding * 0.87,
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: image != null && image.toString().isNotEmpty
                            ? (image.toString().startsWith('http')
                                  ? Image.network(
                                      image.toString(),
                                      fit: BoxFit.cover,
                                      alignment: Alignment.topCenter,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              _buildHeroPlaceholder(name),
                                    )
                                  : Image.asset(
                                      image.toString(),
                                      fit: BoxFit.cover,
                                      alignment: Alignment.topCenter,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              _buildHeroPlaceholder(name),
                                    ))
                            : _buildHeroPlaceholder(name),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Floating Action Buttons (Clean Frosted/White Buttons)
              Positioned(
                top: topPadding + 8,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(
                              0xFFE2E8F0,
                            ).withValues(alpha: 0.8),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Color(0xFF0F172A),
                          size: 16,
                        ),
                      ),
                    ),

                    // Favorite Button
                    GestureDetector(
                      onTap: () {
                        setState(() => _isFavorite = !_isFavorite);
                      },
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(
                              0xFFE2E8F0,
                            ).withValues(alpha: 0.8),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 10,
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
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Name Centered (Matching Lab Details Screen) ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            name.isNotEmpty ? name : 'پەرستار',
            textAlign: TextAlign.center,
            style: _kStyle(
              fontSize: 18.5,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 6),

        // ── Location & Rating Centered Row (Exact like screenshot) ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.location, color: Color(0xFF3B82F6), size: 14),
            const SizedBox(width: 4),
            Text(
              _cityKurdish(city.isNotEmpty ? city : 'Erbil'),
              style: _kStyle(color: const Color(0xFF475569), fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _showReviewBottomSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFD97706),
                      size: 13,
                    ),
                    const SizedBox(width: 2.5),
                    Text(
                      _rating > 0 ? _rating.toStringAsFixed(1) : '5.0',
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
        const SizedBox(height: 8),

        // ── Badges Pill Row (Experience + Specialty + Status) ──
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (experienceYears != null &&
                  experienceYears.toString().isNotEmpty &&
                  experienceYears.toString() != '0') ...[
                _heroPill(
                  icon: Iconsax.award,
                  label: '$experienceYears ساڵ ئەزموون',
                  color: const Color(0xFF2563EB),
                  bgColor: const Color(0xFFEFF6FF),
                  borderColor: const Color(0xFFBFDBFE),
                ),
                const SizedBox(width: 8),
              ],
              if (specialty.isNotEmpty) ...[
                _heroPill(
                  icon: Iconsax.health,
                  label: specialty.split(RegExp(r'[،,]')).first.trim(),
                  color: const Color(0xFF0D9488),
                  bgColor: const Color(0xFFF0FDFA),
                  borderColor: const Color(0xFF99F6E4),
                ),
                const SizedBox(width: 8),
              ],
              _heroPill(
                icon: isAvailable
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                label: isAvailable ? 'ئامادەیە' : 'بەردەست نییە',
                color: isAvailable
                    ? const Color(0xFF10B981)
                    : const Color(0xFF94A3B8),
                bgColor: isAvailable
                    ? const Color(0xFFECFDF5)
                    : const Color(0xFFF1F5F9),
                borderColor: isAvailable
                    ? const Color(0xFFA7F3D0)
                    : const Color(0xFFE2E8F0),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heroPill({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
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
    );
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

  // ─── Action Buttons Row (Call, Review) ───
  Widget _buildActionButtons(String phone) {
    return Row(
      children: [
        // 1. Call
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
        const SizedBox(width: 10),

        // 2. Review / هەڵسەنگاندن
        Expanded(
          child: _buildActionButton(
            icon: Icons.star_rate_rounded,
            label: 'هەڵسەنگاندن',
            color: const Color(0xFFD97706),
            bgColor: const Color(0xFFFEF3C7),
            onTap: _showReviewBottomSheet,
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



  Widget _buildReviewsSection(int nurseId, String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: [ هەڵسەنگاندن و فیدباک ] & [ سەرنج بنووسە Button ]
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
                    'هەڵسەنگاندن و فیدباک ($_totalReviews)',
                    style: _kStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
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

          // Rating summary badge
          GestureDetector(
            onTap: () => _openReviews(nurseId, name, _rating),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      _rating > 0 ? _rating.toStringAsFixed(1) : '5.0',
                      style: _kStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
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
                          color: i < (_rating > 0 ? _rating.round() : 5)
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFCBD5E1),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'لەسەر بنەمای $_totalReviews هەڵسەنگاندن',
                      style: _kStyle(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Reviews List if available
          if (_reviews.isNotEmpty) ...[
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _reviews.length > 3 ? 3 : _reviews.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final rev = _reviews[index];
                final rName = rev['patient_name']?.toString() ?? 'نەخۆشێک';
                final rStars = int.tryParse(rev['rating']?.toString() ?? '') ?? 5;
                final rComment = rev['comment']?.toString() ?? '';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.12),
                          child: Text(
                            rName.isNotEmpty ? rName.characters.first : '؟',
                            style: _kStyle(
                              color: const Color(0xFF0D9488),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rName,
                            style: _kStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (starI) => Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: starI < rStars
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (rComment.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        rComment,
                        style: _kStyle(
                          fontSize: 12,
                          color: const Color(0xFF475569),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ],
      ),
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
              const Icon(Iconsax.user, color: Color(0xFF0D9488), size: 18),
              const SizedBox(width: 8),
              Text(
                'دەربارەی پەرستار',
                style: _kStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          if (bio.isNotEmpty) ...[
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
            child: const Icon(Iconsax.call, color: Color(0xFF3B82F6), size: 20),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.health, color: Color(0xFF0D9488), size: 18),
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
                    child: Icon(Icons.check_circle, color: color, size: 16),
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
                  Icon(
                    Iconsax.arrow_left_2,
                    color: color.withValues(alpha: 0.5),
                    size: 16,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: (idx * 80).ms).slideX(begin: -0.05);
          }),
        ],
      ),
    );
  }


  // ─── Service Request Card (Price + Request Button) ───
  Widget _buildServiceRequestCard(dynamic fee, Map<String, dynamic> nurse) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0FDFA), Color(0xFFECFDF5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF99F6E4)),
      ),
      child: Column(
        children: [
          if (fee != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Iconsax.money_recive,
                  color: Color(0xFF0D9488),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'نرخی خزمەتگوزاری',
                  style: _kStyle(
                    color: const Color(0xFF475569),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${double.tryParse(fee.toString())?.toInt() ?? fee} د.ع',
                  style: _kStyle(
                    color: const Color(0xFF0D9488),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          GestureDetector(
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
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Iconsax.calendar_tick,
                    color: Colors.white,
                    size: 17,
                  ),
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
        ],
      ),
    );
  }
}

class HeroCurveClipper extends CustomClipper<Path> {
  const HeroCurveClipper();

  static const double _sideInset = 48;
  static const double _sideCorner = 20;
  static const double _tipCorner = 26;

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final edge = h - _sideInset;
    final mid = w / 2;

    final slope = Offset(mid, h - edge);
    final length = slope.distance;
    final backX = mid * (_tipCorner / length);
    final backY = (h - edge) * (_tipCorner / length);

    return Path()
      ..lineTo(0, edge - _sideCorner)
      ..quadraticBezierTo(0, edge, _sideCorner, edge + _sideCorner * 0.35)
      ..lineTo(mid - backX, h - backY)
      ..quadraticBezierTo(mid, h, mid + backX, h - backY)
      ..lineTo(w - _sideCorner, edge + _sideCorner * 0.35)
      ..quadraticBezierTo(w, edge, w, edge - _sideCorner)
      ..lineTo(w, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
