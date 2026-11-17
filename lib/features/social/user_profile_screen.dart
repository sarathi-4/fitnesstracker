import 'package:flutter/material.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/social_service.dart';

class UserProfileScreen extends StatefulWidget {
  final SocialUser? user;
  final String? userId;
  final String? username;
  final String? displayName;

  const UserProfileScreen({
    super.key,
    this.user,
    this.userId,
    this.username,
    this.displayName,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late SocialUser _user;
  List<SocialPost> _userPosts = [];
  bool _isLoadingPosts = true;
  int _selectedTabIndex = 0; // 0: Grid, 1: Tagged

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _user = widget.user!;
    } else {
      _user = SocialUser(
        uid: widget.userId ?? 'athlete_uid',
        username: widget.username ?? 'runner',
        displayName: widget.displayName ?? 'Athlete',
        bio: 'Athlete @ JAIHIND Runners Club 🏃‍♂️⚡',
      );
    }
    _checkFollowingStatus();
    _loadUserPosts();
  }

  Future<void> _checkFollowingStatus() async {
    final isFol = await SocialService.instance.isFollowing(_user.uid);
    if (mounted && isFol != _user.isFollowing) {
      setState(() {
        _user = SocialUser(
          uid: _user.uid,
          username: _user.username,
          displayName: _user.displayName,
          bio: _user.bio,
          profileImageUrl: _user.profileImageUrl,
          followersCount: _user.followersCount,
          followingCount: _user.followingCount,
          postsCount: _user.postsCount,
          isFollowing: isFol,
        );
      });
    }
  }

  Future<void> _loadUserPosts() async {
    setState(() => _isLoadingPosts = true);
    final posts = await SocialService.instance.getUserPosts(_user.uid);
    if (!mounted) return;
    setState(() {
      _userPosts = posts;
      _isLoadingPosts = false;
    });
  }

