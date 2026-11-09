import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/api_client.dart';
import 'admin_app_bar.dart';
import 'admin_ui.dart';

class AdminStaffScheduleScreen extends StatefulWidget {
  const AdminStaffScheduleScreen({super.key});

  @override
  State<AdminStaffScheduleScreen> createState() => _AdminStaffScheduleScreenState();
}

class _AdminStaffScheduleScreenState extends State<AdminStaffScheduleScreen> {
  List<dynamic> _nurses = [];
  dynamic _selectedNurse;
  List<dynamic> _schedules = [];
  bool _isLoading = true;
  String? _error;

  final Map<String, String> _dayTranslations = {
    'Sunday': 'یەکشەممە',
    'Monday': 'دووشەممە',
    'Tuesday': 'سێشەممە',
    'Wednesday': 'چوارشەممە',
    'Thursday': 'پێنجشەممە',
    'Friday': 'هەینی',
    'Saturday': 'شەممە',
  };

  @override
  void initState() {
    super.initState();
    _loadNurses();
  }

  Future<void> _loadNurses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await ApiClient.get('/admin/nurses');
      if (!mounted) return;

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = decoded is List ? decoded : (decoded is Map ? (decoded['data'] ?? []) : []);
        setState(() {
          _nurses = list;
          if (_nurses.isNotEmpty) {
            _selectedNurse = _nurses.first;
          }
          _isLoading = false;
        });

        if (_selectedNurse != null) {
          final nurseId = _selectedNurse['nurse']?['id'] ?? _selectedNurse['id'];
          if (nurseId != null) {
            _loadScheduleForNurse(int.tryParse(nurseId.toString()) ?? 0);
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _isLoading = false; });
    }
  }

  Future<void> _loadScheduleForNurse(int nurseId) async {
    try {
      final res = await ApiClient.get('/nurse/schedule?nurse_id=$nurseId');
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = decoded is List ? decoded : (decoded is Map ? (decoded['data'] ?? []) : []);
        setState(() {
          _schedules = list;
        });
      }
    } catch (_) {}
  }

  Future<void> _editSlot(dynamic slot) async {
    final startCtrl = TextEditingController(text: slot['start_time'] ?? '08:00');
    final endCtrl = TextEditingController(text: slot['end_time'] ?? '20:00');
    final visitsCtrl = TextEditingController(text: (slot['max_daily_visits'] ?? 6).toString());
    bool isAvail = slot['is_available'] == true || slot['is_available'] == 1;

    await AdminUi.formSheet(
      context: context,
      title: 'خشتەی دەوامی ${_dayTranslations[slot['day_of_week']] ?? slot['day_of_week']}',
      subtitle: 'دیاریکردنی کاتی دەستپێک، کۆتایی و زۆرترین داواکاری لە ڕۆژێکدا',
      submitLabel: 'پاشەکەوتکردن',
      builder: (setSheetState, setError) => [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Iconsax.calendar_tick, size: 20, color: Color(0xFF14B8A6)),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('بەردەستە بۆ وەرگرتنی داواکاری؟', style: TextStyle(fontFamily: 'Rabar', fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              Switch.adaptive(
                value: isAvail,
                activeTrackColor: const Color(0xFF14B8A6),
                onChanged: (v) => setSheetState(() => isAvail = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: startCtrl,
                decoration: const InputDecoration(labelText: 'کاتی دەستپێک', hintText: '08:00'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: endCtrl,
                decoration: const InputDecoration(labelText: 'کاتی کۆتایی', hintText: '20:00'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: visitsCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'زۆرترین داواکاری لە ڕۆژێکدا'),
        ),
      ],
      onSubmit: (setError) async {
        slot['start_time'] = startCtrl.text.trim();
        slot['end_time'] = endCtrl.text.trim();
        slot['is_available'] = isAvail;
        slot['max_daily_visits'] = int.tryParse(visitsCtrl.text.trim()) ?? 6;

        final nurseId = _selectedNurse?['nurse']?['id'] ?? _selectedNurse?['id'];
        if (nurseId != null) {
          try {
            await ApiClient.post('/nurse/schedule', body: {
              'nurse_id': nurseId,
              'schedules': _schedules,
            });
          } catch (_) {}
        }

        if (mounted) {
          setState(() {});
          AdminUi.toast(context, 'خشتەی کاتی پەرستار پاشەکەوتکرا');
        }
        return true;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AdminAppBar(
        title: 'خشتەی دەوامی ستاف',
        subtitle: 'ڕێگری ئۆتۆماتیکی لە تێکەڵبوونی کاتی دوو داواکاری',
        icon: Iconsax.calendar_tick,
        iconColor: const Color(0xFF0D9488),
        iconBackgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.1),
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: AdminUi.subtitle))
              : _nurses.isEmpty
                  ? Center(child: Text('هیچ پەرستارێک نەدۆزرایەوە', style: AdminUi.subtitle))
                  : Column(
                      children: [
                        // Nurse Selector
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: DropdownButtonFormField<dynamic>(
                            initialValue: _selectedNurse,
                            decoration: const InputDecoration(labelText: 'پەرستار هەڵبژێرە'),
                            items: _nurses.map((n) {
                              return DropdownMenuItem(
                                value: n,
                                child: Text(n['name'] ?? n['user']?['name'] ?? 'پەرستار'),
                              );
                            }).toList(),
                            onChanged: (n) {
                              setState(() => _selectedNurse = n);
                              if (n != null) {
                                final nurseId = n['nurse']?['id'] ?? n['id'];
                                if (nurseId != null) {
                                  _loadScheduleForNurse(int.tryParse(nurseId.toString()) ?? 0);
                                }
                              }
                            },
                          ),
                        ),

                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _schedules.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final slot = _schedules[i];
                          final dayName = _dayTranslations[slot['day_of_week']] ?? slot['day_of_week'];
                          final isAvail = slot['is_available'] == true || slot['is_available'] == 1;

                          return Container(
                            decoration: AdminUi.cardDecoration,
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: (isAvail ? const Color(0xFF0D9488) : Colors.grey)
                                      .withValues(alpha: 0.12),
                                  child: Icon(
                                    isAvail ? Iconsax.clock : Iconsax.close_circle,
                                    color: isAvail ? const Color(0xFF0D9488) : Colors.grey,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(dayName, style: AdminUi.title),
                                      const SizedBox(height: 2),
                                      Text(
                                        isAvail
                                            ? '${slot['start_time']} - ${slot['end_time']} (زۆرترین سەردان: ${slot['max_daily_visits'] ?? 6})'
                                            : 'پشووە (ناچالاک)',
                                        style: AdminUi.subtitle.copyWith(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Iconsax.edit, color: Color(0xFF0D9488), size: 20),
                                  onPressed: () => _editSlot(slot),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 150.ms);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
