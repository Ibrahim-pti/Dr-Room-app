import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/appointment_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/order_provider.dart';
import '../providers/payment_provider.dart';

/// Ends a signed-in session.
///
/// Signing out has to clear two separate places, and missing either one leaks
/// one patient's data to the next person holding the phone: the stored
/// credentials on disk, and the providers that stay alive in memory above the
/// login screen. Keeping both in one function means every exit — the logout
/// button, an expired token — clears the same things.
class SessionService {
  SessionService._();

  /// Everything written at login. Listed explicitly rather than wiping all of
  /// SharedPreferences, which also holds the chosen language and theme.
  static const List<String> _sessionKeys = [
    'auth_token',
    'user_role',
    'user_name',
    'user_phone',
    'is_admin',
  ];

  static Future<void> signOut(BuildContext context) async {
    // Memory first, and synchronously: the widget tree is torn down right
    // after this call, and an await in between would leave a frame where the
    // previous patient's data is still on screen.
    clearProviders(context);

    final prefs = await SharedPreferences.getInstance();
    for (final key in _sessionKeys) {
      await prefs.remove(key);
    }
  }

  /// Wipes every provider holding data that belongs to one patient.
  static void clearProviders(BuildContext context) {
    context.read<OrderProvider>().clear();
    context.read<AppointmentProvider>().clear();
    context.read<FavoriteProvider>().clear();
    context.read<CartProvider>().clearCart();
    context.read<PaymentProvider>().clearPaymentIntent();
  }
}
