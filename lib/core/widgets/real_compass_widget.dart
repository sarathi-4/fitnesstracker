import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Real Analog Navigational Magnetic Compass Widget for JAIHIND Maps
/// Rotates dynamically according to Google Maps camera bearing to always point to True North.
class RealCompassWidget extends StatelessWidget {
  final double bearing;
  final VoidCallback? onTap;
  final double size;

  const RealCompassWidget({
    super.key,
    required this.bearing,
    this.onTap,
    this.size = 50.0,
  });

  String get cardinalDirection {
    final normalized = (bearing % 360 + 360) % 360;
    if (normalized >= 337.5 || normalized < 22.5) return 'N';
    if (normalized >= 22.5 && normalized < 67.5) return 'NE';
    if (normalized >= 67.5 && normalized < 112.5) return 'E';
    if (normalized >= 112.5 && normalized < 157.5) return 'SE';
    if (normalized >= 157.5 && normalized < 202.5) return 'S';
    if (normalized >= 202.5 && normalized < 247.5) return 'SW';
    if (normalized >= 247.5 && normalized < 292.5) return 'W';
    return 'NW';
  }

  @override
  Widget build(BuildContext context) {
    // In Google Maps, bearing 0 = North, 90 = East, etc.
    // To keep North pointing upwards to True North relative to the camera,
    // we rotate the compass dial by -bearing.
    final double angleInRadians = -bearing * (math.pi / 180.0);

    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: 'Bearing: ${bearing.round()}° $cardinalDirection (Tap to reset North)',
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Rotating Real Compass Dial / Needle
              Transform.rotate(
                angle: angleInRadians,
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/real_compass.png',
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // 2. Cardinal direction badge overlay on bottom right
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white70, width: 0.5),
                  ),
                  child: Text(
                    cardinalDirection,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
