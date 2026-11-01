import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_client.dart';

class ServiceFeeModel {
  final bool isEnabled;
  final bool isFree;
  final double amount;
  final bool hasDiscount;
  final double discountPercent;
  final double discountAmount;
  final String? note;

  const ServiceFeeModel({
    this.isEnabled = true,
    this.isFree = false,
    this.amount = 1000.0,
    this.hasDiscount = false,
    this.discountPercent = 0.0,
    this.discountAmount = 0.0,
    this.note,
  });

  double get discountValue {
    if (!isEnabled || isFree || !hasDiscount) return 0.0;
    if (discountPercent > 0) {
      final val = (amount * (discountPercent / 100)).roundToDouble();
      return val > amount ? amount : val;
    }
    if (discountAmount > 0) {
      return discountAmount > amount ? amount : discountAmount;
    }
    return 0.0;
  }

  double get effectiveAmount {
    if (!isEnabled || isFree) return 0.0;
    final res = amount - discountValue;
    return res < 0.0 ? 0.0 : res;
  }

  Map<String, dynamic> toJson() => {
        'is_enabled': isEnabled,
        'is_free': isFree,
        'amount': amount,
        'has_discount': hasDiscount,
        'discount_percent': discountPercent,
        'discount_amount': discountAmount,
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
    final hasDiscountVal = json['has_discount'] == true ||
        json['has_discount'] == 1 ||
        json['has_discount'] == '1' ||
        json['has_discount'] == 'true';
    final amountVal = (json['amount'] as num?)?.toDouble() ?? 1000.0;
    final discountPercentVal = (json['discount_percent'] as num?)?.toDouble() ?? 0.0;
    final discountAmountVal = (json['discount_amount'] as num?)?.toDouble() ?? 0.0;

    return ServiceFeeModel(
      isEnabled: isEnabledVal,
      isFree: isFreeVal,
      amount: amountVal,
      hasDiscount: hasDiscountVal,
      discountPercent: discountPercentVal,
      discountAmount: discountAmountVal,
      note: json['note']?.toString(),
    );
  }

  ServiceFeeModel copyWith({
    bool? isEnabled,
    bool? isFree,
    double? amount,
    bool? hasDiscount,
    double? discountPercent,
    double? discountAmount,
    String? note,
  }) {
    return ServiceFeeModel(
      isEnabled: isEnabled ?? this.isEnabled,
      isFree: isFree ?? this.isFree,
      amount: amount ?? this.amount,
      hasDiscount: hasDiscount ?? this.hasDiscount,
      discountPercent: discountPercent ?? this.discountPercent,
      discountAmount: discountAmount ?? this.discountAmount,
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
  double get originalFee => _feeModel.isEnabled ? _feeModel.amount : 0.0;
  double get currentFee => _feeModel.effectiveAmount;
  double get discountValue => _feeModel.discountValue;
  double get discountPercent => _feeModel.discountPercent;
  bool get hasDiscount => _feeModel.hasDiscount && _feeModel.discountValue > 0;
  bool get isFree => _feeModel.isFree || !_feeModel.isEnabled || currentFee == 0;
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
