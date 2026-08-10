import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:convert';
import '../../core/utils/api_client.dart';
import '../../core/utils/firebase_auth_service.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  final void Function(String phone, String verificationId) onOtpSent;
  final void Function(String role) onVerified;
  final VoidCallback onSignUp;

  const LoginScreen({
    super.key,
    required this.onOtpSent,
    required this.onVerified,
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
  String? _phoneError;
  String? _passwordError;
  String? _formError;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _phoneError = (phone.isEmpty || phone.length != 11)
          ? 'phone_invalid'.tr()
          : null;
      _passwordError = password.isEmpty ? 'password_required'.tr() : null;
      _formError = null;
    });

    if (_phoneError != null || _passwordError != null) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiClient.post(
        '/login',
        body: {'phone': phone, 'password': password},
      );

      if (response.statusCode == 200) {
        await FirebaseAuthService.sendOtp(
          localPhone: phone,
          onCodeSent: (verificationId) {
            if (mounted) widget.onOtpSent(phone, verificationId);
          },
          onAutoVerified: (role) {
            if (mounted) widget.onVerified(role);
          },
          onFailed: (message) {
            if (mounted) setState(() => _formError = 'otp_send_failed'.tr());
          },
        );
      } else {
        final err = jsonDecode(response.body);
        final msg = err['message'] ?? 'login_failed'.tr();
        if (mounted) setState(() => _formError = msg);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _formError = '${'server_connection_error'.tr()}: $e');
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 8),

              // ── Back Button ──
              Align(
                alignment: AlignmentDirectional.topStart,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // ── Doctor Image ──
              SizedBox(
                    height: size.height * 0.32,
                    width: size.width * 0.90,
                    child: Image.asset(
                      'assets/images/doctor2.png',
                      fit: BoxFit.contain,
                    ),
                  )
                  .animate(delay: 100.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(
                    begin: 0.08,
                    end: 0,
                    duration: 500.ms,
                    curve: Curves.easeOut,
                  ),

              const SizedBox(height: 12),

              // ── Welcome Text ──
              Text(
                'welcome_back'.tr(),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  height: 1.25,
                  letterSpacing: -0.3,
                ),
              ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

              const SizedBox(height: 6),

              Text(
                'sign_in_continue'.tr(),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF78909C),
                  height: 1.5,
                  letterSpacing: 0.1,
                ),
              ).animate(delay: 300.ms).fadeIn(duration: 400.ms),

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
                          errorText: _phoneError,
                          onChanged: (_) {
                            if (_phoneError != null) {
                              setState(() => _phoneError = null);
                            }
                          },
                        )
                        .animate()
                        .fadeIn(delay: 300.ms)
                        .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 16),

                    // Password Input
                    _buildInputField(
                          hint: 'password'.tr(),
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          controller: _passwordController,
                          errorText: _passwordError,
                          onChanged: (_) {
                            if (_passwordError != null) {
                              setState(() => _passwordError = null);
                            }
                          },
                        )
                        .animate()
                        .fadeIn(delay: 400.ms)
                        .slideY(begin: 0.2, end: 0),

                    if (_formError != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFECACA),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _formError!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ).animate().fadeIn(duration: 250.ms),
                    ],

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
                            decorationColor: const Color(
                              0xFF2563EB,
                            ).withValues(alpha: 0.2),
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
                              disabledBackgroundColor: const Color(
                                0xFF2563EB,
                              ).withValues(alpha: 0.6),
                              foregroundColor: Colors.white,
                              elevation: 3,
                              shadowColor: const Color(
                                0xFF2563EB,
                              ).withValues(alpha: 0.25),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
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
                        )
                        .animate()
                        .fadeIn(delay: 600.ms)
                        .slideY(begin: 0.2, end: 0),

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
      ),
    );
  }

  Widget _buildInputField({
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isPhone = false,
    required TextEditingController controller,
    String? errorText,
    void Function(String)? onChanged,
  }) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasError
                  ? const Color(0xFFEF4444)
                  : const Color(0xFFE2E8F0),
              width: hasError ? 1.4 : 1.2,
            ),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            obscureText: isPassword ? _obscurePassword : false,
            keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
            inputFormatters: isPhone
                ? [FilteringTextInputFormatter.digitsOnly]
                : null,
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
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsetsDirectional.only(start: 14, end: 12),
                child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
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
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 4,
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 6, start: 4),
            child: Text(
              errorText,
              textAlign: TextAlign.end,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFEF4444),
              ),
            ),
          ),
      ],
    );
  }
}
