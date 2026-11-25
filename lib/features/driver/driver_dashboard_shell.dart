import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/driver_earnings_pdf_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_client.dart';
import '../../core/utils/erbil_map_service.dart';
import '../../core/utils/live_route_service.dart';
import '../../main.dart';

class DriverDashboardShell extends StatefulWidget {
  const DriverDashboardShell({super.key});

  @override
  State<DriverDashboardShell> createState() => _DriverDashboardShellState();
}

class _DriverDashboardShellState extends State<DriverDashboardShell> {
  int _tabIndex = 0; // 0: Tasks, 1: Live Map, 2: Earnings, 3: Profile
  int _orderSubTab = 0; // 0: Active, 1: Available Pool, 2: Completed
  int _earningsFilter = 0; // 0: All, 1: Cash, 2: Online
  String? _selectedEarningsMonth;
  bool _isMonthLoading = false;
  bool _isExportingPdf = false;

  bool _isLoading = true;
  bool _isDutyLoading = false;
  String? _error;
  String? _busyOrderId;
  int _unreadNotifications = 0;

  Map<String, dynamic> _driver = {};
  Map<String, dynamic> _stats = {};
  List<dynamic> _activeOrders = [];
  List<dynamic> _availableOrders = [];
  List<dynamic> _completedOrders = [];

  bool _scheduleLoading = false;
  bool _isOnShiftNow = true;
  int _scheduleDayIdx = 0;
  List<Map<String, dynamic>> _driverWeek = [];
  List<Map<String, dynamic>> _driverAvailability = [];
  List<Map<String, dynamic>> _driverUpcoming = [];

  Timer? _refreshTimer;
  Timer? _gpsTimer;
  StreamSubscription<Position>? _positionSub;
  double? _lastLat;
  double? _lastLng;
  double? _lastUploadedLat;
  double? _lastUploadedLng;
  double _lastHeading = 0.0;
  double _lastSpeedMps = 0.0;
  DateTime? _lastGpsSentAt;
  String? _gpsStatusMessage;
  bool _locationPermissionGranted = false;
  bool _followDriver = true;
  bool _hasInitialFitted = false;
  GoogleMapController? _mapController;

  LiveRouteResult? _activeRoute;
  List<LatLng> _secondaryRoutePoints = const [];
  String? _routeCacheSignature;
  BitmapDescriptor? _courierIcon;
  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _patientIcon;

