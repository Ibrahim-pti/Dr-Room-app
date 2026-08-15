import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class LabMapScreen extends StatefulWidget {
  final Map<String, dynamic> lab;

  const LabMapScreen({super.key, required this.lab});

  @override
  State<LabMapScreen> createState() => _LabMapScreenState();
}

class _LabMapScreenState extends State<LabMapScreen> {
  GoogleMapController? _mapController;
  late final double _lat;
  late final double _lng;
  late final LatLng _targetPoint;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _lat = double.tryParse(widget.lab['latitude']?.toString() ?? '') ?? 36.1911;
    _lng = double.tryParse(widget.lab['longitude']?.toString() ?? '') ?? 44.0092;
    _targetPoint = LatLng(_lat, _lng);

    final name = widget.lab['name']?.toString() ?? 'تاقیگەی پزیشکی';
    final location = widget.lab['location']?.toString() ?? 'هەولێر - شەقامی پزیشکان';

    _markers.add(
      Marker(
        markerId: MarkerId('lab_${widget.lab['id'] ?? 1}'),
        position: _targetPoint,
        infoWindow: InfoWindow(
          title: name,
          snippet: location,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  TextStyle _kStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color color = const Color(0xFF0F172A),
  }) {
    return TextStyle(
      fontFamily: 'Rabar',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  void _openExternalNavigation() async {
    final labName = Uri.encodeComponent(widget.lab['name']?.toString() ?? 'Laboratory');
    final Uri googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$_lat,$_lng');
    final Uri geoUrl = Uri.parse('geo:$_lat,$_lng?q=$_lat,$_lng($labName)');

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(geoUrl)) {
        await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching external navigation: $e');
    }
  }

  void _makePhoneCall() async {
    final rawPhone = widget.lab['phone']?.toString() ?? '07505556677';
    final cleanPhone = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri url = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error making call: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.lab['name']?.toString() ?? 'تاقیگەی پزیشکی';
    final location = widget.lab['location']?.toString() ?? 'هەولێر - شەقامی پزیشکان';
    final rating = '${widget.lab['rating'] ?? 4.8}';
    final openingHours = widget.lab['opening_hours']?.toString() ?? '08:00 AM - 10:00 PM';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // ── 1. Official Google Map ──
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _targetPoint,
              zoom: 15.5,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),

          // ── 2. Top Bar (Back & Recenter buttons) ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Color(0xFF0F172A),
                      size: 18,
                    ),
                  ),
                ),

                // Recenter Button
                GestureDetector(
                  onTap: () {
                    _mapController?.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: _targetPoint,
                          zoom: 16.0,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.gps_fixed_rounded, color: Color(0xFF3B82F6), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'شوێنی تاقیگە',
                          style: _kStyle(
                            color: const Color(0xFF0F172A),
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── 3. Zoom In / Out Buttons (Floating on Right/End) ──
          PositionedDirectional(
            end: 16,
            bottom: 230,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    _mapController?.animateCamera(CameraUpdate.zoomIn());
                  },
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: Color(0xFF0F172A), size: 20),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    _mapController?.animateCamera(CameraUpdate.zoomOut());
                  },
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.remove, color: Color(0xFF0F172A), size: 20),
                  ),
                ),
              ],
            ),
          ),

          // ── 4. Bottom Info Card Overlay ──
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lab Name & Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: _kStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 14),
                            const SizedBox(width: 3),
                            Text(
                              rating,
                              style: _kStyle(
                                color: const Color(0xFFB45309),
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Location and Hours
                  Row(
                    children: [
                      const Icon(Iconsax.location, color: Color(0xFF3B82F6), size: 15),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          location,
                          style: _kStyle(
                            color: const Color(0xFF64748B),
                            fontSize: 12.5,
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
                      const Icon(Iconsax.clock, color: Color(0xFF10B981), size: 15),
                      const SizedBox(width: 6),
                      Text(
                        openingHours,
                        style: _kStyle(
                          color: const Color(0xFF64748B),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons: Call & Google Maps Navigation
                  Row(
                    children: [
                      // Call Button
                      GestureDetector(
                        onTap: _makePhoneCall,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.2)),
                          ),
                          child: const Icon(
                            Iconsax.call,
                            color: Color(0xFF3B82F6),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Navigation Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _openExternalNavigation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Iconsax.routing, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'دەستپێکردنی ڕێنوێنی (Google Maps)',
                                style: _kStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
