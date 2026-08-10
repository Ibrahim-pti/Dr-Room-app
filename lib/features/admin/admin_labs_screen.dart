import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/utils/api_client.dart';
import 'admin_app_bar.dart';

class AdminLabsScreen extends StatefulWidget {
  const AdminLabsScreen({super.key});

  @override
  State<AdminLabsScreen> createState() => _AdminLabsScreenState();
}

class _AdminLabsScreenState extends State<AdminLabsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _labs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchLabs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchLabs() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.get('/admin/labs');
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _labs = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveLab(int id) async {
    try {
      final response = await ApiClient.patch('/admin/labs/$id/approve');
      if (response.statusCode == 200) _fetchLabs();
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _rejectLab(int id) async {
    try {
      final response = await ApiClient.patch('/admin/labs/$id/reject');
      if (response.statusCode == 200) _fetchLabs();
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _deleteLab(int id) async {
    try {
      final response = await ApiClient.delete('/admin/labs/$id');
      if (response.statusCode == 204) _fetchLabs();
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingLabs =
        _labs.where((d) => d['status'] == 'pending').toList();
    final approvedLabs =
        _labs.where((d) => d['status'] == 'approved').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: const AdminAppBar(
        title: 'تاقیگەکان',
        subtitle: 'بینین و قبوڵکردنی تاقیگەکان',
        icon: Icons.science_rounded,
        iconColor: Colors.white,
        iconBackgroundColor: Color(0xFF8B5CF6),
        showBackButton: true,
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
                  color: const Color(0xFF8B5CF6),
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
                  Tab(text: 'چاوەڕێکراو (${pendingLabs.length})'),
                  Tab(text: 'پەسەندکراو (${approvedLabs.length})'),
                ],
              ),
            ).animate().fadeIn().slideX(begin: 0.1, end: 0),
          ),
          const SizedBox(height: 16),

          // ── Content ──
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLabList(pendingLabs, isPending: true),
                      _buildLabList(approvedLabs, isPending: false),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddLabSheet(context),
        backgroundColor: const Color(0xFF8B5CF6),
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }

  Widget _buildLabList(List<dynamic> list, {required bool isPending}) {
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchLabs,
        color: const Color(0xFF8B5CF6),
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
      onRefresh: _fetchLabs,
      color: const Color(0xFF8B5CF6),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final user = list[index];
          final name = user['name'] ?? 'نەزانراو';
          final email = user['email'] ?? '';
          final phone = user['phone'] ?? '';
          final lab = user['lab'] ?? {};
          final type = lab['lab_type'] ?? 'گشتی';

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
                      backgroundColor: const Color(0xFFF5F3FF),
                      child: const Icon(
                        Iconsax.user,
                        color: Color(0xFF8B5CF6),
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
                            type,
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              color: const Color(0xFF8B5CF6),
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
                          onTap: () => _approveLab(user['id']),
                        ),
                      ),
                    if (!isPending)
                      Expanded(
                        child: _buildActionBtn(
                          label: 'ڕەتکردنەوە',
                          icon: Iconsax.close_circle,
                          color: const Color(0xFFF59E0B),
                          onTap: () => _rejectLab(user['id']),
                        ),
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildActionBtn(
                        label: 'سڕینەوە',
                        icon: Iconsax.trash,
                        color: const Color(0xFFEF4444),
                        onTap: () => _deleteLab(user['id']),
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

  void _showAddLabSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final typeCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'زیادکردنی تاقیگەی نوێ',
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTextField('ناوی تاقیگە', nameCtrl, Iconsax.building_3),
                const SizedBox(height: 16),
                _buildTextField('شار (بۆ نموونە: هەولێر)', cityCtrl, Iconsax.location),
                const SizedBox(height: 16),
                _buildTextField('ژمارەی تەلەفۆن', phoneCtrl, Iconsax.call),
                const SizedBox(height: 16),
                _buildTextField('جۆری تاقیگە (گشتی، تایبەت)', typeCtrl, Iconsax.category),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.isEmpty) return;
                      // Mock POST request to backend
                      try {
                        await ApiClient.post('/admin/labs', body: {
                          'name': nameCtrl.text,
                          'city': cityCtrl.text,
                          'phone': phoneCtrl.text,
                          'lab_type': typeCtrl.text,
                          'status': 'approved', // Automatically approved if added by admin
                        });
                      } catch (e) {
                        debugPrint('Add Lab Mock Error: $e');
                      }
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'تاقیگە بە سەرکەوتوویی زیادکرا',
                              style: TextStyle(fontFamily: 'Rabar'),
                            ),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                        _fetchLabs();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'زیادکردن',
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(String hint, TextEditingController ctrl, IconData icon) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(fontFamily: 'Rabar', fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontFamily: 'Rabar', color: Color(0xFF94A3B8)),
        prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
