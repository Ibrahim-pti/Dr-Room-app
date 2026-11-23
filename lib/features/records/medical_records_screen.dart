import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/medical_report_pdf_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_client.dart';
import 'patient_emr_screen.dart';

class MedicalRecordsScreen extends StatefulWidget {
  final bool showBackButton;

  const MedicalRecordsScreen({super.key, this.showBackButton = false});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  bool _isLoading = true;
  List<dynamic> _labResults = [];
  List<dynamic> _nurseCares = [];
  Map<String, dynamic> _branding = {};
  String _selectedCategory = 'all';

  TextStyle _kStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color color = const Color(0xFF0F172A),
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'Rabar',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height ?? 1.25,
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  Future<void> _fetchRecords() async {
    setState(() => _isLoading = true);
    try {
      final resultsFuture = ApiClient.get('/lab-results');
      final caresFuture = ApiClient.get('/nurse-cares');

      final responses = await Future.wait([resultsFuture, caresFuture]);

      if (responses[0].statusCode == 200) {
        final labData = jsonDecode(responses[0].body);
        _labResults = labData['data'] ?? [];
        if (labData['branding'] is Map) {
          _branding = Map<String, dynamic>.from(labData['branding']);
        }
      }

      if (responses[1].statusCode == 200) {
        final nurseData = jsonDecode(responses[1].body);
        _nurseCares = nurseData['data'] ?? [];
      }
    } catch (e) {
      debugPrint('Error fetching medical records: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final visibleCount = _selectedCategory == 'lab'
        ? _labResults.length
        : (_selectedCategory == 'nurse'
            ? _nurseCares.length
            : _labResults.length + _nurseCares.length);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        leading: widget.showBackButton
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          'medical_records'.tr(),
          style: _kStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchRecords,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Comprehensive Patient EMR Quick Action ──
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const PatientEmrScreen(isReadOnly: true),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Colors.white24,
                              child: Icon(Iconsax.health, color: Colors.white),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'comprehensive_emr'.tr(),
                                    style: _kStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'emr_subtitle'.tr(),
                                    style: _kStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.85)),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 50.ms),
                    const SizedBox(height: 20),

