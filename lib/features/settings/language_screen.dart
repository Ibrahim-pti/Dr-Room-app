import 'package:dr_room/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_theme.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Iconsax.arrow_left_2,
            color: AppColors.getTextTitle(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Language / زمان / اللغة',
          style: GoogleFonts.poppins(
            color: AppColors.getTextTitle(context),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildLanguageOption(
              context,
              title: 'کوردی (Kurdish)',
              localeCode: 'ckb',
              icon: Iconsax.global,
            ),
            const SizedBox(height: 16),
            _buildLanguageOption(
              context,
              title: 'العربية (Arabic)',
              localeCode: 'ar',
              icon: Iconsax.global,
            ),
            const SizedBox(height: 16),
            _buildLanguageOption(
              context,
              title: 'English',
              localeCode: 'en',
              icon: Iconsax.global,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context, {
    required String title,
    required String localeCode,
    required IconData icon,
  }) {
    final isSelected = context.locale.languageCode == localeCode;

    return InkWell(
      onTap: () {
        context.setLocale(Locale(localeCode));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.getBorder(context),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.getTextSubtitle(context),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.getTextTitle(context),
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Iconsax.tick_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
