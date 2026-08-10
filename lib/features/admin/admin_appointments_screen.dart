import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'dart:convert';
import '../../core/utils/api_client.dart';
import '../../core/theme/app_colors.dart';

class AdminAppointmentsScreen extends StatefulWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  State<AdminAppointmentsScreen> createState() =>
      _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState extends State<AdminAppointmentsScreen> {
  List<dynamic> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.get('/admin/appointments');
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _appointments = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      case 'confirmed':
        return AppColors.primary;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      margin: const EdgeInsets.only(left: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.getSurface(context),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.getTextTitle(context),
                        size: 20,
                      ),
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Iconsax.calendar_tick,
                      color: Color(0xFF8B5CF6),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'چاوپێکەوتنەکان',
                        style: TextStyle(
                          color: AppColors.getTextTitle(context),
                          fontFamily: 'Rabar',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_appointments.length} total',
                        style: TextStyle(
                          color: AppColors.getTextSubtitle(context),
                          fontFamily: 'Rabar',
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _fetchAppointments,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.getSurface(context),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.refresh_rounded,
                        color: AppColors.getTextSubtitle(context),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn().slideY(begin: -0.1, end: 0),
            ),

            // List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _appointments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.getTextSubtitle(context).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Iconsax.calendar_remove,
                                  color: AppColors.getTextSubtitle(context),
                                  size: 48,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'هیچ چاوپێکەوتنێک نییە',
                                style: TextStyle(
                                  color: AppColors.getTextTitle(context),
                                  fontFamily: 'Rabar',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'تائێستا هیچ نۆرەیەک نەگیراوە',
                                style: TextStyle(
                                  color: AppColors.getTextSubtitle(context),
                                  fontFamily: 'Rabar',
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchAppointments,
                          color: AppColors.primary,
                          backgroundColor: AppColors.getSurface(context),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 110),
                            itemCount: _appointments.length,
                            itemBuilder: (context, index) {
                              final appt = _appointments[index];
                              final userName = appt['user'] != null
                                  ? appt['user']['name']
                                  : 'Patient';
                              final doctorName = (appt['doctor'] != null &&
                                      appt['doctor']['user'] != null)
                                  ? appt['doctor']['user']['name']
                                  : 'Doctor';
                              final status = appt['status'] ?? 'pending';
                              final date = appt['appointment_date'] ?? '';
                              final time = appt['appointment_time'] ?? '';
                              final statusColor = _statusColor(status);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.getSurface(context),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        Iconsax.calendar_1,
                                        color: statusColor,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            userName,
                                            style: TextStyle(
                                              color: AppColors.getTextTitle(context),
                                              fontFamily: 'Rabar',
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Dr. $doctorName',
                                            style: TextStyle(
                                              color: AppColors.getTextSubtitle(context),
                                              fontFamily: 'Rabar',
                                              fontSize: 13,
                                            ),
                                          ),
                                          if (date.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(
                                                  Iconsax.clock,
                                                  size: 14,
                                                  color: AppColors.getTextSubtitle(context),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '$date${time.isNotEmpty ? ' • $time' : ''}',
                                                  style: TextStyle(
                                                    color: AppColors.getTextSubtitle(context),
                                                    fontFamily: 'Rabar',
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontFamily: 'Rabar',
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                                  .animate(delay: Duration(milliseconds: index * 60))
                                  .fadeIn()
                                  .slideX(begin: 0.05, end: 0);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
