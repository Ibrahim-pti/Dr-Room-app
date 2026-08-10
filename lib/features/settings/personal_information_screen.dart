import 'package:flutter/material.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  final TextEditingController _nameController =
      TextEditingController(text: 'Sara Ahmed');
  final TextEditingController _emailController =
      TextEditingController(text: 'sara.ahmed@example.com');
  final TextEditingController _phoneController =
      TextEditingController(text: '+964 750 123 4567');
  final TextEditingController _dobController =
      TextEditingController(text: '15/08/1995');

  String _selectedGender = 'Female';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

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
          'personal_information'.tr(),
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Image
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF3B82F6),
                        width: 3,
                      ),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/doctor2.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    bottom: 0,
                    end: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.getBackground(context),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Iconsax.camera,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Form Fields
            _buildInputField(
              label: 'full_name'.tr(),
              controller: _nameController,
              icon: Iconsax.user,
            ),
            const SizedBox(height: 16),

            _buildInputField(
              label: 'email'.tr(),
              controller: _emailController,
              icon: Iconsax.sms,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            _buildInputField(
              label: 'phone_number'.tr(),
              controller: _phoneController,
              icon: Iconsax.call,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            _buildInputField(
              label: 'date_of_birth'.tr(),
              controller: _dobController,
              icon: Iconsax.calendar_1,
              readOnly: true,
              onTap: () {
                // Show date picker
              },
            ),
            const SizedBox(height: 16),

            // Gender Selection
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'gender'.tr(),
                  style: GoogleFonts.poppins(
                    color: AppColors.getTextSubtitle(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildGenderOption('male'.tr(), Icons.male_rounded),
                    const SizedBox(width: 16),
                    _buildGenderOption('female'.tr(), Icons.female_rounded),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 48),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'save_changes'.tr(),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: AppColors.getTextSubtitle(context),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.getSurface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.getBorder(context)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onTap: onTap,
            style: GoogleFonts.poppins(
              color: AppColors.getTextTitle(context),
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: label,
              hintStyle: GoogleFonts.poppins(
                color: const Color(0xFF94A3B8),
                fontSize: 14,
              ),
              prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderOption(String gender, IconData icon) {
    final isSelected = _selectedGender == gender;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedGender = gender;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFE0EEFF)
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF94A3B8),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                gender,
                style: GoogleFonts.poppins(
                  color: isSelected
                      ? const Color(0xFF3B82F6)
                      : AppColors.getTextTitle(context),
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
