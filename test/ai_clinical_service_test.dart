import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dr_room/features/ai_assistant/services/ai_clinical_service.dart';

void main() {
  test('AiClinicalVisionService local fallback analyzes medical image across modes', () {
    final sampleFile = File('assets/images/report.png');
    expect(sampleFile.existsSync(), isTrue);

    for (final mode in ['lab', 'medicine', 'prescription']) {
      final result = AiClinicalVisionService.instance.getIntelligentMedicineResult(
        imageFile: sampleFile,
        mode: mode,
        language: 'ckb',
      );

      expect(result, isA<Map<String, dynamic>>());
      expect(result['title'], isNotNull);
      expect(result['summary'], isNotNull);
      expect(result['markers'], isA<List>());
      expect(result['recommendations'], isNotNull);
      expect(result['warnings'], isNotNull);
    }
  });

  test('AiClinicalVisionService analyzeMedicalImage returns valid result or falls back cleanly', () async {
    final sampleFile = File('assets/images/report.png');
    expect(sampleFile.existsSync(), isTrue);

    final result = await AiClinicalVisionService.instance.analyzeMedicalImage(
      imageFile: sampleFile,
      mode: 'lab',
    );

    expect(result, isNotNull);
    expect(result['title'], isNotNull);
    expect(result['summary'], isNotNull);
    expect(result['markers'], isA<List>());
    expect(result['recommendations'], isNotNull);
    expect(result['warnings'], isNotNull);
  }, timeout: const Timeout(Duration(seconds: 45)));
}
