import 'package:flutter/material.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import '../../core/theme/app_colors.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:convert';
import '../../core/utils/api_client.dart';
import 'article_details_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  List<dynamic> _articles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchArticles();
  }

  Future<void> _fetchArticles() async {
    try {
      final response = await ApiClient.get('/articles');
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _articles = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } finally {
      if (mounted && _articles.length < 4) {
        setState(() {
          _articles.addAll([
            {
              'id': 101,
              'title': 'The Importance of Blood Donation',
              'category': 'HEALTH',
              'author': 'Dr. Sara Ahmed',
              'image_path': null,
              'color': const Color(0xFFEF4444),
            },
            {
              'id': 102,
              'title': 'How to maintain a healthy heart',
              'category': 'CARDIOLOGY',
              'author': 'Dr. Hekmat Jalal',
              'image_path': null,
              'color': const Color(0xFF3B82F6),
            },
            {
              'id': 103,
              'title': '5 Tips for Better Sleep at Night',
              'category': 'WELLNESS',
              'author': 'Dr. Ava Karim',
              'image_path': null,
              'color': const Color(0xFF8B5CF6),
            },
            {
              'id': 104,
              'title': 'Proper Nutrition for Kids',
              'category': 'NUTRITION',
              'author': 'Dr. Roni Yousif',
              'image_path': null,
              'color': const Color(0xFF10B981),
            },
          ]);
          _isLoading = false;
        });
      }
    }
  }

  String _getTranslated(dynamic article, String field, String langCode) {
    if (langCode == 'en' && article['${field}_en'] != null) {
      return article['${field}_en'];
    }
    if (langCode == 'ar' && article['${field}_ar'] != null) {
      return article['${field}_ar'];
    }
    return article[field] ?? '';
  }

  final List<Map<String, String>> _categories = const [
    {'name': 'All', 'icon': 'All'},
    {'name': 'Nutrition', 'icon': '🍏'},
    {'name': 'Fitness', 'icon': '💪'},
    {'name': 'Mental', 'icon': '🧠'},
    {'name': 'Sleep', 'icon': '😴'},
  ];

  final List<Map<String, dynamic>> _healthPackages = [
    {
      'title': 'Full Body Checkup',
      'clinic': 'Dr-Room Lab',
      'original_price': '\$150',
      'discount_price': '\$99',
      'discount_percent': '34%',
      'color': const Color(0xFF10B981), // Emerald
      'icon': Icons.medical_services_outlined,
      'features': ['Blood Test', 'Liver Function', 'Consultation'],
    },
    {
      'title': 'Heart Health Package',
      'clinic': 'Cardio Care',
      'original_price': '\$200',
      'discount_price': '\$140',
      'discount_percent': '30%',
      'color': const Color(0xFFEF4444), // Red
      'icon': Icons.favorite_outline,
      'features': ['ECG', 'Cholesterol Test', 'Cardiologist Visit'],
    },
    {
      'title': 'Vitamin Deficiency',
      'clinic': 'BioLab',
      'original_price': '\$80',
      'discount_price': '\$50',
      'discount_percent': '37%',
      'color': const Color(0xFFF59E0B), // Amber
      'icon': Icons.biotech_outlined,
      'features': ['Vitamin D', 'Vitamin B12', 'Iron Profile'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final langCode = context.locale.languageCode;
    
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              
              // ── Custom Header ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'hello'.tr(),
                          style: GoogleFonts.poppins(
                            color: AppColors.getTextSubtitle(context),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'discover'.tr(),
                          style: GoogleFonts.poppins(
                            color: AppColors.getTextTitle(context),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.getSurface(context),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Iconsax.notification,
                            color: AppColors.getTextTitle(context),
                            size: 24,
                          ),
                          Positioned(
                            top: 12,
                            right: 14,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),

              const SizedBox(height: 24),

              // ── Modern Search Bar ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.getSurface(context),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Icon(
                        Iconsax.search_normal_1,
                        color: AppColors.getTextSubtitle(context),
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'search'.tr(),
                          style: GoogleFonts.poppins(
                            color: AppColors.getTextSubtitle(context),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        margin: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 32),

              // ── Categories ──
              SizedBox(
                height: 40,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = index == 0;
                    return Container(
                          margin: const EdgeInsetsDirectional.only(end: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF3B82F6)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF3B82F6)
                                  : AppColors.getBorder(context),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              if (cat['icon'] != 'All') ...[
                                Text(
                                  cat['icon']!,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                cat['name']!,
                                style: GoogleFonts.poppins(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.getTextTitle(context),
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: (50 * index).ms)
                        .slideX(begin: 0.2, end: 0);
                  },
                ),
              ),

              const SizedBox(height: 32),

              // ── Health Packages & Offers ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'health_packages'.tr(),
                      style: GoogleFonts.poppins(
                        color: AppColors.getTextTitle(context),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'see_all'.tr(),
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF3B82F6),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              SizedBox(
                height: 230,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _healthPackages.length,
                  itemBuilder: (context, index) {
                    final package = _healthPackages[index];
                    final Color pkgColor = package['color'];
                    
                    return Container(
                      width: 280,
                      margin: const EdgeInsetsDirectional.only(end: 16, bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.getSurface(context),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: pkgColor.withValues(alpha: 0.15),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: pkgColor.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          children: [
                            // Soft background gradient circle
                            Positioned(
                              right: -40,
                              top: -40,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: pkgColor.withValues(alpha: 0.1),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: pkgColor,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '-${package['discount_percent']}',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        package['icon'],
                                        color: pkgColor,
                                        size: 28,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    package['title'],
                                    style: GoogleFonts.poppins(
                                      color: AppColors.getTextTitle(context),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  // Features List
                                  ...((package['features'] as List<String>).take(3).map((feature) => 
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        children: [
                                          Icon(Icons.check_circle, color: pkgColor, size: 14),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              feature,
                                              style: GoogleFonts.poppins(
                                                color: AppColors.getTextSubtitle(context),
                                                fontSize: 12,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  )),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      Text(
                                        package['original_price'],
                                        style: GoogleFonts.poppins(
                                          color: AppColors.getTextSubtitle(context),
                                          fontSize: 14,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        package['discount_price'],
                                        style: GoogleFonts.poppins(
                                          color: pkgColor,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
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
                    ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.2, end: 0);
                  },
                ),
              ),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_articles.isNotEmpty) ...[


                // ── Recent Articles ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'articles'.tr(),
                    style: GoogleFonts.poppins(
                      color: AppColors.getTextTitle(context),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _articles.length > 1 ? _articles.length - 1 : 0,
                  itemBuilder: (context, index) {
                    final article = _articles[index + 1];
                    return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ArticleDetailsScreen(article: article),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsetsDirectional.only(bottom: 20),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.getSurface(context),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AppColors.getBorder(context),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: AppColors.getBackground(context),
                                    ),
                                    child: article['image_path'] != null
                                        ? Image.network(
                                            '${ApiClient.storageUrl}/${article['image_path']}',
                                            fit: BoxFit.cover,
                                          )
                                        : Image.asset(
                                            'assets/images/article${(index % 2) + 1}.jpg',
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: (article['color'] ?? const Color(0xFF3B82F6)).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          (article['category'] ?? 'ARTICLE')
                                              .toString()
                                              .toUpperCase(),
                                          style: GoogleFonts.poppins(
                                            color: article['color'] ?? const Color(0xFF3B82F6),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _getTranslated(
                                          article,
                                          'title',
                                          langCode,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          color: AppColors.getTextTitle(context),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Icon(
                                            Iconsax.user,
                                            size: 14,
                                            color: AppColors.getTextSubtitle(context),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              article['author'] ?? 'Dr. Room',
                                              style: GoogleFonts.poppins(
                                                color: AppColors.getTextSubtitle(
                                                  context,
                                                ),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
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
                        )
                        .animate()
                        .fadeIn(delay: (200 + (50 * index)).ms)
                        .slideX(begin: 0.1, end: 0);
                  },
                ),
              ],

              const SizedBox(height: 100), // Padding for bottom nav
            ],
          ),
        ),
      ),
    );
  }
}
