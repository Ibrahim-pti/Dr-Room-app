import 'package:flutter/material.dart';
import 'package:dr_room/core/utils/api_client.dart';
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

/// The statuses the API actually stores on an order, in the order a patient
/// moves through them. Anything the server sends that is not in this list is
/// treated as [OrderStatus.pending] so an unexpected value can never make an
/// order disappear from the list.
enum OrderStatus {
  pending,
  processing,
  completed,
  cancelled;

  static OrderStatus fromApi(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();
    if (value == 'processing' ||
        value == 'in_progress' ||
        value == 'approved' ||
        value == 'confirmed' ||
        value == 'accepted') {
      return OrderStatus.processing;
    }
    if (value == 'completed' || value == 'done' || value == 'delivered') {
      return OrderStatus.completed;
    }
    if (value == 'cancelled' || value == 'rejected' || value == 'canceled') {
      return OrderStatus.cancelled;
    }
    return OrderStatus.pending;
  }

  /// Translation key — every status already exists in the translation files.
  String get label => name.tr();

  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return const Color(0xFFF59E0B);
      case OrderStatus.processing:
        return const Color(0xFF3B82F6);
      case OrderStatus.completed:
        return const Color(0xFF10B981);
      case OrderStatus.cancelled:
        return const Color(0xFFEF4444);
    }
  }

  /// Whether the patient is still waiting on something. Drives the badge on
  /// the Orders tab and the polling in the details screen.
  bool get isActive =>
      this == OrderStatus.pending || this == OrderStatus.processing;
}

class OrderModel {
  final String id;

  /// Raw `service_type` from the API — 'Lab Tests', 'Nursing Services',
  /// 'pharmacy' … Kept as sent so it survives a round trip unchanged.
  final String serviceType;
  final OrderStatus status;
  final double price;
  final DateTime date;
  final String? assignedNurseId;
  final String? assignedNurseName;
  final String? assignedNurseAvatar;
  final String? assignedPharmacyName;
  final String? paymentMethod;
  final List<dynamic>? items;

  /// Set only for orders built locally right after checkout, where the item
  /// names are known and more useful than the generic service name.
  final String? customTitle;

  const OrderModel({
    required this.id,
    required this.serviceType,
    required this.status,
    required this.price,
    required this.date,
    this.assignedNurseId,
    this.assignedNurseName,
    this.assignedNurseAvatar,
    this.assignedPharmacyName,
    this.paymentMethod,
    this.items,
    this.customTitle,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final nurse = json['assigned_nurse'];
    final pharmacy = json['assigned_pharmacy'];

    return OrderModel(
      id: json['id']?.toString() ?? '',
      serviceType: json['service_type']?.toString() ?? '',
      status: OrderStatus.fromApi(json['status']?.toString()),
      price: double.tryParse(json['total_price']?.toString() ?? '') ?? 0.0,
      date: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      assignedNurseId: nurse?['id']?.toString(),
      assignedNurseName: nurse?['name']?.toString(),
      assignedNurseAvatar: nurse?['avatar']?.toString() ?? nurse?['profile_image']?.toString(),
      assignedPharmacyName: pharmacy?['name']?.toString(),
      paymentMethod: json['payment_method']?.toString(),
      items: json['items'] is List ? json['items'] : null,
    );
  }

  OrderModel copyWith({
    OrderStatus? status,
    String? assignedNurseId,
    String? assignedNurseName,
    String? assignedNurseAvatar,
    String? assignedPharmacyName,
    String? paymentMethod,
    List<dynamic>? items,
  }) {
    return OrderModel(
      id: id,
      serviceType: serviceType,
      status: status ?? this.status,
      price: price,
      date: date,
      assignedNurseId: assignedNurseId ?? this.assignedNurseId,
      assignedNurseName: assignedNurseName ?? this.assignedNurseName,
      assignedNurseAvatar: assignedNurseAvatar ?? this.assignedNurseAvatar,
      assignedPharmacyName: assignedPharmacyName ?? this.assignedPharmacyName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      items: items ?? this.items,
      customTitle: customTitle,
    );
  }

  /// Normalised service type, used to pick the icon and the translated name.
  String get _serviceKey => serviceType.toLowerCase();

  bool get _isLab => _serviceKey.contains('lab');
  bool get _isNursing => _serviceKey.contains('nurs');
  bool get _isPharmacy => _serviceKey.contains('pharmac');

  /// What the patient sees as the order's name. Falls back to the translated
  /// service name so an order is never labelled with a raw English string.
  String get title {
    if (customTitle != null && customTitle!.isNotEmpty) return customTitle!;

    if (_isLab) return 'lab_tests'.tr();
    if (_isNursing) return 'nursing_services'.tr();
    if (_isPharmacy) return 'pharmacy'.tr();

    return serviceType.isNotEmpty ? serviceType : 'general_service'.tr();
  }

  IconData get icon {
    if (_isLab) return Iconsax.d_cube_scan;
    if (_isNursing) return Iconsax.health;
    if (_isPharmacy) return Iconsax.shop;
    return Iconsax.box;
  }

  Color get iconColor {
    if (_isLab) return const Color(0xFF8B5CF6);
    if (_isNursing) return const Color(0xFF10B981);
    if (_isPharmacy) return const Color(0xFF3B82F6);
    return const Color(0xFF64748B);
  }

  Color get statusColor => status.color;
  String get statusLabel => status.label;
}

class OrderProvider extends ChangeNotifier {
  List<OrderModel> _orders = [];
  bool _isLoading = false;
  bool _hasLoadedOnce = false;
  String? _error;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// True until the first fetch completes, so the screen can tell "still
  /// starting up" apart from "loaded and genuinely empty".
  bool get hasLoadedOnce => _hasLoadedOnce;

  /// Orders the patient is still waiting on — drives the Orders tab badge.
  int get activeOrderCount =>
      _orders.where((order) => order.status.isActive).length;

  Future<void> fetchOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiClient.get('/orders');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List? ?? [];
        _orders = data
            .whereType<Map<String, dynamic>>()
            .map(OrderModel.fromJson)
            .toList();
      } else {
        _error = 'orders_load_failed'.tr();
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      _error = 'orders_load_failed'.tr();
    }

    _isLoading = false;
    _hasLoadedOnce = true;
    notifyListeners();
  }

  /// Shows the order immediately after checkout instead of waiting for the
  /// next fetch to bring it back from the server.
  Future<void> addOrder(OrderModel order) async {
    _orders = [order, ..._orders];
    notifyListeners();
  }

  void updateOrderStatus(String id, OrderStatus newStatus) {
    _orders = _orders
        .map((order) => order.id == id ? order.copyWith(status: newStatus) : order)
        .toList();
    notifyListeners();
  }

  /// Clears everything on logout so the next patient never sees the previous
  /// patient's orders.
  void clear() {
    _orders = [];
    _error = null;
    _hasLoadedOnce = false;
    notifyListeners();
  }
}
