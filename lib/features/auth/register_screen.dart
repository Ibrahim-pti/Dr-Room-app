import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'dart:convert';
import '../../core/utils/api_client.dart';
import 'package:flutter/services.dart';
import 'widgets/terms_privacy_modal.dart';

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
  late TapGestureRecognizer _termsRecognizer;
  late TapGestureRecognizer _privacyRecognizer;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = true;
  bool _isLoading = false;

  String? _nameError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => _openTermsAndPrivacy(initialTab: 0);
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => _openTermsAndPrivacy(initialTab: 1);
  }

  void _openTermsAndPrivacy({int initialTab = 0}) {
    HapticFeedback.lightImpact();
    TermsPrivacyModal.show(
      context,
      initialTabIndex: initialTab,
      onAccept: () {
        if (mounted) {
          setState(() {
            _agreeToTerms = true;
            if (_formError == 'must_agree_terms'.tr()) {
              _formError = null;
            }
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidIraqiPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
    // 07XXXXXXXXX (11 digits starting with 07)
    if (clean.length == 11 && clean.startsWith('07')) {
      final prefix = clean.substring(0, 3);
      return ['075', '077', '078', '079', '074', '073', '070', '071', '072'].contains(prefix) ||
          RegExp(r'^07\d{9}$').hasMatch(clean);
    }
    // 7XXXXXXXXX (10 digits starting with 7)
    if (clean.length == 10 && clean.startsWith('7')) {
      return RegExp(r'^7\d{9}$').hasMatch(clean);
    }
    // 9647XXXXXXXXX (12 digits starting with 9647)
    if (clean.length == 12 && clean.startsWith('9647')) {
      return true;
    }
    return false;
  }

  String _normalizeIraqiPhone(String raw) {
    final clean = raw.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
    if (clean.startsWith('9647') && clean.length == 12) {
      return '0${clean.substring(3)}';
    }
    if (clean.startsWith('7') && clean.length == 10) {
      return '0$clean';
    }
    return clean;
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    final isPhoneValid = _isValidIraqiPhone(phone);
    final normalizedPhone = _normalizeIraqiPhone(phone);

    setState(() {
      _nameError = name.isEmpty ? 'name_required'.tr() : null;
      _phoneError = !isPhoneValid ? 'phone_invalid'.tr() : null;
      _passwordError = password.isEmpty
          ? 'password_required'.tr()
          : (password.length < 6 ? 'password_too_short'.tr() : null);
      _confirmPasswordError = (password.isNotEmpty && confirm != password)
          ? 'passwords_do_not_match'.tr()
          : null;
      _formError = !_agreeToTerms ? 'must_agree_terms'.tr() : null;
    });

    if (_nameError != null ||
        _phoneError != null ||
        _passwordError != null ||
        _confirmPasswordError != null ||
        !_agreeToTerms) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.post(
        '/register',
        body: {'name': name, 'phone': normalizedPhone, 'password': password},
      );

      if (response.statusCode == 201) {
        widget.onOtpSent(normalizedPhone);
      } else {
        final err = jsonDecode(response.body);
        final msg = err['message'] ?? 'register_failed'.tr();
        if (mounted) setState(() => _formError = msg);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _formError = '${'server_connection_error'.tr()}: $e');
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
                    onTap: widget.onLogin,
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

              const SizedBox(height: 2),

              // ── Doctor Image ──
              SizedBox(
                    height: size.height * 0.18,
                    width: size.width * 0.55,
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

              const SizedBox(height: 10),

              // ── Title ──
              Text(
                'create_account'.tr().replaceAll('\n', ' '),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  height: 1.25,
                ),
              ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

              const SizedBox(height: 6),

              Text(
                'sign_up_to_get_started'.tr(),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF78909C),
                  height: 1.4,
                ),
              ).animate(delay: 300.ms).fadeIn(duration: 400.ms),

              // ── Form Section ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Name Input
                    _buildInputField(
                          hint: 'full_name'.tr(),
                          icon: Icons.person_outline_rounded,
                          controller: _nameController,
                          errorText: _nameError,
                          onChanged: (_) {
                            if (_nameError != null) {
                              setState(() => _nameError = null);
                            }
                          },
                        )
                        .animate()
                        .fadeIn(delay: 300.ms)
                        .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 14),

                    // Iraqi Phone Input
                    _buildPhoneField()
                        .animate()
                        .fadeIn(delay: 350.ms)
                        .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 14),

                    // Password Input
                    _buildInputField(
                          hint: 'password'.tr(),
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          obscure: _obscurePassword,
                          onToggleObscure: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
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

                    const SizedBox(height: 14),

                    // Confirm Password Input
                    _buildInputField(
                          hint: 'confirm_password'.tr(),
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          obscure: _obscureConfirmPassword,
                          onToggleObscure: () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          ),
                          controller: _confirmPasswordController,
                          errorText: _confirmPasswordError,
                          onChanged: (_) {
                            if (_confirmPasswordError != null) {
                              setState(() => _confirmPasswordError = null);
                            }
                          },
                        )
                        .animate()
                        .fadeIn(delay: 450.ms)
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

                    // Terms & Conditions
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () =>
                              setState(() => _agreeToTerms = !_agreeToTerms),
                          child: Container(
                            margin: const EdgeInsetsDirectional.only(end: 10),
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
                                        color: const Color(0xFF2563EB)
                                            .withValues(alpha: 0.25),
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
                                  recognizer: _termsRecognizer,
                                  style: TextStyle(
                                    color: const Color(0xFF2563EB),
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                    decorationColor: const Color(0xFF2563EB)
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                TextSpan(text: 'and'.tr()),
                                TextSpan(
                                  text: 'privacy_policy'.tr(),
                                  recognizer: _privacyRecognizer,
                                  style: TextStyle(
                                    color: const Color(0xFF2563EB),
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                    decorationColor: const Color(0xFF2563EB)
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 550.ms),

                    const SizedBox(height: 22),

                    // Create Account Button
                    SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
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
                                    'create_account'.tr().replaceAll('\n', ' '),
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 600.ms)
                        .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 20),

                    // Log In Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'already_have_account'.tr(),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: widget.onLogin,
                          child: Text(
                            'log_in'.tr(),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 800.ms),

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

  Widget _buildPhoneField() {
    final hasError = _phoneError != null;
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
          child: Row(
            children: [
              // Iraqi Flag + Code Badge
              Container(
                margin: const EdgeInsetsDirectional.only(start: 10, end: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFDBEAFE),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🇮🇶', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      '+964',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1D4ED8),
                      ),
                    ),
                  ],
                ),
              ),

              // Phone text field
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextField(
                    controller: _phoneController,
                    onChanged: (_) {
                      if (_phoneError != null) {
                        setState(() => _phoneError = null);
                      }
                    },
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                    textAlign: TextAlign.start,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '0750 123 4567',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF94A3B8),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 8,
                      ),
                    ),
                  ),
                ),
              ),

              // Phone icon
              const Padding(
                padding: EdgeInsetsDirectional.only(end: 14),
                child: Icon(
                  Icons.phone_android_rounded,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 6, start: 4),
            child: Text(
              _phoneError!,
              textAlign: TextAlign.start,
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

  Widget _buildInputField({
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool? obscure,
    VoidCallback? onToggleObscure,
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
            obscureText: obscure ?? false,
            textAlign: TextAlign.start,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1E293B),
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF94A3B8),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
              prefixIcon: Icon(icon, color: const Color(0xFF2563EB), size: 20),
              suffixIcon: isPassword
                  ? GestureDetector(
                      onTap: onToggleObscure,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(end: 14),
                        child: Icon(
                          (obscure ?? true)
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF94A3B8),
                          size: 20,
                        ),
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 8,
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 6, start: 4),
            child: Text(
              errorText,
              textAlign: TextAlign.start,
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
