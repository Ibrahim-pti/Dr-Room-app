import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/utils/api_client.dart';
import '../../core/theme/app_colors.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedRole = 'all';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.get('/admin/users');
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _users = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBlockStatus(int id, bool currentlyBlocked) async {
    try {
      final endpoint = currentlyBlocked
          ? '/admin/users/$id/unblock'
          : '/admin/users/$id/block';
      final response = await ApiClient.patch(endpoint);
      if (response.statusCode == 200) _fetchUsers();
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  List<dynamic> get _filteredUsers {
    return _users.where((user) {
      final name = (user['name'] ?? '').toString().toLowerCase();
      final phone = (user['phone'] ?? '').toString().toLowerCase();
      final role = (user['role'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase().trim();

      final matchesQuery = query.isEmpty ||
          name.contains(query) ||
          phone.contains(query) ||
          role.contains(query);

      final matchesRole = _selectedRole == 'all' || role == _selectedRole;

      return matchesQuery && matchesRole;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredUsers;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
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
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Iconsax.people,
                      color: Color(0xFF10B981),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'بەکارهێنەران',
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            color: Color(0xFF1E293B),
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${filtered.length} لە کۆی ${_users.length} بەکارهێنەر',
                          style: const TextStyle(
                            fontFamily: 'Rabar',
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ],
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
                    hintText: 'گەڕان بەپێی ناو یان ژمارە مۆبایل...',
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

            // ── Role Filter Pills ──
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    _buildRolePill('all', 'هەمووی'),
                    _buildRolePill('patient', 'نەخۆش'),
                    _buildRolePill('doctor', 'پزیشک'),
                    _buildRolePill('nurse', 'پەرستار'),
                    _buildRolePill('pharmacy', 'دەرمانخانە'),
                    _buildRolePill('lab', 'تاقیگە'),
                    _buildRolePill('admin', 'ئەدمین'),
                  ],
                ),
              ),
            ),

            // ── Content ──
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF10B981)),
                    )
                  : filtered.isEmpty
                      ? RefreshIndicator(
                          onRefresh: _fetchUsers,
                          color: const Color(0xFF10B981),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Container(
                              height: MediaQuery.of(context).size.height * 0.45,
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Iconsax.profile_remove,
                                    color: Color(0xFFCBD5E1),
                                    size: 56,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'هیچ بەکارهێنەرێک نەدۆزرایەوە',
                                    style: TextStyle(
                                      fontFamily: 'Rabar',
                                      color: Color(0xFF94A3B8),
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchUsers,
                          color: const Color(0xFF10B981),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(24, 4, 24, 120),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final user = filtered[index];
                              final isBlocked = user['is_blocked'] ?? false;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isBlocked
                                      ? const Color(0xFFEF4444)
                                          .withValues(alpha: 0.3)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: isBlocked
                                        ? const Color(0xFFFEF2F2)
                                        : const Color(0xFFF0FDF4),
                                    child: Icon(
                                      Iconsax.user,
                                      color: isBlocked
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFF10B981),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              user['name'] ?? 'نەزانراو',
                                              style: TextStyle(
                                                fontFamily: 'Rabar',
                                                color: const Color(0xFF1E293B),
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                decoration: isBlocked
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                                decorationColor:
                                                    const Color(0xFFEF4444),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            _buildUserRoleBadge(user['role']),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          user['phone'] ?? user['email'] ?? '',
                                          style: const TextStyle(
                                            fontFamily: 'Rabar',
                                            color: Color(0xFF64748B),
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (isBlocked) ...[
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEF4444)
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'هەژمار ڕاگیراوە',
                                              style: TextStyle(
                                                fontFamily: 'Rabar',
                                                color: Color(0xFFEF4444),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _toggleBlockStatus(
                                      user['id'],
                                      isBlocked,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isBlocked
                                            ? const Color(0xFF10B981)
                                                .withValues(alpha: 0.1)
                                            : const Color(0xFFEF4444)
                                                .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        isBlocked ? 'لابردنی بلۆک' : 'بلۆک',
                                        style: TextStyle(
                                          fontFamily: 'Rabar',
                                          color: isBlocked
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFEF4444),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                                .animate(
                                    delay:
                                        Duration(milliseconds: index * 50))
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

  Widget _buildRolePill(String role, String label) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        margin: const EdgeInsetsDirectional.only(end: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF10B981)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Rabar',
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildUserRoleBadge(String? role) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = const Color(0xFF64748B);
    String label = 'نەخۆش';

    switch (role) {
      case 'admin':
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF2563EB);
        label = 'ئەدمین';
        break;
      case 'doctor':
        bg = const Color(0xFFF0FDF4);
        fg = const Color(0xFF16A34A);
        label = 'پزیشک';
        break;
      case 'nurse':
        bg = const Color(0xFFFDF2F8);
        fg = const Color(0xFFDB2777);
        label = 'پەرستار';
        break;
      case 'pharmacy':
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFD97706);
        label = 'دەرمانخانە';
        break;
      case 'lab':
        bg = const Color(0xFFF5F3FF);
        fg = const Color(0xFF7C3AED);
        label = 'تاقیگە';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Rabar',
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
