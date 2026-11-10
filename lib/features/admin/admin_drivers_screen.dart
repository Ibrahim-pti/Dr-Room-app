import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart' as intl;
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/api_client.dart';
import '../../core/utils/erbil_map_service.dart';
import 'admin_app_bar.dart';
import 'admin_ui.dart';

class AdminDriversScreen extends StatefulWidget {
  const AdminDriversScreen({super.key});

  @override
  State<AdminDriversScreen> createState() => _AdminDriversScreenState();
}

class _AdminDriversScreenState extends State<AdminDriversScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  bool _isLoading = true;
  String? _error;
  List<dynamic> _drivers = [];
  List<dynamic> _liveMapDrivers = [];
  Map<String, dynamic> _meta = {};
  Map<String, dynamic>? _selectedMapDriver;

  String _search = '';
  String _dutyFilter = 'all'; // all, available, busy, offline, blocked
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  Timer? _liveMapTimer;
  GoogleMapController? _mapCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging && _tabCtrl.index == 0) {
        _loadLiveMap();
      }
    });
    _loadAll();
    _liveMapTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted && _tabCtrl.index == 0) {
        _loadLiveMap(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    _liveMapTimer?.cancel();
    _mapCtrl?.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadDrivers(), _loadLiveMap(silent: true)]);
  }

  Future<void> _loadDrivers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final params = <String>[
        if (_search.isNotEmpty) 'search=${Uri.encodeComponent(_search)}',
        if (_dutyFilter == 'blocked') 'status=blocked',
        if (_dutyFilter == 'available' || _dutyFilter == 'busy' || _dutyFilter == 'offline')
          'duty_status=$_dutyFilter',
      ];
      final query = params.isNotEmpty ? '?${params.join('&')}' : '';
      final res = await ApiClient.get('/admin/drivers$query');
      if (!mounted) return;

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() {
          _drivers = List<dynamic>.from(body['data'] ?? []);
          _meta = body['meta'] is Map ? Map<String, dynamic>.from(body['meta']) : {};
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = AdminUi.readError(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _isLoading = false; });
    }
  }

  Future<void> _loadLiveMap({bool silent = false}) async {
    try {
      final res = await ApiClient.get('/admin/drivers/live-map');
      if (!mounted || res.statusCode != 200) return;
      final list = List<dynamic>.from(jsonDecode(res.body)['data'] ?? []);
      setState(() {
        _liveMapDrivers = list;
        if (_selectedMapDriver != null) {
          final match = list.where((d) => d['id'] == _selectedMapDriver!['id']).toList();
          if (match.isNotEmpty) {
            _selectedMapDriver = Map<String, dynamic>.from(match.first);
          }
        }
      });
    } catch (_) {
      if (!silent && mounted) {
        AdminUi.toast(context, 'نەتوانرا نەخشەی زیندوو نوێبکرێتەوە', isError: true);
      }
    }
  }

  void _onSearchChanged(String val) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _search = val.trim();
      _loadDrivers();
    });
  }

  Future<void> _approveDriver(dynamic d) async {
    try {
      final res = await ApiClient.patch('/admin/drivers/${d['id']}/approve');
      if (!mounted) return;
      if (res.statusCode == 200) {
        AdminUi.toast(context, 'کارمەندی گەیاندن پەسەندکرا');
        _loadAll();
      } else {
        AdminUi.toast(context, AdminUi.readError(res), isError: true);
      }
    } catch (e) {
      if (mounted) AdminUi.toast(context, '$e', isError: true);
    }
  }

  Future<void> _rejectDriver(dynamic d) async {
    try {
      final res = await ApiClient.patch('/admin/drivers/${d['id']}/reject');
      if (!mounted) return;
      if (res.statusCode == 200) {
        AdminUi.toast(context, 'داواکارییەکە ڕەتکرایەوە');
        _loadAll();
      } else {
        AdminUi.toast(context, AdminUi.readError(res), isError: true);
      }
    } catch (e) {
      if (mounted) AdminUi.toast(context, '$e', isError: true);
    }
  }

  Future<void> _toggleBlock(dynamic d) async {
    try {
      final res = await ApiClient.patch('/admin/drivers/${d['id']}/toggle-block');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final msg = jsonDecode(res.body)['message']?.toString() ?? 'دۆخ گۆڕدرا';
        AdminUi.toast(context, msg);
        _loadAll();
      } else {
        AdminUi.toast(context, AdminUi.readError(res), isError: true);
      }
    } catch (e) {
      if (mounted) AdminUi.toast(context, '$e', isError: true);
    }
  }

  Future<void> _openAddDriverDialog() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final plateCtrl = TextEditingController();
    String city = 'هەولێر';
    String vehicle = 'motorcycle';
    String scope = 'both';
    bool saving = false;

    try {
      await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (dCtx, setDState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('زیادکردنی کارمەندی گەیاندن', style: TextStyle(fontFamily: 'Rabar', fontWeight: FontWeight.bold, fontSize: 16)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'ناوی تەواو',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: 'ژمارەی مۆبایل (0750...)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: 'وشەی تێپەڕ (لانیکەم ٦ پیت)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: city,
                    decoration: InputDecoration(labelText: 'شار', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    items: const ['هەولێر', 'سلێمانی', 'دهۆک', 'کەرکوک', 'هەڵەبجە']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontFamily: 'Rabar'))))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDState(() => city = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: vehicle,
                    decoration: InputDecoration(labelText: 'ئامێر', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    items: const [
                      DropdownMenuItem(value: 'motorcycle', child: Text('ماتۆڕسکیل', style: TextStyle(fontFamily: 'Rabar'))),
                      DropdownMenuItem(value: 'car', child: Text('ئۆتۆمبێل', style: TextStyle(fontFamily: 'Rabar'))),
                      DropdownMenuItem(value: 'refrigerated_van', child: Text('ساردکەرەوەی تاقیگە', style: TextStyle(fontFamily: 'Rabar'))),
                    ],
                    onChanged: (v) {
                      if (v != null) setDState(() => vehicle = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: scope,
                    decoration: InputDecoration(labelText: 'بوار', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    items: const [
                      DropdownMenuItem(value: 'both', child: Text('دەرمان + نموونەی تاقیگە', style: TextStyle(fontFamily: 'Rabar'))),
                      DropdownMenuItem(value: 'pharmacy', child: Text('دەرمان تەنها', style: TextStyle(fontFamily: 'Rabar'))),
                      DropdownMenuItem(value: 'lab_sample', child: Text('نموونەی تاقیگە تەنها', style: TextStyle(fontFamily: 'Rabar'))),
                    ],
                    onChanged: (v) {
                      if (v != null) setDState(() => scope = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: plateCtrl,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: 'ژمارەی تابلۆ (ئارەزوومەندانە)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dCtx),
                child: const Text('پاشگەزبوونەوە', style: TextStyle(fontFamily: 'Rabar')),
              ),
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (nameCtrl.text.trim().isEmpty ||
                            phoneCtrl.text.trim().isEmpty ||
                            passCtrl.text.length < 6) {
                          AdminUi.toast(context, 'تکایە ناو، مۆبایل و وشەی تێپەڕ (٦ پیت+) بنووسە', isError: true);
                          return;
                        }
                        setDState(() => saving = true);
                        try {
                          final res = await ApiClient.post('/admin/drivers', body: {
                            'name': nameCtrl.text.trim(),
                            'phone': phoneCtrl.text.trim(),
                            'password': passCtrl.text,
                            'city': city,
                            'vehicle_type': vehicle,
                            'service_scope': scope,
                            'plate_number': plateCtrl.text.trim(),
                          });
                          if (dCtx.mounted) Navigator.pop(dCtx);
                          if (!mounted) return;
                          if (res.statusCode == 201 || res.statusCode == 200) {
                            AdminUi.toast(context, 'کارمەندی گەیاندن زیادکرا');
                            _loadAll();
                          } else {
                            AdminUi.toast(context, AdminUi.readError(res), isError: true);
                          }
                        } catch (e) {
                          if (mounted) AdminUi.toast(context, '$e', isError: true);
                        } finally {
                          if (dCtx.mounted) setDState(() => saving = false);
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('زیادکردن', style: TextStyle(fontFamily: 'Rabar')),
              ),
            ],
          ),
        ),
      );
    } finally {
      nameCtrl.dispose();
      phoneCtrl.dispose();
      passCtrl.dispose();
      plateCtrl.dispose();
    }
  }

  Future<void> _callPhone(String? raw) async {
    final p = (raw ?? '').trim();
    if (p.isEmpty) return;
    final clean = p.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openWhatsApp(String? raw) async {
    var clean = (raw ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return;
    if (clean.startsWith('07')) clean = '964${clean.substring(1)}';
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _formatIqd(dynamic v) {
    final d = double.tryParse(v?.toString() ?? '0') ?? 0;
    return '${intl.NumberFormat('#,###').format(d)} د.ع';
  }

  String _vehicleLabel(String? v) => switch (v) {
        'car' => 'ئۆتۆمبێل',
        'refrigerated_van' => 'ساردکەرەوە',
        _ => 'ماتۆڕ',
      };

  String _scopeLabel(String? s) => switch (s) {
        'pharmacy' => 'دەرمان',
        'lab_sample' => 'تاقیگە',
        _ => 'دەرمان + تاقیگە',
      };

  String _lastSeenText(dynamic secRaw) {
    final sec = int.tryParse('${secRaw ?? ''}');
    if (sec == null) return 'شوێن نەنێردراوە';
    if (sec < 60) return 'پێش $sec چرکە';
    final min = sec ~/ 60;
    if (min < 60) return 'پێش $min خولەک';
    return 'پێش ${min ~/ 60} کاتژمێر';
  }

  Color _dutyColor(String? duty, String? status) {
    if (status == 'pending') return const Color(0xFFF59E0B);
    if (status == 'blocked' || status == 'rejected') return const Color(0xFFEF4444);
    return switch (duty) {
      'available' => const Color(0xFF10B981),
      'busy' => const Color(0xFF2563EB),
      _ => const Color(0xFF64748B),
    };
  }

  String _dutyLabel(String? duty, String? status) {
    if (status == 'pending') return 'چاوەڕوانی پەسەند';
    if (status == 'blocked' || status == 'rejected') return 'بلۆککراوە';
    return switch (duty) {
      'available' => 'ئامادە (Online)',
      'busy' => 'لە گەیاندندایە',
      _ => 'ئۆفلاین',
    };
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = int.tryParse('${_meta['pending_count'] ?? 0}') ?? 0;
    final onlineCount = int.tryParse('${_meta['online_count'] ?? 0}') ?? 0;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AdminAppBar(
        title: 'کارمەندانی گەیاندن (دلیڤەری)',
        subtitle: '$onlineCount لە هێڵ · $pendingCount داواکاری نوێ',
        icon: Iconsax.truck_fast,
        iconColor: const Color(0xFF10B981),
        iconBackgroundColor: const Color(0xFF10B981).withValues(alpha: 0.12),
        showBackButton: true,
        actions: [
          IconButton(
            onPressed: _openAddDriverDialog,
            icon: const Icon(Iconsax.user_add, color: Color(0xFF2563EB)),
            tooltip: 'زیادکردنی شۆفێر',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.getSurface(context),
            child: TabBar(
              controller: _tabCtrl,
              labelColor: const Color(0xFF2563EB),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF2563EB),
              labelStyle: const TextStyle(fontFamily: 'Rabar', fontSize: 12, fontWeight: FontWeight.bold),
              tabs: [
                const Tab(icon: Icon(Iconsax.map_1, size: 18), text: 'نەخشەی زیندوو'),
                Tab(
                  icon: Badge(
                    isLabelVisible: pendingCount > 0,
                    label: Text('$pendingCount'),
                    child: const Icon(Iconsax.user_tick, size: 18),
                  ),
                  text: 'داواکاری نوێ',
                ),
                const Tab(icon: Icon(Iconsax.people, size: 18), text: 'هەموو شۆفێرەکان'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              physics: const NeverScrollableScrollPhysics(), // Don't steal GoogleMap horizontal pan
              children: [
                _buildLiveMapTab(),
                _buildPendingTab(),
                _buildRosterTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveMapTab() {
    final markers = <Marker>{};
    LatLng initialCenter = const LatLng(36.1911, 44.0092);

    for (final d in _liveMapDrivers) {
      final lat = double.tryParse('${d['current_lat'] ?? ''}');
      final lng = double.tryParse('${d['current_lng'] ?? ''}');
      if (lat == null || lng == null) continue;
      initialCenter = LatLng(lat, lng);

      final duty = (d['duty_status'] ?? 'offline').toString();
      final hue = switch (duty) {
        'available' => BitmapDescriptor.hueGreen,
        'busy' => BitmapDescriptor.hueAzure,
        _ => BitmapDescriptor.hueOrange,
      };

      markers.add(
        Marker(
          markerId: MarkerId('drv_${d['id']}'),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(
            title: (d['name'] ?? '').toString(),
            snippet: '${_dutyLabel(duty, 'approved')} · ${_lastSeenText(d['last_seen_seconds'])}',
          ),
          onTap: () {
            setState(() => _selectedMapDriver = Map<String, dynamic>.from(d));
          },
        ),
      );

      final activeOrder = d['active_order'];
      if (activeOrder is Map && activeOrder['dest_lat'] != null && activeOrder['dest_lng'] != null) {
        final dLat = double.tryParse('${activeOrder['dest_lat']}');
        final dLng = double.tryParse('${activeOrder['dest_lng']}');
        if (dLat != null && dLng != null) {
          markers.add(
            Marker(
              markerId: MarkerId('order_${activeOrder['id']}'),
              position: LatLng(dLat, dLng),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
              infoWindow: InfoWindow(title: 'ئامانجی داواکاری #${activeOrder['id']}'),
            ),
          );
        }
      }
    }

    final available = _meta['available_count'] ?? 0;
    final busy = _meta['busy_count'] ?? 0;

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: initialCenter, zoom: 12.8),
          cameraTargetBounds: ErbilMapService.erbilCameraBounds,
          markers: markers,
          zoomControlsEnabled: false,
          onMapCreated: (c) => _mapCtrl = c,
          onTap: (_) => setState(() => _selectedMapDriver = null),
        ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.getSurface(context).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.getBorder(context)),
            ),
            child: Row(
              children: [
                _dotLegend('ئامادە: $available', const Color(0xFF10B981)),
                const SizedBox(width: 12),
                _dotLegend('لە گەیاندن: $busy', const Color(0xFF2563EB)),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    _loadAll();
                    _loadLiveMap();
                  },
                  icon: const Icon(Icons.refresh, size: 18, color: Color(0xFF2563EB)),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
        if (_liveMapDrivers.where((d) => d['current_lat'] != null).isEmpty)
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.getBorder(context)),
              ),
              child: const Text(
                'هێشتا هیچ شۆفێرێکی ئۆنلاین شوێنی GPSـی خۆی نەناردووە. کاتێک شۆفێر لە ئەپەکە خۆی ئۆنلاین دەکات، لێرە دەردەکەوێت.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Rabar', fontSize: 12),
              ),
            ),
          ),
        if (_selectedMapDriver != null)
          Positioned(
            bottom: 18,
            left: 14,
            right: 14,
            child: _buildMapDriverCard(_selectedMapDriver!),
          ),
      ],
    );
  }

  Widget _dotLegend(String text, Color c) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontFamily: 'Rabar', fontSize: 11.5, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMapDriverCard(Map<String, dynamic> d) {
    final duty = (d['duty_status'] ?? 'offline').toString();
    final color = _dutyColor(duty, 'approved');
    final activeOrder = d['active_order'] is Map ? d['active_order'] as Map : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.getBorder(context)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(Iconsax.truck_fast, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((d['name'] ?? '').toString(), style: const TextStyle(fontFamily: 'Rabar', fontSize: 14, fontWeight: FontWeight.bold)),
                    Text(
                      '${_dutyLabel(duty, 'approved')} · ${_vehicleLabel(d['vehicle_type']?.toString())} · ${_lastSeenText(d['last_seen_seconds'])}',
                      style: TextStyle(fontFamily: 'Rabar', fontSize: 11, color: color),
                    ),
                  ],
                ),
              ),
              IconButton(onPressed: () => _callPhone(d['phone']?.toString()), icon: const Icon(Iconsax.call, color: Color(0xFF2563EB))),
              IconButton(onPressed: () => _openWhatsApp(d['phone']?.toString()), icon: const Icon(Iconsax.message, color: Color(0xFF10B981))),
            ],
          ),
          if (activeOrder != null) ...[
            const Divider(height: 16),
            Row(
              children: [
                const Icon(Iconsax.box, size: 15, color: Color(0xFF2563EB)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'داواکاری چالاک #${activeOrder['id']} · ${activeOrder['dest_address'] ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'Rabar', fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    final pending = _drivers.where((d) => d['status'] == 'pending').toList();
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (pending.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.user_tick, size: 52, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text('هیچ داواکارییەکی نوێ نییە', style: AdminUi.title),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: pending.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final d = pending[i];
          final phone = (d['phone'] ?? '').toString();
          return Container(
            decoration: AdminUi.cardDecoration,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Iconsax.user_add, color: Color(0xFFF59E0B)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text((d['name'] ?? '').toString(), style: AdminUi.title),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text('\u200E$phone', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B))),
                          ),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => _callPhone(phone), icon: const Icon(Iconsax.call, color: Color(0xFF2563EB))),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _tagChip('${d['city'] ?? 'هەولێر'}', Iconsax.location),
                    _tagChip(_vehicleLabel(d['vehicle_type']?.toString()), Iconsax.car),
                    _tagChip(_scopeLabel(d['service_scope']?.toString()), Iconsax.box),
                    if ((d['plate_number'] ?? '').toString().isNotEmpty)
                      _tagChip('${d['plate_number']}', Iconsax.card),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rejectDriver(d),
                        icon: const Icon(Iconsax.close_circle, size: 17),
                        label: const Text('ڕەتکردنەوە', style: TextStyle(fontFamily: 'Rabar', fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _approveDriver(d),
                        icon: const Icon(Iconsax.tick_circle, size: 17),
                        label: const Text('پەسەندکردن', style: TextStyle(fontFamily: 'Rabar', fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _tagChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.getBackground(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontFamily: 'Rabar', fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildRosterTab() {
    final filters = [
      (key: 'all', label: 'هەموو'),
      (key: 'available', label: 'ئامادە'),
      (key: 'busy', label: 'لە گەیاندن'),
      (key: 'offline', label: 'ئۆفلاین'),
      (key: 'blocked', label: 'بلۆککراو'),
    ];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          color: AppColors.getSurface(context),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'گەڕان بەپێی ناو، مۆبایل، شار یان تابلۆ...',
                  hintStyle: const TextStyle(fontFamily: 'Rabar', fontSize: 12),
                  prefixIcon: const Icon(Iconsax.search_normal, size: 18),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.getBackground(context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: filters.map((f) {
                    final sel = _dutyFilter == f.key;
                    return Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ChoiceChip(
                        label: Text(
                          f.label,
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 11.5,
                            color: sel ? Colors.white : AppColors.getTextSubtitle(context),
                          ),
                        ),
                        selected: sel,
                        selectedColor: const Color(0xFF2563EB),
                        onSelected: (_) {
                          setState(() => _dutyFilter = f.key);
                          _loadDrivers();
                        },
                      ),
                    );
                  }).toList(),
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, style: AdminUi.subtitle),
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: _loadAll, child: const Text('دووبارە هەوڵبدەرەوە', style: TextStyle(fontFamily: 'Rabar'))),
                        ],
                      ),
                    )
                  : _drivers.isEmpty
                      ? Center(child: Text('هیچ کارمەندێک نەدۆزرایەوە', style: AdminUi.title))
                      : RefreshIndicator(
                          onRefresh: _loadAll,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _drivers.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (_, i) => _buildDriverRosterCard(_drivers[i]),
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildDriverRosterCard(dynamic d) {
    final status = (d['status'] ?? 'approved').toString();
    final duty = (d['duty_status'] ?? 'offline').toString();
    final color = _dutyColor(duty, status);
    final phone = (d['phone'] ?? '').toString();
    final isBlocked = status == 'blocked' || status == 'rejected';

    return Container(
      decoration: AdminUi.cardDecoration,
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Iconsax.truck_fast, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            (d['name'] ?? '').toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AdminUi.title.copyWith(fontSize: 14),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _dutyLabel(duty, status),
                            style: TextStyle(fontFamily: 'Rabar', fontSize: 10, fontWeight: FontWeight.bold, color: color),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        '\u200E$phone',
                        style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _tagChip('${d['city'] ?? 'هەولێر'} · ${_vehicleLabel(d['vehicle_type']?.toString())}', Iconsax.location),
              const SizedBox(width: 6),
              _tagChip('${d['completed_deliveries'] ?? 0} گەیاندن · ${_formatIqd(d['total_earnings'])}', Iconsax.box_tick),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton(
                onPressed: () => _callPhone(phone),
                icon: const Icon(Iconsax.call, size: 18, color: Color(0xFF2563EB)),
                tooltip: 'پەیوەندی',
              ),
              IconButton(
                onPressed: () => _openWhatsApp(phone),
                icon: const Icon(Iconsax.message, size: 18, color: Color(0xFF10B981)),
                tooltip: 'واتسئاپ',
              ),
              if (d['current_lat'] != null && d['current_lng'] != null)
                TextButton.icon(
                  onPressed: () {
                    _tabCtrl.animateTo(0);
                    setState(() => _selectedMapDriver = Map<String, dynamic>.from(d));
                    _mapCtrl?.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(double.parse('${d['current_lat']}'), double.parse('${d['current_lng']}')),
                        15,
                      ),
                    );
                  },
                  icon: const Icon(Iconsax.gps, size: 15),
                  label: Text(_lastSeenText(d['last_seen_seconds']), style: const TextStyle(fontFamily: 'Rabar', fontSize: 11)),
                ),
              const Spacer(),
              if (status == 'pending')
                ElevatedButton(
                  onPressed: () => _approveDriver(d),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                  child: const Text('پەسەندکردن', style: TextStyle(fontFamily: 'Rabar', fontSize: 11.5)),
                )
              else
                OutlinedButton(
                  onPressed: () => _toggleBlock(d),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isBlocked ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    side: BorderSide(color: isBlocked ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                  ),
                  child: Text(isBlocked ? 'چالاککردن' : 'بلۆککردن', style: const TextStyle(fontFamily: 'Rabar', fontSize: 11.5)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

