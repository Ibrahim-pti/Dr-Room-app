import 'package:flutter/material.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';

class MedicalRecordsScreen extends StatelessWidget {
  const MedicalRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(context),
        elevation: 0,
        title: Text(
          'medical_records'.tr(),
          style: GoogleFonts.poppins(
            color: AppColors.getTextTitle(context),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.getTextTitle(context)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Iconsax.add_circle, color: const Color(0xFF3B82F6)),
            onPressed: () {}, // Add new document
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Search & Filter ──
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.getSurface(context),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: AppColors.getBorder(context)),
                      ),
                      child: Row(
                        children: [
                          Icon(Iconsax.search_normal_1, color: AppColors.getTextSubtitle(context), size: 20),
                          const SizedBox(width: 12),
                          Text(
                            'search_files'.tr(),
                            style: GoogleFonts.poppins(
                              color: AppColors.getTextSubtitle(context),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Iconsax.filter, color: Colors.white, size: 22),
                  ),
                ],
              ).animate().fadeIn().slideY(begin: 0.1, end: 0),
              
              const SizedBox(height: 32),

              // ── Folders ──
              Text(
                'folders'.tr(),
                style: GoogleFonts.poppins(
                  color: AppColors.getTextTitle(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 16),
              
              SizedBox(
                height: 140,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFolderCard(context, 'lab_results'.tr(), '12 Files', const Color(0xFF3B82F6), Iconsax.document_like),
                    _buildFolderCard(context, 'x_rays'.tr(), '5 Files', const Color(0xFF8B5CF6), Iconsax.scan),
                    _buildFolderCard(context, 'prescriptions'.tr(), '8 Files', const Color(0xFF10B981), Iconsax.receipt_2),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1, end: 0),

              const SizedBox(height: 32),

              // ── Recent Files ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'recent_files'.tr(),
                    style: GoogleFonts.poppins(
                      color: AppColors.getTextTitle(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'see_all'.tr(),
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF3B82F6),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 16),
              
              _buildFileItem(context, 'blood_test_results'.tr(), 'Lab Results • Oct 24, 2026', '1.2 MB', Iconsax.document_text),
              _buildFileItem(context, 'x_rays'.tr(), 'X-Rays • Oct 15, 2026', '5.4 MB', Iconsax.gallery),
              _buildFileItem(context, 'prescriptions'.tr(), 'Prescriptions • Sep 30, 2026', '800 KB', Iconsax.receipt_2),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFolderCard(BuildContext context, String title, String subtitle, Color color, IconData icon) {
    return Container(
      width: 140,
      margin: const EdgeInsetsDirectional.only(end: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const Spacer(),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: AppColors.getTextTitle(context),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              color: AppColors.getTextSubtitle(context),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(BuildContext context, String title, String subtitle, String size, IconData icon) {
    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9), // Use constant or generic color to avoid dark mode clash on pure backgrounds
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFF64748B), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: AppColors.getTextTitle(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: AppColors.getTextSubtitle(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(Icons.more_vert, color: Color(0xFF94A3B8), size: 20),
              const SizedBox(height: 8),
              Text(
                size,
                style: GoogleFonts.poppins(
                  color: AppColors.getTextSubtitle(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);
  }
}
