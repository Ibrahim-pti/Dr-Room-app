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
import 'services/commission_pdf_service.dart';

class AdminCommissionScreen extends StatefulWidget {
  const AdminCommissionScreen({super.key});

  @override
  State<AdminCommissionScreen> createState() => _AdminCommissionScreenState();
}

class _AdminCommissionScreenState extends State<AdminCommissionScreen> {
  static const _green = Color(0xFF10B981);

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isExporting = false;
  Map<String, dynamic> _summary = {};
  String? _error;

  late DateTime _period = DateTime(DateTime.now().year, DateTime.now().month);

  int _totalOrders = 0;
  double _totalRevenue = 0;
  double _totalCommission = 0;
  double _totalProviderPayout = 0;
  bool _isCustomMonth = false;
  List<dynamic> _breakdown = [];
  List<Map<String, dynamic>> _providers = [];
  String _providerFilter = 'all';
  String _providerSearch = '';

  final _nursingRateCtrl = TextEditingController();
  final _labRateCtrl = TextEditingController();
  final _providerSearchCtrl = TextEditingController();

  bool get _isDark => ThemeProvider().isDarkMode;
  String get _periodQuery => 'year=${_period.year}&month=${_period.month}';
  String get _periodLabel => '${_period.month.toString().padLeft(2, '0')} / ${_period.year}';
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
    _providerSearchCtrl.dispose();
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
        final nursingRate = _num(r['nursing_rate'] ?? 10);
        final labRate = _num(r['lab_rate'] ?? 15);
        final rawProviders = s['providers'];

        List<Map<String, dynamic>> providersList = [];
        if (rawProviders is List) {
          providersList = rawProviders.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        } else {
          providersList = await _loadProvidersFallback(nursingRate: nursingRate, labRate: labRate);
          if (!mounted) return;
        }

        final summaryMap = Map<String, dynamic>.from(s as Map);
        summaryMap['providers'] = providersList;

