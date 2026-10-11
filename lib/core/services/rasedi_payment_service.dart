import 'package:flutter/foundation.dart';
import 'package:rasedi_flutter_sdk/rasedi_flutter_sdk.dart';

class RasediPaymentResult {
  final bool isSuccess;
  final bool isCancelled;
  final String? referenceCode;
  final String? gatewayName;
  final String? errorMessage;

  const RasediPaymentResult({
    required this.isSuccess,
    this.isCancelled = false,
    this.referenceCode,
    this.gatewayName,
    this.errorMessage,
  });

  factory RasediPaymentResult.success({
    required String referenceCode,
    String? gatewayName,
  }) {
    return RasediPaymentResult(
      isSuccess: true,
      referenceCode: referenceCode,
      gatewayName: gatewayName,
    );
  }

  factory RasediPaymentResult.cancelled() {
    return const RasediPaymentResult(
      isSuccess: false,
      isCancelled: true,
      errorMessage: 'Payment was cancelled',
    );
  }

  factory RasediPaymentResult.failure(String error) {
    return RasediPaymentResult(
      isSuccess: false,
      errorMessage: error,
    );
  }
}

class RasediPaymentService {
  RasediPaymentService._internal();
  static final RasediPaymentService instance = RasediPaymentService._internal();

  // ─── Rasedi Credentials ──────────────────────────────────────────
  static const String privateKey = """-----BEGIN PRIVATE KEY-----
MC4CAQAwBQYDK2VwBCIEIBeh/FvUTOqfg5imPVSk2Efgxj1PjPgTzUwCyhHGL1Rj
-----END PRIVATE KEY-----""";

  static const String secretKey =
      "live_laislE2YS5aoEkKf5_eF9ZFxCX1q6pdF1YcqgnkaIaK_w0Rn-sxo2VoJqsFqtn0s_N6wIWnLh6VDfKb3jdf6O9xn";

  static const String redirectUrl = "https://drroom.app/payment/callback";
  static const String callbackUrl = "https://drroom.app/api/payments/webhook";

  late final RasediClient _client = RasediClient(privateKey, secretKey);

  RasediClient get client => _client;

  /// Map app payment method name to Rasedi Gateway enum
  static Gateway? mapMethodToGateway(String method) {
    final lower = method.toLowerCase();
    if (lower.contains('fib')) {
      return Gateway.FIB;
    } else if (lower.contains('fastpay') || lower.contains('فاستپەی')) {
      return Gateway.FAST_PAY;
    } else if (lower.contains('zain') || lower.contains('زەین')) {
      return Gateway.ZAIN;
    } else if (lower.contains('qi') ||
        lower.contains('کی کارد') ||
        lower.contains('card') ||
        lower.contains('stripe') ||
        lower.contains('master') ||
        lower.contains('visa')) {
      return Gateway.CREDIT_CARD;
    }
    return null;
  }

  /// Format amount in integer IQD string for Rasedi
  static String formatAmount(double amount) {
    return amount.round().toString();
  }

  /// Create payment session on Rasedi
  Future<CreatePaymentResponseBody> createPayment({
    required double amount,
    required String title,
    required String description,
    required Gateway gateway,
    String? customerPhone,
    String? customerEmail,
  }) async {
    try {
      final payload = CreatePaymentPayload(
        amount: formatAmount(amount),
        title: title,
        description: description,
        gateways: [gateway],
        redirectUrl: redirectUrl,
        callbackUrl: callbackUrl,
        collectFeeFromCustomer: false,
        collectCustomerEmail: customerEmail != null && customerEmail.isNotEmpty,
        collectCustomerPhoneNumber:
            customerPhone != null && customerPhone.isNotEmpty,
      );

      final response = await _client.createPayment(payload);
      return response.body;
    } catch (e) {
      debugPrint("Rasedi createPayment error: $e");
      rethrow;
    }
  }

  /// Check payment status by reference code
  Future<PaymentStatus> checkPaymentStatus(String referenceCode) async {
    try {
      final response = await _client.getPaymentByReference(referenceCode);
      return response.body.status;
    } catch (e) {
      debugPrint("Rasedi checkPaymentStatus error: $e");
      rethrow;
    }
  }

  /// Cancel payment session
  Future<bool> cancelPayment(String referenceCode) async {
    try {
      final response = await _client.cancelPayment(referenceCode);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Rasedi cancelPayment error: $e");
      return false;
    }
  }
}
