import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(true);
  Timer? _timer;

  void initialize() {
    // Initial check
    checkRealInternet();

    // Regular interval internet checker (pure Dart, 0 native plugin dependencies)
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      checkRealInternet();
    });
  }

  Future<bool> checkRealInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      final hasInternet = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      if (isConnected.value != hasInternet) {
        isConnected.value = hasInternet;
      }
      return hasInternet;
    } catch (_) {
      try {
        // Fallback check
        final fallback = await InternetAddress.lookup('cloudflare.com')
            .timeout(const Duration(seconds: 3));
        final hasFallback = fallback.isNotEmpty && fallback[0].rawAddress.isNotEmpty;
        if (isConnected.value != hasFallback) {
          isConnected.value = hasFallback;
        }
        return hasFallback;
      } catch (_) {
        if (isConnected.value != false) {
          isConnected.value = false;
        }
        return false;
      }
    }
  }

  void dispose() {
    _timer?.cancel();
  }
}
