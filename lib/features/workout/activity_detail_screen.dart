import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_config.dart';
import '../../core/services/social_service.dart';
import '../../core/services/user_service.dart';
import '../../core/navigation/main_navigation_screen.dart';
import 'saved_activities_screen.dart';

class ActivityDetailScreen extends StatefulWidget {
  final WorkoutActivity activity;
  final bool isFromSave;

  const ActivityDetailScreen({
    super.key,
    required this.activity,
    this.isFromSave = false,
  });

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  GoogleMapController? _mapController;
  MapType _mapType = MapType.normal;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _setupRouteMap();
  }

  void _setupRouteMap() {
    final pts = widget.activity.gpsRoutePoints;
    if (pts.isNotEmpty) {
      // Glow Polyline
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('detail_route_glow'),
          points: pts,
          color: AppColors.primaryBlue.withValues(alpha: 0.35),
          width: 9,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );

      // Core Blue Polyline
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('detail_route_main'),
          points: pts,
          color: AppColors.primaryBlue,
          width: 5,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );

      // Start Marker (Green)
      _markers.add(
        Marker(
          markerId: const MarkerId('start_pin'),
          position: pts.first,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Start 🟢'),
        ),
      );

      // Finish Marker (Red)
      if (pts.length > 1) {
        _markers.add(
          Marker(
            markerId: const MarkerId('finish_pin'),
            position: pts.last,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: const InfoWindow(title: 'Finish 🏁'),
          ),
        );
      }
    }
  }

  void _fitRouteBounds() {
    final pts = widget.activity.gpsRoutePoints;
    if (_mapController == null || pts.length < 2) return;

    double minLat = pts.first.latitude;
    double maxLat = pts.first.latitude;
    double minLng = pts.first.longitude;
    double maxLng = pts.first.longitude;

    for (final p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 45.0),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayName = days[dt.weekday - 1];
    final monthName = months[dt.month - 1];
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');

    return '$dayName, $monthName ${dt.day}, ${dt.year} • $hour:$minute $ampm';
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Activity?'),
        content: const Text('Are you sure you want to remove this saved activity from your history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              UserService.instance.deleteActivity(widget.activity.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Activity deleted'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              if (widget.isFromSave) {
                Navigator.of(context).pushAndRemoveUntil(
                  AppRouteTransitions.scaleFade(const MainNavigationScreen(initialIndex: 0)),
                  (route) => false,
                );
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _onBackPressed() {
    if (widget.isFromSave) {
      Navigator.of(context).pushAndRemoveUntil(
        AppRouteTransitions.scaleFade(const MainNavigationScreen(initialIndex: 0)),
        (route) => false,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final act = widget.activity;
    final pts = act.gpsRoutePoints;

    final calculatedSpeed = act.avgSpeedKmH > 0.0
        ? act.avgSpeedKmH.toStringAsFixed(1)
        : (act.distanceKm > 0 && act.durationSeconds > 0
            ? (act.distanceKm / (act.durationSeconds / 3600)).toStringAsFixed(1)
            : '0.0');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: BouncingTap(
          onTap: _onBackPressed,
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 22, color: AppColors.textBlack),
        ),
        title: Text(
          act.title,
          style: const TextStyle(
            fontSize: 17.5,
            fontWeight: FontWeight.w900,
            color: AppColors.textBlack,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Post to Profile Feed',
            icon: const Icon(Icons.send_rounded, color: AppColors.primaryBlue, size: 22),
            onPressed: () {
              final post = ProfilePost(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                activityId: act.id,
                title: act.title,
                mode: act.mode,
                distanceKm: act.distanceKm,
                durationSeconds: act.durationSeconds,
                calories: act.calories,
                avgPace: act.avgPace,
                avgSpeedKmH: act.avgSpeedKmH,
                heartRateBpm: act.heartRateBpm,
                dateTime: act.dateTime,
                locationName: act.locationName,
                gpsRoutePoints: act.gpsRoutePoints,
                caption: act.notes ?? 'Running session completed with JAIHIND! 🏃‍♂️⚡',
                imagePath: act.imagePath,
                likes: 0,
                isLiked: false,
                comments: [],
              );
              UserService.instance.addProfilePost(post);

              // Also publish to Community Social Feed on Firestore
              SocialService.instance.createPost(
                imageFile: act.imagePath != null ? File(act.imagePath!) : null,
                caption: act.notes ?? 'Running session completed with JAIHIND! 🏃‍♂️⚡',
                activityType: act.mode,
                distanceKm: act.distanceKm,
                durationSeconds: act.durationSeconds,
                calories: act.calories,
                pace: act.avgPace,
                locationName: act.locationName,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Activity successfully posted to your Profile Feed! 🚀'),
                  backgroundColor: AppColors.primaryBlue,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 23),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. COMPLETED ROUTE GOOGLE MAP CARD
            FadeSlideEntry(
              delay: Duration.zero,
              child: Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.25), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(19),
                  child: Stack(
                    children: [
                      // Google Map
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: pts.isNotEmpty
                              ? pts.first
                              : const LatLng(AppConfig.defaultLatitude, AppConfig.defaultLongitude),
                          zoom: 16.5,
                        ),
                        mapType: _mapType,
                        polylines: _polylines,
                        markers: _markers,
                        zoomControlsEnabled: false,
                        myLocationEnabled: false,
                        myLocationButtonEnabled: false,
                        compassEnabled: false,
                        mapToolbarEnabled: false,
                        buildingsEnabled: true,
                        rotateGesturesEnabled: true,
                        scrollGesturesEnabled: true,
                        zoomGesturesEnabled: true,
                        tiltGesturesEnabled: true,
                        onMapCreated: (controller) {
                          _mapController = controller;
                          Future.delayed(const Duration(milliseconds: 350), _fitRouteBounds);
                        },
                      ),

                      // Top Left: Distance & Location Pill
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on_rounded, color: AppColors.accentGreen, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${act.locationName} • ${act.distanceKm.toStringAsFixed(2)} km',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Top Right: Map Type Switcher
                      Positioned(
                        top: 12,
                        right: 12,
                        child: BouncingTap(
                          onTap: () {
                            setState(() {
                              _mapType = _mapType == MapType.normal
                                  ? MapType.hybrid
                                  : MapType.normal;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 4),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _mapType == MapType.hybrid
                                      ? Icons.layers_rounded
                                      : Icons.satellite_alt_rounded,
                                  color: AppColors.primaryBlue,
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _mapType == MapType.hybrid ? 'Satellite' : 'Roadmap',
                                  style: const TextStyle(
                                    color: AppColors.textBlack,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Bottom Left: Re-center Route Button
                      if (pts.length > 1)
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: BouncingTap(
                            onTap: _fitRouteBounds,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(color: Colors.black26, blurRadius: 4),
                                ],
                              ),
                              child: const Icon(
                                Icons.fit_screen_rounded,
                                color: AppColors.primaryBlue,
                                size: 16,
                              ),
                            ),
                          ),
                        ),

                      // Bottom Right: Sport Mode Badge
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: AppColors.brandGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryBlue.withValues(alpha: 0.35),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_getModeIcon(act.mode), color: Colors.white, size: 13),
                              const SizedBox(width: 4),
                              Text(
                                act.mode,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 2. DATE, TIME & LOCATION BANNER
            FadeSlideEntry(
              delay: const Duration(milliseconds: 40),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0F2FE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: AppColors.primaryBlue,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _formatDateTime(act.dateTime),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 3. KEY METRICS STATS CARD (TIME, DISTANCE, SPEED, CALORIES, HEARTBEAT, PACE)
            FadeSlideEntry(
              delay: const Duration(milliseconds: 80),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF0F4F8)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // ROW 1: PRIMARY WORKOUT STATS (TIME, DISTANCE, SPEED)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricCol(
                          icon: Icons.timer_outlined,
                          iconColor: AppColors.primaryBlue,
                          value: _formatDuration(act.durationSeconds),
                          label: 'DURATION',
                        ),
                        Container(width: 1, height: 38, color: const Color(0xFFEEEEEE)),
                        _buildMetricCol(
                          icon: Icons.straighten_rounded,
                          iconColor: const Color(0xFF00B0FF),
                          value: '${act.distanceKm.toStringAsFixed(2)} km',
                          label: 'DISTANCE',
                        ),
                        Container(width: 1, height: 38, color: const Color(0xFFEEEEEE)),
                        _buildMetricCol(
                          icon: Icons.speed_rounded,
                          iconColor: const Color(0xFF7C4DFF),
                          value: '$calculatedSpeed km/h',
                          label: 'AVG SPEED',
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFF0F0F0)),
                    const SizedBox(height: 14),

                    // ROW 2: PHYSIOLOGICAL & ENERGY (CALORIES, HEARTBEAT, PACE)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricCol(
                          icon: Icons.local_fire_department_rounded,
                          iconColor: const Color(0xFFFF6D00),
                          value: '${act.calories} kcal',
                          label: 'CALORIES',
                        ),
                        Container(width: 1, height: 38, color: const Color(0xFFEEEEEE)),
                        _buildMetricCol(
                          icon: Icons.favorite_rounded,
                          iconColor: const Color(0xFFE53935),
                          value: '${act.heartRateBpm} bpm',
                          label: 'HEARTBEAT',
                          isHeartbeat: true,
                        ),
                        Container(width: 1, height: 38, color: const Color(0xFFEEEEEE)),
                        _buildMetricCol(
                          icon: Icons.directions_run_rounded,
                          iconColor: AppColors.accentGreen,
                          value: act.avgPace,
                          label: 'AVG PACE',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 4. FEELING & NOTES (IF PRESENT)
            if (act.feeling != null || (act.notes != null && act.notes!.isNotEmpty))
              FadeSlideEntry(
                delay: const Duration(milliseconds: 120),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFF0F4F8)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (act.feeling != null) ...[
                        Row(
                          children: [
                            const Text(
                              'Feeling:',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accentGreen.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                act.feeling!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accentGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (act.notes != null && act.notes!.isNotEmpty) const SizedBox(height: 10),
                      ],
                      if (act.notes != null && act.notes!.isNotEmpty) ...[
                        const Text(
                          'Notes:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          act.notes!,
                          style: const TextStyle(fontSize: 13.5, color: AppColors.textDark, height: 1.4),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // 5. ACTION BUTTONS: VIEW ALL HISTORY & DONE
            FadeSlideEntry(
              delay: const Duration(milliseconds: 160),
              child: Column(
                children: [
                  BouncingTap(
                    onTap: () {
                      Navigator.push(
                        context,
                        AppRouteTransitions.slideRight(const SavedActivitiesScreen()),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: AppColors.primaryBlue, width: 1.8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_rounded, color: AppColors.primaryBlue, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'View All Saved Activities',
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  BouncingTap(
                    onTap: _onBackPressed,
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(27),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 21),
                            SizedBox(width: 8),
                            Text(
                              'Done',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCol({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    bool isHeartbeat = false,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 14, color: iconColor),
            ),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
                color: isHeartbeat ? const Color(0xFFD32F2F) : AppColors.textBlack,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF888888),
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  IconData _getModeIcon(String mode) {
    switch (mode.toLowerCase()) {
      case 'cycling':
        return Icons.directions_bike_rounded;
      case 'walking':
        return Icons.directions_walk_rounded;
      case 'hike':
      case 'hiking':
      case 'gym':
        return Icons.hiking_rounded;
      case 'running':
      default:
        return Icons.directions_run_rounded;
    }
  }
}
