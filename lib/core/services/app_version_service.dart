import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/api_client.dart';
import '../theme/dr_room_fonts.dart';

class AppVersionService {
  static const String currentAppVersion = '1.0.0';

  static Future<void> checkAppVersion(BuildContext context) async {
    try {
      final response = await ApiClient.get('/app-version');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestVersion = data['latest_version']?.toString() ?? '1.0.0';
        final isForceUpdate = data['force_update'] == true;
        final updateTitle = data['update_title']?.toString() ?? 'وەشانی نوێ بەردەستە';
        final updateMessage = data['update_message']?.toString() ?? 'تکایە ئەپەکە نوێبکەرەوە.';
        final androidUrl = data['android_store_url']?.toString() ?? '';
        final iosUrl = data['ios_store_url']?.toString() ?? '';

        if (_isVersionLower(currentAppVersion, latestVersion) && context.mounted) {
          _showUpdateDialog(
            context,
            title: updateTitle,
            message: updateMessage,
            isForce: isForceUpdate,
            androidUrl: androidUrl,
            iosUrl: iosUrl,
          );
        }
      }
    } catch (_) {
      // Ignore version check network failure gracefully
    }
  }

  static bool _isVersionLower(String current, String latest) {
    try {
      final curParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final latParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < 3; i++) {
        final c = i < curParts.length ? curParts[i] : 0;
        final l = i < latParts.length ? latParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
    } catch (_) {}
    return false;
  }

  static void _showUpdateDialog(
    BuildContext context, {
    required String title,
    required String message,
    required bool isForce,
    required String androidUrl,
    required String iosUrl,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !isForce,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return PopScope(
          canPop: !isForce,
          child: AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            contentPadding: const EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.system_update_rounded, color: Color(0xFF0D9488), size: 36),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: DrRoomFonts.primary(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: DrRoomFonts.primary(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final urlStr = Theme.of(context).platform == TargetPlatform.iOS ? iosUrl : androidUrl;
                      final uri = Uri.parse(urlStr.isNotEmpty ? urlStr : 'https://drroom.app');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(
                      'نوێکردنەوە لە ستۆر (Update Now)',
                      style: DrRoomFonts.primary(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                if (!isForce) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'دواتر (Later)',
                      style: DrRoomFonts.primary(
                        fontSize: 12.5,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
