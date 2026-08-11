import 'package:flutter/material.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../doctors/doctor_details_screen.dart';
import '../queue/virtual_waiting_room_screen.dart';
import '../../core/models/appointment_model.dart';
import '../../core/providers/appointment_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_client.dart';
import '../../core/widgets/shimmer_loading_list.dart';

class AllSchedulesScreen extends StatefulWidget {
  /// When true the screen renders only its content, so it can sit inside the
  /// My Requests tab under that screen's own app bar.
  final bool embedded;

  const AllSchedulesScreen({super.key, this.embedded = false});

  @override
  State<AllSchedulesScreen> createState() => AllSchedulesScreenState();
}

class AllSchedulesScreenState extends State<AllSchedulesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppointmentProvider>().fetchAppointments();
    });
  }

  /// Called by the shell when the tab is reopened, so a booking made or
  /// cancelled elsewhere shows up without a manual pull.
  void refresh() {
    if (mounted) context.read<AppointmentProvider>().fetchAppointments();
  }

  Future<void> _cancelAppointment(Appointment appointment) async {
    final provider = context.read<AppointmentProvider>();
    final success = await provider.cancelAppointment(appointment.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'appointment_cancelled'.tr()
              : 'appointment_cancel_failed'.tr(),
        ),
        backgroundColor:
            success ? const Color(0xFF10B981) : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();

    if (widget.embedded) return content;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.getTextTitle(context),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'my_appointments'.tr(),
          style: GoogleFonts.poppins(
            color: AppColors.getTextTitle(context),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: content,
    );
  }

  Widget _buildContent() {
    return Consumer<AppointmentProvider>(
      builder: (context, provider, child) {
        // Only a first load takes over the screen; later refreshes leave the
        // list in place instead of flashing back to skeletons.
        if (provider.isLoading && provider.appointments.isEmpty) {
          return const ShimmerLoadingList();
        }

        final appointments = [...provider.appointments]
          ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));

        if (appointments.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => provider.fetchAppointments(),
            child: _buildEmptyState(),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchAppointments(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
            itemCount: appointments.length,
            itemBuilder: (context, index) =>
                _buildAppointmentCard(appointments[index], index),
          ),
        );
      },
    );
  }

  Widget _buildAppointmentCard(Appointment appointment, int index) {
    final image = appointment.doctorImagePath != null
        ? ApiClient.getImageUrl(appointment.doctorImagePath!)
        : 'assets/images/doctor1.png';

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DoctorDetailsScreen(
                doctorId: appointment.doctorId,
                name: appointment.doctorName,
                specialty: appointment.doctorSpecialty,
                image: image,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.getSurface(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.getBorder(context)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    clipBehavior: Clip.hardEdge,
                    child: appointment.doctorImagePath != null
                        ? Image.network(
                            image,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            errorBuilder: (context, error, stack) => Image.asset(
                              'assets/images/doctor1.png',
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset(
                            image,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.doctorName,
                          style: GoogleFonts.poppins(
                            color: AppColors.getTextTitle(context),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appointment.doctorSpecialty,
                          style: GoogleFonts.poppins(
                            color: AppColors.getTextSubtitle(context),
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(appointment.status),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Iconsax.calendar_1,
                      size: 18, color: AppColors.getTextSubtitle(context)),
                  const SizedBox(width: 8),
                  Text(
                    appointment.formattedDate,
                    style: GoogleFonts.poppins(
                      color: AppColors.getTextSubtitle(context),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Icon(Iconsax.clock,
                      size: 18, color: AppColors.getTextSubtitle(context)),
                  const SizedBox(width: 8),
                  Text(
                    appointment.formattedTime,
                    style: GoogleFonts.poppins(
                      color: AppColors.getTextSubtitle(context),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              // The model already knows when the API would reject a cancel, so
              // the buttons never offer an action that comes back as an error.
              if (appointment.canCancel) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _cancelAppointment(appointment),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.getSurfaceSecondary(context),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Center(
                            child: Text(
                              'cancel_appointment'.tr(),
                              style: GoogleFonts.poppins(
                                color: AppColors.getTextSubtitle(context),
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VirtualWaitingRoomScreen(
                                doctorName: appointment.doctorName,
                                specialty: appointment.doctorSpecialty,
                                image: image,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Iconsax.people,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'join_now'.tr(),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (100 * index).ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStatusChip(AppointmentStatus status) {
    final color = switch (status) {
      AppointmentStatus.pending => const Color(0xFFF59E0B),
      AppointmentStatus.confirmed => const Color(0xFF3B82F6),
      AppointmentStatus.completed => const Color(0xFF10B981),
      AppointmentStatus.cancelled => const Color(0xFFEF4444),
    };

    final isKurdish = context.locale.languageCode == 'ckb';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isKurdish ? status.kurdiName : status.displayName,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Scrollable so pull-to-refresh still works with nothing in the list.
  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(Iconsax.calendar_1,
                    color: AppColors.primary, size: 38),
              ),
              const SizedBox(height: 20),
              Text(
                'no_appointments'.tr(),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: AppColors.getTextTitle(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  'no_appointments_hint'.tr(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: AppColors.getTextSubtitle(context),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
