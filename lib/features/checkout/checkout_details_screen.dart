import 'package:dr_room/core/providers/cart_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
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
  String _sampleCollectionMethod = 'home'; // 'home' or 'lab'
  bool _hasSubmitted = false;

  bool _isLoadingLocation = false;
  String _locationDetails = 'no_location_selected'.tr();

  GoogleMapController? _mapController;
  LatLng? _currentLatLng;

  TextStyle _kStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color color = const Color(0xFF0F172A),
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'Rabar',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

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
            content: Text(e.toString().replaceAll('Exception: ', ''), style: _kStyle(color: Colors.white)),
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
    if (place.street != null && place.street!.isNotEmpty && !place.street!.contains('+') && !place.street!.toLowerCase().contains('unnamed')) {
      parts.add(place.street!);
    }
    if (place.subLocality != null && place.subLocality!.isNotEmpty) parts.add(place.subLocality!);
    if (place.locality != null && place.locality!.isNotEmpty) parts.add(place.locality!);
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) parts.add(place.administrativeArea!);
    if (place.country != null && place.country!.isNotEmpty) parts.add(place.country!);

    return parts.toSet().toList().join(', ');
  }

  void _submitForm() {
    setState(() {
      _hasSubmitted = true;
    });

    final isLab = context.read<CartProvider>().serviceType == 'lab';

    if (_formKey.currentState!.validate() &&
        _selectedGender != null &&
        (isLab || _selectedNurseGender != null)) {
      if (_currentLatLng == null && _sampleCollectionMethod == 'home') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('please_fetch_location_first'.tr(), style: _kStyle(color: Colors.white)),
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
        'nurse_gender': isLab ? null : _selectedNurseGender,
        'collection_method': isLab ? _sampleCollectionMethod : null,
        'location': _locationDetails,
        'lat': _currentLatLng?.latitude,
        'lng': _currentLatLng?.longitude,
      });

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PaymentMethodScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLab = context.watch<CartProvider>().serviceType == 'lab';
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                size: 16,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          isLab ? 'زانیارییەکانی داواکاری' : 'patient_details'.tr(),
          style: _kStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 17,
            fontWeight: FontWeight.bold,
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header Section ──
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            isLab ? Iconsax.health : Iconsax.user_tag,
                            color: const Color(0xFF3B82F6),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isLab ? 'زانیاری کەسی پشکنینکراو' : 'who_is_this_for'.tr(),
                                style: _kStyle(
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                isLab
                                    ? 'تکایە زانیارییەکانی کەسی پشکنینکراو پڕبکەرەوە'
                                    : 'provide_person_details'.tr(),
                                style: _kStyle(
                                  color: const Color(0xFF64748B),
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ).animate().fadeIn().slideX(begin: -0.05, end: 0),

                    const SizedBox(height: 20),

                    // ── Person Info Box ──
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name Field
                          _buildTextField(
                            label: isLab ? 'ناوی سیانی' : 'patient_name'.tr(),
                            controller: _nameController,
                            icon: Iconsax.user,
                            hint: isLab ? 'ناوی سیانی بنووسە' : 'e.g. John Doe',
                          ),
                          const SizedBox(height: 18),

                          // Gender Selector
                          _buildGenderSelector(
                            title: 'ڕەگەز',
                            selectedValue: _selectedGender,
                            onChanged: (val) {
                              setState(() => _selectedGender = val);
                            },
                          ),

                          // If nursing service, show nurse gender preference
                          if (!isLab) ...[
                            const SizedBox(height: 18),
                            _buildGenderSelector(
                              title: 'nurse_gender_preference'.tr(),
                              selectedValue: _selectedNurseGender,
                              onChanged: (val) {
                                setState(() => _selectedNurseGender = val);
                              },
                            ),
                          ],

                          // If Lab service, show sample collection preference
                          if (isLab) ...[
                            const SizedBox(height: 18),
                            _buildSampleCollectionSelector(),
                          ],

                          const SizedBox(height: 18),

                          // Age & Phone Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildTextField(
                                  label: 'age'.tr(),
                                  controller: _ageController,
                                  icon: Iconsax.calendar_1,
                                  hint: '٣٠',
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                flex: 5,
                                child: _buildTextField(
                                  label: 'phone_number'.tr(),
                                  controller: _phoneController,
                                  icon: Iconsax.call,
                                  hint: '0750 000 0000',
                                  keyboardType: TextInputType.phone,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.05, end: 0),

                    const SizedBox(height: 24),

                    // ── Location Section (Only if home collection or general) ──
                    if (!isLab || _sampleCollectionMethod == 'home') ...[
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Iconsax.location,
                              color: Color(0xFF10B981),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isLab ? 'ناونیشانی وەرگرتنی نموونە' : 'service_location'.tr(),
                            style: _kStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 250.ms).slideX(begin: -0.05, end: 0),

                      const SizedBox(height: 12),

                      // Location text badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            const Icon(Iconsax.map, color: Color(0xFF3B82F6), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _locationDetails,
                                style: _kStyle(fontSize: 12.5, color: const Color(0xFF475569)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // The Map Container
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              GoogleMap(
                                onMapCreated: (controller) {
                                  _mapController = controller;
                                },
                                initialCameraPosition: CameraPosition(
                                  target: _currentLatLng ?? const LatLng(36.1911, 44.0092),
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
                                          markerId: const MarkerId('selected_location'),
                                          position: _currentLatLng!,
                                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                                        ),
                                      }
                                    : {},
                                myLocationEnabled: true,
                                myLocationButtonEnabled: false,
                                zoomControlsEnabled: true,
                                mapToolbarEnabled: true,
                                padding: const EdgeInsets.only(bottom: 20, right: 10),
                                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                                  Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                                },
                              ),
                              // Floating map controls
                              Positioned(
                                right: 10,
                                bottom: 16,
                                child: InkWell(
                                  onTap: _getCurrentLocation,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: cardBg,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: _isLoadingLocation
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(
                                            Icons.my_location,
                                            size: 18,
                                            color: Color(0xFF3B82F6),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05, end: 0),
                    ],

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // ── Bottom Container ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(top: BorderSide(color: borderColor)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'بەردەوامبوون بۆ شێوازی پارەدان',
                      style: _kStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
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

  Widget _buildSampleCollectionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'شێوازی وەرگرتنی نموونە',
          style: _kStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildCollectionOption(
                label: 'لە ماڵەوە',
                icon: Icons.home_rounded,
                isSelected: _sampleCollectionMethod == 'home',
                onTap: () => setState(() => _sampleCollectionMethod = 'home'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCollectionOption(
                label: 'سەردانی تاقیگە',
                icon: Icons.local_hospital_rounded,
                isSelected: _sampleCollectionMethod == 'lab',
                onTap: () => setState(() => _sampleCollectionMethod = 'lab'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCollectionOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF64748B),
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: _kStyle(
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF334155),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
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
          style: _kStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: _kStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
          autovalidateMode: _hasSubmitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          validator: (value) => value == null || value.isEmpty ? 'تکایە ئەم بەشە پڕبکەرەوە' : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: _kStyle(
              color: const Color(0xFF94A3B8),
              fontSize: 13,
            ),
            prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 18),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
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
          style: _kStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildGenderOption(
                label: 'نێر',
                icon: Iconsax.man,
                isSelected: selectedValue == 'male',
                onTap: () => onChanged('male'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGenderOption(
                label: 'مێ',
                icon: Iconsax.woman,
                isSelected: selectedValue == 'female',
                onTap: () => onChanged('female'),
              ),
            ),
          ],
        ),
        if (showError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'تکایە ڕەگەز دیاری بکە',
              style: _kStyle(
                color: const Color(0xFFEF4444),
                fontSize: 11.5,
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF64748B),
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: _kStyle(
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF334155),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
