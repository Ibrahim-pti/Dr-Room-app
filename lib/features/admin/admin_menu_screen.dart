import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/api_client.dart';
import '../../core/utils/admin_permissions.dart';
import '../../core/theme/app_colors.dart';
import '../../main.dart';
import 'admin_reviews_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_transactions_screen.dart';
import 'admin_banners_screen.dart';
import 'admin_notifications_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final sections = _visibleSections();

    return _buildScaffold(context, sections);
  }

  /// Filters the menu down to what the signed-in staff account may open.
  List<Map<String, dynamic>> _visibleSections() {
    final all = [
      {
        'sectionTitle': 'بەڕێوەبردنی ناوەڕۆک و ڕێکخستنەکان',
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
