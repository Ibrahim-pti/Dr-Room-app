import 'package:flutter/material.dart';
import 'package:dr_room/core/utils/api_client.dart';
import 'dart:convert';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class OrderModel {
  final String id;
  final String title;
  final String status;
  final Color statusColor;
  final IconData icon;
  final Color iconColor;
  final double price;
  final DateTime date;
  final String? assignedNurseId;
  final String? assignedNurseName;
  final String? assignedNurseAvatar;

  OrderModel({
    required this.id,
    required this.title,
    required this.status,
    required this.statusColor,
    required this.icon,
    required this.iconColor,
    required this.price,
    required this.date,
    this.assignedNurseId,
    this.assignedNurseName,
    this.assignedNurseAvatar,
  });
}

class OrderProvider extends ChangeNotifier {
  List<OrderModel> _orders = [];
  bool _isLoading = false;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;

  OrderProvider() {
    // Optionally fetch initial orders here
  }

  Future<void> fetchOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient.get('/orders');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        _orders = data.map((json) {
          return OrderModel(
            id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
            title: "${json['service_type'] ?? 'General'} Order",
            status: json['status']?.toString() ?? 'Pending',
            statusColor: _getStatusColor(json['status']?.toString() ?? 'Pending'),
            icon: Iconsax.health,
            iconColor: const Color(0xFF3B82F6),
            price: double.tryParse(json['total_price']?.toString() ?? '0') ?? 0.0,
            date: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
            assignedNurseId: json['assigned_nurse'] != null ? json['assigned_nurse']['id']?.toString() : null,
            assignedNurseName: json['assigned_nurse'] != null ? json['assigned_nurse']['name']?.toString() : null,
            assignedNurseAvatar: json['assigned_nurse'] != null ? json['assigned_nurse']['avatar']?.toString() : null,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return const Color(0xFFF59E0B);
      case 'accepted': return const Color(0xFF3B82F6);
      case 'completed': return const Color(0xFF10B981);
      case 'cancelled': return const Color(0xFFEF4444);
      default: return const Color(0xFF94A3B8);
    }
  }

  // Add order locally right away for better UX after checkout
  Future<void> addOrder(OrderModel order) async {
    _orders = [order, ..._orders];
    notifyListeners();
  }

  void updateOrderStatus(String id, String newStatus, Color newColor) {
    _orders = _orders.map((order) {
      if (order.id == id) {
        return OrderModel(
          id: order.id,
          title: order.title,
          status: newStatus,
          statusColor: newColor,
          icon: order.icon,
          iconColor: order.iconColor,
          price: order.price,
          date: order.date,
          assignedNurseId: order.assignedNurseId,
          assignedNurseName: order.assignedNurseName,
          assignedNurseAvatar: order.assignedNurseAvatar,
        );
      }
      return order;
    }).toList();
    notifyListeners();
  }
}
