import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _isLoading = true;
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

  Future<void> _openFile(String? path) async {
    if (path == null || path.isEmpty) {
      AdminUi.toast(context, 'فایلی PDF هێشتا لەلایەن تاقیگە ئەپلۆد نەکراوە', isError: true);
      return;
    }
    final url = ApiClient.getImageUrl(path);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _verifyResult(dynamic item) async {
    try {
      final res = await ApiClient.patch('/admin/lab-results/${item['id']}/verify');
      if (res.statusCode == 200) {
        if (mounted) AdminUi.toast(context, 'ئەنجامەکە وەک تەواوکراو پشتڕاستکرایەوە');
        _load();
      }
    } catch (_) {}
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: AdminUi.subtitle))
                    : _results.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Iconsax.document_code, size: 54, color: Color(0xFF94A3B8)),
                                const SizedBox(height: 12),
                                Text('هیچ تۆمارێکی پشکنین نەدۆزرایەوە', style: AdminUi.title),
                              ],
                            ),
                          )
                        : RefreshIndicator(
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
                                          Text(
                                            test['name'] ?? 'پشکنینی تاقیگە',
                                            style: AdminUi.title.copyWith(fontSize: 15),
                                          ),
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
                                          Text('تاقیگە: ${lab['name'] ?? 'تاقیگەی گشتی'}', style: AdminUi.subtitle),
                                          const Spacer(),
                                          const Icon(Iconsax.user, size: 14, color: Color(0xFF64748B)),
                                          const SizedBox(width: 4),
                                          Text('نەخۆش: ${patient['name'] ?? 'نەناسراو'}', style: AdminUi.subtitle),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          OutlinedButton.icon(
                                            onPressed: hasFile ? () => _openFile(r['file_path']) : null,
                                            icon: Icon(hasFile ? Iconsax.document_download : Iconsax.document, size: 16),
                                            label: Text(hasFile ? 'بینینی فایلی PDF' : 'فایل بارنەکراوە', style: const TextStyle(fontFamily: 'Rabar', fontSize: 12)),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: hasFile ? const Color(0xFF0284C7) : Colors.grey,
                                            ),
                                          ),
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
