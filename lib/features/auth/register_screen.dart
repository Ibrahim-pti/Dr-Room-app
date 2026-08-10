import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import 'dart:convert';
import '../../core/utils/api_client.dart';
import 'package:flutter/services.dart';

class RegisterScreen extends StatefulWidget {
  final void Function(String phone) onOtpSent;
  final VoidCallback onLogin;

  const RegisterScreen({
    super.key,
    required this.onOtpSent,
    required this.onLogin,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (name.isEmpty ||
        phone.isEmpty ||
        phone.length != 11 ||
        password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تکایە دڵنیابە لە داخڵکردنی زانیارییەکان و ١١ ژمارەی مۆبایل',
            ),
          ),
        );
      }
      return;
    }
    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('وشەی تێپەڕەکان وەک یەک نین')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.post(
        '/register',
        body: {'name': name, 'phone': phone, 'password': password},
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final otp = data['otp'];
        debugPrint('OTP is: $otp');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('کۆدەکە: $otp')));
        }
        widget.onOtpSent(phone);
      } else {
        final err = jsonDecode(response.body);
        final msg = err['message'] ?? 'هەڵە ڕوویدا لە دروستکردنی هەژمار';
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('هەڵە لە پەیوەندیکردن بە سێرڤەر: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Header Section ──
            SizedBox(
              height: size.height * 0.30, // Slightly increased header height
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Gradient Background
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFFE0EEFF),
                            const Color(0xFFF8FAFC),
                          ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Soft blue glow behind doctor
                  PositionedDirectional(
                    end: 0,
                    top: size.height * 0.02,
                    child: Container(
                      width: size.width * 0.55,
                      height: size.width * 0.55,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF93C5FD).withValues(alpha: 0.3),
                            const Color(0xFFDBEAFE).withValues(alpha: 0.15),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Doctor Image
                  PositionedDirectional(
                    end: -20,
                    top: 60,
                    bottom: -10,
                    width: size.width * 0.55,
                    child:
                        ShaderMask(
                              shaderCallback: (rect) {
                                return const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black,
                                    Colors.black,
                                    Colors.transparent,
                                  ],
                                  stops: [0.0, 0.80, 1.0],
                                ).createShader(rect);
                              },
                              blendMode: BlendMode.dstIn,
                              child: Image.asset(
                                'assets/images/doctor3.png',
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 800.ms)
                            .slideX(begin: 0.2, end: 0, curve: Curves.easeOut),
                  ),

                  // Back Button
                  PositionedDirectional(
                    top: 56,
                    start: 24,
                    child: GestureDetector(
                      onTap: widget.onLogin,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFE2E8F0,
                              ).withValues(alpha: 0.8),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          size: 26,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),

                  // Title Section
                  PositionedDirectional(
                    start: 28,
                    top: 130, // Increased top padding from 105 to 130
                    child: SizedBox(
                      width: size.width * 0.42,
                      child:
                          Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Logo + DrRoom in a row
                                  Row(
                                    children: [
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            begin:
                                                AlignmentDirectional.topStart,
                                            end: AlignmentDirectional.bottomEnd,
                                            colors: [
                                              Color(0xFF60A5FA),
                                              Color(0xFF2563EB),
                                              Color(0xFF1D4ED8),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF2563EB,
                                              ).withValues(alpha: 0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Stack(
                                          children: [
                                            PositionedDirectional(
                                              top: -6,
                                              end: -6,
                                              child: Container(
                                                width: 20,
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.white
                                                      .withValues(alpha: 0.15),
                                                ),
                                              ),
                                            ),
                                            const Center(
                                              child: Icon(
                                                Icons.local_hospital_rounded,
                                                color: Colors.white,
                                                size: 22,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: 'Dr',
                                              style: GoogleFonts.poppins(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w800,
                                                color: const Color(0xFF2563EB),
                                                letterSpacing: -0.5,
                                              ),
                                            ),
                                            TextSpan(
                                              text: 'Room',
                                              style: GoogleFonts.poppins(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w800,
                                                color: const Color(0xFF0F172A),
                                                letterSpacing: -0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Title
                                  Text(
                                    'create_account'.tr(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                      height: 1.15,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'sign_up_to_get_started'.tr(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              )
                              .animate()
                              .fadeIn(delay: 200.ms)
                              .slideY(begin: 0.2, end: 0),
                    ),
                  ),
                ],
              ),
            ),

            // ── Form Section ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Name Input
                  _buildInputField(
                    hint: 'full_name'.tr(),
                    icon: Icons.person_outline_rounded,
                    controller: _nameController,
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 12),

                  // Phone
                  _buildInputField(
                    hint: 'phone_number'.tr(),
                    icon: Icons.phone_outlined,
                    controller: _phoneController,
                    isPhone: true,
                  ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 12),

                  // Password
                  _buildInputField(
                    hint: 'password'.tr(),
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                    obscure: _obscurePassword,
                    onToggleObscure: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    controller: _passwordController,
                  ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 12),

                  // Confirm Password
                  _buildInputField(
                    hint: 'confirm_password'.tr(),
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                    obscure: _obscureConfirmPassword,
                    onToggleObscure: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                    controller: _confirmPasswordController,
                  ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 16),

                  // Terms & Conditions
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () =>
                            setState(() => _agreeToTerms = !_agreeToTerms),
                        child: Container(
                          margin: const EdgeInsetsDirectional.only(
                            top: 2,
                            end: 12,
                          ),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: _agreeToTerms
                                ? const Color(0xFF2563EB)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: _agreeToTerms
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFCBD5E1),
                              width: 1.5,
                            ),
                            boxShadow: _agreeToTerms
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF2563EB,
                                      ).withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: _agreeToTerms
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 15,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                              height: 1.5,
                            ),
                            children: [
                              TextSpan(text: 'by_signing_up'.tr()),
                              TextSpan(
                                text: 'terms_of_service'.tr(),
                                style: TextStyle(
                                  color: const Color(0xFF2563EB),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: 'and'.tr()),
                              TextSpan(
                                text: 'privacy_policy'.tr(),
                                style: TextStyle(
                                  color: const Color(0xFF2563EB),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 550.ms),

                  const SizedBox(height: 24),

                  // Create Account Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D4ED8),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: const Color(
                          0xFF1D4ED8,
                        ).withValues(alpha: 0.3),
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
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'create_account'.tr().replaceAll('\n', ' '),
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 24),

                  // Log In Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'already_have_account'.tr(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onLogin,
                        child: Text(
                          'log_in'.tr(),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 800.ms),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isPhone = false,
    bool? obscure,
    VoidCallback? onToggleObscure,
    required TextEditingController controller,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure ?? false,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        inputFormatters: isPhone
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        maxLength: isPhone ? 11 : null,
        style: GoogleFonts.poppins(
          fontSize: 15,
          color: const Color(0xFF1E293B),
          letterSpacing: isPhone ? 1.5 : 0,
        ),
        decoration: InputDecoration(
          counterText: '',
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF94A3B8),
            letterSpacing: 0,
          ),
          prefixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 12),
              Icon(icon, color: const Color(0xFF2563EB), size: 20),
              if (isPhone) ...[
                const SizedBox(width: 8),
                Text(
                  '+964',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(width: 8),
                Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
                const SizedBox(width: 12),
              ] else ...[
                const SizedBox(width: 12),
              ],
            ],
          ),
          suffixIcon: isPassword
              ? GestureDetector(
                  onTap: onToggleObscure,
                  child: Icon(
                    (obscure ?? true)
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF94A3B8),
                    size: 20,
                  ),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
