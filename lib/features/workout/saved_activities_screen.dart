import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/user_service.dart';
import 'activity_detail_screen.dart';

class SavedActivitiesScreen extends StatefulWidget {
  const SavedActivitiesScreen({super.key});

  @override
  State<SavedActivitiesScreen> createState() => _SavedActivitiesScreenState();
}

class _SavedActivitiesScreenState extends State<SavedActivitiesScreen> {
  @override
  Widget build(BuildContext context) {
    final user = UserService.instance;
    final activities = user.savedActivities;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: BouncingTap(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 22, color: AppColors.textBlack),
        ),
        title: const Text(
          'Saved Activities',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.textBlack,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '${activities.length} Total',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: activities.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions_run_rounded, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 14),
                  const Text(
                    'No Saved Activities Yet',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Complete a workout and tap Finish to see your route history here!',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              itemCount: activities.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  // TOTAL SUMMARY STATS CARD
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem('Total Workouts', '${activities.length}', Icons.fitness_center_rounded),
                        Container(width: 1, height: 32, color: Colors.white30),
                        _buildSummaryItem('Total Distance', '${user.totalDistanceKm.toStringAsFixed(2)} km', Icons.straighten_rounded),
                        Container(width: 1, height: 32, color: Colors.white30),
                        _buildSummaryItem('Total Calories', '${user.totalCalories} kcal', Icons.local_fire_department_rounded),
                      ],
                    ),
                  );
                }

                final act = activities[index - 1];
                return _buildActivityCard(context, act);
              },
            ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(BuildContext context, WorkoutActivity act) {
    final d = act.dateTime;
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${months[d.month - 1]} ${d.day}, ${d.year}';
    final hour = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hour:${d.minute.toString().padLeft(2, '0')} $ampm';

    final m = act.durationSeconds ~/ 60;
    final s = act.durationSeconds % 60;
    final durStr = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    final calculatedSpeed = act.avgSpeedKmH > 0.0
        ? act.avgSpeedKmH.toStringAsFixed(1)
        : (act.distanceKm > 0 && act.durationSeconds > 0
            ? (act.distanceKm / (act.durationSeconds / 3600)).toStringAsFixed(1)
            : '0.0');

    final pts = act.gpsRoutePoints;

    return BouncingTap(
      onTap: () {
        Navigator.push(
          context,
          AppRouteTransitions.slideRight(ActivityDetailScreen(activity: act)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP HEADER (MODE, TITLE, FEELING, DATE)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          _getModeIcon(act.mode),
                          color: AppColors.primaryBlue,
                          size: 22,
                        ),
                      ),
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
                                  act.title,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textBlack,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (act.feeling != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentGreen.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    act.feeling!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accentGreen,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$dateStr • $timeStr • ${act.locationName}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. ROUTE MAP PREVIEW (IF GPS ROUTE RECORDED)
              if (pts.isNotEmpty)
                Container(
                  height: 140,
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: pts.first,
                            zoom: 16.0,
                          ),
                          mapType: MapType.normal,
                          polylines: {
                            Polyline(
                              polylineId: PolylineId('preview_${act.id}_glow'),
                              points: pts,
                              color: AppColors.primaryBlue.withValues(alpha: 0.35),
                              width: 7,
                              jointType: JointType.round,
                              startCap: Cap.roundCap,
                              endCap: Cap.roundCap,
                            ),
                            Polyline(
                              polylineId: PolylineId('preview_${act.id}_main'),
                              points: pts,
                              color: AppColors.primaryBlue,
                              width: 4,
                              jointType: JointType.round,
                              startCap: Cap.roundCap,
                              endCap: Cap.roundCap,
                            ),
                          },
                          markers: {
                            Marker(
                              markerId: const MarkerId('start'),
                              position: pts.first,
                              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                            ),
                            if (pts.length > 1)
                              Marker(
                                markerId: const MarkerId('finish'),
                                position: pts.last,
                                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                              ),
                          },
                          zoomControlsEnabled: false,
                          myLocationEnabled: false,
                          myLocationButtonEnabled: false,
                          compassEnabled: false,
                          mapToolbarEnabled: false,
                          rotateGesturesEnabled: false,
                          scrollGesturesEnabled: false,
                          zoomGesturesEnabled: false,
                          tiltGesturesEnabled: false,
                          onMapCreated: (ctrl) {
                            if (pts.length >= 2) {
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
                              ctrl.animateCamera(
                                CameraUpdate.newLatLngBounds(
                                  LatLngBounds(
                                    southwest: LatLng(minLat, minLng),
                                    northeast: LatLng(maxLat, maxLng),
                                  ),
                                  28.0,
                                ),
                              );
                            }
                          },
                        ),

                        // Route overlay chip
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.touch_app_rounded, color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'Tap for details',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 3. STATS METRICS BAR (DISTANCE, TIME, SPEED, HEARTBEAT, CALORIES)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPillStat(Icons.straighten_rounded, '${act.distanceKm.toStringAsFixed(2)} km', 'Dist'),
                    _buildPillStat(Icons.timer_outlined, durStr, 'Time'),
                    _buildPillStat(Icons.speed_rounded, '$calculatedSpeed km/h', 'Speed'),
                    _buildPillStat(Icons.favorite_rounded, '${act.heartRateBpm} bpm', 'Heart', isHeart: true),
                    _buildPillStat(Icons.local_fire_department_rounded, '${act.calories} cal', 'Kcal', isCal: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillStat(IconData icon, String value, String label, {bool isHeart = false, bool isCal = false}) {
    Color iconColor = AppColors.primaryBlue;
    if (isHeart) iconColor = const Color(0xFFE53935);
    if (isCal) iconColor = const Color(0xFFFF6D00);

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: iconColor),
            const SizedBox(width: 3),
            Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: isHeart ? const Color(0xFFD32F2F) : AppColors.textBlack,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF94A3B8),
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
