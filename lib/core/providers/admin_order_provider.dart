import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../utils/api_client.dart';

class AdminOrderProvider with ChangeNotifier {
  List<dynamic> _orders = [];
  List<dynamic> _nurses = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get orders => _orders;
  List<dynamic> get nurses => _nurses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiClient.get('/admin/orders');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _orders = data['orders'] ?? [];
      } else {
        _error = 'Failed to load orders: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error connecting to server: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchNurses() async {
    try {
      final response = await ApiClient.get('/admin/nurses');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List nursesList = data is List ? data : (data['data'] ?? []);
        _nurses = nursesList
            // If you want only approved nurses, keep this. For testing, let's allow all or check if status is approved or null
            .where((n) => n['status'] == 'approved' || n['status'] == null || n['status'] == 'pending' || n['status'] == 'active')
            .toList();
        notifyListeners();
      }
    } catch (e) {
      // Ignore or handle
    }
  }

  Future<bool> assignNurse(int orderId, int nurseId) async {
    try {
      final response = await ApiClient.patch(
        '/admin/orders/$orderId/assign-nurse',
        body: {'nurse_id': nurseId},
      );

      if (response.statusCode == 200) {
        // Refresh orders
        await fetchOrders();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateStatus(int orderId, String status) async {
    try {
      final response = await ApiClient.patch(
        '/admin/orders/$orderId/status',
        body: {'status': status},
      );

      if (response.statusCode == 200) {
        await fetchOrders();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
