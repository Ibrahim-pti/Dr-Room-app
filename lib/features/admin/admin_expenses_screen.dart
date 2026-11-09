import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/api_client.dart';
import 'admin_app_bar.dart';
import 'admin_ui.dart';

class AdminExpensesScreen extends StatefulWidget {
  const AdminExpensesScreen({super.key});

  @override
  State<AdminExpensesScreen> createState() => _AdminExpensesScreenState();
}

class _AdminExpensesScreenState extends State<AdminExpensesScreen> {
  List<dynamic> _expenses = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = true;
  String? _error;

  final _categories = const [
    ('salaries', 'مووچەی کارمەندان', Iconsax.profile_2user),
    ('transport', 'کرێی هاتوچۆ و بەنزین', Iconsax.car),
    ('lab_supplies', 'کەلوپەل و کەرەستەی تاقیگە', Iconsax.microscope),
    ('marketing', 'مارکێتینگ و ڕیکلام', Iconsax.magic_star),
    ('maintenance', 'چاودێری و چاککردنەوە', Iconsax.setting_2),
    ('rent', 'کرێی شوێن / ئۆفیس', Iconsax.building),
    ('other', 'خەرجی تر', Iconsax.more),
  ];

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
      final results = await Future.wait([
        ApiClient.get('/admin/expenses'),
        ApiClient.get('/admin/expenses/summary'),
      ]);

      if (!mounted) return;

      if (results[0].statusCode == 200 && results[1].statusCode == 200) {
        final listData = jsonDecode(results[0].body)['data'];
        final summaryData = jsonDecode(results[1].body)['data'];

        setState(() {
          _expenses = listData is Map ? (listData['data'] ?? []) : (listData ?? []);
          _summary = summaryData ?? {};
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'کێشە لە بارکردنی خەرجییەکان ڕوویدا';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _isLoading = false; });
    }
  }

  Future<void> _deleteExpense(dynamic item) async {
    final ok = await AdminUi.confirm(
      context,
      title: 'سڕینەوەی خەرجی',
      message: 'ئایا دڵنیایت لە سڕینەوەی ${item['title']} بە بڕی ${item['amount']} د.ع؟',
    );
    if (!ok) return;

    try {
      final res = await ApiClient.delete('/admin/expenses/${item['id']}');
      if (res.statusCode == 200) {
        if (mounted) AdminUi.toast(context, 'خەرجی سڕایەوە');
        _load();
      }
    } catch (_) {}
  }

  Future<void> _openAddDialog() async {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String category = 'salaries';
    DateTime selectedDate = DateTime.now();

    await AdminUi.formSheet(
      context: context,
      title: 'تۆمارکردنی خەرجی نوێ',
      subtitle: 'خەرجییەکان پۆلێن بکە بۆ چاودێری وردی بودجە',
      submitLabel: 'تۆمارکردن',
      builder: (setSheetState, setError) => [
        TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(labelText: 'ناونیشانی خەرجی'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: category,
          decoration: const InputDecoration(labelText: 'پۆلێنی خەرجی'),
          items: _categories.map((c) {
            return DropdownMenuItem(value: c.$1, child: Text(c.$2));
          }).toList(),
          onChanged: (v) => setSheetState(() => category = v ?? 'salaries'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: amountCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'بڕی خەرجی (دینار)', suffixText: 'د.ع'),
        ),
        const SizedBox(height: 12),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2025),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setSheetState(() => selectedDate = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.calendar, size: 20, color: Color(0xFFEF4444)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'بەروار: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                      style: const TextStyle(fontFamily: 'Rabar', fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: notesCtrl,
          decoration: const InputDecoration(labelText: 'تێبینی زیاتر (ئارەزوومەندانە)'),
        ),
      ],
      onSubmit: (setError) async {
        final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
        if (titleCtrl.text.trim().isEmpty || amount <= 0) {
          setError('تکایە ناونیشان و بڕێکی دروست بنووسە');
          return false;
        }

        final res = await ApiClient.post('/admin/expenses', body: {
          'title': titleCtrl.text.trim(),
          'category': category,
          'amount': amount,
          'expense_date': DateFormat('yyyy-MM-dd').format(selectedDate),
          'notes': notesCtrl.text.trim(),
        });

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

  String _formatIqd(dynamic val) {
    final d = double.tryParse(val?.toString() ?? '0') ?? 0;
    return '${NumberFormat('#,###').format(d)} د.ع';
  }

  @override
  Widget build(BuildContext context) {
    final totalExpenses = _summary['total_expenses'] ?? 0;
    final netProfit = _summary['net_profit'] ?? 0;
    final totalComm = _summary['total_commission_revenue'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AdminAppBar(
        title: 'بودجە و خەرجییەکان',
        subtitle: 'چاودێریکردنی بودجەی گشتی و قازانجی پوخت',
        icon: Iconsax.moneys,
        iconColor: const Color(0xFFF97316),
        iconBackgroundColor: const Color(0xFFF97316).withValues(alpha: 0.1),
        showBackButton: true,
        actions: [
          IconButton(
            onPressed: _openAddDialog,
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFFF97316), size: 26),
            tooltip: 'تۆمارکردنی خەرجی',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: AdminUi.subtitle))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Financial Balance Banner
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text('قازانجی پوخت (داهاتی کۆمیشن - کۆی خەرجی)', style: TextStyle(fontFamily: 'Rabar', fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
                            const SizedBox(height: 6),
                            Text(
                              _formatIqd(netProfit),
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: (netProfit >= 0) ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              ),
                            ),
                            const Divider(color: Colors.white24, height: 28),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    Text('داهاتی خزمەتگوزاری', style: TextStyle(fontFamily: 'Rabar', fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
                                    const SizedBox(height: 4),
                                    Text(_formatIqd(totalComm), style: const TextStyle(fontFamily: 'Rabar', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ],
                                ),
                                Container(width: 1, height: 30, color: Colors.white24),
                                Column(
                                  children: [
                                    Text('کۆی گشتی خەرجی', style: TextStyle(fontFamily: 'Rabar', fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
                                    const SizedBox(height: 4),
                                    Text(_formatIqd(totalExpenses), style: const TextStyle(fontFamily: 'Rabar', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFF97316))),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 250.ms),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('تۆماری خەرجییەکان', style: AdminUi.title),
                          Text('${_expenses.length} خەرجی', style: AdminUi.subtitle),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_expenses.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Text('هیچ خەرجییەک تۆمارنەکراوە', style: AdminUi.subtitle),
                          ),
                        )
                      else
                        ..._expenses.map((e) {
                          final category = e['category'] ?? 'other';
                          final match = _categories.firstWhere((c) => c.$1 == category, orElse: () => _categories.last);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: AdminUi.cardDecoration,
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFFF97316).withValues(alpha: 0.12),
                                  child: Icon(match.$3, color: const Color(0xFFF97316), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(e['title'] ?? '', style: AdminUi.title),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${match.$2} • ${e['expense_date'] ?? ''}',
                                        style: AdminUi.subtitle.copyWith(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatIqd(e['amount']),
                                  style: const TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Iconsax.trash, color: Colors.grey, size: 18),
                                  onPressed: () => _deleteExpense(e),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}
