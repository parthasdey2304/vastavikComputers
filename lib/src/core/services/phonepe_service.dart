import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import '../config/secrets.dart';

/// Result of a PhonePe payment attempt.
class PhonePeResult {
  final bool success;
  final String message;
  final String? transactionId;
  final String? providerReferenceId;

  const PhonePeResult({
    required this.success,
    required this.message,
    this.transactionId,
    this.providerReferenceId,
  });
}

/// Client-side PhonePe integration.
///
/// Flow (PhonePe "Standard Checkout"):
/// 1. Build base64 payload + X-VERIFY header (SHA256 of payload + saltKey).
/// 2. POST to PhonePe `/pg/v1/pay` (sandbox or prod based on [Secrets.phonePeIsSandbox]).
/// 3. PhonePe responds with a payment page URL → open it (WebView/browser).
/// 4. After redirect, verify via Cloud Function ([Secrets.phonePeVerifyUrl]).
///
/// NOTE: Never ship with real salt keys compiled into release builds — keep
/// sandbox=true during development and rotate keys via env/config at release.
class PhonePeService {
  late final Dio _dio;

  PhonePeService() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }

  String get _baseUrl => Secrets.phonePeIsSandbox
      ? 'https://api-preprod.phonepe.com/apis/pg-sandbox'
      : 'https://api.phonepe.com/apis/hermes';

  String get _merchantId => Secrets.phonePeMerchantId;
  String get _saltKey => Secrets.phonePeSaltKey;
  String get _saltIndex => Secrets.phonePeSaltIndex;

  bool get isConfigured =>
      !_merchantId.contains('YOUR_') && !_saltKey.contains('YOUR_');

  /// Convenience unique ID generator for merchant transaction IDs.
  static String newTransactionId() =>
      'MT${DateTime.now().millisecondsSinceEpoch}';

  /// Convenience unique ID generator for merchant subscription IDs.
  static String newSubscriptionId() =>
      'MS${DateTime.now().millisecondsSinceEpoch}';

  /// Computes X-VERIFY checksum required by PhonePe.
  String _computeXVerify(String base64Payload, String path) {
    final input = '$base64Payload$path$_saltKey';
    final digest = sha256.convert(utf8.encode(input)).toString();
    return '$digest###$_saltIndex';
  }

  /// Step 1: Create a payment. Returns the pay-page URL on success.
  Future<PhonePeResult> createPayment({
    required String merchantTransactionId,
    required String merchantUserId,
    required double amountRupees,
    required String callbackUrl,
    required String redirectUrl,
    String? mobileNumber,
  }) async {
    if (!isConfigured) {
      return const PhonePeResult(
        success: false,
        message:
            'PhonePe is not configured. Fill phonePeMerchantId & phonePeSaltKey in secrets.dart',
      );
    }

    final amountPaise = (amountRupees * 100).round();
    final payload = {
      'merchantId': _merchantId,
      'merchantTransactionId': merchantTransactionId,
      'merchantUserId': merchantUserId,
      'amount': amountPaise,
      'redirectUrl': redirectUrl,
      'redirectMode': 'REDIRECT',
      'callbackUrl': callbackUrl,
      'paymentInstrument': {'type': 'PAY_PAGE'},
      if (mobileNumber != null) 'mobileNumber': mobileNumber,
    };

    final base64Payload = base64Encode(utf8.encode(jsonEncode(payload)));
    final xVerify = _computeXVerify(base64Payload, '/pg/v1/pay');

    try {
      final response = await _dio.post(
        '$_baseUrl/pg/v1/pay',
        data: {'request': base64Payload},
        options: Options(headers: {'X-VERIFY': xVerify}),
      );

      final data = response.data;
      if (data is Map && data['success'] == true) {
        final instrument = data['data']?['instrumentResponse'];
        final redirectInfo = instrument?['redirectInfo'];
        final url = redirectInfo?['url']?.toString();
        if (url != null && url.isNotEmpty) {
          return PhonePeResult(
            success: true,
            message: 'Payment page ready',
            transactionId: merchantTransactionId,
            providerReferenceId: url,
          );
        }
        return PhonePeResult(
          success: false,
          message: 'No redirect URL returned by PhonePe.',
          transactionId: merchantTransactionId,
        );
      }
      return PhonePeResult(
        success: false,
        message: data?['message']?.toString() ?? 'PhonePe rejected the request.',
        transactionId: merchantTransactionId,
      );
    } on DioException catch (e) {
      return PhonePeResult(
        success: false,
        message: e.response?.data is Map
            ? (e.response?.data['message']?.toString() ??
                'Network error: ${e.message}')
            : 'Network error: ${e.message}',
        transactionId: merchantTransactionId,
      );
    } catch (e) {
      return PhonePeResult(
        success: false,
        message: 'Unexpected error: $e',
        transactionId: merchantTransactionId,
      );
    }
  }

  /// Step 2 (fallback): Check payment status server-to-server. In production
  /// do this from your Cloud Function; kept here for sandbox testing.
  Future<PhonePeResult> checkStatus({
    required String merchantTransactionId,
  }) async {
    if (!isConfigured) {
      return const PhonePeResult(
        success: false,
        message: 'PhonePe is not configured.',
      );
    }
    final path =
        '/pg/v1/status/$_merchantId/$merchantTransactionId';
    final input = path + _saltKey;
    final digest = sha256.convert(utf8.encode(input)).toString();
    final xVerify = '$digest###$_saltIndex';

    try {
      final response = await _dio.get(
        '$_baseUrl$path',
        options: Options(headers: {
          'X-VERIFY': xVerify,
          'X-MERCHANT-ID': _merchantId,
        }),
      );
      final data = response.data;
      final state = data?['data']?['state']?.toString();
      final success = data?['success'] == true && state == 'COMPLETED';
      return PhonePeResult(
        success: success,
        message: data?['message']?.toString() ?? state ?? 'Unknown',
        transactionId: merchantTransactionId,
        providerReferenceId:
            data?['data']?['providerReferenceId']?.toString(),
      );
    } on DioException catch (e) {
      return PhonePeResult(
        success: false,
        message: 'Status check failed: ${e.message}',
        transactionId: merchantTransactionId,
      );
    }
  }

  /// Phase 3: Create a recurring UPI mandate (monthly auto-debit / EMI).
  ///
  /// Returns a PhonePe redirect URL the user must open to approve the mandate
  /// via UPI PIN/OTP. Amount is charged automatically each [intervalMonths].
  Future<PhonePeResult> createSubscription({
    required String merchantSubscriptionId,
    required String merchantUserId,
    required double amountRupees,
    required int intervalMonths,
    required int totalMonths,
    required String callbackUrl,
    required String redirectUrl,
    String? mobileNumber,
  }) async {
    if (!isConfigured) {
      return const PhonePeResult(
        success: false,
        message:
            'PhonePe is not configured. Fill phonePeMerchantId & phonePeSaltKey in secrets.dart',
      );
    }

    final amountPaise = (amountRupees * 100).round();
    final end = DateTime.now().add(Duration(days: totalMonths * 30));
    final endDate = end.toUtc().toIso8601String().substring(0, 10);

    final payload = {
      'merchantId': _merchantId,
      'merchantUserId': merchantUserId,
      'merchantSubscriptionId': merchantSubscriptionId,
      'amount': amountPaise,
      'recurringPaymentDetail': {
        'interval': 'MONTH',
        'frequency': intervalMonths,
        'endDate': endDate,
      },
      'paymentInstrument': {
        'type': 'UPI_MANDATE',
        'isUpiIntentMode': true,
        'isUpiCollectMode': false,
      },
      'authFlow': 'OTP',
      'returnUrl': redirectUrl,
      'redirectMode': 'REDIRECT',
      'callbackUrl': callbackUrl,
      if (mobileNumber != null) 'mobileNumber': mobileNumber,
    };

    final base64Payload = base64Encode(utf8.encode(jsonEncode(payload)));
    final xVerify = _computeXVerify(base64Payload, '/pg/v1/subscriptions');

    try {
      final response = await _dio.post(
        '$_baseUrl/pg/v1/subscriptions',
        data: {'request': base64Payload},
        options: Options(headers: {'X-VERIFY': xVerify}),
      );

      final data = response.data;
      if (data is Map && data['success'] == true) {
        final redirect = data['data']?['redirectUrl']?.toString();
        if (redirect != null && redirect.isNotEmpty) {
          return PhonePeResult(
            success: true,
            message: 'Mandate approval page ready',
            transactionId: merchantSubscriptionId,
            providerReferenceId: redirect,
          );
        }
        return PhonePeResult(
          success: false,
          message: 'No redirect URL returned by PhonePe for mandate.',
          transactionId: merchantSubscriptionId,
        );
      }
      return PhonePeResult(
        success: false,
        message: data?['message']?.toString() ?? 'PhonePe rejected the mandate request.',
        transactionId: merchantSubscriptionId,
      );
    } on DioException catch (e) {
      return PhonePeResult(
        success: false,
        message: e.response?.data is Map
            ? (e.response?.data['message']?.toString() ?? 'Network error: ${e.message}')
            : 'Network error: ${e.message}',
        transactionId: merchantSubscriptionId,
      );
    } catch (e) {
      return PhonePeResult(
        success: false,
        message: 'Unexpected error: $e',
        transactionId: merchantSubscriptionId,
      );
    }
  }
}
