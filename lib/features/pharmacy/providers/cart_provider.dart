import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medication_model.dart';
import '../models/pharmacy_model.dart';

class CartItem {
  final Medication medication;
  int quantity;

  CartItem({
    required this.medication,
    this.quantity = 1,
  });

  double get totalPrice => medication.price * quantity;
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
  CartNotifier() : super(CartState());

  void setPharmacy(Pharmacy pharmacy) {
    if (state.pharmacy?.id != pharmacy.id) {
      // If changing pharmacy, clear cart
      state = CartState(pharmacy: pharmacy, items: []);
    } else {
      state = state.copyWith(pharmacy: pharmacy);
    }
  }

  void addItem(Medication medication, Pharmacy pharmacy) {
    if (state.pharmacy == null || state.pharmacy?.id != pharmacy.id) {
      setPharmacy(pharmacy);
    }

    final existingIndex = state.items.indexWhere((item) => item.medication.id == medication.id);

    if (existingIndex >= 0) {
      final updatedItems = List<CartItem>.from(state.items);
      updatedItems[existingIndex].quantity++;
      state = state.copyWith(items: updatedItems);
    } else {
      state = state.copyWith(items: [...state.items, CartItem(medication: medication)]);
    }
  }

  void removeItem(int medicationId) {
    final updatedItems = state.items.where((item) => item.medication.id != medicationId).toList();
    state = state.copyWith(items: updatedItems);
  }

  void updateQuantity(int medicationId, int quantity) {
    if (quantity <= 0) {
      removeItem(medicationId);
      return;
    }

    final updatedItems = state.items.map((item) {
      if (item.medication.id == medicationId) {
        return CartItem(medication: item.medication, quantity: quantity);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  void clearCart() {
    state = CartState(pharmacy: state.pharmacy, items: []);
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
