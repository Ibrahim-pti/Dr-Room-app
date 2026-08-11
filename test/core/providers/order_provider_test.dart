import 'package:dr_room/core/providers/order_provider.dart';
import 'package:flutter_test/flutter_test.dart';

final _fixedDate = DateTime(2026, 8, 11);

/// Builds an order without going through JSON, for provider-level tests.
OrderModel order({
  required String id,
  String serviceType = 'Lab Tests',
  OrderStatus status = OrderStatus.pending,
}) {
  return OrderModel(
    id: id,
    serviceType: serviceType,
    status: status,
    price: 110,
    date: _fixedDate,
  );
}

/// Builds the JSON shape the `/orders` endpoint actually returns.
Map<String, dynamic> orderJson({
  Object? id = 1,
  String serviceType = 'Lab Tests',
  String status = 'pending',
  Object? totalPrice = 110,
  String createdAt = '2026-08-11T17:05:52.000000Z',
  Map<String, dynamic>? nurse,
}) {
  return {
    'id': id,
    'service_type': serviceType,
    'status': status,
    'total_price': totalPrice,
    'created_at': createdAt,
    'assigned_nurse': nurse,
  };
}

void main() {
  group('OrderStatus.fromApi', () {
    test('maps each status the API stores', () {
      expect(OrderStatus.fromApi('pending'), OrderStatus.pending);
      expect(OrderStatus.fromApi('processing'), OrderStatus.processing);
      expect(OrderStatus.fromApi('completed'), OrderStatus.completed);
      expect(OrderStatus.fromApi('cancelled'), OrderStatus.cancelled);
    });

    test('is case and whitespace insensitive', () {
      expect(OrderStatus.fromApi('  Pending '), OrderStatus.pending);
      expect(OrderStatus.fromApi('COMPLETED'), OrderStatus.completed);
    });

    test('maps the legacy "accepted" status onto processing', () {
      expect(OrderStatus.fromApi('accepted'), OrderStatus.processing);
    });

    test('falls back to pending rather than dropping unknown values', () {
      expect(OrderStatus.fromApi('something_new'), OrderStatus.pending);
      expect(OrderStatus.fromApi(null), OrderStatus.pending);
      expect(OrderStatus.fromApi(''), OrderStatus.pending);
    });

    test('only pending and processing count as active', () {
      expect(OrderStatus.pending.isActive, isTrue);
      expect(OrderStatus.processing.isActive, isTrue);
      expect(OrderStatus.completed.isActive, isFalse);
      expect(OrderStatus.cancelled.isActive, isFalse);
    });
  });

  group('OrderModel.fromJson', () {
    test('parses the fields the API sends', () {
      final parsed = OrderModel.fromJson(orderJson());

      expect(parsed.id, '1');
      expect(parsed.serviceType, 'Lab Tests');
      expect(parsed.status, OrderStatus.pending);
      expect(parsed.price, 110.0);
      expect(parsed.date.year, 2026);
      expect(parsed.assignedNurseId, isNull);
    });

    test('accepts a price sent as a string or a number', () {
      expect(OrderModel.fromJson(orderJson(totalPrice: 110)).price, 110.0);
      expect(OrderModel.fromJson(orderJson(totalPrice: '110.50')).price, 110.50);
      expect(OrderModel.fromJson(orderJson(totalPrice: null)).price, 0.0);
    });

    test('reads the assigned nurse when one is attached', () {
      final parsed = OrderModel.fromJson(
        orderJson(nurse: {'id': 7, 'name': 'Zhino', 'avatar': 'a.png'}),
      );

      expect(parsed.assignedNurseId, '7');
      expect(parsed.assignedNurseName, 'Zhino');
      expect(parsed.assignedNurseAvatar, 'a.png');
    });

    test('survives a malformed date instead of throwing', () {
      final parsed = OrderModel.fromJson(orderJson(createdAt: 'not-a-date'));
      expect(parsed.date, isA<DateTime>());
    });

    test('gives each service type its own icon and colour', () {
      final lab = OrderModel.fromJson(orderJson(serviceType: 'Lab Tests'));
      final nursing =
          OrderModel.fromJson(orderJson(serviceType: 'Nursing Services'));
      final pharmacy = OrderModel.fromJson(orderJson(serviceType: 'pharmacy'));

      expect({lab.icon, nursing.icon, pharmacy.icon}.length, 3);
      expect({lab.iconColor, nursing.iconColor, pharmacy.iconColor}.length, 3);
    });
  });

  group('OrderProvider', () {
    test('counts only the orders the patient is still waiting on', () async {
      final provider = OrderProvider();

      await provider
          .addOrder(order(id: '3', status: OrderStatus.completed));
      await provider
          .addOrder(order(id: '2', status: OrderStatus.processing));
      await provider.addOrder(order(id: '1', status: OrderStatus.pending));

      expect(provider.orders.length, 3);
      expect(provider.activeOrderCount, 2);
    });

    test('updateOrderStatus changes only the targeted order', () {
      final provider = OrderProvider();
      provider.addOrder(order(id: '1'));
      provider.addOrder(order(id: '2', serviceType: 'pharmacy'));

      provider.updateOrderStatus('1', OrderStatus.cancelled);

      expect(provider.orders.firstWhere((o) => o.id == '1').status,
          OrderStatus.cancelled);
      expect(provider.orders.firstWhere((o) => o.id == '2').status,
          OrderStatus.pending);
      expect(provider.activeOrderCount, 1);
    });

    test('clear() empties the list so the next patient starts fresh', () {
      final provider = OrderProvider();
      provider.addOrder(order(id: '1'));

      provider.clear();

      expect(provider.orders, isEmpty);
      expect(provider.activeOrderCount, 0);
      expect(provider.hasLoadedOnce, isFalse);
    });
  });
}
