import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  String _activeFilter = 'all'; // all | nurse | lab (all inside Delivery)
  int _innerTab = 0; // 0: weekly schedule, 1: slots & upcoming bookings
  int _selectedDayIndex = 0;

  bool _isLoadingProviders = true;
  bool _isLoadingDetail = false;
  String? _error;

  List<Map<String, dynamic>> _allDrivers = [];
  int? _selectedProviderId;

  List<Map<String, dynamic>> _week = [];
  List<Map<String, dynamic>> _availability = [];
  List<Map<String, dynamic>> _upcoming = [];

  bool get _isDark => ThemeProvider().isDarkMode;

  ({String key, String labelKey, IconData icon, Color color})
      get _currentFilter =>
          _filters.firstWhere((f) => f.key == _activeFilter);

  List<Map<String, dynamic>> get _filteredDrivers {
    if (_activeFilter == 'all') return _allDrivers;
    return _allDrivers.where((d) {
      final role = (d['applicant_role'] ?? 'phlebotomist').toString().toLowerCase();
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

  String _dayLabel(dynamic dayOfWeek) {
    final key = _dayTranslationKeys[dayOfWeek?.toString() ?? ''];
    return key != null ? key.tr() : (dayOfWeek?.toString() ?? '');
  }

  @override
  void initState() {
    super.initState();
    _selectedProviderId = widget.initialDriverId;
    _loadProviders();
  }

  @override
  void didUpdateWidget(covariant AdminStaffScheduleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDriverId != null &&
        widget.initialDriverId != oldWidget.initialDriverId &&
        widget.initialDriverId != _selectedProviderId) {
      setState(() => _activeFilter = 'all');
      final exists = _allDrivers
          .any((d) => (d['id'] as num?)?.toInt() == widget.initialDriverId);
      if (exists) {
        setState(() => _selectedProviderId = widget.initialDriverId);
        _loadProviderDetail(widget.initialDriverId!);
      } else {
        _selectedProviderId = widget.initialDriverId;
      }
    }
  }

  Future<void> _loadProviders() async {
    setState(() {
      _isLoadingProviders = true;
      _error = null;
      _allDrivers = [];
      _selectedProviderId ??= widget.initialDriverId;
      _week = [];
      _availability = [];
      _upcoming = [];
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
          _isLoadingProviders = false;
        });
        _syncSelectedWithFilter();
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

  void _syncSelectedWithFilter() {
    final visible = _filteredDrivers;
    final stillValid = visible.any((d) => (d['id'] as num?)?.toInt() == _selectedProviderId);
    final nextId = stillValid
        ? _selectedProviderId
        : (visible.isNotEmpty ? (visible.first['id'] as num?)?.toInt() : null);

    setState(() {
      _selectedProviderId = nextId;
      if (nextId == null) {
        _week = [];
        _availability = [];
        _upcoming = [];
      }
    });

    if (nextId != null) {
      _loadProviderDetail(nextId);
    }
  }

  Future<void> _loadProviderDetail(int userId) async {
    setState(() => _isLoadingDetail = true);
    try {
      final res = await ApiClient.get('/admin/schedules/driver/$userId');
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
        _parseTime(dayRow['end_time']?.toString(), const TimeOfDay(hour: 23, minute: 0));
    bool isAvail = dayRow['is_available'] == true || dayRow['is_available'] == 1;
    int slotMinutes = (dayRow['slot_minutes'] as num?)?.toInt() ?? 60;
    int slotCapacity = (dayRow['slot_capacity'] as num?)?.toInt() ?? 2;
    final maxDailyCtrl = TextEditingController(
      text: ((dayRow['max_daily_orders'] ?? 20)).toString(),
    );
    bool applyToAll = false;

    final accent = _currentFilter.color;

    await AdminUi.formSheet(
      context: context,
      title: 'admin_staff_schedule_sheet_title'
          .tr(args: [_dayLabel(dayRow['day_of_week'])]),
      subtitle: 'admin_staff_schedule_sheet_sub'.tr(),
      submitLabel: 'admin_staff_schedule_save'.tr(),
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
              timeBox('admin_staff_schedule_start_time'.tr(), start, (v) => start = v),
              const SizedBox(width: 10),
              timeBox('admin_staff_schedule_end_time'.tr(), end, (v) => end = v),
            ],
          ),
          const SizedBox(height: 14),
          Text('admin_staff_schedule_slot_duration'.tr(), style: AdminUi.subtitle),
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
                      Text(
                        'admin_staff_schedule_orders_per_slot'.tr(),
                        style: const TextStyle(fontFamily: 'Rabar', fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'admin_staff_schedule_orders_per_slot_sub'.tr(),
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
            decoration: InputDecoration(
              labelText: 'admin_staff_schedule_max_daily'.tr(),
            ),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: applyToAll,
            activeColor: accent,
            onChanged: (v) => setSheetState(() => applyToAll = v ?? false),
            title: Text(
              'admin_staff_schedule_apply_all'.tr(),
              style: const TextStyle(fontFamily: 'Rabar', fontSize: 12.5),
            ),
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
            '/admin/schedules/driver/${_selectedProviderId!}',
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
            AdminUi.toast(context, 'admin_staff_schedule_saved'.tr());
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
    final filter = _currentFilter;
    final visibleDrivers = _filteredDrivers;

    final body = _isLoadingProviders
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, style: AdminUi.subtitle),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _loadProviders,
                      child: Text('admin_staff_schedule_retry'.tr(),
                          style: const TextStyle(fontFamily: 'Rabar')),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  // Delivery sub-filters: All | Nurses | Labs
                  _buildDeliveryRoleTabs(),
                  if (visibleDrivers.isEmpty)
                    Expanded(
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
                    Expanded(
                      child: Column(
                        children: [
                          _buildProviderPicker(visibleDrivers, filter.color),
                          _buildInnerToggle(filter.color),
                          Expanded(
                            child: _isLoadingDetail
                                ? const Center(child: CircularProgressIndicator())
                                : (_innerTab == 0
                                    ? _buildWeeklyList(filter.color)
                                    : _buildSlotsAndBookings(filter.color)),
                          ),
                        ],
                      ),
                    ),
                ],
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: AdminUi.cardDecoration,
        child: Row(
          children: _filters.map((f) {
            final selected = _activeFilter == f.key;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_activeFilter == f.key) return;
                  setState(() {
                    _activeFilter = f.key;
                    _innerTab = 0;
                    _selectedDayIndex = 0;
                  });
                  _syncSelectedWithFilter();
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
      ),
    );
  }

  Widget _buildProviderPicker(List<Map<String, dynamic>> drivers, Color accent) {
    final driverLabel = 'admin_staff_schedule_section_driver_single'.tr();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: DropdownButtonFormField<int>(
        initialValue: _selectedProviderId,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'admin_staff_schedule_choose_provider'.tr(args: [driverLabel]),
          prefixIcon: Icon(Iconsax.truck_fast, color: accent, size: 20),
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
        items: drivers.map((p) {
          final id = (p['id'] as num).toInt();
          final upcoming = (p['upcoming_count'] as num?)?.toInt() ?? 0;
          final name = (p['name'] ?? driverLabel).toString();
          final roleText = _roleLabel(p);
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
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    roleText,
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                ),
                if (upcoming > 0) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'admin_staff_schedule_slot_count'.tr(args: ['$upcoming']),
                      style: const TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ),
                ],
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
          pill(0, 'admin_staff_schedule_weekly_tab'.tr(), Iconsax.clock),
          const SizedBox(width: 10),
          pill(1, '${'admin_staff_schedule_booked_tab'.tr()} (${_upcoming.length})', Iconsax.calendar_1),
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
        final dayName = _dayLabel(row['day_of_week']);
        final isAvail = row['is_available'] == true || row['is_available'] == 1;
        final slotMin = row['slot_minutes'] ?? 60;
        final cap = row['slot_capacity'] ?? 2;
        final maxDaily = row['max_daily_orders'] ?? 20;

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
                            ? '${row['start_time']} - ${row['end_time']}  •  $slotMin ${'admin_staff_schedule_minutes'.tr()}'
                            : 'admin_staff_schedule_off_inactive'.tr(),
                        style: AdminUi.subtitle.copyWith(fontSize: 12),
                      ),
                      if (isAvail) ...[
                        const SizedBox(height: 4),
                        Text(
                          'admin_staff_schedule_per_slot_max'
                              .tr(args: ['$cap', '$maxDaily']),
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
                final dayLabel = _dayLabel(d['day_of_week']);
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
                          i == 0 ? 'admin_staff_schedule_today'.tr() : dayLabel,
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
                          closed ? 'admin_staff_schedule_off'.tr() : shortDate,
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
                      child: Text('admin_staff_schedule_no_slots_day'.tr(),
                          style: AdminUi.subtitle),
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
                        tag = 'admin_staff_schedule_past'.tr();
                      } else if (taken) {
                        bg = const Color(0xFFEF4444).withValues(alpha: 0.12);
                        fg = const Color(0xFFDC2626);
                        tag = 'admin_staff_schedule_taken'.tr();
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
        Text('admin_staff_schedule_upcoming_title'.tr(), style: AdminUi.title),
        const SizedBox(height: 8),
        if (_upcoming.isEmpty)
          Container(
            decoration: AdminUi.cardDecoration,
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text('admin_staff_schedule_no_upcoming'.tr(),
                  style: AdminUi.subtitle),
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
                            '#${o['id']}  •  ${o['patient_name'] ?? 'admin_staff_schedule_patient_default'.tr()}',
                            style: AdminUi.title.copyWith(fontSize: 13.5),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'admin_staff_schedule_time_label'
                                .tr(args: ['${o['scheduled_at'] ?? ''}']),
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
