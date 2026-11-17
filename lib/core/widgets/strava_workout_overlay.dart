import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Strava / Nike Run Club style athletic photo overlay.
/// Displays real Distance, Pace, Time, mini GPS route line, and JAIHIND watermark
/// overlaid directly on runner's photo with high-contrast drop shadows.
class StravaWorkoutOverlay extends StatelessWidget {
  final double distanceKm;
  final String pace;
  final int durationSeconds;
  final List<LatLng> routePoints;
  final String brandName;
  final bool isCompact;

  const StravaWorkoutOverlay({
    super.key,
    required this.distanceKm,
    required this.pace,
    required this.durationSeconds,
    this.routePoints = const [],
    this.brandName = 'JAIHIND',
    this.isCompact = false,
  });

  String get formattedDuration {
    if (durationSeconds <= 0) return '00:00';
    final h = durationSeconds ~/ 3600;
    final m = (durationSeconds % 3600) ~/ 60;
    final s = durationSeconds % 60;

    if (h > 0) {
      return '${h}h ${m}m';
    } else if (m > 0) {
      return '${m}m ${s.toString().padLeft(2, '0')}s';
    } else {
      return '00:${s.toString().padLeft(2, '0')}';
    }
  }

  String get formattedDistance {
    return '${distanceKm.toStringAsFixed(2)} km';
  }

  String get formattedPace {
    if (pace.isNotEmpty && pace != '-:--') {
      String clean = pace.replaceAll("'", ':').replaceAll('"', '');
      if (!clean.contains('/')) {
        clean = '$clean /km';
      }
      return clean;
    }
    if (distanceKm > 0 && durationSeconds > 0) {
      final totalSecPerKm = (durationSeconds / distanceKm).round();
      final pMin = totalSecPerKm ~/ 60;
      final pSec = totalSecPerKm % 60;
      return '$pMin:${pSec.toString().padLeft(2, '0')} /km';
    }
    return '6:23 /km';
  }

  bool get _hasValidRoute {
    if (routePoints.length < 2 || distanceKm < 0.03) return false;
    double minLat = routePoints.first.latitude;
    double maxLat = routePoints.first.latitude;
    double minLng = routePoints.first.longitude;
    double maxLng = routePoints.first.longitude;
    for (var p in routePoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return (maxLat - minLat) > 0.00008 || (maxLng - minLng) > 0.00008;
  }

  @override
  Widget build(BuildContext context) {
    final labelSize = isCompact ? 11.0 : 13.0;
    final valSize = isCompact ? 18.0 : 24.0;
    final gap = isCompact ? 10.0 : 14.0;

    final textShadow = [
      Shadow(
        color: Colors.black.withOpacity(0.85),
        blurRadius: 6,
        offset: const Offset(0, 1.5),
      ),
    ];

    return Positioned(
      top: isCompact ? 12 : 24,
      right: isCompact ? 12 : 18,
      bottom: isCompact ? 12 : 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. STATS METRICS (DISTANCE, PACE, TIME)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // DISTANCE
              Text(
                'Distance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: labelSize,
                  fontWeight: FontWeight.w600,
                  shadows: textShadow,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                formattedDistance,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: valSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  shadows: textShadow,
                ),
              ),
              SizedBox(height: gap),

              // PACE
              Text(
                'Pace',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: labelSize,
                  fontWeight: FontWeight.w600,
                  shadows: textShadow,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                formattedPace,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: valSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  shadows: textShadow,
                ),
              ),
              SizedBox(height: gap),

              // TIME
              Text(
                'Time',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: labelSize,
                  fontWeight: FontWeight.w600,
                  shadows: textShadow,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                formattedDuration,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: valSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  shadows: textShadow,
                ),
              ),
            ],
          ),

          // 2. MINI GPS RUNNING ROUTE VECTOR & WATERMARK
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_hasValidRoute) ...[
                CustomPaint(
                  size: Size(isCompact ? 80 : 110, isCompact ? 40 : 52),
                  painter: MiniRoutePainter(routePoints),
                ),
                const SizedBox(height: 10),
              ],

              // 3. JAIHIND BRAND WATERMARK (Replaces STRAVA)
              Text(
                brandName.toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isCompact ? 13 : 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.2,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.9),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom Painter that normalizes and draws the GPS route polyline on the photo.
class MiniRoutePainter extends CustomPainter {
  final List<LatLng> points;
  final Color routeColor;

  MiniRoutePainter(this.points, {this.routeColor = const Color(0xFFFF5722)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = routeColor
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.65)
      ..strokeWidth = 5.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (points.length >= 2) {
      double minLat = points.first.latitude;
      double maxLat = points.first.latitude;
      double minLng = points.first.longitude;
      double maxLng = points.first.longitude;

      for (var p in points) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }

      double latRange = maxLat - minLat;
      double lngRange = maxLng - minLng;
      if (latRange < 0.00008 && lngRange < 0.00008) return;
      if (latRange == 0) latRange = 0.0001;
      if (lngRange == 0) lngRange = 0.0001;

      final path = Path();
      for (int i = 0; i < points.length; i++) {
        final x = 8.0 + ((points[i].longitude - minLng) / lngRange) * (size.width - 16.0);
        final y = (size.height - 8.0) - ((points[i].latitude - minLat) / latRange) * (size.height - 16.0);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, shadowPaint);
      canvas.drawPath(path, paint);

      // Start Dot (Green)
      final startX = 8.0 + ((points.first.longitude - minLng) / lngRange) * (size.width - 16.0);
      final startY = (size.height - 8.0) - ((points.first.latitude - minLat) / latRange) * (size.height - 16.0);
      canvas.drawCircle(Offset(startX, startY), 3.5, Paint()..color = const Color(0xFF22C55E));

      // Finish Dot (Red)
      final endX = 8.0 + ((points.last.longitude - minLng) / lngRange) * (size.width - 16.0);
      final endY = (size.height - 8.0) - ((points.last.latitude - minLat) / latRange) * (size.height - 16.0);
      canvas.drawCircle(Offset(endX, endY), 3.5, Paint()..color = const Color(0xFFEF4444));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
