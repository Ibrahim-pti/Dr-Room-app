import 'package:flutter/material.dart';

/// One appointment time, exactly as the server generated it.
class Slot {
  final DateTime dateTime;
  final bool taken;

  const Slot({required this.dateTime, required this.taken});
}

/// One bookable day. The server decides which days and slots exist — the app
/// never derives its own grid, so the two can't drift apart.
class BookableDay {
  final DateTime date;
  final List<Slot> slots;

  const BookableDay({required this.date, required this.slots});

  static BookableDay? fromJson(Map<String, dynamic> json) {
    final date = DateTime.tryParse(json['date']?.toString() ?? '');
    if (date == null) return null;

    final slots = <Slot>[];
    for (final raw in (json['slots'] as List?) ?? const []) {
      final parts = raw['time'].toString().split(':');
      if (parts.length < 2) continue;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;

      slots.add(
        Slot(
          dateTime: DateTime(date.year, date.month, date.day, hour, minute),
          taken: raw['taken'] == true,
        ),
      );
    }
    return BookableDay(date: date, slots: slots);
  }
}

/// Sweeps the bottom edge of the hero photo into a soft arc that dips lower in
/// the middle than at the sides.
class HeroCurveClipper extends CustomClipper<Path> {
  const HeroCurveClipper();

  /// How far above the bottom the two side edges stop.
  static const double _sideInset = 58;

  /// Rounds off the three points of the V, so it reads as a soft chevron
  /// rather than a shape with knife edges.
  static const double _sideCorner = 22;
  static const double _tipCorner = 28;

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final edge = h - _sideInset;
    final mid = w / 2;

    // Pull back from the tip along each diagonal by _tipCorner, then round the
    // gap between the two points.
    final slope = Offset(mid, h - edge);
    final length = slope.distance;
    final backX = mid * (_tipCorner / length);
    final backY = (h - edge) * (_tipCorner / length);

    return Path()
      ..lineTo(0, edge - _sideCorner)
      ..quadraticBezierTo(0, edge, _sideCorner, edge + _sideCorner * 0.35)
      ..lineTo(mid - backX, h - backY)
      ..quadraticBezierTo(mid, h, mid + backX, h - backY)
      ..lineTo(w - _sideCorner, edge + _sideCorner * 0.35)
      ..quadraticBezierTo(w, edge, w, edge - _sideCorner)
      ..lineTo(w, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
