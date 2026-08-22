import 'package:easy_localization/easy_localization.dart';

/// Money formatting for the whole app.
///
/// Prices are Iraqi dinars. The dinar has no practical subunit and everyday
/// amounts run to five or six digits, so amounts are shown as whole numbers
/// with thousand separators — "15,000 د.ع", never "15000.00".
///
/// Everything that shows a price goes through here, so changing how money
/// looks (or which currency it is) is a change to this one file.
class Currency {
  Currency._();

  static final NumberFormat _whole = NumberFormat('#,##0');

  /// The symbol, translated: د.ع in Kurdish and Arabic, IQD in English.
  static String get symbol => 'currency_iqd'.tr();

  /// e.g. `15,000 د.ع`
  static String format(num amount) => '${_whole.format(amount)} $symbol';

  /// The number alone, for places that draw the symbol separately.
  static String amountOnly(num amount) => _whole.format(amount);
}