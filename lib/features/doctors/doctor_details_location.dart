import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/dr_room_fonts.dart';
import 'doctor_details_widgets.dart';

/// Location section: Google Maps lite preview + clinic info + open in maps.
class DoctorDetailsLocation extends StatelessWidget {
  final bool isDark;
  final int doctorId;
  final String clinicName;
  final String address;
  final double? latitude;
  final double? longitude;
  final VoidCallback onOpenInMaps;

  const DoctorDetailsLocation({
    super.key,
    required this.isDark,
    required this.doctorId,
    required this.clinicName,
    required this.address,
    this.latitude,
    this.longitude,
    required this.onOpenInMaps,
  });

  bool get _hasLocation => latitude != null && longitude != null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DoctorDetailsSectionHeader(
          icon: Iconsax.location,
          title: 'dd_location'.tr(),
        ),
        const SizedBox(height: 10),
        DoctorDetailsCard(
          isDark: isDark,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_hasLocation)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(21),
                  ),
                  child: SizedBox(
                    height: 170,
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(latitude!, longitude!),
                            zoom: 15,
                          ),
                          markers: {
                            Marker(
                              markerId: MarkerId('doctor-$doctorId'),
                              position: LatLng(latitude!, longitude!),
                            ),
                          },
                          zoomControlsEnabled: false,
                          myLocationButtonEnabled: false,
                          liteModeEnabled:
                              true, // static preview, cheap to draw
                        ),
                        // Lite mode swallows taps, so the whole preview opens
                        // the real maps app instead.
                        Positioned.fill(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(onTap: onOpenInMaps),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (clinicName.isNotEmpty)
                            Text(
                              clinicName,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.getTextTitle(context),
                              ),
                            ),
                          if (clinicName.isNotEmpty && address.isNotEmpty)
                            const SizedBox(height: 3),
                          Text(
                            address.isNotEmpty ? address : 'dd_no_address'.tr(),
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              height: 1.6,
                              color: address.isNotEmpty
                                  ? AppColors.getTextSubtitle(context)
                                  : AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_hasLocation) ...[
                      const SizedBox(width: 10),
                      TextButton.icon(
                        onPressed: onOpenInMaps,
                        icon: const Icon(Iconsax.direct_right, size: 16),
                        label: Text(
                          'dd_open_maps'.tr(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
