import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

/// Thrown when the server rejects the stored token. Callers that want to react
/// (rather than just show an error) can catch this specifically.
class UnauthorizedException implements Exception {
  final String message;
  const UnauthorizedException([this.message = 'Session expired']);

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();

  static String get baseUrl => AppConfig.baseUrl;
  static String get storageUrl => AppConfig.storageUrl;

  static String getImageUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    
    final origin = AppConfig.baseUrl.replaceAll(RegExp(r'/api/?$'), '');
    final cleanPath = path.startsWith('/') ? path : '/$path';
    // Handle the case where path already contains /storage
    if (cleanPath.startsWith('/storage')) {
        return '$origin$cleanPath';
    }
    return '$origin/storage$cleanPath';
  }

  /// Invoked when any request comes back 401 so the app can clear its session
  /// and send the user back to login. Wired up in main().
  static void Function()? onUnauthorized;

  /// Cached [SharedPreferences] instance — avoids the async overhead of
  /// [SharedPreferences.getInstance] on every single API call.
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await _getPrefs();
    final token = prefs.getString('auth_token');

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Runs [request], enforcing the shared timeout and handling token expiry.
  ///
  /// On 401 the stored credentials are cleared and [onUnauthorized] fires
  /// before the exception propagates, so a stale token can't leave the app in
  /// a state where every subsequent call silently fails.
  static Future<http.Response> _send(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    final headers = await _getHeaders();
    final response = await request(headers).timeout(
      AppConfig.requestTimeout,
      onTimeout: () => throw TimeoutException(
        'The server took too long to respond.',
        AppConfig.requestTimeout,
      ),
    );

    if (response.statusCode == 401) {
      await _clearSession();
      onUnauthorized?.call();
      throw const UnauthorizedException();
    }

    return response;
  }

  static Future<void> _clearSession() async {
    final prefs = await _getPrefs();
    await prefs.remove('auth_token');
    await prefs.remove('user_role');
  }

  static Uri _uri(String endpoint) => Uri.parse('$baseUrl$endpoint');

  static Future<http.Response> get(String endpoint) =>
      _send((headers) => http.get(_uri(endpoint), headers: headers));

  static Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) =>
      _send((headers) => http.post(
            _uri(endpoint),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          ));

  static Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) =>
      _send((headers) => http.put(
            _uri(endpoint),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          ));

  static Future<http.Response> patch(
    String endpoint, {
    Map<String, dynamic>? body,
  }) =>
      _send((headers) => http.patch(
            _uri(endpoint),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          ));

  static Future<http.Response> delete(String endpoint) =>
      _send((headers) => http.delete(_uri(endpoint), headers: headers));
}
