import 'package:flutter/material.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';

/// Iraq's national ambulance / emergency line.
const String _emergencyNumber = '122';

class _Clinic {
  _Clinic({required this.name, required this.address});

  final String name;
  final String address;

  LatLng? location;
  double? distanceMeters;
  bool resolving = true;
}

class ClinicLocatorScreen extends StatefulWidget {
  const ClinicLocatorScreen({super.key});

  @override
  State<ClinicLocatorScreen> createState() => _ClinicLocatorScreenState();
}

class _ClinicLocatorScreenState extends State<ClinicLocatorScreen> {
  static const LatLng _fallbackCenter = LatLng(36.1911, 44.0092); // Erbil, Iraq

  final List<_Clinic> _clinics = [
    _Clinic(name: 'Rizgary Teaching Hospital', address: 'Rizgary Teaching Hospital, Erbil, Iraq'),
    _Clinic(name: 'West Erbil Emergency Hospital', address: 'West Erbil Emergency Hospital, Erbil, Iraq'),
    _Clinic(name: 'Dr-Room Partner Clinic', address: 'Erbil City Center, Erbil, Iraq'),
  ];

  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  GoogleMapController? _mapController;
  Position? _userPosition;
  bool _isLoadingLocation = true;
  String? _locationError;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _fetchLocation();
    await _resolveClinics();
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (mounted) {
        setState(() {
          _userPosition = position;
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(position.latitude, position.longitude), 13),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _resolveClinics() async {
    for (final clinic in _clinics) {
      try {
        final geocoder = geo.Geocoding();
        final results = await geocoder
            .locationFromAddress(clinic.address)
            .timeout(const Duration(seconds: 10));
        if (results.isNotEmpty) {
          final loc = results.first;
          clinic.location = LatLng(loc.latitude, loc.longitude);
          if (_userPosition != null) {
            clinic.distanceMeters = Geolocator.distanceBetween(
              _userPosition!.latitude,
              _userPosition!.longitude,
              loc.latitude,
              loc.longitude,
            );
          }
        }
      } catch (_) {
        // Leave unresolved; filtered out of the list/map.
      } finally {
        clinic.resolving = false;
        if (mounted) setState(() {});
      }
    }

    if (mounted) {
      setState(() {
        final resolved = _resolvedClinics;
        resolved.sort((a, b) => (a.distanceMeters ?? double.infinity).compareTo(b.distanceMeters ?? double.infinity));
      });
    }
  }

  List<_Clinic> get _resolvedClinics => _clinics.where((c) => c.location != null).toList();

  List<_Clinic> get _visibleClinics {
    final list = _resolvedClinics;
    if (_query.trim().isEmpty) return list;
    final q = _query.trim().toLowerCase();
    return list.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _callEmergency() async {
    final uri = Uri(scheme: 'tel', path: _emergencyNumber);
    try {
      await launchUrl(uri);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open dialer. Call $_emergencyNumber directly.')),
        );
      }
    }
  }

  Future<void> _openDirections(_Clinic clinic) async {
    if (clinic.location == null) return;
    final dest = '${clinic.location!.latitude},${clinic.location!.longitude}';
    final origin = _userPosition != null
        ? '${_userPosition!.latitude},${_userPosition!.longitude}'
        : null;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '${origin != null ? '&origin=$origin' : ''}'
      '&destination=$dest',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps for directions.')),
        );
      }
    }
  }

  String _formatDistance(double? meters) {
    if (meters == null) return '—';
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleClinics;
    final selected = visible.isNotEmpty ? visible[_selectedIndex.clamp(0, visible.length - 1)] : null;
    final center = _userPosition != null
        ? LatLng(_userPosition!.latitude, _userPosition!.longitude)
        : _fallbackCenter;

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──
          Positioned.fill(
            child: _isLoadingLocation
                ? Container(
                    color: const Color(0xFFF1F5F9),
                    child: const Center(child: CircularProgressIndicator()),
                  )
                : GoogleMap(
                    onMapCreated: (controller) => _mapController = controller,
                    initialCameraPosition: CameraPosition(target: center, zoom: 13),
                    myLocationEnabled: _userPosition != null,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    markers: {
                      for (int i = 0; i < visible.length; i++)
                        Marker(
                          markerId: MarkerId(visible[i].name),
                          position: visible[i].location!,
                          infoWindow: InfoWindow(title: visible[i].name, snippet: visible[i].address),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            i == _selectedIndex ? BitmapDescriptor.hueBlue : BitmapDescriptor.hueRed,
                          ),
                          onTap: () => setState(() => _selectedIndex = i),
                        ),
                    },
                  ),
          ),

          // ── Top Bar ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Iconsax.search_normal_1, color: Colors.grey, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) => setState(() {
                                _query = value;
                                _selectedIndex = 0;
                              }),
                              decoration: InputDecoration(
                                hintText: 'Search hospitals, clinics...',
                                hintStyle: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
                                border: InputBorder.none,
                                isCollapsed: true,
                              ),
                              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    backgroundColor: const Color(0xFFEF4444),
                    child: IconButton(
                      icon: const Icon(Icons.call, size: 18, color: Colors.white),
                      tooltip: 'Call $_emergencyNumber',
                      onPressed: _callEmergency,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_locationError != null)
            PositionedDirectional(
              top: 110,
              start: 20,
              end: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_off, color: Color(0xFFEF4444), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _locationError!,
                        style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF334155)),
                      ),
                    ),
                    TextButton(
                      onPressed: _fetchLocation,
                      child: Text('Retry', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),

          // ── Bottom Info Card ──
          PositionedDirectional(
            bottom: 0,
            start: 0,
            end: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: const BorderRadiusDirectional.only(
                  topStart: Radius.circular(32),
                  topEnd: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (selected == null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        _clinics.any((c) => c.resolving) ? 'Finding nearby hospitals...' : 'No hospitals found nearby',
                        style: GoogleFonts.poppins(color: AppColors.getTextSubtitle(context), fontSize: 14),
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.local_hospital, color: Color(0xFF3B82F6), size: 40),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selected.name,
                                style: GoogleFonts.poppins(
                                  color: AppColors.getTextTitle(context),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Iconsax.location, color: Colors.grey, size: 14),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${selected.address} • ${_formatDistance(selected.distanceMeters)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        color: AppColors.getTextSubtitle(context),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _callEmergency,
                            icon: const Icon(Icons.call, size: 18),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF3B82F6),
                              side: const BorderSide(color: Color(0xFF3B82F6)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            label: Text('Call $_emergencyNumber', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _openDirections(selected),
                            icon: const Icon(Icons.directions, size: 18),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            label: Text('Directions', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ).animate().slideY(begin: 1, end: 0, duration: 400.ms, curve: Curves.easeOut),
          ),
        ],
      ),
    );
  }
}