        setState(() {
          _summary = summaryMap;
          _totalOrders = (s['total_orders'] as num?)?.toInt() ?? 0;
          _totalRevenue = _num(s['total_revenue']);
          _totalCommission = _num(s['total_commission']);
          _totalProviderPayout = _num(s['total_provider_payout']);
          _breakdown = s['breakdown'] ?? [];
          _providers = providersList;
          _nursingRateCtrl.text = _fmtRate(nursingRate);
          _labRateCtrl.text = _fmtRate(labRate);
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

  /// Builds the per-nurse & per-lab list client-side when the server hasn't
  /// yet deployed the `providers` field on `/admin/commission/summary`.
  Future<List<Map<String, dynamic>>> _loadProvidersFallback({
    required double nursingRate,
    required double labRate,
  }) async {
    try {
      final resList = await Future.wait([
        ApiClient.get('/admin/nurses'),
        ApiClient.get('/admin/labs'),
        ApiClient.get('/admin/orders'),
      ]);

      final providers = <String, Map<String, dynamic>>{};
      final labRecordToUserId = <int, dynamic>{};
      final nurseRecordToUserId = <int, dynamic>{};

      void seedList(dynamic decoded, String type, double rate) {
        final list = decoded is List ? decoded : (decoded is Map ? (decoded['data'] as List? ?? []) : []);
        for (final item in list) {
          if (item is! Map) continue;
          final id = item['id'];
          if (id == null) continue;
          if (type == 'lab' && item['lab'] is Map && item['lab']['id'] != null) {
            final recId = int.tryParse('${item['lab']['id']}');
            if (recId != null) labRecordToUserId[recId] = id;
          }
          if (type == 'nursing' && item['nurse'] is Map && item['nurse']['id'] != null) {
            final recId = int.tryParse('${item['nurse']['id']}');
            if (recId != null) nurseRecordToUserId[recId] = id;
          }
          final key = '${type}_$id';
          providers[key] = {
            'id': id,
            'name': (item['name'] ?? (type == 'lab' ? 'تاقیگە' : 'پەرستار')).toString(),
            'phone': (item['phone'] ?? '').toString(),
            'service_type': type,
            'status': (item['status'] ?? 'approved').toString(),
            'rate': rate,
            'total_orders': 0,
            'total_amount': 0.0,
            'total_commission': 0.0,
            'provider_net': 0.0,
            'orders': <Map<String, dynamic>>[],
          };
        }
      }

      if (resList[0].statusCode == 200) {
        seedList(jsonDecode(resList[0].body), 'nursing', nursingRate);
      }
      if (resList[1].statusCode == 200) {
        seedList(jsonDecode(resList[1].body), 'lab', labRate);
      }

      if (resList[2].statusCode == 200) {
        final ordersBody = jsonDecode(resList[2].body);
        final orders = (ordersBody['orders'] as List?) ?? (ordersBody['data'] as List?) ?? [];

        for (final raw in orders) {
          if (raw is! Map) continue;
          final status = (raw['status'] ?? '').toString().toLowerCase().trim();
          if (status != 'completed') continue;

          // Compare in UTC to match backend CommissionController's `config('app.timezone') = 'UTC'`
          final createdDt = DateTime.tryParse('${raw['created_at'] ?? ''}')?.toUtc();
          if (createdDt == null || createdDt.year != _period.year || createdDt.month != _period.month) {
            continue;
          }

          final st = (raw['service_type'] ?? '').toString().toLowerCase();
          String? cat;
          if (st.contains('lab') || st.contains('تاقیگە')) {
            cat = 'lab';
          } else if (st.contains('nurs') || st.contains('پەرستار')) {
            cat = 'nursing';
          }
          if (cat == null) continue;

          final total = _num(raw['total_price']).clamp(0.0, double.infinity);
          final storedRate = _num(raw['commission_rate']);
          final storedComm = _num(raw['commission_amount']);
          final rate = cat == 'nursing' ? nursingRate : labRate;
          double comm;
          if (storedComm > 0) {
            comm = storedComm > total ? total : storedComm;
          } else if (storedRate > 0) {
            comm = double.parse((total * storedRate / 100.0).toStringAsFixed(2));
          } else {
            comm = double.parse((total * rate / 100.0).toStringAsFixed(2));
          }
          final net = double.parse((total - comm).toStringAsFixed(2));

          final providerUser = cat == 'nursing' ? raw['assigned_nurse'] : raw['assigned_lab'];
          dynamic providerId = cat == 'nursing' ? raw['assigned_nurse_id'] : raw['assigned_lab_id'];

          if (cat == 'lab' && providerId == null) {
            var items = raw['items'];
            if (items is String) {
              try {
                items = jsonDecode(items);
              } catch (_) {}
            }
            if (items is List && items.isNotEmpty && items.first is Map) {
              var extra = items.first['extra_data'];
              if (extra is String) {
                try {
                  extra = jsonDecode(extra);
                } catch (_) {}
              }
              if (extra is Map && extra['lab_id'] != null) {
                final recId = int.tryParse('${extra['lab_id']}');
                if (recId != null) {
                  providerId = labRecordToUserId[recId] ?? recId;
                }
              }
            }
          } else if (cat == 'nursing' && providerId != null) {
            final rawInt = int.tryParse('$providerId');
            if (rawInt != null && !providers.containsKey('nursing_$rawInt') && nurseRecordToUserId.containsKey(rawInt)) {
              providerId = nurseRecordToUserId[rawInt];
            }
          }

          String key;
          if (providerId != null) {
            key = '${cat}_$providerId';
            if (!providers.containsKey(key)) {
              final pMap = providerUser is Map ? providerUser : const {};
              providers[key] = {
                'id': providerId,
                'name': (pMap['name'] ?? (cat == 'lab' ? 'تاقیگە' : 'پەرستار')).toString(),
                'phone': (pMap['phone'] ?? '').toString(),
                'service_type': cat,
                'status': (pMap['status'] ?? 'approved').toString(),
                'rate': rate,
                'total_orders': 0,
                'total_amount': 0.0,
                'total_commission': 0.0,
                'provider_net': 0.0,
                'orders': <Map<String, dynamic>>[],
              };
            }
          } else {
            key = 'unassigned_$cat';
            providers.putIfAbsent(key, () => {
                  'id': null,
                  'name': cat == 'lab' ? 'تاقیگەی دیارینەکراو' : 'پەرستاری دیارینەکراو',
                  'phone': '',
                  'service_type': cat,
                  'status': 'unassigned',
                  'rate': rate,
                  'total_orders': 0,
                  'total_amount': 0.0,
                  'total_commission': 0.0,
                  'provider_net': 0.0,
                  'orders': <Map<String, dynamic>>[],
                });
          }

          final target = providers[key]!;
          target['total_orders'] = (target['total_orders'] as int) + 1;
          target['total_amount'] = (target['total_amount'] as double) + total;
          target['total_commission'] = (target['total_commission'] as double) + comm;
          target['provider_net'] = (target['provider_net'] as double) + net;

          final patient = raw['patient'] is Map ? raw['patient'] as Map : const {};
          var pDetails = raw['patient_details'];
          if (pDetails is String) {
            try {
              pDetails = jsonDecode(pDetails);
            } catch (_) {}
          }
          final pName = (patient['name'] ?? (pDetails is Map ? pDetails['name'] : null) ?? 'نەخۆش').toString();
          (target['orders'] as List<Map<String, dynamic>>).add({
            'id': raw['id'],
            'patient_name': pName,
            'total_price': total,
            'commission_amount': comm,
            'provider_net': net,
            'created_at': raw['created_at'],
          });
        }
      }

      final result = providers.values.toList()
        ..sort((a, b) {
          final amtCmp = (b['total_amount'] as double).compareTo(a['total_amount'] as double);
          if (amtCmp != 0) return amtCmp;
          final ordCmp = (b['total_orders'] as int).compareTo(a['total_orders'] as int);
          if (ordCmp != 0) return ordCmp;
          return (a['name'] as String).compareTo(b['name'] as String);
        });

      return result;
    } catch (_) {
      return [];
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

  Future<void> _exportPdf({required bool share}) async {
    if (_summary.isEmpty || _isExporting) return;
    setState(() => _isExporting = true);
    try {
      if (share) {
        await CommissionPdfService.share(_summary);
      } else {
        await CommissionPdfService.preview(_summary);
      }
    } catch (e) {
      if (mounted) AdminUi.toast(context, 'کێشە لە دروستکردنی PDF: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Widget _buildPdfCard() {
    Widget action(String label, IconData icon, Color color, VoidCallback onTap) => Expanded(
          child: Material(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: _isExporting ? null : onTap,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(label,
                          style: TextStyle(fontFamily: 'Rabar', fontSize: 14, height: 1.5, color: color)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

    return Container(
      decoration: AdminUi.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Iconsax.document_download, color: Color(0xFFEF4444), size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('ڕاپۆرتی PDF ی مانگی $_periodLabel', style: AdminUi.title)),
              if (_isExporting)
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              action('پاشەکەوت / هاوبەشکردن', Iconsax.document_download, const Color(0xFFEF4444),
                  () => _exportPdf(share: true)),
              const SizedBox(width: 10),
              action('پیشاندان / چاپ', Iconsax.printer, const Color(0xFF6366F1), () => _exportPdf(share: false)),
            ],
          ),
        ],
      ),
    );
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
        actions: [
          IconButton(
            tooltip: 'PDF',
            onPressed: _isLoading || _isExporting ? null : () => _exportPdf(share: true),
            icon: const Icon(Iconsax.document_download, color: Color(0xFFEF4444)),
          ),
        ],
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
                            const SizedBox(height: 16),
                            _buildProvidersSection(),
                            const SizedBox(height: 16),
                            _buildPdfCard(),
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
          Material(
            color: _isSaving ? _green.withValues(alpha: 0.6) : _green,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: _isSaving ? null : _saveSettings,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Iconsax.tick_circle, size: 20, color: Colors.white),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'پاشەکەوتکردنی ڕێژەکان',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'Rabar', fontSize: 15, height: 1.5, color: Colors.white),
                      ),
                    ),
                  ],
                ),
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

