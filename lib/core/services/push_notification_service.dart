import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../utils/api_client.dart';
import '../../firebase_options.dart';
import '../../main.dart';
import '../../features/notifications/notifications_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('FCM Background message: ${message.messageId}');
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  bool _initialized = false;
  static OverlayEntry? _currentBannerEntry;

  Future<void> init() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;

      // Request notification permissions (iOS and Android 13+)
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('User granted notification permission: ${settings.authorizationStatus}');

      // Enable foreground notification presentation options for iOS
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Get FCM Token and register with backend
      final token = await messaging.getToken();
      if (token != null) {
        debugPrint('FCM Device Token: $token');
        await registerToken(token);
      }

      // Listen for token refresh
      messaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token refreshed: $newToken');
        registerToken(newToken);
      });

      // Handle foreground notifications (Top Banner)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Foreground notification received: ${message.notification?.title}');
        final title = message.notification?.title ?? message.data['title'] ?? 'ئاگادارکردنەوە';
        final body = message.notification?.body ?? message.data['message'] ?? '';
        
        _showTopBanner(title, body.toString());
      });

      // Handle notification opened from background / terminated
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Notification clicked: ${message.data}');
      });

      _initialized = true;
    } catch (e) {
      debugPrint('PushNotificationService init error: $e');
    }
  }

  /// Displays an animated iOS/Dynamic Island style Top Notification Banner
  void _showTopBanner(String title, String body) {
    final overlay = appNavigatorKey.currentState?.overlay;
    if (overlay == null) return;

    _currentBannerEntry?.remove();
    _currentBannerEntry = null;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _TopBannerWidget(
        title: title,
        body: body,
        onTap: () {
          appNavigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          );
        },
        onDismiss: () {
          if (_currentBannerEntry == entry) {
            entry.remove();
            _currentBannerEntry = null;
          }
        },
      ),
    );

    _currentBannerEntry = entry;
    overlay.insert(entry);
  }

  /// Sends the device token to the Laravel backend
  Future<void> registerToken(String token) async {
    try {
      final platform = kIsWeb
          ? 'web'
          : Platform.isIOS
              ? 'ios'
              : 'android';

      await ApiClient.post(
        '/device-tokens',
        body: {
          'token': token,
          'platform': platform,
          'device_name': Platform.operatingSystem,
        },
      );
    } catch (e) {
      debugPrint('Failed to register device token: $e');
    }
  }

  /// Re-sync device token after user logs in or switches account
  Future<void> reRegisterToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await registerToken(token);
      }
    } catch (e) {
      debugPrint('PushNotificationService reRegisterToken error: $e');
    }
  }
}

/// Floating Heads-Up Top Notification Banner
class _TopBannerWidget extends StatefulWidget {
  final String title;
  final String body;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _TopBannerWidget({
    required this.title,
    required this.body,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_TopBannerWidget> createState() => _TopBannerWidgetState();
}

class _TopBannerWidgetState extends State<_TopBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    // Auto-dismiss after 4.5 seconds
    Future.delayed(const Duration(milliseconds: 4500), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    if (!mounted) return;
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: SlideTransition(
          position: _offsetAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta != null && details.primaryDelta! < -4) {
                  _dismiss();
                }
              },
              onTap: () {
                _dismiss();
                widget.onTap();
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => const Icon(
                            Icons.notifications_active_rounded,
                            color: Color(0xFF3B82F6),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.title,
                                  style: const TextStyle(
                                    fontFamily: 'Rabar',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 14.5,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Dr-Room',
                                  style: TextStyle(
                                    color: Color(0xFF60A5FA),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (widget.body.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              widget.body,
                              style: const TextStyle(
                                fontFamily: 'Rabar',
                                color: Color(0xFFCBD5E1),
                                fontSize: 12.5,
                                height: 1.3,
                                fontWeight: FontWeight.normal,
                                decoration: TextDecoration.none,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}