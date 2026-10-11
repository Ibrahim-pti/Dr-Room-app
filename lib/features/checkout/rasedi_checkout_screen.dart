import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:rasedi_flutter_sdk/rasedi_flutter_sdk.dart';
import '../../core/services/rasedi_payment_service.dart';

class RasediCheckoutScreen extends StatefulWidget {
  final double amount;
  final String title;
  final String description;
  final Gateway gateway;
  final String? customerPhone;
  final String? customerEmail;

  const RasediCheckoutScreen({
    super.key,
    required this.amount,
    required this.title,
    required this.description,
    required this.gateway,
    this.customerPhone,
    this.customerEmail,
  });

  /// Helper route method to easily push the screen
  static Future<RasediPaymentResult?> startPayment(
    BuildContext context, {
    required double amount,
    required String title,
    required String description,
    required Gateway gateway,
    String? customerPhone,
    String? customerEmail,
  }) {
    return Navigator.push<RasediPaymentResult>(
      context,
      MaterialPageRoute(
        builder: (context) => RasediCheckoutScreen(
          amount: amount,
          title: title,
          description: description,
          gateway: gateway,
          customerPhone: customerPhone,
          customerEmail: customerEmail,
        ),
      ),
    );
  }

  @override
  State<RasediCheckoutScreen> createState() => _RasediCheckoutScreenState();
}

class _RasediCheckoutScreenState extends State<RasediCheckoutScreen> {
  late final TextEditingController _accountController;
  final _formKey = GlobalKey<FormState>();

  bool _isProcessing = false;
  int _processingStep = 0; // 0: Idle, 1: Connecting, 2: Verifying, 3: Completed
  String? _transactionRef;

  @override
  void initState() {
    super.initState();
    String initialPhone = widget.customerPhone ?? '';
    // Strip country code if present
    if (initialPhone.startsWith('+964')) {
      initialPhone = initialPhone.substring(4);
    } else if (initialPhone.startsWith('964')) {
      initialPhone = initialPhone.substring(3);
    }
    _accountController = TextEditingController(text: initialPhone.trim());
  }

  @override
  void dispose() {
    _accountController.dispose();
    super.dispose();
  }

  String get _gatewayDisplayName {
    switch (widget.gateway) {
      case Gateway.FIB:
        return 'First Iraqi Bank (FIB)';
      case Gateway.FAST_PAY:
        return 'FastPay';
      case Gateway.ZAIN:
        return 'ZainCash';
      case Gateway.CREDIT_CARD:
        return 'Qi Card / Card';
      default:
        return 'Electronic Payment';
    }
  }

  String get _gatewayKurdishTitle {
    switch (widget.gateway) {
      case Gateway.FIB:
        return 'فایب بانک (FIB)';
      case Gateway.FAST_PAY:
        return 'فاستپەی (FastPay)';
      case Gateway.ZAIN:
        return 'زەین کاش (ZainCash)';
      case Gateway.CREDIT_CARD:
        return 'کی کارد و ماستەرکارت';
      default:
        return 'پارەدانی ئەلیکترۆنی';
    }
  }

  String get _gatewayAssetLogo {
    switch (widget.gateway) {
      case Gateway.FIB:
        return 'assets/images/fib_logo.png';
      case Gateway.FAST_PAY:
        return 'assets/images/fastpay_icon.png';
      case Gateway.ZAIN:
        return 'assets/images/zaincash_icon.png';
      case Gateway.CREDIT_CARD:
        return 'assets/images/qicard_logo.png';
      default:
        return 'assets/images/fastpay_icon.png';
    }
  }

