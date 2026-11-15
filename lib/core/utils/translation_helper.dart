import 'dart:convert';
import 'api_client.dart';

class TranslationHelper {
  static Future<Map<String, String>> translate(
    String text, {
    bool throwOnError = false,
  }) =>
      translateText(text, throwOnError: throwOnError);

  /// Translates a single text string into English, Arabic, Sorani, and Badini.
  static Future<Map<String, String>> translateText(
    String text, {
    bool throwOnError = false,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return {'en': '', 'ar': '', 'ckb': '', 'kmr': ''};

    try {
      final res = await ApiClient.post('/translate', body: {'text': trimmed});

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['translations'] != null) {
          final t = data['translations'];
          return {
            'en': (t['en'] ?? '').toString().trim(),
            'ar': (t['ar'] ?? '').toString().trim(),
            'ckb': (t['ckb'] ?? trimmed).toString().trim(),
            'kmr': (t['kmr'] ?? trimmed).toString().trim(),
          };
        }
      }
      if (throwOnError) {
        throw Exception('هەڵە لە وەرگێڕان (${res.statusCode})');
      }
    } catch (e) {
      if (throwOnError) rethrow;
    }

    return {'en': trimmed, 'ar': trimmed, 'ckb': trimmed, 'kmr': trimmed};
  }

  static Future<Map<String, Map<String, String>>> translateFields(
    Map<String, String> fields,
  ) async {
    if (fields.isEmpty) return {};

    try {
      final res = await ApiClient.post('/translate', body: {'fields': fields});

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
                'kmr': (val['kmr'] ?? '').toString().trim(),
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
      fallback[k] = {'en': v, 'ar': v, 'ckb': v, 'kmr': v};
    });
    return fallback;
  }
}