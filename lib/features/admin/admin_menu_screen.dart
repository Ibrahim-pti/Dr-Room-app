import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../main.dart';
import 'admin_users_screen.dart';
import 'admin_appointments_screen.dart';
import 'admin_banners_screen.dart';
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

  Future<void> _showAddAdminModal() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    bool isAdding = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.getBorder(context),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'زیادکردنی ئەدمینی نوێ',
                      style: TextStyle(
                        color: AppColors.getTextTitle(context),
                        fontFamily: 'Rabar',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInput(
                      controller: nameController,
                      hint: 'ناوی تەواو',
                      context: context,
                    ),
                    const SizedBox(height: 12),
                    _buildInput(
                      controller: phoneController,
                      hint: 'ژمارە مۆبایل (0750...)',
                      context: context,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    _buildInput(
                      controller: passwordController,
                      hint: 'وشەی تێپەڕ (٦ پیت یان زیاتر)',
                      context: context,
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isAdding
                            ? null
                            : () async {
                                if (nameController.text.isEmpty ||
                                    phoneController.text.isEmpty ||
                                    passwordController.text.isEmpty)
                                  return;

                                setModalState(() => isAdding = true);
                                try {
                                  final response = await ApiClient.post(
                                    '/admin/add-admin',
                                    body: {
                                      'name': nameController.text,
                                      'phone': phoneController.text,
                                      'password': passwordController.text,
                                    },
                                  );

                                  if (response.statusCode == 201) {
                                    if (!context.mounted) return;
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'ئەدمین بە سەرکەوتوویی زیادکرا',
                                        ),
                                      ),
                                    );
                                  } else {
                                    final body = jsonDecode(response.body);
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          body['message'] ?? 'هەڵەیەک ڕوویدا',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'هەڵەیەک ڕوویدا لە پەیوەندی کردن',
                                      ),
                                    ),
                                  );
                                }
                                setModalState(() => isAdding = false);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: isAdding
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'زیادکردن',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Rabar',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required BuildContext context,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: TextStyle(
          color: AppColors.getTextTitle(context),
          fontFamily: 'Rabar',
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.getTextSubtitle(context),
            fontFamily: 'Rabar',
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sections = [
      {
        'sectionTitle': 'هەژمار و ڕێکخستنەکان',
        'items': [
          {
            'title': 'بەکارهێنەران',
            'subtitle': 'بەڕێوەبردنی بەکارهێنەران',
            'icon': Iconsax.people,
            'color': const Color(0xFF3B82F6),
            'screen': const AdminUsersScreen(),
          },
          {
            'title': 'زیادکردنی ئەدمین',
            'subtitle': 'دروستکردنی ئەدمینی نوێ',
            'icon': Iconsax.user_add,
            'color': Colors.indigo,
            'action': _showAddAdminModal,
          },
          {
            'title': 'چوونەدەرەوە',
            'subtitle': 'چوونەدەرەوە لە هەژمارەکە',
            'icon': Iconsax.logout,
            'color': AppColors.error,
            'action': _logout,
          },
        ],
      },
    ];

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
