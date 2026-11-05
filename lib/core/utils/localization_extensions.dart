import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

extension LocalizedContextExtension on BuildContext {
  /// Extracts the localized value from a dynamic Map/Model based on the active locale.
  /// Checks `field_en`, `field_ar`, `field_ckb`, and falls back to `field` with smart translation.
  String localizedField(dynamic item, String fieldName, {String fallback = ''}) {
    if (item == null) return fallback;
    final lang = this.locale.languageCode.toLowerCase(); // 'ckb', 'ar', 'en', 'kmr'
    
    if (item is Map) {
      // If field not directly on item, check nested user object (e.g. nurse['user'])
      final targetMap = (item[fieldName] == null && item['user'] is Map)
          ? item['user'] as Map
          : item;

      if (lang == 'en') {
        final enVal = targetMap['${fieldName}_en'] ?? targetMap['${fieldName}En'] ?? targetMap['${fieldName}_english'];
        if (enVal != null && enVal.toString().trim().isNotEmpty) {
          return enVal.toString().trim();
        }
      } else if (lang == 'ar') {
        final arVal = targetMap['${fieldName}_ar'] ?? targetMap['${fieldName}Ar'] ?? targetMap['${fieldName}_arabic'];
        if (arVal != null && arVal.toString().trim().isNotEmpty) {
          return arVal.toString().trim();
        }
      } else if (lang == 'kmr') {
        final kmrVal = targetMap['${fieldName}_kmr'] ?? targetMap['${fieldName}Kmr'] ?? targetMap['${fieldName}_badini'];
        if (kmrVal != null && kmrVal.toString().trim().isNotEmpty) {
          return kmrVal.toString().trim();
        }
      } else {
        // Kurdish (ckb / ku)
        final ckbVal = targetMap['${fieldName}_ckb'] ?? targetMap['${fieldName}_ku'] ?? targetMap['${fieldName}_kurdish'];
        if (ckbVal != null && ckbVal.toString().trim().isNotEmpty) {
          return ckbVal.toString().trim();
        }
      }

      final defaultVal = targetMap[fieldName];
      if (defaultVal != null && defaultVal.toString().trim().isNotEmpty) {
        final str = defaultVal.toString().trim();
        if (lang != 'en') {
          final translated = _translateKnownValue(str, lang);
          if (translated != null) return translated;
        }
        return str;
      }
    }
    return fallback;
  }

  String? _translateKnownValue(String raw, String lang) {
    final lower = raw.toLowerCase().trim();
    final isArabic = lang == 'ar';
    final isBadini = lang == 'kmr';

    // 1. Common names from API
    if (lower == 'aesha fatih' || lower == 'aisha fatih') {
      return isArabic ? 'عائشة فاتح' : (isBadini ? 'عایشە فاتیح' : 'عائشە فاتیح');
    }
    if (lower == 'aesha' || lower == 'aisha') {
      return isArabic ? 'عائشة' : (isBadini ? 'عایشە' : 'عائشە');
    }

    // 2. Specialties & Titles
    if (lower == 'general care' || lower == 'general' || lower == 'general nursing') {
      return isArabic ? 'رعاية عامة' : (isBadini ? 'چاڤدێرییا گشتی' : 'چاودێری گشتی');
    }
    if (lower.contains('sampling') || lower.contains('phlebotom')) {
      return isArabic ? 'أخصائي سحب عينات' : (isBadini ? 'پسپۆڕێ وەرگرتنا نموونان' : 'پسپۆڕی وەرگرتنی نموونە');
    }
    if (lower.contains('wound') || lower.contains('dressing')) {
      return isArabic ? 'عناية بالجروح' : (isBadini ? 'چارەسەریا برینان' : 'چارەسەری برین');
    }
    if (lower.contains('emergency') || lower.contains('first aid')) {
      return isArabic ? 'طوارئ وإسعافات' : (isBadini ? 'هەوارچوونا لەزگین' : 'فریاکەوتنی خێرا');
    }
    if (lower.contains('elderly') || lower.contains('geriatric')) {
      return isArabic ? 'رعاية كبار السن' : (isBadini ? 'چاڤدێرییا ب تەمەن داچوویان' : 'چاودێری بەساڵاچووان');
    }
    if (lower.contains('pediatric') || lower.contains('child care')) {
      return isArabic ? 'رعاية أطفال' : (isBadini ? 'چاڤدێرییا زارۆکان' : 'چاودێری منداڵان');
    }
    if (lower.contains('cannula')) {
      return isArabic ? 'تركيب كانيولا وريدية' : (isBadini ? 'دانانا کانیۆلا' : 'دانانی کانیۆلا و دەرزی دەمار');
    }
    if (lower.contains('injection')) {
      return isArabic ? 'حقن (عضلي / وريدي)' : (isBadini ? 'لێدانا دەرزیێ' : 'لێدانی دەرزی (ماسولکە یان دەمار)');
    }
    if (lower.contains('serum') || lower.contains('fluid infusion')) {
      return isArabic ? 'إعطاء مغذي ومحاليل' : (isBadini ? 'گرێدانا موغەزی' : 'بەستنی موغەزی (سیرۆم)');
    }
    if (lower.contains('vital signs') || lower.contains('blood pressure')) {
      return isArabic ? 'قياس العلامات الحيوية' : (isBadini ? 'پێڤانا نیشانێن ژیانێ' : 'پێوانی پەستان، شەکرە و ئۆکسجین');
    }
    if (lower.contains('catheter')) {
      return isArabic ? 'قسطرة بولية' : (isBadini ? 'سۆندەیا میزێ' : 'دانان یان گۆڕینی سۆندەی میز');
    }
    if (lower.contains('home nursing') || lower.contains('home care')) {
      return isArabic ? 'تمريض منزلي' : (isBadini ? 'پەرستاریا مالێ' : 'پەرستاری ماڵەوە');
    }
    if (lower.contains('icu')) {
      return isArabic ? 'عناية مركزة' : (isBadini ? 'چاڤدێرییا چڕ' : 'چاودێری چڕ');
    }

    // 3. Cities
    if (lower == 'erbil' || lower == 'hawler') {
      return isArabic ? 'أربيل' : 'هەولێر';
    }
    if (lower == 'sulaymaniyah' || lower == 'slemani') {
      return isArabic ? 'السليمانية' : 'سلێمانی';
    }
    if (lower == 'duhok' || lower == 'dohuk') {
      return isArabic ? 'دهوك' : 'دهۆک';
    }
    if (lower == 'kirkuk') {
      return isArabic ? 'كركوك' : 'کەرکووک';
    }
    if (lower == 'halabja') {
      return isArabic ? 'حلبجة' : 'هەڵەبجە';
    }
    if (lower == 'zakho') {
      return isArabic ? 'زاخو' : 'زاخۆ';
    }
    if (lower == 'soran') {
      return isArabic ? 'سوران' : 'سۆران';
    }

    return null;
  }
}

extension LocalizedMapExtension on Map<String, dynamic> {
  /// Convenience extension to call directly on a Map with BuildContext
  String trField(BuildContext context, String fieldName, {String fallback = ''}) {
    return context.localizedField(this, fieldName, fallback: fallback);
  }
}
