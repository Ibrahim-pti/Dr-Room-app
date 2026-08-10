import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentService _paymentService = PaymentService();

  List<PaymentMethod> _paymentMethods = [];
  List<Transaction> _transactions = [];
  Transaction? _currentTransaction;
  bool _isLoading = false;
  String? _error;
  PaymentIntent? _currentPaymentIntent;

  // Getters
  List<PaymentMethod> get paymentMethods => _paymentMethods;
  List<Transaction> get transactions => _transactions;
  Transaction? get currentTransaction => _currentTransaction;
  bool get isLoading => _isLoading;
  String? get error => _error;
  PaymentIntent? get currentPaymentIntent => _currentPaymentIntent;

  /// Create payment intent
  Future<bool> createPaymentIntent({
    required double amount,
    required String currency,
    required String description,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _currentPaymentIntent = await _paymentService.createPaymentIntent(
        amount: amount,
        currency: currency,
        description: description,
        metadata: metadata,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Confirm payment
  Future<bool> confirmPayment({
    required String paymentIntentId,
    required String paymentMethodId,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _currentTransaction = await _paymentService.confirmPayment(
        paymentIntentId: paymentIntentId,
        paymentMethodId: paymentMethodId,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Fetch transaction history
  Future<bool> fetchTransactionHistory() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _transactions = await _paymentService.getTransactionHistory();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Fetch payment methods
  Future<bool> fetchPaymentMethods() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _paymentMethods = await _paymentService.getPaymentMethods();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Save payment method
  Future<bool> savePaymentMethod({
    required String token,
    required String type,
    required bool setAsDefault,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final method = await _paymentService.savePaymentMethod(
        token: token,
        type: type,
        setAsDefault: setAsDefault,
      );

      _paymentMethods.add(method);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete payment method
  Future<bool> deletePaymentMethod(String methodId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _paymentService.deletePaymentMethod(methodId);
      _paymentMethods.removeWhere((m) => m.id == methodId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Request refund
  Future<bool> requestRefund({
    required String transactionId,
    required String reason,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _paymentService.requestRefund(
        transactionId: transactionId,
        reason: reason,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear current payment intent
  void clearPaymentIntent() {
    _currentPaymentIntent = null;
    _currentTransaction = null;
    _error = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
