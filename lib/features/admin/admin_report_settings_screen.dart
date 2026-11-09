import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/api_client.dart';
import 'admin_app_bar.dart';
import 'admin_ui.dart';

class AdminReportSettingsScreen extends StatefulWidget {
  const AdminReportSettingsScreen({super.key});

  @override
  State<AdminReportSettingsScreen> createState() => _AdminReportSettingsScreenState();
}

class _AdminReportSettingsScreenState extends State<AdminReportSettingsScreen> {
  bool _isLoading = true;
  String? _error;

  final _titleCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  final _footerCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _showWatermark = true;
  bool _showStamp = true;

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
      final res = await ApiClient.get('/admin/report-settings');
      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'] ?? {};
        setState(() {
          _titleCtrl.text = data['header_title'] ?? '';
          _subtitleCtrl.text = data['header_subtitle'] ?? '';
          _footerCtrl.text = data['footer_text'] ?? '';
          _phoneCtrl.text = data['emergency_phone'] ?? '';
          _showWatermark = data['show_watermark'] ?? true;
          _showStamp = data['show_stamp'] ?? true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'کێشە لە بارکردنی ڕێکخستنی ڕاپۆرت ڕوویدا';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _isLoading = false; });
    }
  }

  Future<void> _save() async {
    try {
      final res = await ApiClient.post('/admin/report-settings', body: {
        'header_title': _titleCtrl.text.trim(),
        'header_subtitle': _subtitleCtrl.text.trim(),
        'footer_text': _footerCtrl.text.trim(),
        'emergency_phone': _phoneCtrl.text.trim(),
        'show_watermark': _showWatermark,
        'show_stamp': _showStamp,
      });

      if (res.statusCode == 200) {
        if (mounted) AdminUi.toast(context, 'ڕێکخستن و قالبی ڕاپۆرت بە سەرکەوتوویی نوێکرایەوە');
      } else {
        if (mounted) AdminUi.toast(context, AdminUi.readError(res), isError: true);
      }
    } catch (e) {
      if (mounted) AdminUi.toast(context, '$e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AdminAppBar(
        title: 'دیزاین و قالبی ڕاپۆرتەکان',
        subtitle: 'ڕێکخستنی سەرپەڕە، لۆگۆ و مۆری فەرمی ئەنجامەکان',
        icon: Iconsax.document_filter,
        iconColor: const Color(0xFF6366F1),
        iconBackgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: AdminUi.subtitle))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Preview Box
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Image.asset('assets/images/logo.png', width: 44, height: 44, errorBuilder: (_, _, _) => const Icon(Icons.local_hospital, size: 40, color: Color(0xFF6366F1))),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _titleCtrl.text.isNotEmpty ? _titleCtrl.text : 'دکتۆر ڕۆم - ئەنجامی پشکنین',
                                        style: const TextStyle(fontFamily: 'Rabar', fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        _subtitleCtrl.text.isNotEmpty ? _subtitleCtrl.text : 'سیستەمی تەندروستی پێشکەوتوو',
                                        style: const TextStyle(fontFamily: 'Rabar', fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_showStamp)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('پەسەندکراوە', style: TextStyle(fontFamily: 'Rabar', fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                            const Divider(height: 24),
                            Text(
                              _footerCtrl.text.isNotEmpty ? _footerCtrl.text : 'ئەم ئەنجامە بە شێوازی ئەلیکترۆنی دەرکراوە.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontFamily: 'Rabar', fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 250.ms),

                      const SizedBox(height: 20),

                      // Form Settings
                      Container(
                        decoration: AdminUi.cardDecoration,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ڕێکخستنە سەرەکییەکان', style: AdminUi.title),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _titleCtrl,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(labelText: 'سەرناوی فەرمی سەرپەڕەی ڕاپۆرت'),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _subtitleCtrl,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(labelText: 'سەردێڕی دووەم (ئینگلیزی / کوردی)'),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _footerCtrl,
                              onChanged: (_) => setState(() {}),
                              maxLines: 2,
                              decoration: const InputDecoration(labelText: 'دەقی خوارەوەی ڕاپۆرت (تێبینی تاقیگە و گەرەنتی)'),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _phoneCtrl,
                              decoration: const InputDecoration(labelText: 'ژمارەی پەیوەندی و فریاکەوتن'),
                            ),
                            const Divider(height: 24),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('پیشاندانی مۆری ئەلیکترۆنی لەسەر فایلی ڕاپۆرت', style: TextStyle(fontFamily: 'Rabar', fontSize: 13)),
                              value: _showStamp,
                              onChanged: (v) => setState(() => _showStamp = v),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('پیشاندانی Watermark لە پاشبنەمای پەڕە', style: TextStyle(fontFamily: 'Rabar', fontSize: 13)),
                              value: _showWatermark,
                              onChanged: (v) => setState(() => _showWatermark = v),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('پاشەکەوتکردنی ڕێکخستنەکان', style: TextStyle(fontFamily: 'Rabar', fontSize: 14)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
