import 'package:flutter/material.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import '../../core/theme/app_colors.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';

class ArticleDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> article;

  const ArticleDetailsScreen({super.key, required this.article});

  String _getTranslated(Map<String, dynamic> data, String field, String langCode) {
    if (langCode == 'en' && data['${field}_en'] != null) {
      return data['${field}_en'];
    }
    if (langCode == 'ar' && data['${field}_ar'] != null) {
      return data['${field}_ar'];
    }
    return data[field] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final langCode = context.locale.languageCode;
    final color = article['color'] ?? const Color(0xFF3B82F6);
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.getBackground(context),
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: AppColors.getSurface(context),
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.getTextTitle(context)),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: AppColors.getSurface(context),
                  child: IconButton(
                    icon: Icon(Iconsax.bookmark, size: 20, color: AppColors.getTextTitle(context)),
                    onPressed: () {},
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: AppColors.getSurface(context),
                  child: IconButton(
                    icon: Icon(Icons.share_outlined, size: 20, color: AppColors.getTextTitle(context)),
                    onPressed: () {},
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: article['title'],
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadiusDirectional.only(
                      bottomStart: Radius.circular(40),
                      bottomEnd: Radius.circular(40),
                    ),
                  ),
                  child: Center(
                    child: Icon(Iconsax.document, color: Colors.white.withValues(alpha: 0.3), size: 100),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      (article['category'] ?? 'ARTICLE').toString().toUpperCase(),
                      style: GoogleFonts.poppins(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 16),
                  Text(
                    _getTranslated(article, 'title', langCode),
                    style: GoogleFonts.poppins(
                      color: AppColors.getTextTitle(context),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE2E8F0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, color: Colors.grey),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            article['author'] ?? 'Dr. Room',
                            style: GoogleFonts.poppins(
                              color: AppColors.getTextTitle(context),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${"medical_specialist".tr()} • ${article['time'] ?? '5 min'}',
                            style: GoogleFonts.poppins(
                              color: AppColors.getTextSubtitle(context),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 24),
                  
                  Text(
                    _getTranslated(article, 'content', langCode),
                    style: GoogleFonts.poppins(
                      color: AppColors.getTextTitle(context),
                      fontSize: 16,
                      height: 1.8,
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