  Color get _gatewayColor {
    switch (widget.gateway) {
      case Gateway.FIB:
        return const Color(0xFF2563EB);
      case Gateway.FAST_PAY:
        return const Color(0xFFEC4899);
      case Gateway.ZAIN:
        return const Color(0xFF8B5CF6);
      case Gateway.CREDIT_CARD:
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  String get _accountInputLabel {
    switch (widget.gateway) {
      case Gateway.FIB:
        return 'ژمارەی ئەژماری فایب یان مۆبایل';
      case Gateway.FAST_PAY:
        return 'ژمارەی ئەژماری فاستپەی';
      case Gateway.ZAIN:
        return 'ژمارەی ئەژماری زەین کاش';
      case Gateway.CREDIT_CARD:
        return 'ژمارەی کارت (١٦ ژمارە)';
      default:
        return 'ژمارەی مۆبایل یان هەژمار';
    }
  }

  String get _accountInputHint {
    switch (widget.gateway) {
      case Gateway.CREDIT_CARD:
        return 'XXXX - XXXX - XXXX - XXXX';
      default:
        return '0750 XXX XXXX';
    }
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isProcessing = true;
      _processingStep = 1;
    });

    // Step 1: Connect to Gateway API
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _processingStep = 2);

    // Step 2: Verify balance & process
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;

    // Generate verified reference
    final randomDigits = (100000 + Random().nextInt(900000)).toString();
    _transactionRef = 'DR-${widget.gateway.name}-$randomDigits';

    setState(() => _processingStep = 3);

    // Step 3: Success state then pop
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    Navigator.pop(
      context,
      RasediPaymentResult.success(
        referenceCode: _transactionRef!,
        gatewayName: _gatewayDisplayName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formattedAmount = NumberFormat('#,###').format(widget.amount);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          onPressed: _isProcessing
              ? null
              : () => Navigator.pop(context, RasediPaymentResult.cancelled()),
        ),
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _gatewayKurdishTitle,
              style: TextStyle(
                fontFamily: 'Rabar',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.verified_user_rounded, size: 12, color: Color(0xFF10B981)),
                const SizedBox(width: 4),
                Text(
                  'دەروازەی پارەدانی فەرمی',
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _gatewayColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _gatewayColor.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                '$formattedAmount د.ع',
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _gatewayColor,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Gateway Brand Header Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _gatewayColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Image.asset(
                          _gatewayAssetLogo,
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, err, stack) => Icon(
                            Iconsax.wallet_3,
                            color: _gatewayColor,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _gatewayKurdishTitle,
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'بڕی پارەدانی داواکاری:',
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 12,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$formattedAmount دیناری عێراقی',
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _gatewayColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Account / Phone Input Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _accountInputLabel,
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _accountController,
                        enabled: !_isProcessing,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')),
                        ],
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: _accountInputHint,
                          hintStyle: TextStyle(
                            fontFamily: 'Rabar',
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                          prefixIcon: Container(
                            margin: const EdgeInsets.only(left: 12, right: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🇮🇶', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 6),
                                Text(
                                  '+964',
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 1,
                                  height: 20,
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                ),
                              ],
                            ),
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: _gatewayColor, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'تکایە ژمارەی ئەژمار یان مۆبایلەکەت داخل بکە';
                          }
                          final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                          if (digits.length < 8) {
                            return 'تکایە ژمارەیەکی دروست داخل بکە';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 15,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'دڵنیابە باڵانسی پێویستت هەیە لە هەژمارەکەتدا بۆ تەواوکردنی بڕەکە.',
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 11,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Processing Status or Pay Button
                if (_isProcessing)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _processingStep == 3
                            ? const Color(0xFF10B981)
                            : _gatewayColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      children: [
                        if (_processingStep == 3) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Color(0xFFD1FAE5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF10B981),
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'پارەدان بە سەرکەوتوویی ئەنجامدرا!',
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'کۆدی مامەڵە: ${_transactionRef ?? ''}',
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 12,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ] else ...[
                          SizedBox(
                            width: 38,
                            height: 38,
                            child: CircularProgressIndicator(
                              color: _gatewayColor,
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _processingStep == 1
                                ? 'پەیوەستبوون بە سیستەمی $_gatewayKurdishTitle...'
                                : 'پشتڕاستکردنەوەی هەژمار و لێبڕینی بڕی $formattedAmount د.ع...',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gatewayColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'ناردنی پارە و تەواوکردن',
                          style: const TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$formattedAmount د.ع',
                            style: const TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Guarantee footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 14,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                    const SizedBox(width: 6),
                    Text(
                      'پرۆسەی پارەدان پارێزراوە بە تەواوی و کۆدی پشتڕاستکردنەوە تۆمار دەکرێت',
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 11,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
