/// Iraqi mobile numbers are entered locally as 11 digits starting with 0
/// (e.g. 07701234567). Firebase Phone Auth requires E.164, so the leading 0
/// is swapped for the +964 country code.
String toE164IraqPhone(String localPhone) => '+964${localPhone.substring(1)}';
