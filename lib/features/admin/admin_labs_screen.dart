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

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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

  List<dynamic> _filterList(List<dynamic> list) {
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.toLowerCase().trim();
    return list.where((d) {
      final name = (d['name'] ?? '').toString().toLowerCase();
      final address = (d['address'] ?? '').toString().toLowerCase();
      final phone = (d['phone'] ?? '').toString().toLowerCase();
      return name.contains(q) || address.contains(q) || phone.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pendingLabs =
        _labs.where((d) => d['status'] == 'pending').toList();
    final approvedLabs =
        _labs.where((d) => d['status'] == 'approved').toList();

    final filteredPending = _filterList(pendingLabs);
    final filteredApproved = _filterList(approvedLabs);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
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
          // ── Search Field ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(fontFamily: 'Rabar', fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'گەڕان بەپێی ناوی تاقیگە، ناونیشان یان مۆبایل...',
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
                          child: Icon(
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
                color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
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
                labelStyle: const TextStyle(
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
                      _buildLabList(filteredPending, isPending: true),
                      _buildLabList(filteredApproved, isPending: false),
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
              color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
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
                    Expanded(
                      child: _buildActionBtn(
                        label: 'وردەکاری پرۆفایل',
                        icon: Iconsax.eye,
                        color: const Color(0xFF6366F1),
                        onTap: () => _showLabDetails(user, isPending),
                      ),
                    ),
                    const SizedBox(width: 8),
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
                    const SizedBox(width: 8),
                    _buildIconActionBtn(
                      icon: Iconsax.trash,
                      color: const Color(0xFFEF4444),
                      onTap: () => _deleteLab(user['id']),
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

  void _showLabDetails(dynamic user, bool isPending) {
    final lab = user['lab'] ?? {};
    final name = user['name'] ?? 'نەزانراو';
    final nameEn = user['name_en'] ?? '';
    final nameAr = user['name_ar'] ?? '';
    final phone = user['phone'] ?? lab['phone'] ?? '';
    final email = user['email'] ?? '';
    final address = lab['address'] ?? lab['location'] ?? '';
    final city = lab['city'] ?? '';
    final labType = lab['lab_type'] ?? 'تاقیگەی پزیشکی';
    final bio = lab['bio'] ?? '';
    final license = lab['license_number'] ?? '';
    final workingHours = lab['working_hours'] ?? '';
    final tests = (lab['tests'] is List) ? lab['tests'] as List : [];
    final imagePath = user['profile_image'] ?? lab['image_path'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'وردەکاریی تاقیگە',
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(Icons.close, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: const Color(0xFFE0E7FF),
                            backgroundImage: ApiClient.getImageProvider(imagePath),
                            child: imagePath == null
                                ? const Icon(Iconsax.radar, color: Color(0xFF4F46E5), size: 30)
                                : null,
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
                                    color: const Color(0xFFE0E7FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    labType,
                                    style: const TextStyle(
                                      fontFamily: 'Rabar',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4338CA),
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
                    const Text('زانیارییەکانی پەیوەندی و ناونیشان', style: TextStyle(fontFamily: 'Rabar', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    const SizedBox(height: 8),
                    _buildInfoTile(icon: Iconsax.call, title: 'ژمارەی مۆبایل', value: phone.isNotEmpty ? phone : 'تۆمار نەکراوە'),
                    _buildInfoTile(icon: Iconsax.sms, title: 'ئیمەیڵ', value: email.isNotEmpty ? email : 'تۆمار نەکراوە'),
                    _buildInfoTile(icon: Iconsax.location, title: 'شار و ناونیشان', value: [city, address].where((s) => s.isNotEmpty).join(' - ').isNotEmpty ? [city, address].where((s) => s.isNotEmpty).join(' - ') : 'دیاری نەکراوە'),
                    const SizedBox(height: 16),
                    const Text('زانیارییەکانی مۆڵەت و خزمەتگوزارییەکان', style: TextStyle(fontFamily: 'Rabar', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    const SizedBox(height: 8),
                    if (license.isNotEmpty)
                      _buildInfoTile(icon: Iconsax.verify, title: 'ژمارەی مۆڵەت', value: license),
                    if (workingHours.isNotEmpty)
                      _buildInfoTile(icon: Iconsax.clock, title: 'کاتژمێرەکانی کارکردن', value: workingHours),
                    if (bio.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('دەربارەی تاقیگە:', style: TextStyle(fontFamily: 'Rabar', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                            const SizedBox(height: 4),
                            Text(bio, style: TextStyle(fontFamily: 'Rabar', fontSize: 12.5, color: Color(0xFF0F172A), height: 1.4)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (tests.isNotEmpty) ...[
                      const Text('پشکنینە بەردەستەکان', style: TextStyle(fontFamily: 'Rabar', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      const SizedBox(height: 8),
                      ...tests.map((t) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(t['name'] ?? '', style: const TextStyle(fontFamily: 'Rabar', fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            Text('${t['price'] ?? 0} د.ع', style: const TextStyle(fontFamily: 'Rabar', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                          ],
                        ),
                      )),
                    ],
                  ],
                ),
              ),
            ),
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
                          _approveLab(user['id']);
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
                          _rejectLab(user['id']);
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
                      _deleteLab(user['id']);
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
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)), size: 18),
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
          decoration: BoxDecoration(
            color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white),
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
      style: TextStyle(fontFamily: 'Rabar', fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontFamily: 'Rabar', color: Color(0xFF94A3B8)),
        prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}