import 'package:flutter/material.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../lab/lab_order_method_screen.dart';
import '../nursing/nursing_services_screen.dart';

class AllCategoriesScreen extends StatelessWidget {
  const AllCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'All Categories',
          style: GoogleFonts.poppins(
            color: const Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: GridView.count(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          _buildGridCard(context, imagePath: 'assets/images/doctor.png', title: 'Doctor', isActive: false, delay: 100),
          _buildGridCard(context, imagePath: 'assets/images/medicine.png', title: 'Pharmacy', isActive: false, delay: 150),
          _buildGridCard(context, imagePath: 'assets/images/lab.png', title: 'Lab', isActive: true, delay: 200),
          _buildGridCard(context, imagePath: 'assets/images/xray.png', title: 'X-Ray', isActive: false, delay: 250),
          _buildGridCard(context, imagePath: 'assets/images/doctor_bag.png', title: 'Nursing', isActive: true, delay: 300),
          _buildGridCard(context, imagePath: 'assets/images/report.png', title: 'Reports', isActive: false, delay: 350),
          _buildGridCard(context, imagePath: 'assets/images/apps.png', title: 'Specialty', isActive: false, delay: 400),
          _buildGridCard(context, imagePath: 'assets/images/add.png', title: 'Ambulance', isActive: false, delay: 450),
        ],
      ),
    );
  }

  Widget _buildGridCard(
    BuildContext context, {
    required String imagePath,
    required String title,
    required bool isActive,
    required int delay,
  }) {
    return GestureDetector(
      onTap: () {
        if (!isActive) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'ئەم بەشە لە قۆناغی ئامادەکارییە و بەم زووانە دەکەوێتە خزمەتت.',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              backgroundColor: const Color(0xFF0F172A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          if (title == 'Lab') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LabOrderMethodScreen()),
            );
          } else if (title == 'Nursing') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NursingServicesScreen()),
            );
          }
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Opacity(
                    opacity: isActive ? 1.0 : 0.6,
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: isActive ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
          if (!isActive)
            PositionedDirectional(
              top: -6,
              end: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  'Soon',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF94A3B8),
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.1, end: 0),
    );
  }
}
