import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/api_client.dart';
import 'admin_app_bar.dart';
import 'admin_ui.dart';

class AdminCommissionScreen extends StatefulWidget {
  const AdminCommissionScreen({super.key});

  @override
  State<AdminCommissionScreen> createState() => _AdminCommissionScreenState();
}

class _AdminCommissionScreenState extends State<AdminCommissionScreen> {
  static const _green = Color(0xFF10B981);
  static const _kurdishMonths = [
    'کانوونی دووەم', 'شوبات', 'ئازار', 'نیسان', 'ئایار', 'حوزەیران',
    'تەممووز', 'ئاب', 'ئەیلوول', 'تشرینی یەکەم', 'تشرینی دووەم', 'کانوونی یەکەم',
  ];

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  late DateTime _period = DateTime(DateTime.now().year, DateTime.now().month);

  int _totalOrders = 0;
  double _totalRevenue = 0;
  double _totalCommission = 0;
  double _totalProviderPayout = 0;
  bool _isCustomMonth = false;
  List<dynamic> _breakdown = [];

  final _nursingRateCtrl = TextEditingController();
  final _labRateCtrl = TextEditingController();

  bool get _isDark => ThemeProvider().isDarkMode;
  String get _periodQuery => 'year=${_period.year}&month=${_period.month}';
  String get _periodLabel => '${_kurdishMonths[_period.month - 1]} ${_period.year}';
  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _period.year == now.year && _period.month == now.month;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nursingRateCtrl.dispose();
    _labRateCtrl.dispose();
    super.dispose();
  }

  double _num(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0.0;

  String _fmtRate(dynamic v) {
    final d = _num(v);
    return d == d.roundToDouble() ? d.toInt().toString() : d.toString();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        ApiClient.get('/admin/commission/summary?$_periodQuery'),
        ApiClient.get('/admin/commission/settings?$_periodQuery'),
      ]);
      if (!mounted) return;

      if (results[0].statusCode == 200 && results[1].statusCode == 200) {
        final s = jsonDecode(results[0].body)['data'];
        final r = jsonDecode(results[1].body)['data'];
        setState(() {
          _totalOrders = (s['total_orders'] as num?)?.toInt() ?? 0;
          _totalRevenue = _num(s['total_revenue']);
          _totalCommission = _num(s['total_commission']);
          _totalProviderPayout = _num(s['total_provider_payout']);
          _breakdown = s['breakdown'] ?? [];
          _nursingRateCtrl.text = _fmtRate(r['nursing_rate'] ?? 10);
          _labRateCtrl.text = _fmtRate(r['lab_rate'] ?? 15);
          _isCustomMonth = r['is_custom'] == true;
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
    final nursing = double.tryParse(_nursingRateCtrl.text.trim());
    final lab = double.tryParse(_labRateCtrl.text.trim());
    if (nursing == null || lab == null || nursing < 0 || nursing > 100 || lab < 0 || lab > 100) {
      AdminUi.toast(context, 'ڕێژەکان دەبێت ژمارە بن لە نێوان ٠ بۆ ١٠٠', isError: true);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);
    try {
      final res = await ApiClient.post('/admin/commission/settings', body: {
        'year': _period.year,
        'month': _period.month,
        'nursing_rate': nursing,
        'lab_rate': lab,
      });
      if (!mounted) return;
      if (res.statusCode == 200) {
        final count = jsonDecode(res.body)['data']?['recalculated_orders'] ?? 0;
        AdminUi.toast(context, 'ڕێژەکانی $_periodLabel نوێکرانەوە ($count داواکاری دووبارە حیسابکرایەوە)');
        await _load();
      } else {
        AdminUi.toast(context, AdminUi.readError(res), isError: true);
      }
    } catch (e) {
      if (mounted) AdminUi.toast(context, '$e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _shiftMonth(int delta) {
    final next = DateTime(_period.year, _period.month + delta);
    final now = DateTime.now();
    if (next.isAfter(DateTime(now.year, now.month))) return;
    setState(() => _period = next);
    _load();
  }

  String _formatIqd(double val) => '${NumberFormat('#,##0').format(val.round())} د.ع';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AdminAppBar(
        title: 'سیستەمی کۆمیشن',
        subtitle: 'حیسابکردنی قازانجی سیستم و پشکی ستاف',
        icon: Iconsax.percentage_square,
        iconColor: _green,
        iconBackgroundColor: _green.withValues(alpha: 0.1),
        showBackButton: true,
      ),
      body: Column(
        children: [
          _buildMonthSelector(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          children: [
                            _buildOverview(),
                            const SizedBox(height: 16),
                            _buildRatesCard(),
                            const SizedBox(height: 20),
                            _buildBreakdown(),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        decoration: AdminUi.cardDecoration,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          children: [
            IconButton(
              onPressed: _isLoading ? null : () => _shiftMonth(-1),
              icon: const Icon(Icons.chevron_right_rounded),
              tooltip: 'مانگی پێشوو',
            ),
            Expanded(
              child: Column(
                children: [
                  Text(_periodLabel, style: AdminUi.title),
                  Text(_isCurrentMonth ? 'مانگی ئێستا' : 'مانگی ڕابردوو', style: AdminUi.subtitle.copyWith(fontSize: 11)),
                ],
              ),
            ),
            IconButton(
              onPressed: _isLoading || _isCurrentMonth ? null : () => _shiftMonth(1),
              icon: const Icon(Icons.chevron_left_rounded),
              tooltip: 'مانگی دواتر',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.warning_2, color: Color(0xFFEF4444), size: 36),
            const SizedBox(height: 10),
            Text(_error!, style: AdminUi.subtitle, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('دووبارە هەوڵبدەرەوە', style: TextStyle(fontFamily: 'Rabar'))),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview() {
    final share = _totalRevenue > 0 ? (_totalCommission / _totalRevenue) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMetricCard(
          title: 'کۆی گشتی داهاتی داواکارییەکان',
          amount: _formatIqd(_totalRevenue),
          caption: '$_totalOrders داواکاری تەواوکراو',
          color: const Color(0xFF6366F1),
          icon: Iconsax.moneys,
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'قازانجی ئەپ (کۆمیشن)',
                  amount: _formatIqd(_totalCommission),
                  caption: '${(share * 100).toStringAsFixed(1)}% ی داهات',
                  color: _green,
                  icon: Iconsax.wallet_check,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'پشکی پێشکەشکاران',
                  amount: _formatIqd(_totalProviderPayout),
                  caption: '${((1 - share) * 100).toStringAsFixed(1)}% ی داهات',
                  color: const Color(0xFF3B82F6),
                  icon: Iconsax.card_receive,
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 250.ms);
  }

  Widget _buildRatesCard() {
    return Container(
      decoration: AdminUi.cardDecoration,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Iconsax.setting_4, color: _green, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ڕێژەی کۆمیشنی مانگانە', style: AdminUi.title),
                    const SizedBox(height: 2),
                    Text(
                      _isCustomMonth ? 'ڕێژەی تایبەت بۆ $_periodLabel' : 'ڕێژەی بنەڕەتی (هێشتا بۆ ئەم مانگە نەگۆڕدراوە)',
                      style: AdminUi.subtitle.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildRateRow('پەرستاری ماڵەوە', Iconsax.health, _nursingRateCtrl),
          const SizedBox(height: 12),
          _buildRateRow('تاقیگەکان', Iconsax.microscope, _labRateCtrl),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Iconsax.info_circle, size: 16, color: Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'پاشەکەوتکردن هەموو داواکارییەکانی ئەم مانگە بە ڕێژەی نوێ دووبارە حیساب دەکاتەوە.',
                    style: AdminUi.subtitle.copyWith(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _green.withValues(alpha: 0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Iconsax.tick_circle, size: 20),
              label: const Text(
                'پاشەکەوتکردنی ڕێژەکان',
                style: TextStyle(fontFamily: 'Rabar', fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('پوختەی کۆمیشن بەپێی بەشەکان', style: AdminUi.title),
        const SizedBox(height: 10),
        ..._breakdown.map((b) {
          final isLab = b['service_type'] == 'lab';
          final color = isLab ? const Color(0xFF8B5CF6) : const Color(0xFFEC4899);
          final total = _num(b['total_amount']);
          final comm = _num(b['total_commission']);
          final net = _num(b['provider_net']);
          final orders = (b['total_orders'] as num?)?.toInt() ?? 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: AdminUi.cardDecoration,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                      child: Icon(isLab ? Iconsax.microscope : Iconsax.health, color: color, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b['label']?.toString() ?? '', style: AdminUi.title),
                          Text('$orders داواکاری', style: AdminUi.subtitle.copyWith(fontSize: 11)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: _green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                      child: Text('${_fmtRate(b['rate'])}%',
                          style: const TextStyle(fontFamily: 'Rabar', fontSize: 12, fontWeight: FontWeight.bold, color: _green)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _breakdownCell('کۆی داهات', total, AdminUi.title.color!),
                    _breakdownCell('کۆمیشن', comm, _green),
                    _breakdownCell('پشکی پێشکەشکار', net, const Color(0xFF3B82F6)),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _breakdownCell(String label, double value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: AdminUi.subtitle.copyWith(fontSize: 10.5), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(_formatIqd(value),
                style: TextStyle(fontFamily: 'Rabar', fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String amount,
    required String caption,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      decoration: AdminUi.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(title, style: AdminUi.subtitle, maxLines: 2),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(amount, style: AdminUi.title.copyWith(fontSize: 17, color: color)),
          ),
          const SizedBox(height: 2),
          Text(caption, style: AdminUi.subtitle.copyWith(fontSize: 10.5)),
        ],
      ),
    );
  }

  Widget _buildRateRow(String title, IconData icon, TextEditingController ctrl) {
    final fill = _isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    return Row(
      children: [
        Icon(icon, size: 18, color: AdminUi.subtitle.color),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: AdminUi.title.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600))),
        SizedBox(
          width: 96,
          child: TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,2})?'))],
            textAlign: TextAlign.center,
            style: AdminUi.title.copyWith(fontSize: 15),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: fill,
              suffixText: '%',
              suffixStyle: AdminUi.subtitle,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _green, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
