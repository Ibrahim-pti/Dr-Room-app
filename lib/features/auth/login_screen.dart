import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:convert';
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Header Section ──
            SizedBox(
              height: size.height * 0.34,
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
                            const Color(0xFFDEEBFF),
                            const Color(0xFFF8FAFC),
                          ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Soft blue glow behind doctor
                  PositionedDirectional(
                    end: -50,
                    top: -30,
                    child: Container(
                      width: size.width * 0.7,
                      height: size.width * 0.7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF93C5FD).withValues(alpha: 0.2),
                            const Color(0xFFDBEAFE).withValues(alpha: 0.08),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Doctor Image — confined to the left ~54% so it never
                  // shares horizontal space with the text column.
                  PositionedDirectional(
                    end: 0,
                    top: 58,
                    bottom: 0,
                    width: size.width * 0.54,
                    child: ShaderMask(
                      shaderCallback: (rect) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black,
                            Colors.black,
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.8, 1.0],
                        ).createShader(rect);
                      },
                      blendMode: BlendMode.dstIn,
                      child: Image.asset(
                        'assets/images/doctor2.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      ),
                    ),
                  ).animate().fadeIn(duration: 800.ms).slideX(begin: 0.2, end: 0, curve: Curves.easeOut),

                  // Back Button (leading edge — left side for RTL)
                  PositionedDirectional(
                    top: 50,
                    end: 20,
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          size: 24,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),

                  // DrRoom Logo & Welcome Text — confined to the right ~40%
                  PositionedDirectional(
                    start: 24,
                    top: 64,
                    child: SizedBox(
                      width: size.width * 0.40,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Logo Icon
                          Container(
                            width: 50,
                            height: 50,
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
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                PositionedDirectional(
                                  top: -5,
                                  end: -5,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(alpha: 0.18),
                                    ),
                                  ),
                                ),
                                const Center(
                                  child: Icon(
                                    Icons.local_hospital_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Logo Text
                          RichText(
                            textAlign: TextAlign.end,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Dr',
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF2563EB),
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Room',
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                    letterSpacing: -0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          // Welcome Text
                          Text(
                            'welcome_back'.tr(),
                            textAlign: TextAlign.end,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              height: 1.25,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'sign_in_continue'.tr(),
                            textAlign: TextAlign.end,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF78909C),
                              height: 1.5,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
                  ),
                ],
              ),
            ),

            // ── Form Section ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
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

                  const SizedBox(height: 16),

                  // Forgot Password
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: GestureDetector(
                      onTap: () {},
                      child: Text(
                        'forgot_password'.tr(),
                        textAlign: TextAlign.end,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF2563EB),
                          decoration: TextDecoration.underline,
                          decorationColor: const Color(0xFF2563EB).withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: 32),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D4ED8),
                        disabledBackgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.6),
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.25),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'log_in'.tr(),
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 28),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'dont_have_account'.tr(),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: widget.onSignUp,
                        child: Text(
                          'sign_up'.tr(),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2563EB),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 900.ms),

                  const SizedBox(height: 24),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        inputFormatters: isPhone ? [FilteringTextInputFormatter.digitsOnly] : null,
        maxLength: isPhone ? 11 : null,
        textAlign: TextAlign.end,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1E293B),
          letterSpacing: isPhone ? 1.2 : 0.2,
        ),
        decoration: InputDecoration(
          counterText: '',
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF94A3B8),
            letterSpacing: 0.2,
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          prefixIcon: Padding(
            padding: const EdgeInsetsDirectional.only(start: 14, end: 12),
            child: Icon(
              icon,
              color: const Color(0xFF2563EB),
              size: 20,
            ),
          ),
          suffixIcon: isPassword
              ? GestureDetector(
                  onTap: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(end: 14),
                    child: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF94A3B8),
                      size: 20,
                    ),
                  ),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        ),
      ),
    );
  }
}
