import 'package:dr_room/core/providers/cart_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart';
import '../../core/theme/app_colors.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'payment_method_screen.dart';

class CheckoutDetailsScreen extends StatefulWidget {
  const CheckoutDetailsScreen({super.key});

  @override
  State<CheckoutDetailsScreen> createState() => _CheckoutDetailsScreenState();
}

class _CheckoutDetailsScreenState extends State<CheckoutDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _selectedGender;
  String? _selectedNurseGender;
  bool _hasSubmitted = false;

  bool _isLoadingLocation = false;
  String _locationDetails = 'no_location_selected'.tr();

  GoogleMapController? _mapController;
  LatLng? _currentLatLng;

  @override
  void initState() {
    super.initState();
    // Auto fetch location on screen load
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        throw Exception('Please enable location services to continue.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        throw Exception('Location permissions are permanently denied');
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (mounted) {
        setState(() {
          _currentLatLng = LatLng(position.latitude, position.longitude);
        });
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _currentLatLng!, zoom: 15.0),
          ),
        );
      }

      try {
        final geo.Geocoding geocoder = geo.Geocoding();
        List<geo.Placemark> placemarks = await geocoder
            .placemarkFromCoordinates(position.latitude, position.longitude)
            .timeout(const Duration(seconds: 10));

        if (placemarks.isNotEmpty) {
          geo.Placemark place = placemarks[0];
          if (mounted) {
            setState(() {
              _locationDetails = _formatAddress(place);
            });
          }
        }
      } catch (e) {
        // Geocoding often fails on iOS simulators
        if (mounted) {
          setState(() {
            _locationDetails =
                'Location (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _updateAddressFromLatLng(LatLng point) async {
    try {
      final geo.Geocoding geocoder = geo.Geocoding();
      List<geo.Placemark> placemarks = await geocoder
          .placemarkFromCoordinates(point.latitude, point.longitude)
          .timeout(const Duration(seconds: 10));

      if (placemarks.isNotEmpty) {
        geo.Placemark place = placemarks[0];
        if (mounted) {
          setState(() {
            _locationDetails = _formatAddress(place);
          });
        }
      }
    } catch (e) {
      // Handle error gracefully if reverse geocoding fails
      if (mounted) {
        setState(() {
          _locationDetails =
              'Location (${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)})';
        });
      }
    }
  }

  String _formatAddress(geo.Placemark place) {
    List<String> parts = [];
    
    // Ignore Plus Codes (which contain '+') or generic unnamed roads
    if (place.street != null && place.street!.isNotEmpty && !place.street!.contains('+') && !place.street!.toLowerCase().contains('unnamed')) {
      parts.add(place.street!);
    }
    
    if (place.subLocality != null && place.subLocality!.isNotEmpty) parts.add(place.subLocality!);
    if (place.locality != null && place.locality!.isNotEmpty) parts.add(place.locality!);
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) parts.add(place.administrativeArea!);
    if (place.country != null && place.country!.isNotEmpty) parts.add(place.country!);

    // Remove duplicates (e.g. "Erbil, Erbil")
    return parts.toSet().toList().join(', ');
  }

  void _submitForm() {
    setState(() {
      _hasSubmitted = true;
    });

    if (_formKey.currentState!.validate() &&
        _selectedGender != null &&
        _selectedNurseGender != null) {
      if (_currentLatLng == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('please_fetch_location_first'.tr()),
            backgroundColor: const Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }
      // Save details to CartProvider
      context.read<CartProvider>().setPatientDetails({
        'name': _nameController.text.trim(),
        'age': _ageController.text.trim(),
        'phone': _phoneController.text.trim(),
        'patient_gender': _selectedGender,
        'nurse_gender': _selectedNurseGender,
        'location': _locationDetails,
        'lat': _currentLatLng!.latitude,
        'lng': _currentLatLng!.longitude,
      });

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PaymentMethodScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.getTextTitle(context),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'patient_details'.tr(),
          style: GoogleFonts.poppins(
            color: AppColors.getTextTitle(context),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header Section ──
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Iconsax.user_tag_copy,
                            color: Color(0xFF3B82F6),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'who_is_this_for'.tr(),
                                style: GoogleFonts.poppins(
                                  color: AppColors.getTextTitle(context),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'provide_person_details'.tr(),
                                style: GoogleFonts.poppins(
                                  color: AppColors.getTextSubtitle(context),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ).animate().fadeIn().slideX(begin: -0.05, end: 0),

                    const SizedBox(height: 32),

                    // ── Patient Info Box ──
                    Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.getSurface(context),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildTextField(
                                label: 'patient_name'.tr(),
                                controller: _nameController,
                                icon: Iconsax.user_copy,
                                hint: 'e.g. John Doe',
                              ),
                              const SizedBox(height: 20),
                              _buildGenderSelector(
                                title: 'patient_gender'.tr(),
                                selectedValue: _selectedGender,
                                onChanged: (val) {
                                  setState(() => _selectedGender = val);
                                },
                              ),
                              const SizedBox(height: 20),
                              _buildGenderSelector(
                                title: 'nurse_gender_preference'.tr(),
                                selectedValue: _selectedNurseGender,
                                onChanged: (val) {
                                  setState(() => _selectedNurseGender = val);
                                },
                              ),
                              const SizedBox(height: 20),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _buildTextField(
                                      label: 'age'.tr(),
                                      controller: _ageController,
                                      icon: Iconsax.calendar_1_copy,
                                      hint: 'e.g. 30',
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 5,
                                    child: _buildTextField(
                                      label: 'phone_number'.tr(),
                                      controller: _phoneController,
                                      icon: Iconsax.call_copy,
                                      hint: '+964 750 ...',
                                      keyboardType: TextInputType.phone,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 150.ms)
                        .slideY(begin: 0.05, end: 0),

                    const SizedBox(height: 36),

                    // ── Location Section ──
                    Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Iconsax.location_copy,
                                color: Color(0xFF10B981),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'service_location'.tr(),
                              style: GoogleFonts.poppins(
                                color: AppColors.getTextTitle(context),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                        .animate()
                        .fadeIn(delay: 250.ms)
                        .slideX(begin: -0.05, end: 0),

                    const SizedBox(height: 16),

                    // The Map Container
                    Container(
                      height: 240,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          children: [
                            GoogleMap(
                              onMapCreated: (controller) {
                                _mapController = controller;
                              },
                              initialCameraPosition: CameraPosition(
                                target:
                                    _currentLatLng ??
                                    const LatLng(36.1911, 44.0092),
                                zoom: 15.0,
                              ),
                              onCameraIdle: () {
                                if (_currentLatLng != null) {
                                  _updateAddressFromLatLng(_currentLatLng!);
                                }
                              },
                              onTap: (LatLng location) {
                                setState(() {
                                  _currentLatLng = location;
                                });
                                _updateAddressFromLatLng(location);
                              },
                              markers: _currentLatLng != null
                                  ? {
                                      Marker(
                                        markerId: const MarkerId(
                                          'selected_location',
                                        ),
                                        position: _currentLatLng!,
                                        icon:
                                            BitmapDescriptor.defaultMarkerWithHue(
                                              BitmapDescriptor.hueRed,
                                            ),
                                      ),
                                    }
                                  : {},
                              myLocationEnabled: true,
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: true,
                              mapToolbarEnabled: true,
                              padding: const EdgeInsets.only(
                                bottom: 24,
                                right: 12,
                              ),
                              gestureRecognizers:
                                  <Factory<OneSequenceGestureRecognizer>>{
                                    Factory<OneSequenceGestureRecognizer>(
                                      () => EagerGestureRecognizer(),
                                    ),
                                  },
                            ),
                            // Floating map controls
                            Positioned(
                              right: 12,
                              bottom: 24,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: _getCurrentLocation,
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.getSurface(context),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: _isLoadingLocation
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.my_location,
                                              size: 20,
                                              color: Color(0xFF3B82F6),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.05, end: 0),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // ── Bottom Container ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 4,
                      shadowColor: const Color(0xFF3B82F6).withOpacity(0.4),
                    ),
                    child: Text(
                      'continue_to_payment'.tr(),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: AppColors.getTextTitle(context),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.poppins(
            color: AppColors.getTextTitle(context),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          autovalidateMode: _hasSubmitted
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          validator: (value) =>
              value == null || value.isEmpty ? 'required'.tr() : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: AppColors.textLight.withOpacity(0.6),
              fontSize: 14,
            ),
            prefixIcon: Icon(icon, color: AppColors.textLight, size: 20),
            filled: true,
            fillColor: AppColors.getBackground(context),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 20,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppColors.getBorder(context).withOpacity(0.5),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF3B82F6),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector({
    required String title,
    required String? selectedValue,
    required void Function(String) onChanged,
  }) {
    bool showError = _hasSubmitted && selectedValue == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            color: AppColors.getTextTitle(context),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildGenderOption(
                label: 'male'.tr(),
                icon: Iconsax.man_copy,
                isSelected: selectedValue == 'male',
                onTap: () => onChanged('male'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGenderOption(
                label: 'female'.tr(),
                icon: Iconsax.woman_copy,
                isSelected: selectedValue == 'female',
                onTap: () => onChanged('female'),
              ),
            ),
          ],
        ),
        if (showError)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              'required'.tr(),
              style: GoogleFonts.poppins(
                color: const Color(0xFFEF4444),
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGenderOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3B82F6).withOpacity(0.1)
              : AppColors.getBackground(context),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3B82F6)
                : AppColors.getBorder(context).withOpacity(0.5),
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF3B82F6) : AppColors.textLight,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected
                    ? const Color(0xFF3B82F6)
                    : AppColors.getTextTitle(context),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
