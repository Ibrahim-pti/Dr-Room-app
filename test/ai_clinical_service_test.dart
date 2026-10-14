import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dr_room/features/ai_assistant/services/ai_clinical_service.dart';

void main() {
  test('AiClinicalVisionService analyzes medical image via real Gemini Vision', () async {
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

    print('REAL AI RESPONSE FOR REPORT:');
    print('Title: ${result['title']}');
    print('Summary: ${result['summary']}');
    print('Markers count: ${(result['markers'] as List).length}');
  });
}
