import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class LiveRouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final int durationSeconds;
  final bool isRoadRoute;

  const LiveRouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.isRoadRoute,
  });

  int get etaMinutes => math.max(1, (durationSeconds / 60).ceil());

  String formattedDistance(String lang) {
    if (distanceMeters < 1000) {
      final m = (distanceMeters / 10).round() * 10;
      return switch (lang) {
        'en' => '${m}m',
        'ar' => '$m م',
        _ => '$m م',
      };
    }
    final km = (distanceMeters / 1000).toStringAsFixed(1);
    return switch (lang) {
      'en' => '$km km',
      'ar' => '$km كم',
      _ => '$km کم',
    };
  }

  String formattedEta(String lang) {
    final mins = etaMinutes;
    return switch (lang) {
      'en' => '~$mins min',
      'ar' => '~$mins دقيقة',
      'kmr' => '~$mins خولەک',
      _ => '~$mins خولەک',
    };
  }
}

class LiveProximityInfo {
  final String headline;
  final String detail;
  final Color color;
  final bool isUrgentClose;

  const LiveProximityInfo({
    required this.headline,
    required this.detail,
    required this.color,
    this.isUrgentClose = false,
  });
}

class LiveRouteService {
  LiveRouteService._();

  static final Map<String, LiveRouteResult> _routeCache = {};
  static final Map<String, BitmapDescriptor> _iconCache = {};

  static String _cacheKey(LatLng a, LatLng b) {
    return '${a.latitude.toStringAsFixed(3)},${a.longitude.toStringAsFixed(3)}'
        '->${b.latitude.toStringAsFixed(3)},${b.longitude.toStringAsFixed(3)}';
  }

