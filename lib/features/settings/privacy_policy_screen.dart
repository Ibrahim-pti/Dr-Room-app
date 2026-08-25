import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/theme/dr_room_fonts.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  TextStyle _kStyle({
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? height,
  }) {
    return DrRoomFonts.primary(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgSurface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textTitle = isDark ? Colors.white : const Color(0xFF0F172A);
    final textBody = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: bgSurface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textTitle, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'سیاسەتی تایبەتمەندی',
          style: _kStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: textTitle),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
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
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Iconsax.shield_security, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'پاراستنی تەواوی زانیارییەکانت',
                          style: _kStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'لە دکتۆر ڕووم (Dr. Room)، زانیارییە تەندروستی و کەسییەکانت بە بەرزترین ستانداردەکانی ئاسایش و بە پارێزراوی هەڵدەگیرێن.',
                    style: _kStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.9), height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Policy Sections
            _buildPolicyCard(
              context,
              icon: Iconsax.document_text,
              title: '١. ئەو زانیارییانەی کۆیان دەکەینەوە',
              content:
                  '• زانیاری هەژمار: ناو، ژمارەی مۆبایل، و شار بۆ مەبەستی دروستکردنی هەژمار و گەیاندنی خزمەتگوزاری.\n• زانیاری تەندروستی: تۆماری ڕەچەتە، تاقیگە، و داواکاری پەرستاری تەنها بە ڕەزامەندی نەخۆش.\n• لۆکەیشن: تەنها بۆ دۆزینەوەی نزیکترین ناوەندی تەندروستی و پەرستاری ماڵەوە.',
              bgSurface: bgSurface,
              borderColor: borderColor,
              textTitle: textTitle,
              textBody: textBody,
            ),

            const SizedBox(height: 14),

            _buildPolicyCard(
              context,
              icon: Iconsax.lock,
              title: '٢. ئاسایش و نهێنی پارێزی',
              content:
                  'هەموو پەیوەندی و داتاکان بە پڕۆتۆکۆڵی پارێزراوی HTTPS و بە شێوازی Encrypted دەنێردرێن. بە هیچ جۆرێک زانیارییەکانت بە لایەنی سێیەم یان کۆمپانیاکانی ڕیکلام نافرۆشرێن.',
              bgSurface: bgSurface,
              borderColor: borderColor,
              textTitle: textTitle,
              textBody: textBody,
            ),

            const SizedBox(height: 14),

            // Medical disclaimer card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFFB45309), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ئاگاداری پزیشکی (Medical Disclaimer)',
                          style: _kStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF92400E)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'پشکنەری ڕەچەتەی ژیری دەستکرد و ڕێنماییەکان تەنها بۆ هاوکاری سەرەتایین و جێگرەوەی بڕیاری پزیشکی پسپۆڕ نین.',
                          style: _kStyle(fontSize: 12, color: const Color(0xFFB45309), height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            _buildPolicyCard(
              context,
              icon: Iconsax.trash,
              title: '٣. سڕینەوەی هەژمار (Account Deletion)',
              content:
                  'بەپێی یاسای نێودەوڵەتی، لە هەر کاتێکدا دەتوانیت هەژمارەکەت بسڕیتەوە لە بەشی Settings > Delete Account و سەرجەم داتاکانت بە تەواوی دەسڕدرێنەوە.',
              bgSurface: bgSurface,
              borderColor: borderColor,
              textTitle: textTitle,
              textBody: textBody,
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    required Color bgSurface,
    required Color borderColor,
    required Color textTitle,
    required Color textBody,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF0D9488), size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: _kStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textTitle),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: _kStyle(fontSize: 12.5, color: textBody, height: 1.6),
          ),
        ],
      ),
    );
  }
}
