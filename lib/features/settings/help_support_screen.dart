import 'package:flutter/material.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getBackground(context),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left_rounded,
            color: AppColors.getTextTitle(context),
            size: 32,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'help_support'.tr(),
          style: GoogleFonts.poppins(
            color: AppColors.getTextTitle(context),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.getBorder(context)),
              ),
              child: TextField(
                style: GoogleFonts.poppins(
                  color: AppColors.getTextTitle(context),
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Search for help...',
                  hintStyle: GoogleFonts.poppins(
                    color: const Color(0xFF94A3B8),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  icon: const Icon(Iconsax.search_normal, color: Color(0xFF94A3B8), size: 20),
                ),
              ),
            ),
            const SizedBox(height: 32),

            Text(
              'contact_us'.tr(),
              style: GoogleFonts.poppins(
                color: AppColors.getTextTitle(context),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Contact Options
            Row(
              children: [
                _buildContactCard(
                  context,
                  icon: Iconsax.call,
                  title: 'Call Us',
                  color: const Color(0xFF3B82F6),
                  onTap: () async {
                    final Uri url = Uri.parse('tel:+9647501234567');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  },
                ),
                const SizedBox(width: 16),
                _buildContactCard(
                  context,
                  icon: Iconsax.sms,
                  title: 'Email Us',
                  color: const Color(0xFFF59E0B),
                  onTap: () async {
                    final Uri url = Uri.parse('mailto:support@drroom.com?subject=Help and Support');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),

            Text(
              'faq'.tr(),
              style: GoogleFonts.poppins(
                color: AppColors.getTextTitle(context),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // FAQ Items
            _buildFAQItem(
              context,
              question: 'How do I book an appointment?',
              answer: 'To book an appointment, go to the Home screen, search for a doctor, and click on "Book Appointment". Choose an available time slot and confirm.',
            ),
            const SizedBox(height: 16),
            _buildFAQItem(
              context,
              question: 'How can I cancel my appointment?',
              answer: 'Go to your Schedule or Appointments tab, select the upcoming appointment you wish to cancel, and click the "Cancel" button at the bottom of the details page.',
            ),
            const SizedBox(height: 16),
            _buildFAQItem(
              context,
              question: 'Is my medical data secure?',
              answer: 'Yes, your data is encrypted and stored securely following the highest HIPAA and data privacy standards. We prioritize your privacy.',
            ),
            const SizedBox(height: 16),
            _buildFAQItem(
              context,
              question: 'How do I add a family member?',
              answer: 'Go to the Profile section, click on "My Family", and use the "Add New Member" button to register your dependents.',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.getSurface(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.getBorder(context)),
            boxShadow: [
              BoxShadow(
                color: AppColors.getBorder(context).withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: AppColors.getTextTitle(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, {required String question, required String answer}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: const Color(0xFF3B82F6),
          collapsedIconColor: const Color(0xFF94A3B8),
          title: Text(
            question,
            style: GoogleFonts.poppins(
              color: AppColors.getTextTitle(context),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          childrenPadding: const EdgeInsetsDirectional.only(start: 16, end: 16, bottom: 16),
          children: [
            Text(
              answer,
              style: GoogleFonts.poppins(
                color: AppColors.getTextSubtitle(context),
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
