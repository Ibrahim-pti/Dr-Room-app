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
  String _searchQuery = '';
  String _selectedStatus = 'all';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  String _statusLabel(String? status) {
    switch (status) {
      case 'completed':
        return 'تەواوکراو';
      case 'cancelled':
        return 'ڕەتکراوە';
      case 'confirmed':
        return 'پەسەندکراو';
      default:
        return 'چاوەڕێکراو';
    }
  }

  List<dynamic> get _filteredAppointments {
    return _appointments.where((apt) {
      final patientName = (apt['patient_name'] ?? apt['user']?['name'] ?? '')
          .toString()
          .toLowerCase();
      final doctorName = (apt['doctor_name'] ?? apt['doctor']?['user']?['name'] ?? '')
          .toString()
          .toLowerCase();
      final status = (apt['status'] ?? '').toString().toLowerCase();
      final date = (apt['date'] ?? apt['appointment_date'] ?? '')
          .toString()
          .toLowerCase();
      final q = _searchQuery.toLowerCase().trim();

      final matchesQuery = q.isEmpty ||
          patientName.contains(q) ||
          doctorName.contains(q) ||
          date.contains(q);

      final matchesStatus =
          _selectedStatus == 'all' || status == _selectedStatus;

      return matchesQuery && matchesStatus;
    }).toList();
  }

  Widget _buildFilterPill(String status, String label) {
    final isSelected = _selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedStatus = status),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.getSurface(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.getTextSubtitle(context),
              fontFamily: 'Rabar',
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredAppointments;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.getSurface(context),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.getTextTitle(context),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Iconsax.calendar_tick,
                      color: Color(0xFF8B5CF6),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'چاوپێکەوتنەکان',
                          style: TextStyle(
                            color: AppColors.getTextTitle(context),
                            fontFamily: 'Rabar',
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${filtered.length} لە کۆی ${_appointments.length} نۆرە',
                          style: TextStyle(
                            color: AppColors.getTextSubtitle(context),
                            fontFamily: 'Rabar',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
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

            // ── Search Field ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(fontFamily: 'Rabar', fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'گەڕان بەپێی ناوی نەخۆش، پزیشک یان بەروار...',
                    hintStyle: const TextStyle(
                      fontFamily: 'Rabar',
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Iconsax.search_normal_1,
                      color: Color(0xFF94A3B8),
                      size: 18,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: const Icon(
                              Icons.close,
                              color: Color(0xFF94A3B8),
                              size: 18,
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),

            // ── Status Filter Pills ──
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    _buildFilterPill('all', 'هەمووی'),
                    _buildFilterPill('pending', 'چاوەڕێکراو'),
                    _buildFilterPill('confirmed', 'پەسەندکراو'),
                    _buildFilterPill('completed', 'تەواوکراو'),
                    _buildFilterPill('cancelled', 'ڕەتکراوە'),
                  ],
                ),
              ),
            ),

            // List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : filtered.isEmpty
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
                                'هیچ چاوپێکەوتنێک نەدۆزرایەوە',
                                style: TextStyle(
                                  color: AppColors.getTextTitle(context),
                                  fontFamily: 'Rabar',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'بەپێی ئەو فلتەر یان سێرچە هیچ نۆرەیەک نەدۆزرایەوە',
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
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final appt = filtered[index];
                              final userName = appt['user'] != null
                                  ? appt['user']['name']
                                  : 'نەخۆش';
                              final doctorName = (appt['doctor'] != null &&
                                      appt['doctor']['user'] != null)
                                  ? appt['doctor']['user']['name']
                                  : 'پزیشک';
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
                                            'د. $doctorName',
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
                                        _statusLabel(status),
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
