import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/models/appointment_model.dart';
import '../../core/providers/appointment_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'appointment_confirmation_screen.dart';

/// Date and time picker for a booking.
///
/// The backend has no slot table and no availability endpoint — it stores one
/// `appointment_date` per appointment and only requires it to be in the future.
/// So this offers a date strip plus a time picker rather than fetching slots
/// that do not exist. `available_days` on the doctor is used to grey out days
/// the doctor does not work.
class BookingSlotScreen extends StatefulWidget {
  final Doctor doctor;

  const BookingSlotScreen({super.key, required this.doctor});

  @override
  State<BookingSlotScreen> createState() => _BookingSlotScreenState();
}

class _BookingSlotScreenState extends State<BookingSlotScreen> {
  static const _daysShown = 14;
  static const _weekdayNames = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
  AppointmentType _type = AppointmentType.inPerson;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = _firstBookableDate();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// Earliest day from tomorrow onward that the doctor actually works.
  DateTime _firstBookableDate() {
    final start = DateUtils.dateOnly(DateTime.now().add(const Duration(days: 1)));
    for (var i = 0; i < _daysShown; i++) {
      final day = start.add(Duration(days: i));
      if (_doctorWorksOn(day)) return day;
    }
    return start;
  }

  /// `available_days` holds weekday names. An empty list means the doctor has
  /// not set a schedule, so treat every day as bookable rather than blocking
  /// the whole calendar.
  bool _doctorWorksOn(DateTime day) {
    final days = widget.doctor.availableDays;
    if (days.isEmpty) return true;

    final name = _weekdayNames[day.weekday - 1].toLowerCase();
    return days.any((d) => d.toLowerCase().startsWith(name));
  }

  /// Combines the chosen day and time. Null until a time is picked.
  DateTime? get _chosenDateTime {
    final time = _selectedTime;
    if (time == null) return null;
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      time.hour,
      time.minute,
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _continue() {
    final when = _chosenDateTime;
    if (when == null) return;

    context.read<AppointmentProvider>().selectDoctor(widget.doctor);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppointmentConfirmationScreen(
          doctor: widget.doctor,
          when: when,
          type: _type,
          notes: _notesController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _chosenDateTime != null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Choose a time', style: AppTypography.headingSm),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DoctorSummary(doctor: widget.doctor),
            const SizedBox(height: 24),
            _SectionLabel('Date'),
            const SizedBox(height: 12),
            _buildDateStrip(),
            const SizedBox(height: 24),
            _SectionLabel('Time'),
            const SizedBox(height: 12),
            _buildTimeField(),
            const SizedBox(height: 24),
            _SectionLabel('Visit type'),
            const SizedBox(height: 12),
            _buildTypeSelector(),
            const SizedBox(height: 24),
            _SectionLabel('Notes for the doctor (optional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              maxLength: 500,
              decoration: _inputDecoration('Symptoms, medications, anything relevant'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: canContinue ? _continue : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.textLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Review booking',
                  style: AppTypography.button.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateStrip() {
    final start = DateUtils.dateOnly(DateTime.now().add(const Duration(days: 1)));

    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _daysShown,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = start.add(Duration(days: index));
          final bookable = _doctorWorksOn(day);
          final selected = DateUtils.isSameDay(day, _selectedDate);

          return Semantics(
            button: true,
            selected: selected,
            enabled: bookable,
            child: InkWell(
              onTap: bookable ? () => setState(() => _selectedDate = day) : null,
              borderRadius: BorderRadius.circular(12),
              child: Opacity(
                opacity: bookable ? 1 : 0.35,
                child: Container(
                  width: 62,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.cardBorderLight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _weekdayNames[day.weekday - 1],
                        style: AppTypography.labelSm.copyWith(
                          color: selected ? Colors.white : AppColors.textMedium,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${day.day}',
                        style: AppTypography.labelLg.copyWith(
                          color: selected ? Colors.white : AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeField() {
    final time = _selectedTime;

    return InkWell(
      onTap: _pickTime,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.cardBorderLight),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Iconsax.clock, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              time == null ? 'Pick a time' : time.format(context),
              style: AppTypography.bodyMd.copyWith(
                color: time == null ? AppColors.textMedium : AppColors.textDark,
              ),
            ),
            const Spacer(),
            Icon(Iconsax.arrow_down_1, size: 18, color: AppColors.textMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: AppointmentType.values.map((type) {
        final selected = _type == type;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: type == AppointmentType.values.last ? 0 : 8),
            child: InkWell(
              onTap: () => setState(() => _type = type),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : Colors.transparent,
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.cardBorderLight,
                    width: selected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  type.displayName,
                  style: AppTypography.labelMd.copyWith(
                    color: selected ? AppColors.primary : AppColors.textDark,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color),
        );

    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.bodySm.copyWith(color: AppColors.textMedium),
      border: border(AppColors.cardBorderLight),
      enabledBorder: border(AppColors.cardBorderLight),
      focusedBorder: border(AppColors.primary),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTypography.labelLg.copyWith(color: AppColors.textDark),
      );
}

class _DoctorSummary extends StatelessWidget {
  final Doctor doctor;
  const _DoctorSummary({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorderLight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          DoctorAvatar(imageUrl: doctor.imageUrl, size: 56),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.name,
                  style: AppTypography.labelMd.copyWith(color: AppColors.textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  doctor.specialty,
                  style: AppTypography.bodySm.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          Text(
            doctor.formattedFee,
            style: AppTypography.labelMd.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

/// Shared avatar so a missing or broken photo never leaves a blank box.
class DoctorAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const DoctorAvatar({super.key, required this.imageUrl, this.size = 56});

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      Iconsax.user,
      size: size * 0.45,
      color: AppColors.primary,
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceLightSecondary,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl == null
          ? fallback
          : Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            ),
    );
  }
}
