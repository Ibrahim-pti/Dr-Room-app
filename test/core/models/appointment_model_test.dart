import 'package:flutter_test/flutter_test.dart';
import 'package:dr_room/core/models/appointment_model.dart';

/// These tests pin the models to the real backend contract.
///
/// The fixtures below mirror what Laravel actually returns:
///   GET /api/doctors      — bare array of `doctors` rows with `user` loaded
///   GET /api/appointments — { data: [...] } of `appointments` rows
///
/// An earlier version of these models guessed field names (`speciality`,
/// `years_experience`, `slot_date`) and every value silently came back empty,
/// so the exact snake_case keys matter.
void main() {
  group('Doctor.fromJson', () {
    Map<String, dynamic> doctorRow() => {
          'id': 7,
          'user_id': 21,
          'specialty': 'Cardiology',
          'bio': 'Interventional cardiologist.',
          'rating': 4.8,
          'total_reviews': 150,
          // Laravel serialises decimal columns as strings.
          'consultation_fee': '50.00',
          'experience_years': 10,
          'phone': '+9647701234567',
          'available_days': ['Mon', 'Wed', 'Thu'],
          'image_path': 'doctors/abc.jpg',
          'user': {'id': 21, 'name': 'Dr. Ahmed', 'email': 'a@example.com'},
        };

    test('reads the name from the eager-loaded user relation', () {
      expect(Doctor.fromJson(doctorRow()).name, 'Dr. Ahmed');
    });

    test('reads the snake_case columns the migration defines', () {
      final doctor = Doctor.fromJson(doctorRow());

      expect(doctor.id, 7);
      expect(doctor.userId, 21);
      expect(doctor.specialty, 'Cardiology');
      expect(doctor.experienceYears, 10);
      expect(doctor.totalReviews, 150);
      expect(doctor.rating, 4.8);
      expect(doctor.availableDays, ['Mon', 'Wed', 'Thu']);
    });

    test('parses a decimal fee delivered as a string', () {
      expect(Doctor.fromJson(doctorRow()).consultationFee, 50.0);
      expect(Doctor.fromJson(doctorRow()).formattedFee, r'$50');
    });

    test('builds an absolute image URL from the storage path', () {
      final url = Doctor.fromJson(doctorRow()).imageUrl;

      expect(url, isNotNull);
      expect(url, endsWith('/storage/doctors/abc.jpg'));
    });

    test('imageUrl is null when the doctor has no photo', () {
      expect(Doctor.fromJson({...doctorRow(), 'image_path': null}).imageUrl,
          isNull);
      expect(
          Doctor.fromJson({...doctorRow(), 'image_path': ''}).imageUrl, isNull);
    });

    test('survives a row with every optional field missing', () {
      final doctor = Doctor.fromJson({});

      expect(doctor.id, 0);
      expect(doctor.name, '');
      expect(doctor.consultationFee, 0.0);
      expect(doctor.availableDays, isEmpty);
      expect(doctor.imageUrl, isNull);
    });
  });

  group('Appointment.fromJson', () {
    Map<String, dynamic> appointmentRow({
      String status = 'confirmed',
      String? date,
      String type = 'in_person',
    }) =>
        {
          'id': 42,
          'doctor_id': 7,
          'patient_id': 3,
          'appointment_date':
              date ?? DateTime.now().add(const Duration(days: 3)).toIso8601String(),
          'fee': '50.00',
          'type': type,
          'notes': 'Chest pain',
          'status': status,
          'doctor': {
            'id': 7,
            'specialty': 'Cardiology',
            'image_path': 'doctors/abc.jpg',
            'user': {'id': 21, 'name': 'Dr. Ahmed'},
          },
        };

    test('parses the four statuses the API validates', () {
      for (final status in AppointmentStatus.values) {
        final parsed =
            Appointment.fromJson(appointmentRow(status: status.apiValue)).status;
        expect(parsed, status, reason: status.apiValue);
      }
    });

    test('uses the British "cancelled" spelling the backend sends', () {
      expect(AppointmentStatus.cancelled.apiValue, 'cancelled');
      expect(Appointment.fromJson(appointmentRow(status: 'cancelled')).status,
          AppointmentStatus.cancelled);
    });

    test('falls back to pending for an unrecognised status', () {
      expect(Appointment.fromJson(appointmentRow(status: 'nope')).status,
          AppointmentStatus.pending);
    });

    test('parses both visit types and defaults to in person', () {
      expect(Appointment.fromJson(appointmentRow(type: 'online')).type,
          AppointmentType.online);
      expect(Appointment.fromJson(appointmentRow(type: 'in_person')).type,
          AppointmentType.inPerson);
      expect(Appointment.fromJson(appointmentRow(type: 'carrier_pigeon')).type,
          AppointmentType.inPerson);
    });

    test('flattens the nested doctor relation', () {
      final appointment = Appointment.fromJson(appointmentRow());

      expect(appointment.doctorName, 'Dr. Ahmed');
      expect(appointment.doctorSpecialty, 'Cardiology');
      expect(appointment.doctorImageUrl, endsWith('/storage/doctors/abc.jpg'));
    });

    test('parses a fee delivered as a string', () {
      expect(Appointment.fromJson(appointmentRow()).fee, 50.0);
    });

    group('canCancel', () {
      test('is true for an upcoming pending or confirmed appointment', () {
        expect(Appointment.fromJson(appointmentRow(status: 'confirmed')).canCancel,
            isTrue);
        expect(Appointment.fromJson(appointmentRow(status: 'pending')).canCancel,
            isTrue);
      });

      test('is false once the appointment is in the past', () {
        final past = appointmentRow(
          date: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        );
        expect(Appointment.fromJson(past).isUpcoming, isFalse);
        expect(Appointment.fromJson(past).canCancel, isFalse);
      });

      test('is false for completed, matching the API which returns 422', () {
        expect(Appointment.fromJson(appointmentRow(status: 'completed')).canCancel,
            isFalse);
      });

      test('is false for an already cancelled appointment', () {
        expect(Appointment.fromJson(appointmentRow(status: 'cancelled')).canCancel,
            isFalse);
      });
    });

    test('survives a row with every optional field missing', () {
      final appointment = Appointment.fromJson({});

      expect(appointment.id, 0);
      expect(appointment.fee, 0.0);
      expect(appointment.status, AppointmentStatus.pending);
      expect(appointment.type, AppointmentType.inPerson);
      expect(appointment.doctorName, '');
      expect(appointment.doctorImageUrl, isNull);
    });

    test('round-trips through toJson', () {
      final original = Appointment.fromJson(appointmentRow());
      final restored = Appointment.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.status, original.status);
      expect(restored.type, original.type);
      expect(restored.fee, original.fee);
      expect(restored.doctorName, original.doctorName);
    });
  });

  group('labels', () {
    test('every status and type has an English and a Kurdish label', () {
      for (final status in AppointmentStatus.values) {
        expect(status.displayName, isNotEmpty);
        expect(status.kurdiName, isNotEmpty);
      }
      for (final type in AppointmentType.values) {
        expect(type.displayName, isNotEmpty);
        expect(type.kurdiName, isNotEmpty);
      }
    });
  });
}
