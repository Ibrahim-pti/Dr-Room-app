import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/cupertino.dart';

class CkbMaterialLocalizations extends LocalizationsDelegate<MaterialLocalizations> {
  const CkbMaterialLocalizations();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ckb';

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    return await GlobalMaterialLocalizations.delegate.load(const Locale('ar'));
  }

  @override
  bool shouldReload(CkbMaterialLocalizations old) => false;
}

class CkbWidgetLocalizations extends LocalizationsDelegate<WidgetsLocalizations> {
  const CkbWidgetLocalizations();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ckb';

  @override
  Future<WidgetsLocalizations> load(Locale locale) async {
    return await GlobalWidgetsLocalizations.delegate.load(const Locale('ar'));
  }

  @override
  bool shouldReload(CkbWidgetLocalizations old) => false;
}

class CkbCupertinoLocalizations extends LocalizationsDelegate<CupertinoLocalizations> {
  const CkbCupertinoLocalizations();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ckb';

  @override
  Future<CupertinoLocalizations> load(Locale locale) async {
    return await GlobalCupertinoLocalizations.delegate.load(const Locale('ar'));
  }

  @override
  bool shouldReload(CkbCupertinoLocalizations old) => false;
}
