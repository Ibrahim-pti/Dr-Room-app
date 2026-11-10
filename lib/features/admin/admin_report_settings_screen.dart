import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
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
  bool _isSaving = false;
  String? _error;

  final _titleCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  final _footerCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _showWatermark = true;
  bool _showStamp = true;
  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _footerCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
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
          _titleCtrl.text = data['header_title'] ?? 'دکتۆر ڕۆم - دۆسیەی پزیشکی و ئەنجامی پشکنین';
          _subtitleCtrl.text = data['header_subtitle'] ?? 'Dr. Room Healthcare System & Lab Diagnostics';
          _footerCtrl.text = data['footer_text'] ?? 'ئەم ڕاپۆرتە بە فەرمی لەلایەن تاقیگەی باوەڕپێکراو پەسەندکراوە و پارێزراوە بە مۆری ئەلیکترۆنی.';
          final rawPhone = (data['emergency_phone'] ?? '+964 750 000 0000').toString();
          _phoneCtrl.text = _cleanPhone(rawPhone);
          _showWatermark = data['show_watermark'] ?? true;
          _showStamp = data['show_stamp'] ?? true;
          _logoUrl = data['logo_url']?.toString();
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

  String _cleanPhone(String raw) {
    return raw
        .replaceAll('\u200E', '')
        .replaceAll('\u200F', '')
        .replaceAll('\u202A', '')
        .replaceAll('\u202B', '')
        .replaceAll('\u202C', '')
        .trim();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final res = await ApiClient.post('/admin/report-settings', body: {
        'header_title': _titleCtrl.text.trim(),
        'header_subtitle': _subtitleCtrl.text.trim(),
        'footer_text': _footerCtrl.text.trim(),
        'emergency_phone': _cleanPhone(_phoneCtrl.text),
        'show_watermark': _showWatermark,
        'show_stamp': _showStamp,
      });

      if (!mounted) return;

      if (res.statusCode == 200) {
        AdminUi.toast(context, 'ڕێکخستن و قالبی ڕاپۆرت بە سەرکەوتوویی نوێکرایەوە');
      } else {
        AdminUi.toast(context, AdminUi.readError(res), isError: true);
      }
    } catch (e) {
      if (mounted) AdminUi.toast(context, '$e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Iconsax.info_circle, size: 48, color: Colors.amber),
                        const SizedBox(height: 12),
                        Text(_error!, style: AdminUi.subtitle, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('دووبارە هەوڵبدەرەوە', style: TextStyle(fontFamily: 'Rabar')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section Header: Live Preview
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Iconsax.eye, size: 16, color: Color(0xFF6366F1)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('پێشبینینی ڕاستەوخۆی قالبی فەرمی (Live Preview)', style: AdminUi.title),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Premium Medical Document Preview
                      _buildDocumentPreview(isDark).animate().fadeIn(duration: 250.ms),

                      const SizedBox(height: 24),

                      // Section Header: Header Details
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Iconsax.edit_2, size: 16, color: Color(0xFF3B82F6)),
                          ),
                          const SizedBox(width: 8),
                          Text('سەرپەڕە و دەقە فەرمییەکان', style: AdminUi.title),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Main Form Card
                      Container(
                        decoration: AdminUi.cardDecoration,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputField(
                              label: 'سەرناوی فەرمی سەرپەڕەی ڕاپۆرت',
                              hint: 'دکتۆر ڕۆم - دۆسیەی پزیشکی و ئەنجامی پشکنین',
                              icon: Iconsax.document_text,
                              controller: _titleCtrl,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 14),
                            _buildInputField(
                              label: 'سەردێڕی دووەم (ئینگلیزی / پۆلێن)',
                              hint: 'Dr. Room Healthcare System & Lab Diagnostics',
                              icon: Iconsax.text_block,
                              controller: _subtitleCtrl,
                              isDark: isDark,
                              textDirection: TextDirection.ltr,
                            ),
                            const SizedBox(height: 14),
                            _buildInputField(
                              label: 'ژمارەی پەیوەندی و فریاکەوتن',
                              hint: '+964 750 000 0000',
                              icon: Iconsax.call,
                              controller: _phoneCtrl,
                              isDark: isDark,
                              keyboardType: TextInputType.phone,
                              textDirection: TextDirection.ltr,
                            ),
                            const SizedBox(height: 14),
                            _buildInputField(
                              label: 'دەقی خوارەوەی ڕاپۆرت (تێبینی و گەرەنتی)',
                              hint: 'ئەم ڕاپۆرتە بە فەرمی لەلایەن تاقیگەی باوەڕپێکراو پەسەندکراوە...',
                              icon: Iconsax.note_text,
                              controller: _footerCtrl,
                              isDark: isDark,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 300.ms),

                      const SizedBox(height: 24),

                      // Section Header: Stamps & Security
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Iconsax.shield_tick, size: 16, color: Color(0xFF10B981)),
                          ),
                          const SizedBox(width: 8),
                          Text('مۆر و ئاسایشی بەڵگەنامەکان', style: AdminUi.title),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Switches Card (Uses pure custom widgets to prevent any ListTile assertions!)
                      Container(
                        decoration: AdminUi.cardDecoration,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          children: [
                            _buildCustomSwitchTile(
                              title: 'پیشاندانی مۆری ئەلیکترۆنی لەسەر فایلی ڕاپۆرت',
                              subtitle: 'مۆری فەرمی پەسەندکراو بە سەوزی لە گۆشەی سەرەوە چاپ دەکرێت',
                              icon: Iconsax.verify,
                              iconColor: const Color(0xFF10B981),
                              value: _showStamp,
                              onChanged: (v) => setState(() => _showStamp = v),
                              isDark: isDark,
                            ),
                            Divider(height: 20, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                            _buildCustomSwitchTile(
                              title: 'پیشاندانی Watermark لە پاشبنەمای پەڕە',
                              subtitle: 'بۆ پاراستنی ڕاپۆرت لە ساختەکاری و کۆپیکردنی دەستکاری کراو',
                              icon: Iconsax.security_safe,
                              iconColor: const Color(0xFF6366F1),
                              value: _showWatermark,
                              onChanged: (v) => setState(() => _showWatermark = v),
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 350.ms),

                      const SizedBox(height: 28),

                      // Full-width Luxury Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shadowColor: const Color(0xFF6366F1).withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Iconsax.tick_circle, size: 20),
                                    SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'پاشەکەوتکردنی ڕێکخستنەکان',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontFamily: 'Rabar', fontSize: 15, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  /// Modern Interactive Medical Document Preview Card
  Widget _buildDocumentPreview(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Subtle Watermark Simulation
          if (_showWatermark)
            Positioned.fill(
              child: Center(
                child: Opacity(
                  opacity: isDark ? 0.05 : 0.04,
                  child: Transform.rotate(
                    angle: -0.25,
                    child: const Text(
                      'DR. ROOM VERIFIED OFFICIAL',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top luxury gradient bar
              Container(
                height: 6,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Official Header Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Official Dr. Room Logo
                        Builder(
                          builder: (context) {
                            final remoteLogo = ApiClient.getImageProvider(_logoUrl);
                            return Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6366F1).withValues(alpha: 0.16),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: remoteLogo != null
                                    ? Image(
                                        image: remoteLogo,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Image.asset(
                                          'assets/images/app_icon.png',
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Image.asset(
                                        'assets/images/app_icon.png',
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => const Icon(
                                          Icons.local_hospital_rounded,
                                          color: Color(0xFF6366F1),
                                          size: 28,
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),

                        // Title & Subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _titleCtrl.text.isNotEmpty
                                    ? _titleCtrl.text
                                    : 'دکتۆر ڕۆم - دۆسیەی پزیشکی و ئەنجامی پشکنین',
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _subtitleCtrl.text.isNotEmpty
                                    ? _subtitleCtrl.text
                                    : 'Dr. Room Healthcare System & Lab Diagnostics',
                                textDirection: TextDirection.ltr,
                                textAlign: Directionality.of(context) == TextDirection.rtl
                                    ? TextAlign.right
                                    : TextAlign.left,
                                style: const TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Official Stamp Seal
                        if (_showStamp)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF10B981), width: 1.2),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Iconsax.verify, color: Color(0xFF10B981), size: 13),
                                SizedBox(width: 4),
                                Text(
                                  'پەسەندکراوە',
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                    const SizedBox(height: 12),

                    // Phone & Guarantee Footer
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          ),
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Iconsax.call, size: 13, color: Color(0xFF6366F1)),
                                const SizedBox(width: 6),
                                Text(
                                  '\u200E${_cleanPhone(_phoneCtrl.text).isNotEmpty ? _cleanPhone(_phoneCtrl.text) : '+964 750 000 0000'}',
                                  textDirection: TextDirection.ltr,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 8),
                        const Flexible(
                          child: Text(
                            'مۆری دیجیتاڵی فەرمی',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: 'Rabar', fontSize: 10.5, color: Color(0xFF94A3B8)),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    Text(
                      _footerCtrl.text.isNotEmpty
                          ? _footerCtrl.text
                          : 'ئەم ڕاپۆرتە بە فەرمی لەلایەن تاقیگەی باوەڕپێکراو پەسەندکراوە و پارێزراوە بە مۆری ئەلیکترۆنی.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 10.5,
                        height: 1.4,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Modern Form Input Field with Icon Badge
  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required bool isDark,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    TextDirection? textDirection,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Rabar',
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Directionality(
            textDirection: textDirection ?? Directionality.of(context),
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              keyboardType: keyboardType,
              textDirection: textDirection,
              textAlign: textDirection == TextDirection.ltr ? TextAlign.left : TextAlign.right,
              onChanged: (_) => setState(() {}),
              style: textDirection == TextDirection.ltr
                  ? GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    )
                  : TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
              decoration: InputDecoration(
                hintText: hint,
                hintTextDirection: textDirection,
                hintStyle: const TextStyle(fontFamily: 'Rabar', fontSize: 12, color: Color(0xFF94A3B8)),
                prefixIcon: Icon(icon, size: 20, color: const Color(0xFF6366F1)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Custom Switch Tile without ListTile to prevent any DecoratedBox assertions
  Widget _buildCustomSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            activeTrackColor: iconColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
