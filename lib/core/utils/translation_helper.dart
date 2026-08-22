import 'dart:convert';
import 'api_client.dart';

class TranslationHelper {
  static Future<Map<String, String>> translate(String text) => translateText(text);

  /// Translates a single text string into English, Arabic, and Kurdish.
  static Future<Map<String, String>> translateText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return {'en': '', 'ar': '', 'ckb': ''};

    try {
      final res = await ApiClient.post('/translate', body: {
        'text': trimmed,
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['translations'] != null) {
          final t = data['translations'];
          return {
            'en': (t['en'] ?? '').toString().trim(),
            'ar': (t['ar'] ?? '').toString().trim(),
            'ckb': (t['ckb'] ?? trimmed).toString().trim(),
          };
        }
      }
    } catch (_) {}

    return {'en': trimmed, 'ar': trimmed, 'ckb': trimmed};
  }

  /// Batch translates multiple key-value pairs at once.
  /// Example input: `{"title": "سووتان", "content": "..."}`
  /// Example output: `{"title": {"en": "Burns", "ar": "حروق", "ckb": "سووتان"}, ...}`
  static Future<Map<String, Map<String, String>>> translateFields(Map<String, String> fields) async {
    if (fields.isEmpty) return {};

    try {
      final res = await ApiClient.post('/translate', body: {
        'fields': fields,
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['translations'] != null) {
          final Map<String, dynamic> raw = data['translations'];
          final Map<String, Map<String, String>> result = {};

          raw.forEach((key, val) {
            if (val is Map) {
              result[key] = {
                'en': (val['en'] ?? '').toString().trim(),
                'ar': (val['ar'] ?? '').toString().trim(),
                'ckb': (val['ckb'] ?? '').toString().trim(),
              };
            }
          });

          return result;
        }
      }
    } catch (_) {}

    // Fallback: return original for all
    final Map<String, Map<String, String>> fallback = {};
    fields.forEach((k, v) {
      fallback[k] = {'en': v, 'ar': v, 'ckb': v};
    });
    return fallback;
  }
}
