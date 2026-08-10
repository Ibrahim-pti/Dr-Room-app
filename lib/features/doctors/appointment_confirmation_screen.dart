import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/models/appointment_model.dart';
import '../../core/providers/appointment_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'booking_slot_screen.dart' show DoctorAvatar;

/// Final review before the booking is sent.
///
/// There is deliberately no payment step here. The backend exposes no
/// `/payments/*` routes and `appointments` has no transaction column, so
/// routing the user into a card form would only fail after they entered their
/// details. The fee is shown as payable at the visit; wire payment in once the
/// endpoints exist.
class AppointmentConfirmationScreen extends StatefulWidget {
  final Doctor doctor;
  final DateTime when;
  final AppointmentType type;
  final String notes;

  const AppointmentConfirmationScreen({
    super.key,
    required this.doctor,
    required this.when,
    required this.type,
    required this.notes,
  });

  @override
  State<AppointmentConfirmationScreen> createState() =>
      _AppointmentConfirmationScreenState();
}

class _AppointmentConfirmationScreenState
    extends State<AppointmentConfirmationScreen> {
  bool _agreed = false;

  Future<void> _confirm() async {
    final provider = context.read<AppointmentProvider>();

    final booked = await provider.bookAppointment(
      when: widget.when,
      type: widget.type,
      notes: widget.notes,
    );

    if (!mounted) return;

    if (booked) {
      await _showSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Could not book the appointment'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _showSuccess() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Iconsax.tick_circle,
                    color: AppColors.success, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                'Appointment requested',
                style: AppTypography.headingSm.copyWith(color: AppColors.textDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.doctor.name} will confirm your booking. '
                'You can see it under your appointments.',
                style: AppTypography.bodySm.copyWith(color: AppColors.textMedium),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Done',
                      style: AppTypography.button.copyWith(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (mounted) {
      // Unwind the booking flow back to wherever it was entered from.
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBooking = context.watch<AppointmentProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text('Confirm booking', style: AppTypography.headingSm),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDoctorCard(),
            const SizedBox(height: 24),
            Text('Details',
                style: AppTypography.labelLg.copyWith(color: AppColors.textDark)),
            const SizedBox(height: 12),
            _DetailRow(
              icon: Iconsax.calendar,
              label: 'When',
              value: _formatWhen(),
            ),
            const SizedBox(height: 8),
            _DetailRow(
              icon: Iconsax.hospital,
              label: 'Visit type',
              value: widget.type.displayName,
            ),
            if (widget.notes.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              _DetailRow(
                icon: Iconsax.note,
                label: 'Notes',
                value: widget.notes.trim(),
              ),
            ],
            const SizedBox(height: 24),
            _buildFeeCard(),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _agreed,
              onChanged: (v) => setState(() => _agreed = v ?? false),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                'I agree to the booking and cancellation terms',
                style: AppTypography.bodySm.copyWith(color: AppColors.textDark),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_agreed && !isBooking) ? _confirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.textLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isBooking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text('Confirm booking',
                        style: AppTypography.button.copyWith(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'You can cancel any time before the visit.',
                style: AppTypography.bodySm.copyWith(color: AppColors.textMedium),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorderLight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          DoctorAvatar(imageUrl: widget.doctor.imageUrl, size: 64),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.doctor.name,
                  style: AppTypography.labelMd.copyWith(color: AppColors.textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.doctor.specialty,
                  style: AppTypography.bodySm.copyWith(color: AppColors.primary),
                ),
                if (widget.doctor.totalReviews > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Iconsax.star, size: 13, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.doctor.rating} (${widget.doctor.totalReviews})',
                        style: AppTypography.bodySm
                            .copyWith(color: AppColors.textMedium),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLightSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Consultation fee',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.textDark)),
              Text(
                widget.doctor.formattedFee,
                style: AppTypography.headingSm.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Iconsax.info_circle, size: 15, color: AppColors.textMedium),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Payable at the clinic. No card is charged now.',
                  style: AppTypography.bodySm.copyWith(color: AppColors.textMedium),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatWhen() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final w = widget.when;
    final hour12 = w.hour % 12 == 0 ? 12 : w.hour % 12;
    final period = w.hour < 12 ? 'AM' : 'PM';
    final minute = w.minute.toString().padLeft(2, '0');

    return '${months[w.month - 1]} ${w.day}, ${w.year} • $hour12:$minute $period';
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLightSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTypography.bodySm
                        .copyWith(color: AppColors.textMedium)),
                const SizedBox(height: 4),
                Text(value,
                    style: AppTypography.labelSm
                        .copyWith(color: AppColors.textDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
