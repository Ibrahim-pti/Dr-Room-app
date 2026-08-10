import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../locator/clinic_locator_screen.dart';

/// Iraq's national ambulance / emergency line.
const String _emergencyNumber = '122';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  bool _isTracking = false;
  int _countdown = 5;
  Timer? _timer;

  bool _isLoadingLocation = true;
  Position? _position;
  String? _locationError;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _fetchLocation();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        _timer?.cancel();
        _triggerEmergencyCall();
      }
    });
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
          _position = position;
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            16,
          ),
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

  Future<void> _triggerEmergencyCall() async {
    setState(() {
      _isTracking = true;
    });
    await _callEmergency();
  }

  Future<void> _callEmergency() async {
    final uri = Uri(scheme: 'tel', path: _emergencyNumber);
    try {
      await launchUrl(uri);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open dialer. Call $_emergencyNumber directly.'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _shareLocation() async {
    if (_position == null) {
      await _fetchLocation();
    }
    if (_position == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location is not available yet.')),
        );
      }
      return;
    }
    final lat = _position!.latitude;
    final lng = _position!.longitude;
    final mapsUrl = 'https://maps.google.com/?q=$lat,$lng';
    await SharePlus.instance.share(
      ShareParams(
        text: 'I need help. This is my current location: $mapsUrl',
        subject: 'Emergency location',
      ),
    );
  }

  void _cancelSos() {
    _timer?.cancel();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isTracking ? AppColors.getBackground(context) : const Color(0xFFEF4444),
      body: _isTracking ? _buildTrackingView() : _buildCountdownView(),
    );
  }

  Widget _buildCountdownView() {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 80)
                .animate(onPlay: (controller) => controller.repeat())
                .fade(duration: 500.ms)
                .then()
                .fade(duration: 500.ms, begin: 1, end: 0.3),
            const SizedBox(height: 32),
            Text(
              'Calling Emergency ($_emergencyNumber) in',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Center(
                child: Text(
                  '$_countdown',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ).animate(key: ValueKey(_countdown)).scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 200.ms),
            const SizedBox(height: 80),
            ElevatedButton(
              onPressed: _cancelSos,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFEF4444),
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'CANCEL',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingView() {
    final hasLocation = _position != null;
    final target = hasLocation
        ? LatLng(_position!.latitude, _position!.longitude)
        : const LatLng(36.1911, 44.0092);

    return Stack(
      children: [
        Positioned.fill(
          child: _isLoadingLocation
              ? Container(
                  color: const Color(0xFFE2E8F0),
                  child: const Center(child: CircularProgressIndicator()),
                )
              : GoogleMap(
                  onMapCreated: (controller) => _mapController = controller,
                  initialCameraPosition: CameraPosition(target: target, zoom: 16),
                  markers: hasLocation
                      ? {
                          Marker(
                            markerId: const MarkerId('me'),
                            position: target,
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                          ),
                        }
                      : {},
                  myLocationEnabled: hasLocation,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
        ),

        // Back button
        PositionedDirectional(
          top: 50,
          start: 20,
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),

        if (_locationError != null)
          PositionedDirectional(
            top: 50,
            start: 76,
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

        // Bottom Sheet Info
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
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emergency call placed',
                            style: GoogleFonts.poppins(
                              color: AppColors.getTextTitle(context),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hasLocation
                                ? 'Your live location is shown above'
                                : 'Enable location to share your position',
                            style: GoogleFonts.poppins(
                              color: AppColors.getTextSubtitle(context),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _emergencyNumber,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFEF4444),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _callEmergency,
                        icon: const Icon(Icons.call, size: 18),
                        label: Text('Call $_emergencyNumber', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _shareLocation,
                        icon: const Icon(Icons.share_location, size: 18),
                        label: Text('Share', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF3B82F6),
                          side: const BorderSide(color: Color(0xFF3B82F6)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ClinicLocatorScreen()),
                    ),
                    icon: const Icon(Iconsax.location, size: 18),
                    label: Text('Find Nearest Hospital', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ).animate().slideY(begin: 1, end: 0, duration: 400.ms, curve: Curves.easeOut),
        ),
      ],
    );
  }
}
