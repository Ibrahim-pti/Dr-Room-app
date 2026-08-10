import 'dart:convert';

import '../models/appointment_model.dart';
import '../utils/api_client.dart';

/// Talks to the appointment and doctor endpoints that actually exist.
///
/// The backend currently exposes only:
///   GET    /doctors            — bare array, optional ?specialty=
///   GET    /appointments       — { data: [...], total: n }
///   POST   /appointments       — doctor_id, appointment_date, type, notes
///   DELETE /appointments/{id}  — cancels (sets status=cancelled)
///
/// There is no per-doctor detail, reviews, or availability endpoint and no
/// slot table, so this class deliberately does not pretend to offer them.
/// Search and rating filters are applied client-side for the same reason.
class AppointmentService {
  /// Fetches doctors, optionally narrowed by specialty server-side.
  ///
  /// [search] and [minRating] are filtered locally because `GET /doctors`
  /// supports neither.
  Future<List<Doctor>> getDoctors({
    String? search,
    String? specialty,
    double? minRating,
  }) async {
    final endpoint = (specialty == null || specialty.isEmpty)
        ? '/doctors'
        : '/doctors?specialty=${Uri.encodeQueryComponent(specialty)}';

    final response = await ApiClient.get(endpoint);

    if (response.statusCode != 200) {
      throw ApiException.fromResponse(response, 'Could not load doctors');
    }

    final decoded = jsonDecode(response.body);
    // The endpoint returns a bare array; tolerate a wrapped shape in case it
    // is paginated later.
    final rows = decoded is List ? decoded : (decoded['data'] as List? ?? []);

    var doctors = rows
        .cast<Map<String, dynamic>>()
        .map(Doctor.fromJson)
        .toList();

    if (search != null && search.trim().isNotEmpty) {
      final needle = search.trim().toLowerCase();
      doctors = doctors
          .where((d) =>
              d.name.toLowerCase().contains(needle) ||
              d.specialty.toLowerCase().contains(needle))
          .toList();
    }

    if (minRating != null) {
      doctors = doctors.where((d) => d.rating >= minRating).toList();
    }

    return doctors;
  }

  /// The patient's own appointments, newest first.
  Future<List<Appointment>> getAppointments({AppointmentStatus? status}) async {
    final endpoint = status == null
        ? '/appointments'
        : '/appointments?status=${status.apiValue}';

    final response = await ApiClient.get(endpoint);

    if (response.statusCode != 200) {
      throw ApiException.fromResponse(response, 'Could not load appointments');
    }

    final rows = jsonDecode(response.body)['data'] as List? ?? [];
    return rows.cast<Map<String, dynamic>>().map(Appointment.fromJson).toList();
  }

  /// Books an appointment.
  ///
  /// The API validates `appointment_date` as a single datetime that must be in
  /// the future, so [when] carries both the day and the time.
  Future<Appointment> bookAppointment({
    required int doctorId,
    required DateTime when,
    AppointmentType type = AppointmentType.inPerson,
    String? notes,
  }) async {
    final response = await ApiClient.post(
      '/appointments',
      body: {
        'doctor_id': doctorId,
        // Laravel's `date` rule parses ISO-8601; send local time without the
        // trailing Z so "after:now" compares against the same wall clock.
        'appointment_date': _formatForApi(when),
        'type': type.apiValue,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw ApiException.fromResponse(response, 'Could not book the appointment');
    }

    return Appointment.fromJson(jsonDecode(response.body)['appointment']);
  }

  /// Cancels an appointment. The API rejects this for completed appointments.
  Future<void> cancelAppointment(int appointmentId) async {
    final response = await ApiClient.delete('/appointments/$appointmentId');

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException.fromResponse(response, 'Could not cancel the appointment');
    }
  }

  /// `2026-08-15 14:30:00` — the format Laravel's validator and the
  /// `appointment_date` column both accept.
  static String _formatForApi(DateTime when) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${when.year}-${two(when.month)}-${two(when.day)} '
        '${two(when.hour)}:${two(when.minute)}:00';
  }
}

/// Carries the server's own message so the UI can show why a call failed
/// instead of a generic error.
class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  factory ApiException.fromResponse(dynamic response, String fallback) {
    String message = fallback;

    try {
      final body = jsonDecode(response.body);
      if (body is Map) {
        // Laravel returns {message, errors:{field:[...]}} on a 422.
        final errors = body['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          message = first is List && first.isNotEmpty
              ? first.first.toString()
              : errors.values.first.toString();
        } else if (body['message'] is String) {
          message = body['message'] as String;
        }
      }
    } catch (_) {
      // Body was not JSON; keep the fallback.
    }

    return ApiException(response.statusCode as int, message);
  }

  @override
  String toString() => message;
}
