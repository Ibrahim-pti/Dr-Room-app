import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/utils/api_client.dart';
import 'admin_app_bar.dart';
import 'admin_ui.dart';

/// Who changed what, and when. Written automatically by the LogsActivity
/// trait on the backend — nothing here needs the staff to remember to log.
class AdminActivityLogScreen extends StatefulWidget {
  const AdminActivityLogScreen({super.key});

  @override
  State<AdminActivityLogScreen> createState() => _AdminActivityLogScreenState();
}

class _AdminActivityLogScreenState extends State<AdminActivityLogScreen> {
  final _searchController = TextEditingController();

  List<dynamic> _logs = [];
  String _action = '';
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _lastPage = 1;
  String? _error;

  static const _actionFilters = [
    (value: '', label: 'هەمووی'),
    (value: 'created', label: 'زیادکردن'),
    (value: 'updated', label: 'دەستکاری'),
    (value: 'deleted', label: 'سڕینەوە'),
    (value: 'hid_review', label: 'شاردنەوەی کۆمێنت'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool loadMore = false}) async {
    if (loadMore) {
      if (_isLoadingMore || _currentPage >= _lastPage) return;
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    final targetPage = loadMore ? _currentPage + 1 : 1;
    final params = <String>[
      'page=$targetPage',
      if (_action.isNotEmpty) 'action=$_action',
      if (_searchController.text.trim().isNotEmpty)
        'search=${Uri.encodeQueryComponent(_searchController.text.trim())}',
    ];
    final query = '?${params.join('&')}';

    try {
      final res = await ApiClient.get('/admin/activity-logs$query');
      if (!mounted) return;

      if (res.statusCode == 200) {
        final page = jsonDecode(res.body);
        final items = page is Map ? (page['data'] ?? []) : page;
        setState(() {
          _logs = loadMore ? [..._logs, ...items] : items;
          _currentPage = page is Map ? ((page['current_page'] as num?)?.toInt() ?? targetPage) : 1;
          _lastPage = page is Map ? ((page['last_page'] as num?)?.toInt() ?? 1) : 1;
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _error = AdminUi.readError(res);
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AdminAppBar(
        title: 'تۆماری چالاکی',
        subtitle: 'کێ چی گۆڕی و کەی',
        icon: Iconsax.document_text,
        iconColor: const Color(0xFF64748B),
        iconBackgroundColor: const Color(0xFFF1F5F9),
        showBackButton: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _load(),
                  onChanged: (_) => setState(() {}),
                  style: AdminUi.title.copyWith(fontSize: 13.5, fontWeight: FontWeight.normal),
                  decoration: InputDecoration(
                    hintText: 'گەڕان بە ناوی ستاف یان بابەت...',
                    hintStyle: AdminUi.subtitle,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 17),
                            onPressed: () {
                              _searchController.clear();
                              _load();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _actionFilters
                              .map((f) => Padding(
                                    padding: const EdgeInsetsDirectional.only(end: 8),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() => _action = f.value);
                                        _load();
                                      },
                                      child: AdminUi.selectChip(f.label, _action == f.value),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _load,
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(Iconsax.search_normal, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: AdminUi.body(
              isLoading: _isLoading,
              error: _error,
              isEmpty: _logs.isEmpty,
              emptyIcon: Iconsax.document_text,
              emptyText: 'هیچ چالاکییەک تۆمار نەکراوە',
              onRetry: _load,
              child: RefreshIndicator(
                onRefresh: () => _load(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _logs.length + (_currentPage < _lastPage ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == _logs.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: OutlinedButton(
                          onPressed: _isLoadingMore ? null : () => _load(loadMore: true),
                          child: _isLoadingMore
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('پیشاندانی زیاتر', style: TextStyle(fontFamily: 'Rabar')),
                        ),
                      );
                    }
                    return _buildRow(_logs[i], i);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(dynamic log, int index) {
    final action = log['action'] ?? '';
    final (color, icon, label) = switch (action) {
      'created' => (const Color(0xFF10B981), Iconsax.add_circle, 'زیادکرا'),
      'updated' => (const Color(0xFF2563EB), Iconsax.edit_2, 'دەستکاریکرا'),
      'deleted' => (const Color(0xFFEF4444), Iconsax.trash, 'سڕایەوە'),
      'hid_review' => (const Color(0xFFD97706), Iconsax.eye_slash, 'کۆمێنت شاردرایەوە'),
      'restored_review' => (const Color(0xFF10B981), Iconsax.eye, 'کۆمێنت گەڕایەوە'),
      'deleted_review' => (const Color(0xFFEF4444), Iconsax.trash, 'کۆمێنت سڕایەوە'),
      _ => (const Color(0xFF64748B), Iconsax.info_circle, action.toString()),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: AdminUi.cardDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        log['subject_label'] ?? '—',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AdminUi.title,
                      ),
                    ),
                    const SizedBox(width: 6),
                    AdminUi.chip(label, color, small: true),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${log['user_name'] ?? 'سیستەم'} · ${_when(log['created_at'])}',
                  style: AdminUi.subtitle,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 25).ms);
  }

  String _when(dynamic raw) {
    final parsed = DateTime.tryParse('$raw')?.toLocal();
    if (parsed == null) return '';

    final diff = DateTime.now().difference(parsed);
    if (diff.inMinutes < 1) return 'ئێستا';
    if (diff.inMinutes < 60) return 'پێش ${diff.inMinutes} خولەک';
    if (diff.inHours < 24) return 'پێش ${diff.inHours} کاتژمێر';
    if (diff.inDays < 7) return 'پێش ${diff.inDays} ڕۆژ';

    return '${parsed.year}/${parsed.month.toString().padLeft(2, '0')}/${parsed.day.toString().padLeft(2, '0')}';
  }
}