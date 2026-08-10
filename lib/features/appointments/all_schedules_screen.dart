import 'package:flutter/material.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import '../doctors/doctor_details_screen.dart';
import '../queue/virtual_waiting_room_screen.dart';
import 'dart:convert';
import '../../core/utils/api_client.dart';

class AllSchedulesScreen extends StatefulWidget {
  const AllSchedulesScreen({super.key});

  @override
  State<AllSchedulesScreen> createState() => _AllSchedulesScreenState();
}

class _AllSchedulesScreenState extends State<AllSchedulesScreen> {
  bool _isLoading = true;
  List<dynamic> _appointments = [];

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.get('/appointments');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _appointments = data['data'] ?? [];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching appointments: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelAppointment(int id) async {
    try {
      final response = await ApiClient.delete('/appointments/$id');
      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment cancelled successfully.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        _fetchAppointments(); // Refresh list
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel appointment: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'my_appointments'.tr(),
          style: GoogleFonts.poppins(
            color: const Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _appointments.isEmpty
              ? Center(child: Text('You have no appointments.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    children: [
                      // ── Schedule Cards ──
                      ...List.generate(_appointments.length, (index) {
                        final s = _appointments[index];
                        final doctor = s['doctor'] != null && s['doctor']['user'] != null ? s['doctor']['user']['name'] : 'Doctor';
                        final specialty = s['doctor'] != null ? s['doctor']['specialty'] : 'Specialty';
                        final dateStr = s['appointment_date'];
                        final DateTime dateTime = DateTime.parse(dateStr);
                        final date = '${dateTime.year}-${dateTime.month}-${dateTime.day}';
                        final time = '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
                        final image = (s['doctor'] != null && s['doctor']['image_path'] != null)
                            ? ApiClient.getImageUrl(s['doctor']['image_path'])
                            : 'assets/images/doctor1.png';
                        final doctorId = s['doctor_id'];

                        return Padding(
                          padding: const EdgeInsetsDirectional.only(bottom: 16),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DoctorDetailsScreen(
                                    doctorId: doctorId,
                                    name: doctor,
                                    specialty: specialty ?? '',
                                    image: image,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                        ),
                                        clipBehavior: Clip.hardEdge,
                                        child: (s['doctor'] != null && s['doctor']['image_path'] != null)
                                            ? Image.network(image, fit: BoxFit.cover, alignment: Alignment.topCenter)
                                            : Image.asset(image, fit: BoxFit.cover, alignment: Alignment.topCenter),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              doctor,
                                              style: GoogleFonts.poppins(
                                                color: const Color(0xFF0F172A),
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              specialty ?? '',
                                              style: GoogleFonts.poppins(
                                                color: const Color(0xFF94A3B8),
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: s['status'] == 'pending' 
                                            ? const Color(0xFFF59E0B).withValues(alpha: 0.1) 
                                            : const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          s['status'] == 'pending' ? 'Pending' : (s['status'] ?? 'upcoming'),
                                          style: GoogleFonts.poppins(
                                            color: s['status'] == 'pending' ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Iconsax.calendar_1, size: 18, color: Color(0xFF64748B)),
                                          const SizedBox(width: 8),
                                          Text(
                                            date,
                                            style: GoogleFonts.poppins(
                                              color: const Color(0xFF64748B),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 24),
                                      Row(
                                        children: [
                                          const Icon(Iconsax.clock, size: 18, color: Color(0xFF64748B)),
                                          const SizedBox(width: 8),
                                          Text(
                                            time,
                                            style: GoogleFonts.poppins(
                                              color: const Color(0xFF64748B),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  if (s['status'] != 'cancelled' && s['status'] != 'completed')
                                    Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () => _cancelAppointment(s['id']),
                                            child: Container(
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(24),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'cancel_appointment'.tr(),
                                                  style: GoogleFonts.poppins(
                                                    color: const Color(0xFF64748B),
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
                                                    doctorName: doctor,
                                                    specialty: specialty ?? '',
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
                                                  const Icon(Iconsax.people, color: Colors.white, size: 18),
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
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: (100 * index).ms).slideY(begin: 0.1, end: 0);
                      }),
                      const SizedBox(height: 100), // padding for bottom nav
                    ],
                  ),
                ),
    );
  }
}