  Future<void> _toggleFollow() async {
    final originalState = _user.isFollowing;
    final originalFollowers = _user.followersCount;

    setState(() {
      _user.isFollowing = !originalState;
      // Optimistically update count
      _user = SocialUser(
        uid: _user.uid,
        username: _user.username,
        displayName: _user.displayName,
        bio: _user.bio,
        profileImageUrl: _user.profileImageUrl,
        followersCount: originalState ? originalFollowers - 1 : originalFollowers + 1,
        followingCount: _user.followingCount,
        postsCount: _user.postsCount,
        isFollowing: !originalState,
      );
    });

    bool success;
    if (originalState) {
      success = await SocialService.instance.unfollowUser(_user.uid);
    } else {
      success = await SocialService.instance.followUser(_user);
    }

    if (!success && mounted) {
      setState(() {
        _user = SocialUser(
          uid: _user.uid,
          username: _user.username,
          displayName: _user.displayName,
          bio: _user.bio,
          profileImageUrl: _user.profileImageUrl,
          followersCount: originalFollowers,
          followingCount: _user.followingCount,
          postsCount: _user.postsCount,
          isFollowing: originalState,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update follow status')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _user.username,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF0095F6)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.black),
            onPressed: () => _showUserOptionsSheet(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryOrange,
        onRefresh: _loadUserPosts,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // 1. PROFILE HEADER: AVATAR + STATS (POSTS, FOLLOWERS, FOLLOWING)
              _buildProfileHeader(),

              const SizedBox(height: 12),

              // 2. BIO SECTION
              _buildBioSection(),

              const SizedBox(height: 16),

              // 3. ACTION BUTTONS: FOLLOW / FOLLOWING + MESSAGE
              _buildActionButtons(),

              const SizedBox(height: 16),

              // 4. TABS: GRID / TAGGED
              _buildTabsBar(),

              // 5. POSTS GRID
              _buildPostsSection(),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 82,
            height: 82,
            padding: const EdgeInsets.all(2.5),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primaryOrange, Color(0xFFFF8A00), AppColors.primaryBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              padding: const EdgeInsets.all(2),
              child: CircleAvatar(
                backgroundColor: const Color(0xFFFFF3E0),
                child: Text(
                  _user.displayName.isNotEmpty ? _user.displayName[0].toUpperCase() : 'A',
                  style: const TextStyle(
                    color: AppColors.primaryOrange,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 24),

          // 3 Columns: posts, followers, following
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('${_userPosts.length > _user.postsCount ? _userPosts.length : _user.postsCount}', 'posts'),
                _buildStatColumn('${_user.followersCount}', 'followers'),
                _buildStatColumn('${_user.followingCount}', 'following'),
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

  Widget _buildBioSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _user.displayName,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 3),
          if (_user.bio != null && _user.bio!.isNotEmpty)
            Text(
              _user.bio!,
              style: const TextStyle(
                fontSize: 13.5,
                color: Colors.black87,
                height: 1.35,
              ),
            )
          else
            const Text(
              'Athlete @ JAIHIND Runners Club 🏃‍♂️⚡\nTracking endurance, pace and GPS milestones.',
              style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.3),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          // Follow / Following Button
          Expanded(
            flex: 5,
            child: BouncingTap(
              onTap: _toggleFollow,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 36,
                decoration: BoxDecoration(
                  color: _user.isFollowing ? const Color(0xFFEFEFEF) : AppColors.primaryOrange,
                  borderRadius: BorderRadius.circular(8),
                  border: _user.isFollowing
                      ? Border.all(color: const Color(0xFFD1D5DB), width: 1)
                      : null,
                ),
                child: Center(
                  child: Text(
                    _user.isFollowing ? 'Following' : 'Follow',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _user.isFollowing ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Message Button
          Expanded(
            flex: 4,
            child: BouncingTap(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Direct Messaging with @${_user.username} coming soon! 💬'),
                    backgroundColor: Colors.black87,
                  ),
                );
              },
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEFEF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Message',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabsBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 0.8)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedTabIndex == 0 ? Colors.black : Colors.transparent,
                      width: 1.8,
                    ),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.grid_on_sharp,
                    size: 22,
                    color: _selectedTabIndex == 0 ? Colors.black : const Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedTabIndex == 1 ? Colors.black : Colors.transparent,
                      width: 1.8,
                    ),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.assignment_ind_outlined,
                    size: 22,
                    color: _selectedTabIndex == 1 ? Colors.black : const Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsSection() {
    if (_selectedTabIndex == 1) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.person_pin_outlined, size: 48, color: Color(0xFF9CA3AF)),
              SizedBox(height: 12),
              Text(
                'Photos and Videos of Athlete',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              SizedBox(height: 4),
              Text(
                'When people tag this athlete in workouts, they will appear here.',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF6B7280)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoadingPosts) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
          ),
        ),
      );
    }

    if (_userPosts.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 24),
        child: Center(
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black87, width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.directions_run_rounded, size: 32, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'No Workouts Posted Yet',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '@${_user.username} hasn\'t shared any running or workout sessions yet.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      );
    }

    // 3-Column Grid of Posts
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _userPosts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1.5,
        mainAxisSpacing: 1.5,
      ),
      itemBuilder: (context, index) {
        final post = _userPosts[index];
        return GestureDetector(
          onTap: () => _openPostDetailViewer(post),
          child: Container(
            color: const Color(0xFF1E293B),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background workout badge design
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryOrange.withOpacity(0.85),
                        const Color(0xFF0F172A),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.directions_run_rounded, color: Colors.white, size: 28),
                        const SizedBox(height: 4),
                        if (post.distanceKm != null && post.distanceKm! > 0)
                          Text(
                            '${post.distanceKm!.toStringAsFixed(1)} KM',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Likes counter in bottom-right
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite, size: 11, color: Colors.white),
                      const SizedBox(width: 2),
                      Text(
                        '${post.likesCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openPostDetailViewer(SocialPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Author Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFFFFF3E0),
                      child: Text(
                        post.userDisplayName.isNotEmpty ? post.userDisplayName[0].toUpperCase() : 'A',
                        style: const TextStyle(
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.username,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        Text(
                          post.locationName,
                          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11.5),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Scrollable Post Details
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Metrics Strip
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDetailMetric(
                            icon: Icons.straighten_rounded,
                            label: 'Distance',
                            val: post.distanceKm != null
                                ? '${post.distanceKm!.toStringAsFixed(2)} km'
                                : '--',
                          ),
                          _buildDetailMetric(
                            icon: Icons.timer_outlined,
                            label: 'Duration',
                            val: post.durationSeconds != null
                                ? _formatSeconds(post.durationSeconds!)
                                : '--',
                          ),
                          _buildDetailMetric(
                            icon: Icons.speed_rounded,
                            label: 'Pace',
                            val: post.pace ?? '--',
                          ),
                          _buildDetailMetric(
                            icon: Icons.local_fire_department_rounded,
                            label: 'Calories',
                            val: post.calories != null ? '${post.calories} kcal' : '--',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Caption
                    Text(
                      post.caption,
                      style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
                    ),

                    const SizedBox(height: 18),

                    // Like & Action Bar
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            await SocialService.instance.toggleLike(post);
                            if (mounted) setState(() {});
                          },
                          child: Row(
                            children: [
                              Icon(
                                post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: post.isLiked ? const Color(0xFFED4956) : Colors.black87,
                                size: 24,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${post.likesCount} likes',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Row(
                          children: [
                            const Icon(Icons.mode_comment_outlined, size: 22, color: Colors.black87),
                            const SizedBox(width: 6),
                            Text(
                              '${post.commentsCount} comments',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailMetric({required IconData icon, required String label, required String val}) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryOrange),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B7280))),
      ],
    );
  }

  String _formatSeconds(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showUserOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share this Profile'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Profile link copied: https://jaihind-runner.web.app/@${_user.username}')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_gmailerrorred_rounded, color: Colors.redAccent),
              title: const Text('Report Athlete', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thank you. Athlete report submitted for review.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
