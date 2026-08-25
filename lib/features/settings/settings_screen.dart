import 'package:flutter/material.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import '../../core/services/session_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/utils/api_client.dart';
import 'personal_information_screen.dart';
import 'help_support_screen.dart';
import 'privacy_policy_screen.dart';
import '../../core/services/store_review_service.dart';
import '../checkout/payment_history_screen.dart';
import '../doctors/favorite_doctors_screen.dart';
import '../records/medical_records_screen.dart';
import '../notifications/notifications_screen.dart';
import '../admin/admin_dashboard_shell.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _userName = '';
  String _userPhone = '';
  String? _profileImageUrl;
  bool _isGuest = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        final token = prefs.getString('auth_token');
        _isGuest = token == null || token.isEmpty;
        _isAdmin =
            prefs.getBool('is_admin') == true ||
            prefs.getString('user_role') == 'admin';

        if (!_isGuest) {
          final un = prefs.getString('user_name') ?? '';
          _userName = un.isNotEmpty ? un : 'guest_user'.tr();
          _userPhone = prefs.getString('user_phone') ?? '';
          _profileImageUrl = prefs.getString('user_profile_image');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isGuest) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_circle_rounded,
                  size: 100,
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                ),
                const SizedBox(height: 24),
                Text(
                  'login_prompt_title'.tr(),
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    color: AppColors.getTextTitle(context),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'login_prompt_desc'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    color: AppColors.getTextSubtitle(context),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AppFlow(startAtLogin: true),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'login'.tr(),
                      style: const TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Section
            SizedBox(
              height: 270,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Blue Gradient
                  Container(
                    height: 190,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isDark
                            ? [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)]
                            : [
                                const Color(0xFF4A90E2),
                                const Color(0xFF82B1FF),
                              ],
                      ),
                    ),
                  ),

                  // Background Curve
                  PositionedDirectional(
                    top: 155,
                    start: 0,
                    end: 0,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(40),
                        ),
                      ),
                    ),
                  ),

                  // App Bar
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      child: Center(
                        child: Text(
                          'profile'.tr(),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Profile Picture & Name
                  PositionedDirectional(
                    top: 100,
                    start: 0,
                    end: 0,
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final res = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const PersonalInformationScreen(),
                              ),
                            );
                            if (res == true || mounted) {
                              _loadUserInfo();
                            }
                          },
                          child: Stack(
                            children: [
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).scaffoldBackgroundColor,
                                    width: 4,
                                  ),
                                  image:
                                      _profileImageUrl != null &&
                                          _profileImageUrl!.isNotEmpty
                                      ? DecorationImage(
                                          image: ApiClient.getImageProvider(_profileImageUrl) ??
                                              const AssetImage('assets/images/doctor2.png'),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child:
                                    _profileImageUrl != null &&
                                        _profileImageUrl!.isNotEmpty
                                    ? null
                                    : Icon(
                                        Icons.person_rounded,
                                        size: 50,
                                        color: isDark
                                            ? const Color(0xFF64748B)
                                            : const Color(0xFF94A3B8),
                                      ),
                              ),
                              PositionedDirectional(
                                bottom: 0,
                                end: 2,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B82F6),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).scaffoldBackgroundColor,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _userName,
                          style: GoogleFonts.poppins(
                            color: AppColors.getTextTitle(context),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _userPhone.isNotEmpty ? '+964 $_userPhone' : '',
                          style: GoogleFonts.poppins(
                            color: AppColors.getTextSubtitle(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Dark Mode Toggle Section
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.getSurface(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.getBorder(context)),
                    ),
                    child: _buildToggleItem(
                      context,
                      imagePath: 'assets/images/settings_theme.png',
                      title: 'dark_mode'.tr(),
                      value: isDark,
                      onChanged: (val) {
                        ThemeProvider().toggleTheme();
                      },
                    ),
                  ),

                  if (_isAdmin) ...[
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF2563EB,
                            ).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Iconsax.shield_security,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        title: const Text(
                          'داشبۆردی ئەدمین (Admin Panel)',
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: const Text(
                          'بەڕێوەبردنی پزیشکان، دەرمانخانە، تاقیگەکان و سیستەم',
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white70,
                          size: 16,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminDashboardShell(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Section 1
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.getSurface(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.getBorder(context)),
                    ),
                    child: Column(
                      children: [
                        _buildListItem(
                          context,
                          imagePath: 'assets/images/settings_personal.png',
                          title: 'personal_information'.tr(),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const PersonalInformationScreen(),
                              ),
                            );
                            _loadUserInfo();
                          },
                        ),

                        // The three below belong with the patient's own
                        // account rather than in the menu drawer, which is
                        // where they used to sit (or, for payments, nowhere).
                        _buildDivider(context),
                        _buildListItem(
                          context,
                          icon: Iconsax.folder_2,
                          title: 'medical_records'.tr(),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const MedicalRecordsScreen(),
                              ),
                            );
                          },
                        ),

                        _buildDivider(context),
                        _buildListItem(
                          context,
                          icon: Iconsax.heart,
                          title: 'favorite_doctors'.tr(),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const FavoriteDoctorsScreen(),
                              ),
                            );
                          },
                        ),

                        _buildDivider(context),
                        _buildListItem(
                          context,
                          icon: Iconsax.receipt_item,
                          title: 'payment_history'.tr(),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const PaymentHistoryScreen(),
                              ),
                            );
                          },
                        ),

                        _buildDivider(context),
                        _buildListItem(
                          context,
                          icon: Iconsax.notification,
                          title: 'notifications'.tr(),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NotificationsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Section 2
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.getSurface(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.getBorder(context)),
                    ),
                    child: Column(
                      children: [
                        _buildListItem(
                          context,
                          icon: Iconsax.language_square,
                          title: 'language'.tr(),
                          onTap: () {
                            _showLanguageBottomSheet(context);
                          },
                        ),
                        _buildDivider(context),
                        _buildListItem(
                          context,
                          icon: Iconsax.shield_security,
                          title: 'privacy_policy'.tr(),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PrivacyPolicyScreen(),
                              ),
                            );
                          },
                        ),
                        _buildDivider(context),
                        _buildListItem(
                          context,
                          icon: Iconsax.star,
                          title: 'rate_app_store'.tr(),
                          onTap: () {
                            StoreReviewService.showInAppReviewPrompt(context);
                          },
                        ),
                        _buildDivider(context),
                        _buildListItem(
                          context,
                          imagePath: 'assets/images/drawer_help.png',
                          title: 'help_support'.tr(),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HelpSupportScreen(),
                              ),
                            );
                          },
                        ),
                        _buildDivider(context),
                        _buildListItem(
                          context,
                          icon: Iconsax.user_add,
                          title: 'invite_friends'.tr(),
                          onTap: () {
                            SharePlus.instance.share(
                              ShareParams(text: 'https://drroom.app/download'),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Log Out Button
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.getSurface(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.getBorder(context)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          await SessionService.signOut(context);
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AppFlow(),
                              ),
                              (route) => false,
                            );
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Iconsax.logout,
                              color: Color(0xFF64748B),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'log_out'.tr(),
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Delete Account Button (Prominent & Required by Apple/Google)
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showDeleteAccountDialog(context),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Iconsax.trash,
                              color: Color(0xFFEF4444),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'delete_account'.tr(),
                              style: const TextStyle(
                                fontFamily: 'Rabar',
                                color: Color(0xFFEF4444),
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Generous bottom spacing so bottom navigation bar never overlaps buttons
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        bool isDeleting = false;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            contentPadding: const EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Iconsax.trash, color: Color(0xFFEF4444), size: 30),
                ),
                const SizedBox(height: 18),
                Text(
                  'delete_account_title'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'delete_account_confirm_msg'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 12.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isDeleting
                        ? null
                        : () async {
                            setDialogState(() => isDeleting = true);
                            try {
                              await ApiClient.delete('/user');
                            } catch (_) {}
                            if (context.mounted) {
                              await SessionService.signOut(context);
                            }
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const AppFlow()),
                                (route) => false,
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: isDeleting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'yes_delete_account'.tr(),
                            style: const TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(ctx),
                  child: Text(
                    'cancel'.tr(),
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 13,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListItem(
    BuildContext context, {
    IconData? icon,
    String? imagePath,
    required String title,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (imagePath != null)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(imagePath, fit: BoxFit.cover),
                  ),
                )
              else if (icon != null)
                Icon(icon, color: const Color(0xFF3B82F6), size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                Iconsax.arrow_left_2,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF475569)
                    : const Color(0xFFCBD5E1),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleItem(
    BuildContext context, {
    IconData? icon,
    String? imagePath,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          if (imagePath != null)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(imagePath, fit: BoxFit.cover),
              ),
            )
          else if (icon != null)
            Icon(icon, color: const Color(0xFF3B82F6), size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Rabar',
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: const Color(0xFF3B82F6),
            activeTrackColor: const Color(0xFF93C5FD),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        color: AppColors.getDivider(context),
        height: 1,
        thickness: 1,
      ),
    );
  }

  Widget _buildKurdishFlag() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(child: Container(color: const Color(0xFFED2024))),
          Expanded(
            child: Container(
              color: Colors.white,
              child: const Center(
                child: Icon(Icons.wb_sunny, color: Color(0xFFF9AF1A), size: 10),
              ),
            ),
          ),
          Expanded(child: Container(color: const Color(0xFF278E43))),
        ],
      ),
    );
  }

  void _showLanguageBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.getBackground(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'select_language'.tr(),
                style: GoogleFonts.poppins(
                  color: AppColors.getTextTitle(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              _buildLanguageOption(
                bottomSheetContext,
                'English',
                '🇬🇧',
                const Locale('en'),
              ),
              const SizedBox(height: 12),
              _buildLanguageOption(
                bottomSheetContext,
                'کوردی',
                'kurdish',
                const Locale('ckb'),
              ),
              const SizedBox(height: 12),
              _buildLanguageOption(
                bottomSheetContext,
                'العربية',
                '🇮🇶',
                const Locale('ar'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String title,
    String flag,
    Locale locale,
  ) {
    final isSelected = context.locale == locale;
    return InkWell(
      onTap: () {
        context.setLocale(locale);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
              : AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3B82F6)
                : AppColors.getBorder(context),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (flag == 'kurdish')
              _buildKurdishFlag()
            else
              Text(flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  color: isSelected
                      ? const Color(0xFF3B82F6)
                      : AppColors.getTextTitle(context),
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF3B82F6),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}