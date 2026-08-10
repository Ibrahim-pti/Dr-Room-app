import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'lab_details_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/utils/api_client.dart';
import 'package:easy_localization/easy_localization.dart';

class AllLabsScreen extends StatefulWidget {
  const AllLabsScreen({super.key});

  @override
  State<AllLabsScreen> createState() => _AllLabsScreenState();
}

class _AllLabsScreenState extends State<AllLabsScreen> {
  List<dynamic> _allLabs = [];
  List<dynamic> _filteredLabs = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  final TextEditingController _searchCtrl = TextEditingController();

  final List<String> _filters = ['All', 'top_rated', 'nearest', 'open_now'];

  @override
  void initState() {
    super.initState();
    _fetchLabs();
  }

  Future<void> _fetchLabs() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.get('/admin/labs');
      if (response.statusCode == 200 && mounted) {
        final List<dynamic> labs = jsonDecode(response.body);
        setState(() {
          _allLabs = labs.where((l) => l['status'] == 'approved').toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching labs: $e');
    } finally {
      if (mounted) {
        setState(() {
          if (_allLabs.isEmpty) {
            _allLabs = [
              {
                'id': 1,
                'name': 'Erbil Central Laboratory',
                'city': 'Erbil',
                'phone': '0750 123 4567',
                'type': 'General',
                'rating': '4.8',
                'reviews': 120,
                'image': 'assets/images/lab1.jpg',
                'isVerified': true,
              },
              {
                'id': 2,
                'name': 'Sulaymaniyah Model Lab',
                'city': 'Sulaymaniyah',
                'phone': '0770 123 4567',
                'type': 'Private',
                'rating': '4.9',
                'reviews': 85,
                'image': 'assets/images/lab2.jpg',
                'isVerified': true,
              },
              {
                'id': 3,
                'name': 'Duhok Diagnostic Center',
                'city': 'Duhok',
                'phone': '0751 123 4567',
                'type': 'General',
                'rating': '4.6',
                'reviews': 45,
                'image': 'assets/images/lab3.jpg',
                'isVerified': false,
              },
              {
                'id': 4,
                'name': 'Kirkuk Medica Lab',
                'city': 'Kirkuk',
                'phone': '0771 123 4567',
                'type': 'Private',
                'rating': '4.7',
                'reviews': 210,
                'image': 'assets/images/lab4.jpg',
                'isVerified': true,
              },
              {
                'id': 5,
                'name': 'Halabja Medical Lab',
                'city': 'Halabja',
                'phone': '0750 987 6543',
                'type': 'General',
                'rating': '4.5',
                'reviews': 34,
                'image': 'assets/images/lab.png',
                'isVerified': false,
              },
            ];
          }
          _filteredLabs = _allLabs;
          _isLoading = false;
        });
      }
    }
  }

  void _filterLabs() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filteredLabs = _allLabs.where((lab) {
        final nameMatches =
            lab['name']?.toString().toLowerCase().contains(query) ?? false;

        bool filterMatches = true;
        if (_selectedFilter == 'top_rated') {
          filterMatches = (double.tryParse(lab['rating'] ?? '0') ?? 0) >= 4.7;
        }

        return nameMatches && filterMatches;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
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
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                  )
                else if (_filteredLabs.isEmpty)
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
                            child: const Icon(
                              Iconsax.search_normal_1,
                              size: 48,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'no_labs_found'.tr(),
                            style: GoogleFonts.inter(
                              color: const Color(0xFF475569),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
                    ),
                  )
                else
                  ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredLabs.length,
                    itemBuilder: (context, index) {
                      return _buildPremiumLabCard(_filteredLabs[index], index);
                    },
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF0F172A),
            size: 18,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 60, bottom: 16, right: 20),
        title: Text(
          'all_labs'.tr(),
          style: const TextStyle(
            fontFamily: 'Rabar',
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      const Icon(
                        Iconsax.search_normal_1,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (_) => _filterLabs(),
                          style: GoogleFonts.inter(
                            color: const Color(0xFF0F172A),
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'search_labs'.tr(),
                            hintStyle: GoogleFonts.inter(
                              color: const Color(0xFF94A3B8),
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Iconsax.setting_4, color: Colors.white),
              ),
            ],
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

          const SizedBox(height: 24),

          // Filters Row
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedFilter = filter);
                    _filterLabs();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF0F172A)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      filter == 'All' ? 'all_labs'.tr() : filter.tr(),
                      style: GoogleFonts.inter(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF475569),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildPremiumLabCard(dynamic lab, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LabDetailsScreen(lab: lab)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left: Image ──
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: AssetImage(
                    lab['image'] ?? 'assets/images/laboratory.jpg',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // ── Right: Details ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF9C3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFEAB308),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              lab['rating'] ?? '4.8',
                              style: GoogleFonts.inter(
                                color: const Color(0xFFCA8A04),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (lab['isVerified'] == true)
                        const Icon(
                          Icons.verified,
                          color: Color(0xFF3B82F6),
                          size: 16,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Name
                  Text(
                    lab['name'] ?? 'تاقیگە',
                    style: const TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      const Icon(
                        Iconsax.location,
                        color: Color(0xFF94A3B8),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          lab['city'] ?? 'Erbil',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF64748B),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Bottom Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${lab['reviews'] ?? 120} Reviews',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'view_more'.tr(),
                              style: GoogleFonts.inter(
                                color: const Color(0xFF3B82F6),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios, color: Color(0xFF3B82F6), size: 10),
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
    ).animate().fadeIn(delay: (100 * index).ms).slideY(begin: 0.1, end: 0);
  }
}
