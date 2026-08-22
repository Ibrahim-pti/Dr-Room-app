import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../widgets/checkout_step_indicator.dart';
import 'pharmacy_payment_screen.dart';

class PharmacyCheckoutScreen extends ConsumerStatefulWidget {
  const PharmacyCheckoutScreen({super.key});

  @override
  ConsumerState<PharmacyCheckoutScreen> createState() =>
      _PharmacyCheckoutScreenState();
}

class _PharmacyCheckoutScreenState
    extends ConsumerState<PharmacyCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String _addressText = 'هەولێر، شەقامی ٦٠ مەتری';
  bool _isLoadingLocation = true;

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
    _addressController.text = _addressText;
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _instructionsController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location disabled');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permission denied');
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      LatLng latLng = LatLng(position.latitude, position.longitude);

      _updateLocation(latLng);

      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15.0));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _addressText = 'هەولێر، شەقامی ٦٠ مەتری، نزیک فلان';
          _addressController.text = _addressText;
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _updateLocation(LatLng latLng) async {
    setState(() {
      _selectedLocation = latLng;
      _isLoadingLocation = true;
    });

    try {
      final geo.Geocoding geocoder = geo.Geocoding();
      List<geo.Placemark> placemarks = await geocoder.placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      if (placemarks.isNotEmpty) {
        geo.Placemark place = placemarks[0];
        final country = place.country ?? '';
        final locality = place.locality ?? '';
        final adminArea = place.administrativeArea ?? '';

        String formatted = 'هەولێر، شەقامی ٦٠ مەتری';
        if (country.toLowerCase().contains('united states') ||
            locality.toLowerCase().contains('mountain view') ||
            adminArea.toLowerCase().contains('california')) {
          formatted = 'هەولێر، شەقامی ٦٠ مەتری، نزیک فلان';
        } else {
          List<String> parts = [];
          if (place.street != null && place.street!.isNotEmpty && !place.street!.contains('+')) {
            parts.add(place.street!);
          }
          if (place.locality != null && place.locality!.isNotEmpty) {
            parts.add(place.locality!);
          }
          if (parts.isNotEmpty) formatted = parts.join('، ');
        }

        if (mounted) {
          setState(() {
            _addressText = formatted;
            _addressController.text = formatted;
            _isLoadingLocation = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _addressText = 'هەولێر، شەقامی ٦٠ مەتری';
          _addressController.text = _addressText;
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _proceedToPayment() {
    if (_formKey.currentState!.validate()) {
      final customAddr = _addressController.text.trim();
      final finalAddress = customAddr.isNotEmpty ? customAddr : _addressText;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PharmacyPaymentScreen(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            latitude: _selectedLocation?.latitude ?? 36.1911,
            longitude: _selectedLocation?.longitude ?? 44.0092,
            addressText: finalAddress,
            instructions: _instructionsController.text.trim(),
          ),
        ),
      );
    }
  }

  Widget _buildTextField(
    String label,
    String hint,
    IconData icon,
    TextEditingController controller, {
    bool isPhone = false,
    bool isRequired = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        style: _kStyle(
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: _kStyle(color: const Color(0xFF64748B), fontSize: 13.5),
          hintText: hint,
          hintStyle: _kStyle(color: const Color(0xFF94A3B8), fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFF3B82F6), size: 20),
          filled: true,
          fillColor: cardBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
          ),
        ),
        validator: (value) {
          if (!isRequired) return null;
          return value == null || value.trim().isEmpty ? 'تکایە ئەم بەشە پڕبکەرەوە' : null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'تەواوکردنی داواکاری',
          style: _kStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: CheckoutStepIndicator(currentStep: 1),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Iconsax.user, color: Color(0xFF3B82F6), size: 18),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'زانیاریی وەرگر',
                            style: _kStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        'ناوی تەواو',
                        'ناوی وەرگری داواکاری بنووسە',
                        Iconsax.user,
                        _nameController,
                      ),
                      _buildTextField(
                        'ژمارەی مۆبایل',
                        '0750XXXXXXX',
                        Iconsax.call,
                        _phoneController,
                        isPhone: true,
                      ),
                      _buildTextField(
                        'تێبینی یان ڕێنمایی تایبەت (ئارەزوومەندانە)',
                        'بۆ نموونە: گەیاندن دوای کاتژمێر ٥ی ئێوارە',
                        Iconsax.note_text,
                        _instructionsController,
                        isRequired: false,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Iconsax.location, color: Color(0xFF10B981), size: 18),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'ناونیشانی گەیاندن',
                            style: _kStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
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
                                _addressText,
                                style: _kStyle(fontSize: 12.5, color: const Color(0xFF475569)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                                initialCameraPosition: CameraPosition(
                                  target: _selectedLocation ?? const LatLng(36.1911, 44.0092),
                                  zoom: 15,
                                ),
                                onMapCreated: (controller) => _mapController = controller,
                                onTap: (latLng) {
                                  _updateLocation(latLng);
                                },
                                markers: _selectedLocation != null
                                    ? {
                                        Marker(
                                          markerId: const MarkerId('delivery'),
                                          position: _selectedLocation!,
                                        ),
                                      }
                                    : {},
                                myLocationEnabled: true,
                                myLocationButtonEnabled: false,
                                zoomControlsEnabled: false,
                                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                                  Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                                },
                              ),
                              Positioned(
                                right: 10,
                                bottom: 10,
                                child: FloatingActionButton.small(
                                  onPressed: _getCurrentLocation,
                                  backgroundColor: cardBg,
                                  foregroundColor: const Color(0xFF3B82F6),
                                  child: _isLoadingLocation
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.my_location, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        'ناونیشانی ورد (گەڕەک، کۆڵان، نیشانە)',
                        'نموونە: هەولێر، شەقامی ٦٠ مەتری، بەرامبەر فلان...',
                        Iconsax.building,
                        _addressController,
                        isRequired: false,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(top: BorderSide(color: borderColor)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _proceedToPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'بەردەوامبوون بۆ پارەدان',
                    style: _kStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
}