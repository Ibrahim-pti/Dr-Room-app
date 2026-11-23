import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/api_client.dart';
import 'admin_app_bar.dart';
import 'admin_ui.dart';

class AdminStaffScheduleScreen extends StatefulWidget {
  final bool embedded;
  final int? initialDriverId;

  const AdminStaffScheduleScreen({
    super.key,
    this.embedded = false,
    this.initialDriverId,
  });

  @override
  State<AdminStaffScheduleScreen> createState() =>
      _AdminStaffScheduleScreenState();
}

class _AdminStaffScheduleScreenState extends State<AdminStaffScheduleScreen> {
  static const _accent = Color(0xFF2563EB);

  static const _filters = [
    (
      key: 'all',
      labelKey: 'admin_staff_schedule_filter_all',
      icon: Iconsax.truck_fast,
      color: Color(0xFF2563EB),
    ),
    (
      key: 'nurse',
      labelKey: 'admin_staff_schedule_section_nurses',
      icon: Iconsax.health,
      color: Color(0xFF0D9488),
    ),
    (
      key: 'lab',
      labelKey: 'admin_staff_schedule_section_labs',
      icon: Iconsax.microscope,
      color: Color(0xFF8B5CF6),
    ),
  ];

  static const _dayTranslationKeys = {
    'Sunday': 'admin_staff_schedule_day_sunday',
    'Monday': 'admin_staff_schedule_day_monday',
    'Tuesday': 'admin_staff_schedule_day_tuesday',
    'Wednesday': 'admin_staff_schedule_day_wednesday',
    'Thursday': 'admin_staff_schedule_day_thursday',
    'Friday': 'admin_staff_schedule_day_friday',
    'Saturday': 'admin_staff_schedule_day_saturday',
  };

  static const _orderedWeekShort = [
    ('Saturday', 'admin_staff_schedule_day_short_sat'),
    ('Sunday', 'admin_staff_schedule_day_short_sun'),
    ('Monday', 'admin_staff_schedule_day_short_mon'),
    ('Tuesday', 'admin_staff_schedule_day_short_tue'),
    ('Wednesday', 'admin_staff_schedule_day_short_wed'),
    ('Thursday', 'admin_staff_schedule_day_short_thu'),
    ('Friday', 'admin_staff_schedule_day_short_fri'),
  ];

  String _activeFilter = 'all';
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _allDrivers = [];
  bool _openedInitial = false;

  bool get _isDark => ThemeProvider().isDarkMode;

  ({String key, String labelKey, IconData icon, Color color})
      get _currentFilter =>
          _filters.firstWhere((f) => f.key == _activeFilter);

  List<Map<String, dynamic>> get _filteredDrivers {
    if (_activeFilter == 'all') return _allDrivers;
    return _allDrivers.where((d) {
      final role =
          (d['applicant_role'] ?? 'phlebotomist').toString().toLowerCase();
      final scope = (d['service_scope'] ?? 'both').toString().toLowerCase();
      if (_activeFilter == 'nurse') {
        return role == 'mobile_nurse' || role == 'both';
      }
      if (_activeFilter == 'lab') {
        return role == 'phlebotomist' || role == 'both' || scope == 'lab_sample';
      }
      return true;
    }).toList();
  }

  String _roleLabel(Map<String, dynamic> d) {
    final role = (d['applicant_role'] ?? 'phlebotomist').toString().toLowerCase();
    return switch (role) {
      'mobile_nurse' => 'admin_staff_schedule_role_nurse'.tr(),
      'phlebotomist' => 'admin_staff_schedule_role_lab'.tr(),
      'both' => 'admin_staff_schedule_role_both'.tr(),
      'courier' => 'admin_staff_schedule_role_courier'.tr(),
      _ => 'admin_staff_schedule_delivery_badge'.tr(),
    };
  }

  Color _roleColor(Map<String, dynamic> d) {
    final role = (d['applicant_role'] ?? 'phlebotomist').toString().toLowerCase();
    return switch (role) {
      'mobile_nurse' => const Color(0xFF0D9488),
      'phlebotomist' => const Color(0xFF8B5CF6),
      'both' => const Color(0xFF2563EB),
      _ => const Color(0xFF64748B),
    };
  }

