import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
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
          ? 'تکایە ژمارە مۆبایلێکی عێراقی دروست بنووسە'
          : null;
      _passwordError = password.isEmpty ? 'تکایە وشەی نهێنی بنووسە' : null;
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
        final msg = err['message'] ?? 'ژمارە مۆبایل یان وشەی نهێنی هەڵەیە';
        if (mounted) setState(() => _formError = msg);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _formError = 'کێشە لە پەیوەندی بە سێرڤەر هەیە: $e');
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
                              Container(
                                width: 68,
                                height: 68,
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
                                  Icons.local_hospital_rounded,
                                  color: Color(0xFF2563EB),
                                  size: 36,
                                ),
                              ).animate().scale(
                                duration: 500.ms,
                                curve: Curves.easeOutBack,
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'چوونەژوورەوە',
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 23,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                              const SizedBox(height: 6),
                              const Text(
                                    'بەخێربێیتەوە بۆ ئەپڵیکەیشنی دکتۆر ڕووم',
                                    style: TextStyle(
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
                      const Text(
                        'ژمارەی مۆبایل',
                        style: TextStyle(
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

                      const SizedBox(height: 18),

                      // Password Label
                      const Text(
                        'وشەی نهێنی',
                        style: TextStyle(
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
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'تکایە پەیوەندی بە بەشی پشتگیرییەوە بکە بۆ گۆڕینی وشەی نهێنی',
                                  style: TextStyle(fontFamily: 'Rabar'),
                                ),
                                backgroundColor: Color(0xFF2563EB),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            minimumSize: const Size(0, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'وشەی نهێنیت لەبیرچووە؟',
                            style: TextStyle(
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
                                  children: const [
                                    Icon(Iconsax.login_1, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'چوونەژوورەوە',
                                      style: TextStyle(
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
                const Text(
                  'هێشتا هەژمارت نییە؟',
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    color: Color(0xFF64748B),
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: widget.onSignUp,
                  child: const Text(
                    'دروستکردنی هەژمار',
                    style: TextStyle(
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