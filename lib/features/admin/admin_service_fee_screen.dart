import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
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
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  bool _isSaving = false;

  final List<double> _presets = [1000, 1500, 2000, 2500, 3000, 5000];

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
    _isEnabled = model.isEnabled;
    _isFree = model.isFree;
    _amountController = TextEditingController(
      text: model.amount > 0 ? model.amount.toInt().toString() : '1000',
    );
    _noteController = TextEditingController(
      text: model.note ?? 'کرێی خزمەتگوزاری سیستەم و چاودێری کوالێتی',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _currentAmount {
    if (_isFree || !_isEnabled) return 0.0;
    return double.tryParse(_amountController.text.trim()) ?? 0.0;
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    final amountVal = double.tryParse(_amountController.text.trim()) ?? 1000.0;
    final newModel = ServiceFeeModel(
      isEnabled: _isEnabled,
      isFree: _isFree,
      amount: amountVal,
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
                'گۆڕانکارییەکانی کرێی خزمەتگوزاری پاشەکەوت کران',
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
                'هەڵە لە پاشەکەوتکردن، تکایە دووبارە هەوڵبدەرەوە',
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

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AdminAppBar(
        title: 'ڕێکخستنی کرێی خزمەتگوزاری',
        subtitle: 'دیاریکردنی کرێی داواکارییەکان بۆ بەکارهێنەران',
        icon: Iconsax.receipt_item,
        iconColor: const Color(0xFF2563EB),
        iconBackgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                          'چالاککردنی کرێی خزمەتگوزاری',
                          style: _rabar(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _isEnabled
                              ? 'کرێی خزمەتگوزاری لەسەر هەموو داواکارییەکان کارایە'
                              : 'ناچالاکە، هیچ کرێیەک لە کڕیار وەرناگیرێت',
                          style: _rabar(
                            fontSize: 12.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isEnabled,
                    activeColor: const Color(0xFF10B981),
                    onChanged: (val) {
                      setState(() => _isEnabled = val);
                    },
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05),

            if (_isEnabled) ...[
              const SizedBox(height: 20),

              // ── Section 2: Mode Selection (Free vs Custom) ──
              Text(
                'جۆری کرێیەکە',
                style: _rabar(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  // Option: Free (خۆڕایی)
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        setState(() => _isFree = true);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          color: _isFree
                              ? const Color(0xFF10B981).withValues(alpha: 0.12)
                              : cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isFree ? const Color(0xFF10B981) : borderColor,
                            width: _isFree ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Iconsax.gift,
                              color: _isFree ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                              size: 26,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'خۆڕایی (Free)',
                              style: _rabar(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: _isFree ? const Color(0xFF10B981) : (isDark ? Colors.white : const Color(0xFF0F172A)),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '٠ د.ع (بێ بەرامبەر)',
                              style: _rabar(
                                fontSize: 11.5,
                                color: _isFree ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Option: Custom Price (دیاریکردنی نرخ)
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        setState(() => _isFree = false);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          color: !_isFree
                              ? const Color(0xFF2563EB).withValues(alpha: 0.12)
                              : cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: !_isFree ? const Color(0xFF2563EB) : borderColor,
                            width: !_isFree ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Iconsax.coin,
                              color: !_isFree ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                              size: 26,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'دیاریکردنی نرخ',
                              style: _rabar(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: !_isFree ? const Color(0xFF2563EB) : (isDark ? Colors.white : const Color(0xFF0F172A)),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'نرخی دیاریکراو بە دینار',
                              style: _rabar(
                                fontSize: 11.5,
                                color: !_isFree ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              if (!_isFree) ...[
                const SizedBox(height: 20),

                // ── Section 3: Preset Amount Chips ──
                Text(
                  'نرخە ئامادەکراوەکان',
                  style: _rabar(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presets.map((preset) {
                    final isSelected = _amountController.text.trim() == preset.toInt().toString();
                    return ActionChip(
                      backgroundColor: isSelected
                          ? const Color(0xFF2563EB)
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                      label: Text(
                        '${NumberFormat('#,###').format(preset.toInt())} د.ع',
                        style: _rabar(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF334155)),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _amountController.text = preset.toInt().toString();
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // ── Section 4: Custom Amount Input ──
                Text(
                  'بڕی کرێی خزمەتگوزاری (بە دیناری عێراقی)',
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
                      prefixIcon: const Icon(Iconsax.empty_wallet, color: Color(0xFF2563EB), size: 20),
                      suffixText: 'د.ع',
                      suffixStyle: _rabar(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2563EB),
                      ),
                      hintText: 'بۆ نموونە: 1000',
                      hintStyle: _rabar(color: const Color(0xFF94A3B8)),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ── Section 5: Note / Description for Customer ──
              Text(
                'ڕوونکردنەوە بۆ کڕیار (تێبینی ژێر خزمەتگوزاری)',
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
                    hintText: 'وەک: کرێی خزمەتگوزاری سیستەم و چاودێری کوالێتی',
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
                Text(
                  'پێشبینینی ڕاستەوخۆ (لای کڕیار لە سەبەتەدا چۆن دەردەکەوێت):',
                  style: _rabar(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                        'کۆی نرخی کاڵاکان',
                        style: _rabar(
                          fontSize: 13.5,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        '10,000 د.ع',
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
                            'کرێی خزمەتگوزاری',
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
                          'ناچالاک کراوە',
                          style: _rabar(
                            fontSize: 13,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else if (_isFree || _currentAmount == 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'خۆڕایی (Free)',
                            style: _rabar(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        )
                      else
                        Text(
                          '${NumberFormat('#,###').format(_currentAmount.toInt())} د.ع',
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
                        'کۆی گشتی',
                        style: _rabar(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${NumberFormat('#,###').format((10000 + _currentAmount).toInt())} د.ع',
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
                            'پاشەکەوتکردنی گۆڕانکارییەکان',
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
