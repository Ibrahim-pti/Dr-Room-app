import 'package:flutter/material.dart';

import '../models/appointment_model.dart';
import '../services/appointment_service.dart';

class AppointmentProvider extends ChangeNotifier {
  AppointmentProvider({AppointmentService? service})
      : _service = service ?? AppointmentService();

  final AppointmentService _service;

  List<Doctor> _doctors = [];
  List<Appointment> _appointments = [];
  Doctor? _selectedDoctor;
  Appointment? _lastBooked;
  bool _isLoading = false;
  String? _error;

  List<Doctor> get doctors => _doctors;
  List<Appointment> get appointments => _appointments;
  Doctor? get selectedDoctor => _selectedDoctor;
  Appointment? get lastBooked => _lastBooked;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Appointment> get upcomingAppointments =>
      _appointments.where((a) => a.isUpcoming).toList();

  /// Runs [action], funnelling loading state and errors into the UI.
  /// Returns true when it completed without throwing.
  Future<bool> _run(Future<void> Function() action) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await action();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> fetchDoctors({
    String? search,
    String? specialty,
    double? minRating,
  }) =>
      _run(() async {
        _doctors = await _service.getDoctors(
          search: search,
          specialty: specialty,
          minRating: minRating,
        );
      });

  Future<bool> fetchAppointments({AppointmentStatus? status}) => _run(() async {
        _appointments = await _service.getAppointments(status: status);
      });

  /// Books with the currently selected doctor.
  ///
  /// [when] must carry both the day and the time — the backend stores a single
  /// `appointment_date` and rejects anything not in the future.
  Future<bool> bookAppointment({
    required DateTime when,
    AppointmentType type = AppointmentType.inPerson,
    String? notes,
  }) {
    final doctor = _selectedDoctor;
    if (doctor == null) {
      _error = 'Choose a doctor first';
      notifyListeners();
      return Future.value(false);
    }

    return _run(() async {
      _lastBooked = await _service.bookAppointment(
        doctorId: doctor.id,
        when: when,
        type: type,
        notes: notes,
      );
      _appointments = [_lastBooked!, ..._appointments];
    });
  }

  Future<bool> cancelAppointment(int appointmentId) => _run(() async {
        await _service.cancelAppointment(appointmentId);
        _appointments = _appointments
            .where((a) => a.id != appointmentId)
            .toList(growable: false);
      });

  void selectDoctor(Doctor doctor) {
    _selectedDoctor = doctor;
    _error = null;
    notifyListeners();
  }

  void clearSelection() {
    _selectedDoctor = null;
    _lastBooked = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