  Widget _buildProvidersSection() {
    final nursingCount = _providers.where((p) => p['service_type'] == 'nursing').length;
    final labCount = _providers.where((p) => p['service_type'] == 'lab').length;

    final filtered = _providers.where((p) {
      if (_providerFilter != 'all' && p['service_type'] != _providerFilter) {
        return false;
      }
      if (_providerSearch.trim().isNotEmpty) {
        final q = _providerSearch.trim().toLowerCase();
        final name = (p['name'] ?? '').toString().toLowerCase();
        final phone = (p['phone'] ?? '').toString().toLowerCase();
        if (!name.contains(q) && !phone.contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    Widget filterPill(String key, String label) {
      final selected = _providerFilter == key;
      return GestureDetector(
        onTap: () => setState(() => _providerFilter = key),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? _green : AppColors.getSurface(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? _green : AppColors.getBorder(context),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : AdminUi.subtitle.color,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('پەرستارەکان و تاقیگەکان (${filtered.length})', style: AdminUi.title),
            Text(
              'مانگی $_periodLabel',
              style: AdminUi.subtitle.copyWith(fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              filterPill('all', 'هەمووی (${_providers.length})'),
              const SizedBox(width: 8),
              filterPill('nursing', 'پەرستاری ماڵەوە ($nursingCount)'),
              const SizedBox(width: 8),
              filterPill('lab', 'تاقیگەکان ($labCount)'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _providerSearchCtrl,
          onChanged: (v) => setState(() => _providerSearch = v),
          decoration: InputDecoration(
            hintText: 'گەڕان بەپێی ناوی پەرستار یان تاقیگە یان مۆبایل...',
            hintStyle: AdminUi.subtitle.copyWith(fontSize: 11.5),
            prefixIcon: const Icon(Iconsax.search_normal_1, size: 17),
            suffixIcon: _providerSearch.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _providerSearchCtrl.clear();
                      setState(() => _providerSearch = '');
                    },
                    icon: const Icon(Icons.close, size: 17),
                  )
                : null,
            filled: true,
            fillColor: AppColors.getSurface(context),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.getBorder(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.getBorder(context)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (filtered.isEmpty)
          Container(
            decoration: AdminUi.cardDecoration,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            child: Column(
              children: [
                const Icon(Iconsax.profile_2user, size: 36, color: Color(0xFF94A3B8)),
                const SizedBox(height: 8),
                Text(
                  'هیچ پەرستار یان تاقیگەیەک نەدۆزرایەوە',
                  style: AdminUi.subtitle,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...filtered.map((p) {
            final isLab = p['service_type'] == 'lab';
            final color = isLab ? const Color(0xFF8B5CF6) : const Color(0xFFEC4899);
            final total = _num(p['total_amount']);
            final comm = _num(p['total_commission']);
            final net = _num(p['provider_net']);
            final orders = (p['total_orders'] as num?)?.toInt() ?? 0;
            final phone = (p['phone'] ?? '').toString().trim();

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: AdminUi.cardDecoration,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _showProviderOrdersSheet(p),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isLab ? Iconsax.microscope : Iconsax.health,
                                color: color,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p['name']?.toString() ?? '',
                                    style: AdminUi.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    phone.isNotEmpty
                                        ? '${isLab ? 'تاقیگە' : 'پەرستاری'} • $phone • $orders داواکاری'
                                        : '${isLab ? 'تاقیگە' : 'پەرستاری'} • $orders داواکاری',
                                    style: AdminUi.subtitle.copyWith(fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _green.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_fmtRate(p['rate'])}%',
                                style: const TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _green,
                                ),
                              ),
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
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  void _showProviderOrdersSheet(Map<String, dynamic> provider) {
    final isLab = provider['service_type'] == 'lab';
    final color = isLab ? const Color(0xFF8B5CF6) : const Color(0xFFEC4899);
    final orders = ((provider['orders'] as List?) ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.78),
        decoration: BoxDecoration(
          color: AppColors.getSurface(ctx),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.getBorder(ctx),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(isLab ? Iconsax.microscope : Iconsax.health, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(provider['name']?.toString() ?? '', style: AdminUi.title),
                      Text(
                        '${isLab ? 'تاقیگە' : 'پەرستاری ماڵەوە'} • مانگی $_periodLabel • ${orders.length} داواکاری',
                        style: AdminUi.subtitle.copyWith(fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.getBackground(ctx),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.getBorder(ctx)),
              ),
              child: Row(
                children: [
                  _breakdownCell('کۆی داهات', _num(provider['total_amount']), AdminUi.title.color!),
                  _breakdownCell('کۆمیشن', _num(provider['total_commission']), _green),
                  _breakdownCell('پشکی پێشکەشکار', _num(provider['provider_net']), const Color(0xFF3B82F6)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (orders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Text(
                  'لەم مانگەدا هیچ داواکارییەکی تەواوکراو تۆمار نەکراوە',
                  style: AdminUi.subtitle,
                  textAlign: TextAlign.center,
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: orders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, idx) {
                    final o = orders[idx];
                    final dt = DateTime.tryParse('${o['created_at'] ?? ''}')?.toLocal();
                    final dateStr = dt != null ? DateFormat('yyyy/MM/dd • HH:mm').format(dt) : '-';
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.getBackground(ctx),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.getBorder(ctx)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('#${o['id']} • ${o['patient_name'] ?? 'نەخۆش'}',
                                  style: AdminUi.title.copyWith(fontSize: 13)),
                              Text(dateStr, style: AdminUi.subtitle.copyWith(fontSize: 10.5)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _breakdownCell('نرخ', _num(o['total_price']), AdminUi.title.color!),
                              _breakdownCell('کۆمیشن', _num(o['commission_amount']), _green),
                              _breakdownCell('پشکی پێشکەشکار', _num(o['provider_net']), const Color(0xFF3B82F6)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
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
