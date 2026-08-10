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

  @override
  void initState() {
    super.initState();
    _fetchUsers();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
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
                      Text(
                        'بەکارهێنەران',
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          color: const Color(0xFF1E293B),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_users.length} کۆی گشتی',
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          color: const Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ).animate().fadeIn().slideY(begin: -0.1, end: 0),
          ),

          // ── Content ──
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF10B981)))
                : _users.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _fetchUsers,
                        color: const Color(0xFF10B981),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.5,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Iconsax.profile_remove,
                                  color: const Color(0xFFCBD5E1),
                                  size: 56,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'هیچ بەکارهێنەرێک نەدۆزرایەوە',
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
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchUsers,
                        color: const Color(0xFF10B981),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
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
                                        const SizedBox(height: 2),
                                        Text(
                                          user['email'] ?? '',
                                          style: TextStyle(
                                            fontFamily: 'Rabar',
                                            color: const Color(0xFF94A3B8),
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
                                            child: Text(
                                              'هەژمار ڕاگیراوە',
                                              style: TextStyle(
                                                fontFamily: 'Rabar',
                                                color:
                                                    const Color(0xFFEF4444),
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
}
