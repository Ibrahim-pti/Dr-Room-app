import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api_client.dart';

class HealthProfile {
  final String? gender;
  final String? bloodType;
  final int? age;

  HealthProfile({
    this.gender,
    this.bloodType,
    this.age,
  });

  Map<String, dynamic> toJson() => {
    'gender': gender,
    'blood_type': bloodType,
    'age': age,
  };

  factory HealthProfile.fromJson(Map<String, dynamic> json) => HealthProfile(
    gender: json['gender'] as String?,
    bloodType: json['blood_type'] as String?,
    age: json['age'] as int?,
  );
}

class HealthProfileService {
  static const String _genderKey = 'user_health_gender';
  static const String _bloodTypeKey = 'user_health_blood_type';
  static const String _ageKey = 'user_health_age';

  /// Onboarding fills the health profile before the user has an account, so
  /// hitting the API there would 401 and bounce them straight to the login
  /// screen via [ApiClient.onUnauthorized].
  static bool _isSignedIn(SharedPreferences prefs) =>
      (prefs.getString('auth_token') ?? '').isNotEmpty;

  static Future<HealthProfile> loadHealthProfile() async {
    final prefs = await SharedPreferences.getInstance();

    final localGender = prefs.getString(_genderKey);
    final localBloodType = prefs.getString(_bloodTypeKey);
    final localAge = prefs.getInt(_ageKey);

    if (localGender != null || localBloodType != null || localAge != null) {
      return HealthProfile(
        gender: localGender,
        bloodType: localBloodType,
        age: localAge,
      );
    }

    if (!_isSignedIn(prefs)) return HealthProfile();

    try {
      final response = await ApiClient.get('/user');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'];
        if (user != null) {
          return HealthProfile.fromJson(user);
        }
      }
    } catch (_) {}

    return HealthProfile();
  }

  static Future<void> saveHealthProfile(HealthProfile profile) async {
    final prefs = await SharedPreferences.getInstance();

    if (profile.gender != null) {
      await prefs.setString(_genderKey, profile.gender!);
    }
    if (profile.bloodType != null) {
      await prefs.setString(_bloodTypeKey, profile.bloodType!);
    }
    if (profile.age != null) {
      await prefs.setInt(_ageKey, profile.age!);
    }

    if (!_isSignedIn(prefs)) return;

    try {
      final body = <String, dynamic>{};
      if (profile.gender != null) body['gender'] = profile.gender;
      if (profile.bloodType != null) body['blood_type'] = profile.bloodType;
      if (profile.age != null) body['age'] = profile.age;

      if (body.isNotEmpty) {
        await ApiClient.put('/user', body: body);
      }
    } catch (_) {}
  }

  static Future<void> clearHealthProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_genderKey);
    await prefs.remove(_bloodTypeKey);
    await prefs.remove(_ageKey);
  }

  static Future<String?> getGender() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_genderKey);
  }

  static Future<String?> getBloodType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_bloodTypeKey);
  }

  static Future<int?> getAge() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_ageKey);
  }
}
