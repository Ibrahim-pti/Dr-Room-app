import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/medical_report_pdf_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_client.dart';
import 'admin_app_bar.dart';
import 'admin_ui.dart';

class AdminLabResultsScreen extends StatefulWidget {
  const AdminLabResultsScreen({super.key});

  @override
  State<AdminLabResultsScreen> createState() => _AdminLabResultsScreenState();
}

class _AdminLabResultsScreenState extends State<AdminLabResultsScreen> {
  List<dynamic> _results = [];
  Map<String, dynamic> _branding = {};
  bool _isLoading = true;
  bool _isExporting = false;
  String? _error;
  String _filter = '';

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

    try {
      final query = _filter.isNotEmpty ? '?status=$_filter' : '';
      final res = await ApiClient.get('/admin/lab-results$query');
      if (!mounted) return;

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body['data'];
        setState(() {
          _results = data is Map ? (data['data'] ?? []) : (data ?? []);
          if (body['branding'] is Map) {
            _branding = Map<String, dynamic>.from(body['branding']);
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = AdminUi.readError(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _isLoading = false; });
    }
  }

  Future<void> _openOfficialPdf(dynamic item) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      await MedicalReportPdfService.previewAndPrint(
        context,
        result: Map<String, dynamic>.from(item as Map),
        branding: _branding,
      );
    } catch (e) {
      if (mounted) {
        AdminUi.toast(context, 'کێشە لە دروستکردنی PDF: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _openFile(String? path) async {
    if (path == null || path.isEmpty) {
      AdminUi.toast(context, 'فایلی PDF هێشتا لەلایەن تاقیگە ئەپلۆد نەکراوە', isError: true);
      return;
    }
    final url = ApiClient.getImageUrl(path);
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      AdminUi.toast(context, 'نەتوانرا فایلەکە بکرێتەوە', isError: true);
    }
  }

  Future<void> _verifyResult(dynamic item) async {
    try {
      final res = await ApiClient.patch('/admin/lab-results/${item['id']}/verify');
      if (!mounted) return;
      if (res.statusCode == 200) {
        AdminUi.toast(context, 'ئەنجامەکە وەک تەواوکراو پشتڕاستکرایەوە');
        _load();
      } else {
        AdminUi.toast(context, AdminUi.readError(res), isError: true);
      }
    } catch (e) {
      if (mounted) AdminUi.toast(context, 'کێشەیەک ڕوویدا: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AdminAppBar(
        title: 'چاودێری ئەنجامی پشکنینەکان',
        subtitle: 'دڵنیابوونەوە لە ناردنی دروستی PDF بۆ نەخۆش',
        icon: Iconsax.document_text,
        iconColor: const Color(0xFF0284C7),
        iconBackgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.1),
        showBackButton: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('', 'هەمووی'),
                const SizedBox(width: 8),
                _buildFilterChip('completed', 'نێردراوە (تەواو)'),
                const SizedBox(width: 8),
                _buildFilterChip('pending', 'چاوەڕوانە'),
              ],
            ),
          ),
          Expanded(
            child: AdminUi.body(
              isLoading: _isLoading,
              error: _error,
              isEmpty: _results.isEmpty,
              emptyIcon: Iconsax.document_code,
              emptyText: 'هیچ تۆمارێکی پشکنین نەدۆزرایەوە',
              onRetry: _load,
              child: RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _results.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final r = _results[index];
                                final hasFile = r['file_path'] != null && r['file_path'].toString().isNotEmpty;
                                final isCompleted = r['status'] == 'completed';
                                final lab = r['lab'] ?? {};
                                final patient = r['patient'] ?? {};
                                final test = r['test'] ?? {};

                                return Container(
                                  decoration: AdminUi.cardDecoration,
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              test['name'] ?? 'پشکنینی تاقیگە',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AdminUi.title.copyWith(fontSize: 15),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: (isCompleted ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
                                                  .withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              isCompleted ? 'ڕادەستکراوە' : 'لە چاوەڕوانیدایە',
                                              style: TextStyle(
                                                fontFamily: 'Rabar',
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isCompleted ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Iconsax.microscope, size: 14, color: Color(0xFF0284C7)),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              'تاقیگە: ${lab['user']?['name'] ?? lab['name'] ?? 'تاقیگەی گشتی'}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AdminUi.subtitle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Iconsax.user, size: 14, color: Color(0xFF64748B)),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              'نەخۆش: ${patient['name'] ?? 'نەناسراو'}',
                                              textAlign: TextAlign.end,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AdminUi.subtitle,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          ElevatedButton.icon(
                                            onPressed: _isExporting ? null : () => _openOfficialPdf(r),
                                            icon: const Icon(Iconsax.verify, size: 15),
                                            label: const Text('ڕاپۆرتی فەرمی (PDF)', style: TextStyle(fontFamily: 'Rabar', fontSize: 11.5, fontWeight: FontWeight.bold)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF4F46E5),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              elevation: 0,
                                            ),
                                          ),
                                          if (hasFile) ...[
                                            const SizedBox(width: 6),
                                            IconButton(
                                              tooltip: 'فایلی بنەڕەتی',
                                              onPressed: () => _openFile(r['file_path']),
                                              icon: const Icon(Iconsax.document_download, size: 18, color: Color(0xFF0284C7)),
                                            ),
                                          ],
                                          const Spacer(),
                                          if (!isCompleted)
                                            ElevatedButton(
                                              onPressed: () => _verifyResult(r),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF10B981),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                              child: const Text('پشتڕاستکردنەوە', style: TextStyle(fontFamily: 'Rabar', fontSize: 12)),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ).animate().fadeIn(duration: 200.ms);
                              },
                            ),
                          ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filter == value;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontFamily: 'Rabar', fontSize: 12)),
      selected: isSelected,
      selectedColor: const Color(0xFF0284C7),
      labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF64748B)),
      onSelected: (_) {
        setState(() => _filter = value);
        _load();
      },
    );
  }
}
