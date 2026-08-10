import 'package:dr_room/core/utils/api_client.dart';
import 'package:flutter/material.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/favorite_provider.dart';
import 'doctor_details_screen.dart';

class FavoriteDoctorsScreen extends StatelessWidget {
  const FavoriteDoctorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'favorite_doctors'.tr(),
          style: GoogleFonts.poppins(
            color: AppColors.getTextTitle(context),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.getTextTitle(context),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<FavoriteProvider>(
        builder: (context, favoriteProvider, child) {
          final favorites = favoriteProvider.favoriteDoctors;

          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Iconsax.heart_slash,
                      size: 48,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'no_favorites_yet'.tr(),
                    style: GoogleFonts.poppins(
                      color: AppColors.getTextTitle(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'favorite_doctors_desc'.tr(),
                    style: GoogleFonts.poppins(
                      color: AppColors.textLight,
                      fontSize: 14,
                    ),
                  ),
                ],
              ).animate().fadeIn().slideY(begin: 0.2, end: 0),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final doctor = favorites[index];
              final name = doctor['user'] != null
                  ? doctor['user']['name']
                  : (doctor['doctor'] ?? doctor['name'] ?? 'Doctor');
              final specialty = doctor['specialty'] ?? '';
              final image = doctor['image_path'] != null
                  ? ApiClient.getImageUrl(doctor['image_path'])
                  : (doctor['image'] ?? 'assets/images/doctor.png');

              return Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 16),
                child:
                    GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DoctorDetailsScreen(
                                  doctorId: doctor['id'] ?? 1,
                                  name: name,
                                  specialty: specialty,
                                  image: image,
                                  initialDoctor: Map<String, dynamic>.from(
                                    doctor,
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.getSurface(context),
                              borderRadius: BorderRadius.circular(20),
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
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: image.startsWith('http')
                                          ? NetworkImage(image)
                                          : AssetImage(image) as ImageProvider,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: GoogleFonts.poppins(
                                          color: AppColors.getTextTitle(
                                            context,
                                          ),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        specialty,
                                        style: GoogleFonts.poppins(
                                          color: AppColors.textLight,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.favorite,
                                    color: Color(0xFFEF4444),
                                  ),
                                  onPressed: () {
                                    favoriteProvider.toggleFavorite(doctor);
                                  },
                                ),
                              ],
                            ),
                          ),
                        )
                        .animate(delay: (100 * index).ms)
                        .fadeIn()
                        .slideY(begin: 0.1, end: 0),
              );
            },
          );
        },
      ),
    );
  }
}
