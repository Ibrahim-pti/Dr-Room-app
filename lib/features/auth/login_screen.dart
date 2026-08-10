import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/dr_widgets.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/api_client.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  final void Function(String phone) onOtpSent;
  final VoidCallback onSignUp;

  const LoginScreen({
    super.key,
    required this.onOtpSent,
    required this.onSignUp,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    if (phone.isEmpty || phone.length != 11 || password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تکایە دڵنیابە لە داخڵکردنی ١١ ژمارە بۆ مۆبایلەکە وە پاسۆرد',
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiClient.post(
        '/login',
        body: {'phone': phone, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final otp = data['otp']; // For development
        debugPrint('OTP is: $otp');

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('کۆدەکە: $otp')));
        }
        widget.onOtpSent(phone);
      } else {
        final err = jsonDecode(response.body);
        final msg = err['message'] ?? 'هەڵە ڕوویدا';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('هەڵە لە پەیوەندیکردن بە سێرڤەر: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(
        0xFFF8FAFC,
      ), // Very light cool grey/blue background
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Header Section ──
            SizedBox(
              height: size.height * 0.42,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Gradient Background at top
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
                    top: size.height * 0.05,
                    child: Container(
                      width: size.width * 0.6,
                      height: size.width * 0.6,
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

                  // Doctor Image (Aligned tightly to the right, fading at bottom)
                  PositionedDirectional(
                    end: -20,
                    top: 90,
                    bottom: 0,
                    width: size.width * 0.65,
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
                                  stops: [0.0, 0.85, 1.0],
                                ).createShader(rect);
                              },
                              blendMode: BlendMode.dstIn,
                              child: Image.asset(
                                'assets/images/doctor2.png',
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
                    top: 60, // Adjusted to match status bar
                    start: 24,
                    child: GestureDetector(
                      onTap: () {},
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

                  // DrRoom Logo & Welcome Text
                  PositionedDirectional(
                    start: 28,
                    top: 120,
                    child: SizedBox(
                      width: size.width * 0.40,
                      child:
                          Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Logo Custom Design
                                  Container(
                                    width: 58,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: AlignmentDirectional.topStart,
                                        end: AlignmentDirectional.bottomEnd,
                                        colors: [
                                          Color(0xFF60A5FA),
                                          Color(0xFF2563EB),
                                          Color(0xFF1D4ED8),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF2563EB,
                                          ).withValues(alpha: 0.35),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        // Decorative circle
                                        PositionedDirectional(
                                          top: -8,
                                          end: -8,
                                          child: Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white.withValues(
                                                alpha: 0.15,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Medical cross icon
                                        const Center(
                                          child: Icon(
                                            Icons.local_hospital_rounded,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  // Logo Text
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Dr',
                                          style: GoogleFonts.poppins(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF2563EB),
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'Room',
                                          style: GoogleFonts.poppins(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF0F172A),
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  // Welcome Text
                                  Text(
                                    'welcome_back'.tr(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                      height: 1.15,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'sign_in_continue'.tr(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
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
                  const SizedBox(height: 28),

                  // Phone Input
                  _buildInputField(
                    hint: 'phone_number'.tr(),
                    icon: Icons.phone_android_rounded,
                    controller: _phoneController,
                    isPhone: true,
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 16),

                  // Password Input
                  _buildInputField(
                    hint: 'password'.tr(),
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                    controller: _passwordController,
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 12),

                  // Forgot Password
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: GestureDetector(
                      onTap: () {},
                      child: Text(
                        'forgot_password'.tr(),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF2563EB),
                          decoration: TextDecoration.underline,
                          decorationColor: const Color(
                            0xFF2563EB,
                          ).withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: 24),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
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
                      child: Text(
                        'log_in'.tr(),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 32),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'dont_have_account'.tr(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onSignUp,
                        child: Text(
                          'sign_up'.tr(),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 900.ms),

                  const SizedBox(height: 40),
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
    required TextEditingController controller,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
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
            fontSize: 15,
            color: const Color(0xFF94A3B8),
            letterSpacing: 0,
          ),
          prefixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 12),
              Icon(icon, color: AppColors.primary, size: 22),
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
                  onTap: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  child: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF94A3B8),
                    size: 22,
                  ),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
      ),
    );
  }
}

const String _drRoomIconSvg = '''
<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
<rect x="4" y="4" width="24" height="24" rx="6" fill="white" fill-opacity="0.2"/>
<path d="M16 9V23" stroke="white" stroke-width="3" stroke-linecap="round"/>
<path d="M9 16H23" stroke="white" stroke-width="3" stroke-linecap="round"/>
<circle cx="22" cy="10" r="4" fill="white" fill-opacity="0.25"/>
</svg>
''';
