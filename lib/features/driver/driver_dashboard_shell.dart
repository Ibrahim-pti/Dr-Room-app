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

import '../../core/theme/app_colors.dart';
import '../../core/utils/api_client.dart';
import '../../core/utils/erbil_map_service.dart';
import '../../main.dart';

class DriverDashboardShell extends StatefulWidget {
  const DriverDashboardShell({super.key});

  @override
  State<DriverDashboardShell> createState() => _DriverDashboardShellState();
}

class _DriverDashboardShellState extends State<DriverDashboardShell> {
  int _tabIndex = 0; // 0: Tasks, 1: Live Map, 2: Profile & Earnings
  int _orderSubTab = 0; // 0: Active, 1: Available Pool, 2: Completed

  bool _isLoading = true;
  bool _isDutyLoading = false;
  String? _error;
  String? _busyOrderId;

  Map<String, dynamic> _driver = {};
  Map<String, dynamic> _stats = {};
  List<dynamic> _activeOrders = [];
  List<dynamic> _availableOrders = [];
  List<dynamic> _completedOrders = [];

  Timer? _refreshTimer;
  Timer? _gpsTimer;
  double? _lastLat;
  double? _lastLng;
  DateTime? _lastGpsSentAt;
  String? _gpsStatusMessage;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) _loadDashboard(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _gpsTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final res = await ApiClient.get('/driver/dashboard');
      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'] ?? {};
        final driverMap = Map<String, dynamic>.from(data['driver'] ?? {});
        final duty = (driverMap['duty_status'] ?? 'offline').toString();

        setState(() {
          _driver = driverMap;
          _stats = Map<String, dynamic>.from(data['stats'] ?? {});
          _activeOrders = List<dynamic>.from(data['active_orders'] ?? []);
          _availableOrders = List<dynamic>.from(data['available_orders'] ?? []);
          _completedOrders = List<dynamic>.from(data['completed_orders'] ?? []);
          if (driverMap['current_lat'] != null && driverMap['current_lng'] != null) {
            _lastLat = double.tryParse(driverMap['current_lat'].toString());
            _lastLng = double.tryParse(driverMap['current_lng'].toString());
          }
          _isLoading = false;
        });

        _syncGpsTimerForDuty(duty);
      } else if (!silent) {
        setState(() {
          _error = 'کێشە لە بارکردنی زانیاری کارمەندی گەیاندن ڕوویدا';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!silent && mounted) {
        setState(() {
          _error = 'کێشەی پەیوەندی بە سێرڤەر: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _syncGpsTimerForDuty(String duty) {
    final shouldTrack = duty == 'available' || duty == 'busy';
    if (shouldTrack) {
      if (_gpsTimer == null || !_gpsTimer!.isActive) {
        _sendCurrentGps();
        _gpsTimer = Timer.periodic(const Duration(seconds: 12), (_) {
          if (mounted) _sendCurrentGps();
        });
      }
    } else {
      _gpsTimer?.cancel();
      _gpsTimer = null;
    }
  }

  Future<void> _sendCurrentGps() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (mounted) {
          setState(() => _gpsStatusMessage = 'تکایە GPSـی مۆبایلەکەت هەڵبکە');
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _gpsStatusMessage = 'دەسەڵاتی شوێن (Location) پێویستە');
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final res = await ApiClient.post('/driver/location', body: {
        'lat': pos.latitude,
        'lng': pos.longitude,
      });

      if (!mounted) return;
      if (res.statusCode == 200) {
        setState(() {
          _lastLat = pos.latitude;
          _lastLng = pos.longitude;
          _lastGpsSentAt = DateTime.now();
          _gpsStatusMessage = null;
        });
      }
    } catch (_) {
      // Non-fatal; retry on next tick
    }
  }

  Future<void> _toggleDuty(bool goOnline) async {
    if (_isDutyLoading) return;
    setState(() => _isDutyLoading = true);

    try {
      final nextDuty = goOnline ? 'available' : 'offline';
      final res = await ApiClient.post('/driver/duty', body: {'duty_status': nextDuty});
      if (!mounted) return;

      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        _toast(body['message']?.toString() ?? 'دۆخی کارکردن گۆڕدرا');
        await _loadDashboard(silent: true);
        if (goOnline) {
          _sendCurrentGps();
        }
      } else {
        _toast(body['message']?.toString() ?? 'نەتوانرا دۆخ بگۆڕدرێت', isError: true);
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
        _toast(body['message']?.toString() ?? 'داواکاری وەرگیرا');
        setState(() => _orderSubTab = 0);
        await _loadDashboard(silent: true);
      } else {
        _toast(body['message']?.toString() ?? 'داواکاری بەردەست نەماوە', isError: true);
      }
    } catch (e) {
      if (mounted) _toast('$e', isError: true);
    } finally {
      if (mounted) setState(() => _busyOrderId = null);
    }
  }

  Future<void> _advanceOrderStatus(dynamic order, String nextStatus, {bool confirm = false}) async {
    final id = order['id'].toString();
    if (confirm) {
      final paymentMethod = (order['payment_method'] ?? '').toString();
      final totalStr = _formatIqd(order['total_price']);
      final isCash = paymentMethod.toLowerCase().contains('cash') || paymentMethod.contains('کاش');
      final approved = await showDialog<bool>(
        context: context,
        builder: (dCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            nextStatus == 'rejected' ? 'ڕەتکردنەوەی داواکاری' : 'دڵنیابوونەوە لە تەواوکردن',
            style: const TextStyle(fontFamily: 'Rabar', fontWeight: FontWeight.bold),
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
              child: const Text('پاشگەزبوونەوە', style: TextStyle(fontFamily: 'Rabar')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dCtx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: nextStatus == 'rejected' ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                nextStatus == 'rejected' ? 'بەڵێ، ڕەتی بکەرەوە' : 'بەڵێ، ڕادەستکرا',
                style: const TextStyle(fontFamily: 'Rabar', fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
      if (approved != true || !mounted) return;
    }

    setState(() => _busyOrderId = id);
    try {
      final res = await ApiClient.post('/driver/orders/$id/status', body: {
        'delivery_status': nextStatus,
      });
      if (!mounted) return;
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        _toast(body['message']?.toString() ?? 'دۆخەکە نوێکرایەوە');
        await _loadDashboard(silent: true);
      } else {
        _toast(body['message']?.toString() ?? 'نوێکردنەوە سەرکەوتوو نەبوو', isError: true);
      }
    } catch (e) {
      if (mounted) _toast('$e', isError: true);
    } finally {
      if (mounted) setState(() => _busyOrderId = null);
    }
  }

  Future<void> _callPhone(String? raw) async {
    final phone = (raw ?? '').trim();
    if (phone.isEmpty) {
      _toast('ژمارەی مۆبایل بەردەست نییە', isError: true);
      return;
    }
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _toast('نەتوانرا پەیوەندی بکرێت', isError: true);
    }
  }

  Future<void> _openMaps(double? lat, double? lng, String fallbackAddress) async {
    Uri uri;
    if (lat != null && lng != null) {
      uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    } else if (fallbackAddress.trim().isNotEmpty) {
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(fallbackAddress)}');
    } else {
      _toast('شوێن لەسەر نەخشە تۆمارنەکراوە', isError: true);
      return;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _toast('نەتوانرا نەخشە بکرێتەوە', isError: true);
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

  void _toast(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Rabar')),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Iconsax.location_slash, size: 16, color: Color(0xFFD97706)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _gpsStatusMessage!,
                          style: const TextStyle(fontFamily: 'Rabar', fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                        ),
                      ),
                      TextButton(
                        onPressed: _sendCurrentGps,
                        child: const Text('چالاککردن', style: TextStyle(fontFamily: 'Rabar', fontSize: 11.5, fontWeight: FontWeight.bold)),
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
                                  const Icon(Iconsax.info_circle, size: 48, color: Colors.amber),
                                  const SizedBox(height: 12),
                                  Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Rabar')),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _loadDashboard,
                                    icon: const Icon(Icons.refresh, size: 18),
                                    label: const Text('دووبارە هەوڵبدەرەوە', style: TextStyle(fontFamily: 'Rabar')),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : IndexedStack(
                            index: _tabIndex,
                            children: [
                              _buildTasksTab(isDark),
                              _buildLiveMapTab(isDark),
                              _buildProfileTab(isDark),
                            ],
                          ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.getSurface(context),
            border: Border(top: BorderSide(color: AppColors.getBorder(context))),
          ),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 10,
            bottom: MediaQuery.of(context).padding.bottom + 10,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavButton(0, Iconsax.truck_fast, 'داواکارییەکان', badge: _activeOrders.length),
              _buildNavButton(1, Iconsax.map_1, 'نەخشە'),
              _buildNavButton(2, Iconsax.user_square, 'پڕۆفایل و داهات'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, String duty, bool isOnline) {
    final driverName = (_driver['name'] ?? 'کارمەندی گەیاندن').toString();
    final dutyLabel = switch (duty) {
      'busy' => 'لە گەیاندندایت',
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
            child: Icon(Iconsax.truck_fast, color: dutyColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextTitle(context),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: dutyColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        dutyLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: dutyColor,
                        ),
                      ),
                    ),
                    if (_lastGpsSentAt != null && isOnline) ...[
                      const SizedBox(width: 6),
                      const Icon(Iconsax.gps, size: 12, color: Color(0xFF10B981)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _isDutyLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
              : Switch.adaptive(
                  value: isOnline,
                  activeTrackColor: const Color(0xFF10B981),
                  onChanged: (val) => _toggleDuty(val),
                ),
        ],
      ),
    );
  }

  Widget _buildNavButton(int index, IconData icon, String label, {int badge = 0}) {
    final active = _tabIndex == index;
    return InkWell(
      onTap: () => setState(() => _tabIndex = index),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2563EB).withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 20, color: active ? const Color(0xFF2563EB) : const Color(0xFF94A3B8)),
                if (badge > 0)
                  Positioned(
                    top: -5,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          '$badge',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white, height: 1),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Rabar',
                fontSize: 12,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
                color: active ? const Color(0xFF2563EB) : const Color(0xFF64748B),
              ),
            ),
          ],
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
                              Icon(Iconsax.box_tick, size: 54, color: Colors.grey.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              Text(
                                _orderSubTab == 0
                                    ? 'هیچ گەیاندنێکی چالاکت نییە'
                                    : (_orderSubTab == 1 ? 'هیچ داواکارییەکی ئامادە نییە' : 'هێشتا گەیاندن تەواو نەکراوە'),
                                style: TextStyle(fontFamily: 'Rabar', fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.getTextSubtitle(context)),
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
                    itemBuilder: (_, i) => _buildOrderCard(currentList[i], isDark, isPool: _orderSubTab == 1),
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
            color: selected ? const Color(0xFF2563EB) : AppColors.getSurface(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? const Color(0xFF2563EB) : AppColors.getBorder(context)),
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

  Widget _buildOrderCard(dynamic order, bool isDark, {required bool isPool}) {
    final id = order['id'].toString();
    final isBusy = _busyOrderId == id;
    final isLab = order['is_lab'] == true;
    final stage = (order['delivery_status'] ?? 'unassigned').toString();
    final orderStatus = (order['status'] ?? 'pending').toString();
    final pickup = (order['pickup'] is Map) ? order['pickup'] as Map : {};
    final patient = (order['patient'] is Map) ? order['patient'] as Map : {};
    final items = (order['items'] is List) ? order['items'] as List : [];

    final serviceColor = isLab ? const Color(0xFF8B5CF6) : const Color(0xFF0D9488);
    final pickupLat = double.tryParse('${pickup['lat'] ?? ''}');
    final pickupLng = double.tryParse('${pickup['lng'] ?? ''}');
    final destLat = double.tryParse('${patient['lat'] ?? ''}');
    final destLng = double.tryParse('${patient['lng'] ?? ''}');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: serviceColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isLab ? 'نموونەی تاقیگە' : 'گەیاندنی دەرمان',
                  style: TextStyle(fontFamily: 'Rabar', fontSize: 11, fontWeight: FontWeight.bold, color: serviceColor),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                order['order_number'] ?? '#$id',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.getTextTitle(context)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPool ? 'ئامادە بۆ وەرگرتن' : _deliveryStageLabel(stage, isLab),
                  style: const TextStyle(fontFamily: 'Rabar', fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Stop 1: Pharmacy or Lab
          _buildStopTile(
            title: isLab ? 'تاقیگەی دیاریکراو' : 'وەرگرتن لە دەرمانخانە',
            name: (pickup['name'] ?? '').toString(),
            address: (pickup['address'] ?? '').toString(),
            phone: (pickup['phone'] ?? '').toString(),
            lat: pickupLat,
            lng: pickupLng,
            accentColor: serviceColor,
            icon: isLab ? Iconsax.microscope : Iconsax.shop,
          ),
          const SizedBox(height: 10),

          // Stop 2: Patient Location
          _buildStopTile(
            title: isLab ? 'ماڵی نەخۆش (وەرگرتنی نموونە)' : 'شوێنی نەخۆش (گەیاندن)',
            name: (patient['name'] ?? 'نەخۆش').toString(),
            address: (patient['address'] ?? '').toString(),
            phone: (patient['phone'] ?? '').toString(),
            lat: destLat,
            lng: destLng,
            accentColor: const Color(0xFF2563EB),
            icon: Iconsax.location,
          ),

          if ((patient['notes'] ?? '').toString().trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'تێبینی: ${patient['notes']}',
                style: TextStyle(fontFamily: 'Rabar', fontSize: 11.5, color: AppColors.getTextSubtitle(context)),
              ),
            ),
          ],

          if (items.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: items.take(4).map((it) {
                final m = it is Map ? it : {};
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  Text('کۆی پسوڵە', style: TextStyle(fontFamily: 'Rabar', fontSize: 10.5, color: AppColors.getTextSubtitle(context))),
                  Text(
                    _formatIqd(order['total_price']),
                    style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.getTextTitle(context)),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('کرێی گەیاندن', style: TextStyle(fontFamily: 'Rabar', fontSize: 10.5, color: AppColors.getTextSubtitle(context))),
                  Text(
                    _formatIqd(order['delivery_fee']),
                    style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                  ),
                ],
              ),
            ],
          ),

          if (orderStatus != 'completed' && orderStatus != 'cancelled') ...[
            const SizedBox(height: 14),
            if (isPool)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isBusy ? null : () => _claimOrder(order),
                  icon: isBusy
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Iconsax.tick_circle, size: 18),
                  label: const Text('وەرگرتنی ئەم داواکارییە', style: TextStyle(fontFamily: 'Rabar', fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              )
            else
              _buildProgressionActions(order, stage, isLab, isBusy),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressionActions(dynamic order, String stage, bool isLab, bool isBusy) {
    final (String nextStage, String buttonLabel, Color color, bool needsConfirm) = switch (stage) {
      'assigned' => ('accepted', 'قبوڵکردنی ئەرک', const Color(0xFF2563EB), false),
      'accepted' => ('picked_up', isLab ? 'نموونە وەرگیرا' : 'لە دەرمانخانە وەرگیرا', const Color(0xFF8B5CF6), false),
      'picked_up' => ('on_the_way', 'لە ڕێگادام', const Color(0xFFF59E0B), false),
      'on_the_way' => ('arrived', 'گەیشتمە شوێنەکە', const Color(0xFF0D9488), false),
      _ => ('delivered', isLab ? 'گەیەنرایە تاقیگە (تەواو)' : 'ڕادەستکرا (تەواو)', const Color(0xFF10B981), true),
    };

    return Row(
      children: [
        if (stage == 'assigned' || stage == 'accepted') ...[
          OutlinedButton(
            onPressed: isBusy ? null : () => _advanceOrderStatus(order, 'rejected', confirm: true),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              side: const BorderSide(color: Color(0xFFEF4444)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('ڕەتکردنەوە', style: TextStyle(fontFamily: 'Rabar', fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isBusy ? null : () => _advanceOrderStatus(order, nextStage, confirm: needsConfirm),
            icon: isBusy
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Iconsax.arrow_left_2, size: 18),
            label: Text(buttonLabel, style: const TextStyle(fontFamily: 'Rabar', fontSize: 13, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStopTile({
    required String title,
    required String name,
    required String address,
    required String phone,
    required double? lat,
    required double? lng,
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
                Text(title, style: TextStyle(fontFamily: 'Rabar', fontSize: 10.5, fontWeight: FontWeight.bold, color: accentColor)),
                const SizedBox(height: 2),
                Text(
                  name.isNotEmpty ? name : 'دیاری نەکراوە',
                  style: TextStyle(fontFamily: 'Rabar', fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.getTextTitle(context)),
                ),
                if (address.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: 'Rabar', fontSize: 11.5, color: AppColors.getTextSubtitle(context)),
                  ),
                ],
              ],
            ),
          ),
          if (phone.isNotEmpty)
            IconButton(
              onPressed: () => _callPhone(phone),
              icon: const Icon(Iconsax.call, size: 18, color: Color(0xFF10B981)),
              tooltip: 'پەیوەندی',
              visualDensity: VisualDensity.compact,
            ),
          if (lat != null && lng != null || address.trim().isNotEmpty)
            IconButton(
              onPressed: () => _openMaps(lat, lng, address),
              icon: const Icon(Iconsax.routing, size: 18, color: Color(0xFF2563EB)),
              tooltip: 'نەخشە',
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _buildLiveMapTab(bool isDark) {
    final center = LatLng(_lastLat ?? 36.1911, _lastLng ?? 44.0092);
    final markers = <Marker>{};

    if (_lastLat != null && _lastLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver_self'),
          position: LatLng(_lastLat!, _lastLng!),
          infoWindow: const InfoWindow(title: 'شوێنی ئێستای من'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }

    for (final o in _activeOrders) {
      final p = o['patient'] is Map ? o['patient'] as Map : {};
      final pLat = double.tryParse('${p['lat'] ?? ''}');
      final pLng = double.tryParse('${p['lng'] ?? ''}');
      if (pLat != null && pLng != null) {
        markers.add(
          Marker(
            markerId: MarkerId('dest_${o['id']}'),
            position: LatLng(pLat, pLng),
            infoWindow: InfoWindow(
              title: 'نەخۆش: ${p['name'] ?? ''}',
              snippet: 'داواکاری ${o['order_number'] ?? '#${o['id']}'}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
      }

      final pk = o['pickup'] is Map ? o['pickup'] as Map : {};
      final pkLat = double.tryParse('${pk['lat'] ?? ''}');
      final pkLng = double.tryParse('${pk['lng'] ?? ''}');
      if (pkLat != null && pkLng != null) {
        markers.add(
          Marker(
            markerId: MarkerId('pickup_${o['id']}'),
            position: LatLng(pkLat, pkLng),
            infoWindow: InfoWindow(title: '${pk['name'] ?? ''}'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          ),
        );
      }
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: center, zoom: 13.5),
          cameraTargetBounds: ErbilMapService.erbilCameraBounds,
          markers: markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
          onMapCreated: (c) => _mapController = c,
        ),
        Positioned(
          top: 12,
          right: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.getSurface(context).withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.getBorder(context)),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.gps, color: Color(0xFF2563EB), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'داواکاری چالاک: ${_activeOrders.length} · دواین GPS: ${_lastLat != null ? '${_lastLat!.toStringAsFixed(4)}, ${_lastLng!.toStringAsFixed(4)}' : 'نادیار'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'Rabar', fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: _sendCurrentGps,
                  icon: const Icon(Icons.my_location, size: 18, color: Color(0xFF10B981)),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileTab(bool isDark) {
    final phone = (_driver['phone'] ?? '').toString();
    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildMiniStat('گەیاندنی ئەمڕۆ', '${_stats['today_deliveries'] ?? 0}', Iconsax.box_tick, const Color(0xFF2563EB)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMiniStat('داهاتی ئەمڕۆ', _formatIqd(_stats['today_earnings']), Iconsax.wallet_2, const Color(0xFF10B981)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat('کۆی گەیاندن', '${_stats['total_deliveries'] ?? 0}', Iconsax.award, const Color(0xFF8B5CF6)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMiniStat('کۆی داهات', _formatIqd(_stats['total_earnings']), Iconsax.money_recive, const Color(0xFFF59E0B)),
              ),
            ],
          ),
          const SizedBox(height: 18),

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
                const Text('زانیاری کارمەندی گەیاندن', style: TextStyle(fontFamily: 'Rabar', fontSize: 14, fontWeight: FontWeight.bold)),
                const Divider(height: 22),
                _buildInfoRow('ناو', (_driver['name'] ?? '').toString()),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ژمارەی مۆبایل', style: TextStyle(fontFamily: 'Rabar', fontSize: 12.5, color: AppColors.getTextSubtitle(context))),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text('\u200E$phone', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildInfoRow('شار', (_driver['city'] ?? 'هەولێر').toString()),
                const SizedBox(height: 10),
                _buildInfoRow('ئامێری گواستنەوە', _vehicleLabel(_driver['vehicle_type']?.toString())),
                if ((_driver['plate_number'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildInfoRow('ژمارەی تابلۆ', (_driver['plate_number']).toString()),
                ],
                const SizedBox(height: 10),
                _buildInfoRow('بوار', _scopeLabel(_driver['service_scope']?.toString())),
              ],
            ),
          ),

          const SizedBox(height: 22),
          ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Iconsax.logout, size: 18),
            label: const Text('چوونەدەرەوە لە هەژمار', style: TextStyle(fontFamily: 'Rabar', fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Rabar', fontSize: 11, color: AppColors.getTextSubtitle(context))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(val, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String k, String v) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(k, style: TextStyle(fontFamily: 'Rabar', fontSize: 12.5, color: AppColors.getTextSubtitle(context))),
        Flexible(
          child: Text(v, textAlign: TextAlign.end, style: const TextStyle(fontFamily: 'Rabar', fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
