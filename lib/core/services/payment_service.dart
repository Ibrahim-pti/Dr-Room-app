import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/payment_model.dart';
import '../utils/api_client.dart';

class PaymentService {
  static const String _storageKey = 'payment_methods';
  static const String _transactionsKey = 'transactions';

  /// Create a payment intent for a transaction
  Future<PaymentIntent> createPaymentIntent({
    required double amount,
    required String currency,
    required String description,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final response = await ApiClient.post(
        '/payments/create-intent',
        body: {
          'amount': amount,
          'currency': currency,
          'description': description,
          'metadata': metadata,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return PaymentIntent.fromJson(data);
      } else {
        throw Exception('Failed to create payment intent: ${response.body}');
      }
    } catch (e) {
      throw Exception('Payment intent creation failed: $e');
    }
  }

  /// Confirm payment with card details
  Future<Transaction> confirmPayment({
    required String paymentIntentId,
    required String paymentMethodId,
  }) async {
    try {
      final response = await ApiClient.post(
        '/payments/confirm',
        body: {
          'paymentIntentId': paymentIntentId,
          'paymentMethodId': paymentMethodId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final transaction = Transaction.fromJson(data);
        await _cacheTransaction(transaction);
        return transaction;
      } else {
        throw Exception('Payment confirmation failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Payment confirmation error: $e');
    }
  }

  /// Get transaction history
  Future<List<Transaction>> getTransactionHistory() async {
    try {
      final response = await ApiClient.get('/payments/history');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transactions = (data['data'] as List)
            .map((t) => Transaction.fromJson(t))
            .toList();
        return transactions;
      } else {
        throw Exception('Failed to fetch transactions: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching transactions: $e');
    }
  }

  /// Get a single transaction
  Future<Transaction> getTransaction(String transactionId) async {
    try {
      final response = await ApiClient.get('/payments/transaction/$transactionId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Transaction.fromJson(data);
      } else {
        throw Exception('Failed to fetch transaction: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching transaction: $e');
    }
  }

  /// Save a payment method
  Future<PaymentMethod> savePaymentMethod({
    required String token,
    required String type,
    required bool setAsDefault,
  }) async {
    try {
      final response = await ApiClient.post(
        '/payments/methods/save',
        body: {
          'token': token,
          'type': type,
          'set_as_default': setAsDefault,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final method = PaymentMethod.fromJson(data);
        await _cachePaymentMethod(method);
        return method;
      } else {
        throw Exception('Failed to save payment method: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error saving payment method: $e');
    }
  }

  /// Get saved payment methods
  Future<List<PaymentMethod>> getPaymentMethods() async {
    try {
      final response = await ApiClient.get('/payments/methods');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final methods = (data['data'] as List)
            .map((m) => PaymentMethod.fromJson(m))
            .toList();
        return methods;
      } else {
        throw Exception('Failed to fetch payment methods: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching payment methods: $e');
    }
  }

  /// Delete a payment method
  Future<bool> deletePaymentMethod(String methodId) async {
    try {
      final response = await ApiClient.delete('/payments/methods/$methodId');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        throw Exception('Failed to delete payment method');
      }
    } catch (e) {
      throw Exception('Error deleting payment method: $e');
    }
  }

  /// Process refund
  Future<Refund> requestRefund({
    required String transactionId,
    required String reason,
  }) async {
    try {
      final response = await ApiClient.post(
        '/payments/refund',
        body: {
          'transactionId': transactionId,
          'reason': reason,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Refund.fromJson(data);
      } else {
        throw Exception('Refund request failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error requesting refund: $e');
    }
  }

  /// Verify payment (for security)
  Future<bool> verifyPayment(String paymentIntentId) async {
    try {
      final response = await ApiClient.post(
        '/payments/verify',
        body: {'paymentIntentId': paymentIntentId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['verified'] ?? false;
      }
      return false;
    } catch (e) {
      throw Exception('Error verifying payment: $e');
    }
  }

  /// Get payment receipt
  Future<String> getReceipt(String transactionId) async {
    try {
      final response = await ApiClient.get('/payments/receipt/$transactionId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['receipt_url'] ?? '';
      } else {
        throw Exception('Failed to get receipt: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting receipt: $e');
    }
  }

  // Local storage methods
  Future<void> _cachePaymentMethod(PaymentMethod method) async {
    final prefs = await SharedPreferences.getInstance();
    final methods = prefs.getStringList(_storageKey) ?? [];
    methods.add(jsonEncode(method.toJson()));
    await prefs.setStringList(_storageKey, methods);
  }

  Future<void> _cacheTransaction(Transaction transaction) async {
    final prefs = await SharedPreferences.getInstance();
    final transactions = prefs.getStringList(_transactionsKey) ?? [];
    transactions.add(jsonEncode(transaction.toJson()));
    await prefs.setStringList(_transactionsKey, transactions);
  }

  Future<List<PaymentMethod>> getCachedPaymentMethods() async {
    final prefs = await SharedPreferences.getInstance();
    final methods = prefs.getStringList(_storageKey) ?? [];
    return methods.map((m) => PaymentMethod.fromJson(jsonDecode(m))).toList();
  }

  Future<List<Transaction>> getCachedTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final transactions = prefs.getStringList(_transactionsKey) ?? [];
    return transactions.map((t) => Transaction.fromJson(jsonDecode(t))).toList();
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.remove(_transactionsKey);
  }
}
