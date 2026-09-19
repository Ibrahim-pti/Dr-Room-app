import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

import 'dart:convert';
import '../../core/utils/api_client.dart';
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
            _formError = null;
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
    if (clean.length == 11 && clean.startsWith('07')) {
      final prefix = clean.substring(0, 3);
      return [
            '075',
            '077',
            '078',
            '079',
            '074',
            '073',
            '070',
            '071',
            '072',
          ].contains(prefix) ||
          RegExp(r'^07\d{9}$').hasMatch(clean);
    }
    if (clean.length == 10 && clean.startsWith('7')) {
      return RegExp(r'^7\d{9}$').hasMatch(clean);
    }
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

  void _handleRegister() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final isPhoneValid = _isValidIraqiPhone(phone);
    final normalizedPhone = _normalizeIraqiPhone(phone);

    setState(() {
      _nameError = name.isEmpty ? 'name_required'.tr() : null;
      _phoneError = !isPhoneValid ? 'phone_invalid'.tr() : null;
      _passwordError = password.length < 6 ? 'password_too_short'.tr() : null;
      _confirmPasswordError = password != confirmPassword ? 'passwords_do_not_match'.tr() : null;
      _formError = !_agreeToTerms ? 'must_agree_terms'.tr() : null;
    });

    if (_nameError != null ||
        _phoneError != null ||
        _passwordError != null ||
        _confirmPasswordError != null ||
        _formError != null) {
      return;
    }

    _showOtpChannelSelectionModal(context, normalizedPhone);
  }

  void _showOtpChannelSelectionModal(BuildContext context, String normalizedPhone) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),

                // Icon
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: Color(0xFF2563EB),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 14),

                Text(
                  'choose_otp_channel'.tr(),
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'choose_otp_channel_desc'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 13,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 20),

                // WhatsApp Card Option
                InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    _submitRegistration(normalizedPhone, 'whatsapp');
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withValues(alpha: isDark ? 0.14 : 0.06),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFF25D366).withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.chat_bubble_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'receive_via_whatsapp'.tr(),
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'receive_via_whatsapp_desc'.tr(),
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 12,
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: Color(0xFF25D366),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // SMS Card Option
                InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    _submitRegistration(normalizedPhone, 'sms');
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.14 : 0.06),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.sms_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'receive_via_sms'.tr(),
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'receive_via_sms_desc'.tr(),
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 12,
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: Color(0xFF2563EB),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitRegistration(String normalizedPhone, String provider) async {
    final name = _nameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() => _isLoading = true);

    try {
      final response = await ApiClient.post(
        '/register',
        body: {
          'name': name,
          'phone': normalizedPhone,
          'password': password,
          'password_confirmation': confirmPassword,
          'provider': provider,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Top Curved Gradient Header ──
            Stack(
              children: [
                Container(
                  height: 230,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF1E3A8A),
                        Color(0xFF2563EB),
                        Color(0xFF3B82F6),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(36),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative Circles
                      Positioned(
                        top: -40,
                        right: -30,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        left: -40,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                      ),

                      // Header Content
                      SafeArea(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.15,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Iconsax.user_add,
                                  color: Color(0xFF2563EB),
                                  size: 28,
                                ),
                              ).animate().scale(
                                duration: 500.ms,
                                curve: Curves.easeOutBack,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'create_new_account'.tr(),
                                style: const TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                              const SizedBox(height: 3),
                              Text(
                                    'enter_info_to_register'.tr(),
                                    style: const TextStyle(
                                      fontFamily: 'Rabar',
                                      fontSize: 12.5,
                                      color: Colors.white70,
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(delay: 150.ms)
                                  .slideY(begin: 0.2, end: 0),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Form Container ──
            Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.3 : 0.06,
                        ),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Error Banner
                      if (_formError != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 18),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Color(0xFFDC2626),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _formError!,
                                  style: const TextStyle(
                                    fontFamily: 'Rabar',
                                    color: Color(0xFFDC2626),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().shake(),

                      // Name Label
                      Text(
                        'full_name'.tr(),
                        style: const TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Name Field
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF334155).withValues(alpha: 0.5)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _nameError != null
                                ? const Color(0xFFEF4444)
                                : borderColor,
                          ),
                        ),
                        child: TextField(
                          controller: _nameController,
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 14.5,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            hintText: 'full_name'.tr(),
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13.5,
                            ),

                            prefixIcon: Icon(
                              Iconsax.user,
                              color: Color(0xFF94A3B8),
                              size: 18,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (_nameError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, right: 6),
                          child: Text(
                            _nameError!,
                            style: const TextStyle(
                              fontFamily: 'Rabar',
                              color: Color(0xFFEF4444),
                              fontSize: 11.5,
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Phone Label
                      Text(
                        'phone_number'.tr(),
                        style: const TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Phone Field
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF334155).withValues(alpha: 0.5)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _phoneError != null
                                ? const Color(0xFFEF4444)
                                : borderColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFEFF6FF),
                                borderRadius:
                                    const BorderRadiusDirectional.horizontal(
                                      start: Radius.circular(15),
                                    ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text('🇮🇶', style: TextStyle(fontSize: 16)),
                                  SizedBox(width: 6),
                                  Text(
                                    '+964',
                                    style: TextStyle(
                                      fontFamily: 'Rabar',
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.right,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(11),
                                ],
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                                decoration: const InputDecoration(
                                  hintText: '0000 000 0750',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 14,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_phoneError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, right: 6),
                          child: Text(
                            _phoneError!,
                            style: const TextStyle(
                              fontFamily: 'Rabar',
                              color: Color(0xFFEF4444),
                              fontSize: 11.5,
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Password Label
                      Text(
                        'password'.tr(),
                        style: const TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Password Field
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF334155).withValues(alpha: 0.5)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _passwordError != null
                                ? const Color(0xFFEF4444)
                                : borderColor,
                          ),
                        ),
                        child: TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 15,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Iconsax.lock,
                              color: Color(0xFF94A3B8),
                              size: 18,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Iconsax.eye_slash
                                    : Iconsax.eye,
                                color: const Color(0xFF94A3B8),
                                size: 18,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (_passwordError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, right: 6),
                          child: Text(
                            _passwordError!,
                            style: const TextStyle(
                              fontFamily: 'Rabar',
                              color: Color(0xFFEF4444),
                              fontSize: 11.5,
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Confirm Password Label
                      Text(
                        'confirm_password'.tr(),
                        style: const TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Confirm Password Field
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF334155).withValues(alpha: 0.5)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _confirmPasswordError != null
                                ? const Color(0xFFEF4444)
                                : borderColor,
                          ),
                        ),
                        child: TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 15,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Iconsax.lock,
                              color: Color(0xFF94A3B8),
                              size: 18,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Iconsax.eye_slash
                                    : Iconsax.eye,
                                color: const Color(0xFF94A3B8),
                                size: 18,
                              ),
                              onPressed: () => setState(
                                () => _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (_confirmPasswordError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, right: 6),
                          child: Text(
                            _confirmPasswordError!,
                            style: const TextStyle(
                              fontFamily: 'Rabar',
                              color: Color(0xFFEF4444),
                              fontSize: 11.5,
                            ),
                          ),
                        ),

                      const SizedBox(height: 18),

                      // Terms & Privacy Checkbox
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _agreeToTerms,
                              activeColor: const Color(0xFF2563EB),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              onChanged: (v) =>
                                  setState(() => _agreeToTerms = v ?? false),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 12.5,
                                  color: Color(0xFF64748B),
                                ),
                                children: [
                                  TextSpan(text: 'agree_to_terms_prefix'.tr()),
                                  TextSpan(
                                    text: 'terms_and_conditions'.tr(),
                                    recognizer: _termsRecognizer,
                                    style: const TextStyle(
                                      color: Color(0xFF2563EB),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(text: 'and_word'.tr()),
                                  TextSpan(
                                    text: 'privacy_protection'.tr(),
                                    recognizer: _privacyRecognizer,
                                    style: const TextStyle(
                                      color: Color(0xFF2563EB),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shadowColor: const Color(
                              0xFF2563EB,
                            ).withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Iconsax.user_add, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'sign_up'.tr(),
                                      style: const TextStyle(
                                        fontFamily: 'Rabar',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Login Link ──
            Padding(
              padding: const EdgeInsets.only(bottom: 32, top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                Text(
                  'already_have_account_question'.tr(),
                  style: const TextStyle(
                    fontFamily: 'Rabar',
                    color: Color(0xFF64748B),
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: widget.onLogin,
                  child: Text(
                    'log_in'.tr(),
                    style: const TextStyle(
                      fontFamily: 'Rabar',
                      color: Color(0xFF2563EB),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}