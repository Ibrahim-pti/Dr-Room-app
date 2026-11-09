import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/api_client.dart';
import 'admin_app_bar.dart';
import 'admin_ui.dart';

class AdminCouponsScreen extends StatefulWidget {
  const AdminCouponsScreen({super.key});

  @override
  State<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends State<AdminCouponsScreen> {
  List<dynamic> _coupons = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await ApiClient.get('/admin/coupons');
      if (!mounted) return;

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() {
          _coupons = body['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = AdminUi.readError(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _isLoading = false; });
    }
  }

  Future<void> _toggleStatus(dynamic coupon) async {
    final id = coupon['id'];
    try {
      final res = await ApiClient.patch('/admin/coupons/$id/toggle');
      if (res.statusCode == 200) {
        _load();
      } else {
        if (mounted) AdminUi.toast(context, AdminUi.readError(res), isError: true);
      }
    } catch (e) {
      if (mounted) AdminUi.toast(context, '$e', isError: true);
    }
  }

  Future<void> _deleteCoupon(dynamic coupon) async {
    final ok = await AdminUi.confirm(
      context,
      title: 'سڕینەوەی کۆدی داشکاندن',
      message: 'ئایا دڵنیایت لە سڕینەوەی کۆدی ${coupon['code']}؟',
    );
    if (!ok) return;

    try {
      final res = await ApiClient.delete('/admin/coupons/${coupon['id']}');
      if (res.statusCode == 200) {
        if (mounted) AdminUi.toast(context, 'کۆدەکە بە سەرکەوتوویی سڕایەوە');
        _load();
      } else {
        if (mounted) AdminUi.toast(context, AdminUi.readError(res), isError: true);
      }
    } catch (e) {
      if (mounted) AdminUi.toast(context, '$e', isError: true);
    }
  }

  Future<void> _openAddEditDialog({dynamic coupon}) async {
    final isEdit = coupon != null;
    final codeCtrl = TextEditingController(text: coupon?['code'] ?? '');
    final titleCtrl = TextEditingController(text: coupon?['title'] ?? '');
    final valCtrl = TextEditingController(text: coupon?['discount_value']?.toString() ?? '');
    final minCtrl = TextEditingController(text: coupon?['min_order_amount']?.toString() ?? '0');
    final limitCtrl = TextEditingController(text: coupon?['usage_limit']?.toString() ?? '');
    String discountType = coupon?['discount_type'] ?? 'percentage';

    await AdminUi.formSheet(
      context: context,
      title: isEdit ? 'دەستکاری کۆدی داشکاندن' : 'دروستکردنی کۆدی داشکاندن',
      subtitle: 'کۆدێک دیاریبکە بۆ هاندانی نەخۆشەکان',
      submitLabel: isEdit ? 'نوێکردنەوە' : 'دروستکردن',
      builder: (setSheetState, setError) => [
        TextField(
          controller: codeCtrl,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'کۆدی داشکاندن (نموونە: EID2026)',
            prefixIcon: Icon(Iconsax.ticket_discount),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(
            labelText: 'ناونیشان (نموونە: داشکاندنی جەژن)',
            prefixIcon: Icon(Iconsax.note),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: discountType,
                decoration: const InputDecoration(labelText: 'جۆری داشکاندن'),
                items: const [
                  DropdownMenuItem(value: 'percentage', child: Text('ڕێژەی سەدی (%)')),
                  DropdownMenuItem(value: 'fixed', child: Text('بڕی جێگیر (د.ع)')),
                ],
                onChanged: (v) => setSheetState(() => discountType = v ?? 'percentage'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: valCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: discountType == 'percentage' ? 'ڕێژە (%)' : 'بڕ (د.ع)',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: minCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'کەمترین بڕی داواکاری'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: limitCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'سنووری بەکارهێنان'),
              ),
            ),
          ],
        ),
      ],
      onSubmit: (setError) async {
        final code = codeCtrl.text.trim().toUpperCase();
        final val = double.tryParse(valCtrl.text.trim()) ?? 0;
        if (code.isEmpty || val <= 0) {
          setError('تکایە کۆد و بەهایەکی دروست بنووسە');
          return false;
        }

        final payload = {
          'code': code,
          'title': titleCtrl.text.trim(),
          'discount_type': discountType,
          'discount_value': val,
          'min_order_amount': double.tryParse(minCtrl.text.trim()) ?? 0,
          'usage_limit': int.tryParse(limitCtrl.text.trim()),
          'is_active': coupon?['is_active'] ?? true,
        };

        final res = isEdit
            ? await ApiClient.put('/admin/coupons/${coupon['id']}', body: payload)
            : await ApiClient.post('/admin/coupons', body: payload);

        if (res.statusCode == 200 || res.statusCode == 201) {
          _load();
          return true;
        } else {
          setError(AdminUi.readError(res));
          return false;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AdminAppBar(
        title: 'کۆدەکانی داشکاندن',
        subtitle: '${_coupons.length} کۆد تۆمارکراوە',
        icon: Iconsax.ticket_discount,
        iconColor: const Color(0xFF6366F1),
        iconBackgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
        showBackButton: true,
        actions: [
          IconButton(
            onPressed: () => _openAddEditDialog(),
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF6366F1), size: 26),
            tooltip: 'دروستکردنی کۆدی نوێ',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: AdminUi.subtitle))
              : _coupons.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Iconsax.ticket_discount, size: 54, color: Color(0xFF94A3B8)),
                          const SizedBox(height: 12),
                          Text('هیچ کۆدێکی داشکاندن نەدۆزرایەوە', style: AdminUi.title),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _openAddEditDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('دروستکردنی یەکەم کۆد', style: TextStyle(fontFamily: 'Rabar')),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _coupons.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final c = _coupons[index];
                          final isActive = c['is_active'] == true || c['is_active'] == 1;
                          final isPercent = c['discount_type'] == 'percentage';
                          final valStr = isPercent
                              ? '${c['discount_value']}%'
                              : '${NumberFormat('#,###').format(double.tryParse(c['discount_value'].toString()) ?? 0)} د.ع';

                          return Container(
                            decoration: AdminUi.cardDecoration,
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: (isActive ? const Color(0xFF6366F1) : Colors.grey)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Iconsax.ticket_discount,
                                      color: isActive ? const Color(0xFF6366F1) : Colors.grey,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            c['code'] ?? '',
                                            style: AdminUi.title.copyWith(fontSize: 16, letterSpacing: 1),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              valStr,
                                              style: const TextStyle(
                                                fontFamily: 'Rabar',
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF6366F1),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        c['title'] ?? 'کۆدی داشکاندنی گشتی',
                                        style: AdminUi.subtitle,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'بەکارهێنراوە: ${c['used_count'] ?? 0}${c['usage_limit'] != null ? ' / ${c['usage_limit']}' : ''}',
                                        style: AdminUi.subtitle.copyWith(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: isActive,
                                  activeThumbColor: const Color(0xFF6366F1),
                                  onChanged: (_) => _toggleStatus(c),
                                ),
                                IconButton(
                                  icon: const Icon(Iconsax.trash, color: Colors.red, size: 20),
                                  onPressed: () => _deleteCoupon(c),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 250.ms);
                        },
                      ),
                    ),
    );
  }
}