  /// Fetch real driving road geometry via OSRM, with fast fallback to a
  /// geodesic line + estimated travel time when offline or >150km apart.
  static Future<LiveRouteResult> fetchRoute(
    LatLng origin,
    LatLng destination,
  ) async {
    final directMeters = Geolocator.distanceBetween(
      origin.latitude,
      origin.longitude,
      destination.latitude,
      destination.longitude,
    );

    final fallback = LiveRouteResult(
      points: [origin, destination],
      distanceMeters: directMeters,
      durationSeconds: math.max(60, (directMeters / 7.5).ceil()), // ~27 km/h urban avg
      isRoadRoute: false,
    );

    if (directMeters < 35 || directMeters > 150000) {
      return fallback;
    }

    final key = _cacheKey(origin, destination);
    final cached = _routeCache[key];
    if (cached != null) {
      return LiveRouteResult(
        points: [origin, ...cached.points.skip(1)],
        distanceMeters: directMeters < cached.distanceMeters ? cached.distanceMeters : directMeters,
        durationSeconds: cached.durationSeconds,
        isRoadRoute: cached.isRoadRoute,
      );
    }

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final routes = decoded['routes'];
        if (routes is List && routes.isNotEmpty) {
          final first = routes.first as Map;
          final coords = first['geometry']?['coordinates'];
          if (coords is List && coords.length >= 2) {
            final pts = <LatLng>[origin];
            for (final c in coords) {
              if (c is List && c.length >= 2) {
                pts.add(
                  LatLng(
                    (c[1] as num).toDouble(),
                    (c[0] as num).toDouble(),
                  ),
                );
              }
            }
            pts.add(destination);

            final dist = (first['distance'] as num?)?.toDouble() ?? directMeters;
            final dur = ((first['duration'] as num?)?.toDouble() ?? (dist / 7.5)).ceil();

            final result = LiveRouteResult(
              points: pts,
              distanceMeters: dist,
              durationSeconds: math.max(60, dur),
              isRoadRoute: true,
            );

            if (_routeCache.length > 40) {
              _routeCache.remove(_routeCache.keys.first);
            }
            _routeCache[key] = result;
            return result;
          }
        }
      }
    } catch (_) {
      // Fallback silently to direct polyline
    }

    return fallback;
  }

  /// Calculate clockwise heading (0..360 deg from North) between two points.
  static double calculateBearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * math.pi / 180.0;
    final lon1 = from.longitude * math.pi / 180.0;
    final lat2 = to.latitude * math.pi / 180.0;
    final lon2 = to.longitude * math.pi / 180.0;

    final dLon = lon2 - lon1;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final brng = math.atan2(y, x) * 180.0 / math.pi;
    return (brng + 360.0) % 360.0;
  }

  /// Build safe LatLngBounds enclosing all points with a slight margin so
  /// identical or close coordinates never throw in CameraUpdate.newLatLngBounds.
  static LatLngBounds buildBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    const minSpan = 0.004;
    if ((maxLat - minLat) < minSpan) {
      minLat -= minSpan / 2;
      maxLat += minSpan / 2;
    }
    if ((maxLng - minLng) < minSpan) {
      minLng -= minSpan / 2;
      maxLng += minSpan / 2;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  /// Talabat-style dynamic proximity messaging based on stage + live distance.
  static LiveProximityInfo describeProximity({
    required String stage,
    required double? distanceMeters,
    required int? etaMinutes,
    required bool isLab,
    required String lang,
  }) {
    final normalized = stage.toLowerCase();
    final l = lang.toLowerCase();
    final distStr = distanceMeters != null
        ? (distanceMeters < 1000
              ? '${(distanceMeters / 10).round() * 10} ${l == 'en' ? 'm' : 'م'}'
              : '${(distanceMeters / 1000).toStringAsFixed(1)} ${l == 'en' ? 'km' : (l == 'ar' ? 'كم' : 'کم')}')
        : '';
    final etaStr = etaMinutes != null
        ? (l == 'en'
              ? '~$etaMinutes min'
              : (l == 'ar' ? '~$etaMinutes د' : '~$etaMinutes خولەک'))
        : '';
    final telemetry = [distStr, etaStr].where((e) => e.isNotEmpty).join(' · ');

    if (normalized == 'arrived') {
      return LiveProximityInfo(
        headline: switch (l) {
          'ar' => 'وصل المندوب إلى موقعك 📍',
          'en' => 'Driver has arrived 📍',
          'kmr' => 'شۆفێر گەهشتە بەر دەرگەهی 📍',
          _ => 'کارمەندی گەیاندن گەیشتە شوێنەکە 📍',
        },
        detail: telemetry.isNotEmpty
            ? telemetry
            : switch (l) {
                'ar' => 'جاهز للتسليم الآن',
                'en' => 'Ready at your location',
                'kmr' => 'د جهێ خۆ دا ئامادەیە',
                _ => 'لە بەردەم شوێنەکەتدایە',
              },
        color: const Color(0xFF0D9488),
        isUrgentClose: true,
      );
    }

    if (normalized == 'delivered') {
      return LiveProximityInfo(
        headline: switch (l) {
          'ar' => 'تم التسليم بنجاح ✅',
          'en' => 'Delivered successfully ✅',
          'kmr' => 'گەهاندن تمام بوو ✅',
          _ => 'بە سەرکەوتوویی ڕادەستکرا ✅',
        },
        detail: '',
        color: const Color(0xFF10B981),
      );
    }

    if (distanceMeters != null &&
        (normalized == 'on_the_way' || normalized == 'picked_up' || normalized == 'accepted')) {
      if (distanceMeters <= 150) {
        return LiveProximityInfo(
          headline: switch (l) {
            'ar' => 'وصل عند الموقع تقريباً! 📍',
            'en' => 'Right outside your location 📍',
            'kmr' => 'گەلەک نێزیکە ل بەر دەرگەهی 📍',
            _ => 'گەیشتووەتە نزیکترین خاڵ 📍',
          },
          detail: telemetry,
          color: const Color(0xFF0D9488),
          isUrgentClose: true,
        );
      }
      if (distanceMeters <= 550) {
        return LiveProximityInfo(
          headline: switch (l) {
            'ar' => 'قريب جداً منك! استعد للاستلام ⚡',
            'en' => 'Almost there! Very close ⚡',
            'kmr' => 'گەلەک نێزیکی تە بوو! ⚡',
            _ => 'زۆر نزیکە لە شوێنەکەت! ⚡',
          },
          detail: telemetry,
          color: const Color(0xFFEA580C),
          isUrgentClose: true,
        );
      }
      if (distanceMeters <= 2500 && normalized == 'on_the_way') {
        return LiveProximityInfo(
          headline: switch (l) {
            'ar' => 'في طريقه إليك، سيصل قريباً 🛵',
            'en' => 'Arriving soon 🛵',
            'kmr' => 'د ڕێکێ دایە و ب زوویی دێ گەهیت 🛵',
            _ => 'لە ڕێگادایە و بەم زووانە دەگات 🛵',
          },
          detail: telemetry,
          color: const Color(0xFF2563EB),
        );
      }
    }

    final defaultHeadline = switch (normalized) {
      'accepted' => switch (l) {
        'ar' => isLab ? 'في الطريق لأخذ العينة' : 'متجه إلى الصيدلية للاستلام',
        'en' => isLab ? 'Accepted · Heading to patient' : 'Heading to pharmacy for pickup',
        'kmr' => isLab ? 'داخوازی وەرگرت · د ڕێکێ دایە' : 'دچیتە دەرمانخانێ بۆ وەرگرتنێ',
        _ => isLab ? 'داواکاری قبوڵکرا · بەرەو لات دێت' : 'بەرەو دەرمانخانە دەڕوات بۆ وەرگرتن',
      },
      'picked_up' => switch (l) {
        'ar' => isLab ? 'تم أخذ العينة المختبرية 🧪' : 'تم استلام الطلب من الصيدلية 💊',
        'en' => isLab ? 'Sample collected 🧪' : 'Picked up from pharmacy 💊',
        'kmr' => isLab ? 'نموونە هاتە وەرگرتن 🧪' : 'ژ دەرمانخانێ هاتە وەرگرتن 💊',
        _ => isLab ? 'نموونەی خوێن وەرگیرا 🧪' : 'لە دەرمانخانە وەرگیرا 💊',
      },
      'on_the_way' => switch (l) {
        'ar' => 'المندوب في الطريق الآن 🛵',
        'en' => 'Driver is on the way 🛵',
        'kmr' => 'شۆفێر د ڕێکێ دایە 🛵',
        _ => 'کارمەندی گەیاندن لە ڕێگادایە 🛵',
      },
      _ => switch (l) {
        'ar' => 'بانتظار تأكيد المندوب...',
        'en' => 'Awaiting driver acceptance...',
        'kmr' => 'چاڤەڕێی قبوڵکرنا شۆفێری...',
        _ => 'نێردراوە بۆ نزیکترین کارمەند...',
      },
    };

    return LiveProximityInfo(
      headline: defaultHeadline,
      detail: telemetry,
      color: const Color(0xFF2563EB),
    );
  }

  /// Crisp Talabat-style directional navigation puck for the live driver marker.
  static Future<BitmapDescriptor> getCourierMarker({
    Color primary = const Color(0xFF2563EB),
  }) async {
    final key = 'courier_${primary.toARGB32()}';
    if (_iconCache.containsKey(key)) return _iconCache[key]!;

    const double size = 128.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const center = Offset(size / 2, size / 2);

    // Outer halo ring
    canvas.drawCircle(
      center,
      54,
      Paint()..color = primary.withValues(alpha: 0.18),
    );
    // White crisp border
    canvas.drawCircle(
      center,
      38,
      Paint()..color = Colors.white,
    );
    // Inner colored disc
    canvas.drawCircle(
      center,
      32,
      Paint()..color = primary,
    );

    // Upward directional arrow inside circle (rotates smoothly with marker bearing)
    final path = Path()
      ..moveTo(center.dx, center.dy - 17)
      ..lineTo(center.dx + 14, center.dy + 13)
      ..lineTo(center.dx, center.dy + 6)
      ..lineTo(center.dx - 14, center.dy + 13)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);

    final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final descriptor = BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      imagePixelRatio: 2.8,
    );
    _iconCache[key] = descriptor;
    return descriptor;
  }

  /// Crisp custom pin marker for Pickup (Pharmacy/Lab) or Destination (Patient).
  static Future<BitmapDescriptor> getTargetMarker({
    required Color color,
    bool isPickup = false,
  }) async {
    final key = 'target_${color.toARGB32()}_$isPickup';
    if (_iconCache.containsKey(key)) return _iconCache[key]!;

    const double size = 112.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const center = Offset(size / 2, size / 2 - 6);

    // Soft drop ring
    canvas.drawCircle(
      Offset(center.dx, center.dy + 26),
      12,
      Paint()..color = color.withValues(alpha: 0.25),
    );
    // White outer pill
    canvas.drawCircle(center, 34, Paint()..color = Colors.white);
    // Inner colored circle
    canvas.drawCircle(center, 28, Paint()..color = color);
    // White center dot or square icon
    if (isPickup) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 18, height: 18),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, Paint()..color = Colors.white);
    } else {
      canvas.drawCircle(center, 9, Paint()..color = Colors.white);
    }

    final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final descriptor = BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      imagePixelRatio: 2.8,
    );
    _iconCache[key] = descriptor;
    return descriptor;
  }
}

