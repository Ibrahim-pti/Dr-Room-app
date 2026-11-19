import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart' as intl;

import '../../core/theme/app_colors.dart';
import '../../core/utils/api_client.dart';
import 'admin_app_bar.dart';
import 'admin_ui.dart';
import 'services/statement_pdf_service.dart';

/// Complete financial accounting screen: incoming payments, provider payouts,
/// platform commission, expenses, net profit, and read-only transaction ledger.
class AdminTransactionsScreen extends StatefulWidget {
  const AdminTransactionsScreen({super.key});

  @override
  State<AdminTransactionsScreen> createState() =>
      _AdminTransactionsScreenState();
}

class _AdminTransactionsScreenState extends State<AdminTransactionsScreen> {
  static const _emerald = Color(0xFF059669);
  static const _indigo = Color(0xFF2563EB);
  static const _violet = Color(0xFF7C3AED);
  static const _amber = Color(0xFFD97706);
  static const _rose = Color(0xFFE11D48);

  bool _isLoading = true;
  String? _error;

  late String _currentMonth;
  late String _selectedMonth;
  String _methodFilter = 'all';
  String _searchQuery = '';
  int _visibleLimit = 30;

  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _allRecords = [];
  List<Map<String, dynamic>> _allExpenses = [];
  Map<int, Map<String, dynamic>> _ordersById = {};
  List<String> _availableMonths = [];
  List<int> _availableYears = [];
  List<String> _availableMethods = [];

  @override
  void initState() {
    super.initState();
    final nowBaghdad = _nowBaghdad();
    _currentMonth = _formatMonth(nowBaghdad);
    _selectedMonth = _currentMonth;
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  DateTime _nowBaghdad() =>
      DateTime.now().toUtc().add(const Duration(hours: 3));

  String _formatMonth(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}';

  DateTime? _parseBaghdadDate(dynamic raw) {
    if (raw == null) return null;
    final str = raw.toString().trim();
    if (str.isEmpty) return null;
    final parsed = DateTime.tryParse(str);
    if (parsed == null) return null;
    return parsed.isUtc
        ? parsed.add(const Duration(hours: 3))
        : parsed.toUtc().add(const Duration(hours: 3));
  }

  DateTime? _recordDate(Map<String, dynamic> tx) =>
      _parseBaghdadDate(tx['paid_at'] ?? tx['created_at']);

  String? _recordMonth(Map<String, dynamic> tx) {
    final dt = _recordDate(tx);
    return dt != null ? _formatMonth(dt) : null;
  }

  String? _expenseMonth(Map<String, dynamic> e) {
    final raw = (e['expense_date'] ?? e['created_at'])?.toString().trim();
    if (raw == null || raw.isEmpty) return null;
    if (RegExp(r'^\d{4}-\d{2}').hasMatch(raw)) {
      return raw.substring(0, 7);
    }
    final dt = _parseBaghdadDate(raw);
    return dt != null ? _formatMonth(dt) : null;
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _fetchAllTransactions(),
        ApiClient.get('/admin/orders')
            .then<dynamic>((r) => r)
            .catchError((_) => null),
        _fetchAllExpenses(),
      ]);

      if (!mounted) return;

      final List<Map<String, dynamic>> rawTxs =
          results[0] as List<Map<String, dynamic>>;
      final dynamic ordersRes = results[1];
      final List<Map<String, dynamic>> expenses =
          results[2] as List<Map<String, dynamic>>;

      final Map<int, Map<String, dynamic>> ordersById = {};
      if (ordersRes != null && ordersRes.statusCode == 200) {
        try {
          final decodedOrders = jsonDecode(ordersRes.body);
          final List<dynamic> ordersList = decodedOrders is Map
              ? (decodedOrders['orders'] ?? decodedOrders['data'] ?? [])
              : (decodedOrders is List ? decodedOrders : []);
          for (final o in ordersList) {
            if (o is! Map) continue;
            final id = int.tryParse('${o['id']}');
            if (id != null) {
              ordersById[id] = Map<String, dynamic>.from(o);
            }
          }
        } catch (_) {}
      }

      // Track which orders already have a Transaction row so we don't double-count,
      // and include any orphan orders that lack a Transaction row so nothing is missed.
      final Set<int> seenOrderIds = {};
      final List<Map<String, dynamic>> unified = [];

      for (final tx in rawTxs) {
        final payableType = (tx['payable_type'] ?? '').toString();
        final payableId = int.tryParse('${tx['payable_id']}');
        if (payableId != null &&
            (payableType.isEmpty || payableType.contains('Order'))) {
          seenOrderIds.add(payableId);
        }
        unified.add(tx);
      }

      for (final entry in ordersById.entries) {
        if (seenOrderIds.contains(entry.key)) continue;
        final o = entry.value;
        final orderStatus = (o['status'] ?? 'pending').toString().toLowerCase();
        final paymentStatus =
            (o['payment_status'] ?? '').toString().toLowerCase();
        final String mappedStatus;
        if (orderStatus == 'completed' || paymentStatus == 'paid') {
          mappedStatus = 'completed';
        } else if (paymentStatus == 'refunded') {
          mappedStatus = 'refunded';
        } else if (orderStatus == 'cancelled' || orderStatus == 'rejected') {
          mappedStatus = 'failed';
        } else {
          mappedStatus = 'pending';
        }

        final method =
            (o['payment_method'] ?? 'cash').toString().toLowerCase().trim();
        final orderNo =
            (o['order_number'] ?? '#${o['id']}').toString();
        unified.add({
          'id': 'ord_${o['id']}',
          'reference': orderNo,
          'description': '${_serviceLabel(_classifyOrderService(o))} $orderNo',
          'amount': o['total_price'] ?? 0,
          'status': mappedStatus,
          'method': method.isEmpty ? 'cash' : method,
          'payable_type': 'Order',
          'payable_id': o['id'],
          'user_id': o['patient_id'],
          'user': o['patient'],
          'coupon_code': o['coupon_code'],
          'discount_amount': o['discount_amount'] ?? 0,
          'created_at': o['created_at'],
          'paid_at': mappedStatus == 'completed'
              ? (o['updated_at'] ?? o['created_at'])
              : null,
        });
      }

      // Sort newest first
      unified.sort((a, b) {
        final da = _recordDate(a);
        final db = _recordDate(b);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });

      final nowBaghdad = _nowBaghdad();
      final currentMonth = _formatMonth(nowBaghdad);
      final Set<String> monthSet = {currentMonth};
      final Set<int> yearSet = {nowBaghdad.year};
      final Set<String> methodSet = {};

      for (final rec in unified) {
        final dt = _recordDate(rec);
        if (dt != null) {
          monthSet.add(_formatMonth(dt));
          yearSet.add(dt.year);
        }
        final m = (rec['method'] ?? '').toString().toLowerCase().trim();
        if (m.isNotEmpty) methodSet.add(m);
      }

