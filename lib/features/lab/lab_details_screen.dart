import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'lab_order_method_screen.dart';

class LabDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> lab;

  const LabDetailsScreen({super.key, required this.lab});

  @override
  State<LabDetailsScreen> createState() => _LabDetailsScreenState();
}

class _LabDetailsScreenState extends State<LabDetailsScreen> {
  // Dummy selected tests for UI demonstration
  List<String> _selectedTests = ['CBC', 'Vitamin D'];
  int _totalPrice = 45000;

  @override
  Widget build(BuildContext context) {
    final String name = widget.lab['user']?['name'] ?? widget.lab['name'] ?? 'Olympic Medical Lab';
    final String city = widget.lab['city'] ?? 'Erbil';
    final String rating = widget.lab['rating']?.toString() ?? '4.8';
    final String coverImage = widget.lab['img'] ?? 'assets/images/lab1.jpg';

    // Using a light, very clean background color from the design
    final Color bgColor = const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
          child: _buildSquareButton(
            icon: Icons.arrow_back_ios_new,
            onTap: () => Navigator.pop(context),
          ),
        ),
        actions: [
          _buildSquareButton(
            icon: Iconsax.heart,
            onTap: () {},
          ),
          const SizedBox(width: 12),
          _buildSquareButton(
            icon: Iconsax.share,
            onTap: () {},
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 700;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Hero Section (Image & Details) ──
                    if (isTablet)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 4,
                            child: _buildHeroImage(coverImage, isTablet),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            flex: 6,
                            child: _buildLabDetails(name, city, rating),
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeroImage(coverImage, isTablet),
                          const SizedBox(height: 24),
                          _buildLabDetails(name, city, rating),
                        ],
                      ),
                    
                    const SizedBox(height: 24),

                    // ── Features Row ──
                    _buildFeaturesRow(),

                    const SizedBox(height: 32),

