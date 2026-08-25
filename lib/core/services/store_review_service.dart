import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/dr_room_fonts.dart';

class StoreReviewService {
  static const String androidPackageName = 'com.drroom.app';
  static const String appleAppId = '6400000000';

  static void openStoreReview([BuildContext? context]) async {
    final playStoreUrl = 'https://play.google.com/store/apps/details?id=$androidPackageName';
    final appStoreUrl = 'https://apps.apple.com/app/id$appleAppId?action=write-review';

    final isIOS = context != null && Theme.of(context).platform == TargetPlatform.iOS;
    final urlStr = isIOS ? appStoreUrl : playStoreUrl;

    final uri = Uri.parse(urlStr);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static void showInAppReviewPrompt(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                'ئایا لە ئەزموونی دکتۆر ڕووم ڕازیت؟',
                style: DrRoomFonts.primary(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'هەڵسەنگاندنەکەت لە پلەی ستۆر و ئەپ ستۆر هاوکارمان دەبێت بۆ باشترکردنی خزمەتگوزارییە تەندروستییەکان.',
                style: DrRoomFonts.primary(
                  fontSize: 12.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 32),
                  );
                }),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    openStoreReview();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    'هەڵسەنگاندن لە ستۆر (Rate on Store)',
                    style: DrRoomFonts.primary(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'دواتر',
                  style: DrRoomFonts.primary(
                    fontSize: 12.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
