import 'dart:convert';

import 'api_client.dart';

/// The signed-in staff member's permissions, fetched once from `/admin/me`.
/// The admin menu hides whatever the current account may not touch — the
/// backend enforces the same list, this just avoids showing dead buttons.
class AdminPermissions {
  static const manageContent = 'manage_content';
  static const manageProviders = 'manage_providers';
  static const manageOrders = 'manage_orders';
  static const manageUsers = 'manage_users';
  static const manageReviews = 'manage_reviews';
  static const manageCategories = 'manage_categories';
  static const viewPayments = 'view_payments';
  static const manageStaff = 'manage_staff';
  static const viewLogs = 'view_logs';

  static Set<String> _granted = {};
  static String? role;
  static String? roleLabel;
  static bool _loaded = false;

  static bool get isLoaded => _loaded;

  /// Call after login and on admin dashboard start.
  static Future<void> load() async {
    try {
      final res = await ApiClient.get('/admin/me');
      if (res.statusCode != 200) return;

      final data = jsonDecode(res.body);
      _granted = Set<String>.from((data['permissions'] as List?) ?? []);
      role = data['role']?.toString();
      roleLabel = data['role_label']?.toString();
      _loaded = true;
    } catch (_) {
      // Leave the cache as-is; `can` falls back to permissive below.
    }
  }

  static void clear() {
    _granted = {};
    role = null;
    roleLabel = null;
    _loaded = false;
  }

  /// Permissive until the roster has loaded, so a slow network never blanks
  /// out the menu — every request is still checked server-side.
  static bool can(String permission) => !_loaded || _granted.contains(permission);
}