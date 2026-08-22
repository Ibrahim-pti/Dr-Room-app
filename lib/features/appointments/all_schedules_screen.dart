import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../doctors/doctor_details_screen.dart';
import '../queue/virtual_waiting_room_screen.dart';
import '../../core/models/appointment_model.dart';
import '../../core/providers/appointment_provider.dart';
import '../../core/utils/api_client.dart';
import '../../core/widgets/shimmer_loading_list.dart';

class AllSchedulesScreen extends StatefulWidget {
  final bool embedded;

  const AllSchedulesScreen({super.key, this.embedded = false});

  @override
  State<AllSchedulesScreen> createState() => AllSchedulesScreenState();
}

class AllSchedulesScreenState extends State<AllSchedulesScreen> {
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppointmentProvider>().fetchAppointments();
    });
  }

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
              ? 'appointment_cancelled_success'.tr()
              : 'cancel_failed'.tr(),
          style: _kStyle(color: Colors.white),
        ),
        backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final content = _buildContent(isDark);

    if (widget.embedded) return content;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'my_appointments'.tr(),
          style: _kStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: content,
    );
  }

  Widget _buildContent(bool isDark) {
    return Consumer<AppointmentProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.appointments.isEmpty) {
          return const ShimmerLoadingList();
        }

        final appointments = [...provider.appointments]
          ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));

        if (appointments.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => provider.fetchAppointments(),
            child: _buildEmptyState(isDark),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchAppointments(),
          child: ListView.builder(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
            itemCount: appointments.length,
            itemBuilder: (context, index) =>
                _buildAppointmentCard(appointments[index], index, isDark),
          ),
        );
      },
    );
  }

  Widget _buildAppointmentCard(Appointment appointment, int index, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final image = appointment.doctorImagePath != null
        ? ApiClient.getImageUrl(appointment.doctorImagePath!)
        : 'assets/images/doctor1.png';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
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
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.2), width: 2),
                    ),
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
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.doctorName,
                          style: _kStyle(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          appointment.doctorSpecialty,
                          style: _kStyle(
                            color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            fontSize: 12.5,
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
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Iconsax.calendar_1, size: 16, color: Color(0xFF3B82F6)),
                        const SizedBox(width: 6),
                        Text(
                          appointment.formattedDate,
                          style: _kStyle(
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Iconsax.clock, size: 16, color: Color(0xFF3B82F6)),
                        const SizedBox(width: 6),
                        Text(
                          appointment.formattedTime,
                          style: _kStyle(
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (appointment.canCancel) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _cancelAppointment(appointment),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: borderColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(
                          'cancel_appointment'.tr(),
                          style: _kStyle(
                            color: const Color(0xFFEF4444),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
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
                        icon: const Icon(Iconsax.people, color: Colors.white, size: 16),
                        label: Text(
                          'چوونەژوورەوە',
                          style: _kStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
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
    ).animate().fadeIn(delay: (60 * index).ms).slideY(begin: 0.05, end: 0);
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isKurdish ? status.kurdiName : status.displayName,
        style: _kStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.calendar_1, color: Color(0xFF3B82F6), size: 36),
              ),
              const SizedBox(height: 18),
              Text(
                'no_appointments'.tr(),
                textAlign: TextAlign.center,
                style: _kStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'no_appointments_desc'.tr(),
                  textAlign: TextAlign.center,
                  style: _kStyle(
                    color: const Color(0xFF94A3B8),
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