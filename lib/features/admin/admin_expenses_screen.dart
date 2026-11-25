import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/api_client.dart';
import 'admin_app_bar.dart';
import 'admin_ui.dart';

class AdminExpensesScreen extends StatefulWidget {
  const AdminExpensesScreen({super.key});

  @override
  State<AdminExpensesScreen> createState() => _AdminExpensesScreenState();
}

class _AdminExpensesScreenState extends State<AdminExpensesScreen> {
  static const _font = 'Rabar';
  static const _accent = Color(0xFFF97316);
  static const _blue = Color(0xFF2563EB);
  static const _green = Color(0xFF10B981);
  static const _red = Color(0xFFEF4444);
  static const _amber = Color(0xFFF59E0B);

  static const _categories = <({String id, String label, IconData icon, Color color})>[
    (id: 'salaries', label: 'مووچەی کارمەندان', icon: Iconsax.profile_2user, color: Color(0xFF6366F1)),
    (id: 'transport', label: 'کرێی هاتوچۆ و بەنزین', icon: Iconsax.car, color: Color(0xFF0EA5E9)),
    (id: 'lab_supplies', label: 'کەلوپەل و کەرەستەی تاقیگە', icon: Iconsax.microscope, color: Color(0xFF10B981)),
    (id: 'marketing', label: 'مارکێتینگ و ڕیکلام', icon: Iconsax.magic_star, color: Color(0xFFEC4899)),
    (id: 'maintenance', label: 'چاودێری و چاککردنەوە', icon: Iconsax.setting_2, color: Color(0xFFF59E0B)),
    (id: 'rent', label: 'کرێی شوێن / ئۆفیس', icon: Iconsax.building, color: Color(0xFF8B5CF6)),
    (id: 'other', label: 'خەرجی تر', icon: Iconsax.more, color: Color(0xFF64748B)),
  ];

  final _searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  bool _allTime = false;
  late DateTime _period = DateTime(DateTime.now().year, DateTime.now().month);
  String _selectedCategory = 'all';

  List<Map<String, dynamic>> _expenses = [];
  Map<String, dynamic> _summary = {};
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalExpensesCount = 0;

