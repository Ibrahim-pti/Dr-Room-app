import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart' as intl;

import '../../core/theme/app_colors.dart';
import 'admin_app_bar.dart';
import 'admin_ui.dart';
import 'services/analytics_pdf_service.dart';
import 'services/analytics_report_service.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  static const _violet = Color(0xFF7C3AED);
  static const _indigo = Color(0xFF2563EB);
  static const _emerald = Color(0xFF059669);
  static const _amber = Color(0xFFD97706);
  static const _rose = Color(0xFFE11D48);

  bool _isLoading = true;
  bool _isExportingPdf = false;
  String? _error;

  late String _selectedMonth;
  String _serviceType = 'all'; // all, lab, nursing, pharmacy
  String _ledgerStatusFilter = 'all'; // all, completed, active, cancelled
  int? _selectedChartIndex;
  int _providerTab = 0; // 0 = labs, 1 = nurses

  Map<String, dynamic> _report = {};

  @override
  void initState() {
    super.initState();
    final nowBaghdad = DateTime.now().toUtc().add(const Duration(hours: 3));
    _selectedMonth =
        '${nowBaghdad.year.toString().padLeft(4, '0')}-${nowBaghdad.month.toString().padLeft(2, '0')}';
    _load(forceRefresh: true);
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await AnalyticsReportService.loadReport(
        selectedMonth: _selectedMonth,
        serviceType: _serviceType,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      final chartSeries = (data['chart_series'] as List?) ?? [];
      setState(() {
        _report = data;
        _selectedMonth = (data['selected_month'] ?? _selectedMonth).toString();
        _selectedChartIndex =
            chartSeries.isNotEmpty ? chartSeries.length - 1 : null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _isLoading = false;
      });
    }
  }

  void _selectMonth(String month) {
    if (_selectedMonth == month) return;
    setState(() => _selectedMonth = month);
    _load();
  }

  void _selectServiceType(String type) {
    if (_serviceType == type) return;
    setState(() => _serviceType = type);
    _load();
  }

  Future<void> _exportPdf({required bool share}) async {
    if (_isExportingPdf || _report.isEmpty) return;
    setState(() => _isExportingPdf = true);
    try {
      if (share) {
        await AnalyticsPdfService.sharePdf(_report);
      } else {
        await AnalyticsPdfService.previewAndPrint(context, _report);
      }
    } catch (e) {
      if (mounted) {
        AdminUi.toast(context, 'هەڵە لە دروستکردنی PDF: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  String _formatIqd(dynamic val) {
    final d = double.tryParse(val?.toString() ?? '0') ?? 0;
    return '${intl.NumberFormat('#,###').format(d)} د.ع';
  }

  String _formatNum(dynamic val) {
    final n = num.tryParse(val?.toString() ?? '0') ?? 0;
    return intl.NumberFormat('#,###').format(n);
  }

  String _formatCompact(dynamic val) {
    final d = double.tryParse(val?.toString() ?? '0') ?? 0;
    if (d >= 1000000) return '${(d / 1000000).toStringAsFixed(1)}M';
    if (d >= 1000) return '${(d / 1000).toStringAsFixed(0)}K';
    return d.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AdminAppBar(
        title: 'ئامار و ڕاپۆرتەکان',
        subtitle: 'ڕاپۆرتی مانگانە و شیکاری تەواوی سیستەم',
        icon: Iconsax.chart_2,
        iconColor: _violet,
        iconBackgroundColor: _violet.withValues(alpha: 0.12),
        showBackButton: true,
        actions: [
          if (!_isLoading && _error == null) ...[
            IconButton(
              tooltip: 'ناردنی PDF',
              onPressed: _isExportingPdf ? null : () => _exportPdf(share: true),
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.getSurface(context),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.getBorder(context)),
                ),
                child: const Icon(Iconsax.export_1, color: _indigo, size: 18),
              ),
            ),
            IconButton(
              tooltip: 'پاشەکەوت / چاپکردنی PDF',
              onPressed: _isExportingPdf ? null : () => _exportPdf(share: false),
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _violet.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _violet.withValues(alpha: 0.25)),
                ),
                child: _isExportingPdf
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _violet,
                        ),
                      )
                    : const Icon(
                        Iconsax.document_download,
                        color: _violet,
                        size: 18,
                      ),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _violet))
          : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: () => _load(forceRefresh: true),
                  color: _violet,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeaderFilterCard(isDark),
                        const SizedBox(height: 16),
                        _buildPrimaryKpisGrid(isDark),
                        const SizedBox(height: 12),
                        _buildFinancialStrip(isDark),
                        const SizedBox(height: 18),
                        _buildSixMonthChartCard(isDark),
                        const SizedBox(height: 18),
                        _buildBreakdownCard(isDark),
                        const SizedBox(height: 18),
                        _buildEcosystemCard(isDark),
                        const SizedBox(height: 18),
                        _buildTopItemsCard(isDark),
                        const SizedBox(height: 18),
                        _buildTopProvidersCard(isDark),
                        const SizedBox(height: 18),
                        _buildMonthlyBreakdownCard(isDark),
                        const SizedBox(height: 18),
                        _buildOrdersLedgerCard(isDark),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.info_circle, size: 48, color: Colors.amber),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: AdminUi.subtitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _load(forceRefresh: true),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text(
                'دووبارە هەوڵبدەرەوە',
                style: TextStyle(fontFamily: 'Rabar'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _violet,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 1. Header, Month & Service Filters + PDF Action Bar ──
  Widget _buildHeaderFilterCard(bool isDark) {
    final months = List<String>.from((_report['months'] as List?) ?? []);
    final currentMonth = (_report['current_month'] ?? '').toString();
    final periodLabel =
        _selectedMonth == 'all' ? 'هەموو مانگەکان' : _selectedMonth;

    const serviceFilters = [
      (key: 'all', label: 'هەمووی', icon: Iconsax.category),
      (key: 'lab', label: 'تاقیگە', icon: Iconsax.microscope),
      (key: 'nursing', label: 'پەرستاری', icon: Iconsax.profile_2user),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.getBorder(context)),
        boxShadow: [
          BoxShadow(
            color: _violet.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _violet.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.calendar_1, size: 13, color: _violet),
                    const SizedBox(width: 5),
                    const Text(
                      'حسابات و ئامار • ',
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _violet,
                      ),
                    ),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        periodLabel,
                        style: const TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _violet,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (_selectedMonth != currentMonth && currentMonth.isNotEmpty)
                TextButton(
                  onPressed: () => _selectMonth(currentMonth),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'ئەم مانگە',
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: _violet,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Month selector chips
          const Text(
            'فلتەری مانگ',
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterPill(
                  label: 'هەموو کاتەکان',
                  selected: _selectedMonth == 'all',
                  color: _violet,
                  onTap: () => _selectMonth('all'),
                ),
                ...months.map((m) {
                  final isCurrent = m == currentMonth;
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(start: 6),
                    child: _buildFilterPill(
                      label: isCurrent ? '$m (ئێستا)' : m,
                      selected: _selectedMonth == m,
                      color: _violet,
                      ltrText: true,
                      onTap: () => _selectMonth(m),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Service sector filter chips
          const Text(
            'جۆری خزمەتگوزاری',
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: serviceFilters.map((f) {
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: _buildFilterPill(
                    label: f.label,
                    icon: f.icon,
                    selected: _serviceType == f.key,
                    color: _indigo,
                    onTap: () => _selectServiceType(f.key),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Save / Print & Share PDF buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isExportingPdf ? null : () => _exportPdf(share: false),
                  icon: const Icon(Iconsax.document_download, size: 17),
                  label: const Text(
                    'پاشەکەوت / چاپکردنی PDF',
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _violet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _isExportingPdf ? null : () => _exportPdf(share: true),
                icon: const Icon(Iconsax.export_1, size: 16),
                label: const Text(
                  'ناردن',
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _indigo,
                  side: BorderSide(color: _indigo.withValues(alpha: 0.35)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.03, end: 0);
  }

  Widget _buildFilterPill({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
    IconData? icon,
    bool ltrText = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.getBackground(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AppColors.getBorder(context),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : const Color(0xFF64748B),
              ),
              const SizedBox(width: 5),
            ],
            Directionality(
              textDirection: ltrText ? TextDirection.ltr : TextDirection.rtl,
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : AppColors.getTextTitle(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 2. Primary 4 KPI Cards (2x2 Grid, matching provider_reports) ──
  Widget _buildPrimaryKpisGrid(bool isDark) {
    final summary = (_report['summary'] as Map?) ?? {};
    final overall = (_report['overall'] as Map?) ?? {};
    final ecosystem = (_report['ecosystem'] as Map?) ?? {};

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                label: 'کۆی گشتی داهات',
                value: _formatIqd(summary['gross_revenue']),
                icon: Iconsax.wallet_3,
                color: _violet,
                footerLeft: 'کۆمیشن: ${_formatIqd(summary['commission_total'])}',
                footerRight: 'پوختی دابینکار: ${_formatCompact(summary['provider_net'])}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildKpiCard(
                label: 'داواکاری تەواوکراو',
                value:
                    '${_formatNum(summary['completed_orders'])} / ${_formatNum(summary['total_orders'])}',
                icon: Iconsax.tick_circle,
                color: _emerald,
                footerLeft: 'چالاک: ${_formatNum(summary['active_orders'])}',
                footerRight: 'تەواوبوون: ${summary['completion_rate'] ?? 0}%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                label: 'پشکنین و خزمەتگوزاری',
                value: _formatNum(summary['items_performed']),
                icon: Iconsax.microscope,
                color: _indigo,
                footerLeft: 'هەموو کات: ${_formatNum(overall['items_performed'])}',
                footerRight:
                    'ئەنجام: ${_formatNum(ecosystem['total_lab_results'])}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildKpiCard(
                label: 'نەخۆشە چالاکەکان',
                value: _formatNum(summary['unique_patients']),
                icon: Iconsax.profile_2user,
                color: _amber,
                footerLeft: 'تۆماری نوێ: ${_formatNum(summary['new_users'])}',
                footerRight: 'کۆی ئەپ: ${_formatNum(ecosystem['total_patients'])}',
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 60.ms).slideY(begin: 0.03, end: 0);
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required String footerLeft,
    required String footerRight,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.getBorder(context)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextSubtitle(context),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Rabar',
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: AppColors.getBorder(context).withValues(alpha: 0.6)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  footerLeft,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 10,
                    color: AppColors.getTextSubtitle(context),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  footerRight,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextTitle(context),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 3. Financial & Payment Split Strip ──
  Widget _buildFinancialStrip(bool isDark) {
    final summary = (_report['summary'] as Map?) ?? {};
    final overall = (_report['overall'] as Map?) ?? {};
    final netProfit = double.tryParse('${summary['net_profit'] ?? 0}') ?? 0.0;

    final cards = [
      (
        label: 'داهاتی کاش (Cash)',
        value: _formatIqd(summary['cash_revenue']),
        tag: 'کاش',
        color: _emerald,
      ),
      (
        label: 'داهاتی ئۆنلاین / کارت',
        value: _formatIqd(summary['online_revenue']),
        tag: 'ئۆنلاین',
        color: _indigo,
      ),
      (
        label: 'خەرجییەکانی ماوەکە',
        value: _formatIqd(summary['expenses_total']),
        tag: 'خەرجی',
        color: _rose,
      ),
      (
        label: 'قازانجی پوختی سەکۆ',
        value: _formatIqd(netProfit),
        tag: 'کۆمیشن - خەرجی',
        color: netProfit >= 0 ? _violet : _rose,
      ),
      (
        label: 'داشکاندن و کۆدەکان',
        value: _formatIqd(summary['discount_total']),
        tag: '${summary['discounted_orders'] ?? 0} داواکاری',
        color: _amber,
      ),
      (
        label: 'کۆی داهات (هەموو کات)',
        value: _formatIqd(overall['gross_revenue']),
        tag: 'گشتی',
        color: const Color(0xFF0D9488),
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: cards.map((c) {
          return Container(
            width: 165,
            margin: const EdgeInsetsDirectional.only(end: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.getSurface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.getBorder(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: c.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    c.tag,
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: c.color,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  c.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 10.5,
                    color: AppColors.getTextSubtitle(context),
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    c.value,
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextTitle(context),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── 4. 6-Month Activity & Revenue Combo Chart ──
  Widget _buildSixMonthChartCard(bool isDark) {
    final series = ((_report['chart_series'] as List?) ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final selectedPoint = (_selectedChartIndex != null &&
            _selectedChartIndex! >= 0 &&
            _selectedChartIndex! < series.length)
        ? series[_selectedChartIndex!]
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'هێڵکاری داهات و چالاکی ٦ مانگی ڕابردوو',
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextTitle(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'کرتە لەسەر هەر مانگێک بکە بۆ بینینی وردەکاری',
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 11,
                        color: AppColors.getTextSubtitle(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _legendDot(_violet, 'داهاتی گشتی (د.ع)'),
              const SizedBox(width: 14),
              _legendDot(_emerald, 'داواکاری تەواوکراو'),
            ],
          ),
          const SizedBox(height: 14),
          if (series.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'داتای هێڵکاری بەردەست نییە',
                  style: TextStyle(fontFamily: 'Rabar', color: Color(0xFF94A3B8)),
                ),
              ),
            )
          else ...[
            Directionality(
              textDirection: TextDirection.ltr,
              child: Column(
                children: [
                  SizedBox(
                    height: 195,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          onTapDown: (details) {
                            final colWidth = constraints.maxWidth / series.length;
                            final tapped =
                                (details.localPosition.dx / colWidth).floor().clamp(0, series.length - 1);
                            setState(() => _selectedChartIndex = tapped);
                          },
                          child: CustomPaint(
                            size: Size(constraints.maxWidth, 195),
                            painter: _SixMonthComboChartPainter(
                              series: series,
                              selectedIndex: _selectedChartIndex,
                              isDark: isDark,
                              barColor: _violet,
                              lineColor: _emerald,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Month labels row (clickable)
                  Row(
                    children: series.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final m = (entry.value['month'] ?? '').toString();
                      final shortLabel = m.length >= 7 ? m.substring(2) : m;
                      final isSelected = idx == _selectedChartIndex;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedChartIndex = idx),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _violet.withValues(alpha: 0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              shortLabel,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 10.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected
                                    ? _violet
                                    : AppColors.getTextSubtitle(context),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            if (selectedPoint != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: AppColors.getBackground(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _violet.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              '${selectedPoint['month']}',
                              style: const TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _violet,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'داهات: ${_formatIqd(selectedPoint['gross_revenue'])}  •  تەواوکراو: ${selectedPoint['completed_orders']}/${selectedPoint['total_orders']}  •  خەرجی: ${_formatIqd(selectedPoint['expenses_total'])}',
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 11,
                              color: AppColors.getTextTitle(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          _selectMonth((selectedPoint['month'] ?? '').toString()),
                      child: const Text(
                        'فلتەرکردن',
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: _violet,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.03, end: 0);
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Rabar',
            fontSize: 11,
            color: AppColors.getTextSubtitle(context),
          ),
        ),
      ],
    );
  }

  // ── 5. Service Sector Donut & Order Status Breakdown ──
  Widget _buildBreakdownCard(bool isDark) {
    final sectors = ((_report['service_breakdown'] as List?) ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final statuses = ((_report['status_breakdown'] as List?) ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final totalSectorOrders =
        sectors.fold<int>(0, (sum, s) => sum + ((s['orders_count'] as num?)?.toInt() ?? 0));
    final totalStatusOrders =
        statuses.fold<int>(0, (sum, s) => sum + ((s['count'] as num?)?.toInt() ?? 0));

    Color sectorColor(String key) {
      return switch (key) {
        'lab' => _indigo,
        'nursing' => _emerald,
        'pharmacy' => _amber,
        _ => _violet,
      };
    }

    Color statusColor(String key) {
      return switch (key) {
        'completed' => _emerald,
        'active' => _amber,
        _ => _rose,
      };
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'دابەشبوونی کەرتەکان و دۆخی داواکارییەکان',
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextTitle(context),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Donut Chart
              SizedBox(
                width: 110,
                height: 110,
                child: CustomPaint(
                  painter: _DonutChartPainter(
                    slices: sectors
                        .map((s) => _DonutSlice(
                              value: ((s['orders_count'] as num?) ?? 0).toDouble(),
                              color: sectorColor((s['key'] ?? '').toString()),
                            ))
                        .toList(),
                    trackColor: AppColors.getBorder(context),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$totalSectorOrders',
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.getTextTitle(context),
                          ),
                        ),
                        Text(
                          'داواکاری',
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 10,
                            color: AppColors.getTextSubtitle(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Sector Bars
              Expanded(
                child: sectors.isEmpty
                    ? Text(
                        'هیچ داواکارییەک لەم ماوەیەدا نییە',
                        style: AdminUi.subtitle,
                      )
                    : Column(
                        children: sectors.map((s) {
                          final key = (s['key'] ?? '').toString();
                          final color = sectorColor(key);
                          final count = (s['orders_count'] as num?)?.toInt() ?? 0;
                          final pct = totalSectorOrders > 0
                              ? (count / totalSectorOrders * 100).round()
                              : 0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          (s['label'] ?? '').toString(),
                                          style: TextStyle(
                                            fontFamily: 'Rabar',
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.getTextTitle(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '$count ($pct%)',
                                      style: TextStyle(
                                        fontFamily: 'Rabar',
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: totalSectorOrders > 0
                                        ? count / totalSectorOrders
                                        : 0,
                                    minHeight: 6,
                                    backgroundColor: color.withValues(alpha: 0.12),
                                    valueColor: AlwaysStoppedAnimation(color),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'داهات: ${_formatIqd(s['revenue'])}',
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 10,
                                    color: AppColors.getTextSubtitle(context),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Status segmented bar
          Text(
            'دۆخی داواکارییەکانی فلتەرکراو',
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextSubtitle(context),
            ),
          ),
          const SizedBox(height: 8),
          if (totalStatusOrders > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: statuses.map((st) {
                    final cnt = (st['count'] as num?)?.toInt() ?? 0;
                    if (cnt == 0) return const SizedBox.shrink();
                    return Expanded(
                      flex: cnt,
                      child: Container(color: statusColor((st['key'] ?? '').toString())),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: statuses.map((st) {
              final cnt = (st['count'] as num?)?.toInt() ?? 0;
              final col = statusColor((st['key'] ?? '').toString());
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: col.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$cnt',
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: col,
                        ),
                      ),
                      Text(
                        (st['label'] ?? '').toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextTitle(context),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 140.ms).slideY(begin: 0.03, end: 0);
  }

  // ── 6. System Ecosystem Snapshot ──
  Widget _buildEcosystemCard(bool isDark) {
    final eco = (_report['ecosystem'] as Map?) ?? {};
    final items = [
      (
        label: 'تاقیگەکان',
        val: '${eco['total_labs'] ?? 0}',
        sub: 'چاوەڕوان: ${eco['pending_labs'] ?? 0}',
        icon: Iconsax.microscope,
        color: _indigo,
      ),
      (
        label: 'پەرستارەکان',
        val: '${eco['total_nurses'] ?? 0}',
        sub: 'چاوەڕوان: ${eco['pending_nurses'] ?? 0}',
        icon: Iconsax.profile_2user,
        color: _emerald,
      ),
      (
        label: 'کارمەندانی گەیاندن',
        val: '${eco['total_drivers'] ?? 0}',
        sub: 'لە هێڵ: ${eco['online_drivers'] ?? 0}',
        icon: Iconsax.truck_fast,
        color: const Color(0xFF0D9488),
      ),
      (
        label: 'ئەنجامی تاقیگە',
        val: '${eco['total_lab_results'] ?? 0}',
        sub: 'پشکنینی تۆمارکراو',
        icon: Iconsax.document_text,
        color: _violet,
      ),
      (
        label: 'دەرمانخانەکان',
        val: '${eco['total_pharmacies'] ?? 0}',
        sub: 'چاوەڕوان: ${eco['pending_pharmacies'] ?? 0}',
        icon: Iconsax.health,
        color: _amber,
      ),
      (
        label: 'تیکێتی پشتیوانی',
        val: '${eco['open_tickets'] ?? 0}',
        sub: 'کراوەی ئێستا',
        icon: Iconsax.message_question,
        color: _rose,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'پوختەی گشتی پێکهاتەکانی سیستەم',
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextTitle(context),
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.08,
            ),
            itemBuilder: (_, idx) {
              final it = items[idx];
              return Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.getBackground(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.getBorder(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(it.icon, size: 17, color: it.color),
                    Text(
                      it.val,
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.getTextTitle(context),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          it.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getTextTitle(context),
                          ),
                        ),
                        Text(
                          it.sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 9,
                            color: AppColors.getTextSubtitle(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── 7. Top Requested Services & Lab Tests ──
  Widget _buildTopItemsCard(bool isDark) {
    final topItems = ((_report['top_items'] as List?) ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final maxCount = topItems.isNotEmpty
        ? topItems
            .map((e) => (e['count'] as num?)?.toInt() ?? 1)
            .reduce(math.max)
            .clamp(1, 999999)
        : 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'زۆرترین پشکنین و خزمەتگوزاری داواکراو',
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextTitle(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'تەنها لە داواکارییە تەواوکراوەکانی ماوەی دیاریکراو',
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: 11,
              color: AppColors.getTextSubtitle(context),
            ),
          ),
          const SizedBox(height: 12),
          if (topItems.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'لەم ماوەیەدا هیچ خزمەتگوزارییەکی تەواوکراو نییە',
                  style: TextStyle(fontFamily: 'Rabar', color: Color(0xFF94A3B8)),
                ),
              ),
            )
          else
            ...topItems.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final count = (item['count'] as num?)?.toInt() ?? 0;
              final ratio = count / maxCount;
              return Padding(
                padding: EdgeInsets.only(bottom: i == topItems.length - 1 ? 0 : 10),
                child: Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: AppColors.getBackground(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.getBorder(context)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _violet.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: _violet,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (item['name'] ?? '').toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.getTextTitle(context),
                                  ),
                                ),
                                Text(
                                  _formatIqd(item['revenue']),
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 10.5,
                                    color: AppColors.getTextSubtitle(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.getSurface(context),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.getBorder(context)),
                            ),
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                '${count}x',
                                style: const TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: _violet,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio.clamp(0.0, 1.0),
                          minHeight: 5,
                          backgroundColor: _violet.withValues(alpha: 0.1),
                          valueColor: const AlwaysStoppedAnimation(_violet),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // ── 8. Top Performing Labs & Nurses ──
  Widget _buildTopProvidersCard(bool isDark) {
    final topLabs = ((_report['top_labs'] as List?) ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final topNurses = ((_report['top_nurses'] as List?) ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final list = _providerTab == 0 ? topLabs : topNurses;
    final accent = _providerTab == 0 ? _indigo : _emerald;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'باشترین دابینکارەکانی ماوەکە',
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextTitle(context),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.getBackground(context),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.getBorder(context)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _tabChip('تاقیگەکان', 0, _indigo),
                    _tabChip('پەرستارەکان', 1, _emerald),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  _providerTab == 0
                      ? 'هیچ داواکارییەکی تەواوکراوی تاقیگە نییە'
                      : 'هیچ داواکارییەکی تەواوکراوی پەرستار نییە',
                  style: AdminUi.subtitle,
                ),
              ),
            )
          else
            ...list.asMap().entries.map((entry) {
              final i = entry.key;
              final p = entry.value;
              return Container(
                margin: EdgeInsets.only(bottom: i == list.length - 1 ? 0 : 8),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: AppColors.getBackground(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.getBorder(context)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: accent.withValues(alpha: 0.12),
                      child: Icon(
                        _providerTab == 0
                            ? Iconsax.microscope
                            : Iconsax.profile_2user,
                        size: 16,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (p['name'] ?? '').toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.getTextTitle(context),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '${p['orders_count'] ?? 0} داواکاری تەواوکراو',
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 10.5,
                                  color: AppColors.getTextSubtitle(context),
                                ),
                              ),
                              if (_providerTab == 1 && p['rating'] != null) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.star, size: 12, color: Colors.amber),
                                const SizedBox(width: 2),
                                Text(
                                  '${p['rating']}',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatIqd(p['revenue']),
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _tabChip(String label, int index, Color color) {
    final active = _providerTab == index;
    return GestureDetector(
      onTap: () => setState(() => _providerTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Rabar',
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: active ? Colors.white : AppColors.getTextSubtitle(context),
          ),
        ),
      ),
    );
  }

  // ── 9. Monthly Breakdown Table (tap any month to filter) ──
  Widget _buildMonthlyBreakdownCard(bool isDark) {
    final rows = ((_report['monthly_rows'] as List?) ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final currentMonth = (_report['current_month'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'خشتەی ڕاپۆرتی مانگانە',
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextTitle(context),
                    ),
                  ),
                  Text(
                    'کرتە لەسەر هەر مانگێک بکە بۆ بینینی وردەکارییەکەی',
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 11,
                      color: AppColors.getTextSubtitle(context),
                    ),
                  ),
                ],
              ),
              Text(
                '${rows.length} مانگ',
                style: const TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: _violet,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'هیچ مانگێک تۆمارنەکراوە',
                  style: TextStyle(fontFamily: 'Rabar', color: Color(0xFF94A3B8)),
                ),
              ),
            )
          else
            ...rows.map((row) {
              final m = (row['month'] ?? '').toString();
              final isSelected = m == _selectedMonth;
              final isNow = m == currentMonth;
              return GestureDetector(
                onTap: () => _selectMonth(m),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _violet.withValues(alpha: 0.08)
                        : AppColors.getBackground(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? _violet : AppColors.getBorder(context),
                      width: isSelected ? 1.4 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  m,
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.getTextTitle(context),
                                  ),
                                ),
                              ),
                              if (isNow) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _violet.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'ئێستا',
                                    style: TextStyle(
                                      fontFamily: 'Rabar',
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _violet,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            _formatIqd(row['gross_revenue']),
                            style: const TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _emerald,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _miniCell(
                            'تەواوکراو',
                            '${row['completed_orders']}/${row['total_orders']}',
                          ),
                          _miniCell(
                            'خزمەتگوزاری',
                            '${row['items_performed']}',
                          ),
                          _miniCell(
                            'کۆمیشن',
                            _formatCompact(row['commission_total']),
                          ),
                          _miniCell(
                            'خەرجی',
                            _formatCompact(row['expenses_total']),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _miniCell(String label, String val) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Rabar',
                fontSize: 9.5,
                color: AppColors.getTextSubtitle(context),
              ),
            ),
            Text(
              val,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Rabar',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextTitle(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 10. Period Orders Ledger ──
  Widget _buildOrdersLedgerCard(bool isDark) {
    final allOrders = ((_report['ledger_orders'] as List?) ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final filtered = allOrders.where((o) {
      final st = (o['status'] ?? '').toString().toLowerCase();
      return switch (_ledgerStatusFilter) {
        'completed' => st == 'completed',
        'cancelled' => st == 'cancelled' || st == 'rejected',
        'active' => st != 'completed' && st != 'cancelled' && st != 'rejected',
        _ => true,
      };
    }).toList();

    const statusChips = [
      (key: 'all', label: 'هەمووی'),
      (key: 'completed', label: 'تەواوکراو'),
      (key: 'active', label: 'چالاک'),
      (key: 'cancelled', label: 'هەڵوەشاوە'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تۆماری داواکارییەکانی ماوەکە',
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextTitle(context),
                      ),
                    ),
                    Text(
                      'بە پێی کاتی ناوخۆی هەولێر • ${filtered.length} تۆمار',
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 11,
                        color: AppColors.getTextSubtitle(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: statusChips.map((c) {
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: _buildFilterPill(
                    label: c.label,
                    selected: _ledgerStatusFilter == c.key,
                    color: _violet,
                    onTap: () => setState(() => _ledgerStatusFilter = c.key),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'لەم ماوەیەدا هیچ داواکارییەک بۆ ئەم فلتەرە نییە',
                  style: TextStyle(fontFamily: 'Rabar', color: Color(0xFF94A3B8)),
                ),
              ),
            )
          else
            ...filtered.take(25).map((o) {
              final st = (o['status'] ?? '').toString().toLowerCase();
              final sColor = st == 'completed'
                  ? _emerald
                  : (st == 'cancelled' || st == 'rejected' ? _rose : _amber);
              final sLabel = switch (st) {
                'completed' => 'تەواوکراو',
                'cancelled' || 'rejected' => 'هەڵوەشاوە',
                'pending' => 'چاوەڕوان',
                _ => 'لە کاردایە',
              };
              final payLabel =
                  (o['payment_method'] ?? 'cash') == 'cash' ? 'کاش' : 'ئۆنلاین';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.getBackground(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.getBorder(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${o['patient_name'] ?? 'نەخۆش'}  •  ${o['order_number'] ?? ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.getTextTitle(context),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: sColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            sLabel,
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: sColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (o['items_summary'] ?? '').toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 11.5,
                        color: AppColors.getTextSubtitle(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${o['provider_name']} • ${o['date']} • $payLabel',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 10,
                              color: AppColors.getTextSubtitle(context),
                            ),
                          ),
                        ),
                        Text(
                          _formatIqd(o['total_price']),
                          style: const TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: _violet,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ── CustomPainter: 6-Month Revenue Bars + Completed Orders Trend Line ──
class _SixMonthComboChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> series;
  final int? selectedIndex;
  final bool isDark;
  final Color barColor;
  final Color lineColor;

  _SixMonthComboChartPainter({
    required this.series,
    required this.selectedIndex,
    required this.isDark,
    required this.barColor,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) return;

    const double topPad = 24;
    const double bottomPad = 10;
    final double chartH = size.height - topPad - bottomPad;
    final double colW = size.width / series.length;

    final maxRev = series
        .map((e) => (double.tryParse('${e['gross_revenue'] ?? 0}') ?? 0))
        .fold<double>(0, math.max);
    final safeMaxRev = maxRev <= 0 ? 1.0 : maxRev;

    final maxOrd = series
        .map((e) => (int.tryParse('${e['completed_orders'] ?? 0}') ?? 0))
        .fold<int>(0, math.max);
    final safeMaxOrd = maxOrd <= 0 ? 1.0 : maxOrd.toDouble();

    // Subtle horizontal grid lines
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (int g = 0; g <= 3; g++) {
      final y = topPad + (chartH / 3) * g;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final List<Offset> linePoints = [];

    for (int i = 0; i < series.length; i++) {
      final item = series[i];
      final rev = double.tryParse('${item['gross_revenue'] ?? 0}') ?? 0.0;
      final ord = int.tryParse('${item['completed_orders'] ?? 0}') ?? 0;

      final barW = math.min(28.0, colW * 0.46);
      final cx = colW * i + colW / 2;
      final barH = (rev / safeMaxRev) * chartH;
      final barTop = topPad + chartH - barH;
      final isSelected = i == selectedIndex;

      // Bar rect
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(cx - barW / 2, barTop, barW, math.max(barH, 3)),
        topLeft: const Radius.circular(7),
        topRight: const Radius.circular(7),
      );
      final barPaint = Paint()
        ..color = isSelected ? barColor : barColor.withValues(alpha: 0.35);
      canvas.drawRRect(rect, barPaint);

      // Revenue mini label on top of selected bar or non-zero bar
      if (rev > 0 || isSelected) {
        final label = rev >= 1000000
            ? '${(rev / 1000000).toStringAsFixed(1)}M'
            : (rev >= 1000 ? '${(rev / 1000).toStringAsFixed(0)}K' : rev.toStringAsFixed(0));
        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected
                  ? barColor
                  : (isDark ? Colors.white70 : const Color(0xFF64748B)),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(cx - tp.width / 2, math.max(0, barTop - 15)));
      }

      // Line point for completed orders
      final ordY = topPad + chartH - ((ord / safeMaxOrd) * (chartH * 0.85));
      linePoints.add(Offset(cx, ordY));
    }

    // Draw trend line
    if (linePoints.length > 1) {
      final path = Path()..moveTo(linePoints.first.dx, linePoints.first.dy);
      for (int i = 1; i < linePoints.length; i++) {
        final prev = linePoints[i - 1];
        final curr = linePoints[i];
        final ctrlX = (prev.dx + curr.dx) / 2;
        path.cubicTo(ctrlX, prev.dy, ctrlX, curr.dy, curr.dx, curr.dy);
      }
      final linePaint = Paint()
        ..color = lineColor
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, linePaint);
    }

    // Draw line dots
    for (int i = 0; i < linePoints.length; i++) {
      final p = linePoints[i];
      final isSelected = i == selectedIndex;
      canvas.drawCircle(
        p,
        isSelected ? 5.5 : 4,
        Paint()..color = isDark ? const Color(0xFF1E293B) : Colors.white,
      );
      canvas.drawCircle(
        p,
        isSelected ? 4 : 2.8,
        Paint()..color = lineColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SixMonthComboChartPainter oldDelegate) {
    return oldDelegate.series != series ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.isDark != isDark;
  }
}

// ── CustomPainter: Donut Chart for Service Sectors ──
class _DonutSlice {
  final double value;
  final Color color;
  const _DonutSlice({required this.value, required this.color});
}

class _DonutChartPainter extends CustomPainter {
  final List<_DonutSlice> slices;
  final Color trackColor;

  _DonutChartPainter({required this.slices, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    const strokeWidth = 14.0;

    final trackPaint = Paint()
      ..color = trackColor.withValues(alpha: 0.45)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, trackPaint);

    final total = slices.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0) return;

    double startAngle = -math.pi / 2;
    const gap = 0.04;
    final nonZero = slices.where((s) => s.value > 0).length;

    for (final s in slices) {
      if (s.value <= 0) continue;
      final sweep = (s.value / total) * (2 * math.pi) - (nonZero > 1 ? gap : 0);
      if (sweep <= 0) continue;
      final paint = Paint()
        ..color = s.color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        paint,
      );
      startAngle += sweep + (nonZero > 1 ? gap : 0);
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.slices != slices || oldDelegate.trackColor != trackColor;
  }
}
