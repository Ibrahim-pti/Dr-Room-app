import 'package:flutter_test/flutter_test.dart';
import 'package:dr_room/core/models/payment_model.dart';

void main() {
  group('Transaction.fromJson', () {
    Map<String, dynamic> json({String status = 'succeeded'}) => {
          'id': 'txn_1',
          'amount': 49.5,
          'currency': 'USD',
          'status': status,
          'description': 'Appointment with Dr. Ahmed',
          'created_at': '2026-07-28T10:00:00.000Z',
          'appointment_id': 'apt_1',
          'payment_method': 'card',
        };

    test('parses the documented status strings', () {
      expect(Transaction.fromJson(json(status: 'succeeded')).status,
          TransactionStatus.succeeded);
      expect(Transaction.fromJson(json(status: 'failed')).status,
          TransactionStatus.failed);
      expect(Transaction.fromJson(json(status: 'refunded')).status,
          TransactionStatus.refunded);
    });

    test('falls back to pending for an unknown status', () {
      expect(Transaction.fromJson(json(status: 'weird')).status,
          TransactionStatus.pending);
    });

    test('formats the amount to two decimal places', () {
      expect(Transaction.fromJson(json()).formattedAmount, r'$49.50');
    });

    test('reads an integer amount as a double', () {
      final t = Transaction.fromJson({...json(), 'amount': 50});
      expect(t.amount, 50.0);
      expect(t.formattedAmount, r'$50.00');
    });

    test('survives a response missing every optional field', () {
      final t = Transaction.fromJson({});
      expect(t.id, '');
      expect(t.amount, 0.0);
      expect(t.currency, 'USD');
      expect(t.status, TransactionStatus.pending);
      expect(t.failureReason, isNull);
      expect(t.receiptUrl, isNull);
    });

    test('round-trips through toJson', () {
      final original = Transaction.fromJson(json());
      final restored = Transaction.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.amount, original.amount);
      expect(restored.status, original.status);
      expect(restored.appointmentId, original.appointmentId);
    });
  });

  group('TransactionStatus', () {
    test('every status has both an English and a Kurdish label', () {
      for (final status in TransactionStatus.values) {
        expect(status.displayName, isNotEmpty, reason: '$status displayName');
        expect(status.kurdiName, isNotEmpty, reason: '$status kurdiName');
      }
    });
  });

  group('PaymentMethod.fromJson', () {
    test('reads the snake_case fields the API returns', () {
      final method = PaymentMethod.fromJson({
        'id': 'pm_1',
        'type': 'card',
        'last4': '4242',
        'brand': 'visa',
        'expiry_month': 12,
        'expiry_year': 2030,
        'is_default': true,
      });

      expect(method.last4, '4242');
      expect(method.expiryMonth, 12);
      expect(method.expiryYear, 2030);
      expect(method.isDefault, isTrue);
    });

    test('defaults isDefault to false when absent', () {
      expect(PaymentMethod.fromJson({}).isDefault, isFalse);
    });
  });
}
