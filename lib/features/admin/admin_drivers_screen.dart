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
import 'admin_recruitment_options_screen.dart';
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
  Map<String, String> _dynamicEducationLabels = {};
  Map<String, String> _dynamicSkillLabels = {};

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
    await Future.wait([
      _loadDrivers(),
      _loadLiveMap(silent: true),
      _loadRecruitmentOptions(),
    ]);
  }

  Future<void> _loadRecruitmentOptions() async {
    try {
      final res = await ApiClient.get('/admin/recruitment-options');
      if (!mounted || res.statusCode != 200) return;
      final decoded = jsonDecode(res.body);
      if (decoded is! List) return;
      final edu = <String, String>{};
      final sk = <String, String>{};
      for (final item in decoded) {
        final key = (item['option_key'] ?? '').toString();
        final label = (item['label_ckb'] ?? '').toString();
        if (key.isEmpty || label.isEmpty) continue;
        if (item['type'] == 'education') {
          edu[key] = label;
        } else if (item['type'] == 'skill') {
          sk[key] = label;
        }
      }
      setState(() {
        _dynamicEducationLabels = edu;
        _dynamicSkillLabels = sk;
      });
    } catch (_) {}
  }

  Future<void> _openRecruitmentOptions() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminRecruitmentOptionsScreen()),
    );
    if (mounted) _loadRecruitmentOptions();
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
        if (_dutyFilter == 'available' ||
            _dutyFilter == 'busy' ||
            _dutyFilter == 'offline')
          'duty_status=$_dutyFilter',
      ];
      final query = params.isNotEmpty ? '?${params.join('&')}' : '';
      final res = await ApiClient.get('/admin/drivers$query');
      if (!mounted) return;

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() {
          _drivers = List<dynamic>.from(body['data'] ?? []);
          _meta = body['meta'] is Map
              ? Map<String, dynamic>.from(body['meta'])
              : {};
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = AdminUi.readError(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _error = '$e';
          _isLoading = false;
        });
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
          final match = list
              .where((d) => d['id'] == _selectedMapDriver!['id'])
              .toList();
          if (match.isNotEmpty) {
            _selectedMapDriver = Map<String, dynamic>.from(match.first);
          }
        }
      });
    } catch (_) {
      if (!silent && mounted) {
        AdminUi.toast(
          context,
          'نەتوانرا نەخشەی زیندوو نوێبکرێتەوە',
          isError: true,
        );
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
        bool smsSent = false;
        try {
          final body = jsonDecode(res.body);
          if (body is Map) smsSent = body['sms_sent'] == true;
        } catch (_) {}
        AdminUi.toast(
          context,
          smsSent
              ? 'کارمەندی گەیاندن پەسەندکرا و نامەی ئاگادارکردنەوە نێردرا'
              : 'کارمەندی گەیاندن پەسەندکرا',
        );
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
      final res = await ApiClient.patch(
        '/admin/drivers/${d['id']}/toggle-block',
      );
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'زیادکردنی کارمەندی گەیاندن',
              style: TextStyle(
                fontFamily: 'Rabar',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'ناوی تەواو',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: 'ژمارەی مۆبایل (0750...)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: 'وشەی تێپەڕ (لانیکەم ٦ پیت)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: city,
                    decoration: InputDecoration(
                      labelText: 'شار',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items:
                        const ['هەولێر', 'سلێمانی', 'دهۆک', 'کەرکوک', 'هەڵەبجە']
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(
                                  c,
                                  style: const TextStyle(fontFamily: 'Rabar'),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (v) {
                      if (v != null) setDState(() => city = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: vehicle,
                    decoration: InputDecoration(
                      labelText: 'ئامێر',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'motorcycle',
                        child: Text(
                          'ماتۆڕسکیل',
                          style: TextStyle(fontFamily: 'Rabar'),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'car',
                        child: Text(
                          'ئۆتۆمبێل',
                          style: TextStyle(fontFamily: 'Rabar'),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'refrigerated_van',
                        child: Text(
                          'ساردکەرەوەی تاقیگە',
                          style: TextStyle(fontFamily: 'Rabar'),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setDState(() => vehicle = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: scope,
                    decoration: InputDecoration(
                      labelText: 'بوار',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'both',
                        child: Text(
                          'دەرمان + نموونەی تاقیگە',
                          style: TextStyle(fontFamily: 'Rabar'),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'pharmacy',
                        child: Text(
                          'دەرمان تەنها',
                          style: TextStyle(fontFamily: 'Rabar'),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'lab_sample',
                        child: Text(
                          'نموونەی تاقیگە تەنها',
                          style: TextStyle(fontFamily: 'Rabar'),
                        ),
                      ),
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dCtx),
                child: const Text(
                  'پاشگەزبوونەوە',
                  style: TextStyle(fontFamily: 'Rabar'),
                ),
              ),
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (nameCtrl.text.trim().isEmpty ||
                            phoneCtrl.text.trim().isEmpty ||
                            passCtrl.text.length < 6) {
                          AdminUi.toast(
                            context,
                            'تکایە ناو، مۆبایل و وشەی تێپەڕ (٦ پیت+) بنووسە',
                            isError: true,
                          );
                          return;
                        }
                        setDState(() => saving = true);
                        try {
                          final res = await ApiClient.post(
                            '/admin/drivers',
                            body: {
                              'name': nameCtrl.text.trim(),
                              'phone': phoneCtrl.text.trim(),
                              'password': passCtrl.text,
                              'city': city,
                              'vehicle_type': vehicle,
                              'service_scope': scope,
                              'plate_number': plateCtrl.text.trim(),
                            },
                          );
                          if (dCtx.mounted) Navigator.pop(dCtx);
                          if (!mounted) return;
                          if (res.statusCode == 201 || res.statusCode == 200) {
                            AdminUi.toast(context, 'کارمەندی گەیاندن زیادکرا');
                            _loadAll();
                          } else {
                            AdminUi.toast(
                              context,
                              AdminUi.readError(res),
                              isError: true,
                            );
                          }
                        } catch (e) {
                          if (mounted)
                            AdminUi.toast(context, '$e', isError: true);
                        } finally {
                          if (dCtx.mounted) setDState(() => saving = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'زیادکردن',
                        style: TextStyle(fontFamily: 'Rabar'),
                      ),
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
    if (await canLaunchUrl(uri))
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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

  String _applicantRoleLabel(String? r) => switch (r) {
    'phlebotomist' => 'وەرگرتنی خوێن و تاقیگە',
    'mobile_nurse' => 'پەرستاری ماڵان',
    'both' => 'پەرستاری + شیکاری',
    'courier' => 'گەیاندنی دەرمان',
    _ => 'تیمی گەڕۆک',
  };

  String? _educationLabel(String? e) {
    final key = (e ?? '').trim();
    if (key.isEmpty) return null;
    if (_dynamicEducationLabels.containsKey(key)) {
      return _dynamicEducationLabels[key];
    }
    return switch (key) {
      'diploma_lab' => 'دبلۆم شیکاری نەخۆشی',
      'bsc_lab' => 'بەکالۆریۆس شیکاری',
      'diploma_nursing' => 'دبلۆم پەرستاری',
      'bsc_nursing' => 'بەکالۆریۆس پەرستاری',
      'high_school_course' => 'خولی پەرستاری',
      'other' => 'بڕوانامەی گشتی',
      _ => key,
    };
  }

  String? _shiftLabel(String? s) => switch (s) {
    'morning' => 'شیفتی بەیانی',
    'evening' => 'شیفتی ئێوارە و شەو',
    'full_flex' => 'تەواوی ڕۆژ / بەپێی نەخۆش',
    _ => null,
  };

  String _skillLabel(String s) {
    if (_dynamicSkillLabels.containsKey(s)) {
      return _dynamicSkillLabels[s]!;
    }
    return switch (s) {
      'venipuncture' => 'کێشانی خوێن',
      'pediatric_draw' => 'خوێنی منداڵان',
      'cannula_iv' => 'کانۆلا و سروم',
      'injections' => 'دەرزیدان',
      'wound_care' => 'پانسمان',
      'vital_signs' => 'نیشانە زیندووەکان',
      'cold_chain' => 'تیوب و ساردکەر (CBC/ESR)',
      'pharma_handling' => 'گەیاندنی دەرمانی هەستیار',
      _ => s,
    };
  }

  Future<void> _openDocUrl(String? rawUrl) async {
    final u = (rawUrl ?? '').trim();
    if (u.isEmpty) return;
    final uri = Uri.tryParse(u);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _docLinkChip(String label, String? url) {
    if ((url ?? '').trim().isEmpty) return const SizedBox.shrink();
    return InkWell(
      onTap: () => _openDocUrl(url),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3EB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFDBA74)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Iconsax.document_text,
              size: 12,
              color: Color(0xFFC2410C),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Rabar',
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9A3412),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
    if (status == 'blocked' || status == 'rejected')
      return const Color(0xFFEF4444);
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
            onPressed: _openRecruitmentOptions,
            icon: const Icon(Iconsax.book_1, color: Color(0xFFEA580C)),
            tooltip: 'بڕوانامە و شارەزاییەکان',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            onPressed: _openAddDriverDialog,
            icon: const Icon(Iconsax.user_add, color: Color(0xFF2563EB)),
            tooltip: 'زیادکردنی شۆفێر',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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
              labelStyle: const TextStyle(
                fontFamily: 'Rabar',
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              tabs: [
                const Tab(
                  icon: Icon(Iconsax.map_1, size: 18),
                  text: 'نەخشەی زیندوو',
                ),
                Tab(
                  icon: Badge(
                    isLabelVisible: pendingCount > 0,
                    label: Text('$pendingCount'),
                    child: const Icon(Iconsax.user_tick, size: 18),
                  ),
                  text: 'داواکاری نوێ',
                ),
                const Tab(
                  icon: Icon(Iconsax.people, size: 18),
                  text: 'هەموو شۆفێرەکان',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              physics:
                  const NeverScrollableScrollPhysics(), // Don't steal GoogleMap horizontal pan
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
            snippet:
                '${_dutyLabel(duty, 'approved')} · ${_lastSeenText(d['last_seen_seconds'])}',
          ),
          onTap: () {
            setState(() => _selectedMapDriver = Map<String, dynamic>.from(d));
          },
        ),
      );

      final activeOrder = d['active_order'];
      if (activeOrder is Map &&
          activeOrder['dest_lat'] != null &&
          activeOrder['dest_lng'] != null) {
        final dLat = double.tryParse('${activeOrder['dest_lat']}');
        final dLng = double.tryParse('${activeOrder['dest_lng']}');
        if (dLat != null && dLng != null) {
          markers.add(
            Marker(
              markerId: MarkerId('order_${activeOrder['id']}'),
              position: LatLng(dLat, dLng),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRose,
              ),
              infoWindow: InfoWindow(
                title: 'ئامانجی داواکاری #${activeOrder['id']}',
              ),
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
          initialCameraPosition: CameraPosition(
            target: initialCenter,
            zoom: 12.8,
          ),
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
                  icon: const Icon(
                    Icons.refresh,
                    size: 18,
                    color: Color(0xFF2563EB),
                  ),
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
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Rabar',
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMapDriverCard(Map<String, dynamic> d) {
    final duty = (d['duty_status'] ?? 'offline').toString();
    final color = _dutyColor(duty, 'approved');
    final activeOrder = d['active_order'] is Map
        ? d['active_order'] as Map
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.getBorder(context)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12),
        ],
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
                    Text(
                      (d['name'] ?? '').toString(),
                      style: const TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_dutyLabel(duty, 'approved')} · ${_vehicleLabel(d['vehicle_type']?.toString())} · ${_lastSeenText(d['last_seen_seconds'])}',
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 11,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _callPhone(d['phone']?.toString()),
                icon: const Icon(Iconsax.call, color: Color(0xFF2563EB)),
              ),
              IconButton(
                onPressed: () => _openWhatsApp(d['phone']?.toString()),
                icon: const Icon(Iconsax.message, color: Color(0xFF10B981)),
              ),
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
                      child: const Icon(
                        Iconsax.user_add,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (d['name'] ?? '').toString(),
                            style: AdminUi.title,
                          ),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              '\u200E$phone',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _callPhone(phone),
                      icon: const Icon(Iconsax.call, color: Color(0xFF2563EB)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _tagChip(
                      _applicantRoleLabel(d['applicant_role']?.toString()),
                      Iconsax.health,
                    ),
                    _tagChip('${d['city'] ?? 'هەولێر'}', Iconsax.location),
                    _tagChip(
                      (d['applicant_role']?.toString() ?? 'phlebotomist') ==
                              'courier'
                          ? _vehicleLabel(d['vehicle_type']?.toString())
                          : (d['has_private_car'] == true
                                ? 'ئۆتۆمبێلی تایبەت'
                                : 'بێ ئۆتۆمبێل'),
                      Iconsax.car,
                    ),
                    _tagChip(
                      _scopeLabel(d['service_scope']?.toString()),
                      Iconsax.box,
                    ),
                    if (_educationLabel(d['education_level']?.toString()) !=
                        null)
                      _tagChip(
                        _educationLabel(d['education_level']?.toString())!,
                        Iconsax.teacher,
                      ),
                    if ((int.tryParse('${d['experience_years'] ?? 0}') ?? 0) >
                        0)
                      _tagChip(
                        '${d['experience_years']} ساڵ ئەزموون',
                        Iconsax.briefcase,
                      ),
                    if (_shiftLabel(d['availability_shift']?.toString()) !=
                        null)
                      _tagChip(
                        _shiftLabel(d['availability_shift']?.toString())!,
                        Iconsax.clock,
                      ),
                    if ((d['service_areas'] ?? '').toString().trim().isNotEmpty)
                      _tagChip('${d['service_areas']}', Iconsax.map_1),
                    if ((d['plate_number'] ?? '').toString().isNotEmpty)
                      _tagChip('${d['plate_number']}', Iconsax.card),
                  ],
                ),
                if (d['clinical_skills'] is List &&
                    (d['clinical_skills'] as List).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 5,
                    children: [
                      for (final sk in (d['clinical_skills'] as List))
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Text(
                            _skillLabel(sk.toString()),
                            style: const TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF065F46),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                if ([
                  d['id_document_url'],
                  d['certificate_url'],
                  d['license_url'],
                  d['cv_url'],
                ].any((u) => (u ?? '').toString().trim().isNotEmpty)) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _docLinkChip('ناسنامە', d['id_document_url']?.toString()),
                      _docLinkChip(
                        'بڕوانامە',
                        d['certificate_url']?.toString(),
                      ),
                      _docLinkChip('مۆڵەت', d['license_url']?.toString()),
                      _docLinkChip('CV', d['cv_url']?.toString()),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rejectDriver(d),
                        icon: const Icon(Iconsax.close_circle, size: 17),
                        label: const Text(
                          'ڕەتکردنەوە',
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _approveDriver(d),
                        icon: const Icon(Iconsax.tick_circle, size: 17),
                        label: const Text(
                          'پەسەندکردن',
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
          Text(
            label,
            style: const TextStyle(fontFamily: 'Rabar', fontSize: 11),
          ),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
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
                            color: sel
                                ? Colors.white
                                : AppColors.getTextSubtitle(context),
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
                      ElevatedButton(
                        onPressed: _loadAll,
                        child: const Text(
                          'دووبارە هەوڵبدەرەوە',
                          style: TextStyle(fontFamily: 'Rabar'),
                        ),
                      ),
                    ],
                  ),
                )
              : _drivers.isEmpty
              ? Center(
                  child: Text(
                    'هیچ کارمەندێک نەدۆزرایەوە',
                    style: AdminUi.title,
                  ),
                )
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

    return InkWell(
      onTap: () => _openDriverProfileSheet(d),
      borderRadius: BorderRadius.circular(18),
      child: Container(
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _dutyLabel(duty, status),
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        '\u200E$phone',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _tagChip(
                _applicantRoleLabel(d['applicant_role']?.toString()),
                Iconsax.health,
              ),
              _tagChip(
                '${d['city'] ?? 'هەولێر'} · ${_vehicleLabel(d['vehicle_type']?.toString())}',
                Iconsax.location,
              ),
              _tagChip(
                '${d['completed_deliveries'] ?? 0} ئەرک · ${_formatIqd(d['total_earnings'])}',
                Iconsax.box_tick,
              ),
              _tagChip(
                'کاشی وەرگیراو: ${_formatIqd(d['cash_total_collected'] ?? 0)}',
                Iconsax.money_recive,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton(
                onPressed: () => _callPhone(phone),
                icon: const Icon(
                  Iconsax.call,
                  size: 18,
                  color: Color(0xFF2563EB),
                ),
                tooltip: 'پەیوەندی',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
              ),
              IconButton(
                onPressed: () => _openWhatsApp(phone),
                icon: const Icon(
                  Iconsax.message,
                  size: 18,
                  color: Color(0xFF10B981),
                ),
                tooltip: 'واتسئاپ',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
              ),
              if (d['current_lat'] != null && d['current_lng'] != null)
                TextButton.icon(
                  onPressed: () {
                    _tabCtrl.animateTo(0);
                    setState(
                      () => _selectedMapDriver = Map<String, dynamic>.from(d),
                    );
                    _mapCtrl?.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(
                          double.parse('${d['current_lat']}'),
                          double.parse('${d['current_lng']}'),
                        ),
                        15,
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Iconsax.gps, size: 14),
                  label: Text(
                    _lastSeenText(d['last_seen_seconds']),
                    style: const TextStyle(fontFamily: 'Rabar', fontSize: 10.5),
                  ),
                ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _openDriverProfileSheet(d),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Iconsax.wallet_money, size: 15),
                label: const Text(
                  'داهات',
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              if (status == 'pending')
                ElevatedButton(
                  onPressed: () => _approveDriver(d),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text(
                    'پەسەندکردن',
                    style: TextStyle(fontFamily: 'Rabar', fontSize: 11.5),
                  ),
                )
              else
                OutlinedButton(
                  onPressed: () => _toggleBlock(d),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isBlocked
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    side: BorderSide(
                      color: isBlocked
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text(
                    isBlocked ? 'چالاککردن' : 'بلۆککردن',
                    style: const TextStyle(fontFamily: 'Rabar', fontSize: 11.5),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  Future<void> _openDriverProfileSheet(dynamic d) async {
    final driverId = d['id'];
    if (driverId == null) return;

    Map<String, dynamic>? profileData;
    String? loadErr;
    bool isLoading = true;
    bool isResetting = false;
    bool didLoad = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Future<void> fetchProfile() async {
              try {
                final res = await ApiClient.get('/admin/drivers/$driverId/profile');
                if (res.statusCode == 200) {
                  final decoded = jsonDecode(res.body);
                  setSheetState(() {
                    profileData = Map<String, dynamic>.from(decoded['data'] ?? {});
                    loadErr = null;
                    isLoading = false;
                  });
                } else {
                  setSheetState(() {
                    loadErr = AdminUi.readError(res);
                    isLoading = false;
                  });
                }
              } catch (e) {
                setSheetState(() {
                  loadErr = '$e';
                  isLoading = false;
                });
              }
            }

            if (!didLoad) {
              didLoad = true;
              fetchProfile();
            }

            Future<void> confirmAndReset(Map<String, dynamic> finance) async {
              final cashTotal =
                  double.tryParse('${finance['cash_total_collected'] ?? 0}') ?? 0;
              final earningsTotal =
                  double.tryParse('${finance['total_earnings'] ?? 0}') ?? 0;

              final ok = await showDialog<bool>(
                context: ctx,
                builder: (dCtx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  title: const Text(
                    'سفرکردنەوەی پارە و داهات',
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Text(
                    'دڵنیایت لە سفرکردنەوەی حیسابی ${d['name']}؟\n\n'
                    '• پارەی کاشی وەرگیراو: ${_formatIqd(cashTotal)}\n'
                    '• کرێی گەیاندن (داهات): ${_formatIqd(earningsTotal)}\n\n'
                    'دوای سفرکردنەوە، لای ئەدمین و لای شۆفێرەکەش دەبێتەوە بە 0 د.ع.',
                    style: const TextStyle(fontFamily: 'Rabar', fontSize: 13),
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
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'بەڵێ، سفر بکرێتەوە',
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
              if (ok != true) return;

              setSheetState(() => isResetting = true);
              try {
                final res = await ApiClient.post(
                  '/admin/drivers/$driverId/reset-earnings',
                );
                if (res.statusCode == 200) {
                  if (mounted) {
                    AdminUi.toast(
                      context,
                      'داهات و پارەی کاشی کارمەند سفرکرایەوە',
                    );
                  }
                  await fetchProfile();
                  await _loadAll();
                } else if (mounted) {
                  AdminUi.toast(context, AdminUi.readError(res), isError: true);
                }
              } catch (e) {
                if (mounted) AdminUi.toast(context, '$e', isError: true);
              } finally {
                if (ctx.mounted) setSheetState(() => isResetting = false);
              }
            }

            final driver = profileData?['driver'] is Map
                ? Map<String, dynamic>.from(profileData!['driver'])
                : Map<String, dynamic>.from(d);
            final finance = profileData?['finance'] is Map
                ? Map<String, dynamic>.from(profileData!['finance'])
                : <String, dynamic>{};
            final orders = profileData?['orders'] is List
                ? List<dynamic>.from(profileData!['orders'])
                : <dynamic>[];
            final phone = (driver['phone'] ?? '').toString();
            final resetAtRaw = finance['earnings_reset_at']?.toString();
            final resetAt = resetAtRaw != null
                ? DateTime.tryParse(resetAtRaw)?.toLocal()
                : null;

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (_, scrollCtrl) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.getSurface(context),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (driver['name'] ?? '').toString(),
                                    style: AdminUi.title.copyWith(fontSize: 16),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_applicantRoleLabel(driver['applicant_role']?.toString())} · ${driver['city'] ?? 'هەولێر'}',
                                    style: const TextStyle(
                                      fontFamily: 'Rabar',
                                      fontSize: 11.5,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _callPhone(phone),
                              icon: const Icon(
                                Iconsax.call,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _openWhatsApp(phone),
                              icon: const Icon(
                                Iconsax.message,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : loadErr != null
                            ? Center(
                                child: Text(
                                  loadErr!,
                                  style: const TextStyle(fontFamily: 'Rabar'),
                                ),
                              )
                            : ListView(
                                controller: scrollCtrl,
                                padding: const EdgeInsets.all(16),
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF059669),
                                          Color(0xFF10B981),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'کاشی وەرگیراو (ئەم خولە)',
                                                style: TextStyle(
                                                  fontFamily: 'Rabar',
                                                  fontSize: 11,
                                                  color: Colors.white
                                                      .withValues(alpha: 0.9),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _formatIqd(
                                                  finance['cash_total_collected'],
                                                ),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              Text(
                                                '${finance['cash_total_count'] ?? 0} داواکاری کاش · ئەمڕۆ: ${_formatIqd(finance['cash_today_collected'])}',
                                                style: TextStyle(
                                                  fontFamily: 'Rabar',
                                                  fontSize: 10.5,
                                                  color: Colors.white
                                                      .withValues(alpha: 0.85),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _profileStatBox(
                                          'داهاتی ئەم خولە (${finance['total_deliveries'] ?? 0} کار)',
                                          _formatIqd(finance['total_earnings']),
                                          const Color(0xFF2563EB),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _profileStatBox(
                                          'داهاتی ئەمڕۆ (${finance['today_deliveries'] ?? 0} کار)',
                                          _formatIqd(finance['today_earnings']),
                                          const Color(0xFFF59E0B),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.getBackground(context),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: AppColors.getBorder(context),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        _profileRow(
                                          'کارە کاشەکان',
                                          '${finance['cash_total_count'] ?? 0} · کرێ: ${_formatIqd(finance['cash_total_delivery_fee'])}',
                                        ),
                                        const SizedBox(height: 6),
                                        _profileRow(
                                          'کارە ئۆنلاینەکان',
                                          '${finance['online_total_count'] ?? 0} · کرێ: ${_formatIqd(finance['online_total_delivery_fee'])}',
                                        ),
                                        const SizedBox(height: 6),
                                        _profileRow(
                                          'کۆی گشتی مێژوویی',
                                          '${finance['lifetime_deliveries'] ?? 0} کار · ${_formatIqd(finance['lifetime_earnings'])}',
                                        ),
                                        const SizedBox(height: 6),
                                        _profileRow(
                                          'دواین سفرکردنەوە',
                                          resetAt != null
                                              ? intl.DateFormat(
                                                  'yyyy-MM-dd HH:mm',
                                                ).format(resetAt)
                                              : 'هێشتا سفر نەکراوەتەوە',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: isResetting
                                          ? null
                                          : () => confirmAndReset(finance),
                                      icon: isResetting
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(
                                              Iconsax.refresh,
                                              size: 18,
                                            ),
                                      label: const Text(
                                        'سفرکردنەوەی پارە و داهات',
                                        style: TextStyle(
                                          fontFamily: 'Rabar',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFEF4444),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 13,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'تۆماری گەیاندنە تەواوبووەکان',
                                    style: TextStyle(
                                      fontFamily: 'Rabar',
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (orders.isEmpty)
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 20),
                                      child: Center(
                                        child: Text(
                                          'هیچ گەیاندنێکی تەواوبوو نییە',
                                          style: TextStyle(
                                            fontFamily: 'Rabar',
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    ...orders.map((o) {
                                      final isCash = o['is_cash'] == true;
                                      final isSettled = o['is_settled'] == true;
                                      return Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color:
                                              AppColors.getBackground(context),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: AppColors.getBorder(context),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  '${o['order_number'] ?? '#${o['id']}'} · ${o['patient_name'] ?? ''}',
                                                  style: const TextStyle(
                                                    fontFamily: 'Rabar',
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const Spacer(),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 7,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: (isSettled
                                                            ? Colors.grey
                                                            : (isCash
                                                                ? const Color(
                                                                    0xFF10B981,
                                                                  )
                                                                : const Color(
                                                                    0xFF2563EB,
                                                                  )))
                                                        .withValues(alpha: 0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      6,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    isSettled
                                                        ? 'سفرکراوە'
                                                        : (isCash
                                                            ? 'کاش'
                                                            : 'ئۆنلاین'),
                                                    style: TextStyle(
                                                      fontFamily: 'Rabar',
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: isSettled
                                                          ? Colors.grey.shade700
                                                          : (isCash
                                                              ? const Color(
                                                                  0xFF059669,
                                                                )
                                                              : const Color(
                                                                  0xFF2563EB,
                                                                )),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  isCash
                                                      ? 'وەرگیراو: ${_formatIqd(o['total_price'])}'
                                                      : 'پسوڵە: ${_formatIqd(o['total_price'])}',
                                                  style: const TextStyle(
                                                    fontFamily: 'Rabar',
                                                    fontSize: 11.5,
                                                  ),
                                                ),
                                                Text(
                                                  'کرێ: ${_formatIqd(o['delivery_fee'])}',
                                                  style: const TextStyle(
                                                    fontFamily: 'Rabar',
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF2563EB),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                ],
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _profileStatBox(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: 10.5,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Rabar',
            fontSize: 11.5,
            color: Color(0xFF64748B),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontFamily: 'Rabar',
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
