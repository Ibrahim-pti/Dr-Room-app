import 'package:flutter/material.dart';

class FavoriteProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _favoriteDoctors = [];

  List<Map<String, dynamic>> get favoriteDoctors => _favoriteDoctors;

  bool isFavorite(int doctorId) {
    return _favoriteDoctors.any((doc) => doc['id'] == doctorId);
  }

  void toggleFavorite(Map<String, dynamic> doctor) {
    final index = _favoriteDoctors.indexWhere((doc) => doc['id'] == doctor['id']);
    if (index >= 0) {
      _favoriteDoctors.removeAt(index);
    } else {
      _favoriteDoctors.add(doctor);
    }
    notifyListeners();
  }

  /// Called on logout — favourites belong to the patient who chose them.
  void clear() {
    _favoriteDoctors.clear();
    notifyListeners();
  }
}