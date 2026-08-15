import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/utils/api_client.dart';
import '../doctors/doctor_details_screen.dart';
import '../pharmacy/screens/pharmacy_detail_screen.dart';
import '../pharmacy/models/pharmacy_model.dart';
import '../lab/lab_details_screen.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isLoading = false;

  List<dynamic> _doctors = [];
  List<dynamic> _pharmacies = [];
  List<dynamic> _medications = [];
  List<dynamic> _labs = [];

  String _selectedCategory = 'All';
  final List<Map<String, dynamic>> _categories = [
    {'id': 'All', 'label': 'سەرجەمیان', 'icon': Iconsax.category},
    {'id': 'Doctors', 'label': 'پزیشکەکان', 'icon': Iconsax.profile_2user},
    {'id': 'Pharmacies', 'label': 'دەرمانخانەکان', 'icon': Iconsax.hospital},
    {'id': 'Labs', 'label': 'تاقیگەکان', 'icon': Iconsax.health},
    {'id': 'Medications', 'label': 'دەرمانەکان', 'icon': Iconsax.box_1},
  ];

  final List<String> _doctorFallbackImages = [
    'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=500&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=500&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1594824813511-236b283d0cfa?w=500&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=500&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1537368910025-700350fe46c7?w=500&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1651008376811-b90baee60c1f?w=500&auto=format&fit=crop&q=80',
  ];

  final List<String> _pharmacyFallbackImages = [
    'assets/images/pharmacy1.jpg',
    'assets/images/pharmacy2.jpg',
    'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=500&auto=format&fit=crop&q=60',
    'https://images.unsplash.com/photo-1576602976047-174e57a47881?w=500&auto=format&fit=crop&q=60',
  ];

  final List<String> _labFallbackImages = [
    'assets/images/lab1.jpg',
    'assets/images/lab2.jpg',
    'assets/images/lab3.jpg',
    'assets/images/lab4.jpg',
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
            _doctors = data['data']['doctors'] ?? [];
            _pharmacies = data['data']['pharmacies'] ?? [];
            _medications = data['data']['medications'] ?? [];
            _labs = data['data']['labs'] ?? [];
          });
        }
      }
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

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
              hintText: 'گەڕان بۆ پزیشک، دەرمانخانە، تاقیگە...',
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
                final label = cat['label'] as String;
                final icon = cat['icon'] as IconData;
                final isSelected = _selectedCategory == id;

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
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12.5,
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
                      // Doctors Group
                      if ((_selectedCategory == 'All' || _selectedCategory == 'Doctors') && _doctors.isNotEmpty) ...[
                        _buildSectionHeader('پزیشکەکان', _doctors.length, Iconsax.profile_2user),
                        ..._doctors.asMap().entries.map((entry) => _buildDoctorCard(context, entry.value, entry.key)),
                        const SizedBox(height: 16),
                      ],

                      // Pharmacies Group
                      if ((_selectedCategory == 'All' || _selectedCategory == 'Pharmacies') && _pharmacies.isNotEmpty) ...[
                        _buildSectionHeader('دەرمانخانەکان', _pharmacies.length, Iconsax.hospital),
                        ..._pharmacies.asMap().entries.map((entry) => _buildPharmacyCard(context, entry.value, entry.key)),
                        const SizedBox(height: 16),
                      ],

                      // Labs Group
                      if ((_selectedCategory == 'All' || _selectedCategory == 'Labs') && _labs.isNotEmpty) ...[
                        _buildSectionHeader('تاقیگەکان', _labs.length, Iconsax.health),
                        ..._labs.asMap().entries.map((entry) => _buildLabCard(context, entry.value, entry.key)),
                        const SizedBox(height: 16),
                      ],

                      // Medications Group
                      if ((_selectedCategory == 'All' || _selectedCategory == 'Medications') && _medications.isNotEmpty) ...[
                        _buildSectionHeader('دەرمانەکان', _medications.length, Iconsax.box_1),
                        ..._medications.asMap().entries.map((entry) => _buildMedicationCard(context, entry.value, entry.key)),
                        const SizedBox(height: 16),
                      ],

                      // Empty State
                      if (_doctors.isEmpty && _pharmacies.isEmpty && _labs.isEmpty && _medications.isEmpty)
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
                                  'هیچ ئەنجامێک نەدۆزرایەوە',
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'تکایە دڵنیابە لە دروستی نووسینی ناوەکە یان پسپۆڕییەکە',
                                  style: TextStyle(
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

  Widget _buildDoctorCard(BuildContext context, dynamic d, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final String doctorName = d['name'] ?? d['"name"'] ?? 'د. ئارام عوسمان';
    final String rawImage = d['image'] ?? d['"image"'] ?? '';
    final String? uploadedUrl = _getImageUrl(rawImage);
    final String fallbackImg = _doctorFallbackImages[index % _doctorFallbackImages.length];
    final String imageToUse = (uploadedUrl != null && !uploadedUrl.contains('default') && !uploadedUrl.contains('doctor1.png'))
        ? uploadedUrl
        : fallbackImg;
    final String specialty = d['specialization'] ?? d['"specialization"'] ?? 'پسپۆڕی پزیشکی';
    final String fee = d['fee']?.toString() ?? d['"fee"']?.toString() ?? '25,000';
    final String rating = d['rating']?.toString() ?? '4.9';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorDetailsScreen(
              doctorId: d['id'] ?? 1,
              name: doctorName,
              specialty: specialty,
              image: imageToUse,
              initialDoctor: d is Map<String, dynamic> ? d : null,
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
            // Doctor Photo
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 72,
                height: 78,
                color: const Color(0xFFEFF6FF),
                child: CachedNetworkImage(
                  imageUrl: imageToUse,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.15),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.person,
                    size: 36,
                    color: Color(0xFF3B82F6),
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
                          doctorName,
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
                      // Verified Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 10),
                            SizedBox(width: 2),
                            Text(
                              'باوەڕپێکراو',
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                color: Color(0xFF10B981),
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    specialty,
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      fontSize: 11.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Rating
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
                        ],
                      ),
                      const SizedBox(width: 10),
                      // Fee
                      Text(
                        '$fee د.ع',
                        style: const TextStyle(
                          fontFamily: 'Rabar',
                          color: Color(0xFF10B981),
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // Book Button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Text(
                          'نۆرەگرتن',
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
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

  Widget _buildPharmacyCard(BuildContext context, dynamic p, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final String pharmacyName = p['name'] ?? p['"name"'] ?? 'دەرمانخانە';
    final String rawImage = p['image'] ?? p['"image"'] ?? '';
    final String? uploadedUrl = _getImageUrl(rawImage);
    final String fallbackImg = _pharmacyFallbackImages[index % _pharmacyFallbackImages.length];
    final String imageToUse = (uploadedUrl != null && !uploadedUrl.contains('default')) ? uploadedUrl : fallbackImg;
    final bool isNetwork = imageToUse.startsWith('http');
    final String address = p['address'] ?? p['"address"'] ?? 'هەولێر - شەقامی پزیشکان';
    final String rating = p['rating']?.toString() ?? '4.8';

    return GestureDetector(
      onTap: () {
        final pharmacyModel = Pharmacy(
          id: p['id'] ?? 1,
          name: pharmacyName,
          profileImage: imageToUse,
          rating: double.tryParse(rating) ?? 4.8,
          isOpen: p['is_open'] == 1 || p['"is_open"'] == '1' || true,
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PharmacyDetailScreen(pharmacy: pharmacyModel),
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
                        errorWidget: (context, url, error) => Image.asset('assets/images/pharmacy1.jpg', fit: BoxFit.cover),
                      )
                    : Image.asset(imageToUse, fit: BoxFit.cover),
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
                          pharmacyName,
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
                        child: const Text(
                          'کراوەیە',
                          style: TextStyle(
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
                      const Icon(Iconsax.truck_fast, size: 12, color: Color(0xFF3B82F6)),
                      const SizedBox(width: 4),
                      const Text(
                        'گەیاندنی خێرا',
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          color: Color(0xFF3B82F6),
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

  Widget _buildLabCard(BuildContext context, dynamic l, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final String labName = l['name'] ?? l['"name"'] ?? 'تاقیگەی پزیشکی';
    final String fallbackImg = _labFallbackImages[index % _labFallbackImages.length];
    final String address = l['address'] ?? l['"address"'] ?? 'هەولێر';
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
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 72,
                height: 72,
                color: const Color(0xFFF8FAFC),
                child: Image.asset(fallbackImg, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'پشکنینەکان',
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            color: Color(0xFF3B82F6),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
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

  Widget _buildMedicationCard(BuildContext context, dynamic m, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final String medName = m['name'] ?? m['"name"'] ?? 'دەرمان';
    final String pharmacyName = m['pharmacy']?['name'] ?? m['pharmacy']?['"name"'] ?? 'لە دەرمانخانە بەردەستە';
    final String price = m['price']?.toString() ?? '3,500';

    return GestureDetector(
      onTap: () {
        if (m['pharmacy_id'] != null) {
          final pharmacyModel = Pharmacy(
            id: m['pharmacy_id'],
            name: pharmacyName,
            profileImage: null,
            rating: 4.9,
            isOpen: true,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PharmacyDetailScreen(pharmacy: pharmacyModel),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Iconsax.box_1, color: Color(0xFF8B5CF6), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medName,
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Iconsax.shop, size: 11, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          pharmacyName,
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
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$price د.ع',
                style: const TextStyle(
                  fontFamily: 'Rabar',
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.bold,
                  fontSize: 11.5,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.05, end: 0);
  }
}
