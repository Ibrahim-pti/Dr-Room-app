import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../theme/dr_room_fonts.dart';

class NoInternetWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? message;

  const NoInternetWidget({
    super.key,
    this.onRetry,
    this.message,
  });

  TextStyle _kStyle({
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
  }) {
    return DrRoomFonts.primary(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFDBEAFE),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 42,
                color: Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'هێڵی ئینتەرنێت پچڕاوە',
              style: _kStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text(
              message ?? 'تکایە دڵنیابە لە پەیوەستبوونت بە ئینتەرنێت و دووبارە هەوڵبدەرەوە.',
              style: _kStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            if (onRetry != null)
              SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Iconsax.refresh, size: 18),
                  label: Text(
                    'دووبارە هەوڵبدەرەوە',
                    style: _kStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
