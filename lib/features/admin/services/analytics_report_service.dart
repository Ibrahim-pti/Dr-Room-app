import 'dart:convert';
import 'package:intl/intl.dart' as intl;
import '../../../core/utils/api_client.dart';

/// Compiles complete monthly & filtered system analytics across orders, revenue,
/// commission, expenses, patients, lab tests, providers, and ecosystem health.
///
/// Prefers the v2 `/admin/analytics/overview` backend endpoint when deployed,
/// and seamlessly aggregates the exact same dataset client-side from live admin
/// endpoints when running against an older backend deployment.
class AnalyticsReportService {
  static _RawSystemSnapshot? _cachedSnapshot;

  static void clearCache() {
    _cachedSnapshot = null;
  }

  static Future<Map<String, dynamic>> loadReport({
    required String selectedMonth,
    required String serviceType,
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) {
      _cachedSnapshot = null;
    }

    // 1. Try fast server-side v2 endpoint first (unless we already know we are using cached snapshot)
    if (_cachedSnapshot == null) {
      try {
        final query =
            '?month=${Uri.encodeComponent(selectedMonth)}&service_type=${Uri.encodeComponent(serviceType)}';
        final res = await ApiClient.get('/admin/analytics/overview$query');
        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);
          if (decoded is Map && decoded['data'] is Map) {
            final data = Map<String, dynamic>.from(decoded['data'] as Map);
            if (data['version'] == 2) {
              return data;
            }
          }
        }
      } catch (_) {
        // Fall through to full client-side aggregation
      }
    }

    // 2. Client-side complete aggregation across live admin endpoints
    final snapshot = _cachedSnapshot ?? await _fetchRawSnapshot();
    _cachedSnapshot = snapshot;

    return _compileFromSnapshot(
      snapshot,
      selectedMonth: selectedMonth,
      serviceType: serviceType,
    );
  }

  static Future<_RawSystemSnapshot> _fetchRawSnapshot() async {
    final results = await Future.wait([
      ApiClient.get('/admin/orders'),
      ApiClient.get('/admin/dashboard').catchError((_) => throw Exception()),
      ApiClient.get('/admin/patients?per_page=200').catchError((_) => throw Exception()),
      ApiClient.get('/admin/nurses').catchError((_) => throw Exception()),
      ApiClient.get('/admin/labs').catchError((_) => throw Exception()),
      ApiClient.get('/admin/lab-results').catchError((_) => throw Exception()),
      ApiClient.get('/admin/report-settings').catchError((_) => throw Exception()),
    ].map((f) => f.then<dynamic>((r) => r).catchError((_) => null)));

    final ordersRes = results[0];
    if (ordersRes == null || ordersRes.statusCode != 200) {
      throw Exception('نەتوانرا داتای داواکارییەکانی سیستەم بهێندرێت');
    }

    final ordersBody = jsonDecode(ordersRes.body);
    final List<Map<String, dynamic>> orders = _extractList(
      ordersBody is Map ? (ordersBody['orders'] ?? ordersBody['data']) : ordersBody,
    );

    final dashRes = results[1];
    final Map<String, dynamic> dashboard = (dashRes != null && dashRes.statusCode == 200)
        ? Map<String, dynamic>.from(jsonDecode(dashRes.body) as Map)
        : {};

    final patientsRes = results[2];
    final List<Map<String, dynamic>> patients = [];
    int totalPatientsFromMeta = _toInt(dashboard['total_users']);
    if (patientsRes != null && patientsRes.statusCode == 200) {
      final pBody = jsonDecode(patientsRes.body);
      if (pBody is Map) {
        final dataBlock = pBody['data'];
        if (dataBlock is Map && dataBlock['data'] is List) {
          patients.addAll(_extractList(dataBlock['data']));
          final lastPage = _toInt(dataBlock['last_page'], fallback: 1).clamp(1, 10);
          if (lastPage > 1) {
            final morePatients = await Future.wait(
              List.generate(lastPage - 1, (idx) => ApiClient.get('/admin/patients?per_page=200&page=${idx + 2}'))
                  .map((f) => f.then<dynamic>((r) => r).catchError((_) => null)),
            );
            for (final res in morePatients) {
              if (res != null && res.statusCode == 200) {
                final mBody = jsonDecode(res.body);
                if (mBody is Map && mBody['data'] is Map && mBody['data']['data'] is List) {
                  patients.addAll(_extractList(mBody['data']['data']));
                }
              }
            }
          }
        } else if (dataBlock is List) {
          patients.addAll(_extractList(dataBlock));
        }
        if (pBody['meta'] is Map) {
          totalPatientsFromMeta = _toInt((pBody['meta'] as Map)['total'], fallback: totalPatientsFromMeta);
        }
      }
    }

    final nursesRes = results[3];
    final List<Map<String, dynamic>> nurses = (nursesRes != null && nursesRes.statusCode == 200)
        ? _extractList(jsonDecode(nursesRes.body))
        : [];

    final labsRes = results[4];
    final List<Map<String, dynamic>> labs = (labsRes != null && labsRes.statusCode == 200)
        ? _extractList(jsonDecode(labsRes.body))
        : [];

    final labResultsRes = results[5];
    int totalLabResults = 0;
    if (labResultsRes != null && labResultsRes.statusCode == 200) {
      final lrBody = jsonDecode(labResultsRes.body);
      if (lrBody is Map && lrBody['data'] is Map) {
        totalLabResults = _toInt((lrBody['data'] as Map)['total']);
      }
    }

    final brandingRes = results[6];
    final Map<String, dynamic> branding = (brandingRes != null && brandingRes.statusCode == 200)
        ? Map<String, dynamic>.from((jsonDecode(brandingRes.body)['data'] as Map?) ?? {})
        : {};

    // Fetch all paginated expenses safely (20 per page in controller)
    final List<Map<String, dynamic>> expenses = await _fetchAllExpenses();

    return _RawSystemSnapshot(
      orders: orders,
      expenses: expenses,
      patients: patients,
      totalPatientsCount: totalPatientsFromMeta > patients.length ? totalPatientsFromMeta : patients.length,
      nurses: nurses,
      labs: labs,
      dashboard: dashboard,
      totalLabResults: totalLabResults,
      branding: branding,
    );
  }

  static Future<List<Map<String, dynamic>>> _fetchAllExpenses() async {
    final List<Map<String, dynamic>> all = [];
    try {
      final firstRes = await ApiClient.get('/admin/expenses?page=1');
      if (firstRes.statusCode != 200) return all;
      final decoded = jsonDecode(firstRes.body);
      final data = decoded is Map ? decoded['data'] : null;
      if (data is Map) {
        all.addAll(_extractList(data['data']));
        final lastPage = _toInt(data['last_page'], fallback: 1).clamp(1, 8);
        if (lastPage > 1) {
          final more = await Future.wait(
            List.generate(lastPage - 1, (idx) => ApiClient.get('/admin/expenses?page=${idx + 2}'))
                .map((f) => f.then<dynamic>((r) => r).catchError((_) => null)),
          );
          for (final res in more) {
            if (res != null && res.statusCode == 200) {
              final d = jsonDecode(res.body);
              if (d is Map && d['data'] is Map) {
                all.addAll(_extractList((d['data'] as Map)['data']));
              }
            }
          }
        }
      } else if (data is List) {
        all.addAll(_extractList(data));
      }
    } catch (_) {}
    return all;
  }

  static Map<String, dynamic> _compileFromSnapshot(
    _RawSystemSnapshot s, {
    required String selectedMonth,
    required String serviceType,
  }) {
    final nowBaghdad = DateTime.now().toUtc().add(const Duration(hours: 3));
    final currentMonth = _formatMonth(nowBaghdad);

    final String effectiveMonth =
        (selectedMonth == 'all' || RegExp(r'^\d{4}-\d{2}$').hasMatch(selectedMonth))
            ? selectedMonth
            : currentMonth;

    // Collect all available months
    final Set<String> monthSet = {currentMonth};
    for (final o in s.orders) {
      final m = _orderMonth(o);
      if (m != null) monthSet.add(m);
    }
    for (final e in s.expenses) {
      final m = _expenseMonth(e);
      if (m != null) monthSet.add(m);
    }
    for (final p in s.patients) {
      final m = _dateMonth(p['created_at']);
      if (m != null) monthSet.add(m);
    }
    final List<String> months = monthSet.toList()..sort((a, b) => b.compareTo(a));

    // Filter orders by service_type
    final filteredOrders = serviceType == 'all'
        ? s.orders
        : s.orders.where((o) => _classifyService(o) == serviceType).toList();

    final periodOrders = effectiveMonth == 'all'
        ? filteredOrders
        : filteredOrders.where((o) => _orderMonth(o) == effectiveMonth).toList();

    final periodExpenses = effectiveMonth == 'all'
        ? s.expenses
        : s.expenses.where((e) => _expenseMonth(e) == effectiveMonth).toList();

    final int periodNewUsers = effectiveMonth == 'all'
        ? s.totalPatientsCount
        : s.patients.where((p) => _dateMonth(p['created_at']) == effectiveMonth).length;

    final summary = _summarizeSlice(
      periodOrders,
      periodExpenses,
      periodNewUsers,
      effectiveMonth,
    );
    final overall = _summarizeSlice(
      filteredOrders,
      s.expenses,
      s.totalPatientsCount,
      'all',
    );

    // Monthly breakdown rows
    final List<Map<String, dynamic>> monthlyRows = months.map((month) {
      final mOrders = filteredOrders.where((o) => _orderMonth(o) == month).toList();
      final mExpenses = s.expenses.where((e) => _expenseMonth(e) == month).toList();
      final mUsers = s.patients.where((p) => _dateMonth(p['created_at']) == month).length;
      return _summarizeSlice(mOrders, mExpenses, mUsers, month);
    }).toList();

    // 6-month chronological chart series
    final List<String> chartMonths = List.generate(6, (idx) {
      final ago = 5 - idx;
      final dt = DateTime(nowBaghdad.year, nowBaghdad.month - ago, 1);
      return _formatMonth(dt);
    });
    final List<Map<String, dynamic>> chartSeries = chartMonths.map((month) {
      final row = monthlyRows.cast<Map<String, dynamic>?>().firstWhere(
            (r) => r?['month'] == month,
            orElse: () => null,
          );
      return {
        'month': month,
        'gross_revenue': row?['gross_revenue'] ?? 0.0,
        'commission_total': row?['commission_total'] ?? 0.0,
        'expenses_total': row?['expenses_total'] ?? 0.0,
        'net_profit': row?['net_profit'] ?? 0.0,
        'total_orders': row?['total_orders'] ?? 0,
        'completed_orders': row?['completed_orders'] ?? 0,
        'items_performed': row?['items_performed'] ?? 0,
        'new_users': row?['new_users'] ?? 0,
      };
    }).toList();

    // Service breakdown across all orders in the selected month
    final monthAllServiceOrders = effectiveMonth == 'all'
        ? s.orders
        : s.orders.where((o) => _orderMonth(o) == effectiveMonth).toList();

    const serviceLabels = {
      'lab': 'پشکنینی تاقیگە',
      'nursing': 'پەرستاری ماڵەوە',
      'pharmacy': 'دەرمانخانە',
      'other': 'خزمەتگوزاری تر',
    };
    final List<Map<String, dynamic>> serviceBreakdown = [];
    for (final entry in serviceLabels.entries) {
      final slice = monthAllServiceOrders.where((o) => _classifyService(o) == entry.key).toList();
      if (entry.key == 'other' && slice.isEmpty) continue;
      final completed = slice.where((o) => _isCompleted(o)).toList();
      serviceBreakdown.add({
        'key': entry.key,
        'label': entry.value,
        'orders_count': slice.length,
        'completed_count': completed.length,
        'revenue': completed.fold<double>(0.0, (sum, o) => sum + _toDouble(o['total_price'])),
      });
    }

    // Status breakdown
    final statusBreakdown = [
      {'key': 'completed', 'label': 'تەواوکراو', 'count': summary['completed_orders']},
      {'key': 'active', 'label': 'چالاک / چاوەڕوان', 'count': summary['active_orders']},
      {'key': 'cancelled', 'label': 'هەڵوەشاوە', 'count': summary['cancelled_orders']},
    ];

    // Top requested services / lab tests from completed orders in period
    final Map<String, Map<String, dynamic>> itemAgg = {};
    for (final o in periodOrders) {
      if (!_isCompleted(o)) continue;
      final svc = _classifyService(o);
      final items = (o['items'] is List) ? (o['items'] as List) : const [];
      if (items.isEmpty) {
        final fallbackName = switch (svc) {
          'lab' => 'پشکنینی تاقیگە',
          'nursing' => 'خزمەتگوزاری پەرستاری',
          _ => 'خزمەتگوزاری گشتی',
        };
        final entry = itemAgg.putIfAbsent(
          fallbackName,
          () => {'name': fallbackName, 'service_type': svc, 'count': 0, 'revenue': 0.0},
        );
        entry['count'] = (entry['count'] as int) + 1;
        entry['revenue'] = (entry['revenue'] as double) + _toDouble(o['total_price']);
      } else {
        for (final raw in items) {
          if (raw is! Map) continue;
          final rawName = (raw['item_name'] ?? '').toString().trim();
          final name = rawName.isNotEmpty ? rawName : 'خزمەتگوزاری';
          final qty = _toInt(raw['quantity'], fallback: 1).clamp(1, 9999);
          final lineRev = _toDouble(raw['price']) * qty;
          final entry = itemAgg.putIfAbsent(
            name,
            () => {'name': name, 'service_type': svc, 'count': 0, 'revenue': 0.0},
          );
          entry['count'] = (entry['count'] as int) + qty;
          entry['revenue'] = (entry['revenue'] as double) + lineRev;
        }
      }
    }
    final topItems = itemAgg.values.toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    // Top Labs in period
    final Map<dynamic, Map<String, dynamic>> labAgg = {};
    for (final o in periodOrders) {
      if (!_isCompleted(o) || o['assigned_lab_id'] == null) continue;
      final lid = o['assigned_lab_id'];
      final labUser = o['assigned_lab'] is Map ? (o['assigned_lab'] as Map) : const {};
      final name = (labUser['name'] ?? 'تاقیگە #$lid').toString();
      final entry = labAgg.putIfAbsent(
        lid,
        () => {'id': lid, 'name': name, 'orders_count': 0, 'revenue': 0.0},
      );
      entry['orders_count'] = (entry['orders_count'] as int) + 1;
      entry['revenue'] = (entry['revenue'] as double) + _toDouble(o['total_price']);
    }
    final topLabs = labAgg.values.toList()
      ..sort((a, b) => (b['orders_count'] as int).compareTo(a['orders_count'] as int));

    // Top Nurses in period (enrich with nurse rating)
    final Map<dynamic, double> nurseRatings = {};
    for (final u in s.nurses) {
      final uid = u['id'];
      final nProfile = u['nurse'] is Map ? (u['nurse'] as Map) : const {};
      nurseRatings[uid] = _toDouble(nProfile['rating'], fallback: 5.0);
    }
    final Map<dynamic, Map<String, dynamic>> nurseAgg = {};
    for (final o in periodOrders) {
      if (!_isCompleted(o) || o['assigned_nurse_id'] == null) continue;
      final nid = o['assigned_nurse_id'];
      final nurseUser = o['assigned_nurse'] is Map ? (o['assigned_nurse'] as Map) : const {};
      final name = (nurseUser['name'] ?? 'پەرستار #$nid').toString();
      final entry = nurseAgg.putIfAbsent(
        nid,
        () => {
          'id': nid,
          'name': name,
          'orders_count': 0,
          'revenue': 0.0,
          'rating': nurseRatings[nid] ?? 5.0,
        },
      );
      entry['orders_count'] = (entry['orders_count'] as int) + 1;
      entry['revenue'] = (entry['revenue'] as double) + _toDouble(o['total_price']);
    }
    final topNurses = nurseAgg.values.toList()
      ..sort((a, b) => (b['orders_count'] as int).compareTo(a['orders_count'] as int));

    // Ecosystem metrics from dashboard & lists
    final ecosystem = {
      'total_patients': s.totalPatientsCount,
      'total_labs': _toInt(s.dashboard['total_labs'], fallback: s.labs.where((l) => l['status'] == 'approved').length),
      'pending_labs': _toInt(s.dashboard['pending_labs'], fallback: s.labs.where((l) => l['status'] == 'pending').length),
      'total_nurses': _toInt(s.dashboard['total_nurses'], fallback: s.nurses.where((n) => n['status'] == 'approved').length),
      'pending_nurses': _toInt(s.dashboard['pending_nurses'], fallback: s.nurses.where((n) => n['status'] == 'pending').length),
      'total_pharmacies': _toInt(s.dashboard['total_pharmacies']),
      'pending_pharmacies': _toInt(s.dashboard['pending_pharmacies']),
      'total_drivers': _toInt(s.dashboard['total_drivers']),
      'pending_drivers': _toInt(s.dashboard['pending_drivers']),
      'online_drivers': _toInt(s.dashboard['online_drivers']),
      'busy_drivers': _toInt(s.dashboard['busy_drivers']),
      'open_tickets': _toInt(s.dashboard['open_tickets']),
      'total_lab_results': s.totalLabResults,
      'total_appointments': _toInt(s.dashboard['total_appointments']),
    };

    // Branding defaults
    final branding = {
      'header_title': (s.branding['header_title']?.toString().trim().isNotEmpty ?? false)
          ? s.branding['header_title'].toString().trim()
          : 'دکتۆر ڕۆم - Dr. Room',
      'header_subtitle': (s.branding['header_subtitle']?.toString().trim().isNotEmpty ?? false)
          ? s.branding['header_subtitle'].toString().trim()
          : 'سیستەمی تەندروستی و پزیشکی ماڵەوە',
      'footer_text': (s.branding['footer_text']?.toString().trim().isNotEmpty ?? false)
          ? s.branding['footer_text'].toString().trim()
          : 'پەسەندکراوە لەلایەن بەڕێوەبەرایەتی Dr. Room',
      'emergency_phone': (s.branding['emergency_phone']?.toString().trim().isNotEmpty ?? false)
          ? s.branding['emergency_phone'].toString().trim()
          : '+964 750 000 0000',
      'show_stamp': s.branding['show_stamp'] != false,
    };

    // Period orders ledger (latest 60)
    final ledgerOrders = periodOrders.take(60).map((o) {
      final svc = _classifyService(o);
      final patient = o['patient'] is Map ? (o['patient'] as Map) : const {};
      final lab = o['assigned_lab'] is Map ? (o['assigned_lab'] as Map) : const {};
      final nurse = o['assigned_nurse'] is Map ? (o['assigned_nurse'] as Map) : const {};
      final pharm = o['assigned_pharmacy'] is Map ? (o['assigned_pharmacy'] as Map) : const {};
      final driver = o['assigned_driver'] is Map ? (o['assigned_driver'] as Map) : const {};

      final providerName = (lab['name'] ??
              nurse['name'] ??
              pharm['name'] ??
              driver['name'] ??
              'تەرخان نەکراوە')
          .toString();

      final items = (o['items'] is List) ? (o['items'] as List) : const [];
      final itemNames = items
          .whereType<Map>()
          .map((i) => (i['item_name'] ?? '').toString().trim())
          .where((n) => n.isNotEmpty)
          .toList();
      final itemsSummary = itemNames.isNotEmpty
          ? itemNames.join('، ')
          : switch (svc) {
              'lab' => 'پشکنینی تاقیگە',
              'nursing' => 'پەرستاری ماڵەوە',
              _ => 'خزمەتگوزاری پزیشکی',
            };

      final dt = _parseBaghdadDate(o['created_at']);
      return {
        'id': o['id'],
        'order_number': o['order_number'] ?? '#ORD-${o['id'].toString().padLeft(4, '0')}',
        'patient_name': (patient['name'] ?? 'نەخۆش').toString(),
        'patient_phone': (patient['phone'] ?? '').toString(),
        'provider_name': providerName,
        'service_type': svc,
        'items_summary': itemsSummary,
        'status': (o['status'] ?? 'pending').toString(),
        'payment_method': (o['payment_method'] ?? 'cash').toString().toLowerCase(),
        'total_price': _toDouble(o['total_price']),
        'commission_amount': _toDouble(o['commission_amount']),
        'delivery_fee': _toDouble(o['delivery_fee']),
        'discount_amount': _toDouble(o['discount_amount']),
        'date': dt != null ? intl.DateFormat('yyyy-MM-dd').format(dt) : '',
        'time': dt != null ? intl.DateFormat('hh:mm a').format(dt) : '',
      };
    }).toList();

    return {
      'version': 2,
      'generated_at': intl.DateFormat('yyyy-MM-dd HH:mm').format(nowBaghdad),
      'current_month': currentMonth,
      'selected_month': effectiveMonth,
      'service_type': serviceType,
      'months': months,
      'summary': summary,
      'overall': overall,
      'monthly_rows': monthlyRows,
      'chart_series': chartSeries,
      'service_breakdown': serviceBreakdown,
      'status_breakdown': statusBreakdown,
      'top_items': topItems.take(10).toList(),
      'top_labs': topLabs.take(5).toList(),
      'top_nurses': topNurses.take(5).toList(),
      'ecosystem': ecosystem,
      'branding': branding,
      'ledger_orders': ledgerOrders,
    };
  }

  static Map<String, dynamic> _summarizeSlice(
    List<Map<String, dynamic>> orders,
    List<Map<String, dynamic>> expenses,
    int newUsers,
    String month,
  ) {
    final completed = orders.where((o) => _isCompleted(o)).toList();
    final cancelled = orders.where((o) => _isCancelled(o)).toList();
    final active = orders.where((o) => !_isCompleted(o) && !_isCancelled(o)).toList();

    double grossRevenue = 0;
    double commissionTotal = 0;
    double providerNet = 0;
    double deliveryFees = 0;
    double cashRevenue = 0;
    int itemsPerformed = 0;
    final Set<dynamic> completedPatients = {};

    for (final o in completed) {
      final total = _toDouble(o['total_price']);
      double comm = _toDouble(o['commission_amount']);
      if (comm <= 0 && _toDouble(o['commission_rate']) > 0) {
        comm = (total * _toDouble(o['commission_rate'])) / 100.0;
      }
      final pNet = o['provider_net_amount'] != null
          ? _toDouble(o['provider_net_amount'])
          : (total - comm).clamp(0.0, double.infinity);
      final dFee = _toDouble(o['delivery_fee']);

      grossRevenue += total;
      commissionTotal += comm;
      providerNet += pNet;
      deliveryFees += dFee;

      final method = (o['payment_method'] ?? 'cash').toString().toLowerCase();
      if (method == 'cash') {
        cashRevenue += total;
      }

      if (o['patient_id'] != null) {
        completedPatients.add(o['patient_id']);
      }

      final items = (o['items'] is List) ? (o['items'] as List) : const [];
      if (items.isEmpty) {
        itemsPerformed += 1;
      } else {
        for (final item in items) {
          if (item is Map) {
            itemsPerformed += _toInt(item['quantity'], fallback: 1).clamp(1, 9999);
          }
        }
      }
    }

    final double onlineRevenue = (grossRevenue - cashRevenue).clamp(0.0, double.infinity);

    double discountTotal = 0;
    int discountedOrders = 0;
    final Set<dynamic> uniquePatients = {};
    for (final o in orders) {
      if (o['patient_id'] != null) {
        uniquePatients.add(o['patient_id']);
      }
      if (!_isCancelled(o)) {
        final disc = _toDouble(o['discount_amount']);
        final code = (o['coupon_code'] ?? '').toString().trim();
        if (disc > 0 || code.isNotEmpty) {
          discountTotal += disc;
          discountedOrders += 1;
        }
      }
    }

    final double expensesTotal =
        expenses.fold<double>(0.0, (sum, e) => sum + _toDouble(e['amount']));

    final totalOrders = orders.length;
    final completedCount = completed.length;
    final double completionRate = totalOrders > 0
        ? double.parse(((completedCount / totalOrders) * 100).toStringAsFixed(1))
        : 0.0;

    return {
      'month': month,
      'total_orders': totalOrders,
      'completed_orders': completedCount,
      'active_orders': active.length,
      'cancelled_orders': cancelled.length,
      'completion_rate': completionRate,
      'items_performed': itemsPerformed,
      'unique_patients': uniquePatients.length,
      'completed_patients': completedPatients.length,
      'new_users': newUsers,
      'gross_revenue': grossRevenue,
      'commission_total': commissionTotal,
      'provider_net': providerNet,
      'delivery_fees': deliveryFees,
      'discount_total': discountTotal,
      'discounted_orders': discountedOrders,
      'cash_revenue': cashRevenue,
      'online_revenue': onlineRevenue,
      'expenses_total': expensesTotal,
      'net_profit': commissionTotal - expensesTotal,
    };
  }

  static bool _isCompleted(Map<String, dynamic> o) =>
      (o['status'] ?? '').toString().toLowerCase() == 'completed';

  static bool _isCancelled(Map<String, dynamic> o) {
    final s = (o['status'] ?? '').toString().toLowerCase();
    return s == 'cancelled' || s == 'rejected';
  }

  static String _classifyService(Map<String, dynamic> o) {
    final st = (o['service_type'] ?? '').toString().toLowerCase().trim();
    if (st.contains('pharm') || st.contains('دەرمان') || o['assigned_pharmacy_id'] != null) {
      return 'pharmacy';
    }
    if (st.contains('lab') || st.contains('تاقیگە') || o['assigned_lab_id'] != null) {
      return 'lab';
    }
    if (st.contains('nurs') || st.contains('پەرستار') || o['assigned_nurse_id'] != null) {
      return 'nursing';
    }
    return 'other';
  }

  static String? _orderMonth(Map<String, dynamic> o) => _dateMonth(o['created_at']);

  static String? _expenseMonth(Map<String, dynamic> e) {
    final raw = (e['expense_date'] ?? e['created_at'])?.toString();
    if (raw == null || raw.trim().isEmpty) return null;
    if (RegExp(r'^\d{4}-\d{2}').hasMatch(raw.trim())) {
      return raw.trim().substring(0, 7);
    }
    return _dateMonth(raw);
  }

  static String? _dateMonth(dynamic raw) {
    if (raw == null) return null;
    final str = raw.toString().trim();
    if (str.isEmpty) return null;
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(str)) {
      return str.substring(0, 7);
    }
    final dt = _parseBaghdadDate(str);
    if (dt == null) return null;
    return _formatMonth(dt);
  }

  static DateTime? _parseBaghdadDate(dynamic raw) {
    if (raw == null) return null;
    final str = raw.toString().trim();
    if (str.isEmpty) return null;
    final parsed = DateTime.tryParse(str);
    if (parsed == null) return null;
    return parsed.isUtc
        ? parsed.add(const Duration(hours: 3))
        : parsed.toUtc().add(const Duration(hours: 3));
  }

  static String _formatMonth(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}';

  static List<Map<String, dynamic>> _extractList(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static int _toInt(dynamic val, {int fallback = 0}) {
    if (val == null) return fallback;
    if (val is int) return val;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString()) ?? fallback;
  }

  static double _toDouble(dynamic val, {double fallback = 0.0}) {
    if (val == null) return fallback;
    if (val is double) return val;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? fallback;
  }
}

class _RawSystemSnapshot {
  final List<Map<String, dynamic>> orders;
  final List<Map<String, dynamic>> expenses;
  final List<Map<String, dynamic>> patients;
  final int totalPatientsCount;
  final List<Map<String, dynamic>> nurses;
  final List<Map<String, dynamic>> labs;
  final Map<String, dynamic> dashboard;
  final int totalLabResults;
  final Map<String, dynamic> branding;

  const _RawSystemSnapshot({
    required this.orders,
    required this.expenses,
    required this.patients,
    required this.totalPatientsCount,
    required this.nurses,
    required this.labs,
    required this.dashboard,
    required this.totalLabResults,
    required this.branding,
  });
}
