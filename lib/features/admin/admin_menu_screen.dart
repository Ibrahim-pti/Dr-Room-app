import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/api_client.dart';
import '../../core/utils/admin_permissions.dart';
import '../../core/theme/app_colors.dart';
import '../../main.dart';
import 'admin_users_screen.dart';
import 'admin_staff_screen.dart';
import 'admin_activity_log_screen.dart';
import 'admin_reviews_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_transactions_screen.dart';
import 'admin_banners_screen.dart';
import 'admin_notifications_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_appointments_screen.dart';
import 'admin_xrays_screen.dart';
import 'admin_app_bar.dart';

class AdminMenuScreen extends StatefulWidget {
  const AdminMenuScreen({super.key});

  @override
  State<AdminMenuScreen> createState() => _AdminMenuScreenState();
}

class _AdminMenuScreenState extends State<AdminMenuScreen> {
  bool _isLoading = false;

  Future<void> _logout() async {
    setState(() => _isLoading = true);
    try {
      await ApiClient.post('/logout');
    } catch (e) {
      debugPrint('Logout api error: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AppFlow()),
      (route) => false,
    );
  }

  Future<void> _deleteAccount() async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.getSurface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'سڕینەوەی هەژمار',
          style: TextStyle(
            color: AppColors.error,
            fontFamily: 'Rabar',
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.right,
        ),
        content: Text(
          'ئایا دڵنیایت لە سڕینەوەی هەژمارەکەت؟ ئەم کردارە پاشگەزبوونەوەی تێدا نییە.',
          style: TextStyle(
            color: AppColors.getTextTitle(context),
            fontFamily: 'Rabar',
          ),
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'نەخێر',
              style: TextStyle(
                fontFamily: 'Rabar',
                color: AppColors.getTextSubtitle(context),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'بەڵێ، بسڕەوە',
              style: TextStyle(fontFamily: 'Rabar', color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await ApiClient.delete('/user');
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AppFlow()),
          (route) => false,
        );
      } catch (e) {
        setState(() => _isLoading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('کێشەیەک ڕوویدا لە کاتی سڕینەوە')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sections = _visibleSections();

    return _buildScaffold(context, sections);
  }

  /// Filters the menu down to what the signed-in staff account may open.
  List<Map<String, dynamic>> _visibleSections() {
    final all = [
      {
        'sectionTitle': 'بەڕێوەبردنی ناوەڕۆک و خزمەتگوزارییەکان',
        'items': [
          {
            'title': 'بانەر و ڕیکلامەکان',
            'permission': AdminPermissions.manageContent,
            'subtitle': 'بەڕێوەبردنی بانەرەکانی سەرەکی',
            'icon': Iconsax.slider_horizontal,
            'color': const Color(0xFF6366F1),
            'screen': const AdminBannersScreen(),
          },
          {
            'title': 'ئاگاداری گشتی (Push Notification)',
            'permission': AdminPermissions.manageContent,
            'subtitle': 'ناردنی پەیام بۆ هەموو بەکارهێنەران',
            'icon': Iconsax.notification_bing,
            'color': const Color(0xFFD97706),
            'screen': const AdminNotificationsScreen(),
          },
          {
            'title': 'داواکارییەکانی نەخۆش',
            'permission': AdminPermissions.manageOrders,
            'subtitle': 'بەڕێوەبردن و دابەشکردنی ئۆردەرەکان',
            'icon': Iconsax.box,
            'color': const Color(0xFF10B981),
            'screen': const AdminOrdersScreen(),
          },
          {
            'title': 'نۆرە و چاوپێکەوتنەکان',
            'permission': AdminPermissions.manageOrders,
            'subtitle': 'تەواوی نۆرە تۆمارکراوەکانی پزیشک',
            'icon': Iconsax.calendar_1,
            'color': const Color(0xFFEC4899),
            'screen': const AdminAppointmentsScreen(),
          },
          {
            'title': 'کەتەگۆرییەکان',
            'permission': AdminPermissions.manageCategories,
            'subtitle': 'لیستەکانی پەرستاری، تاقیگە، دەرمانخانە و پزیشک',
            'icon': Iconsax.category,
            'color': const Color(0xFF0D9488),
            'screen': const AdminCategoriesScreen(),
          },
          {
            'title': 'هەڵسەنگاندن و کۆمێنتەکان',
            'permission': AdminPermissions.manageReviews,
            'subtitle': 'شاردنەوە و سڕینەوەی کۆمێنتی نەگونجاو',
            'icon': Iconsax.star,
            'color': const Color(0xFFD97706),
            'screen': const AdminReviewsScreen(),
          },
          {
            'title': 'مامەڵە و داهات',
            'permission': AdminPermissions.viewPayments,
            'subtitle': 'تۆماری پارەدان و ڕاپۆرتی داهات',
            'icon': Iconsax.wallet_3,
            'color': const Color(0xFF059669),
            'screen': const AdminTransactionsScreen(),
          },
          {
            'title': 'سەنتەرەکانی تیشک و سۆنەر',
            'permission': AdminPermissions.manageProviders,
            'subtitle': 'پەسەندکردن و بەڕێوەبردن',
            'icon': Iconsax.scan,
            'color': const Color(0xFF8B5CF6),
            'screen': const AdminXRaysScreen(),
          },
        ],
      },
      {
        'sectionTitle': 'بەکارهێنەران و دەسەڵاتەکان',
        'items': [
          {
            'title': 'بەکارهێنەرانی ئەپ',
            'permission': AdminPermissions.manageUsers,
            'subtitle': 'بینین و بلۆککردنی بەکارهێنەر',
            'icon': Iconsax.people,
            'color': const Color(0xFF3B82F6),
            'screen': const AdminUsersScreen(),
          },
          {
            'title': 'ستاف و دەسەڵاتەکان',
            'permission': AdminPermissions.manageStaff,
            'subtitle': 'زیادکردنی ستاف و دیاریکردنی ڕۆڵ و دەسەڵات',
            'icon': Iconsax.security_user,
            'color': const Color(0xFF4F46E5),
            'screen': const AdminStaffScreen(),
          },
          {
            'title': 'تۆماری چالاکی',
            'permission': AdminPermissions.viewLogs,
            'subtitle': 'کێ چی گۆڕی و کەی',
            'icon': Iconsax.document_text,
            'color': const Color(0xFF64748B),
            'screen': const AdminActivityLogScreen(),
          },
        ],
      },
      {
        'sectionTitle': 'هەژمار و چوونەدەرەوە',
        'items': [
          {
            'title': 'چوونەدەرەوە',
            'subtitle': 'چوونەدەرەوە لە هەژماری ئەدمین',
            'icon': Iconsax.logout,
            'color': AppColors.error,
            'action': _logout,
          },
          {
            'title': 'سڕینەوەی هەژمار',
            'subtitle': 'سڕینەوەی هەژماری ئێستا',
            'icon': Iconsax.trash,
            'color': AppColors.error,
            'action': _deleteAccount,
          },
        ],
      },
    ];

    // Keep only the items this account may open, then drop sections left empty.
    return all
        .map((section) {
          final items = (section['items'] as List)
              .where((item) {
                final permission = (item as Map)['permission'];
                return permission == null || AdminPermissions.can(permission as String);
              })
              .toList();
          return {'sectionTitle': section['sectionTitle'], 'items': items};
        })
        .where((section) => (section['items'] as List).isNotEmpty)
        .toList();
  }

  Widget _buildScaffold(BuildContext context, List<Map<String, dynamic>> sections) {

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AdminAppBar(
        title: 'ڕێکخستن',
        subtitle: 'ڕێکخستنەکانی هەژمار',
        icon: Iconsax.setting_2,
        iconColor: AppColors.primary,
        iconBackgroundColor: AppColors.primary.withValues(alpha: 0.1),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Grid Items ──
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                    children: sections.asMap().entries.map((sectionEntry) {
                      final sectionIndex = sectionEntry.key;
                      final section = sectionEntry.value;
                      final sectionTitle = section['sectionTitle'] as String;
                      final items =
                          section['items'] as List<Map<String, dynamic>>;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                                padding: EdgeInsets.only(
                                  bottom: 12,
                                  top: sectionIndex == 0 ? 0 : 24,
                                ),
                                child: Text(
                                  sectionTitle,
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    color: AppColors.getTextSubtitle(context),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                              .animate(
                                delay: Duration(
                                  milliseconds: sectionIndex * 100,
                                ),
                              )
                              .fadeIn()
                              .slideX(begin: 0.1, end: 0),
                          ...items.asMap().entries.map((itemEntry) {
                            final index = itemEntry.key;
                            final item = itemEntry.value;
                            final color = item['color'] as Color;

                            return GestureDetector(
                              onTap: () {
                                if (item.containsKey('action')) {
                                  final action = item['action'] as Function;
                                  action();
                                } else if (item.containsKey('screen')) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: item['screen'] as Widget,
                                      ),
                                    ),
                                  );
                                }
                              },
                              child:
                                  Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 14,
                                        ),
                                        padding: const EdgeInsets.all(18),
                                        decoration: BoxDecoration(
                                          color: AppColors.getSurface(context),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.03,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 52,
                                              height: 52,
                                              decoration: BoxDecoration(
                                                color: color.withValues(
                                                  alpha: 0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              child: Icon(
                                                item['icon'] as IconData,
                                                color: color,
                                                size: 26,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item['title'] as String,
                                                    style: TextStyle(
                                                      fontFamily: 'Rabar',
                                                      color:
                                                          item['title'] ==
                                                                  'چوونەدەرەوە' ||
                                                              item['title'] ==
                                                                  'سڕینەوەی هەژمار'
                                                          ? AppColors.error
                                                          : AppColors.getTextTitle(
                                                              context,
                                                            ),
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    item['subtitle'] as String,
                                                    style: TextStyle(
                                                      fontFamily: 'Rabar',
                                                      color:
                                                          AppColors.getTextSubtitle(
                                                            context,
                                                          ),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              color: AppColors.getTextSubtitle(
                                                context,
                                              ).withValues(alpha: 0.5),
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                      )
                                      .animate(
                                        delay: Duration(
                                          milliseconds:
                                              (sectionIndex * 100) +
                                              (index * 80),
                                        ),
                                      )
                                      .fadeIn()
                                      .slideX(begin: 0.1, end: 0),
                            );
                          }),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
    );
  }
}
