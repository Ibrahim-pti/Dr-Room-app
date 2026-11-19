import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/api_client.dart';
import 'admin_app_bar.dart';
import 'admin_ui.dart';

class AdminStaffScheduleScreen extends StatefulWidget {
  const AdminStaffScheduleScreen({super.key});

  @override
  State<AdminStaffScheduleScreen> createState() =>
      _AdminStaffScheduleScreenState();
}

class _AdminStaffScheduleScreenState extends State<AdminStaffScheduleScreen> {
  static const _sections = [
    (
      type: 'nurse',
      label: 'پەرستاران',
      singular: 'پەرستار',
      icon: Iconsax.health,
      color: Color(0xFF0D9488),
    ),
    (
      type: 'lab',
      label: 'تاقیگەکان',
      singular: 'تاقیگە',
      icon: Iconsax.microscope,
      color: Color(0xFF8B5CF6),
    ),
    (
      type: 'driver',
      label: 'دلیڤەری',
      singular: 'شۆفێری دلیڤەری',
      icon: Iconsax.truck_fast,
      color: Color(0xFF2563EB),
    ),
  ];

  static const _dayTranslations = {
    'Sunday': 'یەکشەممە',
    'Monday': 'دووشەممە',
    'Tuesday': 'سێشەممە',
    'Wednesday': 'چوارشەممە',
    'Thursday': 'پێنجشەممە',
    'Friday': 'هەینی',
    'Saturday': 'شەممە',
  };

  String _activeType = 'nurse';
  int _innerTab = 0; // 0: weekly schedule, 1: slots & upcoming bookings
  int _selectedDayIndex = 0;

  bool _isLoadingProviders = true;
  bool _isLoadingDetail = false;
  String? _error;

  List<Map<String, dynamic>> _providers = [];
  int? _selectedProviderId;

  List<Map<String, dynamic>> _week = [];
  List<Map<String, dynamic>> _availability = [];
  List<Map<String, dynamic>> _upcoming = [];

  bool get _isDark => ThemeProvider().isDarkMode;

  ({
    String type,
    String label,
    String singular,
    IconData icon,
    Color color,
  }) get _currentSection =>
      _sections.firstWhere((s) => s.type == _activeType);

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    setState(() {
      _isLoadingProviders = true;
      _error = null;
      _providers = [];
      _selectedProviderId = null;
      _week = [];
      _availability = [];
      _upcoming = [];
    });

    try {
      final res =
          await ApiClient.get('/admin/schedules/providers?type=$_activeType');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = (decoded['data'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        setState(() {
          _providers = list;
          _selectedProviderId =
              list.isNotEmpty ? (list.first['id'] as num?)?.toInt() : null;
          _isLoadingProviders = false;
        });
        if (_selectedProviderId != null) {
          await _loadProviderDetail(_selectedProviderId!);
        }
      } else {
        setState(() {
          _error = AdminUi.readError(res);
          _isLoadingProviders = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _isLoadingProviders = false;
        });
      }
    }
  }

