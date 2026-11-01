import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_client.dart';

class ServiceFeeModel {
  final bool isEnabled;
  final bool isFree;
  final double amount;
  final String? note;

  const ServiceFeeModel({
    this.isEnabled = true,
    this.isFree = false,
    this.amount = 1000.0,
    this.note,
  });

  double get effectiveAmount => (isEnabled && !isFree) ? amount : 0.0;

  Map<String, dynamic> toJson() => {
        'is_enabled': isEnabled,
        'is_free': isFree,
        'amount': amount,
        'note': note,
      };

  factory ServiceFeeModel.fromJson(Map<String, dynamic> json) {
    final isFreeVal = json['is_free'] == true ||
        json['is_free'] == 1 ||
        json['is_free'] == '1' ||
        json['is_free'] == 'true';
    final isEnabledVal = json['is_enabled'] != false &&
        json['is_enabled'] != 0 &&
        json['is_enabled'] != '0' &&
        json['is_enabled'] != 'false';
    final amountVal = (json['amount'] as num?)?.toDouble() ?? 1000.0;

    return ServiceFeeModel(
      isEnabled: isEnabledVal,
      isFree: isFreeVal,
      amount: amountVal,
      note: json['note']?.toString(),
    );
  }

  ServiceFeeModel copyWith({
    bool? isEnabled,
    bool? isFree,
    double? amount,
    String? note,
  }) {
    return ServiceFeeModel(
      isEnabled: isEnabled ?? this.isEnabled,
      isFree: isFree ?? this.isFree,
      amount: amount ?? this.amount,
      note: note ?? this.note,
    );
  }
}

class ServiceFeeService extends ChangeNotifier {
  static final ServiceFeeService instance = ServiceFeeService._();
  static const String _storageKey = 'dr_room_service_fee_config_v1';

  ServiceFeeModel _feeModel = const ServiceFeeModel();
  bool _isInitialized = false;

  ServiceFeeService._() {
    init();
  }

  bool get isInitialized => _isInitialized;
  ServiceFeeModel get feeModel => _feeModel;
  double get currentFee => _feeModel.effectiveAmount;
  bool get isFree => _feeModel.isFree || !_feeModel.isEnabled || _feeModel.amount == 0;
  bool get isEnabled => _feeModel.isEnabled;
  String get note => _feeModel.note ?? '';

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString(_storageKey);
      if (savedStr != null && savedStr.isNotEmpty) {
        final decoded = jsonDecode(savedStr);
        if (decoded is Map<String, dynamic>) {
          _feeModel = ServiceFeeModel.fromJson(decoded);
        } else if (decoded is Map) {
          _feeModel = ServiceFeeModel.fromJson(Map<String, dynamic>.from(decoded));
        }
      }
      _isInitialized = true;
      notifyListeners();

      // Attempt to synchronize with backend if available
      _fetchRemoteConfig();
    } catch (e) {
      debugPrint('ServiceFeeService init error: $e');
    }
  }

  Future<void> _fetchRemoteConfig() async {
    try {
      final res = await ApiClient.get('/admin/service-fee');
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final data = decoded['data'] ?? decoded;
        if (data is Map) {
          _feeModel = ServiceFeeModel.fromJson(Map<String, dynamic>.from(data));
          notifyListeners();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_storageKey, jsonEncode(_feeModel.toJson()));
        }
      }
    } catch (_) {
      // Offline or endpoint not yet deployed; SharedPreferences handles it.
    }
  }

  Future<bool> updateFee(ServiceFeeModel newModel) async {
    try {
      _feeModel = newModel;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(newModel.toJson()));

      // Send to server
      try {
        await ApiClient.post('/admin/service-fee', body: newModel.toJson());
      } catch (_) {}

      return true;
    } catch (e) {
      debugPrint('Error updating service fee: $e');
      return false;
    }
  }
}
