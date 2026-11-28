import 'package:flutter_test/flutter_test.dart';
import 'package:dr_room/features/admin/services/commission_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('CommissionPdfService generates valid multi-page PDF with providers list', () async {
    final providers = List.generate(25, (i) {
      final isLab = i % 2 == 0;
      return {
        'id': i + 1,
        'name': isLab ? 'تاقیگەی تاقیکردنەوە $i' : 'پەرستاری تاقیکردنەوە $i',
        'phone': '075000000${i.toString().padLeft(2, '0')}',
        'service_type': isLab ? 'lab' : 'nursing',
        'rate': isLab ? 58 : 42,
        'total_orders': i + 1,
        'total_amount': 50000 * (i + 1),
        'total_commission': 25000 * (i + 1),
        'provider_net': 25000 * (i + 1),
      };
    });

    final doc = await CommissionPdfService.generate({
      'year': 2026,
      'month': 11,
      'total_orders': 16,
      'total_revenue': 567600,
      'total_commission': 287928,
      'total_provider_payout': 279672,
      'breakdown': [
        {
          'service_type': 'nursing',
          'label': 'پەرستاری ماڵەوە',
          'rate': 42,
          'total_orders': 4,
          'total_amount': 258000,
          'total_commission': 108360,
          'provider_net': 149640,
        },
        {
          'service_type': 'lab',
          'label': 'تاقیگەکان',
          'rate': 58,
          'total_orders': 12,
          'total_amount': 309600,
          'total_commission': 179568,
          'provider_net': 130032,
        },
      ],
      'providers': providers,
      'generated_at': '2026-11-28 09:05',
    });

    final bytes = await doc.save();
    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
