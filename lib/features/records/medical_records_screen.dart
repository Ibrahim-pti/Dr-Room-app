import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_client.dart';

class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  bool _isLoading = true;
  List<dynamic> _labResults = [];
  List<dynamic> _nurseCares = [];
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
      height: height,
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
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'تۆماری پزیشکی',
          style: _kStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              onPressed: () => Navigator.pop(context),
            ),
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
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Folders Section ──
                    Text(
                      'بەشە پزیشکییەکان',
                      style: _kStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 14),

                    SizedBox(
                      height: 130,
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildFolderCard(
                            context,
                            'پشکنینی تاقیگە',
                            '${_labResults.length} پشکنین',
                            const Color(0xFF3B82F6),
                            Iconsax.document_like,
                            isSelected: _selectedCategory == 'lab',
                            onTap: () => setState(() => _selectedCategory =
                                _selectedCategory == 'lab' ? 'all' : 'lab'),
                            isDark: isDark,
                          ),
                          _buildFolderCard(
                            context,
                            'چاودێری پەرستاری',
                            '${_nurseCares.length} تۆمار',
                            const Color(0xFF10B981),
                            Iconsax.health,
                            isSelected: _selectedCategory == 'nurse',
                            onTap: () => setState(() => _selectedCategory =
                                _selectedCategory == 'nurse' ? 'all' : 'nurse'),
                            isDark: isDark,
                          ),
                          _buildFolderCard(
                            context,
                            'هەموو دۆسیەکان',
                            '${_labResults.length + _nurseCares.length} دۆسیە',
                            const Color(0xFF8B5CF6),
                            Iconsax.folder_2,
                            isSelected: _selectedCategory == 'all',
                            onTap: () => setState(() => _selectedCategory = 'all'),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05, end: 0),

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
                          'کۆی گشتی: ${_selectedCategory == 'lab' ? _labResults.length : (_selectedCategory == 'nurse' ? _nurseCares.length : _labResults.length + _nurseCares.length)}',
                          style: _kStyle(
                            color: const Color(0xFF3B82F6),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 14),

                    // Lab Results
                    if (_selectedCategory == 'all' || _selectedCategory == 'lab') ...[
                      ..._labResults.map((item) => _buildFileItem(
                            context,
                            item['test_name'] ?? 'پشکنینی تاقیگە',
                            '${item['lab_name'] ?? 'تاقیگە'} • ${item['created_at_human'] ?? item['created_at'] ?? ''}',
                            item['status'] == 'completed' ? 'تەواوکراو' : (item['status'] ?? 'بەردەستە'),
                            Iconsax.document_text,
                            value: item['result_value'],
                            notes: item['notes'],
                            fileUrl: item['file_url'],
                            isDark: isDark,
                          )),
                    ],

                    // Nurse Cares
                    if (_selectedCategory == 'all' || _selectedCategory == 'nurse') ...[
                      ..._nurseCares.map((item) => _buildFileItem(
                            context,
                            'چاودێری پەرستاری: ${item['nurse_name'] ?? 'پەرستار'}',
                            'بەروار: ${item['date'] ?? item['created_at'] ?? ''}',
                            'تۆمارکراو',
                            Iconsax.heart_tick,
                            notes: item['notes'] ?? item['symptoms'],
                            isDark: isDark,
                          )),
                    ],

                    if (_labResults.isEmpty && _nurseCares.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Iconsax.folder_open, color: Color(0xFF3B82F6), size: 40),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'هیچ تۆمارێکی پزیشکی بەردەست نییە',
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
    final borderColor = isSelected ? color : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsetsDirectional.only(end: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
                color: color.withValues(alpha: 0.12),
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
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  count,
                  style: _kStyle(
                    color: const Color(0xFF94A3B8),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileItem(
    BuildContext context,
    String name,
    String date,
    String status,
    IconData icon, {
    String? value,
    String? notes,
    String? fileUrl,
    required bool isDark,
  }) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF3B82F6), size: 22),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            ],
          ),
          if (value != null && value.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text(
                    'ئەنجام: ',
                    style: _kStyle(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF3B82F6)),
                  ),
                  Expanded(
                    child: Text(
                      value,
                      style: _kStyle(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF334155)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'تێبینی: $notes',
              style: _kStyle(fontSize: 11.5, color: const Color(0xFF64748B)),
            ),
          ],
        ],
      ),
    );
  }
}
