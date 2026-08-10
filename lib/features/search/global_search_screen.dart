import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
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
  final List<String> _categories = [
    'All',
    'Doctors',
    'Pharmacies',
    'Medications',
    'Labs',
  ];

  @override
  void initState() {
    super.initState();
    // Fetch initial data when screen opens
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

    _debounce = Timer(const Duration(milliseconds: 500), () {
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
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Container(
          height: 44,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search doctors, pharmacies, labs...',
              hintStyle: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
              prefixIcon: const Icon(
                Iconsax.search_normal_1,
                color: Colors.grey,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Categories
          Container(
            height: 50,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                  child: InkWell(
                    onTap: () => setState(() => _selectedCategory = category),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF3B82F6)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF3B82F6)
                              : Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        category,
                        style: GoogleFonts.inter(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if ((_selectedCategory == 'All' ||
                              _selectedCategory == 'Doctors') &&
                          _doctors.isNotEmpty) ...[
                        _buildSectionHeader('Doctors'),
                        ..._doctors.map((d) => _buildDoctorCard(context, d)),
                        const SizedBox(height: 16),
                      ],

                      if ((_selectedCategory == 'All' ||
                              _selectedCategory == 'Pharmacies') &&
                          _pharmacies.isNotEmpty) ...[
                        _buildSectionHeader('Pharmacies'),
                        ..._pharmacies.map(
                          (p) => _buildPharmacyCard(context, p),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if ((_selectedCategory == 'All' ||
                              _selectedCategory == 'Labs') &&
                          _labs.isNotEmpty) ...[
                        _buildSectionHeader('Laboratories'),
                        ..._labs.map((l) => _buildLabCard(context, l)),
                        const SizedBox(height: 16),
                      ],

                      if ((_selectedCategory == 'All' ||
                              _selectedCategory == 'Medications') &&
                          _medications.isNotEmpty) ...[
                        _buildSectionHeader('Medications'),
                        ..._medications.map(
                          (m) => _buildMedicationCard(context, m),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (_doctors.isEmpty &&
                          _pharmacies.isEmpty &&
                          _labs.isEmpty &&
                          _medications.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Column(
                              children: [
                                Icon(
                                  Iconsax.search_favorite,
                                  size: 48,
                                  color: Colors.grey.withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No results found',
                                  style: GoogleFonts.inter(
                                    color: Colors.grey,
                                    fontSize: 16,
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          Icon(Iconsax.arrow_right_3, size: 18, color: const Color(0xFF3B82F6)),
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

  Widget _buildAvatarFallback(String type) {
    String assetPath;
    switch (type) {
      case 'doctor':
        assetPath = 'assets/images/doctor1.png';
        break;
      case 'pharmacy':
        assetPath = 'assets/images/pharmacy1.jpg';
        break;
      case 'lab':
        assetPath = 'assets/images/lab1.jpg';
        break;
      default:
        assetPath = 'assets/images/doctor1.png';
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(assetPath, width: 70, height: 70, fit: BoxFit.cover),
    );
  }

  Widget _buildMedAvatarFallback() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/medicine.png', fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildDoctorCard(BuildContext context, dynamic d) {
    final String doctorName = d['name'] ?? d['"name"'] ?? 'Doctor';
    final String? imageUrl = _getImageUrl(d['image'] ?? d['"image"']);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorDetailsScreen(
              doctorId: d['id'],
              name: doctorName,
              specialty: d['specialization'] ?? d['"specialization"'] ?? '',
              image: imageUrl ?? '',
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildAvatarFallback('doctor'),
                ),
              )
            else
              _buildAvatarFallback('doctor'),
            const SizedBox(width: 16),
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
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Iconsax.star_1,
                            color: Color(0xFFF59E0B),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            d['rating']?.toString() ?? '5.0',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    d['specialization'] ??
                        d['"specialization"'] ??
                        'Specialist',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Book Now',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF3B82F6),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${d['fee'] ?? d['"fee"'] ?? '25,000'} IQD',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF10B981),
                          fontSize: 13,
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
    );
  }

  Widget _buildPharmacyCard(BuildContext context, dynamic p) {
    final String pharmacyName = p['name'] ?? p['"name"'] ?? 'Pharmacy';
    final String? imageUrl = _getImageUrl(p['image'] ?? p['"image"']);

    return GestureDetector(
      onTap: () {
        final pharmacyModel = Pharmacy(
          id: p['id'],
          name: pharmacyName,
          profileImage: imageUrl,
          rating: double.tryParse(p['rating']?.toString() ?? '5.0') ?? 5.0,
          isOpen: p['is_open'] == 1 || p['"is_open"'] == '1',
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PharmacyDetailScreen(pharmacy: pharmacyModel),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildAvatarFallback('pharmacy'),
                ),
              )
            else
              _buildAvatarFallback('pharmacy'),
            const SizedBox(width: 16),
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
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Iconsax.star_1,
                            color: Color(0xFFF59E0B),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            p['rating']?.toString() ?? '5.0',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Iconsax.location,
                        size: 12,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          p['address'] ?? p['"address"'] ?? 'Local Pharmacy',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF64748B),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Iconsax.clock,
                        size: 12,
                        color: (p['is_open'] == 1 || p['"is_open"'] == '1')
                            ? const Color(0xFF10B981)
                            : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        (p['is_open'] == 1 || p['"is_open"'] == '1')
                            ? 'Open Now'
                            : 'Closed',
                        style: GoogleFonts.inter(
                          color: (p['is_open'] == 1 || p['"is_open"'] == '1')
                              ? const Color(0xFF10B981)
                              : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Iconsax.truck_fast,
                        size: 14,
                        color: Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${p['delivery_time'] ?? p['"delivery_time"'] ?? '15-20'} min',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF3B82F6),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildLabCard(BuildContext context, dynamic l) {
    final String labName = l['name'] ?? l['"name"'] ?? 'Lab';
    final String? imageUrl = _getImageUrl(l['image'] ?? l['"image"']);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LabDetailsScreen(lab: l)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildAvatarFallback('lab'),
                ),
              )
            else
              _buildAvatarFallback('lab'),
            const SizedBox(width: 16),
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
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Iconsax.star_1,
                            color: Color(0xFFF59E0B),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l['rating']?.toString() ?? '5.0',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Iconsax.location,
                        size: 12,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          l['address'] ?? l['"address"'] ?? 'Medical Lab',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF64748B),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'View Tests',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF475569),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildMedicationCard(BuildContext context, dynamic m) {
    final String medName = m['name'] ?? m['"name"'] ?? 'Medication';
    final String? imageUrl = _getImageUrl(m['image'] ?? m['"image"']);

    return GestureDetector(
      onTap: () {
        if (m['pharmacy_id'] != null) {
          final pharmacyModel = Pharmacy(
            id: m['pharmacy_id'],
            name: m['pharmacy']?['name'] ?? m['pharmacy']?['"name"'] ?? '',
            profileImage: _getImageUrl(
              m['pharmacy']?['image'] ?? m['pharmacy']?['"image"'],
            ),
            rating: 5.0,
            isOpen: true,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PharmacyDetailScreen(pharmacy: pharmacyModel),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildMedAvatarFallback(),
                ),
              )
            else
              _buildMedAvatarFallback(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medName,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Iconsax.shop,
                        size: 12,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          m['pharmacy']?['name'] ??
                              m['pharmacy']?['"name"'] ??
                              'Available in pharmacy',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF64748B),
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
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${m['price'] ?? '0'} IQD',
                style: GoogleFonts.inter(
                  color: const Color(0xFF3B82F6),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
