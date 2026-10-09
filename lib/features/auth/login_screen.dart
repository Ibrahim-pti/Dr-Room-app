import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'dart:convert';
import '../../core/utils/api_client.dart';

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
  String? _phoneError;
  String? _passwordError;
  String? _formError;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
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

  Future<void> _handleLogin() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    final isPhoneValid = _isValidIraqiPhone(phone);
    final normalizedPhone = _normalizeIraqiPhone(phone);

    setState(() {
      _phoneError = !isPhoneValid
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
        body: {'phone': normalizedPhone, 'password': password},
      );

      if (response.statusCode == 200) {
        widget.onOtpSent(normalizedPhone);
      } else {
        final err = jsonDecode(response.body);
        final msg = err['message'] ?? 'invalid_phone_or_password'.tr();
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

  void _showForgotPasswordBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final inputBg = isDark
        ? const Color(0xFF334155).withValues(alpha: 0.5)
        : const Color(0xFFF8FAFC);

    final resetPhoneController = TextEditingController(text: _phoneController.text.trim());
    final otpController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();

    int step = 1; // 1: Enter Phone, 2: Enter OTP & New Password
    bool isSubmitting = false;
    bool obscureNew = true;
    bool obscureConfirm = true;
    String? sheetError;
    String targetPhone = '';
    String chosenProvider = 'sms';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Drag Handle
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Top Key Emblem
                      Center(
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFEFF6FF),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Iconsax.key,
                            color: Color(0xFF2563EB),
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Title & Subtitle
                      Text(
                        step == 1
                            ? 'گۆڕینی وشەی نهێنی'
                            : 'وشەی نهێنی نوێ دابنێ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        step == 1
                            ? 'شێوازی ناردن و ژمارەکەت دیاری بکە بۆ وەرگرتنی کۆد'
                            : 'کۆدی ٤ ژمارەیی بنووسە لەگەڵ وشەی نهێنی نوێ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 12.5,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 18),

                      if (sheetError != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            sheetError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 12.5,
                              color: Color(0xFFEF4444),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (step == 1) ...[
                        // Channel selection (SMS vs WhatsApp)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF334155).withValues(alpha: 0.5)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => setSheetState(() => chosenProvider = 'sms'),
                                  borderRadius: BorderRadius.circular(12),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: chosenProvider == 'sms'
                                          ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: chosenProvider == 'sms'
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.06),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.sms_rounded,
                                          size: 17,
                                          color: chosenProvider == 'sms'
                                              ? const Color(0xFF2563EB)
                                              : const Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 7),
                                        Text(
                                          'کورتەنامە (SMS)',
                                          style: TextStyle(
                                            fontFamily: 'Rabar',
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold,
                                            color: chosenProvider == 'sms'
                                                ? const Color(0xFF2563EB)
                                                : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: InkWell(
                                  onTap: () => setSheetState(() => chosenProvider = 'whatsapp'),
                                  borderRadius: BorderRadius.circular(12),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: chosenProvider == 'whatsapp'
                                          ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: chosenProvider == 'whatsapp'
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.06),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.chat_bubble_outline_rounded,
                                          size: 17,
                                          color: chosenProvider == 'whatsapp'
                                              ? const Color(0xFF16A34A)
                                              : const Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 7),
                                        Text(
                                          'واتسئاپ (WhatsApp)',
                                          style: TextStyle(
                                            fontFamily: 'Rabar',
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold,
                                            color: chosenProvider == 'whatsapp'
                                                ? const Color(0xFF16A34A)
                                                : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Phone Field with +964 flag pill matching login
                        Container(
                          decoration: BoxDecoration(
                            color: inputBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
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
                                      '\u200E+964',
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
                                  controller: resetPhoneController,
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
                                    hintText: '\u200E0750 000 0000',
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
                        const SizedBox(height: 20),

                        // Send OTP Button
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    final raw = resetPhoneController.text.trim();
                                    if (!_isValidIraqiPhone(raw)) {
                                      setSheetState(() => sheetError = 'phone_invalid'.tr());
                                      return;
                                    }
                                    final norm = _normalizeIraqiPhone(raw);
                                    setSheetState(() {
                                      isSubmitting = true;
                                      sheetError = null;
                                    });

                                    try {
                                      final res = await ApiClient.post(
                                        '/forgot-password',
                                        body: {
                                          'phone': norm,
                                          'provider': chosenProvider,
                                        },
                                      );
                                      if (res.statusCode == 200) {
                                        targetPhone = norm;
                                        setSheetState(() {
                                          step = 2;
                                          isSubmitting = false;
                                          sheetError = null;
                                        });
                                      } else {
                                        final b = jsonDecode(res.body);
                                        setSheetState(() {
                                          isSubmitting = false;
                                          sheetError = b['message'] ?? 'نەتوانرا کۆدەکە بنێردرێت';
                                        });
                                      }
                                    } catch (e) {
                                      setSheetState(() {
                                        isSubmitting = false;
                                        sheetError = '${'server_connection_error'.tr()}: $e';
                                      });
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: chosenProvider == 'whatsapp'
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        chosenProvider == 'whatsapp'
                                            ? Icons.chat_bubble_outline_rounded
                                            : Icons.send_rounded,
                                        size: 19,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        chosenProvider == 'whatsapp'
                                            ? 'ناردنی کۆد بە واتسئاپ'
                                            : 'ناردنی کۆدی دڵنیابوونەوە (SMS)',
                                        style: const TextStyle(
                                          fontFamily: 'Rabar',
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ] else ...[
                        // Step 2: Target Phone Info Bar + Change Button
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF334155).withValues(alpha: 0.4)
                                : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF475569)
                                  : const Color(0xFFBFDBFE),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                chosenProvider == 'whatsapp'
                                    ? Icons.chat_bubble_outline_rounded
                                    : Icons.sms_outlined,
                                size: 18,
                                color: chosenProvider == 'whatsapp'
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'کۆد نێردرا بۆ: $targetPhone (${chosenProvider == 'whatsapp' ? 'واتسئاپ' : 'SMS'})',
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF1E40AF),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: isSubmitting
                                    ? null
                                    : () => setSheetState(() {
                                          step = 1;
                                          sheetError = null;
                                        }),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'گۆڕین',
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Step 2: OTP, New Password, Confirm Password
                        Container(
                          decoration: BoxDecoration(
                            color: inputBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: TextField(
                            controller: otpController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 4,
                            style: const TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 12,
                              color: Color(0xFF2563EB),
                            ),
                            decoration: const InputDecoration(
                              counterText: '',
                              hintText: '----',
                              hintStyle: TextStyle(color: Color(0xFF94A3B8), letterSpacing: 8),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // New Password
                        Container(
                          decoration: BoxDecoration(
                            color: inputBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: TextField(
                            controller: newPassController,
                            obscureText: obscureNew,
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 15,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            decoration: InputDecoration(
                              hintText: 'وشەی نهێنی نوێ (لایەنی کەم ٦ پیت)',
                              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                              prefixIcon: const Icon(Iconsax.lock, color: Color(0xFF2563EB)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscureNew ? Iconsax.eye_slash : Iconsax.eye,
                                  color: const Color(0xFF94A3B8),
                                ),
                                onPressed: () => setSheetState(() => obscureNew = !obscureNew),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Confirm Password
                        Container(
                          decoration: BoxDecoration(
                            color: inputBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: TextField(
                            controller: confirmPassController,
                            obscureText: obscureConfirm,
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 15,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            decoration: InputDecoration(
                              hintText: 'دووبارەکردنەوەی وشەی نهێنی',
                              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                              prefixIcon: const Icon(Iconsax.lock, color: Color(0xFF2563EB)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscureConfirm ? Iconsax.eye_slash : Iconsax.eye,
                                  color: const Color(0xFF94A3B8),
                                ),
                                onPressed: () => setSheetState(() => obscureConfirm = !obscureConfirm),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Submit Reset Button
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    final otp = otpController.text.trim();
                                    final pass = newPassController.text;
                                    final conf = confirmPassController.text;

                                    if (otp.length != 4) {
                                      setSheetState(() => sheetError = 'تکایە کۆدی ٤ ژمارەیی بنووسە');
                                      return;
                                    }
                                    if (pass.length < 6) {
                                      setSheetState(() => sheetError = 'وشەی نهێنی دەبێت لانیکەم ٦ پیت بێت');
                                      return;
                                    }
                                    if (pass != conf) {
                                      setSheetState(() => sheetError = 'وشەی نهێنی لەگەڵ دووبارەکردنەوەکەی یەک ناگرێتەوە');
                                      return;
                                    }

                                    setSheetState(() {
                                      isSubmitting = true;
                                      sheetError = null;
                                    });

                                    final messenger = ScaffoldMessenger.of(context);

                                    try {
                                      final res = await ApiClient.post(
                                        '/reset-password',
                                        body: {
                                          'phone': targetPhone,
                                          'otp_code': otp,
                                          'password': pass,
                                        },
                                      );

                                      if (res.statusCode == 200) {
                                        if (ctx.mounted) {
                                          Navigator.pop(ctx);
                                        }
                                        if (!mounted) return;
                                        _phoneController.text = targetPhone;
                                        _passwordController.text = pass;
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'وشەی نهێنی بە سەرکەوتوویی نوێکرایەوە. دەتوانیت ئێستا بچیتە ژوورەوە.',
                                              style: TextStyle(fontFamily: 'Rabar'),
                                            ),
                                            backgroundColor: Color(0xFF10B981),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      } else {
                                        final b = jsonDecode(res.body);
                                        setSheetState(() {
                                          isSubmitting = false;
                                          sheetError = b['message'] ?? 'هەڵەیەک ڕوویدا لە نوێکردنەوەی وشەی نهێنی';
                                        });
                                      }
                                    } catch (e) {
                                      setSheetState(() {
                                        isSubmitting = false;
                                        sheetError = '${'server_connection_error'.tr()}: $e';
                                      });
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                : const Text(
                                    'نوێکردنەوەی وشەی نهێنی',
                                    style: TextStyle(
                                      fontFamily: 'Rabar',
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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
                  height: 320,
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
                        bottom: 20,
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
                              const SizedBox(height: 20),
                              SizedBox(
                                width: 80,
                                height: 80,
                                child: Image.asset(
                                  'assets/images/app_icon.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.local_hospital_rounded,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              ).animate().scale(
                                duration: 500.ms,
                                curve: Curves.easeOutBack,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'log_in'.tr(),
                                style: const TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 23,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                              const SizedBox(height: 6),
                              Text(
                                    'welcome_back_app'.tr(),
                                    style: const TextStyle(
                                      fontFamily: 'Rabar',
                                      fontSize: 13.5,
                                      color: Colors.white70,
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(delay: 150.ms)
                                  .slideY(begin: 0.2, end: 0),
                              const SizedBox(height: 12),
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
              offset: const Offset(0, -24),
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
                            // Flag / Prefix
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
                                    '\u200E+964',
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
                                  hintText: '\u200E0750 000 0000',
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

                      const SizedBox(height: 18),

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

                      // Forgot Password Link
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () => _showForgotPasswordBottomSheet(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            minimumSize: const Size(0, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'forgot_password'.tr(),
                            style: const TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
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
                                    const Icon(Iconsax.login_1, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'log_in'.tr(),
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

            // ── Register Link ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'dont_have_account_question'.tr(),
                  style: const TextStyle(
                    fontFamily: 'Rabar',
                    color: Color(0xFF64748B),
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: widget.onSignUp,
                  child: Text(
                    'sign_up'.tr(),
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
          ],
        ),
      ),
    );
  }
}