import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

enum OtpChannel {
  auto('auto', 'خۆکار', Icons.auto_awesome_rounded),
  whatsapp('whatsapp', 'وەتسئاپ (WhatsApp)', Icons.chat_rounded),
  sms('sms', 'نامەی دەستی (SMS)', Icons.sms_rounded);

  final String value;
  final String label;
  final IconData icon;

  const OtpChannel(this.value, this.label, this.icon);

  static OtpChannel fromString(String? val) {
    if (val == null) return OtpChannel.auto;
    switch (val.toLowerCase()) {
      case 'whatsapp':
        return OtpChannel.whatsapp;
      case 'sms':
        return OtpChannel.sms;
      default:
        return OtpChannel.auto;
    }
  }
}

class OtpIqService {
  OtpIqService._();
  static final OtpIqService instance = OtpIqService._();

  static const String baseUrl = 'https://api.otpiq.com/api';
  static const String apiKey = String.fromEnvironment('OTPIQ_API_KEY', defaultValue: '');

  /// Get project info and credit balance from OTP IQ
  Future<Map<String, dynamic>?> getProjectInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/info'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}
