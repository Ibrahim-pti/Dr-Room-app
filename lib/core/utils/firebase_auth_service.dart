import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'phone_utils.dart';

/// Wraps Firebase Phone Auth so login/register/OTP screens share one path
/// for sending the SMS code and finishing the sign-in against our own
/// Laravel backend (which owns roles/status and issues the session token).
class FirebaseAuthService {
  FirebaseAuthService._();

  /// Starts phone verification for [localPhone] (11-digit, leading 0).
  ///
  /// [onCodeSent] fires once Firebase has dispatched the SMS — the caller
  /// should show the OTP screen with the given verificationId.
  ///
  /// [onAutoVerified] fires when the OS confirms the number itself (Android
  /// instant verification, no code typed) — the caller should finish the
  /// sign-in flow directly without showing the OTP screen.
  static Future<void> sendOtp({
    required String localPhone,
    required void Function(String verificationId) onCodeSent,
    required void Function(String role) onAutoVerified,
    required void Function(String message) onFailed,
  }) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: toE164IraqPhone(localPhone),
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final role = await _finishSignIn(localPhone, credential);
          onAutoVerified(role);
        } catch (e) {
          onFailed(e.toString());
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        onFailed(e.message ?? e.code);
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  /// Confirms the 6-digit code the user typed on the OTP screen.
  static Future<String> confirmCode({
    required String localPhone,
    required String verificationId,
    required String smsCode,
  }) {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _finishSignIn(localPhone, credential);
  }

  static Future<String> _finishSignIn(
    String localPhone,
    PhoneAuthCredential credential,
  ) async {
    final userCredential = await FirebaseAuth.instance.signInWithCredential(
      credential,
    );
    final idToken = await userCredential.user!.getIdToken();

    final response = await ApiClient.post(
      '/verify-firebase-otp',
      body: {'phone': localPhone, 'firebase_id_token': idToken},
    );

    // The app's session lives in the Laravel Sanctum token, not Firebase —
    // sign out of Firebase once we've exchanged the ID token for it.
    await FirebaseAuth.instance.signOut();

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'verification failed');
    }

    final data = jsonDecode(response.body);
    final token = data['access_token'];
    final role = data['user']['role'] ?? 'patient';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_role', role);
    await prefs.setString('user_name', data['user']['name'] ?? '');
    await prefs.setString('user_phone', data['user']['phone'] ?? '');

    return role;
  }
}
