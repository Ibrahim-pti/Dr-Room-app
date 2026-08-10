import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/utils/api_client.dart';
import 'admin_app_bar.dart';

class AdminDoctorsScreen extends StatefulWidget {
  const AdminDoctorsScreen({super.key});

  @override
  State<AdminDoctorsScreen> createState() => _AdminDoctorsScreenState();
}

class _AdminDoctorsScreenState extends State<AdminDoctorsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _doctors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchDoctors();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchDoctors() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.get('/admin/doctors');
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _doctors = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveDoctor(int id) async {
    try {
      final response = await ApiClient.patch('/admin/doctors/$id/approve');
      if (response.statusCode == 200) _fetchDoctors();
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _rejectDoctor(int id) async {
    try {
      final response = await ApiClient.patch('/admin/doctors/$id/reject');
      if (response.statusCode == 200) _fetchDoctors();
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _deleteDoctor(int id) async {
    try {
      final response = await ApiClient.delete('/admin/doctors/$id');
      if (response.statusCode == 204) _fetchDoctors();
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingDoctors =
        _doctors.where((d) => d['status'] == 'pending').toList();
    final approvedDoctors =
        _doctors.where((d) => d['status'] == 'approved').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AdminAppBar(
        title: 'پزیشکەکان',
        subtitle: '${pendingDoctors.length} چاوەڕێکراو',
        icon: Iconsax.health,
        iconColor: const Color(0xFF3B82F6),
        iconBackgroundColor: const Color(0xFFEFF6FF),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tabs ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: 'چاوەڕێکراو (${pendingDoctors.length})'),
                  Tab(text: 'پەسەندکراو (${approvedDoctors.length})'),
                ],
              ),
            ).animate().fadeIn().slideX(begin: 0.1, end: 0),
          ),
          const SizedBox(height: 16),

          // ── Content ──
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDoctorList(pendingDoctors, isPending: true),
                      _buildDoctorList(approvedDoctors, isPending: false),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorList(List<dynamic> list, {required bool isPending}) {
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchDoctors,
        color: const Color(0xFF3B82F6),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.5,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.user_search,
                  color: const Color(0xFFCBD5E1),
                  size: 56,
                ),
                const SizedBox(height: 16),
                Text(
                  isPending
                      ? 'هیچ پزیشکێکی چاوەڕێکراو نییە'
                      : 'هیچ پزیشکێکی پەسەندکراو نییە',
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    color: const Color(0xFF94A3B8),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchDoctors,
      color: const Color(0xFF3B82F6),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final user = list[index];
          final name = user['name'] ?? 'نەزانراو';
          final email = user['email'] ?? '';
          final phone = user['phone'] ?? '';
          final doc = user['doctor'] ?? {};
          final specialty = doc['specialty'] ?? 'گشتی';

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFFEFF6FF),
                      child: const Icon(
                        Iconsax.user,
                        color: Color(0xFF3B82F6),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              color: const Color(0xFF1E293B),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            specialty,
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              color: const Color(0xFF3B82F6),
                              fontSize: 13,
                            ),
                          ),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.email_outlined,
                                  color: Color(0xFF94A3B8),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    email,
                                    style: TextStyle(
                                      fontFamily: 'Rabar',
                                      color: const Color(0xFF94A3B8),
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (phone.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.phone_outlined,
                                  color: Color(0xFF94A3B8),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    phone,
                                    style: TextStyle(
                                      fontFamily: 'Rabar',
                                      color: const Color(0xFF94A3B8),
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (isPending)
                      Expanded(
                        child: _buildActionBtn(
                          label: 'پەسەندکردن',
                          icon: Iconsax.tick_circle,
                          color: const Color(0xFF10B981),
                          onTap: () => _approveDoctor(user['id']),
                        ),
                      ),
                    if (!isPending)
                      Expanded(
                        child: _buildActionBtn(
                          label: 'ڕەتکردنەوە',
                          icon: Iconsax.close_circle,
                          color: const Color(0xFFF59E0B),
                          onTap: () => _rejectDoctor(user['id']),
                        ),
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildActionBtn(
                        label: 'سڕینەوە',
                        icon: Iconsax.trash,
                        color: const Color(0xFFEF4444),
                        onTap: () => _deleteDoctor(user['id']),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
              .animate(delay: Duration(milliseconds: index * 60))
              .fadeIn()
              .slideY(begin: 0.1, end: 0);
        },
      ),
    );
  }

  Widget _buildActionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Rabar',
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