  @override
  void initState() {
    super.initState();
    _initMapIcons();
    _ensureLocationAndFetch();
    _loadDashboard();
    _loadDriverSchedule();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _loadDashboard(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _gpsTimer?.cancel();
    _positionSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initMapIcons() async {
    final icons = await Future.wait([
      LiveRouteService.getCourierMarker(primary: const Color(0xFF2563EB)),
      LiveRouteService.getTargetMarker(color: const Color(0xFFF59E0B), isPickup: true),
      LiveRouteService.getTargetMarker(color: const Color(0xFF10B981), isPickup: false),
    ]);
    if (!mounted) return;
    setState(() {
      _courierIcon = icons[0];
      _pickupIcon = icons[1];
      _patientIcon = icons[2];
    });
  }

  Future<void> _loadDashboard({bool silent = false, String? month}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final activeMonth = month ?? _selectedEarningsMonth;
      final query = (activeMonth != null && activeMonth.isNotEmpty)
          ? '?month=$activeMonth'
          : '';
      final res = await ApiClient.get('/driver/dashboard$query');
      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'] ?? {};
        final driverMap = Map<String, dynamic>.from(data['driver'] ?? {});
        final statsMap = Map<String, dynamic>.from(data['stats'] ?? {});
        final duty = (driverMap['duty_status'] ?? 'offline').toString();

        setState(() {
          _driver = driverMap;
          _stats = statsMap;
          _selectedEarningsMonth =
              month ?? statsMap['selected_month']?.toString() ?? _selectedEarningsMonth;
          _unreadNotifications =
              int.tryParse('${_stats['unread_notifications'] ?? 0}') ?? 0;
          _activeOrders = List<dynamic>.from(data['active_orders'] ?? []);
          _availableOrders = List<dynamic>.from(data['available_orders'] ?? []);
          _completedOrders = List<dynamic>.from(data['completed_orders'] ?? []);
          if (_lastLat == null &&
              _lastLng == null &&
              driverMap['current_lat'] != null &&
              driverMap['current_lng'] != null) {
            _lastLat = double.tryParse(driverMap['current_lat'].toString());
            _lastLng = double.tryParse(driverMap['current_lng'].toString());
          }
          _isLoading = false;
          _isMonthLoading = false;
        });

        _syncGpsTimerForDuty(duty);
        _refreshActiveRoute();
      } else if (!silent) {
        setState(() {
          _error = 'کێشە لە بارکردنی زانیاری کارمەندی گەیاندن ڕوویدا';
          _isLoading = false;
          _isMonthLoading = false;
        });
      } else {
        setState(() => _isMonthLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (!silent) {
            _error = 'کێشەی پەیوەندی بە سێرڤەر: $e';
            _isLoading = false;
          }
          _isMonthLoading = false;
        });
      }
    }
  }

  Future<void> _loadDriverSchedule() async {
    setState(() => _scheduleLoading = true);
    try {
      final res = await ApiClient.get('/driver/schedule');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'] as Map<String, dynamic>? ?? {};
        setState(() {
          _isOnShiftNow = data['is_on_shift_now'] != false;
          _driverWeek = (data['week'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _driverAvailability = (data['availability'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _driverUpcoming = (data['upcoming'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          if (_scheduleDayIdx >= _driverAvailability.length) {
            _scheduleDayIdx = 0;
          }
          _scheduleLoading = false;
        });
      } else {
        setState(() => _scheduleLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _scheduleLoading = false);
    }
  }

  Future<bool> _ensureLocationPermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      if (mounted) {
        setState(() {
          _locationPermissionGranted = false;
          _gpsStatusMessage = 'تکایە GPSـی مۆبایلەکەت هەڵبکە';
        });
      }
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _locationPermissionGranted = false;
          _gpsStatusMessage = 'دەسەڵاتی شوێن (Location) پێویستە';
        });
      }
      return false;
    }

    if (!_locationPermissionGranted && mounted) {
      setState(() {
        _locationPermissionGranted = true;
        _gpsStatusMessage = null;
      });
    } else {
      _locationPermissionGranted = true;
    }
    return true;
  }

  Future<void> _ensureLocationAndFetch() async {
    final ok = await _ensureLocationPermission();
    if (!ok || !mounted) return;

    if (_lastLat == null || _lastLng == null) {
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null && mounted) {
          _onPositionUpdate(last, uploadToServer: false);
        }
      } catch (_) {}
    }

    await _sendCurrentGps();
  }

  void _syncGpsTimerForDuty(String duty) {
    final shouldTrack = duty == 'available' || duty == 'busy';
    if (shouldTrack) {
      _startPositionStream();
      if (_gpsTimer == null || !_gpsTimer!.isActive) {
        _sendCurrentGps();
        _gpsTimer = Timer.periodic(const Duration(seconds: 3), (_) {
          if (mounted) _sendCurrentGps();
        });
      }
    } else {
      _positionSub?.cancel();
      _positionSub = null;
      _gpsTimer?.cancel();
      _gpsTimer = null;
    }
  }

  Future<void> _startPositionStream() async {
    if (_positionSub != null) return;
    final ok = await _ensureLocationPermission();
    if (!ok || !mounted) return;

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3,
      ),
    ).listen(
      (pos) {
        if (!mounted) return;
        _onPositionUpdate(pos, uploadToServer: true);
      },
      onError: (_) {},
    );
  }

  Future<void> _onPositionUpdate(
    Position pos, {
    bool uploadToServer = true,
  }) async {
    final prev = (_lastLat != null && _lastLng != null)
        ? LatLng(_lastLat!, _lastLng!)
        : null;
    final next = LatLng(pos.latitude, pos.longitude);

    double heading = _lastHeading;
    if (pos.heading >= 0 && pos.speed > 0.6) {
      heading = pos.heading;
    } else if (prev != null &&
        Geolocator.distanceBetween(
              prev.latitude,
              prev.longitude,
              next.latitude,
              next.longitude,
            ) >=
            5.0) {
      heading = LiveRouteService.calculateBearing(prev, next);
    }

    if (!mounted) return;
    setState(() {
      _lastLat = pos.latitude;
      _lastLng = pos.longitude;
      _lastHeading = heading;
      _lastSpeedMps = pos.speed;
      _gpsStatusMessage = null;
      _locationPermissionGranted = true;
    });

    if (_tabIndex == 1 && _mapController != null) {
      if (!_hasInitialFitted) {
        _hasInitialFitted = true;
        _fitLiveRouteCamera();
      } else if (_followDriver) {
        _mapController!.animateCamera(CameraUpdate.newLatLng(next));
      }
    }

    _refreshActiveRoute();

    if (!uploadToServer) return;

    final now = DateTime.now();
    final elapsedSec = _lastGpsSentAt != null
        ? now.difference(_lastGpsSentAt!).inSeconds
        : 999;
    final movedSinceUpload = (_lastUploadedLat != null && _lastUploadedLng != null)
        ? Geolocator.distanceBetween(
            _lastUploadedLat!,
            _lastUploadedLng!,
            pos.latitude,
            pos.longitude,
          )
        : 999.0;

    if (elapsedSec >= 3 || movedSinceUpload >= 5.0) {
      await _uploadLocationToServer(pos);
    }
  }

  Future<void> _uploadLocationToServer(Position pos) async {
    try {
      final res = await ApiClient.post(
        '/driver/location',
        body: {
          'lat': pos.latitude,
          'lng': pos.longitude,
          'speed': pos.speed,
          'heading': pos.heading >= 0 ? pos.heading : _lastHeading,
        },
      );

      if (!mounted) return;
      if (res.statusCode == 200) {
        _lastUploadedLat = pos.latitude;
        _lastUploadedLng = pos.longitude;
        _lastGpsSentAt = DateTime.now();

        final decoded = jsonDecode(res.body);
        final autoUpdates = decoded is Map ? decoded['auto_updates'] : null;
        if (autoUpdates is List && autoUpdates.isNotEmpty) {
          final first = autoUpdates.first;
          final toStage = first is Map ? first['to']?.toString() : null;
          if (toStage != null) {
            final label = _deliveryStageLabel(toStage, false);
            _toast('دۆخ خۆکارانە نوێکرایەوە: $label 📍');
          }
          await _loadDashboard(silent: true);
        }
      }
    } catch (_) {
      // Non-fatal; retry on next tick
    }
  }

  Future<void> _sendCurrentGps() async {
    try {
      final ok = await _ensureLocationPermission();
      if (!ok || !mounted) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 8),
        ),
      );

      await _onPositionUpdate(pos, uploadToServer: false);
      await _uploadLocationToServer(pos);
    } catch (_) {
      // Non-fatal; retry on next tick
    }
  }

  dynamic _resolvePrimaryOrder() {
    if (_activeOrders.isEmpty) return null;
    for (final o in _activeOrders) {
      final s = (o['delivery_status'] ?? '').toString();
      if (s == 'on_the_way' || s == 'arrived' || s == 'picked_up') {
        return o;
      }
    }
    for (final o in _activeOrders) {
      if ((o['delivery_status'] ?? '').toString() == 'accepted') {
        return o;
      }
    }
    return _activeOrders.first;
  }

  LatLng? _validLatLng(dynamic latRaw, dynamic lngRaw) {
    final lat = double.tryParse('${latRaw ?? ''}');
    final lng = double.tryParse('${lngRaw ?? ''}');
    if (lat == null || lng == null || (lat == 0.0 && lng == 0.0)) {
      return null;
    }
    return LatLng(lat, lng);
  }

  ({
    LatLng? primaryTarget,
    String targetLabel,
    String targetAddress,
    String targetPhone,
    LatLng? secondaryTarget,
  }) _resolveNavigationTarget(dynamic order) {
    if (order == null) {
      return (
        primaryTarget: null,
        targetLabel: '',
        targetAddress: '',
        targetPhone: '',
        secondaryTarget: null,
      );
    }

    final stage = (order['delivery_status'] ?? 'assigned').toString();
    final isLab = order['is_lab'] == true;
    final pk = order['pickup'] is Map ? order['pickup'] as Map : {};
    final pt = order['patient'] is Map ? order['patient'] as Map : {};

    final pkPos = _validLatLng(pk['lat'], pk['lng']);
    final ptPos = _validLatLng(pt['lat'], pt['lng']);

    if (isLab) {
      final alreadyCollected = order['driver_picked_up_at'] != null;
      if (alreadyCollected && pkPos != null) {
        return (
          primaryTarget: pkPos,
          targetLabel: (pk['name'] ?? 'تاقیگە').toString(),
          targetAddress: (pk['address'] ?? '').toString(),
          targetPhone: (pk['phone'] ?? '').toString(),
          secondaryTarget: null,
        );
      }
      return (
        primaryTarget: ptPos ?? pkPos,
        targetLabel: (pt['name'] ?? 'ماڵی نەخۆش').toString(),
        targetAddress: (pt['address'] ?? '').toString(),
        targetPhone: (pt['phone'] ?? '').toString(),
        secondaryTarget: pkPos,
      );
    }

    if ((stage == 'assigned' || stage == 'accepted') && pkPos != null) {
      return (
        primaryTarget: pkPos,
        targetLabel: (pk['name'] ?? 'دەرمانخانە').toString(),
        targetAddress: (pk['address'] ?? '').toString(),
        targetPhone: (pk['phone'] ?? '').toString(),
        secondaryTarget: ptPos,
      );
    }

    return (
      primaryTarget: ptPos ?? pkPos,
      targetLabel: (pt['name'] ?? 'نەخۆش').toString(),
      targetAddress: (pt['address'] ?? '').toString(),
      targetPhone: (pt['phone'] ?? '').toString(),
      secondaryTarget: null,
    );
  }

  Future<void> _refreshActiveRoute() async {
    if (_lastLat == null || _lastLng == null) return;
    final order = _resolvePrimaryOrder();
    if (order == null) {
      if (_activeRoute != null || _secondaryRoutePoints.isNotEmpty) {
        setState(() {
          _activeRoute = null;
          _secondaryRoutePoints = const [];
          _routeCacheSignature = null;
        });
      }
      return;
    }

    final origin = LatLng(_lastLat!, _lastLng!);
    final nav = _resolveNavigationTarget(order);
    if (nav.primaryTarget == null) return;

    final sig =
        '${order['id']}_${order['delivery_status']}_${origin.latitude.toStringAsFixed(3)}_${origin.longitude.toStringAsFixed(3)}_${nav.primaryTarget!.latitude.toStringAsFixed(4)}';
    if (sig == _routeCacheSignature && _activeRoute != null) {
      // Keep starting vertex glued smoothly to live driver coordinate
      setState(() {
        _activeRoute = LiveRouteResult(
          points: [origin, ..._activeRoute!.points.skip(1)],
          distanceMeters: Geolocator.distanceBetween(
            origin.latitude,
            origin.longitude,
            nav.primaryTarget!.latitude,
            nav.primaryTarget!.longitude,
          ),
          durationSeconds: _activeRoute!.durationSeconds,
          isRoadRoute: _activeRoute!.isRoadRoute,
        );
      });
      return;
    }

    _routeCacheSignature = sig;
    final primary = await LiveRouteService.fetchRoute(origin, nav.primaryTarget!);
    List<LatLng> secondary = const [];
    if (nav.secondaryTarget != null) {
      final secRes = await LiveRouteService.fetchRoute(
        nav.primaryTarget!,
        nav.secondaryTarget!,
      );
      secondary = secRes.points;
    }

    if (!mounted) return;
    setState(() {
      _activeRoute = primary;
      _secondaryRoutePoints = secondary;
    });
  }

  Future<void> _fitLiveRouteCamera({dynamic focusOrder}) async {
    final ctrl = _mapController;
    if (ctrl == null) return;

    final order = focusOrder ?? _resolvePrimaryOrder();
    final nav = _resolveNavigationTarget(order);
    final driverPos = _validLatLng(_lastLat, _lastLng);

    final pts = <LatLng>[];
    if (nav.primaryTarget != null) {
      pts.add(nav.primaryTarget!);
      if (nav.secondaryTarget != null) {
        final secGap = Geolocator.distanceBetween(
          nav.primaryTarget!.latitude,
          nav.primaryTarget!.longitude,
          nav.secondaryTarget!.latitude,
          nav.secondaryTarget!.longitude,
        );
        if (secGap < 150000) {
          pts.add(nav.secondaryTarget!);
        }
      }
      if (driverPos != null) {
        final driverGap = Geolocator.distanceBetween(
          driverPos.latitude,
          driverPos.longitude,
          nav.primaryTarget!.latitude,
          nav.primaryTarget!.longitude,
        );
        if (driverGap < 150000) {
          pts.add(driverPos);
        }
      }
    } else if (driverPos != null) {
      pts.add(driverPos);
    }

    if (pts.isEmpty) {
      await ctrl.animateCamera(
        CameraUpdate.newLatLngZoom(ErbilMapService.erbilCenter, 13.5),
      );
      return;
    }
    if (pts.length == 1) {
      await ctrl.animateCamera(CameraUpdate.newLatLngZoom(pts.first, 15.8));
      return;
    }
    await ctrl.animateCamera(
      CameraUpdate.newLatLngBounds(LiveRouteService.buildBounds(pts), 75),
    );
  }

  Future<void> _toggleDuty(bool goOnline) async {
    if (_isDutyLoading) return;
    setState(() => _isDutyLoading = true);

    try {
      final nextDuty = goOnline ? 'available' : 'offline';
      final res = await ApiClient.post(
        '/driver/duty',
        body: {'duty_status': nextDuty},
      );
      if (!mounted) return;

      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        _toast(body['message']?.toString() ?? 'دۆخی کارکردن گۆڕدرا');
        await _loadDashboard(silent: true);
        if (goOnline) {
          _sendCurrentGps();
        }
      } else {
        _toast(
          body['message']?.toString() ?? 'نەتوانرا دۆخ بگۆڕدرێت',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) _toast('$e', isError: true);
    } finally {
      if (mounted) setState(() => _isDutyLoading = false);
    }
  }

  Future<void> _claimOrder(dynamic order) async {
    final id = order['id'].toString();
    setState(() => _busyOrderId = id);
    try {
      final res = await ApiClient.post('/driver/orders/$id/claim');
      if (!mounted) return;
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        final claimedOrder =
            (body is Map && body['order'] is Map) ? body['order'] : order;
        _toast(body['message']?.toString() ?? 'داواکاری وەرگیرا');
        setState(() {
          _availableOrders.removeWhere((o) => o['id'].toString() == id);
          _activeOrders.removeWhere((o) => o['id'].toString() == id);
          _activeOrders.insert(0, claimedOrder);
          _orderSubTab = 0;
          _tabIndex = 1;
          _followDriver = false;
          _hasInitialFitted = false;
          _routeCacheSignature = null;
        });
        await _loadDashboard(silent: true);
        _syncGpsTimerForDuty('busy');
        _sendCurrentGps();
        await _refreshActiveRoute();
        if (mounted) {
          await _fitLiveRouteCamera(focusOrder: claimedOrder);
        }
      } else {
        _toast(
          body['message']?.toString() ?? 'داواکاری بەردەست نەماوە',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) _toast('$e', isError: true);
    } finally {
      if (mounted) setState(() => _busyOrderId = null);
    }
  }

  Future<void> _advanceOrderStatus(
    dynamic order,
    String nextStatus, {
    bool confirm = false,
  }) async {
    final id = order['id'].toString();
    if (confirm) {
      final paymentMethod = (order['payment_method'] ?? '').toString();
      final totalStr = _formatIqd(order['total_price']);
      final isCash =
          paymentMethod.toLowerCase().contains('cash') ||
          paymentMethod.contains('کاش');
      final approved = await showDialog<bool>(
        context: context,
        builder: (dCtx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            nextStatus == 'rejected'
                ? 'ڕەتکردنەوەی داواکاری'
                : 'دڵنیابوونەوە لە تەواوکردن',
            style: const TextStyle(
              fontFamily: 'Rabar',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            nextStatus == 'rejected'
                ? 'دڵنیایت لە گەڕاندنەوەی داواکاری #$id بۆ لیستەکە؟'
                : (isCash
                      ? 'ئایا داواکاری #$id ڕادەستکرا و بڕی $totalStr بە کاش وەرگیرا؟'
                      : 'ئایا داواکاری #$id بە سەرکەوتوویی ڕادەستکرا؟'),
            style: const TextStyle(fontFamily: 'Rabar', fontSize: 13.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx, false),
              child: const Text(
                'پاشگەزبوونەوە',
                style: TextStyle(fontFamily: 'Rabar'),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dCtx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: nextStatus == 'rejected'
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                nextStatus == 'rejected'
                    ? 'بەڵێ، ڕەتی بکەرەوە'
                    : 'بەڵێ، ڕادەستکرا',
                style: const TextStyle(
                  fontFamily: 'Rabar',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
      if (approved != true || !mounted) return;
    }

    setState(() => _busyOrderId = id);
    try {
      final res = await ApiClient.post(
        '/driver/orders/$id/status',
        body: {'delivery_status': nextStatus},
      );
      if (!mounted) return;
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        _toast(body['message']?.toString() ?? 'دۆخەکە نوێکرایەوە');
        final updatedOrder =
            (body is Map && body['order'] is Map) ? body['order'] : order;
        if (nextStatus == 'accepted' && mounted) {
          setState(() {
            _tabIndex = 1;
            _followDriver = false;
            _hasInitialFitted = false;
            _routeCacheSignature = null;
          });
        }
        await _loadDashboard(silent: true);
        if (nextStatus == 'accepted' && mounted) {
          await _refreshActiveRoute();
          await _fitLiveRouteCamera(focusOrder: updatedOrder);
        }
      } else {
        _toast(
          body['message']?.toString() ?? 'نوێکردنەوە سەرکەوتوو نەبوو',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) _toast('$e', isError: true);
    } finally {
      if (mounted) setState(() => _busyOrderId = null);
    }
  }

  String _normalizePhoneDigits(String input) {
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    var out = input;
    for (var i = 0; i < 10; i++) {
      out = out.replaceAll(arabic[i], '$i').replaceAll(persian[i], '$i');
    }
    return out.replaceAll(RegExp(r'[^0-9+]'), '');
  }

  Future<void> _callPhone(String? raw) async {
    final phone = (raw ?? '').trim();
    if (phone.isEmpty) {
      _toast('ژمارەی مۆبایل بەردەست نییە', isError: true);
      return;
    }
    final clean = _normalizePhoneDigits(phone);
    if (clean.isEmpty) {
      _toast('ژمارەی مۆبایل دروست نییە', isError: true);
      return;
    }
    final uri = Uri(scheme: 'tel', path: clean);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        _toast('نەتوانرا پەیوەندی بکرێت', isError: true);
      }
    } catch (_) {
      if (mounted) {
        _toast('نەتوانرا پەیوەندی بکرێت', isError: true);
      }
    }
  }

  Future<void> _logout() async {
    try {
      await ApiClient.post('/driver/duty', body: {'duty_status': 'offline'});
    } catch (_) {}
    try {
      await ApiClient.post('/logout');
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AppFlow()),
      (_) => false,
    );
  }

  Future<void> _openNotificationsSheet() async {
    try {
      await ApiClient.post('/notifications/mark-read');
      if (mounted) setState(() => _unreadNotifications = 0);
    } catch (_) {}

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.getSurface(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ئاگادارییەکان',
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(height: 16),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: () async {
                    final res = await ApiClient.get('/notifications');
                    if (res.statusCode == 200) {
                      final decoded = jsonDecode(res.body);
                      if (decoded is List) return decoded;
                      if (decoded is Map && decoded['data'] is List) {
                        return List<dynamic>.from(decoded['data']);
                      }
                    }
                    return <dynamic>[];
                  }(),
                  builder: (_, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final list = snap.data ?? [];
                    if (list.isEmpty) {
                      return const Center(
                        child: Text(
                          'هیچ ئاگادارییەک نییە',
                          style: TextStyle(fontFamily: 'Rabar'),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final n = list[i] is Map ? list[i] as Map : {};
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.getBackground(context),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.getBorder(context),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (n['title'] ?? 'ئاگاداری').toString(),
                                style: const TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (n['message'] ?? '').toString(),
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 12,
                                  color: AppColors.getTextSubtitle(context),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _toast(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Rabar')),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatIqd(dynamic v) {
    final d = double.tryParse(v?.toString() ?? '0') ?? 0;
    return '${intl.NumberFormat('#,###').format(d)} د.ع';
  }

  String _vehicleLabel(String? v) => switch (v) {
    'car' => 'ئۆتۆمبێل',
    'refrigerated_van' => 'ساردکەرەوەی تاقیگە',
    _ => 'ماتۆڕسکیل',
  };

  String _scopeLabel(String? s) => switch (s) {
    'pharmacy' => 'دەرمان تەنها',
    'lab_sample' => 'نموونەی تاقیگە تەنها',
    _ => 'دەرمان + نموونەی تاقیگە',
  };

  String _deliveryStageLabel(String? s, bool isLab) => switch (s) {
    'assigned' => 'دیاریکراوە بۆت',
    'accepted' => 'قبوڵکراوە',
    'picked_up' => isLab ? 'نموونە وەرگیرا' : 'لە دەرمانخانە وەرگیرا',
    'on_the_way' => 'لە ڕێگادایە',
    'arrived' => 'گەیشتە شوێنەکە',
    'delivered' => isLab ? 'ڕادەستی تاقیگە کرا' : 'ڕادەستکرا',
    _ => 'چاوەڕوان',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final duty = (_driver['duty_status'] ?? 'offline').toString();
    final isOnline = duty == 'available' || duty == 'busy';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.getBackground(context),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(isDark, duty, isOnline),
              if (_gpsStatusMessage != null && isOnline)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Iconsax.location_slash,
                        size: 16,
                        color: Color(0xFFD97706),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _gpsStatusMessage!,
                          style: const TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _sendCurrentGps,
                        child: const Text(
                          'چالاککردن',
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Iconsax.info_circle,
                                size: 48,
                                color: Colors.amber,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontFamily: 'Rabar'),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadDashboard,
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text(
                                  'دووبارە هەوڵبدەرەوە',
                                  style: TextStyle(fontFamily: 'Rabar'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : IndexedStack(
                        index: _tabIndex,
                        children: [
                          _buildTasksTab(isDark),
                          _tabIndex == 1
                              ? _buildLiveMapTab(isDark)
                              : const SizedBox.shrink(),
                          _buildEarningsTab(isDark),
                          _buildProfileTab(isDark),
                          _buildScheduleTab(isDark),
                        ],
                      ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.getSurface(context),
            border: Border(
              top: BorderSide(color: AppColors.getBorder(context)),
            ),
          ),
          padding: EdgeInsets.only(
            left: 8,
            right: 8,
            top: 8,
            bottom: MediaQuery.of(context).padding.bottom + 8,
          ),
          child: Row(
            children: [
              _buildNavButton(
                0,
                Iconsax.truck_fast,
                'داواکاری',
                badge: _activeOrders.length,
              ),
              _buildNavButton(1, Iconsax.map_1, 'نەخشە'),
              _buildNavButton(
                4,
                Iconsax.calendar_tick,
                'خشتە',
                badge: int.tryParse('${_stats['upcoming_scheduled_count'] ?? _driverUpcoming.length}') ?? 0,
              ),
              _buildNavButton(2, Iconsax.wallet_money, 'داهات'),
              _buildNavButton(3, Iconsax.user_square, 'پڕۆفایل'),
            ],
          ),
        ),
      ),
    );
  }

  String _applicantRoleLabel(String? r) => switch (r) {
        'phlebotomist' => 'وەرگرتنی خوێن و تاقیگە',
        'mobile_nurse' => 'پەرستاری ماڵان',
        'both' => 'پەرستاری + شیکاری',
        'courier' => 'گەیاندنی دەرمان',
        _ => 'تیمی گەڕۆکی DrRoom',
      };

  Widget _buildHeader(bool isDark, String duty, bool isOnline) {
    final roleCode = _driver['applicant_role']?.toString();
    final isCourier = roleCode == 'courier';
    final driverName = (_driver['name'] ?? _applicantRoleLabel(roleCode)).toString();
    final dutyLabel = switch (duty) {
      'busy' => 'لە ئەرکدایت',
      'available' => 'ئۆنلاین · ئامادەیت',
      _ => 'ئۆفلاین',
    };
    final dutyColor = switch (duty) {
      'busy' => const Color(0xFF2563EB),
      'available' => const Color(0xFF10B981),
      _ => const Color(0xFF64748B),
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: dutyColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isCourier ? Iconsax.truck_fast : Iconsax.health,
              color: dutyColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextTitle(context),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: dutyColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  '$dutyLabel · ${_applicantRoleLabel(roleCode)}',
                            ),
                            if (_lastGpsSentAt != null && isOnline) ...[
                              const TextSpan(text: '  '),
                              const WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Icon(
                                  Iconsax.gps,
                                  size: 12,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          height: 1.35,
                          color: dutyColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: _openNotificationsSheet,
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.getBackground(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.getBorder(context)),
                  ),
                  child: const Icon(
                    Iconsax.notification,
                    size: 19,
                    color: Color(0xFF2563EB),
                  ),
                ),
                if (_unreadNotifications > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _unreadNotifications > 9
                            ? '9+'
                            : '$_unreadNotifications',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          _isDutyLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Switch.adaptive(
                  value: isOnline,
                  activeTrackColor: const Color(0xFF10B981),
                  onChanged: (val) => _toggleDuty(val),
                ),
        ],
      ),
    );
  }

  Widget _buildNavButton(
    int index,
    IconData icon,
    String label, {
    int badge = 0,
  }) {
    final active = _tabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            if (_tabIndex == 1 && index != 1) {
              _mapController = null;
            }
            _tabIndex = index;
          });
          if (index == 1) {
            _hasInitialFitted = false;
            _ensureLocationAndFetch();
            _refreshActiveRoute();
          } else if (index == 4) {
            _loadDriverSchedule();
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF2563EB).withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: active
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF94A3B8),
                  ),
                  if (badge > 0)
                    Positioned(
                      top: -5,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$badge',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 11,
                  fontWeight: active ? FontWeight.bold : FontWeight.w500,
                  color: active
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTasksTab(bool isDark) {
    final currentList = switch (_orderSubTab) {
      0 => _activeOrders,
      1 => _availableOrders,
      _ => _completedOrders,
    };

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Row(
            children: [
              _buildSubTabChip(0, 'چالاکەکان (${_activeOrders.length})'),
              const SizedBox(width: 8),
              _buildSubTabChip(1, 'بەردەست (${_availableOrders.length})'),
              const SizedBox(width: 8),
              _buildSubTabChip(2, 'تەواوبوو (${_completedOrders.length})'),
            ],
          ),
        ),
        Expanded(
          child: currentList.isEmpty
              ? RefreshIndicator(
                  onRefresh: _loadDashboard,
                  child: ListView(
                    children: [
                      SizedBox(
                        height: 300,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Iconsax.box_tick,
                                size: 54,
                                color: Colors.grey.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _orderSubTab == 0
                                    ? 'هیچ گەیاندنێکی چالاکت نییە'
                                    : (_orderSubTab == 1
                                          ? 'هیچ داواکارییەکی ئامادە نییە'
                                          : 'هێشتا گەیاندن تەواو نەکراوە'),
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.getTextSubtitle(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: currentList.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _buildOrderCard(
                      currentList[i],
                      isDark,
                      isPool: _orderSubTab == 1,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSubTabChip(int idx, String label) {
    final selected = _orderSubTab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _orderSubTab = idx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF2563EB)
                : AppColors.getSurface(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFF2563EB)
                  : AppColors.getBorder(context),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: selected
                  ? Colors.white
                  : AppColors.getTextSubtitle(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(dynamic order, bool isDark, {required bool isPool}) {
    final id = order['id'].toString();
    final isBusy = _busyOrderId == id;
    final isLab = order['is_lab'] == true;
    final isNursing = order['is_nursing'] == true;
    final stage = (order['delivery_status'] ?? 'unassigned').toString();
    final orderStatus = (order['status'] ?? 'pending').toString();
    final pickup = (order['pickup'] is Map) ? order['pickup'] as Map : {};
    final patient = (order['patient'] is Map) ? order['patient'] as Map : {};
    final items = (order['items'] is List) ? order['items'] as List : [];

    final serviceColor = isLab
        ? const Color(0xFF8B5CF6)
        : (isNursing ? const Color(0xFF10B981) : const Color(0xFF0D9488));
    final isOffer = !isPool && stage == 'assigned';
    final pickupName = (pickup['name'] ?? '').toString().trim();
    final pickupAddressRaw = (pickup['address'] ?? '').toString().trim();
    final pickupAddress =
        pickupAddressRaw == pickupName ? '' : pickupAddressRaw;
    final patientAge = (patient['age'] ?? '').toString().trim();
    final rawGender = (patient['gender'] ?? '').toString().trim().toLowerCase();
    final patientGender = switch (rawGender) {
      'male' || 'm' || 'نێر' => 'نێر',
      'female' || 'f' || 'مێ' => 'مێ',
      _ => (patient['gender'] ?? '').toString().trim(),
    };
    final paymentMethodRaw =
        (order['payment_method'] ?? '').toString().trim().toLowerCase();
    final paymentStatusRaw =
        (order['payment_status'] ?? '').toString().trim().toLowerCase();
    final paymentLabel = paymentMethodRaw.contains('cash') ||
            paymentMethodRaw.contains('کاش')
        ? 'پارەدان: کاش'
        : (paymentStatusRaw == 'paid'
            ? 'پارەدان: ئۆنلاین (دراوە)'
            : 'پارەدان: ئۆنلاین');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOffer
              ? const Color(0xFFF59E0B)
              : AppColors.getBorder(context),
          width: isOffer ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isOffer) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Iconsax.flash_1, size: 15, color: Color(0xFFD97706)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'داواکاری نوێ لە نزیکت · چاوەڕوانی قبوڵکردنی تۆیە',
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: serviceColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isLab
                      ? 'نموونەی تاقیگە'
                      : (isNursing ? 'پەرستاری ماڵەوە' : 'گەیاندنی دەرمان'),
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: serviceColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                order['order_number'] ?? '#$id',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextTitle(context),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      (isOffer
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF2563EB))
                          .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPool
                      ? 'ئامادە بۆ وەرگرتن'
                      : (isOffer
                            ? 'داواکاری نوێ'
                            : _deliveryStageLabel(stage, isLab)),
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: isOffer
                        ? const Color(0xFFD97706)
                        : const Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if ((order['scheduled_at'] ?? '').toString().trim().isNotEmpty) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.calendar_tick, size: 16, color: Color(0xFF0D9488)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'کاتی دیاریکراو: ${order['scheduled_at']}',
                      style: const TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D9488),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Stop 1: Pharmacy or Lab
          _buildStopTile(
            title: isLab ? 'تاقیگەی دیاریکراو' : 'وەرگرتن لە دەرمانخانە',
            name: pickupName,
            address: pickupAddress,
            phone: (pickup['phone'] ?? '').toString(),
            accentColor: serviceColor,
            icon: isLab ? Iconsax.microscope : Iconsax.shop,
          ),
          const SizedBox(height: 10),

          // Stop 2: Patient Location
          _buildStopTile(
            title: isLab
                ? 'ماڵی نەخۆش (وەرگرتنی نموونە)'
                : 'شوێنی نەخۆش (گەیاندن)',
            name: (patient['name'] ?? 'نەخۆش').toString(),
            address: (patient['address'] ?? '').toString(),
            phone: (patient['phone'] ?? '').toString(),
            accentColor: const Color(0xFF2563EB),
            icon: Iconsax.location,
          ),

          if (patientAge.isNotEmpty ||
              patientGender.isNotEmpty ||
              paymentMethodRaw.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (patientAge.isNotEmpty)
                  _buildMetaBadge('تەمەن: $patientAge'),
                if (patientGender.isNotEmpty)
                  _buildMetaBadge('ڕەگەز: $patientGender'),
                if (paymentMethodRaw.isNotEmpty)
                  _buildMetaBadge(paymentLabel),
              ],
            ),
          ],

          if ((patient['notes'] ?? '').toString().trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'تێبینی: ${patient['notes']}',
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 11.5,
                  color: AppColors.getTextSubtitle(context),
                ),
              ),
            ),
          ],

          if (items.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: items.map((it) {
                final m = it is Map ? it : {};
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.getBackground(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.getBorder(context)),
                  ),
                  child: Text(
                    '${m['name'] ?? ''} ×${m['quantity'] ?? 1}',
                    style: const TextStyle(fontFamily: 'Rabar', fontSize: 11),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'کۆی پسوڵە',
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 10.5,
                      color: AppColors.getTextSubtitle(context),
                    ),
                  ),
                  Text(
                    _formatIqd(order['total_price']),
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextTitle(context),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'کرێی گەیاندن',
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 10.5,
                      color: AppColors.getTextSubtitle(context),
                    ),
                  ),
                  Text(
                    _formatIqd(order['delivery_fee']),
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (orderStatus != 'completed' && orderStatus != 'cancelled') ...[
            if (isPool) ...[
              const SizedBox(height: 14),
              Builder(
                builder: (_) {
                  final isOffline =
                      (_driver['duty_status'] ?? 'offline').toString() ==
                      'offline';
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isBusy
                          ? null
                          : (isOffline
                                ? () => _toggleDuty(true)
                                : () => _claimOrder(order)),
                      icon: isBusy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              isOffline ? Iconsax.flash_1 : Iconsax.tick_circle,
                              size: 18,
                            ),
                      label: Text(
                        isOffline
                            ? 'سەرەتا خۆت ئۆنلاین بکە بۆ وەرگرتن'
                            : 'وەرگرتنی ئەم داواکارییە',
                        style: const TextStyle(
                          fontFamily: 'Rabar',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOffline
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ] else if (stage == 'assigned') ...[
              const SizedBox(height: 14),
              _buildProgressionActions(order, stage, isLab, isBusy),
            ] else if (stage == 'accepted') ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: isBusy
                      ? null
                      : () => _advanceOrderStatus(
                          order,
                          'rejected',
                          confirm: true,
                        ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'ڕەتکردنەوە',
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildProgressionActions(
    dynamic order,
    String stage,
    bool isLab,
    bool isBusy,
  ) {
    final (
      String nextStage,
      String buttonLabel,
      Color color,
      bool needsConfirm,
    ) = switch (stage) {
      'assigned' => (
        'accepted',
        'قبوڵکردنی داواکاری',
        const Color(0xFF10B981),
        false,
      ),
      'accepted' => (
        'picked_up',
        isLab ? 'نموونە وەرگیرا' : 'لە دەرمانخانە وەرگیرا',
        const Color(0xFF8B5CF6),
        false,
      ),
      'picked_up' => (
        'on_the_way',
        'لە ڕێگادام',
        const Color(0xFFF59E0B),
        false,
      ),
      'on_the_way' => (
        'arrived',
        'گەیشتمە شوێنەکە',
        const Color(0xFF0D9488),
        false,
      ),
      'arrived' => (isLab && order['driver_picked_up_at'] == null)
          ? (
              'picked_up',
              'نموونە وەرگیرا',
              const Color(0xFF8B5CF6),
              false,
            )
          : (
              'delivered',
              isLab ? 'گەیەنرایە تاقیگە (تەواو)' : 'ڕادەستکرا (تەواو)',
              const Color(0xFF10B981),
              true,
            ),
      _ => (
        'delivered',
        isLab ? 'گەیەنرایە تاقیگە (تەواو)' : 'ڕادەستکرا (تەواو)',
        const Color(0xFF10B981),
        true,
      ),
    };

    return Row(
      children: [
        if (stage == 'assigned' || stage == 'accepted') ...[
          OutlinedButton(
            onPressed: isBusy
                ? null
                : () => _advanceOrderStatus(order, 'rejected', confirm: true),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              side: const BorderSide(color: Color(0xFFEF4444)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'ڕەتکردنەوە',
              style: TextStyle(
                fontFamily: 'Rabar',
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isBusy
                ? null
                : () => _advanceOrderStatus(
                    order,
                    nextStage,
                    confirm: needsConfirm,
                  ),
            icon: isBusy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Iconsax.arrow_left_2, size: 18),
            label: Text(
              buttonLabel,
              style: const TextStyle(
                fontFamily: 'Rabar',
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetaBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.getBackground(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Rabar',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.getTextSubtitle(context),
        ),
      ),
    );
  }

  Widget _buildStopTile({
    required String title,
    required String name,
    required String address,
    required String phone,
    required Color accentColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name.isNotEmpty ? name : 'دیاری نەکراوە',
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextTitle(context),
                  ),
                ),
                if (address.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 11.5,
                      color: AppColors.getTextSubtitle(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (phone.isNotEmpty)
            IconButton(
              onPressed: () => _callPhone(phone),
              icon: const Icon(
                Iconsax.call,
                size: 18,
                color: Color(0xFF10B981),
              ),
              tooltip: 'پەیوەندی',
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _buildLiveMapTab(bool isDark) {
    final primaryOrder = _resolvePrimaryOrder();
    final nav = _resolveNavigationTarget(primaryOrder);
    final driverPos = _validLatLng(_lastLat, _lastLng);
    final initialCenter =
        nav.primaryTarget ?? driverPos ?? ErbilMapService.erbilCenter;

    final markers = <Marker>{};
    if (driverPos != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver_self'),
          position: driverPos,
          rotation: _lastHeading,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 3,
          infoWindow: InfoWindow(
            title: 'شوێنی ئێستای من',
            snippet: _lastSpeedMps > 0.5
                ? '${(_lastSpeedMps * 3.6).toStringAsFixed(0)} کم/کاتژمێر'
                : 'GPS چالاکە',
          ),
          icon: _courierIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }

    for (final o in _activeOrders) {
      final p = o['patient'] is Map ? o['patient'] as Map : {};
      final pPos = _validLatLng(p['lat'], p['lng']);
      if (pPos != null) {
        markers.add(
          Marker(
            markerId: MarkerId('dest_${o['id']}'),
            position: pPos,
            anchor: const Offset(0.5, 0.5),
            zIndexInt: 2,
            infoWindow: InfoWindow(
              title: 'نەخۆش: ${p['name'] ?? ''}',
              snippet: 'داواکاری ${o['order_number'] ?? '#${o['id']}'}',
            ),
            icon: _patientIcon ??
                BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
          ),
        );
      }

      final pk = o['pickup'] is Map ? o['pickup'] as Map : {};
      final pkPos = _validLatLng(pk['lat'], pk['lng']);
      if (pkPos != null) {
        markers.add(
          Marker(
            markerId: MarkerId('pickup_${o['id']}'),
            position: pkPos,
            anchor: const Offset(0.5, 0.5),
            zIndexInt: 2,
            infoWindow: InfoWindow(title: '${pk['name'] ?? ''}'),
            icon: _pickupIcon ??
                BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange,
                ),
          ),
        );
      }
    }

    final polylines = <Polyline>{};
    if (_activeRoute != null && _activeRoute!.points.length >= 2) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('active_route'),
          points: _activeRoute!.points,
          color: const Color(0xFF2563EB),
          width: 5,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );
    }
    if (_secondaryRoutePoints.length >= 2) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('secondary_leg'),
          points: _secondaryRoutePoints,
          color: const Color(0xFF10B981),
          width: 4,
          patterns: [PatternItem.dash(16), PatternItem.gap(10)],
          jointType: JointType.round,
        ),
      );
    }

    double? directMeters = _activeRoute?.distanceMeters;
    if (directMeters == null && driverPos != null && nav.primaryTarget != null) {
      directMeters = Geolocator.distanceBetween(
        driverPos.latitude,
        driverPos.longitude,
        nav.primaryTarget!.latitude,
        nav.primaryTarget!.longitude,
      );
    }

    final primaryStage =
        (primaryOrder?['delivery_status'] ?? 'assigned').toString();
    final primaryIsLab = primaryOrder?['is_lab'] == true;
    final proximity = LiveRouteService.describeProximity(
      stage: primaryStage,
      distanceMeters: directMeters,
      etaMinutes: _activeRoute?.etaMinutes,
      isLab: primaryIsLab,
      lang: 'ckb',
    );

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialCenter,
            zoom: 14.8,
          ),
          markers: markers,
          polylines: polylines,
          compassEnabled: true,
          myLocationEnabled: _locationPermissionGranted,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          onCameraMoveStarted: () {
            // Let user pan freely without snapping back until they tap Follow
          },
          onMapCreated: (c) {
            _mapController = c;
            _hasInitialFitted = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _tabIndex == 1) {
                _fitLiveRouteCamera();
              }
            });
          },
        ),
        Positioned(
          top: 12,
          right: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.getSurface(context).withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: proximity.isUrgentClose
                    ? proximity.color.withValues(alpha: 0.5)
                    : AppColors.getBorder(context),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: (primaryOrder != null
                            ? proximity.color
                            : const Color(0xFF2563EB))
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Iconsax.gps,
                    color: primaryOrder != null
                        ? proximity.color
                        : const Color(0xFF2563EB),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        primaryOrder != null
                            ? proximity.headline
                            : 'داواکاری چالاک: ${_activeOrders.length}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primaryOrder != null
                              ? proximity.color
                              : AppColors.getTextTitle(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        primaryOrder != null && proximity.detail.isNotEmpty
                            ? '${proximity.detail} · ئاڕاستەی تۆماتیک چالاکە'
                            : (_lastLat != null
                                ? 'شوێنی من: ${_lastLat!.toStringAsFixed(4)}, ${_lastLng!.toStringAsFixed(4)}'
                                : 'چاوەڕوانی نیشانەی GPS...'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 10.5,
                          color: AppColors.getTextSubtitle(context),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    setState(() => _followDriver = true);
                    await _ensureLocationAndFetch();
                    if (mounted) {
                      _fitLiveRouteCamera();
                    }
                  },
                  icon: const Icon(
                    Icons.my_location,
                    size: 18,
                    color: Color(0xFF10B981),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 14,
          bottom: primaryOrder != null ? 185 : 22,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'driver_follow_btn',
                onPressed: () {
                  setState(() => _followDriver = !_followDriver);
                  if (_followDriver && driverPos != null) {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(driverPos, 16.0),
                    );
                  }
                },
                backgroundColor: _followDriver
                    ? const Color(0xFF2563EB)
                    : AppColors.getSurface(context),
                foregroundColor: _followDriver
                    ? Colors.white
                    : AppColors.getTextTitle(context),
                elevation: 2,
                child: const Icon(Icons.navigation_rounded, size: 18),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'driver_fit_btn',
                onPressed: () {
                  setState(() => _followDriver = false);
                  _fitLiveRouteCamera();
                },
                backgroundColor: AppColors.getSurface(context),
                foregroundColor: const Color(0xFF0F172A),
                elevation: 2,
                child: const Icon(Icons.zoom_out_map, size: 18),
              ),
            ],
          ),
        ),
        if (primaryOrder != null)
          Positioned(
            right: 12,
            left: 12,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.getBorder(context)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: proximity.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${primaryOrder['order_number'] ?? '#${primaryOrder['id']}'} · ${_deliveryStageLabel(primaryStage, primaryIsLab)}',
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: proximity.color,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (nav.targetPhone.isNotEmpty)
                        IconButton(
                          onPressed: () => _callPhone(nav.targetPhone),
                          icon: const Icon(
                            Iconsax.call,
                            size: 18,
                            color: Color(0xFF10B981),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nav.targetLabel.isNotEmpty
                                  ? nav.targetLabel
                                  : 'ئامانجی داهاتوو',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (nav.targetAddress.isNotEmpty)
                              Text(
                                nav.targetAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 11,
                                  color: AppColors.getTextSubtitle(context),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildProgressionActions(
                    primaryOrder,
                    primaryStage,
                    primaryIsLab,
                    _busyOrderId == primaryOrder['id'].toString(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  bool _isCashPayment(dynamic order) {
    final m = (order['payment_method'] ?? '').toString().trim().toLowerCase();
    return m.isEmpty || m.contains('cash') || m.contains('کاش');
  }

  Future<void> _exportDriverPdf({required bool share}) async {
    if (_isExportingPdf) return;
    setState(() => _isExportingPdf = true);
    try {
      if (share) {
        await DriverEarningsPdfService.sharePdf(
          driver: _driver,
          finance: _stats,
          orders: _completedOrders,
        );
      } else {
        await DriverEarningsPdfService.previewAndPrint(
          context,
          driver: _driver,
          finance: _stats,
          orders: _completedOrders,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'کێشە لە دروستکردنی PDF: $e',
              style: const TextStyle(fontFamily: 'Rabar'),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  Widget _buildDriverMonthChip(
    String label,
    String monthCode,
    String activeMonth,
  ) {
    final selected = activeMonth == monthCode;
    return GestureDetector(
      onTap: () {
        if (_isMonthLoading || selected) return;
        setState(() {
          _selectedEarningsMonth = monthCode;
          _isMonthLoading = true;
        });
        _loadDashboard(silent: true, month: monthCode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2563EB)
              : AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF2563EB)
                : AppColors.getBorder(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Rabar',
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : AppColors.getTextTitle(context),
          ),
        ),
      ),
    );
  }

  Widget _buildEarningsTab(bool isDark) {
    final todayDeliveries =
        int.tryParse('${_stats['today_deliveries'] ?? 0}') ?? 0;
    final totalDeliveries =
        int.tryParse('${_stats['total_deliveries'] ?? 0}') ?? 0;
    final todayEarnings =
        double.tryParse('${_stats['today_earnings'] ?? 0}') ?? 0;
    final totalEarnings =
        double.tryParse('${_stats['total_earnings'] ?? 0}') ?? 0;

    final hasServerCashStats = _stats.containsKey('cash_total_count');
    final unsettledCashList = _completedOrders
        .where((o) => _isCashPayment(o) && o['is_settled'] != true)
        .toList();
    final onlineList =
        _completedOrders.where((o) => !_isCashPayment(o)).toList();
    final now = DateTime.now();
    final cashTodayList = unsettledCashList.where((o) {
      final rawDt = (o['driver_delivered_at'] ?? o['created_at'])?.toString();
      final dt = rawDt != null ? DateTime.tryParse(rawDt)?.toLocal() : null;
      return dt != null &&
          dt.year == now.year &&
          dt.month == now.month &&
          dt.day == now.day;
    }).toList();

    double sumField(List<dynamic> list, String key) {
      return list.fold<double>(
        0.0,
        (sum, o) => sum + (double.tryParse('${o[key] ?? 0}') ?? 0.0),
      );
    }

    final cashTodayCount = hasServerCashStats
        ? (int.tryParse('${_stats['cash_today_count'] ?? 0}') ?? 0)
        : cashTodayList.length;
    final cashTodayCollected = hasServerCashStats
        ? (double.tryParse('${_stats['cash_today_collected'] ?? 0}') ?? 0)
        : sumField(cashTodayList, 'total_price');
    final cashTotalCount = hasServerCashStats
        ? (int.tryParse('${_stats['cash_total_count'] ?? 0}') ?? 0)
        : unsettledCashList.length;
    final cashTotalCollected = hasServerCashStats
        ? (double.tryParse('${_stats['cash_total_collected'] ?? 0}') ?? 0)
        : sumField(unsettledCashList, 'total_price');

    final period = _stats['period_summary'] is Map
        ? Map<String, dynamic>.from(_stats['period_summary'])
        : <String, dynamic>{};
    final availableMonths = _stats['available_months'] is List
        ? List<dynamic>.from(_stats['available_months'])
        : <dynamic>[];
    final activeMonth =
        _selectedEarningsMonth ??
        _stats['selected_month']?.toString() ??
        'all';
    final periodLabel =
        (period['label'] ?? _stats['selected_month_label'] ?? 'هەموو مانگەکان')
            .toString();

    final periodDeliveries = period.containsKey('deliveries')
        ? (int.tryParse('${period['deliveries'] ?? 0}') ?? 0)
        : _completedOrders.length;
    final periodEarnings = period.containsKey('earnings')
        ? (double.tryParse('${period['earnings'] ?? 0}') ?? 0)
        : sumField(_completedOrders, 'delivery_fee');
    final periodCashCount = period.containsKey('cash_count')
        ? (int.tryParse('${period['cash_count'] ?? 0}') ?? 0)
        : _completedOrders.where(_isCashPayment).length;
    final periodCashCollected = period.containsKey('cash_collected')
        ? (double.tryParse('${period['cash_collected'] ?? 0}') ?? 0)
        : sumField(_completedOrders.where(_isCashPayment).toList(), 'total_price');
    final periodCashFee = period.containsKey('cash_delivery_fee')
        ? (double.tryParse('${period['cash_delivery_fee'] ?? 0}') ?? 0)
        : sumField(_completedOrders.where(_isCashPayment).toList(), 'delivery_fee');
    final periodOnlineCount = period.containsKey('online_count')
        ? (int.tryParse('${period['online_count'] ?? 0}') ?? 0)
        : onlineList.length;
    final periodOnlineFee = period.containsKey('online_delivery_fee')
        ? (double.tryParse('${period['online_delivery_fee'] ?? 0}') ?? 0)
        : sumField(onlineList, 'delivery_fee');
    final periodLabCount = period.containsKey('lab_count')
        ? (int.tryParse('${period['lab_count'] ?? 0}') ?? 0)
        : _completedOrders.where((o) => o['is_lab'] == true).length;
    final periodPharmacyCount = period.containsKey('pharmacy_count')
        ? (int.tryParse('${period['pharmacy_count'] ?? 0}') ?? 0)
        : (_completedOrders.length -
            _completedOrders.where((o) => o['is_lab'] == true).length);

    final resetAtRaw =
        (_stats['earnings_reset_at'] ?? _driver['earnings_reset_at'])
            ?.toString();
    final resetAt =
        resetAtRaw != null ? DateTime.tryParse(resetAtRaw)?.toLocal() : null;

    final filteredCompleted = _completedOrders.where((o) {
      if (_earningsFilter == 1) return _isCashPayment(o);
      if (_earningsFilter == 2) return !_isCashPayment(o);
      return true;
    }).toList();

    return RefreshIndicator(
      onRefresh: () => _loadDashboard(month: activeMonth),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (availableMonths.isNotEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildDriverMonthChip(
                    'هەموو ($totalDeliveries)',
                    'all',
                    activeMonth,
                  ),
                  ...availableMonths.map((m) {
                    final code = (m['month'] ?? '').toString();
                    final label = (m['label'] ?? code).toString();
                    final cnt = int.tryParse('${m['deliveries'] ?? 0}') ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildDriverMonthChip(
                        '$label ($cnt)',
                        code,
                        activeMonth,
                      ),
                    );
                  }),
                ],
              ),
            ),
            if (_isMonthLoading) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(minHeight: 2.5),
            ],
            const SizedBox(height: 12),
          ],
          if (resetAt != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Iconsax.tick_circle,
                    size: 16,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'دواین سفرکردنەوەی پارەی کاش: ${intl.DateFormat('yyyy-MM-dd HH:mm').format(resetAt)}',
                      style: const TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Highlighted Cash Collected Card (Unsettled Cash Owed)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF10B981)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Iconsax.money_recive,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'پارەی کاشی وەرگیراو (چاوەڕوانی پاکتاو)',
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ئەمڕۆ ($cashTodayCount داواکاری)',
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatIqd(cashTodayCollected),
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 38,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'سفرنەکراو ($cashTotalCount داواکاری)',
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatIqd(cashTotalCollected),
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Selected Month / Period Earnings & Cash Summary
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  'داهاتی کرێ ($periodDeliveries کار)',
                  _formatIqd(periodEarnings),
                  Iconsax.wallet_2,
                  const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMiniStat(
                  'کاشی ماوە ($periodCashCount کار)',
                  _formatIqd(periodCashCollected),
                  Iconsax.money_tick,
                  const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Detailed Monthly Breakdown Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.getSurface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.getBorder(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'پوختەی حیساباتی ماوە',
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      periodLabel,
                      style: const TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 18),
                _buildInfoRow(
                  'گەیاندنەکان ($periodDeliveries کار)',
                  'تاقیگە: $periodLabCount · دەرمانخانە: $periodPharmacyCount',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  'داواکاری کاش ($periodCashCount)',
                  'وەرگیراو: ${_formatIqd(periodCashCollected)} · کرێ: ${_formatIqd(periodCashFee)}',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  'داواکاری ئۆنلاین ($periodOnlineCount)',
                  'کرێی گەیاندن: ${_formatIqd(periodOnlineFee)}',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  'داهاتی ئەمڕۆ ($todayDeliveries کار)',
                  _formatIqd(todayEarnings),
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  'کۆی گشتی مێژوویی ($totalDeliveries کار)',
                  _formatIqd(totalEarnings),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Export PDF Buttons for Driver
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isExportingPdf
                      ? null
                      : () => _exportDriverPdf(share: false),
                  icon: _isExportingPdf
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Iconsax.document_download, size: 18),
                  label: const Text(
                    'سەیڤکردنی PDF',
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isExportingPdf
                      ? null
                      : () => _exportDriverPdf(share: true),
                  icon: const Icon(Iconsax.share, size: 17),
                  label: const Text(
                    'ناردن',
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    side: const BorderSide(color: Color(0xFF2563EB)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Filter Chips for Completed Earnings List
          Row(
            children: [
              _buildEarningsFilterChip(0, 'هەمووی (${_completedOrders.length})'),
              const SizedBox(width: 8),
              _buildEarningsFilterChip(
                1,
                'کاش (${_completedOrders.where(_isCashPayment).length})',
              ),
              const SizedBox(width: 8),
              _buildEarningsFilterChip(
                2,
                'ئۆنلاین (${_completedOrders.where((o) => !_isCashPayment(o)).length})',
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (filteredCompleted.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.getBorder(context)),
              ),
              child: Column(
                children: [
                  Icon(
                    Iconsax.receipt_item,
                    size: 40,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'هیچ کارێکی تەواوبوو لەم ماوەیەدا نییە',
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 13,
                      color: AppColors.getTextSubtitle(context),
                    ),
                  ),
                ],
              ),
            )
          else
            ...filteredCompleted.map((order) {
              final isCash = _isCashPayment(order);
              final isCashSettled = isCash && order['is_settled'] == true;
              final isLab = order['is_lab'] == true;
              final patient =
                  (order['patient'] is Map) ? order['patient'] as Map : {};
              final orderNum =
                  (order['order_number'] ?? '#${order['id']}').toString();
              final deliveredAt = (order['delivered_at_display'] ?? '')
                  .toString()
                  .trim();
              final fallbackDt = deliveredAt.isNotEmpty
                  ? deliveredAt
                  : (() {
                      final raw =
                          (order['driver_delivered_at'] ?? order['created_at'])
                              ?.toString();
                      final parsed =
                          raw != null ? DateTime.tryParse(raw)?.toLocal() : null;
                      return parsed != null
                          ? intl.DateFormat('yyyy-MM-dd HH:mm').format(parsed)
                          : '';
                    })();

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.getSurface(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.getBorder(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          orderNum,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getTextTitle(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isLab ? 'نموونەی تاقیگە' : 'گەیاندنی دەرمان',
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 11,
                            color: AppColors.getTextSubtitle(context),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: (isCashSettled
                                    ? Colors.grey
                                    : (isCash
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF2563EB)))
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isCashSettled
                                ? 'کاش (سفرکراوە)'
                                : (isCash ? 'کاش (وەرگیراو)' : 'ئۆنلاین'),
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: isCashSettled
                                  ? Colors.grey.shade700
                                  : (isCash
                                      ? const Color(0xFF059669)
                                      : const Color(0xFF2563EB)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            (patient['name'] ?? 'نەخۆش').toString(),
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.getTextTitle(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (fallbackDt.isNotEmpty)
                          Text(
                            fallbackDt,
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              color: AppColors.getTextSubtitle(context),
                            ),
                          ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isCash ? 'پارەی کاشی وەرگیراو' : 'کۆی پسوڵە',
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 10.5,
                                color: AppColors.getTextSubtitle(context),
                              ),
                            ),
                            Text(
                              _formatIqd(order['total_price']),
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: isCash
                                    ? const Color(0xFF059669)
                                    : AppColors.getTextTitle(context),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'کرێی گەیاندنی تۆ',
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 10.5,
                                color: AppColors.getTextSubtitle(context),
                              ),
                            ),
                            Text(
                              _formatIqd(order['delivery_fee']),
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEarningsFilterChip(int index, String label) {
    final selected = _earningsFilter == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _earningsFilter = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF10B981)
                : AppColors.getSurface(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFF10B981)
                  : AppColors.getBorder(context),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : AppColors.getTextSubtitle(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleTab(bool isDark) {
    const dayTranslations = {
      'Sunday': 'یەکشەممە',
      'Monday': 'دووشەممە',
      'Tuesday': 'سێشەممە',
      'Wednesday': 'چوارشەممە',
      'Thursday': 'پێنجشەممە',
      'Friday': 'هەینی',
      'Saturday': 'شەممە',
    };

    if (_scheduleLoading && _driverWeek.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final selectedDay = _driverAvailability.isNotEmpty
        ? _driverAvailability[_scheduleDayIdx.clamp(0, _driverAvailability.length - 1)]
        : null;
    final daySlots = (selectedDay?['slots'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((s) => s['past'] != true)
        .toList();

    return RefreshIndicator(
      onRefresh: _loadDriverSchedule,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Current Shift Status Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (_isOnShiftNow ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: (_isOnShiftNow ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
                    .withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isOnShiftNow ? Iconsax.clock : Iconsax.moon,
                  color: _isOnShiftNow ? const Color(0xFF059669) : const Color(0xFFD97706),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isOnShiftNow ? 'ئێستا لە کاتی دەوامی خۆتیت' : 'ئێستا لە دەرەوەی کاتی دەوامیت',
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: _isOnShiftNow ? const Color(0xFF059669) : const Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'لە کاتی پشوودا داواکاری نوێت بۆ نانێردرێت',
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 11.5,
                          color: AppColors.getTextSubtitle(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Day selector + booked/available slots
          Text(
            'کاتەکانی ئەم هەفتەیە (بەتاڵ و گیراو)',
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextTitle(context),
            ),
          ),
          const SizedBox(height: 10),
          if (_driverAvailability.isNotEmpty) ...[
            SizedBox(
              height: 66,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _driverAvailability.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final d = _driverAvailability[i];
                  final active = i == _scheduleDayIdx;
                  final dateStr = (d['date'] ?? '').toString();
                  final shortDate = dateStr.length >= 10 ? dateStr.substring(5) : dateStr;
                  final label = i == 0
                      ? 'ئەمڕۆ'
                      : (dayTranslations[d['day_of_week']] ?? '');
                  final closed = d['closed'] == true;
                  return GestureDetector(
                    onTap: () => setState(() => _scheduleDayIdx = i),
                    child: Container(
                      width: 84,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? const Color(0xFF2563EB) : AppColors.getSurface(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: active ? const Color(0xFF2563EB) : AppColors.getBorder(context),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: active ? Colors.white : AppColors.getTextTitle(context),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            closed ? 'پشوو' : shortDate,
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 10.5,
                              color: active
                                  ? Colors.white70
                                  : (closed ? const Color(0xFFEF4444) : AppColors.getTextSubtitle(context)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.getBorder(context)),
              ),
              child: daySlots.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'لەم ڕۆژەدا هیچ کاتێک بەردەست نییە',
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 12.5,
                            color: AppColors.getTextSubtitle(context),
                          ),
                        ),
                      ),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: daySlots.map((s) {
                        final taken = s['taken'] == true;
                        final booked = (s['booked'] as num?)?.toInt() ?? 0;
                        final cap = (s['capacity'] as num?)?.toInt() ?? 1;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: (taken ? const Color(0xFFEF4444) : const Color(0xFF10B981))
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            taken
                                ? '${s['time']} • گیراوە'
                                : '${s['time']} ($booked/$cap)',
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: taken ? const Color(0xFFDC2626) : const Color(0xFF059669),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 18),
          ],

          // Upcoming Scheduled Deliveries
          Text(
            'گەیاندنە کات-دیاریکراوەکان (${_driverUpcoming.length})',
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextTitle(context),
            ),
          ),
          const SizedBox(height: 10),
          if (_driverUpcoming.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.getBorder(context)),
              ),
              child: Center(
                child: Text(
                  'هیچ گەیاندنێکی کات-دیاریکراو نییە',
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 12.5,
                    color: AppColors.getTextSubtitle(context),
                  ),
                ),
              ),
            )
          else
            ..._driverUpcoming.map((u) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.getSurface(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.getBorder(context)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Iconsax.calendar_tick, color: Color(0xFF0D9488), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '#${u['id']}  •  ${u['patient_name'] ?? 'نەخۆش'}',
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.getTextTitle(context),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'کات: ${u['scheduled_at'] ?? ''}',
                              style: const TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D9488),
                              ),
                            ),
                            if ((u['address'] ?? '').toString().isNotEmpty)
                              Text(
                                u['address'].toString(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 11.5,
                                  color: AppColors.getTextSubtitle(context),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),

          const SizedBox(height: 18),
          Text(
            'خشتەی دەوامی هەفتانە',
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextTitle(context),
            ),
          ),
          const SizedBox(height: 10),
          ..._driverWeek.map((row) {
            final isAvail = row['is_available'] == true || row['is_available'] == 1;
            final dayName = dayTranslations[row['day_of_week']] ?? row['day_of_week'].toString();
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.getBorder(context)),
              ),
              child: Row(
                children: [
                  Icon(
                    isAvail ? Iconsax.clock : Iconsax.close_circle,
                    size: 18,
                    color: isAvail ? const Color(0xFF2563EB) : Colors.grey,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      dayName,
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextTitle(context),
                      ),
                    ),
                  ),
                  Text(
                    isAvail
                        ? '${row['start_time']} - ${row['end_time']}'
                        : 'پشووە',
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isAvail ? const Color(0xFF2563EB) : Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProfileTab(bool isDark) {
    final phone = (_driver['phone'] ?? '').toString();
    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Driver Details Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.getSurface(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.getBorder(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _driver['applicant_role'] == 'courier'
                      ? 'زانیاری تیمی گەیاندنی تەندروستی'
                      : 'زانیاری ئەندامی تیمی پزیشکی گەڕۆک',
                  style: const TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 22),
                _buildInfoRow('ناو', (_driver['name'] ?? '').toString()),
                const SizedBox(height: 10),
                _buildInfoRow(
                  'پسپۆڕی',
                  _applicantRoleLabel(_driver['applicant_role']?.toString()),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ژمارەی مۆبایل',
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 12.5,
                        color: AppColors.getTextSubtitle(context),
                      ),
                    ),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        '\u200E$phone',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildInfoRow('شار', (_driver['city'] ?? 'هەولێر').toString()),
                const SizedBox(height: 10),
                _buildInfoRow(
                  _driver['applicant_role'] == 'courier' ? 'ئامێری گواستنەوە' : 'هاتوچۆ',
                  _driver['applicant_role'] == 'courier'
                      ? _vehicleLabel(_driver['vehicle_type']?.toString())
                      : (_driver['has_private_car'] == true ? 'ئۆتۆمبێلی تایبەت' : 'بێ ئۆتۆمبێل'),
                ),
                if ((_driver['service_areas'] ?? '').toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildInfoRow(
                    'ناوچەی کار',
                    (_driver['service_areas']).toString(),
                  ),
                ],
                if ((_driver['plate_number'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildInfoRow(
                    'ژمارەی تابلۆ',
                    (_driver['plate_number']).toString(),
                  ),
                ],
                const SizedBox(height: 10),
                _buildInfoRow(
                  'بوار',
                  _scopeLabel(_driver['service_scope']?.toString()),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),
          ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Iconsax.logout, size: 18),
            label: const Text(
              'چوونەدەرەوە لە هەژمار',
              style: TextStyle(
                fontFamily: 'Rabar',
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 11,
                    color: AppColors.getTextSubtitle(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            val,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String k, String v) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          k,
          style: TextStyle(
            fontFamily: 'Rabar',
            fontSize: 12.5,
            color: AppColors.getTextSubtitle(context),
          ),
        ),
        Flexible(
          child: Text(
            v,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontFamily: 'Rabar',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
