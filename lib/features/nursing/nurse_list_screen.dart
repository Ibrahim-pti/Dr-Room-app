import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/utils/api_client.dart';
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
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'all'; // 'all', 'injection', 'cannula', 'dressing', 'checkup'

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
      case 'all_nurses':
        if (isKurdish) return 'هەموو پەرستارەکان';
        if (isArabic) return 'جميع الممرضين';
        return 'All Nurses';
      case 'all':
        if (isKurdish) return 'هەمووی';
        if (isArabic) return 'الكل';
        return 'All';
      case 'search':
        if (isKurdish) return 'گەڕان بۆ ناوی پەرستار...';
        if (isArabic) return 'البحث عن ممرض...';
        return 'Search nurses...';
      case 'no_nurses':
        if (isKurdish) return 'هیچ پەرستارێک نەدۆزرایەوە';
        if (isArabic) return 'لم يتم العثور على ممرضين';
        return 'No nurses found';
      case 'request_service':
        if (isKurdish) return 'داواکردن';
        if (isArabic) return 'طلب خدمة';
        return 'Request';
      case 'available':
        if (isKurdish) return 'ئامادەیە';
        if (isArabic) return 'متاح';
        return 'Available';
      case 'unavailable':
        if (isKurdish) return 'ئامادە نییە';
        if (isArabic) return 'غير متاح';
        return 'Unavailable';
      default:
        return key.tr();
    }
  }

  String _getCategoryName(Map<String, dynamic> cat) {
    final lang = context.locale.languageCode;
    final isKurdish = lang == 'ckb' || lang == 'ku';
    final isArabic = lang == 'ar';
    if (isArabic) return cat['name_ar'] ?? cat['name'] ?? '';
    if (!isKurdish) return cat['name_en'] ?? cat['name'] ?? '';
    return cat['name'] ?? '';
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'health':
        return Iconsax.health;
      case 'activity':
        return Iconsax.activity;
      case 'healing':
        return Icons.healing_outlined;
      case 'heart':
        return Iconsax.heart;
      default:
        return Iconsax.health;
    }
  }

  TextStyle _kStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color color = const Color(0xFF0F172A),
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'Rabar',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  Future<void> _fetchNurses() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.get('/nurses');
      if (response.statusCode == 200 && mounted) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> nurses = decoded['nurses'] ?? [];
        final List<dynamic> categories = decoded['categories'] ?? [];
        setState(() {
          _allNurses = nurses.cast<Map<String, dynamic>>();
          _filteredNurses = _allNurses;
          _categories = categories.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching nurses: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterNurses() {
    final query = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filteredNurses = _allNurses.where((n) {
        final name = (n['name'] ?? '').toString().toLowerCase();
        final specialty = (n['specialty'] ?? '').toString().toLowerCase();
        final specialtyEn = (n['specialty_en'] ?? '').toString().toLowerCase();
        final matchesQuery =
            query.isEmpty || name.contains(query) || specialty.contains(query) || specialtyEn.contains(query);

        bool matchesCategory = true;
        if (_selectedCategory != 'all') {
          final offered = n['offered_services'];
          if (offered is List) {
            matchesCategory = offered.contains(_selectedCategory);
          } else {
            matchesCategory = false;
          }
        }

        return matchesQuery && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        color: const Color(0xFF0D9488),
        backgroundColor: Colors.white,
        displacement: 40,
        onRefresh: _fetchNurses,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchAndFilters(),

                  if (_isLoading)
                    const SizedBox(
                      height: 300,
                      child: Center(child: CircularProgressIndicator(color: Color(0xFF0D9488))),
                    )
                  else if (_filteredNurses.isEmpty)
                    SizedBox(
                      height: 300,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(Iconsax.search_normal_1, size: 48, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _tr('no_nurses'),
                              style: _kStyle(color: const Color(0xFF475569), fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
                      ),
                    )
                  else
                    ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredNurses.length,
                      itemBuilder: (context, index) {
                        return _buildPremiumNurseCard(_filteredNurses[index], index);
                      },
                    ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsetsDirectional.only(start: 16),
        child: Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 16),
            ),
          ),
        ),
      ),
      title: Text(
        _tr('all_nurses'),
        style: _kStyle(color: const Color(0xFF0F172A), fontSize: 17, fontWeight: FontWeight.bold),
      ),
      actions: const [SizedBox(width: 64)],
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search Bar ──
          Container(
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                const Icon(Iconsax.search_normal_1, color: Color(0xFF94A3B8), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => _filterNurses(),
                    style: _kStyle(color: const Color(0xFF0F172A), fontSize: 14),
                    decoration: InputDecoration(
                      hintText: _tr('search'),
                      hintStyle: _kStyle(color: const Color(0xFF94A3B8), fontSize: 13),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

          const SizedBox(height: 18),

          // ── Category Filter Chips (from API) ──
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // "All" chip
                _buildCategoryChip(
                  id: 'all',
                  label: _tr('all'),
                  icon: Iconsax.category,
                  isSelected: _selectedCategory == 'all',
                ),
                // Dynamic categories from API
                ..._categories.map((cat) {
                  final id = cat['id'] as String;
                  return _buildCategoryChip(
                    id: id,
                    label: _getCategoryName(cat),
                    icon: _getCategoryIcon(cat['icon'] ?? ''),
                    isSelected: _selectedCategory == id,
                  );
                }),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String id,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = id);
        _filterNurses();
      },
      child: Container(
        margin: const EdgeInsetsDirectional.only(end: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D9488) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: _kStyle(
                color: isSelected ? Colors.white : const Color(0xFF475569),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumNurseCard(Map<String, dynamic> nurse, int index) {
    final name = nurse['name'] ?? '';
    final specialty = nurse['specialty'] ?? '';
    final image = nurse['image'];
    final completedCount = nurse['completed_appointments'] ?? 0;
    final phone = nurse['phone'] ?? '';
    final isAvailable = nurse['is_available'] == true;
    final offeredServices = nurse['offered_services'] as List<dynamic>? ?? [];
    final fee = nurse['fee'];

    // Map service IDs to Kurdish names for display
    String serviceName(String id) {
      final map = {'injection': 'دەرزی', 'cannula': 'کانیۆلا', 'dressing': 'پانسیمان', 'checkup': 'چاودێری'};
      return map[id] ?? id;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const NursingServicesScreen()));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left: Avatar ──
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                    ),
                    image: image != null
                        ? DecorationImage(image: NetworkImage(image), fit: BoxFit.cover)
                        : null,
                  ),
                  child: image == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Iconsax.health, color: Colors.white, size: 32),
                              const SizedBox(height: 4),
                              Text(
                                name.isNotEmpty ? name.split(' ').first : 'ن',
                                style: _kStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        )
                      : null,
                ),
                // Available/Unavailable badge
                PositionedDirectional(
                  top: 6,
                  start: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isAvailable
                            ? [const Color(0xFF10B981), const Color(0xFF059669)]
                            : [const Color(0xFF94A3B8), const Color(0xFF64748B)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: (isAvailable ? const Color(0xFF10B981) : const Color(0xFF94A3B8))
                              .withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      isAvailable ? _tr('available') : _tr('unavailable'),
                      style: _kStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // ── Right: Details ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Name
                  Text(
                    name,
                    style: _kStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),

                  // 2. Specialty
                  Row(
                    children: [
                      const Icon(Iconsax.health, color: Color(0xFF0D9488), size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          specialty,
                          style: _kStyle(color: const Color(0xFF64748B), fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (completedCount > 0) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Iconsax.tick_circle, color: Color(0xFF059669), size: 13),
                              const SizedBox(width: 3),
                              Text(
                                '$completedCount',
                                style: _kStyle(
                                    color: const Color(0xFF047857), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 3. Service tags
                  if (offeredServices.isNotEmpty)
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: offeredServices.take(4).map<Widget>((s) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDFA),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCCFBF1)),
                          ),
                          child: Text(
                            serviceName(s.toString()),
                            style: _kStyle(color: const Color(0xFF0D9488), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 10),

                  // 4. Bottom: Phone/Fee + Request Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Phone or fee
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (fee != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${double.tryParse(fee.toString())?.toInt() ?? fee} د.ع',
                                style: _kStyle(
                                    color: const Color(0xFFB45309), fontSize: 10.5, fontWeight: FontWeight.bold),
                              ),
                            )
                          else if (phone.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Iconsax.call, color: Color(0xFF64748B), size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    phone,
                                    style: _kStyle(
                                        color: const Color(0xFF64748B), fontSize: 10.5, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      // Request button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDFA),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _tr('request_service'),
                              style: _kStyle(
                                  color: const Color(0xFF0D9488), fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios, color: Color(0xFF0D9488), size: 9),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (60 * index).ms).slideY(begin: 0.08, end: 0);
  }
}
