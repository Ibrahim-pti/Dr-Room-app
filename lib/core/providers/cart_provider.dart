import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/service_fee_service.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final Map<String, dynamic>? extraData;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.extraData,
  });

  double get totalPrice => price * quantity;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'quantity': quantity,
        'extra_data': extraData,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      extraData: json['extra_data'] is Map<String, dynamic>
          ? json['extra_data'] as Map<String, dynamic>
          : (json['extra_data'] is Map
              ? Map<String, dynamic>.from(json['extra_data'])
              : null),
    );
  }
}

class CartProvider extends ChangeNotifier {
  static const String _storageKey = 'dr_room_core_cart_items_v1';
  static const String _serviceTypeKey = 'dr_room_core_cart_service_type_v1';
  static const String _extraFeeKey = 'dr_room_core_cart_extra_fee_v1';

  String? _serviceType; // 'lab', 'pharmacy', 'nursing'
  final List<CartItem> _items = [];
  double _extraFee = 0.0;

  // Patient details stored temporarily during checkout
  Map<String, dynamic>? _patientDetails;

  CartProvider() {
    _loadFromStorage();
    ServiceFeeService.instance.addListener(notifyListeners);
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final itemsStr = prefs.getString(_storageKey);
      _serviceType = prefs.getString(_serviceTypeKey);
      _extraFee = prefs.getDouble(_extraFeeKey) ?? 0.0;

      if (itemsStr != null && itemsStr.isNotEmpty) {
        final decoded = jsonDecode(itemsStr);
        if (decoded is List) {
          _items.clear();
          for (final raw in decoded) {
            if (raw is Map) {
              _items.add(CartItem.fromJson(Map<String, dynamic>.from(raw)));
            }
          }
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading cart from storage: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _items.map((e) => e.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(data));
      if (_serviceType != null) {
        await prefs.setString(_serviceTypeKey, _serviceType!);
      } else {
        await prefs.remove(_serviceTypeKey);
      }
      await prefs.setDouble(_extraFeeKey, _extraFee);
    } catch (e) {
      debugPrint('Error saving cart to storage: $e');
    }
  }

  String? get serviceType => _serviceType;
  List<CartItem> get items => _items;
  double get extraFee => _extraFee;
  Map<String, dynamic>? get patientDetails => _patientDetails;

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  String get effectiveServiceType {
    if (_serviceType != null && _serviceType!.trim().isNotEmpty) {
      final st = _serviceType!.toLowerCase();
      if (st.contains('lab')) return 'lab';
      if (st.contains('nurs')) return 'nursing';
      if (st.contains('pharm')) return 'pharmacy';
      return _serviceType!;
    }
    final hasLab = _items.any((i) =>
        i.extraData?['type'] == 'test' ||
        i.extraData?['type'] == 'package' ||
        i.extraData?['lab_id'] != null ||
        i.extraData?['lab_name'] != null);
    final hasNursing = _items.any((i) =>
        i.extraData?['type'] == 'nursing_service' ||
        i.extraData?['nurse_id'] != null ||
        i.id.startsWith('nurse_'));
    if (hasLab && !hasNursing) return 'lab';
    if (hasNursing && !hasLab) return 'nursing';
    return hasLab ? 'lab' : (hasNursing ? 'nursing' : 'lab');
  }

  double get subtotal {
    return _items.fold(0, (total, item) => total + (item.price * item.quantity));
  }

  double get serviceFee => _items.isEmpty ? 0.0 : ServiceFeeService.instance.currentFee;

  double get total => subtotal + _extraFee + serviceFee;

  void setServiceType(String type, {double extraFee = 0.0}) {
    _serviceType = type;
    _extraFee = extraFee;
    notifyListeners();
    _saveToStorage();
  }

  void addItem(CartItem item) {
    // If the item already exists, increase quantity
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index >= 0) {
      _items[index] = CartItem(
        id: item.id,
        name: item.name,
        price: item.price,
        quantity: _items[index].quantity + item.quantity,
        extraData: item.extraData,
      );
    } else {
      _items.add(item);
    }
    notifyListeners();
    _saveToStorage();
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
    _saveToStorage();
  }

  int getItemQuantity(String id) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      return _items[index].quantity;
    }
    return 0;
  }

  void updateQuantity(String id, int quantity) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index] = CartItem(
          id: _items[index].id,
          name: _items[index].name,
          price: _items[index].price,
          quantity: quantity,
          extraData: _items[index].extraData,
        );
      }
      notifyListeners();
      _saveToStorage();
    }
  }

  void decrementItem(String id) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index] = CartItem(
          id: _items[index].id,
          name: _items[index].name,
          price: _items[index].price,
          quantity: _items[index].quantity - 1,
          extraData: _items[index].extraData,
        );
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
      _saveToStorage();
    }
  }

  void setPatientDetails(Map<String, dynamic> details) {
    _patientDetails = details;
    notifyListeners();
  }

  void clearCart() {
    _serviceType = null;
    _items.clear();
    _extraFee = 0.0;
    _patientDetails = null;
    notifyListeners();
    _saveToStorage();
  }
}