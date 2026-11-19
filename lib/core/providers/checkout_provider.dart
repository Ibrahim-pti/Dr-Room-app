import 'package:flutter/material.dart';
import 'package:dr_room/core/utils/api_client.dart';
import 'dart:convert';
import 'cart_provider.dart';

class CheckoutProvider extends ChangeNotifier {
  String _selectedPaymentMethod = 'Cash on Delivery';
  bool _isProcessing = false;
  String? _lastError;

  String get selectedPaymentMethod => _selectedPaymentMethod;
  bool get isProcessing => _isProcessing;
  String? get lastError => _lastError;

  void selectPaymentMethod(String method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  Future<String?> processPayment(
    CartProvider cart, {
    String? transactionReference,
    String? couponCode,
    double discountAmount = 0.0,
  }) async {
    _isProcessing = true;
    _lastError = null;
    notifyListeners();

    try {
      // Extract prescription image/url from patientDetails or cart items
      String? prescriptionUrl = cart.patientDetails?['prescription_url']?.toString() ??
          cart.patientDetails?['prescription_image']?.toString();
      String? prescriptionPath = cart.patientDetails?['prescription_path']?.toString();

      if (prescriptionUrl == null || prescriptionUrl.isEmpty) {
        for (final item in cart.items) {
          final pUrl = item.extraData?['prescription_url'] ?? item.extraData?['prescription_image'];
          final pPath = item.extraData?['prescription_path'];
          if (pUrl != null && pUrl.toString().isNotEmpty) {
            prescriptionUrl = pUrl.toString();
          }
          if (pPath != null && pPath.toString().isNotEmpty) {
            prescriptionPath = pPath.toString();
          }
        }
      }

      final patientDetails = Map<String, dynamic>.from(cart.patientDetails ?? {});
      if (prescriptionUrl != null && prescriptionUrl.isNotEmpty) {
        patientDetails['prescription_url'] = prescriptionUrl;
        patientDetails['prescription_image'] = prescriptionUrl;
        patientDetails['is_prescription'] = true;
      }
      if (prescriptionPath != null && prescriptionPath.isNotEmpty) {
        patientDetails['prescription_path'] = prescriptionPath;
      }

      final effectiveTotal = (cart.total - discountAmount) < 0.0 ? 0.0 : (cart.total - discountAmount);

      final Map<String, dynamic> payload = {
        'service_type': cart.serviceType ?? 'General',
        'subtotal': cart.subtotal,
        'extra_fee': cart.extraFee,
        'service_fee': cart.serviceFee,
        'coupon_code': couponCode,
        'discount_amount': discountAmount,
        'total_price': effectiveTotal,
        'payment_method': _selectedPaymentMethod,
        'transaction_reference': transactionReference,
        'payment_status': transactionReference != null ? 'paid' : 'pending',
        if (patientDetails['scheduled_at'] != null)
          'scheduled_at': patientDetails['scheduled_at'],
        'patient_details': patientDetails,
        if (patientDetails['lat'] != null ||
            patientDetails['latitude'] != null ||
            patientDetails['location'] != null ||
            patientDetails['address'] != null)
          'location_details': {
            if (patientDetails['lat'] != null) 'latitude': patientDetails['lat'],
            if (patientDetails['lng'] != null) 'longitude': patientDetails['lng'],
            if (patientDetails['latitude'] != null) 'latitude': patientDetails['latitude'],
            if (patientDetails['longitude'] != null) 'longitude': patientDetails['longitude'],
            if (patientDetails['location'] != null) 'address': patientDetails['location'],
            if (patientDetails['address'] != null) 'address': patientDetails['address'],
          },
        'items': cart.items.map((e) => e.toJson()).toList(),
      };

      if (prescriptionUrl != null && prescriptionUrl.isNotEmpty) {
        payload['prescription_url'] = prescriptionUrl;
        payload['prescription_image'] = prescriptionUrl;
      }
      if (prescriptionPath != null && prescriptionPath.isNotEmpty) {
        payload['prescription_path'] = prescriptionPath;
      }

      final response = await ApiClient.post('/orders', body: payload);
      
      _isProcessing = false;
      notifyListeners();

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['order']?['id']?.toString();
      } else {
        try {
          final err = jsonDecode(response.body);
          if (err is Map && err['message'] != null) {
            _lastError = err['message'].toString();
          }
        } catch (_) {}
        _lastError ??= 'کێشە لە تۆمارکردنی داواکاری ڕوویدا (${response.statusCode})';
        debugPrint('Checkout Failed: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Checkout Error: $e');
      _lastError = '$e';
      _isProcessing = false;
      notifyListeners();
      return null;
    }
  }
}