      for (final e in expenses) {
        final em = _expenseMonth(e);
        if (em != null) {
          monthSet.add(em);
          final yr = int.tryParse(em.split('-').first);
          if (yr != null) yearSet.add(yr);
        }
      }

      final months = monthSet.toList()..sort((a, b) => b.compareTo(a));
      final years = yearSet.toList()..sort((a, b) => b.compareTo(a));
      final methods = methodSet.toList()..sort();

      setState(() {
        _currentMonth = currentMonth;
        if (_selectedMonth != 'all' && !months.contains(_selectedMonth)) {
          _selectedMonth = currentMonth;
        }
        _allRecords = unified;
        _allExpenses = expenses;
        _ordersById = ordersById;
        _availableMonths = months;
        _availableYears = years;
        _availableMethods = methods;
        if (_methodFilter != 'all' && !methods.contains(_methodFilter)) {
          _methodFilter = 'all';
        }
        _visibleLimit = 30;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _isLoading = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAllTransactions() async {
    final firstRes =
        await ApiClient.get('/admin/transactions?per_page=200&page=1');
    if (firstRes.statusCode != 200) {
      throw Exception(AdminUi.readError(firstRes));
    }

    final decoded = jsonDecode(firstRes.body);
    final List<Map<String, dynamic>> all = [];

    if (decoded is Map) {
      final list = decoded['data'];
      if (list is List) {
        all.addAll(
          list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
        );
      }
      final int lastPage =
          (int.tryParse('${decoded['last_page'] ?? 1}') ?? 1).clamp(1, 25);
      if (lastPage > 1) {
        final more = await Future.wait(
          List.generate(
            lastPage - 1,
            (i) => ApiClient.get(
              '/admin/transactions?per_page=200&page=${i + 2}',
            ).then<dynamic>((r) => r).catchError((_) => null),
          ),
        );
        for (final res in more) {
          if (res != null && res.statusCode == 200) {
            final pageBody = jsonDecode(res.body);
            if (pageBody is Map && pageBody['data'] is List) {
              all.addAll(
                (pageBody['data'] as List)
                    .whereType<Map>()
                    .map((e) => Map<String, dynamic>.from(e)),
              );
            }
          }
        }
      }
    } else if (decoded is List) {
      all.addAll(
        decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
      );
    }

    return all;
  }

  Future<List<Map<String, dynamic>>> _fetchAllExpenses() async {
    final List<Map<String, dynamic>> all = [];
    try {
      final firstRes = await ApiClient.get('/admin/expenses?page=1');
      if (firstRes.statusCode != 200) return all;
      final decoded = jsonDecode(firstRes.body);
      final data = decoded is Map ? decoded['data'] : null;
      if (data is Map) {
        if (data['data'] is List) {
          all.addAll(
            (data['data'] as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e)),
          );
        }
        final lastPage =
            (int.tryParse('${data['last_page'] ?? 1}') ?? 1).clamp(1, 15);
        if (lastPage > 1) {
          final more = await Future.wait(
            List.generate(
              lastPage - 1,
              (idx) => ApiClient.get('/admin/expenses?page=${idx + 2}')
                  .then<dynamic>((r) => r)
                  .catchError((_) => null),
            ),
          );
          for (final res in more) {
            if (res != null && res.statusCode == 200) {
              final d = jsonDecode(res.body);
              if (d is Map && d['data'] is Map && d['data']['data'] is List) {
                all.addAll(
                  (d['data']['data'] as List)
                      .whereType<Map>()
                      .map((e) => Map<String, dynamic>.from(e)),
                );
              }
            }
          }
        }
      } else if (data is List) {
        all.addAll(
          data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
        );
      }
    } catch (_) {}
    return all;
  }

  Map<String, dynamic>? _matchedOrder(Map<String, dynamic> tx) {
    final payableType = (tx['payable_type'] ?? '').toString();
    final payableId = int.tryParse('${tx['payable_id']}');
    if (payableId == null) return null;
    if (payableType.isNotEmpty && !payableType.contains('Order')) return null;
    return _ordersById[payableId];
  }

  String _classifyOrderService(Map<String, dynamic>? order) {
    if (order == null) return 'other';
    final st = (order['service_type'] ?? '').toString().toLowerCase().trim();
    if (st.contains('lab') ||
        st.contains('تاقیگە') ||
        order['assigned_lab_id'] != null) {
      return 'lab';
    }
    if (st.contains('nurs') ||
        st.contains('پەرستار') ||
        order['assigned_nurse_id'] != null) {
      return 'nursing';
    }
    if (st.contains('pharmac') ||
        st.contains('medic') ||
        st.contains('دەرمان') ||
        order['assigned_pharmacy_id'] != null) {
      return 'pharmacy';
    }
    return 'other';
  }

  String _serviceLabel(String key) {
    return switch (key) {
      'lab' => 'تاقیگە',
      'nursing' => 'ناوەندی تەندروستی',
      'pharmacy' => 'دەرمانخانە',
      _ => 'خزمەتگوزاری تر',
    };
  }

  String _patientName(Map<String, dynamic> tx, Map<String, dynamic>? order) {
    final orderPatient = order?['patient'] is Map
        ? (order!['patient']['name'] ?? '').toString().trim()
        : '';
    if (orderPatient.isNotEmpty) return orderPatient;
    final txUser = tx['user'] is Map
        ? (tx['user']['name'] ?? '').toString().trim()
        : '';
    return txUser.isNotEmpty ? txUser : 'نەناسراو';
  }

  String _providerName(Map<String, dynamic>? order) {
    if (order == null) return '';
    for (final key in const [
      'assigned_lab',
      'assigned_nurse',
      'assigned_pharmacy',
      'assigned_driver',
    ]) {
      final p = order[key];
      if (p is Map) {
        final name = (p['name'] ?? '').toString().trim();
        if (name.isNotEmpty) return name;
      }
    }
    return '';
  }

  ({String couponCode, double discountAmount, bool hasDiscount}) _extractDiscount(
    Map<String, dynamic> tx,
    Map<String, dynamic>? order,
  ) {
    String couponCode = (tx['coupon_code'] ?? '').toString().trim();
    double discountAmount = _toDouble(tx['discount_amount']);

    if (couponCode.isEmpty && discountAmount <= 0 && tx['payable'] is Map) {
      final p = tx['payable'] as Map;
      couponCode = (p['coupon_code'] ?? '').toString().trim();
      discountAmount = _toDouble(p['discount_amount']);
    }

    if (couponCode.isEmpty && discountAmount <= 0 && order != null) {
      couponCode = (order['coupon_code'] ?? '').toString().trim();
      discountAmount = _toDouble(order['discount_amount']);
    }

    return (
      couponCode: couponCode,
      discountAmount: discountAmount,
      hasDiscount: discountAmount > 0 || couponCode.isNotEmpty,
    );
  }

  double _orderCommission(
    Map<String, dynamic> tx,
    Map<String, dynamic>? order,
  ) {
    if (order == null) return 0.0;
    final commAmt = _toDouble(order['commission_amount']);
    if (commAmt > 0) return commAmt;
    final rate = _toDouble(order['commission_rate']);
    if (rate > 0) {
      final base = _toDouble(order['total_price']) > 0
          ? _toDouble(order['total_price'])
          : _toDouble(tx['amount']);
      return (base * rate) / 100.0;
    }
    return 0.0;
  }

  double _orderProviderNet(
    Map<String, dynamic> tx,
    Map<String, dynamic>? order,
    double commission,
  ) {
    if (order != null) {
      final stored = _toDouble(order['provider_net_amount']);
      if (stored > 0) return stored;
    }
    final amount = _toDouble(tx['amount']);
    return (amount - commission).clamp(0.0, double.infinity);
  }

  _AccountingMetrics _computeMetrics({
    required List<Map<String, dynamic>> periodRecords,
  }) {
    final nowBaghdad = _nowBaghdad();
    final todayKey =
        '${nowBaghdad.year.toString().padLeft(4, '0')}-${nowBaghdad.month.toString().padLeft(2, '0')}-${nowBaghdad.day.toString().padLeft(2, '0')}';

    double allTimeCompletedRevenue = 0;
    int allTimeCompletedCount = 0;
    for (final rec in _allRecords) {
      if ((rec['status'] ?? '').toString().toLowerCase() == 'completed') {
        allTimeCompletedRevenue += _toDouble(rec['amount']);
        allTimeCompletedCount++;
      }
    }

    double completedRevenue = 0;
    double todayCompletedRevenue = 0;
    double cashRevenue = 0;
    double onlineRevenue = 0;
    double pendingAmount = 0;
    double failedAmount = 0;
    double refundedAmount = 0;
    double completedCommission = 0;
    double completedProviderNet = 0;
    double completedDeliveryFees = 0;
    double discountTotal = 0;

    int completedCount = 0;
    int pendingCount = 0;
    int failedCount = 0;
    int refundedCount = 0;
    int cashCount = 0;
    int onlineCount = 0;
    int discountedCount = 0;
    final Set<dynamic> discountedUserIds = {};

    final Map<String, ({int count, double amount})> methodTotals = {};
    final Map<String, ({int count, double revenue, double commission})>
        sectorTotals = {};

    for (final tx in periodRecords) {
      final status = (tx['status'] ?? 'pending').toString().toLowerCase();
      final method = (tx['method'] ?? 'cash').toString().toLowerCase();
      final amount = _toDouble(tx['amount']);
      final order = _matchedOrder(tx);
      final disc = _extractDiscount(tx, order);

      if (status != 'failed' && status != 'refunded' && disc.hasDiscount) {
        discountedCount++;
        discountTotal += disc.discountAmount;
        final uid = tx['user_id'] ??
            (tx['user'] is Map ? tx['user']['id'] : null) ??
            order?['patient_id'];
        if (uid != null) discountedUserIds.add(uid);
      }

      switch (status) {
        case 'completed':
          completedCount++;
          completedRevenue += amount;

          final dt = _recordDate(tx);
          if (dt != null) {
            final dKey =
                '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
            if (dKey == todayKey) {
              todayCompletedRevenue += amount;
            }
          }

          if (method == 'cash') {
            cashRevenue += amount;
            cashCount++;
          } else {
            onlineRevenue += amount;
            onlineCount++;
          }

          final prevM = methodTotals[method];
          methodTotals[method] = (
            count: (prevM?.count ?? 0) + 1,
            amount: (prevM?.amount ?? 0.0) + amount,
          );

          final comm = _orderCommission(tx, order);
          final pNet = _orderProviderNet(tx, order, comm);
          final dFee = order != null ? _toDouble(order['delivery_fee']) : 0.0;

          completedCommission += comm;
          completedProviderNet += pNet;
          completedDeliveryFees += dFee;

          final sector = _classifyOrderService(order);
          final prevS = sectorTotals[sector];
          sectorTotals[sector] = (
            count: (prevS?.count ?? 0) + 1,
            revenue: (prevS?.revenue ?? 0.0) + amount,
            commission: (prevS?.commission ?? 0.0) + comm,
          );
          break;

        case 'pending':
          pendingCount++;
          pendingAmount += amount;
          break;

        case 'refunded':
          refundedCount++;
          refundedAmount += amount;
          break;

        default:
          failedCount++;
          failedAmount += amount;
          break;
      }
    }

    final periodExpenses = _selectedMonth == 'all'
        ? _allExpenses
        : _allExpenses.where((e) => _expenseMonth(e) == _selectedMonth).toList();
    final double expensesTotal =
        periodExpenses.fold<double>(0.0, (s, e) => s + _toDouble(e['amount']));
    final double netPlatformProfit = completedCommission - expensesTotal;

    final totalCount = periodRecords.length;
    final successRate = totalCount > 0
        ? double.parse(((completedCount / totalCount) * 100).toStringAsFixed(1))
        : 0.0;
    final avgCompletedAmount =
        completedCount > 0 ? completedRevenue / completedCount : 0.0;

    return _AccountingMetrics(
      totalCount: totalCount,
      completedCount: completedCount,
      pendingCount: pendingCount,
      failedCount: failedCount,
      refundedCount: refundedCount,
      cashCount: cashCount,
      onlineCount: onlineCount,
      completedRevenue: completedRevenue,
      todayCompletedRevenue: todayCompletedRevenue,
      allTimeCompletedRevenue: allTimeCompletedRevenue,
      allTimeCompletedCount: allTimeCompletedCount,
      avgCompletedAmount: avgCompletedAmount,
      successRate: successRate,
      completedCommission: completedCommission,
      completedProviderNet: completedProviderNet,
      completedDeliveryFees: completedDeliveryFees,
      expensesTotal: expensesTotal,
      expensesCount: periodExpenses.length,
      netPlatformProfit: netPlatformProfit,
      cashRevenue: cashRevenue,
      onlineRevenue: onlineRevenue,
      pendingAmount: pendingAmount,
      failedAmount: failedAmount,
      refundedAmount: refundedAmount,
      discountTotal: discountTotal,
      discountedCount: discountedCount,
      discountedUsersCount: discountedUserIds.length,
      methodTotals: methodTotals,
      sectorTotals: sectorTotals,
    );
  }

  List<Map<String, dynamic>> _periodScopedRecords() {
    return _allRecords.where((tx) {
      if (_selectedMonth != 'all' && _recordMonth(tx) != _selectedMonth) {
        return false;
      }
      if (_methodFilter != 'all') {
        final m = (tx['method'] ?? '').toString().toLowerCase().trim();
        if (m != _methodFilter) return false;
      }
      return true;
    }).toList();
  }

  List<Map<String, dynamic>> _ledgerRecords(
    List<Map<String, dynamic>> periodList,
  ) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return periodList;
    return periodList.where((tx) {
      final order = _matchedOrder(tx);
      final disc = _extractDiscount(tx, order);
      final desc = (tx['description'] ?? '').toString().toLowerCase();
      final ref = (tx['reference'] ?? '').toString().toLowerCase();
      final patient = _patientName(tx, order).toLowerCase();
      final provider = _providerName(order).toLowerCase();
      final coupon = disc.couponCode.toLowerCase();
      final orderNo = (order?['order_number'] ?? '').toString().toLowerCase();
      return desc.contains(q) ||
          ref.contains(q) ||
          patient.contains(q) ||
          provider.contains(q) ||
          coupon.contains(q) ||
          orderNo.contains(q);
    }).toList();
  }

