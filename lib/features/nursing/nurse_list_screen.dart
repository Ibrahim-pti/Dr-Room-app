import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/utils/api_client.dart';
import '../../core/theme/app_colors.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'nursing_services_screen.dart';

class NurseListScreen extends StatefulWidget {
  const NurseListScreen({super.key});

  @override
  State<NurseListScreen> createState() => _NurseListScreenState();
}

class _NurseListScreenState extends State<NurseListScreen> {
  List<Map<String, dynamic>> _allNurses = [];
  List<Map<String, dynamic>> _filteredNurses = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchNurses();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _tr(String key) {
    final lang = context.locale.languageCode;
    final isKurdish = lang == 'ckb' || lang == 'ku';
    final isArabic = lang == 'ar';

    switch (key) {
      case 'title':
        if (isKurdish) return 'پەرستارەکان';
        if (isArabic) return 'الممرضون';
        return 'Nurses';
      case 'search':
        if (isKurdish) return 'گەڕان بۆ ناوی پەرستار...';
        if (isArabic) return 'البحث عن ممرض...';
        return 'Search nurses...';
      case 'no_nurses':
        if (isKurdish) return 'هیچ پەرستارێک نەدۆزرایەوە';
        if (isArabic) return 'لم يتم العثور على ممرضين';
        return 'No nurses found';
      case 'completed':
        if (isKurdish) return 'تەواوکراو';
        if (isArabic) return 'مكتمل';
        return 'Completed';
      case 'request_service':
        if (isKurdish) return 'داواکردنی خزمەتگوزاری';
        if (isArabic) return 'طلب خدمة';
        return 'Request Service';
      case 'retry':
        if (isKurdish) return 'هەوڵدانەوە';
        if (isArabic) return 'إعادة المحاولة';
        return 'Retry';
      case 'error':
        if (isKurdish) return 'هەڵە ڕوویدا';
        if (isArabic) return 'حدث خطأ';
        return 'An error occurred';
      default:
        return key.tr();
    }
  }

  Future<void> _fetchNurses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiClient.get('/nurses');
      if (response.statusCode == 200 && mounted) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> nurses = decoded['nurses'] ?? [];
        setState(() {
          _allNurses = nurses.cast<Map<String, dynamic>>();
          _filteredNurses = _allNurses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _filterNurses(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredNurses = _allNurses;
      } else {
        final q = query.toLowerCase();
        _filteredNurses = _allNurses.where((n) {
          final name = (n['name'] ?? '').toString().toLowerCase();
          final specialty = (n['specialty'] ?? '').toString().toLowerCase();
          final specialtyEn = (n['specialty_en'] ?? '').toString().toLowerCase();
          return name.contains(q) || specialty.contains(q) || specialtyEn.contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: CustomScrollView(
        slivers: [
          // ─── App Bar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: const Color(0xFF0D9488),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 50, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _tr('title'),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _tr('request_service'),
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ─── Search ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.getSurface(context),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _filterNurses,
                  decoration: InputDecoration(
                    hintText: _tr('search'),
                    hintStyle: GoogleFonts.poppins(
                      color: AppColors.getTextSubtitle(context),
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(Iconsax.search_normal, size: 20, color: AppColors.getTextSubtitle(context)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
          ),

          // ─── Body ────────────────────────────────────────────
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Color(0xFF0D9488))),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Iconsax.warning_2, size: 48, color: Colors.red.shade300),
                    const SizedBox(height: 12),
                    Text(_tr('error'), style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchNurses,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
                      child: Text(_tr('retry'), style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            )
          else if (_filteredNurses.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Iconsax.people, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      _tr('no_nurses'),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppColors.getTextSubtitle(context),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final nurse = _filteredNurses[index];
                    return _NurseCard(
                      nurse: nurse,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NursingServicesScreen(),
                          ),
                        );
                      },
                    ).animate().fadeIn(delay: (100 + index * 80).ms).slideY(begin: 0.08, end: 0);
                  },
                  childCount: _filteredNurses.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Nurse Card ─────────────────────────────────────────────────────
class _NurseCard extends StatelessWidget {
  final Map<String, dynamic> nurse;
  final VoidCallback onTap;

  const _NurseCard({required this.nurse, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = nurse['name'] ?? '';
    final specialty = nurse['specialty'] ?? '';
    final image = nurse['image'];
    final completedCount = nurse['completed_appointments'] ?? 0;
    final phone = nurse['phone'] ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                ),
                image: image != null
                    ? DecorationImage(
                        image: NetworkImage(image),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: image == null
                  ? Center(
                      child: Text(
                        name.isNotEmpty ? name[0] : 'ن',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.getTextTitle(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    specialty,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0D9488),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (completedCount > 0) ...[
                        Icon(Iconsax.tick_circle, size: 14, color: Colors.green.shade400),
                        const SizedBox(width: 4),
                        Text(
                          '$completedCount',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.getTextSubtitle(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (phone.isNotEmpty) ...[
                        Icon(Iconsax.call, size: 14, color: AppColors.getTextSubtitle(context)),
                        const SizedBox(width: 4),
                        Text(
                          phone,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.getTextSubtitle(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Arrow
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Color(0xFF0D9488),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
