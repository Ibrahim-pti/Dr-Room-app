import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/api_client.dart';
import 'admin_app_bar.dart';
import 'admin_ui.dart';

class AdminCommissionScreen extends StatefulWidget {
  const AdminCommissionScreen({super.key});

  @override
  State<AdminCommissionScreen> createState() => _AdminCommissionScreenState();
}

class _AdminCommissionScreenState extends State<AdminCommissionScreen> {
  bool _isLoading = true;
  String? _error;

  double _totalRevenue = 0;
  double _totalCommission = 0;
  double _totalProviderPayout = 0;
  List<dynamic> _breakdown = [];

  final _nursingRateCtrl = TextEditingController(text: '10');
  final _labRateCtrl = TextEditingController(text: '15');
  final _pharmacyRateCtrl = TextEditingController(text: '5');
  final _doctorRateCtrl = TextEditingController(text: '10');

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
        ApiClient.get('/admin/commission/summary'),
        ApiClient.get('/admin/commission/settings'),
      ]);

      if (!mounted) return;

      if (results[0].statusCode == 200 && results[1].statusCode == 200) {
        final summaryData = jsonDecode(results[0].body)['data'];
        final settingsData = jsonDecode(results[1].body)['data'];

        setState(() {
          _totalRevenue = double.tryParse(summaryData['total_revenue']?.toString() ?? '0') ?? 0.0;
          _totalCommission = double.tryParse(summaryData['total_commission']?.toString() ?? '0') ?? 0.0;
          _totalProviderPayout = double.tryParse(summaryData['total_provider_payout']?.toString() ?? '0') ?? 0.0;
          _breakdown = summaryData['breakdown'] ?? [];

          _nursingRateCtrl.text = (settingsData['nursing_rate'] ?? 10).toString();
          _labRateCtrl.text = (settingsData['lab_rate'] ?? 15).toString();
          _pharmacyRateCtrl.text = (settingsData['pharmacy_rate'] ?? 5).toString();
          _doctorRateCtrl.text = (settingsData['doctor_rate'] ?? 10).toString();

          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'کێشە لە بارکردنی داتای کۆمیشن ڕوویدا';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _isLoading = false; });
    }
  }

  Future<void> _saveSettings() async {
    try {
      final res = await ApiClient.post('/admin/commission/settings', body: {
        'nursing_rate': double.tryParse(_nursingRateCtrl.text) ?? 10,
        'lab_rate': double.tryParse(_labRateCtrl.text) ?? 15,
        'pharmacy_rate': double.tryParse(_pharmacyRateCtrl.text) ?? 5,
        'doctor_rate': double.tryParse(_doctorRateCtrl.text) ?? 10,
      });

      if (res.statusCode == 200) {
        if (mounted) AdminUi.toast(context, 'ڕێژەی کۆمیشنەکان بە سەرکەوتوویی نوێکرانەوە');
        _load();
      } else {
        if (mounted) AdminUi.toast(context, AdminUi.readError(res), isError: true);
      }
    } catch (e) {
      if (mounted) AdminUi.toast(context, '$e', isError: true);
    }
  }

  String _formatIqd(double val) {
    return '${NumberFormat('#,###').format(val)} د.ع';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AdminAppBar(
        title: 'سیستەمی کۆمیشن',
        subtitle: 'حیسابکردنی قازانجی سیستم و پشکی ستاف',
        icon: Iconsax.percentage_square,
        iconColor: const Color(0xFF10B981),
        iconBackgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
        showBackButton: true,
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
                      // Overview cards
                      _buildMetricCard(
                        title: 'کۆی گشتی داهاتی داواکارییەکان',
                        amount: _formatIqd(_totalRevenue),
                        color: const Color(0xFF6366F1),
                        icon: Iconsax.moneys,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              title: 'قازانجی ئەپ (کۆمیشن)',
                              amount: _formatIqd(_totalCommission),
                              color: const Color(0xFF10B981),
                              icon: Iconsax.wallet_check,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              title: 'پشکی پێشکەشکاران',
                              amount: _formatIqd(_totalProviderPayout),
                              color: const Color(0xFF3B82F6),
                              icon: Iconsax.card_receive,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Settings Card
                      Container(
                        decoration: AdminUi.cardDecoration,
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Iconsax.setting_4, color: Color(0xFF10B981), size: 20),
                                const SizedBox(width: 8),
                                Text('دیاریکردنی ڕێژەی کۆمیشن بۆ هەر خزمەتگوزارییەک', style: AdminUi.title),
                              ],
                            ),
                            const SizedBox(height: 16),

                            _buildRateRow('پەرستاری ماڵەوە', _nursingRateCtrl),
                            const Divider(height: 20),
                            _buildRateRow('تاقیگەکان', _labRateCtrl),
                            const Divider(height: 20),
                            _buildRateRow('دەرمانخانەکان', _pharmacyRateCtrl),
                            const Divider(height: 20),
                            _buildRateRow('کلینیک و پزیشکان', _doctorRateCtrl),
                            const SizedBox(height: 16),

                            ElevatedButton(
                              onPressed: _saveSettings,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('پاشەکەوتکردنی ڕێژەی نوێ', style: TextStyle(fontFamily: 'Rabar', fontSize: 14)),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 300.ms),

                      const SizedBox(height: 16),

                      // Service Breakdown
                      if (_breakdown.isNotEmpty) ...[
                        Text('پوختەی کۆمیشن بەپێی بەشەکان', style: AdminUi.title),
                        const SizedBox(height: 10),
                        ..._breakdown.map((b) {
                          final service = b['service_type'] ?? 'گشتی';
                          final total = double.tryParse(b['total_amount']?.toString() ?? '0') ?? 0.0;
                          final comm = double.tryParse(b['total_commission']?.toString() ?? '0') ?? 0.0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: AdminUi.cardDecoration,
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                const Icon(Iconsax.activity, color: Color(0xFF10B981), size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(service.toString().toUpperCase(), style: AdminUi.title),
                                      const SizedBox(height: 4),
                                      Text('کۆی داواکاری: ${_formatIqd(total)}', style: AdminUi.subtitle),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('کۆمیشنی پەیداکراو', style: TextStyle(fontFamily: 'Rabar', fontSize: 11, color: Colors.grey)),
                                    Text(_formatIqd(comm), style: const TextStyle(fontFamily: 'Rabar', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildMetricCard({required String title, required String amount, required Color color, required IconData icon}) {
    return Container(
      decoration: AdminUi.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: AdminUi.subtitle),
          const SizedBox(height: 4),
          Text(amount, style: AdminUi.title.copyWith(fontSize: 16, color: color)),
        ],
      ),
    );
  }

  Widget _buildRateRow(String title, TextEditingController ctrl) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AdminUi.subtitle.copyWith(fontSize: 13, color: Colors.black87))),
        SizedBox(
          width: 75,
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              suffixText: '%',
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}