  /// Read-only financial breakdown modal when tapping any ledger entry.
  void _showTransactionDetails(Map<String, dynamic> tx) {
    final order = _matchedOrder(tx);
    final status = (tx['status'] ?? 'pending').toString().toLowerCase();
    final method = (tx['method'] ?? 'cash').toString().toLowerCase();
    final amount = _toDouble(tx['amount']);
    final disc = _extractDiscount(tx, order);
    final comm = _orderCommission(tx, order);
    final pNet = _orderProviderNet(tx, order, comm);
    final dFee = order != null ? _toDouble(order['delivery_fee']) : 0.0;
    final subtotal = order != null ? _toDouble(order['subtotal']) : 0.0;
    final extraFee = order != null ? _toDouble(order['extra_fee']) : 0.0;
    final patientName = _patientName(tx, order);
    final providerName = _providerName(order);
    final dt = _recordDate(tx);
    final dateStr = dt != null
        ? '${intl.DateFormat('yyyy-MM-dd').format(dt)}  •  ${intl.DateFormat('hh:mm a').format(dt)}'
        : '';

    final sColor = switch (status) {
      'completed' => _emerald,
      'pending' => _amber,
      'refunded' => _violet,
      _ => _rose,
    };
    final sLabel = switch (status) {
      'completed' => 'هاتوو / سەرکەوتوو',
      'pending' => 'چاوەڕوان',
      'refunded' => 'گەڕێندراوە',
      _ => 'شکستخواردوو',
    };

    final items = (order != null && order['items'] is List)
        ? (order['items'] as List).whereType<Map>().toList()
        : const <Map>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF475569)
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: sColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Iconsax.receipt_2, color: sColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (tx['description'] ?? tx['reference'] ?? '')
                                .toString(),
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.getTextTitle(ctx),
                            ),
                          ),
                          if (dateStr.isNotEmpty)
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 11,
                                color: AppColors.getTextSubtitle(ctx),
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
                        color: sColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        sLabel,
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: sColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.getBackground(ctx),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.getBorder(ctx)),
                  ),
                  child: Column(
                    children: [
                      _detailRow(ctx, 'کۆدی مامەڵە',
                          (tx['reference'] ?? '-').toString()),
                      _detailRow(ctx, 'نەخۆش / بەکارهێنەر', patientName),
                      if (providerName.isNotEmpty)
                        _detailRow(ctx, 'دابینکار', providerName),
                      _detailRow(ctx, 'ڕێگای پارەدان', _methodLabel(method)),
                      if (subtotal > 0)
                        _detailRow(ctx, 'نرخی خزمەتگوزاری', _formatIqd(subtotal)),
                      if (extraFee > 0)
                        _detailRow(ctx, 'کرێی سەردان / زیادە', _formatIqd(extraFee)),
                      if (disc.hasDiscount)
                        _detailRow(
                          ctx,
                          disc.couponCode.isNotEmpty
                              ? 'داشکاندن (${disc.couponCode})'
                              : 'داشکاندن',
                          '- ${_formatIqd(disc.discountAmount)}',
                          valueColor: _rose,
                        ),
                      if (dFee > 0)
                        _detailRow(ctx, 'کرێی گەیاندن (شۆفێر)', _formatIqd(dFee)),
                      const Divider(height: 16),
                      _detailRow(
                        ctx,
                        'کۆی گشتی پارەدان',
                        _formatIqd(amount),
                        isBold: true,
                        valueColor: sColor,
                      ),
                      if (order != null) ...[
                        const SizedBox(height: 4),
                        _detailRow(
                          ctx,
                          'پشکی دابینکار',
                          _formatIqd(pNet),
                          valueColor: _indigo,
                        ),
                        _detailRow(
                          ctx,
                          'کۆمیسیۆنی سەکۆ',
                          _formatIqd(comm),
                          valueColor: _violet,
                        ),
                      ],
                    ],
                  ),
                ),
                if (items.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'ناوەڕۆکی خزمەتگوزارییەکان',
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextTitle(ctx),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.getBackground(ctx),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.getBorder(ctx)),
                    ),
                    child: Column(
                      children: items.map((item) {
                        final name =
                            (item['item_name'] ?? 'خزمەتگوزاری').toString();
                        final qty = int.tryParse('${item['quantity'] ?? 1}') ?? 1;
                        final price = _toDouble(item['price']) * qty;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  qty > 1 ? '$name (×$qty)' : name,
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 11.5,
                                    color: AppColors.getTextTitle(ctx),
                                  ),
                                ),
                              ),
                              Text(
                                _formatIqd(price),
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.getTextSubtitle(ctx),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(
    BuildContext ctx,
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: isBold ? 12.5 : 11.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: AppColors.getTextSubtitle(ctx),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontFamily: 'Rabar',
                fontSize: isBold ? 13.5 : 12,
                fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
                color: valueColor ?? AppColors.getTextTitle(ctx),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _methodLabel(String method) {
    return switch (method.toLowerCase()) {
      'cash' => 'کاش',
      'fib' => 'FIB',
      'fastpay' => 'FastPay',
      'zaincash' => 'ZainCash',
      'qi_card' => 'Qi Card',
      'card' => 'کارت',
      'wallet' => 'جزدان',
      _ => method.toUpperCase(),
    };
  }

  String _formatIqd(dynamic val) {
    final d = _toDouble(val);
    return '${intl.NumberFormat('#,###').format(d.round())} د.ع';
  }

  String _formatNum(dynamic val) {
    final n = num.tryParse(val?.toString() ?? '0') ?? 0;
    return intl.NumberFormat('#,###').format(n);
  }

  String _formatCompact(dynamic val) {
    final d = _toDouble(val);
    if (d >= 1000000) return '${(d / 1000000).toStringAsFixed(1)}M';
    if (d >= 1000) return '${(d / 1000).toStringAsFixed(0)}K';
    return d.toStringAsFixed(0);
  }

  double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final periodRecords = _periodScopedRecords();
    final metrics = _computeMetrics(periodRecords: periodRecords);
    final ledgerItems = _ledgerRecords(periodRecords);

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AdminAppBar(
        title: 'مامەڵە و داهات',
        subtitle: 'حیساباتی گشتی، پارەدان و داهاتی هاتوو',
        icon: Iconsax.wallet_3,
        iconColor: _emerald,
        iconBackgroundColor: _emerald.withValues(alpha: 0.12),
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _emerald))
          : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: _emerald,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeaderFilterCard(),
                        const SizedBox(height: 16),
                        _buildPrimaryKpisGrid(metrics),
                        const SizedBox(height: 12),
                        _buildFinancialStrip(metrics),
                        const SizedBox(height: 16),
                        _buildAccountingBreakdownCard(metrics),
                        const SizedBox(height: 16),
                        _buildTransactionsLedgerCard(ledgerItems),
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
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text(
                'دووبارە هەوڵبدەرەوە',
                style: TextStyle(fontFamily: 'Rabar'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _emerald,
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

  // ── 1. Header & Period / Status / Method Filters + PDF Statement ──
  Widget _buildHeaderFilterCard() {
    final periodLabel =
        _selectedMonth == 'all' ? 'هەموو مانگەکان' : _selectedMonth;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.getBorder(context)),
        boxShadow: [
          BoxShadow(
            color: _emerald.withValues(alpha: 0.05),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _emerald.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.calendar_1, size: 13, color: _emerald),
                    const SizedBox(width: 5),
                    const Text(
                      'حیسابات و پارەدان • ',
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _emerald,
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
                          color: _emerald,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (_selectedMonth != _currentMonth)
                TextButton(
                  onPressed: () => setState(() {
                    _selectedMonth = _currentMonth;
                    _visibleLimit = 30;
                  }),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'ئەم مانگە',
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: _emerald,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

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
                  color: _emerald,
                  onTap: () => setState(() {
                    _selectedMonth = 'all';
                    _visibleLimit = 30;
                  }),
                ),
                ..._availableMonths.map((m) {
                  final isCurrent = m == _currentMonth;
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(start: 6),
                    child: _buildFilterPill(
                      label: isCurrent ? '$m (ئێستا)' : m,
                      selected: _selectedMonth == m,
                      color: _emerald,
                      ltrText: true,
                      onTap: () => setState(() {
                        _selectedMonth = m;
                        _visibleLimit = 30;
                      }),
                    ),
                  );
                }),
              ],
            ),
          ),

          if (_availableMethods.length > 1) ...[
            const SizedBox(height: 12),
            const Text(
              'ڕێگای پارەدان',
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
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: _buildFilterPill(
                      label: 'هەمووی',
                      selected: _methodFilter == 'all',
                      color: _violet,
                      onTap: () => setState(() {
                        _methodFilter = 'all';
                        _visibleLimit = 30;
                      }),
                    ),
                  ),
                  ..._availableMethods.map((m) {
                    return Padding(
                      padding: const EdgeInsetsDirectional.only(end: 6),
                      child: _buildFilterPill(
                        label: _methodLabel(m),
                        icon:
                            m == 'cash' ? Iconsax.money_send : Iconsax.card_pos,
                        selected: _methodFilter == m,
                        color: _violet,
                        onTap: () => setState(() {
                          _methodFilter = m;
                          _visibleLimit = 30;
                        }),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openExportReportModal(preferShare: false),
                  icon: const Icon(Iconsax.document_download, size: 17),
                  label: const Text(
                    'پسوڵەی حیساباتی دابینکاران (PDF)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _emerald,
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
                onPressed: () => _openExportReportModal(preferShare: true),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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

  // ── 2. Primary 4 KPI Cards (2x2 Grid) ──
  Widget _buildPrimaryKpisGrid(_AccountingMetrics m) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                label: 'پارەی هاتوو (سەرکەوتوو)',
                value: _formatIqd(m.completedRevenue),
                icon: Iconsax.wallet_3,
                color: _emerald,
                footerLeft: 'ئەمڕۆ: ${_formatCompact(m.todayCompletedRevenue)}',
                footerRight:
                    'هەموو کات: ${_formatCompact(m.allTimeCompletedRevenue)}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildKpiCard(
                label: 'پارەدانەکان (تەواوکراو)',
                value:
                    '${_formatNum(m.completedCount)} / ${_formatNum(m.totalCount)}',
                icon: Iconsax.tick_circle,
                color: _indigo,
                footerLeft: 'چاوەڕوان: ${_formatNum(m.pendingCount)}',
                footerRight: 'سەرکەوتن: ${m.successRate}%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                label: 'پشکی سەکۆ (کۆمیسیۆن)',
                value: _formatIqd(m.completedCommission),
                icon: Iconsax.percentage_square,
                color: _violet,
                footerLeft:
                    'پوختی دابینکار: ${_formatCompact(m.completedProviderNet)}',
                footerRight:
                    'قازانجی سافی: ${_formatCompact(m.netPlatformProfit)}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildKpiCard(
                label: 'داشکاندن و کۆپۆن',
                value: _formatIqd(m.discountTotal),
                icon: Iconsax.ticket_discount,
                color: _rose,
                footerLeft: '${_formatNum(m.discountedCount)} داواکاری',
                footerRight: '${_formatNum(m.discountedUsersCount)} بەکارهێنەر',
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
          Container(
            height: 1,
            color: AppColors.getBorder(context).withValues(alpha: 0.6),
          ),
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

  // ── 3. Financial & Status Breakdown Strip ──
  Widget _buildFinancialStrip(_AccountingMetrics m) {
    final cards = [
      (
        label: 'پارەی هاتوو (کاش)',
        value: _formatIqd(m.cashRevenue),
        tag: '${m.cashCount} مامەڵە',
        color: _emerald,
      ),
      (
        label: 'پارەی هاتوو (ئۆنلاین)',
        value: _formatIqd(m.onlineRevenue),
        tag: '${m.onlineCount} مامەڵە',
        color: _indigo,
      ),
      (
        label: 'پارەی چاوەڕوانکراو',
        value: _formatIqd(m.pendingAmount),
        tag: '${m.pendingCount} چاوەڕوان',
        color: _amber,
      ),
      (
        label: 'خەرجییەکانی ماوەکە',
        value: _formatIqd(m.expensesTotal),
        tag: '${m.expensesCount} خەرجی',
        color: _rose,
      ),
      (
        label: 'شکستخواردوو',
        value: _formatIqd(m.failedAmount),
        tag: '${m.failedCount} مامەڵە',
        color: _rose,
      ),
      (
        label: 'گەڕێندراوە',
        value: _formatIqd(m.refundedAmount),
        tag: '${m.refundedCount} مامەڵە',
        color: _violet,
      ),
      (
        label: 'هەموو کات (سەرکەوتوو)',
        value: _formatIqd(m.allTimeCompletedRevenue),
        tag: '${m.allTimeCompletedCount} مامەڵە',
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

  // ── 4. Complete System Accounting & Payment Reconciliation Card ──
  Widget _buildAccountingBreakdownCard(_AccountingMetrics m) {
    final methodEntries = m.methodTotals.entries.toList()
      ..sort((a, b) => b.value.amount.compareTo(a.value.amount));
    final sectorEntries = m.sectorTotals.entries.toList()
      ..sort((a, b) => b.value.revenue.compareTo(a.value.revenue));

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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _emerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Iconsax.calculator,
                  color: _emerald,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'حیساباتی تەواوی سیستەم و دابەشبوون',
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextTitle(context),
                      ),
                    ),
                    Text(
                      'کۆی پارەی هاتوو، پشکی دابینکاران، خەرجی و قازانجی پوخت',
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 10.5,
                        color: AppColors.getTextSubtitle(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Reconciliation rows
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.getBackground(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.getBorder(context)),
            ),
            child: Column(
              children: [
                _ledgerMathRow(
                  'کۆی پارەی هاتوو (سەرکەوتوو)',
                  _formatIqd(m.completedRevenue),
                  valueColor: _emerald,
                  isBold: true,
                ),
                _ledgerMathRow(
                  'پشکی دابینکاران (تاقیگە / ناوەند / دەرمانخانە)',
                  _formatIqd(m.completedProviderNet),
                  valueColor: _indigo,
                ),
                if (m.completedDeliveryFees > 0)
                  _ledgerMathRow(
                    'کرێی گەیاندنی شۆفێرەکان',
                    _formatIqd(m.completedDeliveryFees),
                    valueColor: _amber,
                  ),
                _ledgerMathRow(
                  'کۆمیسیۆنی سەکۆ (پێش خەرجی)',
                  _formatIqd(m.completedCommission),
                  valueColor: _violet,
                ),
                _ledgerMathRow(
                  'خەرجییەکانی ماوەکە (${m.expensesCount})',
                  '- ${_formatIqd(m.expensesTotal)}',
                  valueColor: _rose,
                ),
                const Divider(height: 14),
                _ledgerMathRow(
                  'قازانجی پوختی سەکۆ (سافی)',
                  _formatIqd(m.netPlatformProfit),
                  valueColor: m.netPlatformProfit >= 0 ? _emerald : _rose,
                  isBold: true,
                ),
              ],
            ),
          ),

          if (methodEntries.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'پارە هاتووەکان بەپێی ڕێگای پارەدان',
              style: TextStyle(
                fontFamily: 'Rabar',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextTitle(context),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: methodEntries.map((entry) {
                final isCash = entry.key == 'cash';
                final color = isCash ? const Color(0xFF0D9488) : _indigo;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    '${_methodLabel(entry.key)} (${entry.value.count}): ${_formatIqd(entry.value.amount)}',
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          if (sectorEntries.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'داهات و کۆمیسیۆن بەپێی کەرتەکان',
              style: TextStyle(
                fontFamily: 'Rabar',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextTitle(context),
              ),
            ),
            const SizedBox(height: 8),
            ...sectorEntries.map((entry) {
              final label = _serviceLabel(entry.key);
              final sColor = switch (entry.key) {
                'lab' => _indigo,
                'nursing' => _emerald,
                'pharmacy' => _amber,
                _ => _violet,
              };
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: AppColors.getBackground(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.getBorder(context)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: sColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$label (${entry.value.count} مامەڵە)',
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextTitle(context),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatIqd(entry.value.revenue),
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: sColor,
                          ),
                        ),
                        if (entry.value.commission > 0)
                          Text(
                            'کۆمیسیۆن: ${_formatIqd(entry.value.commission)}',
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 10,
                              color: AppColors.getTextSubtitle(context),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _ledgerMathRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Rabar',
                fontSize: isBold ? 12 : 11.5,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isBold
                    ? AppColors.getTextTitle(context)
                    : AppColors.getTextSubtitle(context),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: isBold ? 13 : 12,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
              color: valueColor ?? AppColors.getTextTitle(context),
            ),
          ),
        ],
      ),
    );
  }

  // ── 5. Period Transactions Ledger Card (Read-only Breakdown on Tap) ──
  Widget _buildTransactionsLedgerCard(List<Map<String, dynamic>> items) {
    final double filteredTotal = items.fold<double>(
      0.0,
      (sum, tx) => sum + _toDouble(tx['amount']),
    );
    final visible = items.take(_visibleLimit).toList();

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
                      'تۆماری مامەڵە داراییەکان',
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextTitle(context),
                      ),
                    ),
                    Text(
                      'بە پێی کاتی ناوخۆی هەولێر • ${items.length} تۆمار',
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 11,
                        color: AppColors.getTextSubtitle(context),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _emerald.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _formatIqd(filteredTotal),
                  style: const TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: _emerald,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() {
              _searchQuery = v;
              _visibleLimit = 30;
            }),
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: 12.5,
              color: AppColors.getTextTitle(context),
            ),
            decoration: InputDecoration(
              hintText: 'گەڕان بە ناوی نەخۆش، دابینکار، کۆد یان کۆپۆن...',
              hintStyle: TextStyle(
                fontFamily: 'Rabar',
                fontSize: 12,
                color: AppColors.getTextSubtitle(context),
              ),
              prefixIcon: const Icon(Iconsax.search_normal_1, size: 17),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 17),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {
                          _searchQuery = '';
                          _visibleLimit = 30;
                        });
                      },
                    )
                  : null,
              isDense: true,
              filled: true,
              fillColor: AppColors.getBackground(context),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
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
          const SizedBox(height: 12),

          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'لەم ماوەیەدا هیچ مامەڵەیەک بۆ ئەم فلتەرە نییە',
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            )
          else ...[
            ...List.generate(
              visible.length,
              (i) => _buildTransactionRow(visible[i], i),
            ),
            if (items.length > visible.length) ...[
              const SizedBox(height: 6),
              Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => _visibleLimit += 30),
                  icon: const Icon(Icons.expand_more_rounded, size: 18),
                  label: Text(
                    'پیشاندانی زیاتر (${items.length - visible.length} ماوە)',
                    style: const TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(foregroundColor: _emerald),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionRow(Map<String, dynamic> tx, int index) {
    final status = (tx['status'] ?? 'pending').toString().toLowerCase();
    final sColor = switch (status) {
      'completed' => _emerald,
      'pending' => _amber,
      'refunded' => _violet,
      _ => _rose,
    };
    final sLabel = switch (status) {
      'completed' => 'سەرکەوتوو',
      'pending' => 'چاوەڕوان',
      'refunded' => 'گەڕێندراوە',
      _ => 'شکستخواردوو',
    };

    final method = (tx['method'] ?? 'cash').toString().toLowerCase();
    final isCash = method == 'cash';
    final methodColor = isCash ? const Color(0xFF0D9488) : _indigo;

    final order = _matchedOrder(tx);
    final patientName = _patientName(tx, order);
    final providerName = _providerName(order);
    final disc = _extractDiscount(tx, order);
    final comm = status == 'completed' ? _orderCommission(tx, order) : 0.0;

    final dt = _recordDate(tx);
    final dateStr = dt != null
        ? '${intl.DateFormat('yyyy-MM-dd').format(dt)} • ${intl.DateFormat('hh:mm a').format(dt)}'
        : '';

    final metaParts = <String>[
      patientName,
      if (providerName.isNotEmpty) providerName,
      if (dateStr.isNotEmpty) dateStr,
    ];

    return GestureDetector(
      onTap: () => _showTransactionDetails(tx),
      child: Container(
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
                    (tx['description'] ?? tx['reference'] ?? '').toString(),
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
                const SizedBox(width: 8),
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
              metaParts.join(' • '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Rabar',
                fontSize: 11,
                color: AppColors.getTextSubtitle(context),
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: methodColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCash ? Iconsax.money_send : Iconsax.card_pos,
                              size: 10,
                              color: methodColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _methodLabel(method),
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: methodColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (disc.hasDiscount)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _rose.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Iconsax.ticket_discount,
                                size: 10,
                                color: _rose,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                disc.couponCode.isNotEmpty
                                    ? (disc.discountAmount > 0
                                        ? '${disc.couponCode} (-${_formatIqd(disc.discountAmount)})'
                                        : disc.couponCode)
                                    : '-${_formatIqd(disc.discountAmount)}',
                                style: const TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _rose,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (comm > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _violet.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'کۆمیشن: ${_formatCompact(comm)}',
                            style: const TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _violet,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatIqd(tx['amount']),
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: status == 'completed' ? _emerald : sColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: ((index < 15 ? index : 15) * 20).ms);
  }

  // ── 6. Provider Financial Statement PDF Modal (dynamic years) ──
  Future<void> _openExportReportModal({bool preferShare = false}) async {
    final nowBaghdad = _nowBaghdad();
    int selectedYear = nowBaghdad.year;
    int selectedMonth = nowBaghdad.month;
    if (_selectedMonth != 'all' && _selectedMonth.contains('-')) {
      final parts = _selectedMonth.split('-');
      selectedYear = int.tryParse(parts[0]) ?? nowBaghdad.year;
      selectedMonth = int.tryParse(parts[1]) ?? nowBaghdad.month;
    }

    final List<int> years =
        _availableYears.isNotEmpty ? [..._availableYears] : [nowBaghdad.year];
    if (!years.contains(selectedYear)) {
      years.insert(0, selectedYear);
      years.sort((a, b) => b.compareTo(a));
    }

    String providerType = 'all';
    int? selectedProviderId;
    List<dynamic> labs = [];
    List<dynamic> nurses = [];
    List<dynamic> drivers = [];
    bool isGeneratingPdf = false;
    String? modalError;

    try {
      final res = await ApiClient.get('/admin/transactions/providers');
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        labs = body['data']?['labs'] ?? [];
        nurses = body['data']?['nurses'] ?? [];
        drivers = body['data']?['drivers'] ?? [];
      }
    } catch (_) {}

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final isDark = Theme.of(modalCtx).brightness == Brightness.dark;

            const kurdishMonths = [
              {'id': 1, 'name': 'کانوونی دووەم (١)'},
              {'id': 2, 'name': 'شوبات (٢)'},
              {'id': 3, 'name': 'ئازار (٣)'},
              {'id': 4, 'name': 'نیسان (٤)'},
              {'id': 5, 'name': 'ئایار (٥)'},
              {'id': 6, 'name': 'حوزەیران (٦)'},
              {'id': 7, 'name': 'تەممووز (٧)'},
              {'id': 8, 'name': 'ئاب (٨)'},
              {'id': 9, 'name': 'ئەیلوول (٩)'},
              {'id': 10, 'name': 'تشرینی یەکەم (١٠)'},
              {'id': 11, 'name': 'تشرینی دووەم (١١)'},
              {'id': 12, 'name': 'کانوونی یەکەم (١٢)'},
            ];

            Future<Map<String, dynamic>?> fetchStatementData() async {
              setModalState(() {
                isGeneratingPdf = true;
                modalError = null;
              });

              try {
                final queryParams = [
                  'year=$selectedYear',
                  'month=$selectedMonth',
                  'provider_type=$providerType',
                  if (selectedProviderId != null)
                    'provider_id=$selectedProviderId',
                ].join('&');

                final res = await ApiClient.get(
                  '/admin/transactions/statement?$queryParams',
                );
                if (res.statusCode == 200) {
                  final body = jsonDecode(res.body);
                  return Map<String, dynamic>.from(body['data'] ?? {});
                } else {
                  setModalState(() {
                    modalError = AdminUi.readError(res);
                  });
                }
              } catch (e) {
                setModalState(() {
                  modalError = '$e';
                });
              } finally {
                if (modalCtx.mounted) {
                  setModalState(() {
                    isGeneratingPdf = false;
                  });
                }
              }
              return null;
            }

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF475569)
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _emerald.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Iconsax.document_download,
                            color: _emerald,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'پسوڵە و ڕاپۆرتی حیساباتی دابینکاران (PDF)',
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'دیاریکردنی مانگ، ساڵ و دابینکار بۆ یەکلاکردنەوەی دارایی',
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 11.5,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (modalError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _rose.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _rose.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          modalError!,
                          style: const TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 12,
                            color: _rose,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'مانگی ژمێریاری',
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _dropdownBox(
                                isDark: isDark,
                                child: DropdownButton<int>(
                                  value: selectedMonth,
                                  isExpanded: true,
                                  items: kurdishMonths
                                      .map(
                                        (m) => DropdownMenuItem<int>(
                                          value: m['id'] as int,
                                          child: Text(
                                            m['name'] as String,
                                            style: const TextStyle(
                                              fontFamily: 'Rabar',
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setModalState(() => selectedMonth = val);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ساڵ',
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _dropdownBox(
                                isDark: isDark,
                                child: DropdownButton<int>(
                                  value: selectedYear,
                                  isExpanded: true,
                                  items: years
                                      .map(
                                        (y) => DropdownMenuItem<int>(
                                          value: y,
                                          child: Text(
                                            '$y',
                                            style: const TextStyle(
                                              fontFamily: 'Rabar',
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setModalState(() => selectedYear = val);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'دابینکاری خزمەتگوزاری',
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildFilterTypeChip(
                          'all',
                          'هەموو دابینکارەکان',
                          providerType,
                          (t) {
                            setModalState(() {
                              providerType = t;
                              selectedProviderId = null;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildFilterTypeChip(
                          'lab',
                          'تاقیگەکان',
                          providerType,
                          (t) {
                            setModalState(() {
                              providerType = t;
                              selectedProviderId = labs.isNotEmpty
                                  ? int.tryParse('${labs.first['id']}')
                                  : null;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildFilterTypeChip(
                          'nurse',
                          'ناوەندە تەندروستیەکان',
                          providerType,
                          (t) {
                            setModalState(() {
                              providerType = t;
                              selectedProviderId = nurses.isNotEmpty
                                  ? int.tryParse('${nurses.first['id']}')
                                  : null;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildFilterTypeChip(
                          'driver',
                          'کارمەندانی گەیاندن',
                          providerType,
                          (t) {
                            setModalState(() {
                              providerType = t;
                              selectedProviderId = drivers.isNotEmpty
                                  ? int.tryParse('${drivers.first['id']}')
                                  : null;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (providerType == 'lab' && labs.isNotEmpty) ...[
                      _providerDropdown(
                        isDark: isDark,
                        list: labs,
                        selectedId: selectedProviderId,
                        hint: 'تاقیگە دیاریبکە',
                        allLabel: 'تەواوی تاقیگەکان (گشتی)',
                        fallbackName: 'تاقیگە',
                        onChanged: (v) =>
                            setModalState(() => selectedProviderId = v),
                      ),
                      const SizedBox(height: 16),
                    ] else if (providerType == 'nurse' && nurses.isNotEmpty) ...[
                      _providerDropdown(
                        isDark: isDark,
                        list: nurses,
                        selectedId: selectedProviderId,
                        hint: 'ناوەندی تەندروستی دیاریبکە',
                        allLabel: 'تەواوی ناوەندە تەندروستیەکان (گشتی)',
                        fallbackName: 'ناوەندی تەندروستی',
                        onChanged: (v) =>
                            setModalState(() => selectedProviderId = v),
                      ),
                      const SizedBox(height: 16),
                    ] else if (providerType == 'driver' &&
                        drivers.isNotEmpty) ...[
                      _providerDropdown(
                        isDark: isDark,
                        list: drivers,
                        selectedId: selectedProviderId,
                        hint: 'شۆفێر دیاریبکە',
                        allLabel: 'تەواوی کارمەندانی گەیاندن (گشتی)',
                        fallbackName: 'شۆفێر',
                        onChanged: (v) =>
                            setModalState(() => selectedProviderId = v),
                      ),
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 10),
                    if (isGeneratingPdf)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(color: _emerald),
                        ),
                      )
                    else ...[
                      SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final data = await fetchStatementData();
                            if (data != null && modalCtx.mounted) {
                              Navigator.pop(modalCtx);
                              if (mounted) {
                                if (preferShare) {
                                  await StatementPdfService.shareStatement(
                                    data,
                                  );
                                } else {
                                  await StatementPdfService.previewAndPrint(
                                    context,
                                    data,
                                  );
                                }
                              }
                            }
                          },
                          icon: Icon(
                            preferShare ? Iconsax.share : Iconsax.printer,
                            size: 20,
                          ),
                          label: Text(
                            preferShare
                                ? 'هاوبەشکردنی ڕاستەوخۆ (Share PDF)'
                                : 'بینینی پسوڵە و چاپکردن (Print / Save)',
                            style: const TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _emerald,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final data = await fetchStatementData();
                            if (data != null && modalCtx.mounted) {
                              Navigator.pop(modalCtx);
                              if (mounted) {
                                if (preferShare) {
                                  await StatementPdfService.previewAndPrint(
                                    context,
                                    data,
                                  );
                                } else {
                                  await StatementPdfService.shareStatement(
                                    data,
                                  );
                                }
                              }
                            }
                          },
                          icon: Icon(
                            preferShare ? Iconsax.printer : Iconsax.share,
                            size: 18,
                          ),
                          label: Text(
                            preferShare
                                ? 'بینینی پسوڵە و چاپکردن (Print / Save)'
                                : 'هاوبەشکردنی ڕاستەوخۆ (WhatsApp / Share)',
                            style: const TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _indigo,
                            side: const BorderSide(color: _indigo),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _dropdownBox({required bool isDark, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: DropdownButtonHideUnderline(child: child),
    );
  }

  Widget _providerDropdown({
    required bool isDark,
    required List<dynamic> list,
    required int? selectedId,
    required String hint,
    required String allLabel,
    required String fallbackName,
    required ValueChanged<int?> onChanged,
  }) {
    final hasValid =
        list.any((item) => int.tryParse('${item['id']}') == selectedId);
    return _dropdownBox(
      isDark: isDark,
      child: DropdownButton<int?>(
        value: hasValid ? selectedId : null,
        isExpanded: true,
        hint: Text(
          hint,
          style: const TextStyle(fontFamily: 'Rabar', fontSize: 13),
        ),
        items: [
          DropdownMenuItem<int?>(
            value: null,
            child: Text(
              allLabel,
              style: const TextStyle(fontFamily: 'Rabar', fontSize: 13),
            ),
          ),
          ...list.map(
            (item) => DropdownMenuItem<int?>(
              value: int.tryParse('${item['id']}'),
              child: Text(
                (item['name'] ?? fallbackName).toString(),
                style: const TextStyle(fontFamily: 'Rabar', fontSize: 13),
              ),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildFilterTypeChip(
    String type,
    String label,
    String currentType,
    Function(String) onSelect,
  ) {
    final isSelected = currentType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? _emerald : _emerald.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : _emerald,
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountingMetrics {
  final int totalCount;
  final int completedCount;
  final int pendingCount;
  final int failedCount;
  final int refundedCount;
  final int cashCount;
  final int onlineCount;
  final double completedRevenue;
  final double todayCompletedRevenue;
  final double allTimeCompletedRevenue;
  final int allTimeCompletedCount;
  final double avgCompletedAmount;
  final double successRate;
  final double completedCommission;
  final double completedProviderNet;
  final double completedDeliveryFees;
  final double expensesTotal;
  final int expensesCount;
  final double netPlatformProfit;
  final double cashRevenue;
  final double onlineRevenue;
  final double pendingAmount;
  final double failedAmount;
  final double refundedAmount;
  final double discountTotal;
  final int discountedCount;
  final int discountedUsersCount;
  final Map<String, ({int count, double amount})> methodTotals;
  final Map<String, ({int count, double revenue, double commission})>
      sectorTotals;

  const _AccountingMetrics({
    required this.totalCount,
    required this.completedCount,
    required this.pendingCount,
    required this.failedCount,
    required this.refundedCount,
    required this.cashCount,
    required this.onlineCount,
    required this.completedRevenue,
    required this.todayCompletedRevenue,
    required this.allTimeCompletedRevenue,
    required this.allTimeCompletedCount,
    required this.avgCompletedAmount,
    required this.successRate,
    required this.completedCommission,
    required this.completedProviderNet,
    required this.completedDeliveryFees,
    required this.expensesTotal,
    required this.expensesCount,
    required this.netPlatformProfit,
    required this.cashRevenue,
    required this.onlineRevenue,
    required this.pendingAmount,
    required this.failedAmount,
    required this.refundedAmount,
    required this.discountTotal,
    required this.discountedCount,
    required this.discountedUsersCount,
    required this.methodTotals,
    required this.sectorTotals,
  });
}
