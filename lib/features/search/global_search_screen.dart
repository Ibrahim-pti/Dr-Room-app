import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/utils/api_client.dart';
import '../../core/utils/localization_extensions.dart';
import '../lab/lab_details_screen.dart';
import '../nursing/nurse_details_screen.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isLoading = false;

  List<dynamic> _labs = [];
  List<dynamic> _nurses = [];

  String _selectedCategory = 'All';
  final List<Map<String, dynamic>> _categories = [
    {'id': 'All', 'icon': Iconsax.category},
    {'id': 'Labs', 'icon': Iconsax.health},
    {'id': 'Nurses', 'icon': Iconsax.profile_2user},
  ];

  final List<String> _labFallbackImages = [
    'assets/images/lab1.jpg',
    'assets/images/lab2.jpg',
    'assets/images/lab3.jpg',
    'assets/images/lab4.jpg',
  ];

  final List<String> _nurseFallbackImages = [
    'https://images.unsplash.com/photo-1594824813511-236b283d0cfa?w=400&h=300&fit=crop&crop=face,top&q=80',
    'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=400&h=300&fit=crop&crop=face,top&q=80',
    'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=400&h=300&fit=crop&crop=face,top&q=80',
    'https://images.unsplash.com/photo-1582750433449-648ed127bb54?w=400&h=300&fit=crop&crop=face,top&q=80',
  ];

  @override
  void initState() {
    super.initState();
    _performSearch('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.get('/global-search?q=$query');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _labs = data['data']['labs'] ?? [];
            _nurses = data['data']['nurses'] ?? [];
          });
        }
      }

      // Resilient fallback: If nurses are not present in the global-search payload
      if (_nurses.isEmpty) {
        final nurseRes = await ApiClient.get('/nurses');
        if (nurseRes.statusCode == 200) {
          final nData = jsonDecode(nurseRes.body);
          final rawList = nData['data'] is List ? nData['data'] : (nData is List ? nData : []);
          if (query.trim().isEmpty) {
            if (mounted) setState(() => _nurses = rawList);
          } else {
            final q = query.toLowerCase();
            if (mounted) {
              setState(() {
                _nurses = rawList.where((n) {
                  final name = (n['name'] ?? '').toString().toLowerCase();
                  final nameEn = (n['name_en'] ?? '').toString().toLowerCase();
                  final nameAr = (n['name_ar'] ?? '').toString().toLowerCase();
                  final specialty = (n['specialty'] ?? '').toString().toLowerCase();
                  final city = (n['city'] ?? '').toString().toLowerCase();
                  return name.contains(q) ||
                      nameEn.contains(q) ||
                      nameAr.contains(q) ||
                      specialty.contains(q) ||
                      city.contains(q);
                }).toList();
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getCategoryLabel(String id, BuildContext context) {
    final lang = context.locale.languageCode;
    if (id == 'All') {
      return lang == 'ar' ? 'الكل' : (lang == 'en' ? 'All' : 'هەمووی');
    } else if (id == 'Labs') {
      return lang == 'ar' ? 'المختبرات' : (lang == 'en' ? 'Laboratories' : 'لیستی تاقیگەکان');
    } else {
      return lang == 'ar' ? 'الممرضين' : (lang == 'en' ? 'Nurses' : 'لیستی پەرستاران');
    }
  }

  String _getSectionTitle(String type, BuildContext context) {
    final lang = context.locale.languageCode;
    if (type == 'labs') {
      return lang == 'ar' ? 'المختبرات' : (lang == 'en' ? 'Laboratories' : 'تاقیگەکان');
    } else {
      return lang == 'ar' ? 'الممرضين' : (lang == 'en' ? 'Nurses' : 'پەرستارەکان');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final lang = context.locale.languageCode;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                size: 16,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        titleSpacing: 0,
        title: Container(
          height: 46,
          margin: const EdgeInsetsDirectional.only(end: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF334155).withValues(alpha: 0.6) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
            ),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: _onSearchChanged,
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: 14,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: lang == 'ar'
                  ? 'البحث عن مختبر، ممرض...'
                  : (lang == 'en' ? 'Search for lab, nurse...' : 'گەڕان بۆ تاقیگە، پەرستار...'),
              hintStyle: const TextStyle(
                fontFamily: 'Rabar',
                color: Color(0xFF94A3B8),
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Iconsax.search_normal_1,
                color: Color(0xFF3B82F6),
                size: 18,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                      child: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 18),
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
      body: Column(
        children: [
          // ── Category Filter Chips ──
          Container(
            height: 54,
            decoration: BoxDecoration(
              color: surface,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final id = cat['id'] as String;
                final icon = cat['icon'] as IconData;
                final isSelected = _selectedCategory == id;
                final label = _getCategoryLabel(id, context);

                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: InkWell(
                    onTap: () => setState(() => _selectedCategory = id),
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected ? null : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : (isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0)),
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 14,
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF334155)),
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Search Results ──
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Labs Group
                      if ((_selectedCategory == 'All' || _selectedCategory == 'Labs') && _labs.isNotEmpty) ...[
                        _buildSectionHeader(_getSectionTitle('labs', context), _labs.length, Iconsax.health),
                        ..._labs.asMap().entries.map((entry) => _buildLabCard(context, entry.value, entry.key)),
                        const SizedBox(height: 16),
                      ],

                      // Nurses Group
                      if ((_selectedCategory == 'All' || _selectedCategory == 'Nurses') && _nurses.isNotEmpty) ...[
                        _buildSectionHeader(_getSectionTitle('nurses', context), _nurses.length, Iconsax.profile_2user),
                        ..._nurses.asMap().entries.map((entry) => _buildNurseCard(context, entry.value, entry.key)),
                        const SizedBox(height: 16),
                      ],

                      // Empty State
                      if (_labs.isEmpty && _nurses.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 60),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Iconsax.search_status,
                                    size: 48,
                                    color: Color(0xFF3B82F6),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  lang == 'ar'
                                      ? 'لم يتم العثور على أي نتائج'
                                      : (lang == 'en' ? 'No results found' : 'هیچ ئەنجامێک نەدۆزرایەوە'),
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  lang == 'ar'
                                      ? 'تأكد من كتابة اسم المختبر أو الممرض بشكل صحيح'
                                      : (lang == 'en'
                                          ? 'Make sure the lab or nurse name is spelled correctly'
                                          : 'دڵنیابە لە دروستی نووسینی ناوی تاقیگە یان پەرستارەکە'),
                                  style: const TextStyle(
                                    fontFamily: 'Rabar',
                                    color: Color(0xFF94A3B8),
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: const Color(0xFF3B82F6)),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _getImageUrl(String? image) {
    if (image != null && image.isNotEmpty && image != 'image') {
      if (image.startsWith('http')) return image;
      return ApiClient.getImageUrl(image);
    }
    return null;
  }

  Widget _buildLabCard(BuildContext context, dynamic l, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final userObj = l['user'] is Map ? l['user'] : l;
    final String labName = context.localizedField(userObj, 'name', fallback: 'cat_lab'.tr());
    final String fallbackImg = _labFallbackImages[index % _labFallbackImages.length];
    final String address = context.localizedField(
      l,
      'address',
      fallback: context.localizedField(l, 'location', fallback: context.localizedField(l, 'city', fallback: '')),
    );
    final String rating = l['rating']?.toString() ?? '4.8';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LabDetailsScreen(lab: l)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 72,
                height: 72,
                color: const Color(0xFFF8FAFC),
                child: Image.asset(
                  fallbackImg,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.biotech,
                    color: Color(0xFF3B82F6),
                    size: 30,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          labName,
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'open_status'.tr(),
                          style: const TextStyle(
                            fontFamily: 'Rabar',
                            color: Color(0xFF10B981),
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Iconsax.location, size: 11, color: Color(0xFF3B82F6)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          address,
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 13),
                      const SizedBox(width: 2),
                      Text(
                        rating,
                        style: const TextStyle(
                          fontFamily: 'Rabar',
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: Color(0xFFD97706),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Iconsax.shield_tick, size: 12, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text(
                        'verified'.tr(),
                        style: const TextStyle(
                          fontFamily: 'Rabar',
                          color: Color(0xFF10B981),
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
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
    ).animate().fadeIn(delay: (index * 60).ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildNurseCard(BuildContext context, dynamic n, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final userObj = n['user'] is Map ? n['user'] : n;
    final String nurseName = context.localizedField(userObj, 'name', fallback: 'top_nurses'.tr());
    final String rawImage = (n['image'] ?? n['image_path'] ?? userObj['profile_image'] ?? '').toString();
    final String? uploadedUrl = _getImageUrl(rawImage);
    final String fallbackImg = _nurseFallbackImages[index % _nurseFallbackImages.length];
    final String imageToUse = (uploadedUrl != null && !uploadedUrl.contains('default')) ? uploadedUrl : fallbackImg;
    final bool isNetwork = imageToUse.startsWith('http');

    final String specialty = context.localizedField(n, 'specialty', fallback: 'medical_specialist'.tr());
    final String city = context.localizedField(n, 'city', fallback: context.localizedField(n, 'address', fallback: ''));
    final String rating = n['rating']?.toString() ?? '4.9';
    final bool isAvailable = n['is_available'] == true || n['is_available'] == 1 || n['is_available'] == '1';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NurseDetailsScreen(
              nurse: n is Map<String, dynamic> ? n : Map<String, dynamic>.from(n as Map),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 72,
                height: 72,
                color: const Color(0xFFF8FAFC),
                child: isNetwork
                    ? CachedNetworkImage(
                        imageUrl: imageToUse,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Image.network(
                          fallbackImg,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Iconsax.profile_2user,
                            color: Color(0xFF0D9488),
                            size: 30,
                          ),
                        ),
                      )
                    : Image.asset(
                        imageToUse,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Iconsax.profile_2user,
                          color: Color(0xFF0D9488),
                          size: 30,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          nurseName,
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isAvailable ? const Color(0xFF10B981) : const Color(0xFF64748B)).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isAvailable ? 'available'.tr() : 'unavailable'.tr(),
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            color: isAvailable ? const Color(0xFF10B981) : const Color(0xFF64748B),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Iconsax.health, size: 11, color: Color(0xFF0D9488)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          specialty.isNotEmpty ? specialty : (city.isNotEmpty ? city : 'پەرستاری گشتی'),
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 13),
                      const SizedBox(width: 2),
                      Text(
                        rating,
                        style: const TextStyle(
                          fontFamily: 'Rabar',
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: Color(0xFFD97706),
                        ),
                      ),
                      if (city.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        const Icon(Iconsax.location, size: 11, color: Color(0xFF64748B)),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            city,
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              fontSize: 10.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      const Spacer(),
                      const Icon(Iconsax.shield_tick, size: 12, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text(
                        'verified'.tr(),
                        style: const TextStyle(
                          fontFamily: 'Rabar',
                          color: Color(0xFF10B981),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
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
    ).animate().fadeIn(delay: (index * 60).ms).slideY(begin: 0.05, end: 0);
  }
}
