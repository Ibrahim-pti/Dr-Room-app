import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import '../../core/services/service_fee_service.dart';
import '../../core/theme/app_colors.dart';
import 'admin_app_bar.dart';

class AdminServiceFeeScreen extends StatefulWidget {
  const AdminServiceFeeScreen({super.key});

  @override
  State<AdminServiceFeeScreen> createState() => _AdminServiceFeeScreenState();
}

class _AdminServiceFeeScreenState extends State<AdminServiceFeeScreen> {
  late bool _isEnabled;
  late bool _isFree;
  late bool _hasDiscount;
  String _discountType = 'percent'; // 'percent' or 'fixed'
  late TextEditingController _amountController;
  late TextEditingController _discountPercentController;
  late TextEditingController _discountAmountController;
  late TextEditingController _noteController;
  bool _isSaving = false;
  bool _isLoadingBackend = false;

  final List<double> _presets = [1000, 1500, 2000, 2500, 3000, 5000];
  final List<double> _discountPercentPresets = [25, 50, 75, 100];
  final List<double> _discountAmountPresets = [250, 500, 1000, 1500];

  TextStyle _rabar({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? height = 1.35,
  }) {
    return TextStyle(
      fontFamily: 'Rabar',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  @override
  void initState() {
    super.initState();
    final model = ServiceFeeService.instance.feeModel;
    _populateFromModel(model);
    _loadFromBackend();
  }

  void _populateFromModel(ServiceFeeModel model) {
    _isEnabled = model.isEnabled;
    _isFree = model.isFree;
    _hasDiscount = model.hasDiscount;
    _discountType = (model.discountAmount > 0 && model.discountPercent == 0) ? 'fixed' : 'percent';

    _amountController = TextEditingController(
      text: model.amount > 0 ? model.amount.toInt().toString() : '1000',
    );
    _discountPercentController = TextEditingController(
      text: model.discountPercent > 0 ? model.discountPercent.toInt().toString() : '50',
    );
    _discountAmountController = TextEditingController(
      text: model.discountAmount > 0 ? model.discountAmount.toInt().toString() : '500',
    );
    _noteController = TextEditingController(
      text: model.note ?? 'service_fee_default_note'.tr(),
    );
  }

  Future<void> _loadFromBackend() async {
    setState(() => _isLoadingBackend = true);
    final freshModel = await ServiceFeeService.instance.fetchRemoteConfig();
    if (!mounted) return;

    if (freshModel != null) {
      setState(() {
        _isEnabled = freshModel.isEnabled;
        _isFree = freshModel.isFree;
        _hasDiscount = freshModel.hasDiscount;
        _discountType = (freshModel.discountAmount > 0 && freshModel.discountPercent == 0) ? 'fixed' : 'percent';
        _amountController.text = freshModel.amount > 0 ? freshModel.amount.toInt().toString() : '1000';
        _discountPercentController.text = freshModel.discountPercent > 0 ? freshModel.discountPercent.toInt().toString() : '50';
        _discountAmountController.text = freshModel.discountAmount > 0 ? freshModel.discountAmount.toInt().toString() : '500';
        if (freshModel.note != null && freshModel.note!.isNotEmpty) {
          _noteController.text = freshModel.note!;
        }
        _isLoadingBackend = false;
      });
    } else {
      setState(() => _isLoadingBackend = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _discountPercentController.dispose();
    _discountAmountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _baseAmount {
    if (_isFree || !_isEnabled) return 0.0;
    return double.tryParse(_amountController.text.trim()) ?? 0.0;
  }

  double get _discountValue {
    if (!_isEnabled || _isFree || !_hasDiscount) return 0.0;
    final base = _baseAmount;
    if (base <= 0) return 0.0;

    if (_discountType == 'percent') {
      final pct = double.tryParse(_discountPercentController.text.trim()) ?? 0.0;
      if (pct <= 0) return 0.0;
      final val = (base * (pct / 100)).roundToDouble();
      return val > base ? base : val;
    } else {
      final amt = double.tryParse(_discountAmountController.text.trim()) ?? 0.0;
      return amt > base ? base : amt;
    }
  }

  double get _effectiveAmount {
    if (!_isEnabled || _isFree) return 0.0;
    final res = _baseAmount - _discountValue;
    return res < 0.0 ? 0.0 : res;
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    final amountVal = double.tryParse(_amountController.text.trim()) ?? 1000.0;
    final pctVal = _discountType == 'percent'
        ? (double.tryParse(_discountPercentController.text.trim()) ?? 0.0)
        : 0.0;
    final fixedVal = _discountType == 'fixed'
        ? (double.tryParse(_discountAmountController.text.trim()) ?? 0.0)
        : 0.0;

    final newModel = ServiceFeeModel(
      isEnabled: _isEnabled,
      isFree: _isFree,
      amount: amountVal,
      hasDiscount: _hasDiscount,
      discountPercent: pctVal,
      discountAmount: fixedVal,
      note: _noteController.text.trim(),
    );

    final success = await ServiceFeeService.instance.updateFee(newModel);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                'service_fee_saved_success'.tr(),
                style: _rabar(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                'service_fee_saved_error'.tr(),
                style: _rabar(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final currency = 'currency_iqd'.tr();

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AdminAppBar(
        title: 'service_fee_settings_title'.tr(),
        subtitle: 'service_fee_settings_desc'.tr(),
        icon: Iconsax.receipt_item,
        iconColor: const Color(0xFF2563EB),
        iconBackgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoadingBackend)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'دابەزاندنی زانیارییەکان لە باکێندەوە...',
                        style: _rabar(fontSize: 12.5, color: const Color(0xFF2563EB), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Section 1: Main Status Card ──
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (_isEnabled ? const Color(0xFF10B981) : const Color(0xFF94A3B8))
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _isEnabled ? Iconsax.tick_circle : Iconsax.close_circle,
                      color: _isEnabled ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'service_fee_enable_title'.tr(),
                          style: _rabar(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isEnabled
                              ? 'service_fee_active_desc'.tr()
                              : 'service_fee_inactive_desc'.tr(),
                          style: _rabar(
                            fontSize: 12.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _isEnabled,
                    activeColor: const Color(0xFF10B981),
                    onChanged: (val) {
                      setState(() => _isEnabled = val);
                    },
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.05, end: 0),

            const SizedBox(height: 20),

            // ── Section 2: Fee Mode (Free vs Custom Price) ──
            if (_isEnabled) ...[
              Text(
                'service_fee_type_title'.tr(),
                style: _rabar(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  // Option A: Custom Price
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isFree = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          color: !_isFree
                              ? const Color(0xFF2563EB).withValues(alpha: 0.08)
                              : cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: !_isFree
                                ? const Color(0xFF2563EB)
                                : borderColor,
                            width: !_isFree ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Iconsax.coin,
                              color: !_isFree
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF94A3B8),
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'service_fee_custom_price'.tr(),
                              style: _rabar(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: !_isFree
                                    ? const Color(0xFF2563EB)
                                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'service_fee_custom_price_sub'.tr(),
                              style: _rabar(
                                fontSize: 11.5,
                                color: !_isFree
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Option B: Free (خۆڕایی)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isFree = true),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          color: _isFree
                              ? const Color(0xFF10B981).withValues(alpha: 0.08)
                              : cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isFree
                                ? const Color(0xFF10B981)
                                : borderColor,
                            width: _isFree ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Iconsax.gift,
                              color: _isFree
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF94A3B8),
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'service_fee_free'.tr(),
                              style: _rabar(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _isFree
                                    ? const Color(0xFF10B981)
                                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'service_fee_free_sub'.tr(),
                              style: _rabar(
                                fontSize: 11.5,
                                color: _isFree
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Section 3: Preset Price Chips (if not free) ──
              if (!_isFree) ...[
                Text(
                  'service_fee_presets'.tr(),
                  style: _rabar(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _presets.map((preset) {
                    final currentVal = double.tryParse(_amountController.text.trim()) ?? 0.0;
                    final isSelected = currentVal == preset;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _amountController.text = preset.toInt().toString();
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : borderColor,
                          ),
                        ),
                        child: Text(
                          '${NumberFormat('#,###').format(preset.toInt())} $currency',
                          style: _rabar(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white : const Color(0xFF0F172A)),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // ── Section 4: Custom Price Input ──
                Text(
                  'service_fee_amount_label'.tr(),
                  style: _rabar(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: _rabar(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    onChanged: (val) => setState(() {}),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: InputBorder.none,
                      prefixIcon: const Icon(Iconsax.wallet_3, color: Color(0xFF2563EB), size: 20),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          currency,
                          style: _rabar(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                      hintText: '1000',
                      hintStyle: _rabar(color: const Color(0xFF94A3B8)),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Section 4.5: Discount Section (داشکاندنی کرێی خزمەتگوزاری) ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _hasDiscount ? const Color(0xFFF59E0B) : borderColor,
                      width: _hasDiscount ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _hasDiscount
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Iconsax.discount_shape,
                              color: Color(0xFFF59E0B),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'service_fee_discount_title'.tr(),
                                  style: _rabar(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'service_fee_discount_desc'.tr(),
                                  style: _rabar(
                                    fontSize: 12,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _hasDiscount,
                            activeColor: const Color(0xFFF59E0B),
                            onChanged: (val) {
                              setState(() => _hasDiscount = val);
                            },
                          ),
                        ],
                      ),

                      if (_hasDiscount) ...[
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 14),

                        // Switch between Percentage and Fixed Amount
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _discountType = 'percent'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _discountType == 'percent'
                                          ? (_hasDiscount ? const Color(0xFFF59E0B) : cardBg)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(9),
                                      boxShadow: _discountType == 'percent'
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.05),
                                                blurRadius: 4,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'discount_percent_tab'.tr(),
                                        style: _rabar(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: _discountType == 'percent'
                                              ? Colors.white
                                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _discountType = 'fixed'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _discountType == 'fixed'
                                          ? const Color(0xFFF59E0B)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(9),
                                      boxShadow: _discountType == 'fixed'
                                          ? [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.05),
                                                blurRadius: 4,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'discount_fixed_tab'.tr(),
                                        style: _rabar(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: _discountType == 'fixed'
                                              ? Colors.white
                                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // If percentage discount
                        if (_discountType == 'percent') ...[
                          Text(
                            'discount_percent_label'.tr(),
                            style: _rabar(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _discountPercentPresets.map((pct) {
                              final curPct = double.tryParse(_discountPercentController.text.trim()) ?? 0.0;
                              final isSelected = curPct == pct;
                              return GestureDetector(
                                onTap: () => setState(() {
                                  _discountPercentController.text = pct.toInt().toString();
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFF59E0B) : cardBg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFFF59E0B) : borderColor,
                                    ),
                                  ),
                                  child: Text(
                                    '%${pct.toInt()} ${pct == 100 ? "(${'service_fee_free'.tr()})" : ''}',
                                    style: _rabar(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderColor),
                            ),
                            child: TextField(
                              controller: _discountPercentController,
                              keyboardType: TextInputType.number,
                              style: _rabar(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              onChanged: (val) => setState(() {}),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: InputBorder.none,
                                suffixIcon: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Text(
                                    '%',
                                    style: _rabar(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFF59E0B),
                                    ),
                                  ),
                                ),
                                hintText: '50',
                                hintStyle: _rabar(color: const Color(0xFF94A3B8)),
                              ),
                            ),
                          ),
                        ] else ...[
                          // If fixed amount discount
                          Text(
                            'discount_fixed_label'.tr(),
                            style: _rabar(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _discountAmountPresets.map((amt) {
                              final curAmt = double.tryParse(_discountAmountController.text.trim()) ?? 0.0;
                              final isSelected = curAmt == amt;
                              return GestureDetector(
                                onTap: () => setState(() {
                                  _discountAmountController.text = amt.toInt().toString();
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFF59E0B) : cardBg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFFF59E0B) : borderColor,
                                    ),
                                  ),
                                  child: Text(
                                    '${NumberFormat('#,###').format(amt.toInt())} $currency',
                                    style: _rabar(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderColor),
                            ),
                            child: TextField(
                              controller: _discountAmountController,
                              keyboardType: TextInputType.number,
                              style: _rabar(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              onChanged: (val) => setState(() {}),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: InputBorder.none,
                                suffixIcon: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Text(
                                    currency,
                                    style: _rabar(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFF59E0B),
                                    ),
                                  ),
                                ),
                                hintText: '500',
                                hintStyle: _rabar(color: const Color(0xFF94A3B8)),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),

                        // Discount summary badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, size: 16, color: Color(0xFFD97706)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${'discount_summary_prefix'.tr()} -${NumberFormat('#,###').format(_discountValue.toInt())} $currency | ${'discount_summary_after'.tr()} ${NumberFormat('#,###').format(_effectiveAmount.toInt())} $currency',
                                  style: _rabar(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFB45309),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ── Section 5: Note / Description for Customer ──
              Text(
                'service_fee_explanation'.tr(),
                style: _rabar(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: TextField(
                  controller: _noteController,
                  style: _rabar(
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  onChanged: (val) => setState(() {}),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: InputBorder.none,
                    prefixIcon: const Icon(Iconsax.info_circle, color: Color(0xFF64748B), size: 20),
                    hintText: 'service_fee_default_note'.tr(),
                    hintStyle: _rabar(color: const Color(0xFF94A3B8)),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Section 6: Live Customer Preview ──
            Row(
              children: [
                const Icon(Iconsax.eye, size: 18, color: Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'live_preview_title'.tr(),
                    style: _rabar(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Row 1: Subtotal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'items_subtotal'.tr(),
                        style: _rabar(
                          fontSize: 13.5,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        '${NumberFormat('#,###').format(10000)} $currency',
                        style: _rabar(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Row 2: Service fee
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'service_fee'.tr(),
                            style: _rabar(
                              fontSize: 13.5,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                          if (_noteController.text.trim().isNotEmpty) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.info_outline, size: 14, color: Color(0xFF94A3B8)),
                          ],
                        ],
                      ),
                      if (!_isEnabled)
                        Text(
                          'service_fee_disabled_badge'.tr(),
                          style: _rabar(
                            fontSize: 13,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else if (_isFree || _effectiveAmount == 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _hasDiscount && _baseAmount > 0
                                ? 'service_fee_100_free_badge'.tr()
                                : 'service_fee_free'.tr(),
                            style: _rabar(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        )
                      else if (_hasDiscount && _discountValue > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              NumberFormat('#,###').format(_baseAmount.toInt()),
                              style: _rabar(
                                fontSize: 12,
                                color: const Color(0xFF94A3B8),
                              ).copyWith(decoration: TextDecoration.lineThrough),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${NumberFormat('#,###').format(_effectiveAmount.toInt())} $currency',
                              style: _rabar(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _discountType == 'percent'
                                    ? '%${(double.tryParse(_discountPercentController.text.trim()) ?? 0).toInt()}-'
                                    : '-${NumberFormat('#,###').format(_discountValue.toInt())}',
                                style: _rabar(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFD97706),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          '${NumberFormat('#,###').format(_baseAmount.toInt())} $currency',
                          style: _rabar(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1),
                  ),
                  // Row 3: Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'total_price'.tr(),
                        style: _rabar(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${NumberFormat('#,###').format((10000 + _effectiveAmount).toInt())} $currency',
                        style: _rabar(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Section 7: Save Button ──
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.save_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'save_changes'.tr(),
                            style: _rabar(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