                    // ── Folders Section (Symmetrical 3 Columns) ──
                    Text(
                      'بەشە پزیشکییەکان',
                      style: _kStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: _buildFolderCard(
                            context,
                            'هەموو دۆسیەکان',
                            '${_labResults.length + _nurseCares.length} دۆسیە',
                            const Color(0xFF8B5CF6),
                            Iconsax.folder_2,
                            isSelected: _selectedCategory == 'all',
                            onTap: () => setState(() => _selectedCategory = 'all'),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildFolderCard(
                            context,
                            'تاقیگە',
                            '${_labResults.length} پشکنین',
                            const Color(0xFF3B82F6),
                            Iconsax.document_like,
                            isSelected: _selectedCategory == 'lab',
                            onTap: () => setState(() => _selectedCategory =
                                _selectedCategory == 'lab' ? 'all' : 'lab'),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildFolderCard(
                            context,
                            'پەرستاری',
                            '${_nurseCares.length} تۆمار',
                            const Color(0xFF10B981),
                            Iconsax.health,
                            isSelected: _selectedCategory == 'nurse',
                            onTap: () => setState(() => _selectedCategory =
                                _selectedCategory == 'nurse' ? 'all' : 'nurse'),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05, end: 0),

                    const SizedBox(height: 28),

                    // ── Recent Files Section ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'تۆمار و ئەنجامەکان',
                          style: _kStyle(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'کۆی گشتی: $visibleCount',
                          style: _kStyle(
                            color: const Color(0xFF3B82F6),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 14),

                    // Lab Results List
                    if (_selectedCategory == 'all' || _selectedCategory == 'lab') ...[
                      ..._labResults.map((item) => _buildFileItem(
                            context,
                            item['test_name'] ?? 'پشکنینی تاقیگە',
                            '${item['lab_name'] ?? 'تاقیگە'} • ${item['created_at_human'] ?? item['created_at'] ?? ''}',
                            item['status'] == 'completed' ? 'تەواوکراو' : (item['status'] ?? 'بەردەستە'),
                            Iconsax.document_text,
                            isDark: isDark,
                            accentColor: const Color(0xFF3B82F6),
                            onTap: () => _showLabResultDetails(context, item, isDark),
                          )),
                    ],

                    // Nurse Cares List
                    if (_selectedCategory == 'all' || _selectedCategory == 'nurse') ...[
                      ..._nurseCares.map((item) => _buildFileItem(
                            context,
                            (item['title']?.toString().trim().isNotEmpty ?? false)
                                ? item['title'].toString()
                                : 'چاودێری پەرستاری: ${item['nurse_name'] ?? 'پەرستار'}',
                            '${item['nurse_name'] ?? 'پەرستار'} • ${item['date'] ?? item['created_at'] ?? ''}',
                            (item['status'] ?? 'تۆمارکراو').toString(),
                            Iconsax.heart_tick,
                            isDark: isDark,
                            accentColor: const Color(0xFF10B981),
                            onTap: () => _showNurseCareDetails(context, item, isDark),
                          )),
                    ],

                    if (visibleCount == 0)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: (_selectedCategory == 'nurse'
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFF3B82F6))
                                      .withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _selectedCategory == 'nurse'
                                      ? Iconsax.health
                                      : Iconsax.folder_open,
                                  color: _selectedCategory == 'nurse'
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF3B82F6),
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _selectedCategory == 'nurse'
                                    ? 'هیچ تۆمارێکی پەرستاری بەردەست نییە'
                                    : (_selectedCategory == 'lab'
                                        ? 'هیچ ئەنجامێکی تاقیگە بەردەست نییە'
                                        : 'هیچ تۆمارێکی پزیشکی بەردەست نییە'),
                                style: _kStyle(
                                  color: AppColors.getTextTitle(context),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'ئەنجامەکانی پشکنین و چاودێری پەرستار لێرەدا دەردەکەون',
                                style: _kStyle(
                                  color: AppColors.getTextSubtitle(context),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFolderCard(
    BuildContext context,
    String title,
    String count,
    Color color,
    IconData icon, {
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? color.withValues(alpha: 0.16) : color.withValues(alpha: 0.08))
              : cardBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.22)
                    : color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: _kStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  count,
                  style: _kStyle(
                    color: isSelected
                        ? (isDark ? color.withValues(alpha: 0.9) : color)
                        : const Color(0xFF94A3B8),
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Clean, Simple List Item (Tappable to see details)
  Widget _buildFileItem(
    BuildContext context,
    String name,
    String date,
    String status,
    IconData icon, {
    required bool isDark,
    Color accentColor = const Color(0xFF3B82F6),
    required VoidCallback onTap,
  }) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: _kStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: _kStyle(
                      color: const Color(0xFF94A3B8),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                status,
                style: _kStyle(
                  color: const Color(0xFF10B981),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  void _showLabResultDetails(BuildContext context, dynamic item, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final testName = item['test_name'] ?? 'پشکنینی تاقیگە';
    final labName = item['lab_name'] ?? 'تاقیگە';
    final date = item['created_at_human'] ?? item['created_at'] ?? '';
    final resultValue = item['result_value'] ?? '';
    final notes = item['notes'] ?? '';
    final rawFileUrl = (item['file_url'] ?? item['file_path'] ?? '').toString();
    final fullFileUrl = rawFileUrl.isNotEmpty ? ApiClient.getImageUrl(rawFileUrl) : '';
    bool isGeneratingPdf = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Iconsax.document_text, color: Color(0xFF3B82F6), size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          testName,
                          style: _kStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$labName • $date',
                          style: _kStyle(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'تەواوکراوە',
                      style: _kStyle(
                        color: const Color(0xFF10B981),
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Result value box
              if (resultValue.isNotEmpty) ...[
                Text(
                  'ئەنجامی پشکنین',
                  style: _kStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    resultValue,
                    style: _kStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Notes box
              if (notes.isNotEmpty) ...[
                Text(
                  'lab_notes_instructions'.tr(),
                  style: _kStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    notes,
                    style: _kStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Image / PDF report
              if (fullFileUrl.isNotEmpty) ...[
                Text(
                  'official_lab_file'.tr(),
                  style: _kStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 8),
                if (fullFileUrl.toLowerCase().contains('.pdf'))
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444), size: 28),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ڕاپۆرتی فەرمی پشکنین (PDF)',
                                    style: _kStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'فایلی ڕاپۆرتی تاقیگەیە، کلیک بکە بۆ کردنەوە و داگرتن',
                                    style: _kStyle(fontSize: 11.5, color: const Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final uri = Uri.parse(fullFileUrl);
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            },
                            icon: const Icon(Icons.open_in_new_rounded, size: 18),
                            label: Text('کردنەوە و داگرتنی فایلی PDF', style: _kStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () => _openFullImageView(context, fullFileUrl),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 260),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.network(
                            fullFileUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(30),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                padding: const EdgeInsets.all(24),
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                child: Column(
                                  children: [
                                    const Icon(Iconsax.document_text, size: 36, color: Color(0xFF3B82F6)),
                                    const SizedBox(height: 8),
                                    Text(
                                      'فایلی ڕاپۆرتی تاقیگە',
                                      style: _kStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          Positioned(
                            bottom: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Iconsax.maximize_4, color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    'zoom_in'.tr(),
                                    style: _kStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
              ],

              // Official Branded PDF Card (Logo + Stamp + Watermark + Signature)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Iconsax.verify,
                            color: Color(0xFF4F46E5),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ڕاپۆرتی فەرمی پشکنین (بە مۆر و تەوقیح)',
                                style: _kStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'لۆگۆ، مۆری پەسەندکردن و واژووی فەرمی Dr. Room لەسەرە',
                                style: _kStyle(
                                  fontSize: 11,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: isGeneratingPdf
                                ? null
                                : () async {
                                    setSheetState(() => isGeneratingPdf = true);
                                    try {
                                      await MedicalReportPdfService.previewAndPrint(
                                        ctx,
                                        result: Map<String, dynamic>.from(
                                          item as Map,
                                        ),
                                        branding: _branding,
                                      );
                                    } catch (e) {
                                      if (ctx.mounted) {
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                          SnackBar(
                                            content: Text('کێشە لە PDF: $e'),
                                          ),
                                        );
                                      }
                                    } finally {
                                      if (ctx.mounted) {
                                        setSheetState(
                                          () => isGeneratingPdf = false,
                                        );
                                      }
                                    }
                                  },
                            icon: isGeneratingPdf
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Iconsax.document_download, size: 17),
                            label: Text(
                              'سەیڤ / بینینی PDF',
                              style: _kStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
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
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isGeneratingPdf
                                ? null
                                : () async {
                                    setSheetState(() => isGeneratingPdf = true);
                                    try {
                                      await MedicalReportPdfService.shareReport(
                                        result: Map<String, dynamic>.from(
                                          item as Map,
                                        ),
                                        branding: _branding,
                                      );
                                    } finally {
                                      if (ctx.mounted) {
                                        setSheetState(
                                          () => isGeneratingPdf = false,
                                        );
                                      }
                                    }
                                  },
                            icon: const Icon(Iconsax.share, size: 16),
                            label: Text(
                              'ناردن',
                              style: _kStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4F46E5),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF4F46E5),
                              side: const BorderSide(color: Color(0xFF4F46E5)),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Safe and clean Close Button
              Padding(
                padding: EdgeInsets.only(
                  top: 8,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(ctx),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.close_rounded, size: 20, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'داخستن',
                            style: _kStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  void _showNurseCareDetails(BuildContext context, dynamic item, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.white70 : const Color(0xFF334155);
    final title = (item['title'] ?? '').toString().trim();
    final nurseName = (item['nurse_name'] ?? 'پەرستار').toString();
    final date = (item['date'] ?? item['created_at'] ?? '').toString();
    final symptoms = (item['symptoms'] ?? '').toString().trim();
    final medication = (item['medication_given'] ?? '').toString().trim();
    final notes = (item['notes'] ?? '').toString().trim();
    final vitals = item['vitals'] is Map ? item['vitals'] as Map : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title.isNotEmpty ? title : 'چاودێری پەرستاری',
                style: _kStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$nurseName • $date',
                style: _kStyle(fontSize: 12, color: const Color(0xFF94A3B8)),
              ),
              if (symptoms.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text('نیشانەکان',
                    style: _kStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: titleColor)),
                const SizedBox(height: 4),
                Text(symptoms, style: _kStyle(fontSize: 13, color: subColor)),
              ],
              if (vitals != null && vitals.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text('نیشانە زیندووەکان',
                    style: _kStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: titleColor)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (vitals['blood_pressure'] != null)
                      _vitalChip('پەستانی خوێن: ${vitals['blood_pressure']}'),
                    if (vitals['heart_rate'] != null)
                      _vitalChip('لێدانی دڵ: ${vitals['heart_rate']}'),
                    if (vitals['temperature'] != null)
                      _vitalChip('پلەی گەرمی: ${vitals['temperature']}'),
                  ],
                ),
              ],
              if (medication.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text('دەرمانی پێدراو',
                    style: _kStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: titleColor)),
                const SizedBox(height: 4),
                Text(medication, style: _kStyle(fontSize: 13, color: subColor)),
              ],
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text('notes_instructions'.tr(),
                    style: _kStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: titleColor)),
                const SizedBox(height: 4),
                Text(notes, style: _kStyle(fontSize: 13, color: subColor)),
              ],
              Padding(
                padding: EdgeInsets.only(
                  top: 20,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(ctx),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.close_rounded,
                              size: 20, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'close'.tr(),
                            style: _kStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                height: 1.1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vitalChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: _kStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF059669),
        ),
      ),
    );
  }

  void _openFullImageView(BuildContext context, String imageUrl) async {
    if (imageUrl.toLowerCase().contains('.pdf')) {
      final uri = Uri.parse(imageUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text('test_image'.tr(), style: _kStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                },
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Text('image_load_error'.tr(), style: const TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

}