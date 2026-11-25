import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/appointment_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/order_provider.dart';
import '../providers/payment_provider.dart';
import '../utils/admin_permissions.dart';
import '../utils/api_client.dart';
import 'push_notification_service.dart';

/// Ends a signed-in session cleanly across memory, local storage, and push token registration.
class SessionService {
  SessionService._();

  static const List<String> _sessionKeys = [
    'auth_token',
    'user_role',
    'user_name',
    'user_phone',
    'user_profile_image',
    'profile_image',
    'user_dob',
    'saved_user_addresses',
    'submitted_feedback_survey_ids_v1',
    'dr_room_pharmacy_cart_v1',
    'user_health_gender',
    'user_health_blood_type',
    'user_health_age',
    'payment_methods',
    'transactions',
    'is_admin',
    'ai_medicine_scans',
  ];

  static Future<void> signOut(BuildContext context) async {
    clearProviders(context);
    AdminPermissions.clear();

    try {
      final token = PushNotificationService.instance.currentToken;
      if (token != null && token.isNotEmpty) {
        await ApiClient.delete('/device-tokens');
      }
    } catch (_) {}

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
    AdminPermissions.clear();
  }
}
