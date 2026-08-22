import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

extension LocalizedContextExtension on BuildContext {
  /// Extracts the localized value from a dynamic Map/Model based on the active locale.
  /// Checks `field_en`, `field_ar`, `field_ckb`, and falls back to `field`.
  String localizedField(dynamic item, String fieldName, {String fallback = ''}) {
    if (item == null) return fallback;
    final lang = locale.languageCode.toLowerCase(); // 'ckb', 'ar', 'en'
    
    if (item is Map) {
      if (lang == 'en') {
        final enVal = item['${fieldName}_en'] ?? item['${fieldName}En'] ?? item['${fieldName}_english'];
        if (enVal != null && enVal.toString().trim().isNotEmpty) {
          return enVal.toString().trim();
        }
      } else if (lang == 'ar') {
        final arVal = item['${fieldName}_ar'] ?? item['${fieldName}Ar'] ?? item['${fieldName}_arabic'];
        if (arVal != null && arVal.toString().trim().isNotEmpty) {
          return arVal.toString().trim();
        }
      } else {
        // Kurdish (ckb / ku)
        final ckbVal = item['${fieldName}_ckb'] ?? item['${fieldName}_ku'] ?? item['${fieldName}_kurdish'];
        if (ckbVal != null && ckbVal.toString().trim().isNotEmpty) {
          return ckbVal.toString().trim();
        }
      }

      final defaultVal = item[fieldName];
      if (defaultVal != null && defaultVal.toString().trim().isNotEmpty) {
        return defaultVal.toString().trim();
      }
    }
    return fallback;
  }
}

extension LocalizedMapExtension on Map<String, dynamic> {
  /// Convenience extension to call directly on a Map with BuildContext
  String trField(BuildContext context, String fieldName, {String fallback = ''}) {
    return context.localizedField(this, fieldName, fallback: fallback);
  }
}
