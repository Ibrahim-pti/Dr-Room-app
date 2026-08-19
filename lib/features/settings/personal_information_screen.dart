import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_client.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  String _selectedGender = 'Female';
  bool _isLoading = false;
  File? _selectedImage;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('user_name') ?? '';
      _phoneController.text = prefs.getString('user_phone') ?? '';
      _emailController.text = prefs.getString('user_email') ?? '';
      _selectedGender = prefs.getString('guest_gender') ?? 'Female';
      _dobController.text = prefs.getString('user_dob') ?? '';
      _profileImageUrl = prefs.getString('user_profile_image');
    });

    try {
      final response = await ApiClient.get('/user');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final u = data['user'];
        if (mounted && u != null) {
          setState(() {
            if ((u['name'] ?? '').toString().isNotEmpty) {
              _nameController.text = u['name'];
            }
            if ((u['phone'] ?? '').toString().isNotEmpty) {
              _phoneController.text = u['phone'];
            }
            if ((u['email'] ?? '').toString().isNotEmpty) {
              _emailController.text = u['email'];
            }
            if ((u['gender'] ?? '').toString().isNotEmpty) {
              _selectedGender = u['gender'];
            }
            if ((u['dob'] ?? '').toString().isNotEmpty) {
              _dobController.text = u['dob'];
            }
            if ((u['profile_image'] ?? '').toString().isNotEmpty) {
              _profileImageUrl = u['profile_image'];
              prefs.setString('user_profile_image', _profileImageUrl!);
            }
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.getSurface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'هەڵبژاردنی وێنەی پڕۆفایل',
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextTitle(context),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Iconsax.gallery, color: Color(0xFF3B82F6)),
                title: Text('گالەری (مۆبایل)', style: TextStyle(fontFamily: 'Rabar', color: AppColors.getTextTitle(context))),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Iconsax.camera, color: Color(0xFF10B981)),
                title: Text('کامێرا', style: TextStyle(fontFamily: 'Rabar', color: AppColors.getTextTitle(context))),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final dob = _dobController.text.trim();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', name);
      await prefs.setString('user_email', email);
      await prefs.setString('user_dob', dob);
      await prefs.setString('guest_gender', _selectedGender);

      dynamic response;
      if (_selectedImage != null) {
        response = await ApiClient.uploadMultipart(
          '/user',
          fields: {
            'name': name,
            'email': email,
            'dob': dob,
            'gender': _selectedGender,
          },
          fileField: 'profile_image',
          filePath: _selectedImage!.path,
        );
      } else {
        response = await ApiClient.put('/user', body: {
          'name': name,
          'email': email,
          'dob': dob,
          'gender': _selectedGender,
        });
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final user = data['user'];
        if (user != null && user['profile_image'] != null) {
          await prefs.setString('user_profile_image', user['profile_image'].toString());
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'پڕۆفایلەکەت بە سەرکەوتوویی نوێکرایەوە',
              style: TextStyle(fontFamily: 'Rabar', color: Colors.white),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'هەڵەیەک ڕوویدا لە نوێکردنەوەی پڕۆفایل',
              style: TextStyle(fontFamily: 'Rabar', color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
          style: TextStyle(
            fontFamily: 'Rabar',
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
            // Profile Image Picker
            Center(
              child: GestureDetector(
                onTap: _pickImage,
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
                        image: DecorationImage(
                          image: _selectedImage != null
                              ? FileImage(_selectedImage!) as ImageProvider
                              : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                  ? NetworkImage(ApiClient.getImageUrl(_profileImageUrl!))
                                  : const AssetImage('assets/images/doctor2.png') as ImageProvider),
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
              readOnly: true,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            _buildInputField(
              label: 'date_of_birth'.tr(),
              controller: _dobController,
              icon: Iconsax.calendar_1,
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  _dobController.text = DateFormat('yyyy-MM-dd').format(date);
                }
              },
            ),
            const SizedBox(height: 16),

            // Gender Selector
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'gender'.tr(),
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    color: AppColors.getTextTitle(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildGenderOption(
                        title: 'male'.tr(),
                        value: 'Male',
                        selected: _selectedGender == 'Male',
                        onTap: () => setState(() => _selectedGender = 'Male'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildGenderOption(
                        title: 'female'.tr(),
                        value: 'Female',
                        selected: _selectedGender == 'Female',
                        onTap: () => setState(() => _selectedGender = 'Female'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'save_changes'.tr(),
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
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool readOnly = false,
    TextInputType? keyboardType,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Rabar',
            color: AppColors.getTextTitle(context),
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
            readOnly: readOnly,
            keyboardType: keyboardType,
            onTap: onTap,
            style: TextStyle(
              fontFamily: 'Rabar',
              color: AppColors.getTextTitle(context),
              fontSize: 16,
            ),
            decoration: InputDecoration(
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

  Widget _buildGenderOption({
    required String title,
    required String value,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
              : AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? const Color(0xFF3B82F6)
                : AppColors.getBorder(context),
            width: selected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Rabar',
              color: selected
                  ? const Color(0xFF3B82F6)
                  : AppColors.getTextTitle(context),
              fontSize: 16,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
