import 'package:dr_room/core/utils/api_client.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import '../config/app_config.dart';

/// Mirrors the `doctors` table as returned by `GET /api/doctors`.
///
/// The endpoint returns a bare array of Doctor rows with the owning `user`
/// eager-loaded, so the display name lives at `user.name`, not on the row
/// itself. Field names here match the migration exactly — `specialty`,
/// `experience_years`, `total_reviews`, `image_path` — because an earlier
/// version guessed at them and every value came back empty.
class Doctor {
  final int id;
  final int userId;
  final String name;
  final String specialty;
  final String bio;
  final double rating;
  final int totalReviews;
  final double consultationFee;
  final int experienceYears;
  final String phone;
  final List<String> availableDays;

  /// Storage-relative path, e.g. `doctors/abc.jpg`. Use [imageUrl].
  final String? imagePath;

  const Doctor({
    required this.id,
    required this.userId,
    required this.name,
    required this.specialty,
    required this.bio,
    required this.rating,
    required this.totalReviews,
    required this.consultationFee,
    required this.experienceYears,
    required this.phone,
    required this.availableDays,
    this.imagePath,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id']),
      // Eager-loaded relation; falls back to a flat `name` if a future
      // endpoint flattens it.
      name: (json['user']?['name'] ?? json['name'] ?? '') as String,
      specialty: (json['specialty'] ?? '') as String,
      bio: (json['bio'] ?? '') as String,
      rating: _asDouble(json['rating']),
      totalReviews: _asInt(json['total_reviews']),
      consultationFee: _asDouble(json['consultation_fee']),
      experienceYears: _asInt(json['experience_years']),
      phone: (json['phone'] ?? '') as String,
      availableDays: _asStringList(json['available_days']),
      imagePath: json['image_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'specialty': specialty,
    'bio': bio,
    'rating': rating,
    'total_reviews': totalReviews,
    'consultation_fee': consultationFee,
    'experience_years': experienceYears,
    'phone': phone,
    'available_days': availableDays,
    'image_path': imagePath,
  };

  /// Absolute URL for the profile photo, or null when none is set.
  String? get imageUrl => (imagePath == null || imagePath!.isEmpty)
      ? null
      : ApiClient.getImageUrl(imagePath!);

  String get formattedFee => '\$${consultationFee.toStringAsFixed(0)}';
}

/// Mirrors the `appointments` table.
///
/// The schema stores a single `appointment_date` datetime — there is no
/// separate slot date and time, and no slot table — plus `fee`, `type`,
/// `notes` and `status`.
class Appointment {
  final int id;
  final int doctorId;
  final int patientId;
  final DateTime appointmentDate;
  final double fee;
  final AppointmentType type;
  final String? notes;
  final AppointmentStatus status;

  /// Present when the API eager-loads `doctor.user`.
  final String doctorName;
  final String doctorSpecialty;
  final String? doctorImagePath;

  const Appointment({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.appointmentDate,
    required this.fee,
    required this.type,
    this.notes,
    required this.status,
    required this.doctorName,
    required this.doctorSpecialty,
    this.doctorImagePath,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final doctor = json['doctor'] as Map<String, dynamic>?;

    return Appointment(
      id: _asInt(json['id']),
      doctorId: _asInt(json['doctor_id']),
      patientId: _asInt(json['patient_id']),
      appointmentDate: _asDate(json['appointment_date']),
      fee: _asDouble(json['fee']),
      type: AppointmentType.fromApi(json['type'] as String?),
      notes: json['notes'] as String?,
      status: AppointmentStatus.fromApi(json['status'] as String?),
      doctorName: (doctor?['user']?['name'] ?? '') as String,
      doctorSpecialty: (doctor?['specialty'] ?? '') as String,
      doctorImagePath: doctor?['image_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'doctor_id': doctorId,
    'patient_id': patientId,
    'appointment_date': appointmentDate.toIso8601String(),
    'fee': fee,
    'type': type.apiValue,
    'notes': notes,
    'status': status.apiValue,
    'doctor': {
      'specialty': doctorSpecialty,
      'image_path': doctorImagePath,
      'user': {'name': doctorName},
    },
  };

  String? get doctorImageUrl =>
      (doctorImagePath == null || doctorImagePath!.isEmpty)
      ? null
      : ApiClient.getImageUrl(doctorImagePath!);

  String get formattedDate =>
      DateFormat('MMM dd, yyyy').format(appointmentDate);
  String get formattedTime => DateFormat('hh:mm a').format(appointmentDate);
  String get formattedDateTime => '$formattedDate • $formattedTime';
  String get formattedFee => '\$${fee.toStringAsFixed(2)}';

  bool get isUpcoming => appointmentDate.isAfter(DateTime.now());

  /// The API refuses to cancel a completed appointment; mirror that here so
  /// the button is hidden rather than failing with a 422.
  bool get canCancel =>
      status != AppointmentStatus.completed &&
      status != AppointmentStatus.cancelled &&
      isUpcoming;
}

/// `appointments.type` — the API validates `in:in_person,online`.
enum AppointmentType {
  inPerson('in_person'),
  online('online');

  const AppointmentType(this.apiValue);
  final String apiValue;

  static AppointmentType fromApi(String? value) => AppointmentType.values
      .firstWhere((t) => t.apiValue == value, orElse: () => inPerson);

  String get displayName => switch (this) {
    AppointmentType.inPerson => 'In person',
    AppointmentType.online => 'Online',
  };

  String get kurdiName => switch (this) {
    AppointmentType.inPerson => 'سەردانی نۆرینگە',
    AppointmentType.online => 'ڕاوێژی ئۆنلاین',
  };
}

/// `appointments.status` — the API validates
/// `in:pending,confirmed,cancelled,completed`. Note the British spelling of
/// "cancelled"; the backend is the source of truth for these strings.
enum AppointmentStatus {
  pending('pending'),
  confirmed('confirmed'),
  cancelled('cancelled'),
  completed('completed');

  const AppointmentStatus(this.apiValue);
  final String apiValue;

  static AppointmentStatus fromApi(String? value) => AppointmentStatus.values
      .firstWhere((s) => s.apiValue == value, orElse: () => pending);

  String get displayName => switch (this) {
    AppointmentStatus.pending => 'Pending',
    AppointmentStatus.confirmed => 'Confirmed',
    AppointmentStatus.cancelled => 'Cancelled',
    AppointmentStatus.completed => 'Completed',
  };

  String get kurdiName => switch (this) {
    AppointmentStatus.pending => 'چاوەڕوانکراو',
    AppointmentStatus.confirmed => 'پەسەندکراو',
    AppointmentStatus.cancelled => 'هەڵوەشاوە',
    AppointmentStatus.completed => 'تەواوکراو',
  };

  Color get color => switch (this) {
    AppointmentStatus.pending => const Color(0xFFF39C12),
    AppointmentStatus.confirmed => const Color(0xFF2E86DE),
    AppointmentStatus.cancelled => const Color(0xFFEF4444),
    AppointmentStatus.completed => const Color(0xFF27AE60),
  };
}

// ── Coercion helpers ────────────────────────────────────────────────────────
// Laravel serialises decimals as strings ("50.00") and ids can arrive as
// either int or string depending on the driver, so parse defensively.

int _asInt(dynamic value) => switch (value) {
  int v => v,
  num v => v.toInt(),
  String v => int.tryParse(v) ?? 0,
  _ => 0,
};

double _asDouble(dynamic value) => switch (value) {
  double v => v,
  num v => v.toDouble(),
  String v => double.tryParse(v) ?? 0,
  _ => 0,
};

DateTime _asDate(dynamic value) => value is String
    ? (DateTime.tryParse(value) ?? DateTime.now())
    : DateTime.now();

List<String> _asStringList(dynamic value) => switch (value) {
  List v => v.map((e) => e.toString()).toList(),
  String v when v.isNotEmpty => [v],
  _ => <String>[],
};
