import 'package:intl/intl.dart';

class PaymentMethod {
  final String id;
  final String type; // 'card', 'apple_pay', 'google_pay'
  final String last4;
  final String brand; // 'visa', 'mastercard'
  final int expiryMonth;
  final int expiryYear;
  final bool isDefault;

  PaymentMethod({
    required this.id,
    required this.type,
    required this.last4,
    required this.brand,
    required this.expiryMonth,
    required this.expiryYear,
    this.isDefault = false,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] ?? '',
      type: json['type'] ?? 'card',
      last4: json['last4'] ?? '',
      brand: json['brand'] ?? 'unknown',
      expiryMonth: json['expiry_month'] ?? 0,
      expiryYear: json['expiry_year'] ?? 0,
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'last4': last4,
    'brand': brand,
    'expiry_month': expiryMonth,
    'expiry_year': expiryYear,
    'is_default': isDefault,
  };
}

class Transaction {
  final String id;
  final double amount;
  final String currency;
  final TransactionStatus status;
  final String description;
  final DateTime createdAt;
  final String? appointmentId;
  final String? orderId;
  final String? labTestId;
  final String paymentMethod;
  final String? receiptUrl;
  final String? failureReason;

  Transaction({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.description,
    required this.createdAt,
    this.appointmentId,
    this.orderId,
    this.labTestId,
    required this.paymentMethod,
    this.receiptUrl,
    this.failureReason,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString() == 'TransactionStatus.${json['status']}',
        orElse: () => TransactionStatus.pending,
      ),
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      appointmentId: json['appointment_id'],
      orderId: json['order_id'],
      labTestId: json['lab_test_id'],
      paymentMethod: json['payment_method'] ?? 'unknown',
      receiptUrl: json['receipt_url'],
      failureReason: json['failure_reason'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'currency': currency,
    'status': status.toString().split('.').last,
    'description': description,
    'created_at': createdAt.toIso8601String(),
    'appointment_id': appointmentId,
    'order_id': orderId,
    'lab_test_id': labTestId,
    'payment_method': paymentMethod,
    'receipt_url': receiptUrl,
    'failure_reason': failureReason,
  };

  String get formattedAmount => '\$${amount.toStringAsFixed(2)}';
  String get formattedDate => DateFormat('MMM dd, yyyy').format(createdAt);
  String get formattedTime => DateFormat('hh:mm a').format(createdAt);
}

enum TransactionStatus {
  pending,
  processing,
  succeeded,
  failed,
  canceled,
  refunded,
}

extension TransactionStatusExt on TransactionStatus {
  String get displayName {
    switch (this) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.processing:
        return 'Processing';
      case TransactionStatus.succeeded:
        return 'Completed';
      case TransactionStatus.failed:
        return 'Failed';
      case TransactionStatus.canceled:
        return 'Canceled';
      case TransactionStatus.refunded:
        return 'Refunded';
    }
  }

  String get kurdiName {
    switch (this) {
      case TransactionStatus.pending:
        return 'چاوەڕێدان';
      case TransactionStatus.processing:
        return 'لە پرۆسەدا';
      case TransactionStatus.succeeded:
        return 'تەواو بوو';
      case TransactionStatus.failed:
        return 'شکست هێنا';
      case TransactionStatus.canceled:
        return 'لەبیر کرا';
      case TransactionStatus.refunded:
        return 'گێڕانەوە کرا';
    }
  }
}

class PaymentIntent {
  final String clientSecret;
  final String paymentIntentId;
  final double amount;
  final String currency;
  final String description;
  final Map<String, dynamic>? metadata;

  PaymentIntent({
    required this.clientSecret,
    required this.paymentIntentId,
    required this.amount,
    required this.currency,
    required this.description,
    this.metadata,
  });

  factory PaymentIntent.fromJson(Map<String, dynamic> json) {
    return PaymentIntent(
      clientSecret: json['clientSecret'] ?? '',
      paymentIntentId: json['paymentIntentId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      description: json['description'] ?? '',
      metadata: json['metadata'],
    );
  }
}

class Refund {
  final String id;
  final String transactionId;
  final double amount;
  final String reason;
  final DateTime createdAt;
  final RefundStatus status;

  Refund({
    required this.id,
    required this.transactionId,
    required this.amount,
    required this.reason,
    required this.createdAt,
    required this.status,
  });

  factory Refund.fromJson(Map<String, dynamic> json) {
    return Refund(
      id: json['id'] ?? '',
      transactionId: json['transaction_id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      reason: json['reason'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      status: RefundStatus.values.firstWhere(
        (e) => e.toString() == 'RefundStatus.${json['status']}',
        orElse: () => RefundStatus.pending,
      ),
    );
  }
}

enum RefundStatus {
  pending,
  succeeded,
  failed,
}
