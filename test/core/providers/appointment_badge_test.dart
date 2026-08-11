import 'package:dr_room/core/models/appointment_model.dart';
import 'package:dr_room/core/providers/appointment_provider.dart';
import 'package:dr_room/core/services/appointment_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Serves a fixed list so the badge arithmetic can be checked without a server.
class _StubAppointmentService implements AppointmentService {
  _StubAppointmentService(this.appointments);

  final List<Appointment> appointments;

  @override
  Future<List<Appointment>> getAppointments({AppointmentStatus? status}) async =>
      appointments;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> appointmentJson({
  required int id,
  required DateTime when,
  String status = 'confirmed',
}) {
  return {
    'id': id,
    'doctor_id': 1,
    'patient_id': 1,
    'appointment_date': when.toIso8601String(),
    'fee': 100,
    'status': status,
    'type': 'in_person',
  };
}

void main() {
  final future = DateTime.now().add(const Duration(days: 3));
  final past = DateTime.now().subtract(const Duration(days: 3));

  group('activeAppointmentCount', () {
    test('counts upcoming appointments the patient is waiting on', () async {
      final provider = AppointmentProvider(
        service: _StubAppointmentService([
          Appointment.fromJson(appointmentJson(id: 1, when: future)),
          Appointment.fromJson(
              appointmentJson(id: 2, when: future, status: 'pending')),
        ]),
      );

      await provider.fetchAppointments();

      expect(provider.activeAppointmentCount, 2);
    });

    test('ignores appointments already in the past', () async {
      final provider = AppointmentProvider(
        service: _StubAppointmentService([
          Appointment.fromJson(appointmentJson(id: 1, when: past)),
          Appointment.fromJson(appointmentJson(id: 2, when: future)),
        ]),
      );

      await provider.fetchAppointments();

      expect(provider.activeAppointmentCount, 1);
    });

    // A cancelled appointment is still in the future by date, so counting
    // upcoming ones alone would leave a badge for something already called off.
    test('ignores a cancelled appointment even though it is upcoming', () async {
      final provider = AppointmentProvider(
        service: _StubAppointmentService([
          Appointment.fromJson(
              appointmentJson(id: 1, when: future, status: 'cancelled')),
          Appointment.fromJson(appointmentJson(id: 2, when: future)),
        ]),
      );

      await provider.fetchAppointments();

      expect(provider.upcomingAppointments.length, 2);
      expect(provider.activeAppointmentCount, 1);
    });
  });
}
