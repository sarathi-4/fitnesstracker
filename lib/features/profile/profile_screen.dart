import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/social_service.dart';
import '../../core/services/user_service.dart';
import '../../core/widgets/strava_workout_overlay.dart';
import '../settings/settings_screen.dart';
import '../social/search_users_screen.dart';
import '../social/social_feed_screen.dart';
import '../social/user_profile_screen.dart';
import '../workout/saved_activities_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final int _selectedTabIndex = 0; // 0: Grid Posts

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: UserService.instance,
      builder: (context, _) {
        final user = UserService.instance;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildInstagramAppBar(context, user),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // 1. PROFILE HEADER: AVATAR + STATS (POSTS, FOLLOWERS, FOLLOWING)
                _buildProfileHeader(context, user),

                const SizedBox(height: 12),

                // 2. USER BIO & WEBSITE LINK (Shown only when configured)
                _buildBioSection(context, user),

                const SizedBox(height: 14),

                // 3. ACTION BUTTONS: EDIT PROFILE | SHARE PROFILE | DISCOVER
                _buildActionButtons(context, user),

                const SizedBox(height: 16),

                // 4. FOUR INSTAGRAM TABS (Grid ⊞, Reels ▷, Reposts ⇄, Tagged 👤)
                _buildTabsBar(),

                // 5. POSTS CONTENT (Only completed running workouts can be posted!)
                _buildTabContent(context, user),

                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 1. TOP APP BAR (sarathi_joy4       +   ☰)
  // ---------------------------------------------------------------------------
  PreferredSizeWidget _buildInstagramAppBar(BuildContext context, UserService user) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 16,
      title: BouncingTap(
        onTap: () => _showAccountSwitcher(context, user),
        child: Text(
          user.username,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.black,
            letterSpacing: -0.3,
          ),
        ),
      ),
      actions: [
        // Community Feed (Followers & Friends Posts)
        BouncingTap(
          onTap: () {
            Navigator.push(
              context,
              AppRouteTransitions.slideHorizontal(const SocialFeedScreen()),
            );
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
            child: Icon(
              Icons.dynamic_feed_rounded,
              size: 25,
              color: Colors.black87,
            ),
          ),
        ),
        // Find Friends / Athlete Community Explorer (Men icon requested by user)
        BouncingTap(
          onTap: () {
            Navigator.push(
              context,
              AppRouteTransitions.slideHorizontal(const SearchUsersScreen()),
            );
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
            child: Icon(
              Icons.group_add_outlined,
              size: 27,
              color: Colors.black87,
            ),
          ),
        ),
        BouncingTap(
          onTap: () => _showMenuBottomSheet(context, user),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Icon(Icons.menu_rounded, size: 28, color: Colors.black87),
          ),
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. PROFILE HEADER (Avatar + Stats)
  // ---------------------------------------------------------------------------
  Widget _buildProfileHeader(BuildContext context, UserService user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar with + badge (Tactile BouncingTap: Camera or Gallery Picker)
          BouncingTap(
            onTap: () => _showChangePhotoBottomSheet(context, user),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  padding: const EdgeInsets.all(2.5),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(2.0),
                    child: ClipOval(
                      child: _buildAvatarImage(user),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0379CE),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Center(
                      child: Icon(Icons.add, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 24),

          // 3 Columns: posts, followers, following
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                BouncingTap(
                  onTap: () {},
                  child: _buildStatColumn('${user.postsCount}', 'posts'),
                ),
                BouncingTap(
                  onTap: () => _showFollowersDialog(context, 'Followers (${user.followersCount})', isFollowing: false),
                  child: _buildStatColumn('${user.followersCount}', 'followers'),
                ),
                BouncingTap(
                  onTap: () => _showFollowersDialog(context, 'Following (${user.followingCount})', isFollowing: true),
                  child: _buildStatColumn('${user.followingCount}', 'following'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String count, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarImage(UserService user) {
    final imagePath = user.profileImagePath;
    if (imagePath != null && imagePath.trim().isNotEmpty) {
      if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        return Image.network(
          imagePath,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => _buildEmptyAvatarPlaceholder(),
        );
      }
      final file = File(imagePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => _buildEmptyAvatarPlaceholder(),
        );
      }
    }
    return _buildEmptyAvatarPlaceholder();
  }

  Widget _buildEmptyAvatarPlaceholder() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: Icon(
          Icons.person_rounded,
          size: 46,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. BIO SECTION (Display Name + Bio lines + Link: Empty by default)
  // ---------------------------------------------------------------------------
  Widget _buildBioSection(BuildContext context, UserService user) {
    final hasDisplayName = user.displayName.trim().isNotEmpty;
    final hasBio = user.bio.trim().isNotEmpty;
    final hasWebsite = user.website.trim().isNotEmpty;

    if (!hasDisplayName && !hasBio && !hasWebsite) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display Name
          if (hasDisplayName) ...[
            Text(
              user.displayName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 3),
          ],

          // Bio text (Empty by default)
          if (hasBio) ...[
            Text(
              user.bio,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 5),
          ],

          // Website Link (Empty by default)
          if (hasWebsite) ...[
            BouncingTap(
              onTap: () => _launchWebUrl(user.website),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link_rounded, size: 16, color: Color(0xFF0C356A)),
                  const SizedBox(width: 4),
                  Text(
                    user.website,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0C356A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. ACTION BUTTONS ROW (Edit profile | Share profile | +👤)
  // ---------------------------------------------------------------------------
  Widget _buildActionButtons(BuildContext context, UserService user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          // Edit Profile
          Expanded(
            child: BouncingTap(
              onTap: () => _showEditProfileDialog(context, user),
              child: Container(
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEFEF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Edit profile',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Share Profile
          Expanded(
            child: BouncingTap(
              onTap: () => _showShareProfileDialog(context, user),
              child: Container(
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEFEF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Share profile',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Discover Person Icon (+👤) -> Discover & Search Athletes
          BouncingTap(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchUsersScreen()),
              );
            },
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFEFEFEF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(Icons.person_add_outlined, size: 18, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. POSTS TAB BAR (Only Post Grid Icon Centered)
  // ---------------------------------------------------------------------------
  Widget _buildTabsBar() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 0.8)),
      ),
      child: Center(
        child: Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.black,
                width: 2.0,
              ),
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.grid_on_sharp,
              size: 24,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. TAB CONTENT (STRICT: ONLY COMPLETED RUNNING WORKOUTS IN GRID!)
  // ---------------------------------------------------------------------------
  Widget _buildTabContent(BuildContext context, UserService user) {
    if (_selectedTabIndex != 0) {
      return const SizedBox(height: 80);
    }

    final posts = user.profilePosts;

    if (posts.isEmpty) {
      return const SizedBox(height: 80);
    }

    // 3-COLUMN SQUARE POSTS GRID (Instagram Style)
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: posts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1.5,
        mainAxisSpacing: 1.5,
      ),
      itemBuilder: (context, index) {
        final post = posts[index];
        return _buildPostGridTile(context, post, user);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 7. GRID ITEM TILE (Visual Runner Route Snapshot + Metrics)
  // ---------------------------------------------------------------------------
  Widget _buildPostGridTile(BuildContext context, ProfilePost post, UserService user) {
    return BouncingTap(
      scaleFactor: 0.95,
      onTap: () => _openPostDetailViewer(context, post, user),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          gradient: LinearGradient(
            colors: post.mode == 'Cycling'
                ? [const Color(0xFF0F172A), const Color(0xFF0369A1)]
                : [const Color(0xFF0F172A), const Color(0xFFEA580C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Photo thumbnail if available
            if (post.imagePath != null && File(post.imagePath!).existsSync())
              Positioned.fill(
                child: Image.file(
                  File(post.imagePath!),
                  fit: BoxFit.cover,
                ),
              )
            else
              // Route Polyline / Silhouette Graphic
              Center(
                child: Opacity(
                  opacity: 0.28,
                  child: Icon(
                    post.mode == 'Cycling' ? Icons.directions_bike_rounded : Icons.directions_run_rounded,
                    size: 68,
                    color: Colors.white,
                  ),
                ),
              ),

            // Top Badges: Mode icon & Likes
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  post.mode,
                  style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            if (post.likes > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite, size: 11, color: Colors.redAccent),
                    const SizedBox(width: 2),
                    Text(
                      '${post.likes}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

            // Bottom Metric: Distance
            Positioned(
              bottom: 6,
              left: 6,
              right: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${post.distanceKm.toStringAsFixed(2)} km',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    '${post.avgPace} • ${post.calories} kcal',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 9. FULL-SCREEN INSTAGRAM POST DETAIL VIEWER (Likes, Comments, WhatsApp)
  // ---------------------------------------------------------------------------
  void _openPostDetailViewer(BuildContext context, ProfilePost post, UserService user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final formattedDuration =
                '${(post.durationSeconds ~/ 60).toString().padLeft(2, '0')}:${(post.durationSeconds % 60).toString().padLeft(2, '0')}';

            return FractionallySizedBox(
              heightFactor: 0.92,
              child: Column(
                children: [
                  // Header Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 17,
                          backgroundColor: const Color(0xFFF1F5F9),
                          child: ClipOval(
                            child: SizedBox(
                              width: 34,
                              height: 34,
                              child: _buildAvatarImage(user),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.username,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                            ),
                            Text(
                              post.locationName,
                              style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.more_vert_rounded, size: 20),
                          onPressed: () {
                            _showPostOptionsMenu(modalCtx, post, user);
                          },
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: Color(0xFFF1F5F9)),

                  // Scrollable Post Body
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Visual Workout Media Card
                          GestureDetector(
                            onDoubleTap: () {
                              user.toggleLikePost(post.id);
                              setModalState(() {});
                            },
                            child: Container(
                              height: 340,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: post.mode == 'Cycling'
                                      ? [const Color(0xFF0F172A), const Color(0xFF0369A1), const Color(0xFF0284C7)]
                                      : [const Color(0xFF0F172A), const Color(0xFF1E3A8A), const Color(0xFFEA580C)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  // 1. Photo if user attached an image with Strava-Style Athletic Overlay
                                  if (post.imagePath != null && File(post.imagePath!).existsSync()) ...[
                                    Positioned.fill(
                                      child: Image.file(
                                        File(post.imagePath!),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    // Strava-Style Athletic Overlay (Distance, Pace, Time, Mini Route, JAIHIND)
                                    StravaWorkoutOverlay(
                                      distanceKm: post.distanceKm,
                                      pace: post.avgPace,
                                      durationSeconds: post.durationSeconds,
                                      routePoints: post.gpsRoutePoints,
                                      brandName: 'JAIHIND',
                                    ),
                                  ]
                                  // 2. Interactive Google Map if GPS route points exist
                                  else if (post.gpsRoutePoints.isNotEmpty)
                                    GoogleMap(
                                      initialCameraPosition: CameraPosition(
                                        target: post.gpsRoutePoints.first,
                                        zoom: 16,
                                      ),
                                      polylines: {
                                        Polyline(
                                          polylineId: PolylineId(post.id),
                                          points: post.gpsRoutePoints,
                                          color: AppColors.primaryBlue,
                                          width: 5,
                                        ),
                                      },
                                      markers: {
                                        Marker(
                                          markerId: const MarkerId('start'),
                                          position: post.gpsRoutePoints.first,
                                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                                        ),
                                        Marker(
                                          markerId: const MarkerId('finish'),
                                          position: post.gpsRoutePoints.last,
                                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                                        ),
                                      },
                                      zoomControlsEnabled: false,
                                      mapToolbarEnabled: false,
                                      myLocationButtonEnabled: false,
                                    )
                                  // 3. Energetic JAIHIND Athletic Route Circuit Card (Never plain black!)
                                  else
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Positioned(
                                          right: -20,
                                          top: -20,
                                          child: Opacity(
                                            opacity: 0.14,
                                            child: Icon(
                                              post.mode == 'Cycling' ? Icons.directions_bike_rounded : Icons.directions_run_rounded,
                                              size: 220,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.12),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.white.withOpacity(0.25), width: 2),
                                                ),
                                                child: Icon(
                                                  post.mode == 'Cycling' ? Icons.directions_bike_rounded : Icons.directions_run_rounded,
                                                  size: 46,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                post.title.toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 1.1,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.18),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  '${post.locationName} • JAIHIND ATHLETE',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                  // Top Brand Badge overlay
                                  Positioned(
                                    top: 12,
                                    left: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.65),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.flash_on_rounded, color: AppColors.primaryOrange, size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            'JAIHIND ${post.mode.toUpperCase()}',
                                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Overlay Metrics Card at bottom of media (for Map or Graphic without photo)
                                  if (post.imagePath == null)
                                    Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          _buildOverlayMetric('DISTANCE', '${post.distanceKm.toStringAsFixed(2)} km'),
                                          _buildOverlayMetric('PACE', post.avgPace),
                                          _buildOverlayMetric('TIME', formattedDuration),
                                          _buildOverlayMetric('CALORIES', '${post.calories} kcal'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Action Buttons Row: Heart (Like), Comment, Share WhatsApp
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    color: post.isLiked ? Colors.redAccent : Colors.black87,
                                    size: 26,
                                  ),
                                  onPressed: () {
                                    user.toggleLikePost(post.id);
                                    setModalState(() {});
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.mode_comment_outlined, size: 24, color: Colors.black87),
                                  onPressed: () => _showAddCommentSheet(modalCtx, post, user, setModalState),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.send_rounded, size: 24, color: Colors.black87),
                                  tooltip: 'Share via WhatsApp',
                                  onPressed: () => _sharePostViaWhatsApp(post, user),
                                ),
                              ],
                            ),
                          ),

                          // Likes Counter
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              post.likes > 0
                                  ? 'Liked by ${post.likes} athlete${post.likes > 1 ? 's' : ''}'
                                  : 'Be the first to like this run',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Caption: username + title/notes
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(color: Colors.black, fontSize: 13.5, height: 1.35),
                                children: [
                                  TextSpan(
                                    text: '${user.username} ',
                                    style: const TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                  TextSpan(text: post.caption.isNotEmpty ? post.caption : post.title),
                                ],
                              ),
                            ),
                          ),

                          // Hashtags
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Text(
                              '#JAIHIND #RunnersClub #Fitness #TamilNaduRunners #TrackTrainAchieve',
                              style: TextStyle(color: Color(0xFF0369A1), fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),

                          // Comments List
                          if (post.comments.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: Text(
                                'View all ${post.comments.length} comments',
                                style: const TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w600),
                              ),
                            ),
                            ...post.comments.take(3).map(
                                  (c) => Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                                    child: RichText(
                                      text: TextSpan(
                                        style: const TextStyle(color: Colors.black87, fontSize: 12.5),
                                        children: [
                                          const TextSpan(
                                            text: 'athlete_friend ',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(text: c),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                          ],

                          // Date
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              _formatPostDate(post.dateTime),
                              style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOverlayMetric(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 10. EDIT PROFILE MODAL (Name, Username, Bio, Website)
  // ---------------------------------------------------------------------------
  void _showEditProfileDialog(BuildContext context, UserService user) {
    final nameCtrl = TextEditingController(text: user.displayName);
    final userCtrl = TextEditingController(text: user.username);
    final bioCtrl = TextEditingController(text: user.bio);
    final webCtrl = TextEditingController(text: user.website);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel', style: TextStyle(color: Colors.black87)),
                    ),
                    const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    TextButton(
                      onPressed: () {
                        user.updateInstagramProfile(
                          displayName: nameCtrl.text,
                          username: userCtrl.text,
                          bio: bioCtrl.text,
                          website: webCtrl.text,
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile updated successfully! ✨'),
                            backgroundColor: AppColors.accentGreen,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text('Done', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 10),
                Center(
                  child: Column(
                    children: [
                      ClipOval(
                        child: SizedBox(
                          width: 68,
                          height: 68,
                          child: _buildAvatarImage(user),
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showChangePhotoBottomSheet(context, user);
                        },
                        child: const Text(
                          'Edit picture or avatar',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                _buildEditField('Name', nameCtrl),
                const SizedBox(height: 12),
                _buildEditField('Username', userCtrl),
                const SizedBox(height: 12),
                _buildEditField('Bio', bioCtrl, maxLines: 4),
                const SizedBox(height: 12),
                _buildEditField('Links', webCtrl),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textGrey)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryBlue)),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 11. SHARE PROFILE DIALOG (WHATSAPP + COPY)
  // ---------------------------------------------------------------------------
  void _showShareProfileDialog(BuildContext context, UserService user) {
    final shareMessage =
        '🏃‍♂️ *Connect with me on JAIHIND Runners Club!* 🇮🇳\n\n'
        'Athlete: *${user.displayName}* (@${user.username})\n'
        'Bio: ${user.bio.replaceAll('\n', ' ')}\n'
        'Check workouts & connect: ${user.website}\n\n'
        'TRACK. TRAIN. ACHIEVE. 🚀';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.share_outlined, color: AppColors.primaryBlue),
            SizedBox(width: 8),
            Text('Share Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('Share your athlete profile with friends via WhatsApp:\n\n@${user.username}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: shareMessage));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile link copied!'), backgroundColor: AppColors.primaryBlue),
              );
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
            label: const Text('WhatsApp'),
            onPressed: () async {
              Navigator.pop(ctx);
              final encoded = Uri.encodeComponent(shareMessage);
              final whatsappUri = Uri.parse('whatsapp://send?text=$encoded');
              try {
                if (await canLaunchUrl(whatsappUri)) {
                  await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
                } else {
                  await launchUrl(Uri.parse('https://api.whatsapp.com/send?text=$encoded'), mode: LaunchMode.externalApplication);
                }
              } catch (_) {
                await Clipboard.setData(ClipboardData(text: shareMessage));
              }
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 12. HELPER SHEETS (FOLLOWERS, OPTIONS)
  // ---------------------------------------------------------------------------

  void _showFollowersDialog(BuildContext context, String title, {bool isFollowing = false}) {
    List<SocialUser> users = [];
    bool isLoading = true;
    bool hasInitialized = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          if (!hasInitialized) {
            hasInitialized = true;
            final future = isFollowing
                ? SocialService.instance.getFollowingUsers()
                : SocialService.instance.getFollowersUsers();
            future.then((fetched) {
              if (sheetCtx.mounted) {
                setSheetState(() {
                  users = fetched;
                  isLoading = false;
                });
              }
            });
          }

          final liveHeading = isFollowing
              ? 'Following (${isLoading ? UserService.instance.followingCount : users.length})'
              : 'Followers (${isLoading ? UserService.instance.followersCount : users.length})';

          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.72,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          liveHeading,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SearchUsersScreen()),
                            );
                          },
                          child: const Text(
                            'Search Athletes',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(color: AppColors.primaryBlue),
                        ),
                      )
                    else if (users.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Column(
                            children: [
                              Icon(
                                isFollowing ? Icons.person_search_rounded : Icons.people_outline_rounded,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                isFollowing ? 'Not following anyone yet' : 'No followers yet',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isFollowing
                                    ? 'Discover fellow runners to follow on JAIHIND!'
                                    : 'Share your profile or invite friends to grow your runner circle.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey),
                              ),
                              const SizedBox(height: 18),
                              BouncingTap(
                                onTap: () {
                                  Navigator.pop(ctx);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const SearchUsersScreen()),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Find Athletes 🏃‍♂️',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: users.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: Color(0xFFF1F5F9),
                          ),
                          itemBuilder: (_, index) {
                            final athlete = users[index];
                            final initial = athlete.username.isNotEmpty
                                ? athlete.username[0].toUpperCase()
                                : 'A';
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                              onTap: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UserProfileScreen(user: athlete),
                                  ),
                                );
                              },
                              leading: CircleAvatar(
                                radius: 23,
                                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12),
                                backgroundImage: athlete.profileImageUrl != null &&
                                        athlete.profileImageUrl!.startsWith('http')
                                    ? NetworkImage(athlete.profileImageUrl!)
                                    : null,
                                child: (athlete.profileImageUrl == null ||
                                        !athlete.profileImageUrl!.startsWith('http'))
                                    ? Text(
                                        initial,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 17,
                                          color: AppColors.primaryBlue,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                '@${athlete.username}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                  color: Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    athlete.displayName,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF475569),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (athlete.location.isNotEmpty)
                                    Text(
                                      athlete.location,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF94A3B8),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                              trailing: SizedBox(
                                height: 32,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: athlete.isFollowing
                                        ? const Color(0xFFF1F5F9)
                                        : AppColors.primaryBlue,
                                    foregroundColor: athlete.isFollowing
                                        ? Colors.black87
                                        : Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () async {
                                    if (athlete.isFollowing) {
                                      await SocialService.instance.unfollowUser(athlete.uid);
                                      if (sheetCtx.mounted) {
                                        setSheetState(() {
                                          athlete.isFollowing = false;
                                          if (isFollowing) {
                                            users.removeAt(index);
                                          }
                                        });
                                      }
                                    } else {
                                      await SocialService.instance.followUser(athlete);
                                      if (sheetCtx.mounted) {
                                        setSheetState(() {
                                          athlete.isFollowing = true;
                                        });
                                      }
                                    }
                                  },
                                  child: Text(
                                    athlete.isFollowing ? 'Following' : 'Follow',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAccountSwitcher(BuildContext context, UserService user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFF1F5F9),
                  child: ClipOval(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: _buildAvatarImage(user),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                    if (user.displayName.isNotEmpty)
                      Text(
                        user.displayName,
                        style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                      ),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.check_circle_rounded, color: AppColors.primaryBlue, size: 22),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add_a_photo_outlined, color: Colors.black87),
              title: const Text('Change Profile Photo', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _showChangePhotoBottomSheet(context, user);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Colors.black87),
              title: const Text('Edit Profile Information', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _showEditProfileDialog(context, user);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add_outlined, color: Colors.black87),
              title: const Text('Discover & Search Friends', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchUsersScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePhotoBottomSheet(BuildContext context, UserService user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'Profile Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.primaryBlue),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickProfileImage(ImageSource.gallery, user);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF7ED),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryOrange),
                ),
                title: const Text('Take Photo with Camera', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickProfileImage(ImageSource.camera, user);
                },
              ),
              if (user.profileImagePath != null && user.profileImagePath!.isNotEmpty)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF2F2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  ),
                  title: const Text('Remove Current Photo', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.redAccent)),
                  onTap: () {
                    user.updateImage(null);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile photo removed')),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickProfileImage(ImageSource source, UserService user) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        user.updateImage(pickedFile.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated! ✨'),
              backgroundColor: AppColors.primaryBlue,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not set image: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showAddCommentSheet(BuildContext context, ProfilePost post, UserService user, void Function(void Function()) setModalState) {
    final commentCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: commentCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Add a comment...',
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_upward_rounded, color: AppColors.primaryBlue),
              onPressed: () {
                if (commentCtrl.text.trim().isNotEmpty) {
                  user.addCommentToPost(post.id, commentCtrl.text.trim());
                  Navigator.pop(ctx);
                  setModalState(() {});
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPostOptionsMenu(BuildContext context, ProfilePost post, UserService user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.send_rounded, color: Color(0xFF25D366)),
              title: const Text('Share to WhatsApp'),
              onTap: () {
                Navigator.pop(ctx);
                _sharePostViaWhatsApp(post, user);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: const Text('Delete Post', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                user.deleteProfilePost(post.id);
                Navigator.pop(ctx);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post deleted')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _sharePostViaWhatsApp(ProfilePost post, UserService user) async {
    final text =
        '🏃‍♂️ *${user.displayName} completed a ${post.mode}!* 🏆\n\n'
        '📍 Location: ${post.locationName}\n'
        '📏 Distance: ${post.distanceKm.toStringAsFixed(2)} km\n'
        '⚡ Pace: ${post.avgPace}\n'
        '🔥 Calories: ${post.calories} kcal\n'
        '❤️ Heart Rate: ${post.heartRateBpm} bpm\n\n'
        'Follow my fitness journey on JAIHIND! 🇮🇳';

    final encoded = Uri.encodeComponent(text);
    final whatsappUri = Uri.parse('whatsapp://send?text=$encoded');
    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(Uri.parse('https://api.whatsapp.com/send?text=$encoded'), mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
    }
  }

  void _showMenuBottomSheet(BuildContext context, UserService user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.dynamic_feed_rounded, color: Colors.black87),
              title: const Text('Community Feed', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('View followers & friends workout posts', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  AppRouteTransitions.slideHorizontal(const SocialFeedScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined, color: Colors.black87),
              title: const Text('Settings & Privacy', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.history_rounded, color: Colors.black87),
              title: const Text('Saved Activities History', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedActivitiesScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_rounded, color: Colors.black87),
              title: const Text('QR Code & Share', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(ctx);
                _showShareProfileDialog(context, user);
              },
            ),
          ],
        ),
      ),
    );
  }



  void _launchWebUrl(String url) async {
    final fullUrl = url.startsWith('http') ? url : 'https://$url';
    final uri = Uri.parse(fullUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  String _formatPostDate(DateTime dt) {
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[dt.month - 1].toUpperCase()} ${dt.day}, ${dt.year}';
  }
}
