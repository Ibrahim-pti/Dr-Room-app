import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../pharmacy/pill_scanner_screen.dart';

class PillReminderScreen extends StatefulWidget {
  const PillReminderScreen({super.key});

  @override
  State<PillReminderScreen> createState() => _PillReminderScreenState();
}

class _PillReminderScreenState extends State<PillReminderScreen> {
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

  final List<Map<String, dynamic>> _reminders = [
    {
      'time': '٠٨:٠٠ بەیانی',
      'pillName': 'پاراسیتامۆڵ 500mg',
      'description': 'دوای نانی بەیانی بە ئاوی زۆرەوە',
      'isTaken': true,
      'color': const Color(0xFF10B981),
    },
    {
      'time': '٠٢:٠٠ پاشنیوەڕۆ',
      'pillName': 'ڤیتامین D3 5000IU',
      'description': 'لەگەڵ ژەمی نیوەڕۆ',
      'isTaken': false,
      'color': const Color(0xFFF59E0B),
    },
    {
      'time': '٠٨:٠٠ شەو',
      'pillName': 'ئامۆکسیسیلین 250mg',
      'description': 'دوای نانی ئێوارە (دژە هەوکردن)',
      'isTaken': false,
      'color': const Color(0xFF3B82F6),
    },
  ];

  void _toggleTaken(int index) {
    setState(() {
      _reminders[index]['isTaken'] = !(_reminders[index]['isTaken'] as bool);
    });
  }

  void _showAddPillSheet() {
    final nameController = TextEditingController();
    final noteController = TextEditingController();
    String selectedTime = '٠٨:٠٠ بەیانی';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                24,
                20,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'زیادکردنی کاتی دەرمانی نوێ',
                    style: _kStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    style: _kStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      labelText: 'ناوی دەرمان یان حەب',
                      labelStyle: _kStyle(color: const Color(0xFF94A3B8), fontSize: 13),
                      prefixIcon: const Icon(Iconsax.health, color: Color(0xFF3B82F6), size: 20),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    style: _kStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      labelText: 'ڕێنمایی (نموونە: پێش نان، بە ئاوەوە)',
                      labelStyle: _kStyle(color: const Color(0xFF94A3B8), fontSize: 13),
                      prefixIcon: const Icon(Iconsax.note_text, color: Color(0xFF3B82F6), size: 20),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('کاتی خواردن', style: _kStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['٠٨:٠٠ بەیانی', '٠٢:٠٠ پاشنیوەڕۆ', '٠٨:٠٠ شەو'].map((time) {
                      final isSel = selectedTime == time;
                      return ChoiceChip(
                        label: Text(time, style: _kStyle(color: isSel ? Colors.white : const Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.bold)),
                        selected: isSel,
                        selectedColor: const Color(0xFF3B82F6),
                        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        onSelected: (val) {
                          setSheetState(() => selectedTime = time);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameController.text.trim().isNotEmpty) {
                          setState(() {
                            _reminders.add({
                              'time': selectedTime,
                              'pillName': nameController.text.trim(),
                              'description': noteController.text.trim().isNotEmpty ? noteController.text.trim() : 'بەپێی ڕێنمایی پزیشک',
                              'isTaken': false,
                              'color': const Color(0xFF3B82F6),
                            });
                          });
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text('پاشەکەوتکردنی بیرخەرەوە', style: _kStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
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
          'بیرخەرەوەی دەرمان',
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
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Iconsax.add, color: Color(0xFF3B82F6), size: 22),
                onPressed: _showAddPillSheet,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Iconsax.clock, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'دەرمانەکانی ئەمڕۆت لەبیر نەچێت',
                          style: _kStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'تەندروستیت لەپێش هەموو شتێکەوەیە',
                          style: _kStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.05, end: 0),

            const SizedBox(height: 24),

            Text(
              'خشتەی خواردنی دەرمانەکان',
              style: _kStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),

            ...List.generate(_reminders.length, (index) {
              final item = _reminders[index];
              final isTaken = item['isTaken'] as bool;
              final color = item['color'] as Color;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isTaken ? const Color(0xFF10B981).withValues(alpha: 0.5) : borderColor,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Iconsax.health, color: color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['pillName'] as String,
                            style: _kStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                              color: isTaken
                                  ? const Color(0xFF94A3B8)
                                  : (isDark ? Colors.white : const Color(0xFF0F172A)),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item['description'] as String,
                            style: _kStyle(
                              fontSize: 12,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.access_time, size: 12, color: Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Text(
                                  item['time'] as String,
                                  style: _kStyle(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _toggleTaken(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isTaken ? const Color(0xFF10B981) : const Color(0xFF3B82F6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isTaken ? Icons.check : Icons.circle_outlined,
                              color: isTaken ? Colors.white : const Color(0xFF3B82F6),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isTaken ? 'خوراوە' : 'خواردن',
                              style: _kStyle(
                                color: isTaken ? Colors.white : const Color(0xFF3B82F6),
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (index * 80).ms).slideY(begin: 0.05, end: 0);
            }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PillScannerScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF3B82F6),
        icon: const Icon(Iconsax.scan, color: Colors.white, size: 20),
        label: Text('سکانی دەرمان لە ڕەچەتە', style: _kStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }
}