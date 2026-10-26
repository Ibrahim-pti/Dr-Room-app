import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Centralized service area configuration and map boundary for Erbil.
/// Draws the operational boundary polygon and central zone circle matching the service area.
class ErbilMapService {
  ErbilMapService._();

  /// Erbil City Center (Citadel)
  static const LatLng erbilCenter = LatLng(36.1911, 44.0092);

  /// Default Camera Position centered on Erbil with appropriate zoom
  static const CameraPosition erbilCameraPosition = CameraPosition(
    target: erbilCenter,
    zoom: 12.0,
  );

  /// Camera target bounds to restrict scrolling to Greater Erbil
  static final CameraTargetBounds erbilCameraBounds = CameraTargetBounds(
    LatLngBounds(
      southwest: const LatLng(36.0000, 43.8000),
      northeast: const LatLng(36.3800, 44.2200),
    ),
  );

  /// Boundary coordinates enclosing Greater Erbil (Baharka, Shawes, Kesnazan, Bnaslawa, 120m ring, Shamamk, Ankawa)
  static const List<LatLng> erbilBoundaryPoints = [
    LatLng(36.3150, 44.0300), // Baharka (North)
    LatLng(36.3050, 44.0600),
    LatLng(36.2750, 44.1150), // Shawes / Pirzin (North-East)
    LatLng(36.2250, 44.1350), // Kesnazan (East)
    LatLng(36.1750, 44.1150),
    LatLng(36.1350, 44.0950), // Bnaslawa (South-East)
    LatLng(36.0850, 44.0200), // South ring road towards Qushtapa
    LatLng(36.0900, 43.9650), // South-Southwest
    LatLng(36.1300, 43.9150), // Shamamk (South-West)
    LatLng(36.2000, 43.9250), // West 120m ring
    LatLng(36.2550, 43.9650), // Ankawa (North-West)
    LatLng(36.2850, 43.9850), // Girdjutyar (North of Ankawa)
    LatLng(36.3150, 44.0300), // Close loop at Baharka
  ];

  /// Get the set of Polygons representing Erbil service area
  static Set<Polygon> getErbilPolygons(bool isDark) {
    return {
      Polygon(
        polygonId: const PolygonId('erbil_service_boundary'),
        points: erbilBoundaryPoints,
        strokeColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
        strokeWidth: 3,
        fillColor: const Color(0xFF2563EB).withValues(alpha: 0.03),
      ),
    };
  }

  /// Get the set of Circles representing central Erbil zone (100m street / Citadel zone)
  static Set<Circle> getErbilCircles(bool isDark) {
    return {
      Circle(
        circleId: const CircleId('erbil_central_zone'),
        center: erbilCenter,
        radius: 5200, // 5.2 km covers central Erbil and 100m ring road
        fillColor: const Color(0xFFE07A5F).withValues(alpha: 0.18),
        strokeColor: const Color(0xFFD97706),
        strokeWidth: 2,
      ),
    };
  }

  /// Check whether a given coordinate point is inside the Erbil operational boundary
  static bool isInsideErbil(LatLng point) {
    // 1. Ray-casting point-in-polygon algorithm
    int intersectCount = 0;
    for (int j = 0; j < erbilBoundaryPoints.length - 1; j++) {
      final p1 = erbilBoundaryPoints[j];
      final p2 = erbilBoundaryPoints[j + 1];
      if ((p1.latitude > point.latitude) != (p2.latitude > point.latitude)) {
        final double slope =
            (point.latitude - p1.latitude) / (p2.latitude - p1.latitude);
        if (point.longitude < p1.longitude + slope * (p2.longitude - p1.longitude)) {
          intersectCount++;
        }
      }
    }

    if ((intersectCount % 2) == 1) {
      return true;
    }

    // 2. Fallback check: distance within 15 km of Erbil center
    final latDiff = (point.latitude - erbilCenter.latitude).abs();
    final lngDiff = (point.longitude - erbilCenter.longitude).abs();
    return latDiff <= 0.135 && lngDiff <= 0.155;
  }

  /// Show a user-friendly SnackBar when an address outside Erbil is selected
  static void showOutsideWarning(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.location_off, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'outside_erbil_warning'.tr(),
                style: const TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Floating badge showing service availability in Erbil
  static Widget buildServiceBadge(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.92) : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            'service_area_erbil_only'.tr(),
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}
