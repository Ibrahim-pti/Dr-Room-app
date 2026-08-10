import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['All', 'Lab Tests', 'Prescriptions', 'X-Ray'];

  final List<Map<String, dynamic>> _records = [
    {
      'title': 'Complete Blood Count (CBC)',
      'date': '15 Jun 2026',
      'result': 'Normal',
      'resultColor': const Color(0xFF10B981), // Green
      'icon': Iconsax.health,
      'iconColor': const Color(0xFF3B82F6), // Blue
      'type': 'Lab Tests',
    },
    {
      'title': 'Fasting Blood Sugar (FBS)',
      'date': '20 May 2026',
      'result': 'Alert: 126 mg/dl',
      'resultColor': const Color(0xFFEF4444), // Red
      'icon': Iconsax.health,
      'iconColor': const Color(0xFF3B82F6), // Blue
      'type': 'Lab Tests',
    },
    {
      'title': 'Chest Ultrasound',
      'date': '10 Apr 2026',
      'result': 'Normal',
      'resultColor': const Color(0xFF10B981), // Green
      'icon': Iconsax.scan,
      'iconColor': const Color(0xFF8B5CF6), // Purple
      'type': 'X-Ray',
    },
    {
      'title': 'Prescription — Dr. Ahmed',
      'date': '05 Mar 2026',
      'result': 'Metformin 500mg',
      'resultColor': const Color(0xFF3B82F6), // Blue
      'icon': Iconsax.document_text,
      'iconColor': const Color(0xFFF59E0B), // Orange
      'type': 'Prescriptions',
    },
    {
      'title': 'Thyroid Profile',
      'date': '18 Feb 2026',
      'result': 'Normal',
      'resultColor': const Color(0xFF10B981), // Green
      'icon': Iconsax.health,
      'iconColor': const Color(0xFF3B82F6), // Blue
      'type': 'Lab Tests',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'Medical Records',
          style: GoogleFonts.poppins(
            color: AppColors.getTextTitle(context),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Profile Summary ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(24),
                  ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF3B82F6).withValues(alpha: 0.15),
                          const Color(0xFF60A5FA).withValues(alpha: 0.15),
                        ],
                        begin: AlignmentDirectional.topStart,
                        end: AlignmentDirectional.bottomEnd,
                      ),
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(Iconsax.user, color: Color(0xFF3B82F6), size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Yahya Ahmed',
                          style: GoogleFonts.poppins(
                            color: AppColors.getTextTitle(context),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Age: 25  •  Blood: O+',
                          style: GoogleFonts.poppins(
                            color: AppColors.getTextSubtitle(context),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    ),
                    child: Text(
                      'O+',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF3B82F6),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
          ),

          const SizedBox(height: 10),

          // ── Filter Tabs ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: List.generate(
                _filters.length,
                (index) => Padding(
                  padding: const EdgeInsetsDirectional.only(end: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilterIndex = index;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedFilterIndex == index
                            ? const Color(0xFF3B82F6)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _selectedFilterIndex == index
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFFE2E8F0),
                          width: 1.5,
                        ),
                        boxShadow: _selectedFilterIndex == index
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : [],
                      ),
                      child: Text(
                        _filters[index],
                        style: GoogleFonts.poppins(
                          color: _selectedFilterIndex == index
                              ? Colors.white
                              : const Color(0xFF64748B),
                          fontSize: 14,
                          fontWeight: _selectedFilterIndex == index ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.1, end: 0),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Records List ──
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _records.length,
              itemBuilder: (context, index) {
                final record = _records[index];

                // Simple filtering logic
                if (_selectedFilterIndex != 0) {
                  if (_filters[_selectedFilterIndex] != record['type']) {
                    return const SizedBox.shrink();
                  }
                }

                return Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.getSurface(context),
                      borderRadius: BorderRadius.circular(24),
                              ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: (record['iconColor'] as Color).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            record['icon'] as IconData,
                            color: record['iconColor'] as Color,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record['title'] as String,
                                style: GoogleFonts.poppins(
                                  color: AppColors.getTextTitle(context),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (record['resultColor'] as Color).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      record['result'] as String,
                                      style: GoogleFonts.poppins(
                                        color: record['resultColor'] as Color,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      record['date'] as String,
                                      style: GoogleFonts.poppins(
                                        color: AppColors.textLight,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.getSurfaceSecondary(context),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Iconsax.document_download,
                            color: Color(0xFF3B82F6),
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: (100 * index).ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                );
              },
            ),
          ),
          
          // Extra space at bottom to ensure it clears the floating bottom nav bar
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
