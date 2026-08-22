import 'package:dr_room/features/emergency/sos_screen.dart';
import 'package:flutter/material.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../doctors/all_doctors_screen.dart';
import '../pharmacy/screens/pharmacies_screen.dart';
import '../lab/all_labs_screen.dart';
import '../nursing/nurse_list_screen.dart';

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
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF0F172A),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'categories'.tr(),
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
        childAspectRatio: 0.82,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          _buildGridCard(
            context,
            imagePath: 'assets/images/lab.png',
            titleKey: 'cat_lab',
            id: 'lab',
            isActive: true,
            delay: 100,
          ),
          _buildGridCard(
            context,
            imagePath: 'assets/images/doctor_bag.png',
            titleKey: 'cat_nursing',
            id: 'nursing',
            isActive: true,
            delay: 150,
          ),
          _buildGridCard(
            context,
            imagePath: 'assets/images/doctor.png',
            titleKey: 'cat_doctor',
            id: 'doctor',
            isActive: false,
            delay: 200,
          ),
          _buildGridCard(
            context,
            imagePath: 'assets/images/medicine.png',
            titleKey: 'cat_pharmacy',
            id: 'pharmacy',
            isActive: true,
            delay: 250,
          ),
          _buildGridCard(
            context,
            imagePath: 'assets/images/add.png',
            titleKey: 'cat_ambulance',
            id: 'ambulance',
            isActive: false,
            delay: 300,
          ),
          _buildGridCard(
            context,
            imagePath: 'assets/images/xray.png',
            titleKey: 'cat_xray',
            id: 'xray',
            isActive: false,
            delay: 350,
          ),
          _buildGridCard(
            context,
            imagePath: 'assets/images/report.png',
            titleKey: 'cat_news',
            id: 'news',
            isActive: false,
            delay: 400,
          ),
          _buildGridCard(
            context,
            imagePath: 'assets/images/apps.png',
            titleKey: 'cat_more',
            id: 'more',
            isActive: false,
            delay: 450,
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard(
    BuildContext context, {
    required String imagePath,
    required String titleKey,
    required String id,
    required bool isActive,
    required int delay,
  }) {
    return GestureDetector(
      onTap: () {
        if (!isActive) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'service_unavailable_sub'.tr(),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
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
          if (id == 'lab') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AllLabsScreen(),
              ),
            );
          } else if (id == 'nursing') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NurseListScreen(),
              ),
            );
          } else if (id == 'doctor') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AllDoctorsScreen()),
            );
          } else if (id == 'pharmacy') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PharmaciesScreen()),
            );
          } else if (id == 'ambulance') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SosScreen()),
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
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Opacity(
                    opacity: isActive ? 1.0 : 0.6,
                    child: Image.asset(imagePath, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                titleKey.tr(),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: isActive
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF64748B),
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
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  'coming_soon'.tr(),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
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
