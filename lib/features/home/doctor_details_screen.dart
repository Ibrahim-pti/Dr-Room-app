import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class DoctorDetailsScreen extends StatefulWidget {
  const DoctorDetailsScreen({super.key});

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  int _selectedDateIndex = 2; // Default to 'Wed 12'

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Header Section ──
            SizedBox(
              height: 460,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Blue Gradient Background
                  Container(
                    height: 410,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFE8F1FF), // Very light blue
                          Color(0xFF82AFFF), // Soft blue
                        ],
                      ),
                    ),
                  ),

                  // Doctor Image
                  PositionedDirectional(
                    end: -15,
                    bottom: 85, // Moved up to look better
                    width: size.width * 0.72,
                    child:
                        Image.asset(
                              'assets/images/doctor3.png',
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                            )
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .slideX(begin: 0.2, end: 0),
                  ),

                  // White Background Curve
                  PositionedDirectional(
                    bottom: 0,
                    start: 0,
                    end: 0,
                    height: 60,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                      ),
                    ),
                  ),

                  // Content over background
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          // ── App Bar ──
                          Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Container(
                                      width: 46,
                                      height: 46,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.chevron_left_rounded,
                                        color: Color(0xFF0F172A),
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Details',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF0F172A),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.share_outlined,
                                      color: Color(0xFF0F172A),
                                      size: 22,
                                    ),
                                  ),
                                ],
                              )
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .slideY(begin: -0.2, end: 0),

                          const SizedBox(height: 25),

                          // Rating Pill
                          Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Color(0xFFFBBF24),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '4.9',
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF0F172A),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .animate()
                              .fadeIn(delay: 200.ms)
                              .slideX(begin: -0.2, end: 0),

                          const SizedBox(height: 24),

                          // Doctor Name & Specialty
                          SizedBox(
                            width: size.width * 0.55,
                            child: Text(
                                  'Dr. Nusrat\nJahan',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w600,
                                    height: 1.2,
                                  ),
                                )
                                .animate()
                                .fadeIn(delay: 300.ms)
                                .slideX(begin: -0.2, end: 0),
                          ),

                          const SizedBox(height: 12),

                          SizedBox(
                            width: size.width * 0.55,
                            child: Text(
                                  'Pediatrician\nSpecialist',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                  ),
                                )
                                .animate()
                                .fadeIn(delay: 400.ms)
                                .slideX(begin: -0.2, end: 0),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Stats Card ──
                  PositionedDirectional(
                    start: 24,
                    end: 24,
                    bottom: 10,
                    child:
                        Container(
                              height: 85,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStatItem(
                                    Icons.history,
                                    '10 Years',
                                    'Experience',
                                  ),
                                  _buildStatItem(
                                    Iconsax.profile_2user,
                                    '2.5k +',
                                    'Patients',
                                  ),
                                  _buildStatItem(
                                    Iconsax.star,
                                    '3.8k +',
                                    'Reviews',
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 500.ms)
                            .slideY(begin: 0.2, end: 0),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Details Text ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Details',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF475569),
                        fontSize: 14,
                        height: 1.6,
                      ),
                      children: [
                        const TextSpan(
                          text:
                              'Dr. Nusrat Jahan is a trusted pediatrician with 10 years of experience, providing safe, caring, and reliable treatment for children...',
                        ),
                        TextSpan(
                          text: 'See more',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 600.ms),
            ),

            const SizedBox(height: 32),

            // ── Select Date ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Date',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Iconsax.calendar_1,
                          size: 16,
                          color: Color(0xFF475569),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Jan 12',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF475569),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: Color(0xFF475569),
                        ),
                      ],
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 700.ms),
            ),

            const SizedBox(height: 20),

            // Date Picker (Horizontal List)
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _buildDatePill('Mon', '12', 0),
                  const SizedBox(width: 12),
                  _buildDatePill('Tue', '12', 1),
                  const SizedBox(width: 12),
                  _buildDatePill('Wed', '12', 2), // Selected
                  const SizedBox(width: 12),
                  _buildDatePill('Thu', '12', 3),
                  const SizedBox(width: 12),
                  _buildDatePill('Fri', '12', 4),
                  const SizedBox(width: 12),
                  _buildDatePill('Sat', '12', 5),
                ],
              ),
            ).animate().fadeIn(delay: 750.ms).slideX(begin: 0.1, end: 0),

            const SizedBox(height: 32),

            // ── Book Appointment Button ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Book Appointment',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 850.ms).slideY(begin: 0.2, end: 0),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: const Color(0xFF0F172A)),
        const SizedBox(width: 8),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                color: const Color(0xFF3B82F6),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: const Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDatePill(String day, String date, int index) {
    final isSelected = _selectedDateIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDateIndex = index;
        });
      },
      child: Container(
        width: 65,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
          borderRadius: BorderRadius.circular(35),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day,
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  date,
                  style: GoogleFonts.poppins(
                    color: isSelected
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
