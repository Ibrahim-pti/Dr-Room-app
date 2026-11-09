import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/utils/api_client.dart';
import 'admin_app_bar.dart';
import 'admin_ui.dart';
import 'services/statement_pdf_service.dart';

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
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AdminAppBar(
        title: 'مامەڵە و داهات',
        subtitle: 'تۆماری هەموو پارەدانەکان',
        icon: Iconsax.wallet_3,
        iconColor: const Color(0xFF059669),
        iconBackgroundColor: const Color(0xFFECFDF5),
        showBackButton: true,
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
        if (_summary['by_method'] is List && (_summary['by_method'] as List).isNotEmpty) ...[
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: (_summary['by_method'] as List).map<Widget>((bm) {
                final label = bm['label'] ?? bm['method'] ?? '';
                final total = _money(bm['total']);
                final count = bm['count'] ?? 0;
                final isCash = (bm['method'] ?? '') == 'cash';
                final chipColor = isCash ? const Color(0xFF0D9488) : const Color(0xFF3B82F6);
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Container(
                  margin: const EdgeInsetsDirectional.only(end: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: chipColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: chipColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isCash ? Iconsax.money_send : Iconsax.card_pos, size: 13, color: chipColor),
                      const SizedBox(width: 5),
                      Text('$label ($count): ',
                          style: TextStyle(fontFamily: 'Rabar', fontSize: 11, fontWeight: FontWeight.bold, color: chipColor)),
                      Text(total,
                          style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : const Color(0xFF0F172A))),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],

        // Export PDF Statement Button
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 14),
          child: ElevatedButton.icon(
            onPressed: _openExportReportModal,
            icon: const Icon(Iconsax.document_download, size: 20),
            label: const Text(
              'دەرهێنانی ڕاپۆرتی PDF (پسوڵەی حیساباتی دابینکاران)',
              style: TextStyle(fontFamily: 'Rabar', fontSize: 13.5, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 2,
              shadowColor: const Color(0xFF4F46E5).withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openExportReportModal() async {
    int selectedYear = DateTime.now().year;
    int selectedMonth = DateTime.now().month;
    String providerType = 'all'; // 'all', 'lab', 'nurse'
    int? selectedProviderId;
    List<dynamic> labs = [];
    List<dynamic> nurses = [];
    bool isGeneratingPdf = false;
    String? modalError;

    // Fetch providers
    try {
      final res = await ApiClient.get('/admin/transactions/providers');
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        labs = body['data']?['labs'] ?? [];
        nurses = body['data']?['nurses'] ?? [];
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

            final kurdishMonths = [
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
                  if (selectedProviderId != null) 'provider_id=$selectedProviderId',
                ].join('&');

                final res = await ApiClient.get('/admin/transactions/statement?$queryParams');
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
                setModalState(() {
                  isGeneratingPdf = false;
                });
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Iconsax.document_download, color: Color(0xFF4F46E5), size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'دەرهێنانی پسوڵە و ڕاپۆرتی حیسابات (PDF)',
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'دیاریکردنی مانگ، ساڵ و دابینکار بۆ یەکلاکردنەوەی دارایی',
                                style: TextStyle(fontFamily: 'Rabar', fontSize: 11.5, color: Color(0xFF64748B)),
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
                          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          modalError!,
                          style: const TextStyle(fontFamily: 'Rabar', fontSize: 12, color: Color(0xFFEF4444)),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Month & Year Selector Row
                    Row(
                      children: [
                        // Month Dropdown
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('مانگی ژمێریاری', style: TextStyle(fontFamily: 'Rabar', fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: selectedMonth,
                                    isExpanded: true,
                                    items: kurdishMonths.map((m) {
                                      return DropdownMenuItem<int>(
                                        value: m['id'] as int,
                                        child: Text(m['name'] as String, style: const TextStyle(fontFamily: 'Rabar', fontSize: 13)),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => selectedMonth = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Year Dropdown
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ساڵ', style: TextStyle(fontFamily: 'Rabar', fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: selectedYear,
                                    isExpanded: true,
                                    items: [2025, 2026, 2027].map((y) {
                                      return DropdownMenuItem<int>(
                                        value: y,
                                        child: Text('$y', style: const TextStyle(fontFamily: 'Rabar', fontSize: 13)),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setModalState(() => selectedYear = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Provider Filter Section
                    const Text('دابینکاری خزمەتگوزاری (Provider)', style: TextStyle(fontFamily: 'Rabar', fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),

                    // Type Chips: All, Lab, Nurse
                    Row(
                      children: [
                        _buildFilterTypeChip('all', 'هەموو دابینکارەکان', providerType, (t) {
                          setModalState(() {
                            providerType = t;
                            selectedProviderId = null;
                          });
                        }),
                        const SizedBox(width: 8),
                        _buildFilterTypeChip('lab', 'تاقیگەکان', providerType, (t) {
                          setModalState(() {
                            providerType = t;
                            selectedProviderId = labs.isNotEmpty ? labs.first['id'] : null;
                          });
                        }),
                        const SizedBox(width: 8),
                        _buildFilterTypeChip('nurse', 'پەرستارەکان', providerType, (t) {
                          setModalState(() {
                            providerType = t;
                            selectedProviderId = nurses.isNotEmpty ? nurses.first['id'] : null;
                          });
                        }),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Specific Provider Dropdown (if Lab or Nurse selected)
                    if (providerType == 'lab' && labs.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: selectedProviderId,
                            isExpanded: true,
                            hint: const Text('تاقیگە دیاریبکە', style: TextStyle(fontFamily: 'Rabar', fontSize: 13)),
                            items: [
                              const DropdownMenuItem<int>(
                                value: null,
                                child: Text('تەواوی تاقیگەکان (گشتی)', style: TextStyle(fontFamily: 'Rabar', fontSize: 13)),
                              ),
                              ...labs.map((l) => DropdownMenuItem<int>(
                                value: l['id'],
                                child: Text(l['name'] ?? 'تاقیگە', style: const TextStyle(fontFamily: 'Rabar', fontSize: 13)),
                              )),
                            ],
                            onChanged: (val) => setModalState(() => selectedProviderId = val),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else if (providerType == 'nurse' && nurses.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: selectedProviderId,
                            isExpanded: true,
                            hint: const Text('پەرستار دیاریبکە', style: TextStyle(fontFamily: 'Rabar', fontSize: 13)),
                            items: [
                              const DropdownMenuItem<int>(
                                value: null,
                                child: Text('تەواوی پەرستارەکان (گشتی)', style: TextStyle(fontFamily: 'Rabar', fontSize: 13)),
                              ),
                              ...nurses.map((n) => DropdownMenuItem<int>(
                                value: n['id'],
                                child: Text(n['name'] ?? 'پەرستار', style: const TextStyle(fontFamily: 'Rabar', fontSize: 13)),
                              )),
                            ],
                            onChanged: (val) => setModalState(() => selectedProviderId = val),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 10),

                    // Action Buttons Row: View/Print + Share
                    if (isGeneratingPdf)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else ...[
                      // Primary Button: View & Print
                      SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final data = await fetchStatementData();
                            if (data != null && modalCtx.mounted) {
                              Navigator.pop(modalCtx);
                              if (mounted) {
                                await StatementPdfService.previewAndPrint(context, data);
                              }
                            }
                          },
                          icon: const Icon(Iconsax.printer, size: 20),
                          label: const Text(
                            'بینینی پسوڵە و چاپکردن (Print / Save)',
                            style: TextStyle(fontFamily: 'Rabar', fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Secondary Button: WhatsApp / Direct Share
                      SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final data = await fetchStatementData();
                            if (data != null && modalCtx.mounted) {
                              Navigator.pop(modalCtx);
                              await StatementPdfService.shareStatement(data);
                            }
                          },
                          icon: const Icon(Iconsax.share, size: 18),
                          label: const Text(
                            'هاوبەشکردنی ڕاستەوخۆ (WhatsApp / Share)',
                            style: TextStyle(fontFamily: 'Rabar', fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF10B981),
                            side: const BorderSide(color: Color(0xFF10B981)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

  Widget _buildFilterTypeChip(String type, String label, String currentType, Function(String) onSelect) {
    final isSelected = currentType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF4F46E5).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : const Color(0xFF4F46E5),
            ),
          ),
        ),
      ),
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

    final method = (transaction['method'] ?? 'cash').toString().toLowerCase();
    final methodLabel = switch (method) {
      'cash' => 'کاش',
      'fib' => 'FIB',
      'fastpay' => 'FastPay',
      'zaincash' => 'ZainCash',
      'qi_card' => 'Qi Card',
      'card' => 'کارت',
      'wallet' => 'جزدان',
      _ => method.toUpperCase(),
    };
    final isCash = method == 'cash';
    final methodColor = isCash ? const Color(0xFF0D9488) : const Color(0xFF3B82F6);

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
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: methodColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: methodColor.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isCash ? Iconsax.money_send : Iconsax.card_pos, size: 10, color: methodColor),
                            const SizedBox(width: 4),
                            Text(
                              methodLabel,
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
                    ],
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