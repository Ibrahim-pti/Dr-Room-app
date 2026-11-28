import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart' as intl;

import '../../core/theme/app_colors.dart';
import '../../core/utils/api_client.dart';
import '../../core/utils/currency.dart';
import 'admin_app_bar.dart';
import 'admin_ui.dart';

class AdminCouponsScreen extends StatefulWidget {
  const AdminCouponsScreen({super.key});

  @override
  State<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends State<AdminCouponsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();

  List<dynamic> _coupons = [];
  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _byCode = [];
  Map<String, dynamic> _summary = {};

  bool _isLoading = true;
  bool _isHistoryLoading = true;
  String? _error;
  String? _historyError;

  String? _selectedCodeFilter;
  String _searchQuery = '';
  String _datePreset = 'all'; // all, today, 7d, month, custom
  DateTimeRange? _customDateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _isHistoryLoading = true;
      _error = null;
      _historyError = null;
    });

    await Future.wait([
      _loadCoupons(),
      _loadHistory(),
    ]);
  }

  Future<void> _loadCoupons() async {
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
      if (mounted) {
        setState(() {
          _error = '$e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadHistory() async {
    try {
      final res = await ApiClient.get('/admin/coupons/history');
      if (!mounted) return;

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final rawList = (body['data'] as List?) ?? [];
        final rawByCode = (body['by_code'] as List?) ?? [];
        final rawSummary = (body['summary'] as Map?) ?? {};

        setState(() {
          _history = rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _byCode = rawByCode.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _summary = Map<String, dynamic>.from(rawSummary);
          _isHistoryLoading = false;
        });
        return;
      }

      if (res.statusCode == 404) {
        await _loadHistoryFromOrdersFallback();
        return;
      }

      setState(() {
        _historyError = AdminUi.readError(res);
        _isHistoryLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _historyError = '$e';
          _isHistoryLoading = false;
        });
      }
    }
  }

  /// Fallback when the backend hasn't yet deployed `/admin/coupons/history`.
  Future<void> _loadHistoryFromOrdersFallback() async {
    try {
      final res = await ApiClient.get('/admin/orders');
      if (!mounted) return;

      if (res.statusCode != 200) {
        setState(() {
          _historyError = AdminUi.readError(res);
          _isHistoryLoading = false;
        });
        return;
      }

      final body = jsonDecode(res.body);
      final orders = (body['orders'] as List?) ?? (body['data'] as List?) ?? [];

      final couponLookup = <String, Map<String, dynamic>>{};
      for (final c in _coupons) {
        if (c is Map) {
          final code = (c['code'] ?? '').toString().trim().toUpperCase();
          if (code.isNotEmpty) {
            couponLookup[code] = Map<String, dynamic>.from(c);
          }
        }
      }

      final discounted = <Map<String, dynamic>>[];
      final activeUsages = <Map<String, dynamic>>[];
      final grouped = <String, List<Map<String, dynamic>>>{};

      for (final raw in orders) {
        if (raw is! Map) continue;
        final code = (raw['coupon_code'] ?? '').toString().trim().toUpperCase();
        final discAmt = num.tryParse('${raw['discount_amount'] ?? 0}') ?? 0;
        if (code.isEmpty && discAmt <= 0) continue;

        var patientDetails = raw['patient_details'];
        if (patientDetails is String) {
          try {
            patientDetails = jsonDecode(patientDetails);
          } catch (_) {}
        }
        final pd = patientDetails is Map ? patientDetails : {};
        final patient = raw['patient'] is Map ? raw['patient'] : null;

        final patientName = (patient?['name'] ?? pd['name'] ?? 'نەخۆش').toString();
        final patientPhone = (patient?['phone'] ?? pd['phone'] ?? '').toString();
        final patientId = raw['patient_id'] ?? patient?['id'];
        final coupon = code.isNotEmpty ? couponLookup[code] : null;

        final entry = <String, dynamic>{
          'order_id': raw['id'],
          'coupon_code': code.isNotEmpty ? code : null,
          'coupon_title': coupon?['title'],
          'discount_type': coupon?['discount_type'],
          'discount_value': coupon?['discount_value'],
          'discount_amount': discAmt.toDouble(),
          'subtotal': (num.tryParse('${raw['subtotal'] ?? 0}') ?? 0).toDouble(),
          'extra_fee': (num.tryParse('${raw['extra_fee'] ?? 0}') ?? 0).toDouble(),
          'total_price': (num.tryParse('${raw['total_price'] ?? 0}') ?? 0).toDouble(),
          'status': raw['status'],
          'service_type': raw['service_type'],
          'patient': {
            'id': patientId,
            'name': patientName,
            'phone': patientPhone,
          },
          'created_at': raw['created_at'],
        };

        discounted.add(entry);

        final status = (raw['status'] ?? '').toString().toLowerCase();
        if (status != 'cancelled' && status != 'rejected') {
          activeUsages.add(entry);
          if (code.isNotEmpty) {
            grouped.putIfAbsent(code, () => []).add(entry);
          }
        }
      }

      discounted.sort((a, b) =>
          (b['created_at'] ?? '').toString().compareTo((a['created_at'] ?? '').toString()));

      final byCode = grouped.entries.map((entry) {
        final code = entry.key;
        final items = entry.value;
        final coupon = couponLookup[code];
        final uniqueUsers = items
            .map((i) => (i['patient'] as Map?)?['id'])
            .where((id) => id != null)
            .toSet()
            .length;
        final totalDisc = items.fold<double>(
          0,
          (sum, i) => sum + ((i['discount_amount'] as num?)?.toDouble() ?? 0),
        );
        items.sort((a, b) =>
            (b['created_at'] ?? '').toString().compareTo((a['created_at'] ?? '').toString()));

        return <String, dynamic>{
          'code': code,
          'title': coupon?['title'],
          'times_used': items.length,
          'unique_users': uniqueUsers,
          'total_discount': totalDisc,
          'last_used_at': items.first['created_at'],
          'usage_limit': coupon?['usage_limit'],
          'is_active': coupon?['is_active'],
        };
      }).toList()
        ..sort((a, b) => (b['times_used'] as int).compareTo(a['times_used'] as int));

      final uniqueUsersCount = activeUsages
          .map((i) => (i['patient'] as Map?)?['id'])
          .where((id) => id != null)
          .toSet()
          .length;

      final totalDiscountAmount = activeUsages.fold<double>(
        0,
        (sum, i) => sum + ((i['discount_amount'] as num?)?.toDouble() ?? 0),
      );

      final totalCouponUsedCount = _coupons.fold<int>(
        0,
        (sum, c) => sum + (int.tryParse('${c['used_count'] ?? 0}') ?? 0),
      );

      setState(() {
        _history = discounted;
        _byCode = byCode;
        _summary = {
          'total_coupons': _coupons.length,
          'active_coupons': _coupons.where((c) => c['is_active'] == true || c['is_active'] == 1).length,
          'total_coupon_used_count': totalCouponUsedCount,
          'total_usages': activeUsages.length,
          'all_usages': discounted.length,
          'coupon_usages_count': activeUsages.where((i) => i['coupon_code'] != null).length,
          'unique_codes_used': byCode.length,
          'unique_users_count': uniqueUsersCount,
          'total_discount_amount': totalDiscountAmount,
        };
        _isHistoryLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _historyError = '$e';
          _isHistoryLoading = false;
        });
      }
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
    DateTime? expiresAt = coupon?['expires_at'] != null
        ? DateTime.tryParse(coupon['expires_at'].toString())?.toLocal()
        : null;

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
        const SizedBox(height: 12),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: expiresAt ?? now.add(const Duration(days: 30)),
              firstDate: DateTime(2024),
              lastDate: DateTime(2035),
            );
            if (picked != null) {
              setSheetState(() {
                expiresAt = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.getBorder(context)),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.calendar_1, size: 18, color: Color(0xFF6366F1)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    expiresAt != null
                        ? 'بەرواری بەسەرچوون: ${intl.DateFormat('yyyy/MM/dd').format(expiresAt!)}'
                        : 'بەرواری بەسەرچوون (ئارەزوومەندانە)',
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 13,
                      color: expiresAt != null
                          ? AppColors.getTextTitle(context)
                          : AppColors.getTextSubtitle(context),
                    ),
                  ),
                ),
                if (expiresAt != null)
                  GestureDetector(
                    onTap: () => setSheetState(() => expiresAt = null),
                    child: const Icon(Icons.close, size: 18, color: Color(0xFF94A3B8)),
                  ),
              ],
            ),
          ),
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
          'expires_at': expiresAt?.toIso8601String(),
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

  String _formatDate(dynamic raw, {bool includeTime = true}) {
    if (raw == null) return '-';
    final s = raw.toString().trim();
    if (s.isEmpty) return '-';
    final dt = DateTime.tryParse(s)?.toLocal();
    if (dt == null) return s;
    return includeTime
        ? intl.DateFormat('yyyy/MM/dd • HH:mm').format(dt)
        : intl.DateFormat('yyyy/MM/dd').format(dt);
  }

  ({String label, Color color}) _statusInfo(dynamic raw) {
    final s = (raw ?? '').toString().toLowerCase().trim();
    if (s == 'completed' || s == 'delivered' || s == 'done') {
      return (label: 'تەواوبوو', color: const Color(0xFF10B981));
    }
    if (s == 'processing' || s == 'accepted' || s == 'in_progress' || s == 'approved') {
      return (label: 'لە جێبەجێکردن', color: const Color(0xFF3B82F6));
    }
    if (s == 'cancelled' || s == 'rejected') {
      return (label: 'هەڵوەشاوەتەوە', color: const Color(0xFFEF4444));
    }
    if (s == 'pending' || s == 'new' || s.isEmpty) {
      return (label: 'نوێ', color: const Color(0xFFF59E0B));
    }
    return (label: s, color: const Color(0xFF64748B));
  }

  String _serviceLabel(dynamic raw) {
    final s = (raw ?? '').toString().toLowerCase();
    if (s.contains('pharmacy') || s.contains('medic') || s.contains('دەرمان')) {
      return 'دەرمانخانە';
    }
    if (s.contains('lab') || s.contains('تاقیگە')) {
      return 'تاقیگە';
    }
    if (s.contains('nurs') || s.contains('پەرستار')) {
      return 'پەرستاری';
    }
    return raw?.toString() ?? '-';
  }

  bool _matchesDateFilter(dynamic rawDate) {
    if (_datePreset == 'all') return true;
    if (rawDate == null) return false;
    final dt = DateTime.tryParse(rawDate.toString())?.toLocal();
    if (dt == null) return false;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    switch (_datePreset) {
      case 'today':
        return !dt.isBefore(todayStart);
      case '7d':
        return !dt.isBefore(todayStart.subtract(const Duration(days: 6)));
      case 'month':
        return dt.year == now.year && dt.month == now.month;
      case 'custom':
        if (_customDateRange == null) return true;
        final start = DateTime(
          _customDateRange!.start.year,
          _customDateRange!.start.month,
          _customDateRange!.start.day,
        );
        final end = DateTime(
          _customDateRange!.end.year,
          _customDateRange!.end.month,
          _customDateRange!.end.day,
          23,
          59,
          59,
        );
        return !dt.isBefore(start) && !dt.isAfter(end);
      default:
        return true;
    }
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
    );
    if (picked != null && mounted) {
      setState(() {
        _customDateRange = picked;
        _datePreset = 'custom';
      });
    }
  }

  Widget _dateChip(String key, String label, {VoidCallback? onTap}) {
    final selected = _datePreset == key;
    return GestureDetector(
      onTap: onTap ?? () => setState(() => _datePreset = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF6366F1) : AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF6366F1) : AppColors.getBorder(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Rabar',
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : AppColors.getTextSubtitle(context),
          ),
        ),
      ),
    );
  }

  void _openHistoryForCode(String code) {
    setState(() {
      _selectedCodeFilter = code.toUpperCase();
    });
    _tabController.animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    final totalUsedCount = (_summary['total_usages'] as num?)?.toInt() ??
        _history.where((h) {
          final st = (h['status'] ?? '').toString().toLowerCase();
          return st != 'cancelled' && st != 'rejected';
        }).length;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AdminAppBar(
        title: 'کۆدەکانی داشکاندن',
        subtitle: '${_coupons.length} کۆد تۆمارکراوە • $totalUsedCount بەکارهێنان',
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              height: 48,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.getBorder(context)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.getTextSubtitle(context),
                labelStyle: const TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: 'کۆدەکان (${_coupons.length})'),
                  Tab(text: 'هیستۆری و ڕاپۆرت (${_history.length})'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCouponsTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: AdminUi.subtitle, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _load,
                child: const Text('دووبارە هەوڵبدەرەوە', style: TextStyle(fontFamily: 'Rabar')),
              ),
            ],
          ),
        ),
      );
    }
    if (_coupons.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.22),
            Center(
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
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _coupons.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final c = _coupons[index];
          final isActive = c['is_active'] == true || c['is_active'] == 1;
          final isPercent = c['discount_type'] == 'percentage';
          final valStr = isPercent
              ? '${c['discount_value']}%'
              : Currency.format(num.tryParse('${c['discount_value']}') ?? 0);
          final codeStr = (c['code'] ?? '').toString();
          final createdStr = _formatDate(c['created_at'], includeTime: false);
          final expiresRaw = c['expires_at'];
          final expiresDt = expiresRaw != null ? DateTime.tryParse(expiresRaw.toString()) : null;
          final isExpired = expiresDt != null && expiresDt.isBefore(DateTime.now());

          return Container(
            decoration: AdminUi.cardDecoration,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: (isActive ? const Color(0xFF6366F1) : Colors.grey)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(13),
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
                              Flexible(
                                child: Text(
                                  codeStr,
                                  style: AdminUi.title.copyWith(fontSize: 15.5, letterSpacing: 1),
                                  overflow: TextOverflow.ellipsis,
                                ),
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
                            (c['title'] ?? '').toString().trim().isNotEmpty
                                ? c['title'].toString()
                                : 'کۆدی داشکاندنی گشتی',
                            style: AdminUi.subtitle,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isActive,
                      activeThumbColor: const Color(0xFF6366F1),
                      onChanged: (_) => _toggleStatus(c),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    AdminUi.chip(
                      'بەکارهێنراوە: ${c['used_count'] ?? 0}${c['usage_limit'] != null ? ' / ${c['usage_limit']}' : ''}',
                      const Color(0xFF0EA5E9),
                      small: true,
                    ),
                    AdminUi.chip(
                      'دروستکراوە: $createdStr',
                      const Color(0xFF64748B),
                      small: true,
                    ),
                    if (expiresRaw != null)
                      AdminUi.chip(
                        '${isExpired ? 'بەسەرچووە' : 'بەسەرچوون'}: ${_formatDate(expiresRaw, includeTime: false)}',
                        isExpired ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                        small: true,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _openHistoryForCode(codeStr),
                      icon: const Icon(Iconsax.clock, size: 16, color: Color(0xFF10B981)),
                      label: const Text(
                        'هیستۆری',
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _openAddEditDialog(coupon: c),
                      icon: const Icon(Iconsax.edit_2, size: 16, color: Color(0xFF6366F1)),
                      label: const Text(
                        'دەستکاری',
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _deleteCoupon(c),
                      icon: const Icon(Iconsax.trash, size: 16, color: Color(0xFFEF4444)),
                      label: const Text(
                        'سڕینەوە',
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 250.ms);
        },
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_isHistoryLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_historyError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Iconsax.warning_2, size: 42, color: Color(0xFFEF4444)),
              const SizedBox(height: 10),
              Text(_historyError!, style: AdminUi.subtitle, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _load,
                child: const Text('دووبارە هەوڵبدەرەوە', style: TextStyle(fontFamily: 'Rabar')),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _history.where((item) {
      if (!_matchesDateFilter(item['created_at'])) {
        return false;
      }

      if (_selectedCodeFilter != null) {
        final code = (item['coupon_code'] ?? '').toString().trim().toUpperCase();
        if (_selectedCodeFilter == '__NO_CODE__') {
          if (code.isNotEmpty) return false;
        } else if (code != _selectedCodeFilter) {
          return false;
        }
      }

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final code = (item['coupon_code'] ?? '').toString().toLowerCase();
        final title = (item['coupon_title'] ?? '').toString().toLowerCase();
        final patient = item['patient'] is Map ? item['patient'] as Map : const {};
        final pName = (patient['name'] ?? '').toString().toLowerCase();
        final pPhone = (patient['phone'] ?? '').toString().toLowerCase();
        final orderId = '#${item['order_id'] ?? ''}'.toLowerCase();

        if (!code.contains(q) &&
            !title.contains(q) &&
            !pName.contains(q) &&
            !pPhone.contains(q) &&
            !orderId.contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    final isFilteredView = _datePreset != 'all' || _selectedCodeFilter != null || _searchQuery.trim().isNotEmpty;
    final filteredActive = filtered.where((h) {
      final st = (h['status'] ?? '').toString().toLowerCase();
      return st != 'cancelled' && st != 'rejected';
    }).toList();

    final totalUsages = isFilteredView
        ? filteredActive.length
        : ((_summary['total_usages'] as num?)?.toInt() ?? 0);
    final couponUsagesCount = isFilteredView
        ? filteredActive.where((h) => (h['coupon_code'] ?? '').toString().trim().isNotEmpty).length
        : ((_summary['coupon_usages_count'] as num?)?.toInt() ?? 0);
    final uniqueCodesUsed = isFilteredView
        ? filteredActive
            .map((h) => (h['coupon_code'] ?? '').toString().trim().toUpperCase())
            .where((c) => c.isNotEmpty)
            .toSet()
            .length
        : ((_summary['unique_codes_used'] as num?)?.toInt() ?? _byCode.length);
    final totalCoupons = (_summary['total_coupons'] as num?)?.toInt() ?? _coupons.length;
    final uniqueUsers = isFilteredView
        ? filteredActive
            .map((h) => (h['patient'] as Map?)?['id'])
            .where((id) => id != null)
            .toSet()
            .length
        : ((_summary['unique_users_count'] as num?)?.toInt() ?? 0);
    final totalDiscount = isFilteredView
        ? filteredActive.fold<double>(
            0,
            (sum, h) => sum + ((h['discount_amount'] as num?)?.toDouble() ?? 0),
          )
        : ((_summary['total_discount_amount'] as num?)?.toDouble() ?? 0);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          // ── Summary Report Card ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Iconsax.chart_21, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'ڕاپۆرتی بەکارهێنانی کۆد و داشکاندن',
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _summaryStatBox(
                        label: 'کۆی بەکارهێنان',
                        value: '$totalUsages جار',
                        sub: '$couponUsagesCount بە کۆپۆن',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _summaryStatBox(
                        label: 'کۆدی بەکارهاتوو',
                        value: '$uniqueCodesUsed / $totalCoupons',
                        sub: '$uniqueUsers بەکارهێنەر',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'کۆی بڕی داشکاندنی دراو:',
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        Currency.format(totalDiscount),
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Per-Code Breakdown ──
          if (_byCode.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'ڕاپۆرت بەپێی هەر کۆدێک',
              style: AdminUi.title.copyWith(fontSize: 13.5),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 106,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _byCode.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, idx) {
                  if (idx == 0) {
                    final selected = _selectedCodeFilter == null;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCodeFilter = null),
                      child: Container(
                        width: 105,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF6366F1)
                              : AppColors.getSurface(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF6366F1)
                                : AppColors.getBorder(context),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.category,
                              size: 20,
                              color: selected ? Colors.white : const Color(0xFF6366F1),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'هەمووی',
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: selected
                                    ? Colors.white
                                    : AppColors.getTextTitle(context),
                              ),
                            ),
                            Text(
                              '${_history.length} تۆمار',
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 11,
                                color: selected
                                    ? Colors.white70
                                    : AppColors.getTextSubtitle(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final item = _byCode[idx - 1];
                  final code = (item['code'] ?? '').toString();
                  final selected = _selectedCodeFilter == code;
                  final timesUsed = (item['times_used'] as num?)?.toInt() ?? 0;
                  final usersCount = (item['unique_users'] as num?)?.toInt() ?? 0;
                  final discSum = (item['total_discount'] as num?)?.toDouble() ?? 0;
                  final lastUsed = _formatDate(item['last_used_at'], includeTime: false);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCodeFilter = selected ? null : code;
                      });
                    },
                    child: Container(
                      width: 178,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF6366F1)
                            : AppColors.getSurface(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF6366F1)
                              : AppColors.getBorder(context),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  code,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: selected
                                        ? Colors.white
                                        : const Color(0xFF6366F1),
                                  ),
                                ),
                              ),
                              Text(
                                '$timesUsed جار',
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '-${Currency.format(discSum)}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : AppColors.getTextTitle(context),
                            ),
                          ),
                          Text(
                            '$usersCount کەس • $lastUsed',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 10.5,
                              color: selected
                                  ? Colors.white70
                                  : AppColors.getTextSubtitle(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // ── Date Filter Chips ──
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _dateChip('all', 'هەموو کاتەکان'),
                const SizedBox(width: 8),
                _dateChip('today', 'ئەمڕۆ'),
                const SizedBox(width: 8),
                _dateChip('7d', '٧ ڕۆژی ڕابردوو'),
                const SizedBox(width: 8),
                _dateChip('month', 'ئەم مانگە'),
                const SizedBox(width: 8),
                _dateChip(
                  'custom',
                  _datePreset == 'custom' && _customDateRange != null
                      ? '${intl.DateFormat('MM/dd').format(_customDateRange!.start)} - ${intl.DateFormat('MM/dd').format(_customDateRange!.end)}'
                      : 'بەرواری دیاریکراو',
                  onTap: _pickCustomDateRange,
                ),
              ],
            ),
          ),

          // ── Search & Active Filter Indicator ──
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'گەڕان بەپێی کۆد، ناوی نەخۆش، مۆبایل، یان #داواکاری...',
              hintStyle: AdminUi.subtitle.copyWith(fontSize: 12),
              prefixIcon: const Icon(Iconsax.search_normal_1, size: 18),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                      icon: const Icon(Icons.close, size: 18),
                    )
                  : null,
              filled: true,
              fillColor: AppColors.getSurface(context),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.getBorder(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.getBorder(context)),
              ),
            ),
          ),

          if (_selectedCodeFilter != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                AdminUi.chip(
                  'فلتەری کۆد: $_selectedCodeFilter',
                  const Color(0xFF6366F1),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _selectedCodeFilter = null),
                  child: const Text(
                    'لابردنی فلتەر',
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'هیستۆری بەکارهێنان (${filtered.length})',
                style: AdminUi.title.copyWith(fontSize: 13.5),
              ),
              Text(
                'نوێترین لە سەرەوە',
                style: AdminUi.subtitle.copyWith(fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
              decoration: AdminUi.cardDecoration,
              child: Column(
                children: [
                  const Icon(Iconsax.receipt_disscount, size: 44, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 10),
                  Text(
                    _history.isEmpty
                        ? 'هێشتا هیچ کۆدێک یان داشکاندنێک بەکارنەهێنراوە'
                        : 'هیچ تۆمارێک بەپێی ئەم گەڕانە نەدۆزرایەوە',
                    style: AdminUi.subtitle,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...filtered.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildHistoryCard(item),
                )),
        ],
      ),
    );
  }

  Widget _summaryStatBox({
    required String label,
    required String value,
    required String sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Rabar',
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Rabar',
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(
              fontFamily: 'Rabar',
              fontSize: 10.5,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final code = (item['coupon_code'] ?? '').toString().trim();
    final title = (item['coupon_title'] ?? '').toString().trim();
    final orderId = item['order_id'];
    final discountAmt = (item['discount_amount'] as num?)?.toDouble() ?? 0;
    final subtotal = (item['subtotal'] as num?)?.toDouble() ?? 0;
    final totalPrice = (item['total_price'] as num?)?.toDouble() ?? 0;
    final statusInfo = _statusInfo(item['status']);
    final patient = item['patient'] is Map ? item['patient'] as Map : const {};
    final pName = (patient['name'] ?? 'نەخۆش').toString();
    final pPhone = (patient['phone'] ?? '').toString();
    final dateStr = _formatDate(item['created_at']);
    final service = _serviceLabel(item['service_type']);

    return Container(
      decoration: AdminUi.cardDecoration,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Code badge + Order ID + Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (code.isNotEmpty ? const Color(0xFF6366F1) : const Color(0xFFEC4899))
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Iconsax.ticket_discount,
                      size: 13,
                      color: code.isNotEmpty ? const Color(0xFF6366F1) : const Color(0xFFEC4899),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      code.isNotEmpty ? code : 'داشکاندنی ڕاستەوخۆ',
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: code.isNotEmpty ? const Color(0xFF6366F1) : const Color(0xFFEC4899),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '#$orderId',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextSubtitle(context),
                ),
              ),
              const Spacer(),
              AdminUi.chip(statusInfo.label, statusInfo.color, small: true),
            ],
          ),

          if (title.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(title, style: AdminUi.subtitle.copyWith(fontSize: 11.5)),
          ],

          const SizedBox(height: 10),

          // Patient & Date info
          Row(
            children: [
              const Icon(Iconsax.user, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  pPhone.isNotEmpty ? '$pName ($pPhone)' : pName,
                  style: AdminUi.title.copyWith(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AdminUi.chip(service, const Color(0xFF3B82F6), small: true),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Iconsax.calendar_1, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                dateStr,
                style: AdminUi.subtitle.copyWith(fontSize: 11.5),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Financials row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _priceColumn('نرخی سەرەتایی', Currency.format(subtotal), AppColors.getTextSubtitle(context)),
              _priceColumn('داشکاندن', '-${Currency.format(discountAmt)}', const Color(0xFFEC4899)),
              _priceColumn('کۆی گشتی', Currency.format(totalPrice), const Color(0xFF10B981)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 220.ms);
  }

  Widget _priceColumn(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AdminUi.subtitle.copyWith(fontSize: 10.5)),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