                    // ── About Section ──
                    _buildSectionHeader('about_lab'.tr(), 'view_more'.tr()),
                    const SizedBox(height: 8),
                    Text(
                      "$name is one of the leading labs in $city, providing accurate results with advanced technology and professional staff.",
                      style: GoogleFonts.inter(
                        color: const Color(0xFF64748B),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 32),

                    // ── Available Tests ──
                    _buildSectionHeader('${'available_tests'.tr()} (12)', 'view_all_tests'.tr()),
                    const SizedBox(height: 16),
                    _buildTestsList(),

                    const SizedBox(height: 32),

                    // ── Customer Reviews ──
                    _buildSectionHeader('${'customer_reviews'.tr()} (120)', 'view_all'.tr()),
                    const SizedBox(height: 16),
                    _buildReviewCard(),
                  ],
                ),
              ),

              // ── Sticky Bottom Bar ──
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: _buildStickyBottomBar(),
              ),
            ],
          );
        },
      ),
    );
  }

  // UI Components

  Widget _buildSquareButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Icon(icon, color: const Color(0xFF0F172A), size: 20),
      ),
    );
  }

  Widget _buildHeroImage(String image, bool isTablet) {
    return AspectRatio(
      aspectRatio: isTablet ? 1 : 1.8,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: DecorationImage(
            image: AssetImage(image),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '1/8',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scaleXY(begin: 0.95);
  }

  Widget _buildLabDetails(String name, String city, String rating) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Featured Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF9C3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFEAB308), size: 14),
              const SizedBox(width: 6),
              Text(
                'featured_lab'.tr(),
                style: GoogleFonts.inter(color: const Color(0xFFCA8A04), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 16),
        
        // Lab Name
        Text(
          name,
          style: TextStyle(
            fontFamily: 'Rabar',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 12),

        // Rating and Location
        Row(
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFFEAB308), size: 20),
            const SizedBox(width: 6),
            Text(
              rating,
              style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 6),
            Text(
              '(120 ${'reviews'.tr()})',
              style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 14),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.circle, size: 4, color: Color(0xFFCBD5E1)),
            ),
            const Icon(Iconsax.location_copy, color: Color(0xFF3B82F6), size: 16),
            const SizedBox(width: 6),
            Text(
              '$city, 100m away',
              style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 14),
            ),
          ],
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildFeaturesRow() {
    final features = [
      {'icon': Iconsax.clock, 'title': '25-35 min', 'sub': 'nurse_arrival'.tr(), 'color': const Color(0xFF3B82F6)},
      {'icon': Iconsax.document_text, 'title': 'same_day_result'.tr(), 'sub': 'Result', 'color': const Color(0xFF10B981)},
      {'icon': Iconsax.shield_tick, 'title': 'Certified', 'sub': 'iso_15189'.tr(), 'color': const Color(0xFF6366F1)},
      {'icon': Iconsax.headphone, 'title': '24/7 Support', 'sub': 'Available', 'color': const Color(0xFF8B5CF6)},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: features.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          return Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Icon(item['icon'] as IconData, color: item['color'] as Color, size: 20),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] as String,
                      style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      item['sub'] as String,
                      style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: (500 + (idx * 100)).ms).slideX();
        }).toList(),
      ),
    );
  }



  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            color: const Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            Text(
              action,
              style: GoogleFonts.inter(
                color: const Color(0xFF3B82F6),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFF3B82F6), size: 12),
          ],
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildTestsList() {
    final tests = [
      {'name': 'CBC', 'price': '15,000 IQD', 'icon': Iconsax.health},
      {'name': 'HbA1c', 'price': '20,000 IQD', 'icon': Iconsax.drop},
      {'name': 'Vitamin D', 'price': '30,000 IQD', 'icon': Iconsax.sun},
      {'name': 'TSH', 'price': '18,000 IQD', 'icon': Iconsax.activity},
      {'name': 'Lipid Profile', 'price': '25,000 IQD', 'icon': Iconsax.drop},
    ];

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: tests.length,
        itemBuilder: (context, index) {
          final test = tests[index];
          final isSelected = _selectedTests.contains(test['name']);
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 16, bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(test['icon'] as IconData, color: const Color(0xFFEF4444), size: 32),
                ),
                const SizedBox(height: 12),
                Text(
                  test['name'] as String,
                  style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  test['price'] as String,
                  style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedTests.remove(test['name']);
                      } else {
                        _selectedTests.add(test['name'] as String);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(20),
                      color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isSelected ? 'Added' : 'add'.tr(),
                          style: GoogleFonts.inter(
                            color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF3B82F6),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(isSelected ? Icons.check : Icons.add, color: const Color(0xFF3B82F6), size: 14),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: (200 + index * 100).ms).slideY(begin: 0.1);
        },
      ),
    );
  }

  Widget _buildReviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFE2E8F0),
                backgroundImage: const AssetImage('assets/images/user_placeholder.png'),
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hawar Mustafa',
                      style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFEAB308), size: 14),
                        const Icon(Icons.star_rounded, color: Color(0xFFEAB308), size: 14),
                        const Icon(Icons.star_rounded, color: Color(0xFFEAB308), size: 14),
                        const Icon(Icons.star_rounded, color: Color(0xFFEAB308), size: 14),
                        const Icon(Icons.star_rounded, color: Color(0xFFEAB308), size: 14),
                        const SizedBox(width: 6),
                        Text('5.0', style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Verified', style: GoogleFonts.inter(color: const Color(0xFF166534), fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '2 days ago',
                style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.more_vert, color: Color(0xFF94A3B8), size: 16),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Clean place, fast service and accurate results.\nHighly recommended!',
            style: GoogleFonts.inter(color: const Color(0xFF475569), fontSize: 14, height: 1.5),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildStickyBottomBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(isMobile ? 14 : 24),
                child: isMobile
                    ? _buildMobileBottomBarContent()
                    : _buildTabletBottomBarContent(),
              ),
            ],
          ),
        ).animate().slideY(begin: 1.0, duration: 500.ms, curve: Curves.easeOut);
      },
    );
  }

  Widget _buildMobileBottomBarContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedTests.isNotEmpty)
          SizedBox(
            height: 30,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedTests.length,
              itemBuilder: (context, index) {
                final test = _selectedTests[index];
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(test, style: GoogleFonts.inter(color: const Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => setState(() => _selectedTests.remove(test)),
                        child: const Icon(Icons.close, size: 12, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        if (_selectedTests.isNotEmpty) const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('total_price'.tr(), style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12)),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          '45,000',
                          style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text('IQD', style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 5,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const LabOrderMethodScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  shadowColor: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text('continue'.tr(), style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabletBottomBarContent() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${'selected_tests'.tr()} (${_selectedTests.length})',
                style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedTests.map((test) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(test, style: GoogleFonts.inter(color: const Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => setState(() => _selectedTests.remove(test)),
                          child: const Icon(Icons.close, size: 14, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('total_price'.tr(), style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 14)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('45,000', style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('IQD', style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LabOrderMethodScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('continue'.tr(), style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
