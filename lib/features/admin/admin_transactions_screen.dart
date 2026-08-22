import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/utils/api_client.dart';
import 'admin_app_bar.dart';
import 'admin_ui.dart';

/// Revenue at a glance plus the full transaction ledger.
class AdminTransactionsScreen extends StatefulWidget {
  const AdminTransactionsScreen({super.key});

  @override
  State<AdminTransactionsScreen> createState() => _AdminTransactionsScreenState();
}

class _AdminTransactionsScreenState extends State<AdminTransactionsScreen> {
  static const _statusFilters = [
    (value: '', label: 'هەمووی'),
    (value: 'completed', label: 'سەرکەوتوو'),
    (value: 'pending', label: 'چاوەڕوان'),
    (value: 'failed', label: 'شکستخواردوو'),
    (value: 'refunded', label: 'گەڕێندراوە'),
  ];

  Map<String, dynamic> _summary = {};
  List<dynamic> _transactions = [];
  String _status = '';
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

    final query = _status.isEmpty ? '' : '?status=$_status';

    try {
      final results = await Future.wait([
        ApiClient.get('/admin/transactions/summary'),
        ApiClient.get('/admin/transactions$query'),
      ]);

      if (!mounted) return;

      if (results[0].statusCode == 200 && results[1].statusCode == 200) {
        final page = jsonDecode(results[1].body);
        setState(() {
          _summary = Map<String, dynamic>.from(jsonDecode(results[0].body));
          _transactions = page is Map ? (page['data'] ?? []) : page;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = AdminUi.readError(results[0].statusCode == 200 ? results[1] : results[0]);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _isLoading = false; });
    }
  }

  Future<void> _changeStatus(dynamic transaction) async {
    String selected = transaction['status'] ?? 'pending';

    await AdminUi.formSheet(
      context: context,
      title: 'گۆڕینی دۆخی مامەڵە',
      subtitle: transaction['reference'] ?? '',
      submitLabel: 'پاشەکەوتکردن',
      builder: (setSheetState, setError) => [
        AdminUi.label('دۆخی نوێ'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _statusFilters
              .where((s) => s.value.isNotEmpty)
              .map<Widget>((s) => GestureDetector(
                    onTap: () => setSheetState(() => selected = s.value),
                    child: AdminUi.selectChip(s.label, selected == s.value),
                  ))
              .toList(),
        ),
      ],
      onSubmit: (setError) async {
        final res = await ApiClient.patch(
          '/admin/transactions/${transaction['id']}/status',
          body: {'status': selected},
        );

        if (res.statusCode == 200) {
          _load();
          return true;
        }

        setError(AdminUi.readError(res));
        return false;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AdminAppBar(
        title: 'مامەڵە و داهات',
        subtitle: 'تۆماری هەموو پارەدانەکان',
        icon: Iconsax.wallet_3,
        iconColor: const Color(0xFF059669),
        iconBackgroundColor: const Color(0xFFECFDF5),
      ),
      body: AdminUi.body(
        isLoading: _isLoading,
        error: _error,
        isEmpty: false,
        emptyIcon: Iconsax.wallet_3,
        emptyText: '',
        onRetry: _load,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummary(),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _statusFilters
                      .map((s) => Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8),
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _status = s.value);
                                _load();
                              },
                              child: AdminUi.selectChip(s.label, _status == s.value),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 14),
              if (_transactions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      const Icon(Iconsax.wallet_3, size: 44, color: Color(0xFFCBD5E1)),
                      const SizedBox(height: 10),
                      const Text('هێشتا هیچ مامەڵەیەک تۆمار نەکراوە',
                          style: TextStyle(
                              fontFamily: 'Rabar', fontSize: 13, color: Color(0xFF94A3B8))),
                    ],
                  ),
                )
              else
                ...List.generate(
                  _transactions.length,
                  (i) => _buildTransaction(_transactions[i], i),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF10B981)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('کۆی داهات',
                  style: TextStyle(fontFamily: 'Rabar', fontSize: 12.5, color: Colors.white70)),
              const SizedBox(height: 6),
              Text(
                _money(_summary['total_revenue']),
                style: const TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text('${_summary['transaction_count'] ?? 0} مامەڵەی سەرکەوتوو',
                  style: const TextStyle(
                      fontFamily: 'Rabar', fontSize: 11.5, color: Colors.white70)),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.05, end: 0),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _statTile('ئەمڕۆ', _money(_summary['today']), const Color(0xFF2563EB))),
            const SizedBox(width: 10),
            Expanded(
                child: _statTile('ئەم مانگە', _money(_summary['this_month']), const Color(0xFF8B5CF6))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _statTile('چاوەڕوان', '${_summary['pending_count'] ?? 0}',
                    const Color(0xFFD97706))),
            const SizedBox(width: 10),
            Expanded(
                child: _statTile('شکستخواردوو', '${_summary['failed_count'] ?? 0}',
                    const Color(0xFFEF4444))),
          ],
        ),
      ],
    );
  }

  Widget _statTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AdminUi.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontFamily: 'Rabar', fontSize: 11.5, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontFamily: 'Rabar', fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildTransaction(dynamic transaction, int index) {
    final status = transaction['status'] ?? 'pending';
    final color = switch (status) {
      'completed' => const Color(0xFF10B981),
      'pending' => const Color(0xFFD97706),
      'refunded' => const Color(0xFF6366F1),
      _ => const Color(0xFFEF4444),
    };
    final label = switch (status) {
      'completed' => 'سەرکەوتوو',
      'pending' => 'چاوەڕوان',
      'refunded' => 'گەڕێندراوە',
      _ => 'شکستخواردوو',
    };

    return GestureDetector(
      onTap: () => _changeStatus(transaction),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: AdminUi.cardDecoration,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Iconsax.wallet_3, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction['description'] ?? transaction['reference'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AdminUi.title,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${transaction['user']?['name'] ?? 'نەناسراو'} · ${_date(transaction['created_at'])}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AdminUi.subtitle,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_money(transaction['amount']),
                    style: const TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A))),
                const SizedBox(height: 4),
                AdminUi.chip(label, color, small: true),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 30).ms);
  }

  String _money(dynamic amount) {
    final value = amount is num ? amount : double.tryParse('$amount') ?? 0;
    final rounded = value.round().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < rounded.length; i++) {
      if (i > 0 && (rounded.length - i) % 3 == 0) buffer.write(',');
      buffer.write(rounded[i]);
    }

    return '${buffer.toString()} د.ع';
  }

  String _date(dynamic raw) {
    final parsed = DateTime.tryParse('$raw');
    if (parsed == null) return '';
    return '${parsed.year}/${parsed.month.toString().padLeft(2, '0')}/${parsed.day.toString().padLeft(2, '0')}';
  }
}