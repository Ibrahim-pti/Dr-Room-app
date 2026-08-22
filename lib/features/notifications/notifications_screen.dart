import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:convert';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_client.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final response = await ApiClient.get('/notifications');
      if (response.statusCode == 200 && mounted) {
        setState(() {
          notifications = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await ApiClient.post('/notifications/mark-read');
      if (mounted) {
        setState(() {
          for (var item in notifications) {
            item['is_read'] = true;
          }
        });
      }
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  Future<void> _deleteNotification(int id, int index) async {
    try {
      final response = await ApiClient.delete('/notifications/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        if (mounted) {
          setState(() {
            notifications.removeAt(index);
          });
        }
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  String _getTranslated(dynamic notif, String field, String langCode) {
    if (langCode == 'en' && notif['${field}_en'] != null && notif['${field}_en'].toString().isNotEmpty) {
      return notif['${field}_en'];
    }
    if (langCode == 'ar' && notif['${field}_ar'] != null && notif['${field}_ar'].toString().isNotEmpty) {
      return notif['${field}_ar'];
    }
    return notif[field] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final langCode = context.locale.languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isKurdishOrArabic = langCode == 'ckb' || langCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(context),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            size: 20,
            color: AppColors.getTextTitle(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'notifications'.tr(),
          style: TextStyle(
            color: AppColors.getTextTitle(context),
            fontFamily: isKurdishOrArabic ? 'Rabar' : null,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'mark_all_read'.tr(),
                style: TextStyle(
                  color: const Color(0xFF3B82F6),
                  fontFamily: isKurdishOrArabic ? 'Rabar' : null,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Iconsax.notification_bing,
                          color: Color(0xFF3B82F6),
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'no_notifications'.tr(),
                        style: TextStyle(
                          color: AppColors.getTextSubtitle(context),
                          fontFamily: isKurdishOrArabic ? 'Rabar' : null,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  color: const Color(0xFF3B82F6),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      final type = (notif['type'] ?? 'general') as String;
                      final isRead = notif['is_read'] == 1 || notif['is_read'] == true;
                      final imagePath = notif['image_path'] as String?;
                      final hasImage = imagePath != null && imagePath.trim().isNotEmpty;
                      final notifId = notif['id'];
                      final isPersonal = notif['user_id'] != null;

                      final timeString = notif['created_at'] != null
                          ? notif['created_at'].toString().substring(0, 10)
                          : '';

                      IconData icon;
                      Color iconColor;
                      Color bgColor;

                      switch (type) {
                        case 'order':
                        case 'order_update':
                        case 'order_status_update':
                          icon = Iconsax.truck;
                          iconColor = const Color(0xFFF59E0B);
                          bgColor = const Color(0xFFF59E0B).withValues(alpha: 0.12);
                          break;
                        case 'result':
                        case 'lab_result':
                          icon = Iconsax.document_text;
                          iconColor = const Color(0xFF3B82F6);
                          bgColor = const Color(0xFF3B82F6).withValues(alpha: 0.12);
                          break;
                        case 'calendar':
                        case 'appointment':
                          icon = Iconsax.calendar_1;
                          iconColor = const Color(0xFF8B5CF6);
                          bgColor = const Color(0xFF8B5CF6).withValues(alpha: 0.12);
                          break;
                        case 'promo':
                          icon = Iconsax.ticket_discount;
                          iconColor = const Color(0xFFEC4899);
                          bgColor = const Color(0xFFEC4899).withValues(alpha: 0.12);
                          break;
                        case 'system':
                        case 'success':
                          icon = Iconsax.tick_circle;
                          iconColor = const Color(0xFF10B981);
                          bgColor = const Color(0xFF10B981).withValues(alpha: 0.12);
                          break;
                        default:
                          icon = Iconsax.notification;
                          iconColor = const Color(0xFF3B82F6);
                          bgColor = const Color(0xFF3B82F6).withValues(alpha: 0.12);
                      }

                      return Dismissible(
                        key: ValueKey(notifId ?? index),
                        direction: isPersonal ? DismissDirection.endToStart : DismissDirection.none,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Iconsax.trash, color: Colors.white, size: 22),
                        ),
                        onDismissed: (_) {
                          if (notifId != null) {
                            _deleteNotification(notifId, index);
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.getSurface(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isRead
                                  ? AppColors.getBorder(context)
                                  : const Color(0xFF3B82F6).withValues(alpha: 0.35),
                              width: isRead ? 1 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.15)
                                    : Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: bgColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(icon, color: iconColor, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  _getTranslated(notif, 'title', langCode),
                                                  style: TextStyle(
                                                    color: AppColors.getTextTitle(context),
                                                    fontFamily: isKurdishOrArabic ? 'Rabar' : null,
                                                    fontSize: 15,
                                                    fontWeight: isRead
                                                        ? FontWeight.w600
                                                        : FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              if (!isRead)
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFF3B82F6),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _getTranslated(notif, 'message', langCode),
                                            style: TextStyle(
                                              color: AppColors.getTextSubtitle(context),
                                              fontFamily: isKurdishOrArabic ? 'Rabar' : null,
                                              fontSize: 13,
                                              height: 1.45,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (hasImage) ...[
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      ApiClient.getImageUrl(imagePath),
                                      width: double.infinity,
                                      height: 160,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
                                    ),
                                  ),
                                ],
                                if (timeString.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: Text(
                                      timeString,
                                      style: TextStyle(
                                        color: AppColors.textLight,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: (40 * index).ms).slideY(begin: 0.05, end: 0);
                    },

                  ),
                ),
    );
  }
}
