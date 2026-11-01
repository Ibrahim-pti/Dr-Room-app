import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medication_model.dart';
import '../models/pharmacy_model.dart';

class CartItem {
  final Medication medication;
  int quantity;
  final String unit; // 'پاکەت' or 'دانە / شریت'
  final double unitPrice;

  CartItem({
    required this.medication,
    this.quantity = 1,
    this.unit = 'پاکەت',
    double? unitPrice,
  }) : unitPrice = unitPrice ?? medication.price;

  double get totalPrice => unitPrice * quantity;

  Map<String, dynamic> toJson() => {
        'medication': medication.toJson(),
        'quantity': quantity,
        'unit': unit,
        'unit_price': unitPrice,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      medication: Medication.fromJson(Map<String, dynamic>.from(json['medication'])),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unit: json['unit']?.toString() ?? 'پاکەت',
      unitPrice: (json['unit_price'] as num?)?.toDouble(),
    );
  }
}

class CartState {
  final Pharmacy? pharmacy;
  final List<CartItem> items;

  CartState({
    this.pharmacy,
    this.items = const [],
  });

  CartState copyWith({
    Pharmacy? pharmacy,
    List<CartItem>? items,
  }) {
    return CartState(
      pharmacy: pharmacy ?? this.pharmacy,
      items: items ?? this.items,
    );
  }

  double get subtotal => items.fold(0, (sum, item) => sum + item.totalPrice);
  double get total => subtotal + (pharmacy?.deliveryFee ?? 0);
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
}

class CartNotifier extends StateNotifier<CartState> {
  static const String _storageKey = 'dr_room_pharmacy_cart_v1';

  CartNotifier() : super(CartState()) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataStr = prefs.getString(_storageKey);
      if (dataStr != null && dataStr.isNotEmpty) {
        final decoded = jsonDecode(dataStr);
        if (decoded is Map) {
          Pharmacy? pharmacy;
          if (decoded['pharmacy'] != null) {
            pharmacy = Pharmacy.fromJson(Map<String, dynamic>.from(decoded['pharmacy']));
          }
          final itemsList = <CartItem>[];
          if (decoded['items'] is List) {
            for (final raw in decoded['items']) {
              if (raw is Map) {
                itemsList.add(CartItem.fromJson(Map<String, dynamic>.from(raw)));
              }
            }
          }
          state = CartState(pharmacy: pharmacy, items: itemsList);
        }
      }
    } catch (e) {
      debugPrint('Error loading pharmacy cart: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'pharmacy': state.pharmacy?.toJson(),
        'items': state.items.map((e) => e.toJson()).toList(),
      };
      await prefs.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      debugPrint('Error saving pharmacy cart: $e');
    }
  }

  void setPharmacy(Pharmacy pharmacy) {
    if (state.pharmacy?.id != pharmacy.id) {
      // If changing pharmacy, clear cart
      state = CartState(pharmacy: pharmacy, items: []);
    } else {
      state = state.copyWith(pharmacy: pharmacy);
    }
    _saveToStorage();
  }

  void addItem(
    Medication medication,
    Pharmacy pharmacy, {
    int quantity = 1,
    String unit = 'پاکەت',
    double? unitPrice,
  }) {
    if (state.pharmacy == null || state.pharmacy?.id != pharmacy.id) {
      setPharmacy(pharmacy);
    }

    final calculatedPrice = unitPrice ?? medication.price;
    final existingIndex = state.items.indexWhere(
      (item) => item.medication.id == medication.id && item.unit == unit,
    );

    if (existingIndex >= 0) {
      final updatedItems = List<CartItem>.from(state.items);
      updatedItems[existingIndex].quantity += quantity;
      state = state.copyWith(items: updatedItems);
    } else {
      state = state.copyWith(
        items: [
          ...state.items,
          CartItem(
            medication: medication,
            quantity: quantity,
            unit: unit,
            unitPrice: calculatedPrice,
          ),
        ],
      );
    }
    _saveToStorage();
  }

  void removeItem(int medicationId, {String? unit}) {
    final updatedItems = state.items.where((item) {
      if (unit != null) {
        return !(item.medication.id == medicationId && item.unit == unit);
      }
      return item.medication.id != medicationId;
    }).toList();
    state = state.copyWith(items: updatedItems);
    _saveToStorage();
  }

  void updateQuantity(int medicationId, int quantity, {String? unit}) {
    if (quantity <= 0) {
      removeItem(medicationId, unit: unit);
      return;
    }

    final updatedItems = state.items.map((item) {
      if (item.medication.id == medicationId && (unit == null || item.unit == unit)) {
        return CartItem(
          medication: item.medication,
          quantity: quantity,
          unit: item.unit,
          unitPrice: item.unitPrice,
        );
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
    _saveToStorage();
  }

  void clearCart() {
    state = CartState(pharmacy: state.pharmacy, items: []);
    _saveToStorage();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});