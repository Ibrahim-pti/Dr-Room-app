import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math';

class HealthProvider extends ChangeNotifier {
  bool _isSynced = false;
  bool _isLoading = false;

  int _steps = 0;
  int _heartRate = 0;
  int _calories = 0;
  String _sleepTime = '0h 0m';

  // Activity data for the week (0.0 to 1.0)
  List<double> _weeklyActivity = List.filled(7, 0.0);

  bool get isSynced => _isSynced;
  bool get isLoading => _isLoading;
  
  int get steps => _steps;
  int get heartRate => _heartRate;
  int get calories => _calories;
  String get sleepTime => _sleepTime;
  List<double> get weeklyActivity => _weeklyActivity;

  Future<void> toggleSync(bool value) async {
    if (value == _isSynced) return;

    if (value) {
      // Simulating connection to Apple Health / Google Fit
      _isLoading = true;
      notifyListeners();

      await Future.delayed(const Duration(seconds: 2));

      _isSynced = true;
      _isLoading = false;
      _generateRealisticData();
    } else {
      _isSynced = false;
      _clearData();
    }
    notifyListeners();
  }

  void _generateRealisticData() {
    final random = Random();
    
    // Steps between 4,000 and 12,000
    _steps = 4000 + random.nextInt(8000);
    
    // Heart rate between 60 and 95
    _heartRate = 60 + random.nextInt(35);
    
    // Calories between 1,200 and 2,500
    _calories = 1200 + random.nextInt(1300);
    
    // Sleep between 5h and 8h
    int sleepHours = 5 + random.nextInt(4);
    int sleepMinutes = random.nextInt(60);
    _sleepTime = '${sleepHours}h ${sleepMinutes}m';

    // Generate weekly activity
    _weeklyActivity = List.generate(7, (index) => 0.3 + (random.nextDouble() * 0.7));
  }

  void _clearData() {
    _steps = 0;
    _heartRate = 0;
    _calories = 0;
    _sleepTime = '0h 0m';
    _weeklyActivity = List.filled(7, 0.0);
  }
}