  bool get _isDark => ThemeProvider().isDarkMode;
  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _period.year == now.year && _period.month == now.month;
  }

  String get _periodLabel =>
      '${_period.month.toString().padLeft(2, '0')} / ${_period.year}';

  ({String id, String label, IconData icon, Color color}) _categoryMeta(String? id) {
    return _categories.firstWhere(
      (c) => c.id == id,
      orElse: () => _categories.last,
    );
  }

  double _num(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0.0;

  String _formatIqd(dynamic val, {bool showSign = false}) {
    final d = _num(val);
    final absFormatted = NumberFormat('#,###').format(d.abs().round());
    final prefix = d < 0 ? '-' : (showSign && d > 0 ? '+' : '');
    return '$prefix$absFormatted د.ع';
  }

  String _formatExpenseDate(dynamic raw) {
    final str = (raw ?? '').toString().trim();
    if (str.isEmpty) return '';
    final parsed = DateTime.tryParse(str);
    if (parsed != null) {
      return DateFormat('yyyy-MM-dd').format(parsed.toLocal());
    }
    final match = RegExp(r'^(\d{4}-\d{2}-\d{2})').firstMatch(str);
    return match != null ? match.group(1)! : str;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  String _buildQuery({int page = 1, bool forSummary = false}) {
    final params = <String, String>{};
    if (_allTime) {
      params['period'] = 'all';
    } else {
      params['year'] = _period.year.toString();
      params['month'] = _period.month.toString();
    }
    if (_selectedCategory != 'all') {
      params['category'] = _selectedCategory;
    }
    if (!forSummary) {
      params['page'] = page.toString();
      params['per_page'] = '30';
      final q = _searchCtrl.text.trim();
      if (q.isNotEmpty) {
        params['search'] = q;
      }
    }
    return Uri(queryParameters: params).query;
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        ApiClient.get('/admin/expenses?${_buildQuery(page: 1)}'),
        ApiClient.get('/admin/expenses/summary?${_buildQuery(forSummary: true)}'),
      ]);

      if (!mounted) return;

      if (results[0].statusCode == 200 && results[1].statusCode == 200) {
        final listBody = jsonDecode(results[0].body)['data'];
        final summaryBody = jsonDecode(results[1].body)['data'];

        final rawItems = listBody is Map ? (listBody['data'] ?? []) : (listBody ?? []);
        final items = List<Map<String, dynamic>>.from(
          (rawItems as List).map((e) => Map<String, dynamic>.from(e as Map)),
        );

        setState(() {
          _expenses = items;
          _currentPage = listBody is Map ? ((listBody['current_page'] as num?)?.toInt() ?? 1) : 1;
          _lastPage = listBody is Map ? ((listBody['last_page'] as num?)?.toInt() ?? 1) : 1;
          _totalExpensesCount = listBody is Map
              ? ((listBody['total'] as num?)?.toInt() ?? items.length)
              : items.length;
          _summary = summaryBody is Map ? Map<String, dynamic>.from(summaryBody) : {};
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'کێشە لە بارکردنی خەرجییەکان ڕوویدا (${results[0].statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'پەیوەندی سەرکەوتوو نەبوو: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _currentPage >= _lastPage) return;
    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final res = await ApiClient.get('/admin/expenses?${_buildQuery(page: nextPage)}');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final listBody = jsonDecode(res.body)['data'];
        final rawItems = listBody is Map ? (listBody['data'] ?? []) : [];
        final more = List<Map<String, dynamic>>.from(
          (rawItems as List).map((e) => Map<String, dynamic>.from(e as Map)),
        );
        setState(() {
          _expenses = [..._expenses, ...more];
          _currentPage = listBody is Map ? ((listBody['current_page'] as num?)?.toInt() ?? nextPage) : nextPage;
          _lastPage = listBody is Map ? ((listBody['last_page'] as num?)?.toInt() ?? _lastPage) : _lastPage;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _shiftMonth(int delta) {
    setState(() {
      _allTime = false;
      _period = DateTime(_period.year, _period.month + delta);
    });
    _load();
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _load);
  }

  Future<void> _deleteExpense(Map<String, dynamic> item) async {
    final ok = await AdminUi.confirm(
      context,
      title: 'سڕینەوەی خەرجی',
      message: 'ئایا دڵنیایت لە سڕینەوەی "${item['title'] ?? ''}" بە بڕی ${_formatIqd(item['amount'])}؟',
    );
    if (!ok) return;

    try {
      final res = await ApiClient.delete('/admin/expenses/${item['id']}');
      if (!mounted) return;
      if (res.statusCode == 200) {
        AdminUi.toast(context, 'خەرجی سڕایەوە');
        _load();
      } else {
        AdminUi.toast(context, AdminUi.readError(res), isError: true);
      }
    } catch (e) {
      if (mounted) AdminUi.toast(context, 'هەڵە: $e', isError: true);
    }
  }

  Future<void> _openBudgetDialog() async {
    final currentBudget = _num(_summary['monthly_budget']);
    final amountCtrl = TextEditingController(
      text: currentBudget > 0 ? currentBudget.toStringAsFixed(0) : '',
    );
    bool applyDefault = true;

    await _showAdaptiveSheet(
      title: 'دیاریکردنی بودجەی مانگانە',
      subtitle: 'سنووری خەرجی مانگانە بۆ $_periodLabel دیاری بکە',
      submitLabel: 'پاشەکەوتکردنی بودجە',
      builder: (setSheetState, setError) => [
        TextField(
          controller: amountCtrl,
          keyboardType: TextInputType.number,
          style: TextStyle(fontFamily: _font, color: AppColors.getTextTitle(context)),
          decoration: _inputDecoration('بڕی بودجەی مانگانە (د.ع)', suffix: 'د.ع'),
        ),
        const SizedBox(height: 12),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setSheetState(() => applyDefault = !applyDefault),
          child: Row(
            children: [
              Checkbox(
                value: applyDefault,
                activeColor: _blue,
                onChanged: (v) => setSheetState(() => applyDefault = v ?? true),
              ),
              Expanded(
                child: Text(
                  'وەک بودجەی بنەڕەتی مانگەکانی داهاتووش بەکاربهێنرێت',
                  style: AdminUi.subtitle.copyWith(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
      onSubmit: (setError) async {
        final amount = double.tryParse(amountCtrl.text.trim().replaceAll(',', ''));
        if (amount == null || amount < 0) {
          setError('تکایە بڕێکی دروست بنووسە (٠ یان زیاتر)');
          return false;
        }
        final res = await ApiClient.post('/admin/expenses/budget', body: {
          'amount': amount,
          'year': _period.year,
          'month': _period.month,
          'apply_default': applyDefault,
        });
        if (!mounted) return true;
        if (res.statusCode == 200) {
          AdminUi.toast(context, 'بودجەی مانگانە پاشەکەوتکرا');
          _load();
          return true;
        }
        setError(AdminUi.readError(res));
        return false;
      },
    );
  }

  Future<void> _openExpenseForm({Map<String, dynamic>? existing}) async {
    final isEdit = existing != null;
    final titleCtrl = TextEditingController(text: existing?['title']?.toString() ?? '');
    final initialAmount = existing != null ? _num(existing['amount']) : 0.0;
    final amountCtrl = TextEditingController(
      text: initialAmount > 0 ? initialAmount.toStringAsFixed(0) : '',
    );
    final notesCtrl = TextEditingController(text: existing?['notes']?.toString() ?? '');

    String category = existing?['category']?.toString() ?? 'salaries';
    if (!_categories.any((c) => c.id == category)) {
      category = 'other';
    }

    DateTime selectedDate = DateTime.now();
    if (existing != null && existing['expense_date'] != null) {
      selectedDate = DateTime.tryParse(existing['expense_date'].toString())?.toLocal() ?? DateTime.now();
    } else if (!_allTime && !_isCurrentMonth) {
      selectedDate = DateTime(_period.year, _period.month, 1);
    }

    String? pickedFilePath;
    final String existingReceiptUrl = ApiClient.getImageUrl(
      (existing?['receipt_url'] ?? existing?['receipt_path'])?.toString(),
    );
    bool removeExistingReceipt = false;

    await _showAdaptiveSheet(
      title: isEdit ? 'دەستکاریکردنی خەرجی' : 'تۆمارکردنی خەرجی نوێ',
      subtitle: 'خەرجییەکان پۆلێن بکە بۆ چاودێری وردی بودجە و قازانجی پوخت',
      submitLabel: isEdit ? 'نوێکردنەوە' : 'تۆمارکردن',
      builder: (setSheetState, setError) {
        final picker = ImagePicker();

        Future<void> pickImage(ImageSource source) async {
          try {
            final file = await picker.pickImage(source: source, imageQuality: 85, maxWidth: 1600);
            if (file != null) {
              setSheetState(() {
                pickedFilePath = file.path;
                removeExistingReceipt = false;
              });
            }
          } catch (e) {
            setError('نەتوانرا وێنە هەڵبژێردرێت: $e');
          }
        }

        final hasExistingReceipt = existingReceiptUrl.isNotEmpty && !removeExistingReceipt && pickedFilePath == null;

        return [
          TextField(
            controller: titleCtrl,
            style: TextStyle(fontFamily: _font, color: AppColors.getTextTitle(context)),
            decoration: _inputDecoration('ناونیشانی خەرجی'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: category,
            dropdownColor: AppColors.getSurface(context),
            style: TextStyle(fontFamily: _font, fontSize: 13.5, color: AppColors.getTextTitle(context)),
            decoration: _inputDecoration('پۆلێنی خەرجی'),
            items: _categories.map((c) {
              return DropdownMenuItem(
                value: c.id,
                child: Row(
                  children: [
                    Icon(c.icon, size: 17, color: c.color),
                    const SizedBox(width: 8),
                    Text(c.label, style: const TextStyle(fontFamily: _font)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (v) => setSheetState(() => category = v ?? 'salaries'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(fontFamily: _font, color: AppColors.getTextTitle(context)),
            decoration: _inputDecoration('بڕی خەرجی (دینار)', suffix: 'د.ع'),
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2032),
                );
                if (picked != null) {
                  setSheetState(() => selectedDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: _isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.getBorder(context)),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.calendar, size: 20, color: _red),
                    const SizedBox(width: 10),
                    Text('بەروار: ', style: AdminUi.subtitle.copyWith(fontSize: 13)),
                    Directionality(
                      textDirection: ui.TextDirection.ltr,
                      child: Text(
                        DateFormat('yyyy-MM-dd').format(selectedDate),
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextTitle(context),
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: notesCtrl,
            maxLines: 2,
            style: TextStyle(fontFamily: _font, color: AppColors.getTextTitle(context)),
            decoration: _inputDecoration('تێبینی زیاتر (ئارەزوومەندانە)'),
          ),
          const SizedBox(height: 14),
          // Receipt attachment section
          Text('وەسڵ یان پسوولە (ئارەزوومەندانە)', style: AdminUi.subtitle.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (pickedFilePath != null)
            _receiptPreviewTile(
              child: Image.file(File(pickedFilePath!), height: 110, width: double.infinity, fit: BoxFit.cover),
              label: 'وێنەی نوێ هەڵبژێردرا',
              onRemove: () => setSheetState(() => pickedFilePath = null),
            )
          else if (hasExistingReceipt)
            _receiptPreviewTile(
              child: existingReceiptUrl.toLowerCase().endsWith('.pdf')
                  ? Container(
                      height: 70,
                      alignment: Alignment.center,
                      child: const Icon(Iconsax.document_text, size: 32, color: _red),
                    )
                  : CachedNetworkImage(
                      imageUrl: existingReceiptUrl,
                      height: 110,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => const SizedBox(height: 60, child: Icon(Iconsax.receipt_2)),
                    ),
              label: 'وەسڵی پێشوو',
              onRemove: () => setSheetState(() => removeExistingReceipt = true),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => pickImage(ImageSource.gallery),
                    icon: const Icon(Iconsax.gallery, size: 17),
                    label: const Text('لە گەلەری', style: TextStyle(fontFamily: _font, fontSize: 12.5)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => pickImage(ImageSource.camera),
                    icon: const Icon(Iconsax.camera, size: 17),
                    label: const Text('کامێرا', style: TextStyle(fontFamily: _font, fontSize: 12.5)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
        ];
      },
      onSubmit: (setError) async {
        final amount = double.tryParse(amountCtrl.text.trim().replaceAll(',', '')) ?? 0;
        if (titleCtrl.text.trim().isEmpty || amount <= 0) {
          setError('تکایە ناونیشان و بڕێکی دروست بنووسە');
          return false;
        }

        final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
        final http.Response res;

        if (pickedFilePath != null) {
          res = await ApiClient.uploadMultipart(
            isEdit ? '/admin/expenses/${existing['id']}' : '/admin/expenses',
            method: 'POST',
            fields: {
              if (isEdit) '_method': 'PUT',
              'title': titleCtrl.text.trim(),
              'category': category,
              'amount': amount.toString(),
              'expense_date': formattedDate,
              'notes': notesCtrl.text.trim(),
            },
            fileField: 'receipt',
            filePath: pickedFilePath,
          );
        } else {
          final body = {
            'title': titleCtrl.text.trim(),
            'category': category,
            'amount': amount,
            'expense_date': formattedDate,
            'notes': notesCtrl.text.trim(),
            if (isEdit && removeExistingReceipt) 'remove_receipt': true,
          };
          res = isEdit
              ? await ApiClient.put('/admin/expenses/${existing['id']}', body: body)
              : await ApiClient.post('/admin/expenses', body: body);
        }

        if (!mounted) return true;
        if (res.statusCode == 200 || res.statusCode == 201) {
          AdminUi.toast(context, isEdit ? 'خەرجی نوێکرایەوە' : 'خەرجی تۆمارکرا');
          _load();
          return true;
        } else {
          setError(AdminUi.readError(res));
          return false;
        }
      },
    );
  }

  Widget _receiptPreviewTile({
    required Widget child,
    required String label,
    required VoidCallback onRemove,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          child,
          Container(
            color: _isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                const Icon(Iconsax.receipt_2, size: 16, color: _green),
                const SizedBox(width: 6),
                Expanded(child: Text(label, style: AdminUi.subtitle.copyWith(fontSize: 12))),
                TextButton(
                  onPressed: onRemove,
                  child: const Text('لابردن', style: TextStyle(fontFamily: _font, color: _red, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openExpenseDetails(Map<String, dynamic> item) {
    final cat = _categoryMeta(item['category']?.toString());
    final dateStr = _formatExpenseDate(item['expense_date']);
    final notes = (item['notes'] ?? '').toString().trim();
    final creator = item['creator'] is Map ? (item['creator']['name'] ?? '').toString().trim() : '';
    final receiptUrl = ApiClient.getImageUrl((item['receipt_url'] ?? item['receipt_path'])?.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          MediaQuery.viewPaddingOf(ctx).bottom + 20,
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
                  decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(cat.icon, color: cat.color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['title']?.toString() ?? '', style: AdminUi.title.copyWith(fontSize: 16)),
                        const SizedBox(height: 4),
                        AdminUi.chip(cat.label, cat.color),
                      ],
                    ),
                  ),
                  Directionality(
                    textDirection: ui.TextDirection.ltr,
                    child: Text(
                      _formatIqd(item['amount']),
                      style: const TextStyle(fontFamily: _font, fontSize: 17, fontWeight: FontWeight.bold, color: _red),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _detailRow(Iconsax.calendar, 'بەرواری خەرجی', dateStr, isLtrValue: true),
              if (creator.isNotEmpty)
                _detailRow(Iconsax.user, 'تۆمارکراوە لەلایەن', creator),
              if (notes.isNotEmpty)
                _detailRow(Iconsax.note_1, 'تێبینی', notes),
              if (receiptUrl.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('وەسڵ / پسوولە', style: AdminUi.subtitle.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _openReceiptViewer(receiptUrl),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.getBorder(context)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: receiptUrl.toLowerCase().endsWith('.pdf')
                        ? ListTile(
                            leading: const Icon(Iconsax.document_text, color: _red),
                            title: Text('کردنەوەی فایلی PDF وەسڵ', style: AdminUi.title),
                            trailing: const Icon(Icons.open_in_new, size: 18),
                          )
                        : Stack(
                            alignment: Alignment.bottomLeft,
                            children: [
                              CachedNetworkImage(
                                imageUrl: receiptUrl,
                                height: 170,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorWidget: (_, _, _) => const SizedBox(
                                  height: 90,
                                  child: Center(child: Icon(Iconsax.receipt_2, size: 32)),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'داگرە بۆ بینینی تەواو',
                                  style: TextStyle(fontFamily: _font, fontSize: 11, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openExpenseForm(existing: item);
                      },
                      icon: const Icon(Iconsax.edit_2, size: 17, color: _blue),
                      label: const Text('دەستکاریکردن', style: TextStyle(fontFamily: _font, color: _blue, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: _blue),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _deleteExpense(item);
                      },
                      icon: const Icon(Iconsax.trash, size: 17, color: Colors.white),
                      label: const Text('سڕینەوە', style: TextStyle(fontFamily: _font, color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _red,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {bool isLtrValue = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: _accent),
          const SizedBox(width: 8),
          Text('$label: ', style: AdminUi.subtitle),
          Expanded(
            child: Directionality(
              textDirection: isLtrValue ? ui.TextDirection.ltr : Directionality.of(context),
              child: Text(
                value,
                textAlign: isLtrValue ? TextAlign.end : TextAlign.start,
                style: AdminUi.title.copyWith(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openReceiptViewer(String url) async {
    if (url.toLowerCase().endsWith('.pdf')) {
      final uri = Uri.tryParse(url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  errorWidget: (_, _, _) => const Icon(Icons.broken_image, color: Colors.white, size: 48),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {String? suffix}) {
    return InputDecoration(
      labelText: label,
      suffixText: suffix,
      labelStyle: AdminUi.subtitle,
      filled: true,
      fillColor: _isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.getBorder(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.getBorder(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _blue, width: 1.5),
      ),
    );
  }

  Future<void> _showAdaptiveSheet({
    required String title,
    required String subtitle,
    required String submitLabel,
    required List<Widget> Function(void Function(VoidCallback) setSheetState, void Function(String?) setError) builder,
    required Future<bool> Function(void Function(String?) setError) onSubmit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      builder: (ctx) {
        String? errorMessage;
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            void setError(String? message) => setSheetState(() => errorMessage = message);

            return Container(
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.viewPaddingOf(context).bottom + 20,
                left: 20,
                right: 20,
                top: 12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: _isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.getBorder(context)),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.getTextTitle(context)),
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: AdminUi.title.copyWith(fontSize: 17)),
                            const SizedBox(height: 4),
                            Text(subtitle, style: AdminUi.subtitle.copyWith(fontSize: 11.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...builder(setSheetState, setError),
                          const SizedBox(height: 18),
                          if (errorMessage != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _red.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _red.withValues(alpha: 0.35)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, size: 18, color: _red),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      errorMessage!,
                                      style: const TextStyle(fontFamily: _font, fontSize: 12, color: _red),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _blue,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      setSheetState(() {
                                        errorMessage = null;
                                        isSubmitting = true;
                                      });
                                      bool shouldClose = false;
                                      try {
                                        shouldClose = await onSubmit(setError);
                                      } catch (e) {
                                        setError('کێشەیەک لە پەیوەندی هەیە: $e');
                                      }
                                      if (!ctx.mounted) return;
                                      setSheetState(() => isSubmitting = false);
                                      if (shouldClose) Navigator.of(ctx).pop();
                                    },
                              child: isSubmitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                    )
                                  : Text(
                                      submitLabel,
                                      style: const TextStyle(
                                        fontFamily: _font,
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AdminAppBar(
        title: 'بودجە و خەرجییەکان',
        subtitle: 'چاودێریکردنی بودجەی گشتی و قازانجی پوخت',
        icon: Iconsax.moneys,
        iconColor: _accent,
        iconBackgroundColor: _accent.withValues(alpha: 0.1),
        showBackButton: true,
        actions: [
          IconButton(
            onPressed: () => _openExpenseForm(),
            icon: const Icon(Icons.add_circle_outline, color: _accent, size: 26),
            tooltip: 'تۆمارکردنی خەرجی',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPeriodSelector(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? AdminUi.body(
                        isLoading: false,
                        error: _error,
                        isEmpty: false,
                        emptyIcon: Iconsax.moneys,
                        emptyText: '',
                        onRetry: _load,
                        child: const SizedBox.shrink(),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                          children: [
                            _buildBalanceBanner(),
                            if (!_allTime) ...[
                              const SizedBox(height: 12),
                              _buildBudgetCard(),
                            ],
                            if ((_summary['by_category'] as List?)?.isNotEmpty ?? false) ...[
                              const SizedBox(height: 16),
                              _buildCategoryBreakdown(),
                            ],
                            const SizedBox(height: 18),
                            _buildSearchAndFilters(),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('تۆماری خەرجییەکان', style: AdminUi.title),
                                Text('$_totalExpensesCount خەرجی', style: AdminUi.subtitle),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (_expenses.isEmpty)
                              _buildEmptyExpenses()
                            else ...[
                              ..._expenses.map(_buildExpenseCard),
                              if (_currentPage < _lastPage) _buildLoadMoreButton(),
                            ],
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: AdminUi.cardDecoration,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _isLoading ? null : () => _shiftMonth(-1),
                    icon: const Icon(Icons.chevron_right_rounded),
                    tooltip: 'مانگی پێشوو',
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: _allTime
                          ? () {
                              setState(() => _allTime = false);
                              _load();
                            }
                          : null,
                      child: Column(
                        children: [
                          Directionality(
                            textDirection: ui.TextDirection.ltr,
                            child: Text(
                              _allTime ? 'هەموو کاتەکان' : _periodLabel,
                              style: AdminUi.title.copyWith(fontSize: 13.5),
                            ),
                          ),
                          Text(
                            _allTime
                                ? 'کۆی گشتی مێژوو'
                                : (_isCurrentMonth ? 'مانگی ئێستا' : 'مانگی ڕابردوو'),
                            style: AdminUi.subtitle.copyWith(fontSize: 10.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isLoading || (!_allTime && _isCurrentMonth) ? null : () => _shiftMonth(1),
                    icon: const Icon(Icons.chevron_left_rounded),
                    tooltip: 'مانگی دواتر',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _isLoading
                ? null
                : () {
                    setState(() => _allTime = !_allTime);
                    _load();
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
              decoration: BoxDecoration(
                color: _allTime ? _accent : AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _allTime ? _accent : AppColors.getBorder(context),
                ),
              ),
              child: Text(
                'هەموو کات',
                style: TextStyle(
                  fontFamily: _font,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _allTime ? Colors.white : AppColors.getTextTitle(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceBanner() {
    final totalExpenses = _num(_summary['total_expenses']);
    final netProfit = _num(_summary['net_profit']);
    final totalComm = _num(_summary['total_commission_revenue']);
    final grossVolume = _num(_summary['total_gross_volume']);
    final completedOrders = (_summary['completed_orders_count'] as num?)?.toInt() ?? 0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'قازانجی پوخت (داهاتی کۆمیشن - کۆی خەرجی)',
            style: TextStyle(fontFamily: _font, fontSize: 12.5, color: Colors.white.withValues(alpha: 0.72)),
          ),
          const SizedBox(height: 6),
          Directionality(
            textDirection: ui.TextDirection.ltr,
            child: Text(
              _formatIqd(netProfit),
              style: TextStyle(
                fontFamily: _font,
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: netProfit >= 0 ? _green : _red,
              ),
            ),
          ),
          const Divider(color: Colors.white24, height: 26),
          Row(
            children: [
              Expanded(
                child: _bannerStat(
                  'داهاتی کۆمیشن',
                  _formatIqd(totalComm),
                  Colors.white,
                ),
              ),
              Container(width: 1, height: 32, color: Colors.white24),
              Expanded(
                child: _bannerStat(
                  'کۆی گشتی خەرجی',
                  _formatIqd(totalExpenses),
                  _accent,
                ),
              ),
              Container(width: 1, height: 32, color: Colors.white24),
              Expanded(
                child: _bannerStat(
                  'فرۆشی گشتی ($completedOrders)',
                  _formatIqd(grossVolume),
                  const Color(0xFF38BDF8),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 240.ms);
  }

  Widget _bannerStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontFamily: _font, fontSize: 10.5, color: Colors.white.withValues(alpha: 0.65)),
        ),
        const SizedBox(height: 4),
        Directionality(
          textDirection: ui.TextDirection.ltr,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetCard() {
    final budget = _num(_summary['monthly_budget']);
    final totalExpenses = _num(_summary['total_expenses']);
    final remaining = _num(_summary['budget_remaining']);
    final pct = _num(_summary['budget_used_percent']);

    final progress = budget > 0 ? (totalExpenses / budget).clamp(0.0, 1.0) : 0.0;
    final barColor = pct >= 100
        ? _red
        : (pct >= 75 ? _amber : _green);

    return Container(
      decoration: AdminUi.cardDecoration,
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: barColor.withValues(alpha: 0.12),
                child: Icon(Iconsax.wallet_check, size: 18, color: barColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('بودجەی مانگانە ($_periodLabel)', style: AdminUi.title.copyWith(fontSize: 13.5)),
                    Text(
                      budget > 0
                          ? 'سنووری دیاریکراو: ${_formatIqd(budget)}'
                          : 'هیچ سنوورێک بۆ بودجەی ئەم مانگە دیارینەکراوە',
                      style: AdminUi.subtitle.copyWith(fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _openBudgetDialog,
                icon: const Icon(Iconsax.edit_2, size: 15, color: _blue),
                label: Text(
                  budget > 0 ? 'گۆڕین' : 'دیاریکردن',
                  style: const TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.bold, color: _blue),
                ),
              ),
            ],
          ),
          if (budget > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 9,
                backgroundColor: barColor.withValues(alpha: 0.14),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'بەکارهاتوو: ${pct.toStringAsFixed(0)}%',
                  style: TextStyle(fontFamily: _font, fontSize: 11.5, fontWeight: FontWeight.bold, color: barColor),
                ),
                Text(
                  remaining >= 0
                      ? 'ماوە: ${_formatIqd(remaining)}'
                      : 'تێپەڕینی بودجە: ${_formatIqd(remaining.abs())}',
                  style: AdminUi.subtitle.copyWith(
                    fontSize: 11.5,
                    color: remaining < 0 ? _red : null,
                    fontWeight: remaining < 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    final byCat = (_summary['by_category'] as List?) ?? [];
    if (byCat.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: AdminUi.cardDecoration,
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Iconsax.chart_21, size: 18, color: _accent),
              const SizedBox(width: 8),
              Text('دابەشبوونی خەرجییەکان', style: AdminUi.title.copyWith(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          ...byCat.map((raw) {
            final row = raw is Map ? raw : {};
            final catId = row['category']?.toString() ?? 'other';
            final meta = _categoryMeta(catId);
            final amt = _num(row['total_amount']);
            final count = (row['count'] as num?)?.toInt() ?? 0;
            final pct = _num(row['percent']);
            final isSelected = _selectedCategory == catId;

            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                setState(() => _selectedCategory = isSelected ? 'all' : catId);
                _load();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(meta.icon, size: 15, color: meta.color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${meta.label} ($count)',
                            style: AdminUi.title.copyWith(
                              fontSize: 12.5,
                              color: isSelected ? _blue : null,
                            ),
                          ),
                        ),
                        Directionality(
                          textDirection: ui.TextDirection.ltr,
                          child: Text(
                            '${_formatIqd(amt)} • ${pct.toStringAsFixed(0)}%',
                            style: AdminUi.subtitle.copyWith(fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (pct / 100).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: meta.color.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(meta.color),
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

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        TextField(
          controller: _searchCtrl,
          onChanged: _onSearchChanged,
          style: TextStyle(fontFamily: _font, fontSize: 13, color: AppColors.getTextTitle(context)),
          decoration: InputDecoration(
            hintText: 'گەڕان لە ناونیشان یان تێبینی خەرجی...',
            hintStyle: AdminUi.subtitle.copyWith(fontSize: 12.5),
            prefixIcon: const Icon(Iconsax.search_normal, size: 18),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      _load();
                    },
                  )
                : null,
            filled: true,
            fillColor: AppColors.getSurface(context),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _categoryFilterChip('all', 'هەموو'),
              ..._categories.map((c) => _categoryFilterChip(c.id, c.label)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _categoryFilterChip(String id, String label) {
    final selected = _selectedCategory == id;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        selected: selected,
        label: Text(
          label,
          style: TextStyle(
            fontFamily: _font,
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.bold : FontWeight.w600,
            color: selected ? Colors.white : AppColors.getTextTitle(context),
          ),
        ),
        selectedColor: _accent,
        backgroundColor: AppColors.getSurface(context),
        side: BorderSide(color: selected ? _accent : AppColors.getBorder(context)),
        onSelected: (_) {
          if (_selectedCategory != id) {
            setState(() => _selectedCategory = id);
            _load();
          }
        },
      ),
    );
  }

  Widget _buildEmptyExpenses() {
    return Container(
      decoration: AdminUi.cardDecoration,
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
      child: Column(
        children: [
          Icon(Iconsax.receipt_disscount, size: 44, color: Colors.grey.withValues(alpha: 0.5)),
          const SizedBox(height: 10),
          Text('هیچ خەرجییەک بۆ ئەم ماوەیە نەدۆزرایەوە', style: AdminUi.subtitle),
          const SizedBox(height: 14),
          AdminUi.primaryAction(
            label: 'تۆمارکردنی خەرجی نوێ',
            icon: Icons.add,
            color: _accent,
            onTap: () => _openExpenseForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(Map<String, dynamic> e) {
    final meta = _categoryMeta(e['category']?.toString());
    final dateStr = _formatExpenseDate(e['expense_date']);
    final hasNotes = (e['notes'] ?? '').toString().trim().isNotEmpty;
    final hasReceipt = ((e['receipt_url'] ?? e['receipt_path']) ?? '').toString().trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AdminUi.cardDecoration,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openExpenseDetails(e),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: meta.color.withValues(alpha: 0.13),
                child: Icon(meta.icon, color: meta.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e['title']?.toString() ?? '', style: AdminUi.title),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            meta.label,
                            overflow: TextOverflow.ellipsis,
                            style: AdminUi.subtitle.copyWith(fontSize: 11),
                          ),
                        ),
                        if (dateStr.isNotEmpty) ...[
                          Text(' • ', style: AdminUi.subtitle.copyWith(fontSize: 11)),
                          Directionality(
                            textDirection: ui.TextDirection.ltr,
                            child: Text(
                              dateStr,
                              style: AdminUi.subtitle.copyWith(fontSize: 11),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (hasNotes || hasReceipt) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (hasNotes) ...[
                            const Icon(Iconsax.note_1, size: 12, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text('تێبینی', style: AdminUi.subtitle.copyWith(fontSize: 10)),
                            const SizedBox(width: 10),
                          ],
                          if (hasReceipt) ...[
                            const Icon(Iconsax.receipt_2, size: 12, color: _green),
                            const SizedBox(width: 4),
                            Text('وەسڵ', style: AdminUi.subtitle.copyWith(fontSize: 10, color: _green)),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Directionality(
                    textDirection: ui.TextDirection.ltr,
                    child: Text(
                      _formatIqd(e['amount']),
                      style: const TextStyle(
                        fontFamily: _font,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: _red,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _openExpenseForm(existing: e),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Iconsax.edit_2, color: _blue, size: 17),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => _deleteExpense(e),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Iconsax.trash, color: Colors.grey, size: 17),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: OutlinedButton(
        onPressed: _isLoadingMore ? null : _loadMore,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isLoadingMore
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('پیشاندانی زیاتر', style: TextStyle(fontFamily: _font, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