  Future<void> _loadProviderDetail(int userId) async {
    setState(() => _isLoadingDetail = true);
    try {
      final res = await ApiClient.get('/admin/schedules/$_activeType/$userId');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'] as Map<String, dynamic>? ?? {};
        setState(() {
          _week = (data['week'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _availability = (data['availability'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _upcoming = (data['upcoming'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          if (_selectedDayIndex >= _availability.length) {
            _selectedDayIndex = 0;
          }
          _isLoadingDetail = false;
        });
      } else {
        setState(() => _isLoadingDetail = false);
        AdminUi.toast(context, AdminUi.readError(res), isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDetail = false);
        AdminUi.toast(context, '$e', isError: true);
      }
    }
  }

  TimeOfDay _parseTime(String? raw, TimeOfDay fallback) {
    if (raw == null || !raw.contains(':')) return fallback;
    final parts = raw.split(':');
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return fallback;
    return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _editDay(Map<String, dynamic> dayRow) async {
    if (_selectedProviderId == null) return;

    TimeOfDay start =
        _parseTime(dayRow['start_time']?.toString(), const TimeOfDay(hour: 8, minute: 0));
    TimeOfDay end =
        _parseTime(dayRow['end_time']?.toString(), const TimeOfDay(hour: 20, minute: 0));
    bool isAvail = dayRow['is_available'] == true || dayRow['is_available'] == 1;
    int slotMinutes = (dayRow['slot_minutes'] as num?)?.toInt() ?? 60;
    int slotCapacity = (dayRow['slot_capacity'] as num?)?.toInt() ?? 1;
    final maxDailyCtrl = TextEditingController(
      text: ((dayRow['max_daily_orders'] ?? 6)).toString(),
    );
    bool applyToAll = false;

    final accent = _currentSection.color;

    await AdminUi.formSheet(
      context: context,
      title:
          'خشتەی ${_dayTranslations[dayRow['day_of_week']] ?? dayRow['day_of_week']}',
      subtitle: 'کاتەکانی کارکردن، ماوەی نۆرە و ژمارەی داواکاری لە هەر کاتێکدا',
      submitLabel: 'پاشەکەوتکردن',
      builder: (setSheetState, setError) {
        Widget timeBox(String label, TimeOfDay value, ValueChanged<TimeOfDay> onPick) {
          return Expanded(
            child: InkWell(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: value,
                  builder: (ctx, child) => MediaQuery(
                    data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
                    child: child ?? const SizedBox.shrink(),
                  ),
                );
                if (picked != null) {
                  setSheetState(() => onPick(picked));
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: _isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AdminUi.subtitle.copyWith(fontSize: 11)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Iconsax.clock, size: 16, color: accent),
                        const SizedBox(width: 6),
                        Text(
                          _formatTime(value),
                          style: AdminUi.title.copyWith(fontSize: 15),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Icon(Iconsax.calendar_tick, size: 20, color: accent),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'بەردەستە بۆ وەرگرتنی داواکاری؟',
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Switch.adaptive(
                  value: isAvail,
                  activeTrackColor: accent,
                  onChanged: (v) => setSheetState(() => isAvail = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              timeBox('کاتی دەستپێک', start, (v) => start = v),
              const SizedBox(width: 10),
              timeBox('کاتی کۆتایی', end, (v) => end = v),
            ],
          ),
          const SizedBox(height: 14),
          Text('ماوەی هەر نۆرەیەک (خولەک)', style: AdminUi.subtitle),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [15, 30, 45, 60, 90, 120].map((m) {
              final selected = slotMinutes == m;
              return ChoiceChip(
                label: Text('$m خولەک', style: const TextStyle(fontFamily: 'Rabar', fontSize: 12)),
                selected: selected,
                selectedColor: accent.withValues(alpha: 0.16),
                labelStyle: TextStyle(
                  color: selected ? accent : AdminUi.title.color,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (_) => setSheetState(() => slotMinutes = m),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'داواکاری لە هەر کاتێکدا',
                        style: TextStyle(fontFamily: 'Rabar', fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'دوای پڕبوونی، کاتەکە دەبێتە گیراوە',
                        style: AdminUi.subtitle.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: slotCapacity > 1
                      ? () => setSheetState(() => slotCapacity--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$slotCapacity', style: AdminUi.title.copyWith(fontSize: 16)),
                IconButton(
                  onPressed: slotCapacity < 20
                      ? () => setSheetState(() => slotCapacity++)
                      : null,
                  icon: Icon(Icons.add_circle_outline, color: accent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: maxDailyCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'زۆرترین داواکاری لە ڕۆژێکدا',
            ),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: applyToAll,
            activeColor: accent,
            onChanged: (v) => setSheetState(() => applyToAll = v ?? false),
            title: const Text(
              'جێبەجێکردن بۆ هەموو ڕۆژەکانی هەفتە',
              style: TextStyle(fontFamily: 'Rabar', fontSize: 12.5),
            ),
          ),
        ];
      },
      onSubmit: (setError) async {
        final maxDaily = int.tryParse(maxDailyCtrl.text.trim()) ?? 6;
        if (maxDaily < 1) {
          setError('زۆرترین داواکاری دەبێت لانیکەم ١ بێت');
          return false;
        }

        final updatedStart = _formatTime(start);
        final updatedEnd = _formatTime(end);

        for (final row in _week) {
          if (applyToAll || row['day_of_week'] == dayRow['day_of_week']) {
            row['start_time'] = updatedStart;
            row['end_time'] = updatedEnd;
            row['is_available'] = isAvail;
            row['slot_minutes'] = slotMinutes;
            row['slot_capacity'] = slotCapacity;
            row['max_daily_orders'] = maxDaily;
          }
        }

        try {
          final res = await ApiClient.post(
            '/admin/schedules/$_activeType/${_selectedProviderId!}',
            body: {'schedules': _week},
          );
          if (!mounted) return true;
          if (res.statusCode == 200) {
            final data = jsonDecode(res.body)['data'] as Map<String, dynamic>? ?? {};
            setState(() {
              _week = (data['week'] as List? ?? _week)
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList();
              _availability = (data['availability'] as List? ?? _availability)
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList();
            });
            AdminUi.toast(context, 'خشتەی دەوام پاشەکەوتکرا');
            return true;
          }
          setError(AdminUi.readError(res));
          return false;
        } catch (e) {
          setError('$e');
          return false;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final section = _currentSection;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AdminAppBar(
        title: 'خشتەی دەوامی ستاف',
        subtitle: 'ڕێکخستنی کات و نۆرە بۆ پەرستار، تاقیگە و دلیڤەری',
        icon: Iconsax.calendar_tick,
        iconColor: section.color,
        iconBackgroundColor: section.color.withValues(alpha: 0.1),
        showBackButton: true,
        actions: [
          IconButton(
            tooltip: 'نوێکردنەوە',
            onPressed: _isLoadingProviders ? null : _loadProviders,
            icon: Icon(Iconsax.refresh, color: section.color),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSectionTabs(),
          if (_isLoadingProviders)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, style: AdminUi.subtitle),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _loadProviders,
                      child: const Text('دووبارە هەوڵبدەرەوە',
                          style: TextStyle(fontFamily: 'Rabar')),
                    ),
                  ],
                ),
              ),
            )
          else if (_providers.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'هیچ ${section.singular}ێکی پەسەندکراو نەدۆزرایەوە',
                  style: AdminUi.subtitle,
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  _buildProviderPicker(section),
                  _buildInnerToggle(section.color),
                  Expanded(
                    child: _isLoadingDetail
                        ? const Center(child: CircularProgressIndicator())
                        : (_innerTab == 0
                            ? _buildWeeklyList(section.color)
                            : _buildSlotsAndBookings(section.color)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: AdminUi.cardDecoration,
        child: Row(
          children: _sections.map((s) {
            final selected = _activeType == s.type;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_activeType == s.type) return;
                  setState(() {
                    _activeType = s.type;
                    _innerTab = 0;
                    _selectedDayIndex = 0;
                  });
                  _loadProviders();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                  decoration: BoxDecoration(
                    color: selected ? s.color : Colors.transparent,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        s.icon,
                        size: 16,
                        color: selected ? Colors.white : AdminUi.subtitle.color,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          s.label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: selected ? Colors.white : AdminUi.title.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildProviderPicker(
    ({String type, String label, String singular, IconData icon, Color color}) section,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: DropdownButtonFormField<int>(
        initialValue: _selectedProviderId,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: '${section.singular} هەڵبژێرە',
          prefixIcon: Icon(section.icon, color: section.color, size: 20),
          filled: true,
          fillColor: _isDark ? const Color(0xFF1E293B) : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: _isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: _isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
        ),
        items: _providers.map((p) {
          final id = (p['id'] as num).toInt();
          final upcoming = (p['upcoming_count'] as num?)?.toInt() ?? 0;
          final name = (p['name'] ?? section.singular).toString();
          return DropdownMenuItem<int>(
            value: id,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: AdminUi.title.copyWith(fontSize: 13.5),
                  ),
                ),
                if (upcoming > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: section.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$upcoming نۆرە',
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: section.color,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
        onChanged: (id) {
          if (id == null) return;
          setState(() => _selectedProviderId = id);
          _loadProviderDetail(id);
        },
      ),
    );
  }

  Widget _buildInnerToggle(Color accent) {
    Widget pill(int idx, String label, IconData icon) {
      final active = _innerTab == idx;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _innerTab = idx),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: active
                  ? accent.withValues(alpha: 0.12)
                  : (_isDark ? const Color(0xFF1E293B) : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active
                    ? accent
                    : (_isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: active ? accent : AdminUi.subtitle.color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: active ? accent : AdminUi.subtitle.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          pill(0, 'خشتەی هەفتانە', Iconsax.clock),
          const SizedBox(width: 10),
          pill(1, 'کاتە گیراوەکان (${_upcoming.length})', Iconsax.calendar_1),
        ],
      ),
    );
  }

  Widget _buildWeeklyList(Color accent) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: _week.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final row = _week[i];
        final dayName = _dayTranslations[row['day_of_week']] ?? row['day_of_week'].toString();
        final isAvail = row['is_available'] == true || row['is_available'] == 1;
        final slotMin = row['slot_minutes'] ?? 60;
        final cap = row['slot_capacity'] ?? 1;
        final maxDaily = row['max_daily_orders'] ?? 6;

        return InkWell(
          onTap: () => _editDay(row),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: AdminUi.cardDecoration,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: (isAvail ? accent : Colors.grey).withValues(alpha: 0.12),
                  child: Icon(
                    isAvail ? Iconsax.clock : Iconsax.close_circle,
                    color: isAvail ? accent : Colors.grey,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dayName, style: AdminUi.title),
                      const SizedBox(height: 3),
                      Text(
                        isAvail
                            ? '${row['start_time']} - ${row['end_time']}  •  $slotMin خولەک'
                            : 'پشووە (ناچالاک)',
                        style: AdminUi.subtitle.copyWith(fontSize: 12),
                      ),
                      if (isAvail) ...[
                        const SizedBox(height: 4),
                        Text(
                          'لە هەر کاتێکدا: $cap  •  زۆرترین لە ڕۆژێکدا: $maxDaily',
                          style: AdminUi.subtitle.copyWith(fontSize: 11, color: accent),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Iconsax.edit, color: accent, size: 20),
              ],
            ),
          ).animate().fadeIn(duration: 150.ms),
        );
      },
    );
  }

  Widget _buildSlotsAndBookings(Color accent) {
    final selectedDay = _availability.isNotEmpty
        ? _availability[_selectedDayIndex.clamp(0, _availability.length - 1)]
        : null;
    final slots = (selectedDay?['slots'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        if (_availability.isNotEmpty) ...[
          SizedBox(
            height: 68,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _availability.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final d = _availability[i];
                final active = i == _selectedDayIndex;
                final dayLabel = _dayTranslations[d['day_of_week']] ?? '';
                final dateStr = (d['date'] ?? '').toString();
                final shortDate = dateStr.length >= 10 ? dateStr.substring(5) : dateStr;
                final closed = d['closed'] == true;

                return GestureDetector(
                  onTap: () => setState(() => _selectedDayIndex = i),
                  child: Container(
                    width: 88,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: active
                          ? accent
                          : (_isDark ? const Color(0xFF1E293B) : Colors.white),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: active
                            ? accent
                            : (_isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          i == 0 ? 'ئەمڕۆ' : dayLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: active ? Colors.white : AdminUi.title.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          closed ? 'پشوو' : shortDate,
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 11,
                            color: active
                                ? Colors.white70
                                : (closed ? const Color(0xFFEF4444) : AdminUi.subtitle.color),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: AdminUi.cardDecoration,
            padding: const EdgeInsets.all(14),
            child: slots.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text('لەم ڕۆژەدا هیچ کاتێک بەردەست نییە', style: AdminUi.subtitle),
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: slots.map((s) {
                      final past = s['past'] == true;
                      final taken = s['taken'] == true;
                      final booked = (s['booked'] as num?)?.toInt() ?? 0;
                      final cap = (s['capacity'] as num?)?.toInt() ?? 1;

                      final Color bg;
                      final Color fg;
                      final String tag;
                      if (past) {
                        bg = Colors.grey.withValues(alpha: 0.12);
                        fg = Colors.grey;
                        tag = 'تێپەڕیوە';
                      } else if (taken) {
                        bg = const Color(0xFFEF4444).withValues(alpha: 0.12);
                        fg = const Color(0xFFDC2626);
                        tag = 'گیراوە';
                      } else {
                        bg = accent.withValues(alpha: 0.12);
                        fg = accent;
                        tag = '$booked/$cap';
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              s['time']?.toString() ?? '',
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: fg,
                                decoration: (!past && taken) ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tag,
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: fg,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 18),
        ],
        Text('داواکارییە کات-دیاریکراوەکان', style: AdminUi.title),
        const SizedBox(height: 8),
        if (_upcoming.isEmpty)
          Container(
            decoration: AdminUi.cardDecoration,
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text('هیچ داواکارییەکی داهاتوو بۆ ئەم ستافە نییە', style: AdminUi.subtitle),
            ),
          )
        else
          ..._upcoming.map((o) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: AdminUi.cardDecoration,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Iconsax.calendar_tick, color: accent, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${o['id']}  •  ${o['patient_name'] ?? 'نەخۆش'}',
                            style: AdminUi.title.copyWith(fontSize: 13.5),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'کات: ${o['scheduled_at'] ?? ''}',
                            style: AdminUi.subtitle.copyWith(
                              fontSize: 12,
                              color: accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if ((o['address'] ?? '').toString().isNotEmpty)
                            Text(
                              o['address'].toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AdminUi.subtitle.copyWith(fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }
}
