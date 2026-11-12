import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/api_client.dart';
import '../../core/utils/live_route_service.dart';
import '../../core/providers/order_provider.dart';
import 'widgets/order_progress_timeline.dart';

class OrderDetailsScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late OrderModel _currentOrder;
  Timer? _pollingTimer;
  GoogleMapController? _driverMapController;
  double _driverHeading = 0.0;
  LiveRouteResult? _trackingRoute;
  List<LatLng> _secondaryPreviewPoints = const [];
  String? _routeSignature;
  bool _hasFittedDriverMap = false;
  BitmapDescriptor? _courierIcon;
  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _patientIcon;

  TextStyle _kStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color color = const Color(0xFF0F172A),
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'Rabar',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _initTrackingIcons();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchFreshOrder();
        _refreshTrackingRoute();
      }
    });
    _startPolling();
  }

  Future<void> _initTrackingIcons() async {
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

  Future<void> _fetchFreshOrder() async {
    try {
      if (!mounted) return;
      await context.read<OrderProvider>().fetchOrders();
      if (mounted) {
        final updatedOrder = context.read<OrderProvider>().orders.firstWhere(
          (o) => o.id == _currentOrder.id,
          orElse: () => _currentOrder,
        );
        setState(() {
          _currentOrder = updatedOrder;
        });
        _refreshTrackingRoute();
      }
    } catch (_) {}
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) async {
      if (!mounted) return;
      await context.read<OrderProvider>().fetchOrders();

      if (mounted) {
        final updatedOrder = context.read<OrderProvider>().orders.firstWhere(
          (o) => o.id == _currentOrder.id,
          orElse: () => _currentOrder,
        );

        final latChanged = updatedOrder.driverLat != _currentOrder.driverLat ||
            updatedOrder.driverLng != _currentOrder.driverLng;

        if (updatedOrder.status != _currentOrder.status ||
            updatedOrder.assignedNurseId != _currentOrder.assignedNurseId ||
            updatedOrder.deliveryStatus != _currentOrder.deliveryStatus ||
            updatedOrder.assignedDriverId != _currentOrder.assignedDriverId ||
            latChanged) {
          double nextHeading = _driverHeading;
          if (latChanged &&
              _currentOrder.driverLat != null &&
              _currentOrder.driverLng != null &&
              updatedOrder.driverLat != null &&
              updatedOrder.driverLng != null) {
            final moved = Geolocator.distanceBetween(
              _currentOrder.driverLat!,
              _currentOrder.driverLng!,
              updatedOrder.driverLat!,
              updatedOrder.driverLng!,
            );
            if (moved >= 4.0) {
              nextHeading = LiveRouteService.calculateBearing(
                LatLng(_currentOrder.driverLat!, _currentOrder.driverLng!),
                LatLng(updatedOrder.driverLat!, updatedOrder.driverLng!),
              );
            }
          }

          setState(() {
            _currentOrder = updatedOrder;
            _driverHeading = nextHeading;
          });
          _refreshTrackingRoute();
          if (updatedOrder.driverLat != null &&
              updatedOrder.driverLng != null) {
            _fitTrackingMapCamera();
          }
        }
      }
    });
  }

  Future<void> _refreshTrackingRoute() async {
    final dLat = _currentOrder.driverLat;
    final dLng = _currentOrder.driverLng;
    final pLat = _currentOrder.patientLat;
    final pLng = _currentOrder.patientLng;
    final pkLat = _currentOrder.pickupLat;
    final pkLng = _currentOrder.pickupLng;

    if (dLat == null || dLng == null) return;
    final driverPos = LatLng(dLat, dLng);
    final patientPos = (pLat != null && pLng != null) ? LatLng(pLat, pLng) : null;
    final pickupPos = (pkLat != null && pkLng != null) ? LatLng(pkLat, pkLng) : null;

    final stage = (_currentOrder.deliveryStatus ?? 'assigned').toLowerCase();
    final targetPos = (!_currentOrder.isLab &&
            (stage == 'assigned' || stage == 'accepted') &&
            pickupPos != null)
        ? pickupPos
        : (patientPos ?? pickupPos);
    final secondaryPos = (targetPos == pickupPos && patientPos != null)
        ? patientPos
        : null;

    if (targetPos == null) return;

    final sig =
        '${_currentOrder.id}_${stage}_${driverPos.latitude.toStringAsFixed(3)}_${driverPos.longitude.toStringAsFixed(3)}_${targetPos.latitude.toStringAsFixed(4)}';
    if (sig == _routeSignature && _trackingRoute != null) {
      setState(() {
        _trackingRoute = LiveRouteResult(
          points: [driverPos, ..._trackingRoute!.points.skip(1)],
          distanceMeters: Geolocator.distanceBetween(
            driverPos.latitude,
            driverPos.longitude,
            targetPos.latitude,
            targetPos.longitude,
          ),
          durationSeconds: _trackingRoute!.durationSeconds,
          isRoadRoute: _trackingRoute!.isRoadRoute,
        );
      });
      return;
    }

    _routeSignature = sig;
    final route = await LiveRouteService.fetchRoute(driverPos, targetPos);
    List<LatLng> sec = const [];
    if (secondaryPos != null) {
      final secRes = await LiveRouteService.fetchRoute(targetPos, secondaryPos);
      sec = secRes.points;
    }
    if (!mounted) return;
    setState(() {
      _trackingRoute = route;
      _secondaryPreviewPoints = sec;
    });
    if (!_hasFittedDriverMap) {
      _hasFittedDriverMap = true;
      _fitTrackingMapCamera();
    }
  }

  Future<void> _fitTrackingMapCamera() async {
    final ctrl = _driverMapController;
    if (ctrl == null) return;

    final pts = <LatLng>[];
    if (_currentOrder.driverLat != null && _currentOrder.driverLng != null) {
      pts.add(LatLng(_currentOrder.driverLat!, _currentOrder.driverLng!));
    }
    if (_currentOrder.patientLat != null && _currentOrder.patientLng != null) {
      final pt = LatLng(_currentOrder.patientLat!, _currentOrder.patientLng!);
      if (pts.isEmpty ||
          Geolocator.distanceBetween(
                pts.first.latitude,
                pts.first.longitude,
                pt.latitude,
                pt.longitude,
              ) <
              150000) {
        pts.add(pt);
      }
    }
    if (_currentOrder.pickupLat != null && _currentOrder.pickupLng != null) {
      final pk = LatLng(_currentOrder.pickupLat!, _currentOrder.pickupLng!);
      if (pts.isEmpty ||
          Geolocator.distanceBetween(
                pts.first.latitude,
                pts.first.longitude,
                pk.latitude,
                pk.longitude,
              ) <
              150000) {
        pts.add(pk);
      }
    }

    if (pts.isEmpty) return;
    if (pts.length == 1) {
      await ctrl.animateCamera(CameraUpdate.newLatLngZoom(pts.first, 15.2));
      return;
    }
    await ctrl.animateCamera(
      CameraUpdate.newLatLngBounds(LiveRouteService.buildBounds(pts), 55),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _driverMapController?.dispose();
    super.dispose();
  }

  String _getStatusTitle(OrderStatus status, BuildContext context) {
    final lang = context.locale.languageCode.toLowerCase();
    switch (status) {
      case OrderStatus.pending:
        if (lang == 'kmr')
          return _currentOrder.statusLabelKmr ?? 'چاڤەڕێی پشتڕاستکرنێیە';
        if (lang == 'ar')
          return _currentOrder.statusLabelAr ?? 'قيد الانتظار والتأكيد';
        if (lang == 'en')
          return _currentOrder.statusLabelEn ?? 'Pending Confirmation';
        return _currentOrder.statusLabelCkb ?? 'چاوەڕوانی پشتڕاستکردنەوەیە';
      case OrderStatus.processing:
        if (lang == 'kmr')
          return _currentOrder.statusLabelKmr ?? 'د قۆناغا بجهئینانێ دایە';
        if (lang == 'ar')
          return _currentOrder.statusLabelAr ?? 'قيد التنفيذ والمتابعة';
        if (lang == 'en') return _currentOrder.statusLabelEn ?? 'In Progress';
        return _currentOrder.statusLabelCkb ?? 'لە قۆناغی جێبەجێکردندایە';
      case OrderStatus.completed:
        if (lang == 'kmr') return _currentOrder.statusLabelKmr ?? 'تەواوکرایە';
        if (lang == 'ar') return _currentOrder.statusLabelAr ?? 'مكتمل بنجاح';
        if (lang == 'en')
          return _currentOrder.statusLabelEn ?? 'Completed Successfully';
        return _currentOrder.statusLabelCkb ?? 'تەواوکراوە';
      case OrderStatus.cancelled:
        if (lang == 'kmr')
          return _currentOrder.statusLabelKmr ?? 'هاتیە هەلوەشاندن';
        if (lang == 'ar') return _currentOrder.statusLabelAr ?? 'ملغي';
        if (lang == 'en') return _currentOrder.statusLabelEn ?? 'Cancelled';
        return _currentOrder.statusLabelCkb ?? 'هەڵوەشێنراوەتەوە';
    }
  }

  Widget _buildDriverTrackingCard(
    bool isDark,
    Color cardBg,
    Color borderColor,
  ) {
    final lang = context.locale.languageCode.toLowerCase();
    final stage = (_currentOrder.deliveryStatus ?? 'assigned').toLowerCase();

    final vehicleText = switch (_currentOrder.driverVehicleType) {
      'car' => lang == 'en' ? 'Car' : (lang == 'ar' ? 'سيارة' : 'ئۆتۆمبێل'),
      'refrigerated_van' =>
        lang == 'en'
            ? 'Cooler Transport'
            : (lang == 'ar' ? 'سيارة مبردة' : 'ساردکەرەوەی تاقیگە'),
      _ =>
        lang == 'en'
            ? 'Motorcycle'
            : (lang == 'ar' ? 'دراجة نارية' : 'ماتۆڕسکیل'),
    };

    final dLat = _currentOrder.driverLat;
    final dLng = _currentOrder.driverLng;
    final pLat = _currentOrder.patientLat;
    final pLng = _currentOrder.patientLng;
    final pkLat = _currentOrder.pickupLat;
    final pkLng = _currentOrder.pickupLng;
    final showLiveMap =
        ((dLat != null && dLng != null) || (pLat != null && pLng != null)) &&
        stage != 'delivered';

    double? targetDistMeters = _trackingRoute?.distanceMeters;
    if (targetDistMeters == null &&
        dLat != null &&
        dLng != null &&
        pLat != null &&
        pLng != null) {
      targetDistMeters = Geolocator.distanceBetween(dLat, dLng, pLat, pLng);
    }

    final proximity = LiveRouteService.describeProximity(
      stage: stage,
      distanceMeters: targetDistMeters,
      etaMinutes: _trackingRoute?.etaMinutes,
      isLab: _currentOrder.isLab,
      lang: lang,
    );

    final markers = <Marker>{};
    if (dLat != null && dLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('live_driver'),
          position: LatLng(dLat, dLng),
          rotation: _driverHeading,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 3,
          icon: _courierIcon ??
              BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              ),
          infoWindow: InfoWindow(title: _currentOrder.driverName ?? 'Driver'),
        ),
      );
    }
    if (pkLat != null && pkLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup_stop'),
          position: LatLng(pkLat, pkLng),
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 2,
          icon: _pickupIcon ??
              BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange,
              ),
          infoWindow: InfoWindow(
            title: _currentOrder.pickupName ??
                (_currentOrder.isLab ? 'Lab' : 'Pharmacy'),
          ),
        ),
      );
    }
    if (pLat != null && pLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('patient_dest'),
          position: LatLng(pLat, pLng),
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 2,
          icon: _patientIcon ??
              BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
          infoWindow: InfoWindow(
            title: lang == 'en' ? 'Your Location' : 'شوێنی تۆ',
          ),
        ),
      );
    }

    final polylines = <Polyline>{};
    if (_trackingRoute != null && _trackingRoute!.points.length >= 2) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('driver_route'),
          points: _trackingRoute!.points,
          color: const Color(0xFF2563EB),
          width: 5,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );
    }
    if (_secondaryPreviewPoints.length >= 2) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('patient_leg_preview'),
          points: _secondaryPreviewPoints,
          color: const Color(0xFF10B981),
          width: 4,
          patterns: [PatternItem.dash(14), PatternItem.gap(8)],
          jointType: JointType.round,
        ),
      );
    }

    final stageOrder = ['accepted', 'picked_up', 'on_the_way', 'arrived', 'delivered'];
    final currentIdx = stageOrder.indexOf(stage).clamp(0, 4);
    final stageChips = switch (lang) {
      'en' => const ['Accepted', 'Picked up', 'On the way', 'Arrived'],
      'ar' => const ['مقبول', 'تم الاستلام', 'في الطريق', 'وصل'],
      'kmr' => const ['وەرگرت', 'ئامادە', 'د ڕێکێدا', 'گەهشت'],
      _ => const ['قبوڵکرا', 'وەرگیرا', 'لە ڕێگادا', 'گەیشت'],
    };

    final initialTarget = (dLat != null && dLng != null)
        ? LatLng(dLat, dLng)
        : (pLat != null && pLng != null)
            ? LatLng(pLat, pLng)
            : const LatLng(36.1911, 44.0092);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: proximity.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Iconsax.truck_fast,
                  color: proximity.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentOrder.driverName!,
                      style: _kStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$vehicleText${(_currentOrder.driverPlateNumber?.isNotEmpty ?? false) ? ' · ${_currentOrder.driverPlateNumber}' : ''}',
                      style: _kStyle(
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (_currentOrder.driverPhone?.isNotEmpty ?? false)
                IconButton.filled(
                  onPressed: () async {
                    final clean = _currentOrder.driverPhone!.replaceAll(
                      RegExp(r'[^0-9+]'),
                      '',
                    );
                    final uri = Uri.parse('tel:$clean');
                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                  },
                  icon: const Icon(Iconsax.call, size: 18, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: proximity.color.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: proximity.color.withValues(alpha: 0.28),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    proximity.headline,
                    style: _kStyle(
                      color: proximity.color,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (proximity.detail.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: proximity.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      proximity.detail,
                      style: _kStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(stageChips.length, (i) {
              final reached = currentIdx >= i;
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: reached
                            ? proximity.color
                            : (isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stageChips[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: _kStyle(
                        fontSize: 10,
                        fontWeight:
                            reached ? FontWeight.bold : FontWeight.normal,
                        color: reached
                            ? proximity.color
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          if (showLiveMap) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 230,
                width: double.infinity,
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: initialTarget,
                        zoom: 14.5,
                      ),
                      markers: markers,
                      polylines: polylines,
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                      mapToolbarEnabled: false,
                      compassEnabled: true,
                      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                        Factory<OneSequenceGestureRecognizer>(
                          () => EagerGestureRecognizer(),
                        ),
                      },
                      onMapCreated: (c) {
                        _driverMapController = c;
                        _fitTrackingMapCamera();
                      },
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Material(
                        color: cardBg.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: _fitTrackingMapCamera,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: borderColor),
                            ),
                            child: Icon(
                              Icons.zoom_out_map,
                              size: 18,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getStatusDescription(OrderStatus status, BuildContext context) {
    final lang = context.locale.languageCode.toLowerCase();
    switch (status) {
      case OrderStatus.pending:
        if (lang == 'kmr') return 'داخوازییا تە گەهشت و چاڤەڕێی پشتڕاستکرنێیە.';
        if (lang == 'ar') return 'تم استلام طلبك وهو بانتظار التأكيد.';
        if (lang == 'en')
          return 'Your order has been received and is awaiting confirmation.';
        return 'داواکارییەکەت گەیشت و لەلایەن تاقیگەوە چاوەڕوانی پشتڕاستکردنەوەیە.';
      case OrderStatus.processing:
        if (lang == 'kmr')
          return 'داخوازییا تە د قۆناغا ئەنجامدان و دووڤچوونێ دایە.';
        if (lang == 'ar')
          return 'طلبك قيد التنفيذ والمتابعة من قبل الفريق الطبي.';
        if (lang == 'en')
          return 'Your order is currently being processed and prepared.';
        return 'داواکارییەکەت لە قۆناغی ئەنجامدان و بەدواداچووندایە.';
      case OrderStatus.completed:
        if (lang == 'kmr')
          return 'هەمی پشکنین و خزمەتگوزاری ب سەرکەفتیانە هاتنە تمامکرن.';
        if (lang == 'ar') return 'تم إكمال جميع الفحوصات والخدمات بنجاح.';
        if (lang == 'en')
          return 'All services and examinations have been successfully completed.';
        return 'هەموو پشکنینەکان بە سەرکەوتوویی تەواو کران.';
      case OrderStatus.cancelled:
        if (lang == 'kmr') return 'ئەڤ داخوازییە هاتیە هەلوەشاندن.';
        if (lang == 'ar') return 'تم إلغاء هذا الطلب.';
        if (lang == 'en') return 'This order has been cancelled.';
        return 'ئەم داواکارییە هەڵوەشێنراوەتەوە.';
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return const Color(0xFFF59E0B);
      case OrderStatus.processing:
        return const Color(0xFF3B82F6);
      case OrderStatus.completed:
        return const Color(0xFF10B981);
      case OrderStatus.cancelled:
        return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final statusColor = _getStatusColor(_currentOrder.status);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          'order_details'.tr(),
          style: _kStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchFreshOrder,
        color: const Color(0xFF3B82F6),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Summary Card ──
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF3B82F6,
                            ).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _currentOrder.icon,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentOrder.localizedTitle(context),
                            style: _kStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF3B82F6,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${'order_id'.tr()}: #${_currentOrder.id}',
                              style: _kStyle(
                                color: const Color(0xFF2563EB),
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0),

              const SizedBox(height: 16),

              // ── Status Banner Card ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Iconsax.info_circle,
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStatusTitle(_currentOrder.status, context),
                            style: _kStyle(
                              color: statusColor,
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getStatusDescription(
                              _currentOrder.status,
                              context,
                            ),
                            style: _kStyle(
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF475569),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_currentOrder.status.isActive)
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: statusColor,
                        ),
                      ),
                  ],
                ),
              ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.05, end: 0),

              const SizedBox(height: 20),

              // ── Progress Timeline ──
              OrderProgressTimeline(
                status: _currentOrder.status,
              ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.05, end: 0),

              // ── Assigned Pharmacy Card (if Pharmacy) ──
              if (_currentOrder.assignedPharmacyName != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Iconsax.hospital,
                          color: Color(0xFF10B981),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentOrder.localizedPharmacyName(context) ??
                                  _currentOrder.assignedPharmacyName!,
                              style: _kStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'executing_pharmacy'.tr(),
                              style: _kStyle(
                                color:
                                    (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B)),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Live Delivery Driver Card & Map (if Driver assigned) ──
              if (_currentOrder.assignedDriverId != null &&
                  (_currentOrder.driverName?.isNotEmpty ?? false)) ...[
                const SizedBox(height: 20),
                _buildDriverTrackingCard(isDark, cardBg, borderColor),
              ],

              // ── Prescription Photo Card (if order is from prescription) ──
              if (_currentOrder.prescriptionImage != null &&
                  _currentOrder.prescriptionImage!.trim().isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF3B82F6,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Iconsax.document_upload,
                              color: Color(0xFF3B82F6),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'prescription_photo'.tr(),
                            style: _kStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: GestureDetector(
                          onTap: () {
                            final provider = ApiClient.getImageProvider(
                              _currentOrder.prescriptionImage,
                            );
                            if (provider == null) return;
                            showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                backgroundColor: Colors.transparent,
                                insetPadding: const EdgeInsets.all(16),
                                child: Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    InteractiveViewer(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image(
                                          image: provider,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const CircleAvatar(
                                        backgroundColor: Colors.black54,
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Image(
                                image: ApiClient.getImageProvider(
                                  _currentOrder.prescriptionImage,
                                )!,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  height: 100,
                                  alignment: Alignment.center,
                                  color: isDark
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFFF1F5F9),
                                  child: Text(
                                    'could_not_load_image'.tr(),
                                    style: _kStyle(
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.zoom_in,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Iconsax.eye,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: 180.ms).fadeIn().slideY(begin: 0.05, end: 0),
              ],

              const SizedBox(height: 20),

              // ── Order Information Card ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Iconsax.receipt,
                            color: Color(0xFF10B981),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'order_information'.tr(),
                          style: _kStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      context,
                      'order_date'.tr(),
                      '${_currentOrder.date.day}/${_currentOrder.date.month}/${_currentOrder.date.year}',
                      isDark: isDark,
                    ),
                    const Divider(
                      height: 24,
                      thickness: 1,
                      color: Color(0xFFF1F5F9),
                    ),
                    _buildDetailRow(
                      context,
                      'order_time'.tr(),
                      '${_currentOrder.date.hour}:${_currentOrder.date.minute.toString().padLeft(2, '0')}',
                      isDark: isDark,
                    ),
                    if (_currentOrder.paymentMethod != null) ...[
                      const Divider(
                        height: 24,
                        thickness: 1,
                        color: Color(0xFFF1F5F9),
                      ),
                      _buildDetailRow(
                        context,
                        'payment_method'.tr(),
                        _formatPaymentMethod(
                          _currentOrder.paymentMethod,
                          context,
                        ),
                        isDark: isDark,
                      ),
                    ],
                    if (_currentOrder.serviceFee != null) ...[
                      const Divider(
                        height: 24,
                        thickness: 1,
                        color: Color(0xFFF1F5F9),
                      ),
                      _buildDetailRow(
                        context,
                        'service_fee'.tr(),
                        _currentOrder.serviceFee == 0
                            ? 'service_fee_free'.tr()
                            : '${NumberFormat('#,###').format(_currentOrder.serviceFee)} ${'currency_iqd'.tr()}',
                        isDark: isDark,
                      ),
                    ],
                    const Divider(
                      height: 24,
                      thickness: 1,
                      color: Color(0xFFF1F5F9),
                    ),
                    _buildDetailRow(
                      context,
                      'total_price'.tr(),
                      '${NumberFormat('#,###').format(_currentOrder.price)} ${'currency_iqd'.tr()}',
                      isTotal: true,
                      isDark: isDark,
                    ),
                  ],
                ),
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.05, end: 0),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPaymentMethod(String? raw, BuildContext context) {
    if (raw == null || raw.isEmpty) return 'cash_on_delivery'.tr();
    final lower = raw.toLowerCase();
    if (lower.contains('delivery') ||
        lower.contains('cash') ||
        lower.contains('کاش')) {
      return 'cash_on_delivery'.tr();
    } else if (lower.contains('fastpay')) {
      return 'FastPay';
    } else if (lower.contains('fib')) {
      return 'FIB بانکی یەکەمی عێراق';
    } else if (lower.contains('zain')) {
      return 'Zain Cash';
    } else if (lower.contains('qi') ||
        lower.contains('card') ||
        lower.contains('stripe')) {
      return 'کی کارد / کارتی بانکی';
    }
    return raw;
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool isTotal = false,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: _kStyle(
            color: (Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF94A3B8)
                : const Color(0xFF64748B)),
            fontSize: isTotal ? 14.5 : 13.5,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: _kStyle(
            color: isTotal
                ? const Color(0xFF2563EB)
                : (isDark ? Colors.white : const Color(0xFF0F172A)),
            fontSize: isTotal ? 16 : 13.5,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
