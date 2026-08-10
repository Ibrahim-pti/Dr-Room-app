import 'package:flutter/material.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import '../../core/theme/app_colors.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:easy_localization/easy_localization.dart';
import 'dart:convert';
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
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getTranslated(dynamic notif, String field, String langCode) {
    if (langCode == 'en' && notif['${field}_en'] != null) {
      return notif['${field}_en'];
    }
    if (langCode == 'ar' && notif['${field}_ar'] != null) {
      return notif['${field}_ar'];
    }
    return notif[field] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final langCode = context.locale.languageCode;


    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, size: 20, color: AppColors.getTextTitle(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            color: AppColors.getTextTitle(context),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              'Mark all read',
              style: GoogleFonts.poppins(
                color: const Color(0xFF3B82F6),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
            ? Center(
                child: Text(
                  'No notifications yet',
                  style: GoogleFonts.poppins(color: AppColors.getTextSubtitle(context)),
                ),
              )
            : ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notif = notifications[index];
          final type = (notif['type'] ?? 'general') as String;
          final isRead = notif['is_read'] == 1 || notif['is_read'] == true;
          
          final timeString = notif['created_at'] != null 
              ? notif['created_at'].toString().substring(0, 10)
              : 'Just now';

          IconData icon;
          Color iconColor;
          Color bgColor;

          switch (type) {
            case 'order':
              icon = Iconsax.truck;
              iconColor = const Color(0xFFF59E0B);
              bgColor = const Color(0xFFF59E0B).withValues(alpha: 0.1);
              break;
            case 'result':
              icon = Iconsax.document_text;
              iconColor = const Color(0xFF3B82F6);
              bgColor = const Color(0xFF3B82F6).withValues(alpha: 0.1);
              break;
            case 'calendar':
              icon = Iconsax.calendar_1;
              iconColor = const Color(0xFF8B5CF6);
              bgColor = const Color(0xFF8B5CF6).withValues(alpha: 0.1);
              break;
            case 'promo':
              icon = Iconsax.ticket_discount;
              iconColor = const Color(0xFFEC4899);
              bgColor = const Color(0xFFEC4899).withValues(alpha: 0.1);
              break;
            case 'success':
              icon = Iconsax.tick_circle;
              iconColor = const Color(0xFF10B981);
              bgColor = const Color(0xFF10B981).withValues(alpha: 0.1);
              break;
            default:
              icon = Iconsax.notification;
              iconColor = const Color(0xFF64748B);
              bgColor = const Color(0xFF64748B).withValues(alpha: 0.1);
          }

          return Container(
            color: isRead ? Colors.transparent : const Color(0xFF3B82F6).withValues(alpha: 0.05),
            child: InkWell(
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  notif['title'] as String,
                                  style: GoogleFonts.poppins(
                                    color: AppColors.getTextTitle(context),
                                    fontSize: 16,
                                    fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (!isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsetsDirectional.only(top: 6),
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
                            style: GoogleFonts.poppins(
                              color: AppColors.getTextSubtitle(context),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            timeString,
                            style: GoogleFonts.poppins(
                              color: AppColors.textLight,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.1, end: 0);
        },
      ),
    );
  }
}
