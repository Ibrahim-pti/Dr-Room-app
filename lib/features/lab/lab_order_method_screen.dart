import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'upload_prescription_screen.dart';
import 'select_tests_screen.dart';

class LabOrderMethodScreen extends StatelessWidget {
  const LabOrderMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'lab_service'.tr(),
          style: GoogleFonts.poppins(
            color: AppColors.getTextTitle(context),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'how_to_request'.tr(),
              style: GoogleFonts.poppins(
                color: AppColors.getTextTitle(context),
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
            const SizedBox(height: 12),
            Text(
              'choose_lab_method'.tr(),
              style: GoogleFonts.poppins(
                color: AppColors.getTextSubtitle(context),
                fontSize: 15,
                height: 1.5,
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideX(begin: -0.1, end: 0),
            const SizedBox(height: 40),
            
            // Method 1: Upload Prescription
            _buildMethodCard(
              context,
              title: 'upload_prescription'.tr(),
              description: 'upload_prescription_desc'.tr(),
              icon: Iconsax.document_upload,
              color: const Color(0xFF3B82F6),
              delay: 200,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UploadPrescriptionScreen(),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 20),
            
            // Method 2: Select Tests Manually
            _buildMethodCard(
              context,
              title: 'select_tests_manually'.tr(),
              description: 'select_tests_desc'.tr(),
              icon: Iconsax.health,
              color: const Color(0xFF10B981),
              delay: 300,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SelectTestsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required int delay,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.getSurface(context),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: AppColors.getTextTitle(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      color: AppColors.getTextSubtitle(context),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF94A3B8),
                size: 14,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: delay.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
    );
  }
}
