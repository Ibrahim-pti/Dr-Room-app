import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../services/connectivity_service.dart';
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

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
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
                  color: Color(0xFFEF4444),
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
      ),
    );
  }
}

/// Global floating banner that reacts automatically to connectivity state changes
class GlobalInternetBannerWrapper extends StatefulWidget {
  final Widget child;
  const GlobalInternetBannerWrapper({super.key, required this.child});

  @override
  State<GlobalInternetBannerWrapper> createState() => _GlobalInternetBannerWrapperState();
}

class _GlobalInternetBannerWrapperState extends State<GlobalInternetBannerWrapper> {
  bool _isChecking = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ValueListenableBuilder<bool>(
        valueListenable: ConnectivityService.instance.isConnected,
        builder: (context, isOnline, _) {
          return Directionality(
            textDirection: Directionality.maybeOf(context) ?? TextDirection.rtl,
            child: Stack(
              children: [
                widget.child,
                if (!isOnline)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      bottom: false,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'هێڵی ئینتەرنێت پچڕاوە',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: DrRoomFonts.primary(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _isChecking
                                  ? null
                                  : () async {
                                      setState(() => _isChecking = true);
                                      await ConnectivityService.instance.checkRealInternet();
                                      if (mounted) setState(() => _isChecking = false);
                                    },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: _isChecking
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Iconsax.refresh, color: Colors.white, size: 13),
                                          const SizedBox(width: 4),
                                          Text(
                                            'دووبارە',
                                            style: DrRoomFonts.primary(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
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
        },
      ),
    );
  }
}