  String _shiftLabel(String? s) => switch (s) {
        'morning' => 'admin_staff_schedule_shift_morning'.tr(),
        'evening' => 'admin_staff_schedule_shift_evening'.tr(),
        'full_flex' => 'admin_staff_schedule_shift_full'.tr(),
        _ => 'admin_staff_schedule_shift_custom'.tr(),
      };

  String _workDaysLabel(String? w) => switch (w) {
        'daily' => 'admin_staff_schedule_days_daily'.tr(),
        'weekdays' => 'admin_staff_schedule_days_weekdays'.tr(),
        'part_time' => 'admin_staff_schedule_days_part'.tr(),
        _ => 'admin_staff_schedule_days_daily'.tr(),
      };

  (String, Color) _dutyInfo(String? duty) => switch (duty) {
        'available' => (
            'admin_staff_schedule_duty_online'.tr(),
            const Color(0xFF10B981)
          ),
        'busy' => (
            'admin_staff_schedule_duty_busy'.tr(),
            const Color(0xFFF59E0B)
          ),
        _ => (
            'admin_staff_schedule_duty_offline'.tr(),
            const Color(0xFF94A3B8)
          ),
      };

  String _dayLabel(dynamic dayOfWeek) {
    final key = _dayTranslationKeys[dayOfWeek?.toString() ?? ''];
    return key != null ? key.tr() : (dayOfWeek?.toString() ?? '');
  }

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  @override
  void didUpdateWidget(covariant AdminStaffScheduleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDriverId != null &&
        widget.initialDriverId != oldWidget.initialDriverId) {
      final match = _allDrivers.where(
        (d) => (d['id'] as num?)?.toInt() == widget.initialDriverId,
      );
      if (match.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _openDriverSheet(match.first);
        });
      }
    }
  }

  Future<void> _loadDrivers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await ApiClient.get('/admin/schedules/providers?type=driver');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = (decoded['data'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        setState(() {
          _allDrivers = list;
          _isLoading = false;
        });

        if (!_openedInitial && widget.initialDriverId != null) {
          final match = list.where(
            (d) => (d['id'] as num?)?.toInt() == widget.initialDriverId,
          );
          if (match.isNotEmpty) {
            _openedInitial = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _openDriverSheet(match.first);
            });
          }
        }
      } else {
        setState(() {
          _error = AdminUi.readError(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openDriverSheet(Map<String, dynamic> summary) async {
    final userId = (summary['id'] as num).toInt();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DriverScheduleDetailSheet(
        userId: userId,
        summary: summary,
        dayLabel: _dayLabel,
        roleLabel: _roleLabel(summary),
        roleColor: _roleColor(summary),
        shiftLabel: _shiftLabel(summary['availability_shift']?.toString()),
        workDaysLabel: _workDaysLabel(summary['work_days']?.toString()),
        onSaved: _loadDrivers,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = _currentFilter;
    final rows = _filteredDrivers;

    final body = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, style: AdminUi.subtitle),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _loadDrivers,
                      child: Text(
                        'admin_staff_schedule_retry'.tr(),
                        style: const TextStyle(fontFamily: 'Rabar'),
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadDrivers,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    _buildDeliveryRoleTabs(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Iconsax.calendar_tick, color: filter.color, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'admin_staff_schedule_table_title'.tr(),
                            style: AdminUi.title.copyWith(fontSize: 13.5),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: filter.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${rows.length}',
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: filter.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (rows.isEmpty)
                      Container(
                        decoration: AdminUi.cardDecoration,
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'admin_staff_schedule_no_providers'.tr(
                              args: [
                                (_activeFilter == 'nurse'
                                        ? 'admin_staff_schedule_section_nurse_single'
                                        : (_activeFilter == 'lab'
                                            ? 'admin_staff_schedule_section_lab_single'
                                            : 'admin_staff_schedule_section_driver_single'))
                                    .tr(),
                              ],
                            ),
                            style: AdminUi.subtitle,
                          ),
                        ),
                      )
                    else
                      _buildScheduleTable(rows, filter.color),
                  ],
                ),
              );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AdminAppBar(
        title: 'admin_staff_schedule_title'.tr(),
        subtitle: 'admin_staff_schedule_screen_sub'.tr(),
        icon: Iconsax.truck_fast,
        iconColor: _accent,
        iconBackgroundColor: _accent.withValues(alpha: 0.1),
        showBackButton: true,
      ),
      body: body,
    );
  }

  Widget _buildDeliveryRoleTabs() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: AdminUi.cardDecoration,
      child: Row(
        children: _filters.map((f) {
          final selected = _activeFilter == f.key;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (_activeFilter == f.key) return;
                setState(() => _activeFilter = f.key);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                decoration: BoxDecoration(
                  color: selected ? f.color : Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      f.icon,
                      size: 16,
                      color: selected ? Colors.white : AdminUi.subtitle.color,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        f.labelKey.tr(),
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
    );
  }

  Widget _buildScheduleTable(
    List<Map<String, dynamic>> rows,
    Color accent,
  ) {
    final border = _isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final headerBg =
        _isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Container(
      decoration: AdminUi.cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Table Header
          Container(
            color: headerBg,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    'admin_staff_schedule_col_staff'.tr(),
                    style: AdminUi.subtitle
                        .copyWith(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    'admin_staff_schedule_col_shift'.tr(),
                    style: AdminUi.subtitle
                        .copyWith(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'admin_staff_schedule_col_orders'.tr(),
                    textAlign: TextAlign.end,
                    style: AdminUi.subtitle
                        .copyWith(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: border),

          // Table Rows
          ...rows.asMap().entries.map((entry) {
            final idx = entry.key;
            final d = entry.value;
            final roleColor = _roleColor(d);
            final roleText = _roleLabel(d);
            final (dutyLabel, dutyColor) =
                _dutyInfo(d['duty_status']?.toString());
            final start = (d['start_time'] ?? '08:00').toString();
            final end = (d['end_time'] ?? '22:00').toString();
            final shiftStr = _shiftLabel(d['availability_shift']?.toString());
            final workDaysStr = _workDaysLabel(d['work_days']?.toString());
            final upcoming = (d['upcoming_count'] as num?)?.toInt() ?? 0;
            final areas = (d['service_areas'] ?? '').toString().trim();

            final daysMap = <String, bool>{};
            for (final item in (d['days_summary'] as List? ?? [])) {
              if (item is Map) {
                daysMap[item['day_of_week']?.toString() ?? ''] =
                    item['is_available'] == true;
              }
            }

            return Column(
              children: [
                InkWell(
                  onTap: () => _openDriverSheet(d),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Col 1: Staff Name + Role + Duty
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: dutyColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          (d['name'] ?? '').toString(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AdminUi.title
                                              .copyWith(fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              roleColor.withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          roleText,
                                          style: TextStyle(
                                            fontFamily: 'Rabar',
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: roleColor,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        dutyLabel,
                                        style: AdminUi.subtitle.copyWith(
                                          fontSize: 10,
                                          color: dutyColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (areas.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      areas,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AdminUi.subtitle
                                          .copyWith(fontSize: 10),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Col 2: Website Shift, Hours & Work Days
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$start - $end',
                                    style: AdminUi.title.copyWith(
                                      fontSize: 13,
                                      color: accent,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    shiftStr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AdminUi.subtitle
                                        .copyWith(fontSize: 10.5),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    workDaysStr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AdminUi.subtitle
                                        .copyWith(fontSize: 10.5),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),

                            // Col 3: Upcoming / Times Button
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (upcoming > 0
                                              ? const Color(0xFF10B981)
                                              : accent)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      upcoming > 0
                                          ? 'admin_staff_schedule_slot_count'
                                              .tr(args: ['$upcoming'])
                                          : 'admin_staff_schedule_view_times'
                                              .tr(),
                                      style: TextStyle(
                                        fontFamily: 'Rabar',
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: upcoming > 0
                                            ? const Color(0xFF059669)
                                            : accent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 13,
                                    color: AdminUi.subtitle.color,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Compact 7-day availability strip
                        Row(
                          children: _orderedWeekShort.map((pair) {
                            final isOpen = daysMap[pair.$1] ?? true;
                            return Expanded(
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 3),
                                decoration: BoxDecoration(
                                  color: (isOpen
                                          ? const Color(0xFF10B981)
                                          : Colors.grey)
                                      .withValues(alpha: isOpen ? 0.12 : 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  pair.$2.tr(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isOpen
                                        ? const Color(0xFF059669)
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                if (idx < rows.length - 1) Divider(height: 1, color: border),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _DriverScheduleDetailSheet extends StatefulWidget {
  final int userId;
  final Map<String, dynamic> summary;
  final String Function(dynamic) dayLabel;
  final String roleLabel;
  final Color roleColor;
  final String shiftLabel;
  final String workDaysLabel;
  final Future<void> Function() onSaved;

  const _DriverScheduleDetailSheet({
    required this.userId,
    required this.summary,
    required this.dayLabel,
    required this.roleLabel,
    required this.roleColor,
    required this.shiftLabel,
    required this.workDaysLabel,
    required this.onSaved,
  });

  @override
  State<_DriverScheduleDetailSheet> createState() =>
      _DriverScheduleDetailSheetState();
}

class _DriverScheduleDetailSheetState
    extends State<_DriverScheduleDetailSheet> {
  bool _loading = true;
  String? _error;
  int _selectedDayIdx = 0;
  List<Map<String, dynamic>> _week = [];
  List<Map<String, dynamic>> _availability = [];
  List<Map<String, dynamic>> _upcoming = [];

  bool get _isDark => ThemeProvider().isDarkMode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient.get('/admin/schedules/driver/${widget.userId}');
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
          if (_selectedDayIdx >= _availability.length) _selectedDayIdx = 0;
          _loading = false;
        });
      } else {
        setState(() {
          _error = AdminUi.readError(res);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
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
    TimeOfDay start = _parseTime(
        dayRow['start_time']?.toString(), const TimeOfDay(hour: 8, minute: 0));
    TimeOfDay end = _parseTime(
        dayRow['end_time']?.toString(), const TimeOfDay(hour: 22, minute: 0));
    bool isAvail = dayRow['is_available'] == true || dayRow['is_available'] == 1;
    int slotMinutes = (dayRow['slot_minutes'] as num?)?.toInt() ?? 60;
    int slotCapacity = (dayRow['slot_capacity'] as num?)?.toInt() ?? 2;
    final maxDailyCtrl = TextEditingController(
      text: ((dayRow['max_daily_orders'] ?? 20)).toString(),
    );
    bool applyToAll = false;
    final accent = widget.roleColor;

    await AdminUi.formSheet(
      context: context,
      title: 'admin_staff_schedule_sheet_title'
          .tr(args: [widget.dayLabel(dayRow['day_of_week'])]),
      subtitle: 'admin_staff_schedule_sheet_sub'.tr(),
      submitLabel: 'admin_staff_schedule_save'.tr(),
      builder: (setSheetState, setError) {
        Widget timeBox(
            String label, TimeOfDay value, ValueChanged<TimeOfDay> onPick) {
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
                if (picked != null) setSheetState(() => onPick(picked));
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: _isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
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
                        Text(_formatTime(value),
                            style: AdminUi.title.copyWith(fontSize: 15)),
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
              color:
                  _isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Icon(Iconsax.calendar_tick, size: 20, color: accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'admin_staff_schedule_is_available'.tr(),
                    style: const TextStyle(
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
              timeBox('admin_staff_schedule_start_time'.tr(), start,
                  (v) => start = v),
              const SizedBox(width: 10),
              timeBox(
                  'admin_staff_schedule_end_time'.tr(), end, (v) => end = v),
            ],
          ),
          const SizedBox(height: 14),
          Text('admin_staff_schedule_slot_duration'.tr(),
              style: AdminUi.subtitle),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [15, 30, 45, 60, 90, 120].map((m) {
              final selected = slotMinutes == m;
              return ChoiceChip(
                label: Text('$m ${'admin_staff_schedule_minutes'.tr()}',
                    style: const TextStyle(fontFamily: 'Rabar', fontSize: 12)),
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
              color:
                  _isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('admin_staff_schedule_orders_per_slot'.tr(),
                          style: const TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      Text('admin_staff_schedule_orders_per_slot_sub'.tr(),
                          style: AdminUi.subtitle.copyWith(fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: slotCapacity > 1
                      ? () => setSheetState(() => slotCapacity--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$slotCapacity',
                    style: AdminUi.title.copyWith(fontSize: 16)),
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
            decoration: InputDecoration(
                labelText: 'admin_staff_schedule_max_daily'.tr()),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: applyToAll,
            activeColor: accent,
            onChanged: (v) => setSheetState(() => applyToAll = v ?? false),
            title: Text('admin_staff_schedule_apply_all'.tr(),
                style: const TextStyle(fontFamily: 'Rabar', fontSize: 12.5)),
          ),
        ];
      },
      onSubmit: (setError) async {
        final maxDaily = int.tryParse(maxDailyCtrl.text.trim()) ?? 20;
        if (maxDaily < 1) {
          setError('admin_staff_schedule_max_daily_err'.tr());
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
            '/admin/schedules/driver/${widget.userId}',
            body: {'schedules': _week},
          );
          if (!mounted) return true;
          if (res.statusCode == 200) {
            final data =
                jsonDecode(res.body)['data'] as Map<String, dynamic>? ?? {};
            setState(() {
              _week = (data['week'] as List? ?? _week)
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList();
              _availability = (data['availability'] as List? ?? _availability)
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList();
            });
            AdminUi.toast(context, 'admin_staff_schedule_saved'.tr());
            await widget.onSaved();
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
    final accent = widget.roleColor;
    final areas = (widget.summary['service_areas'] ?? '').toString().trim();
    final city = (widget.summary['city'] ?? '').toString().trim();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: AppColors.getBackground(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: accent.withValues(alpha: 0.12),
                    child: Icon(Iconsax.calendar_tick, color: accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (widget.summary['name'] ?? '').toString(),
                          style: AdminUi.title.copyWith(fontSize: 16),
                        ),
                        Text(
                          '${widget.roleLabel}${city.isNotEmpty ? ' • $city' : ''}',
                          style: AdminUi.subtitle.copyWith(color: accent),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!, style: AdminUi.subtitle))
                      : ListView(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.all(16),
                          children: [
                            // Website registration summary card
                            Container(
                              decoration: AdminUi.cardDecoration,
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Iconsax.global,
                                          size: 16, color: accent),
                                      const SizedBox(width: 6),
                                      Text(
                                        'admin_staff_schedule_website_info'.tr(),
                                        style: AdminUi.title
                                            .copyWith(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${'admin_staff_schedule_col_shift'.tr()}: ${widget.shiftLabel}',
                                    style:
                                        AdminUi.subtitle.copyWith(fontSize: 12),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${'admin_staff_schedule_col_days'.tr()}: ${widget.workDaysLabel}',
                                    style:
                                        AdminUi.subtitle.copyWith(fontSize: 12),
                                  ),
                                  if (areas.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      '${'admin_staff_schedule_areas'.tr()}: $areas',
                                      style: AdminUi.subtitle
                                          .copyWith(fontSize: 12),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Live slots section
                            if (_availability.isNotEmpty) ...[
                              Text(
                                'admin_staff_schedule_booked_tab'.tr(),
                                style: AdminUi.title,
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 64,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _availability.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (_, i) {
                                    final d = _availability[i];
                                    final active = i == _selectedDayIdx;
                                    final dateStr =
                                        (d['date'] ?? '').toString();
                                    final shortDate = dateStr.length >= 10
                                        ? dateStr.substring(5)
                                        : dateStr;
                                    final closed = d['closed'] == true;
                                    return GestureDetector(
                                      onTap: () =>
                                          setState(() => _selectedDayIdx = i),
                                      child: Container(
                                        width: 84,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: active
                                              ? accent
                                              : (_isDark
                                                  ? const Color(0xFF1E293B)
                                                  : Colors.white),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: active
                                                ? accent
                                                : (_isDark
                                                    ? const Color(0xFF334155)
                                                    : const Color(0xFFE2E8F0)),
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              i == 0
                                                  ? 'admin_staff_schedule_today'
                                                      .tr()
                                                  : widget.dayLabel(
                                                      d['day_of_week']),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontFamily: 'Rabar',
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: active
                                                    ? Colors.white
                                                    : AdminUi.title.color,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              closed
                                                  ? 'admin_staff_schedule_off'
                                                      .tr()
                                                  : shortDate,
                                              style: TextStyle(
                                                fontFamily: 'Rabar',
                                                fontSize: 10.5,
                                                color: active
                                                    ? Colors.white70
                                                    : (closed
                                                        ? const Color(
                                                            0xFFEF4444)
                                                        : AdminUi
                                                            .subtitle.color),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildDaySlotsCard(accent),
                              const SizedBox(height: 16),
                            ],

                            // Upcoming scheduled orders
                            Text(
                              '${'admin_staff_schedule_upcoming_title'.tr()} (${_upcoming.length})',
                              style: AdminUi.title,
                            ),
                            const SizedBox(height: 8),
                            if (_upcoming.isEmpty)
                              Container(
                                decoration: AdminUi.cardDecoration,
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: Text(
                                    'admin_staff_schedule_no_upcoming'.tr(),
                                    style: AdminUi.subtitle,
                                  ),
                                ),
                              )
                            else
                              ..._upcoming.map((o) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: AdminUi.cardDecoration,
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Icon(Iconsax.calendar_tick,
                                            color: accent, size: 18),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '#${o['id']} • ${o['patient_name'] ?? 'admin_staff_schedule_patient_default'.tr()}',
                                                style: AdminUi.title
                                                    .copyWith(fontSize: 13),
                                              ),
                                              Text(
                                                'admin_staff_schedule_time_label'
                                                    .tr(args: [
                                                  '${o['scheduled_at'] ?? ''}'
                                                ]),
                                                style: AdminUi.subtitle
                                                    .copyWith(
                                                        fontSize: 11.5,
                                                        color: accent),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                            const SizedBox(height: 16),

                            // Weekly editable schedule
                            Text('admin_staff_schedule_weekly_tab'.tr(),
                                style: AdminUi.title),
                            const SizedBox(height: 8),
                            ..._week.map((row) {
                              final isAvail = row['is_available'] == true ||
                                  row['is_available'] == 1;
                              return InkWell(
                                onTap: () => _editDay(row),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: AdminUi.cardDecoration,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 11),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isAvail
                                            ? Iconsax.clock
                                            : Iconsax.close_circle,
                                        size: 18,
                                        color: isAvail ? accent : Colors.grey,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          widget.dayLabel(row['day_of_week']),
                                          style: AdminUi.title
                                              .copyWith(fontSize: 13),
                                        ),
                                      ),
                                      Text(
                                        isAvail
                                            ? '${row['start_time']} - ${row['end_time']}'
                                            : 'admin_staff_schedule_off_inactive'
                                                .tr(),
                                        style: AdminUi.subtitle.copyWith(
                                          fontSize: 12,
                                          color: isAvail ? accent : Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(Iconsax.edit,
                                          size: 16, color: accent),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySlotsCard(Color accent) {
    final day = _availability[_selectedDayIdx];
    final slots = (day['slots'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return Container(
      decoration: AdminUi.cardDecoration,
      padding: const EdgeInsets.all(12),
      child: slots.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'admin_staff_schedule_no_slots_day'.tr(),
                  style: AdminUi.subtitle,
                ),
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
                final bg = past
                    ? Colors.grey.withValues(alpha: 0.12)
                    : (taken
                        ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                        : accent.withValues(alpha: 0.12));
                final fg = past
                    ? Colors.grey
                    : (taken ? const Color(0xFFDC2626) : accent);
                final tag = past
                    ? 'admin_staff_schedule_past'.tr()
                    : (taken
                        ? 'admin_staff_schedule_taken'.tr()
                        : '$booked/$cap');

                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${s['time']} • $tag',
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: fg,
                      decoration:
                          (!past && taken) ? TextDecoration.lineThrough : null,
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
