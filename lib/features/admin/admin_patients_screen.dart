import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart' as intl;

import '../../core/theme/app_colors.dart';
import '../../core/utils/api_client.dart';
import 'admin_app_bar.dart';
import 'admin_patient_detail_screen.dart';
import 'admin_ui.dart';

class AdminPatientsScreen extends StatefulWidget {
  const AdminPatientsScreen({super.key});

  @override
  State<AdminPatientsScreen> createState() => _AdminPatientsScreenState();
}

class _AdminPatientsScreenState extends State<AdminPatientsScreen> {
  List<dynamic> _patients = [];
  bool _isLoading = true;
  String? _error;
  String _search = '';
  String _filter = 'all'; // 'all', 'active', 'new', 'blocked'
  Timer? _debounce;

  final TextEditingController _searchCtrl = TextEditingController();

  final List<({String key, String label, IconData icon})> _filters = [
    (key: 'all', label: 'هەمووی', icon: Iconsax.people),
    (key: 'active', label: 'چالاکەکان', icon: Iconsax.user_tick),
    (key: 'new', label: 'نوێیەکان', icon: Iconsax.user_add),
    (key: 'blocked', label: 'بلۆککراوەکان', icon: Iconsax.user_remove),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final queryParams = [
        if (_search.isNotEmpty) 'search=${Uri.encodeComponent(_search)}',
        if (_filter != 'all') 'status=$_filter',
      ].join('&');

      final query = queryParams.isNotEmpty ? '?$queryParams' : '';
      final res = await ApiClient.get('/admin/patients$query');

      if (!mounted) return;

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = body['data'] is Map ? (body['data']['data'] ?? []) : (body['data'] ?? []);
        setState(() {
          _patients = list;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = AdminUi.readError(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _isLoading = false; });
    }
  }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() => _search = val.trim());
      _load();
    });
  }

  String _formatIqd(dynamic val) {
    final d = double.tryParse(val?.toString() ?? '0') ?? 0;
    return '${intl.NumberFormat('#,###').format(d)} د.ع';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AdminAppBar(
        title: 'بەڕێوەبردنی نەخۆشەکان',
        subtitle: 'لیستی بەکارهێنەران، دۆسیە و پەیوەندیکردن',
        icon: Iconsax.profile_2user,
        iconColor: const Color(0xFF0D9488),
        iconBackgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.1),
        showBackButton: true,
      ),
      body: Column(
        children: [
          // Top Search & Filter Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
            ),
            child: Column(
              children: [
                // Search Input Field
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearchChanged,
                    style: TextStyle(fontFamily: 'Rabar', fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'گەڕان بەپێی ناو، مۆبایل یان ئیمەیڵ...',
                      hintStyle: const TextStyle(fontFamily: 'Rabar', fontSize: 12, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Iconsax.search_normal, size: 18, color: Color(0xFF0D9488)),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Filter Chips Horizontal Scroll
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((f) {
                      final isSelected = _filter == f.key;
                      return Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: ChoiceChip(
                          avatar: Icon(
                            f.icon,
                            size: 14,
                            color: isSelected ? Colors.white : const Color(0xFF0D9488),
                          ),
                          label: Text(
                            f.label,
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFF0D9488),
                          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          onSelected: (_) {
                            setState(() => _filter = f.key);
                            _load();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Patients List or Error
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Iconsax.info_circle, size: 48, color: Colors.amber),
                              const SizedBox(height: 12),
                              Text(_error!, style: AdminUi.subtitle, textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              ElevatedButton(onPressed: _load, child: const Text('دووبارە هەوڵبدەرەوە')),
                            ],
                          ),
                        ),
                      )
                    : _patients.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Iconsax.profile_2user, size: 40, color: Color(0xFF0D9488)),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text('هیچ نەخۆشێک نەدۆزرایەوە', style: TextStyle(fontFamily: 'Rabar', fontSize: 15, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  const Text('بەپێی گەڕان و فلتەرەکەت هیچ بەکارهێنەرێک بەردەست نییە.', style: TextStyle(fontFamily: 'Rabar', fontSize: 12, color: Color(0xFF94A3B8))),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _patients.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final p = _patients[i];
                                final name = p['name'] ?? 'نەخۆش';
                                final phone = p['phone'] ?? '';
                                final isBlocked = p['is_blocked'] == true;
                                final ordersCount = p['orders_count'] ?? 0;
                                final totalSpent = _formatIqd(p['total_spent']);
                                final date = p['created_at'] ?? '';

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AdminPatientDetailScreen(
                                            patientId: p['id'],
                                            initialName: name,
                                          ),
                                        ),
                                      );
                                      _load();
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      decoration: AdminUi.cardDecoration,
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        children: [
                                          // Avatar initials
                                          Container(
                                            width: 46,
                                            height: 46,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: isBlocked
                                                    ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                                                    : [const Color(0xFF0D9488), const Color(0xFF14B8A6)],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Text(
                                                name.isNotEmpty ? name.characters.first : 'ن',
                                                style: const TextStyle(
                                                  fontFamily: 'Rabar',
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),

                                          // Name & Phone
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        name,
                                                        style: TextStyle(
                                                          fontFamily: 'Rabar',
                                                          fontSize: 13.5,
                                                          fontWeight: FontWeight.bold,
                                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    if (isBlocked)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: const Text(
                                                          'بلۆککراوە',
                                                          style: TextStyle(fontFamily: 'Rabar', fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 3),
                                                Directionality(
                                                  textDirection: TextDirection.ltr,
                                                  child: Text(
                                                    phone.isNotEmpty ? phone : 'بێ ژمارە',
                                                    style: const TextStyle(fontFamily: 'Rabar', fontSize: 11.5, color: Color(0xFF64748B)),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    // Orders count badge (Spot repeat buyers!)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        '$ordersCount داواکاری',
                                                        style: const TextStyle(fontFamily: 'Rabar', fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    if (ordersCount > 0)
                                                      Text(
                                                        totalSpent,
                                                        style: const TextStyle(fontFamily: 'Rabar', fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
                                                      ),
                                                    const Spacer(),
                                                    Text(
                                                      date,
                                                      style: const TextStyle(fontFamily: 'Rabar', fontSize: 10, color: Color(0xFF94A3B8)),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFCBD5E1)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ).animate().fadeIn(duration: 150.ms);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
