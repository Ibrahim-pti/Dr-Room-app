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

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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

  List<dynamic> _filterList(List<dynamic> list) {
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.toLowerCase().trim();
    return list.where((d) {
      final name = (d['name'] ?? '').toString().toLowerCase();
      final specialty = (d['specialty'] ?? '').toString().toLowerCase();
      final phone = (d['phone'] ?? '').toString().toLowerCase();
      return name.contains(q) || specialty.contains(q) || phone.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final pendingDoctors =
        _doctors.where((d) => d['status'] == 'pending').toList();
    final approvedDoctors =
        _doctors.where((d) => d['status'] == 'approved').toList();

    final filteredPending = _filterList(pendingDoctors);
    final filteredApproved = _filterList(approvedDoctors);

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
          // ── Search Field ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
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
                  hintText: 'گەڕان بەپێی ناوی پزیشک، پسپۆڕی یان مۆبایل...',
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
                labelStyle: const TextStyle(
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
                      _buildDoctorList(filteredPending, isPending: true),
                      _buildDoctorList(filteredApproved, isPending: false),
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
                    Expanded(
                      child: _buildActionBtn(
                        label: 'وردەکاری پرۆفایل',
                        icon: Iconsax.eye,
                        color: const Color(0xFF2563EB),
                        onTap: () => _showDoctorDetails(user, isPending),
                      ),
                    ),
                    const SizedBox(width: 8),
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
                    const SizedBox(width: 8),
                    _buildIconActionBtn(
                      icon: Iconsax.trash,
                      color: const Color(0xFFEF4444),
                      onTap: () => _deleteDoctor(user['id']),
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

  void _showDoctorDetails(dynamic user, bool isPending) {
    final doc = user['doctor'] ?? {};
    final name = user['name'] ?? 'نەزانراو';
    final nameEn = user['name_en'] ?? '';
    final nameAr = user['name_ar'] ?? '';
    final phone = user['phone'] ?? '';
    final email = user['email'] ?? '';
    final specialty = doc['specialty'] ?? 'گشتی';
    final specialtyEn = doc['specialty_en'] ?? '';
    final bio = doc['bio'] ?? '';
    final address = doc['address'] ?? '';
    final city = doc['city'] ?? '';
    final experience = doc['experience_years']?.toString() ?? '';
    final consultationFee = doc['consultation_fee']?.toString() ?? '';
    final videoFee = doc['video_consultation_fee']?.toString() ?? '';
    final license = doc['license_number'] ?? '';
    final services = (doc['services'] is List) ? doc['services'] as List : [];
    final imagePath = user['profile_image'] ?? doc['image_path'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Drag handle
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),

            // Sheet Title & Close
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'وردەکاریی پرۆفایلی پزیشک',
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: const Color(0xFFEFF6FF),
                            backgroundImage: imagePath != null
                                ? NetworkImage('${ApiClient.storageUrl}/$imagePath')
                                : null,
                            child: imagePath == null
                                ? const Icon(Iconsax.user, color: Color(0xFF2563EB), size: 30)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                if (nameEn.isNotEmpty || nameAr.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    [nameEn, nameAr].where((s) => s.isNotEmpty).join(' | '),
                                    style: const TextStyle(
                                      fontFamily: 'Rabar',
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    specialty + (specialtyEn.isNotEmpty ? ' ($specialtyEn)' : ''),
                                    style: const TextStyle(
                                      fontFamily: 'Rabar',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Information Grid
                    const Text('زانیارییەکانی پەیوەندی و لۆکەیشن', style: TextStyle(fontFamily: 'Rabar', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    const SizedBox(height: 8),
                    _buildInfoTile(icon: Iconsax.call, title: 'ژمارەی مۆبایل', value: phone.isNotEmpty ? phone : 'تۆمار نەکراوە'),
                    _buildInfoTile(icon: Iconsax.sms, title: 'ئیمەیڵ', value: email.isNotEmpty ? email : 'تۆمار نەکراوە'),
                    _buildInfoTile(icon: Iconsax.location, title: 'شار و ناونیشان', value: [city, address].where((s) => s.isNotEmpty).join(' - ').isNotEmpty ? [city, address].where((s) => s.isNotEmpty).join(' - ') : 'دیاری نەکراوە'),
                    const SizedBox(height: 16),

                    // Professional Info
                    const Text('زانیاریی پیشەیی و پسپۆڕی', style: TextStyle(fontFamily: 'Rabar', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    const SizedBox(height: 8),
                    if (experience.isNotEmpty)
                      _buildInfoTile(icon: Iconsax.medal_star, title: 'ساڵانی ئەزموون', value: '$experience ساڵ'),
                    if (license.isNotEmpty)
                      _buildInfoTile(icon: Iconsax.verify, title: 'ژمارەی بڕوانامە / مۆڵەت', value: license),
                    if (consultationFee.isNotEmpty)
                      _buildInfoTile(icon: Iconsax.money, title: 'نرخی پشکنینی کلینیک', value: '$consultationFee دینار'),
                    if (videoFee.isNotEmpty)
                      _buildInfoTile(icon: Iconsax.video, title: 'نرخی پشکنینی ڤیدیۆیی', value: '$videoFee دینار'),
                    if (bio.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('دەربارە / بیۆگرافی:', style: TextStyle(fontFamily: 'Rabar', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                            const SizedBox(height: 4),
                            Text(bio, style: const TextStyle(fontFamily: 'Rabar', fontSize: 12.5, color: Color(0xFF0F172A), height: 1.4)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (services.isNotEmpty) ...[
                      const Text('خزمەتگوزارییە پزیشکییەکان', style: TextStyle(fontFamily: 'Rabar', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      const SizedBox(height: 8),
                      ...services.map((srv) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(srv['name'] ?? '', style: const TextStyle(fontFamily: 'Rabar', fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            Text('${srv['price'] ?? 0} د.ع', style: const TextStyle(fontFamily: 'Rabar', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                          ],
                        ),
                      )),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Actions Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2)),
                ],
              ),
              child: Row(
                children: [
                  if (isPending)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _approveDoctor(user['id']);
                        },
                        icon: const Icon(Iconsax.tick_circle, color: Colors.white, size: 18),
                        label: const Text('پەسەندکردن', style: TextStyle(fontFamily: 'Rabar', color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                      ),
                    ),
                  if (!isPending)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _rejectDoctor(user['id']);
                        },
                        icon: const Icon(Iconsax.close_circle, color: Colors.white, size: 18),
                        label: const Text('ڕەتکردنەوە', style: TextStyle(fontFamily: 'Rabar', color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                      ),
                    ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _deleteDoctor(user['id']);
                    },
                    icon: const Icon(Iconsax.trash, color: Colors.white, size: 18),
                    label: const Text('سڕینەوە', style: TextStyle(fontFamily: 'Rabar', color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({required IconData icon, required String title, required String value}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF64748B), size: 18),
          const SizedBox(width: 10),
          Text('$title: ', style: const TextStyle(fontFamily: 'Rabar', fontSize: 12, color: Color(0xFF64748B))),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'Rabar', fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconActionBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 18),
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
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Rabar',
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
