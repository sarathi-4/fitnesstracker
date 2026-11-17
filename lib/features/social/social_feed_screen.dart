import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/social_service.dart';
import '../../core/widgets/jaihind_brand_logo.dart';
import '../../core/widgets/strava_workout_overlay.dart';
import 'search_users_screen.dart';
import 'user_profile_screen.dart';

class SocialFeedScreen extends StatefulWidget {
  final bool showAppBar;
  const SocialFeedScreen({super.key, this.showAppBar = true});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed({bool refresh = false}) async {
    setState(() => _isLoading = true);
    await SocialService.instance.getFeedPosts(refresh: refresh);
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final bodyContent = AnimatedBuilder(
      animation: SocialService.instance,
      builder: (context, _) {
        final posts = SocialService.instance.cachedFeedPosts;

        if (_isLoading && posts.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryOrange),
          );
        }

        if (posts.isEmpty) {
          return RefreshIndicator(
            color: AppColors.primaryOrange,
            onRefresh: () => _loadFeed(refresh: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.people_outline_rounded, size: 54, color: AppColors.primaryOrange),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Followers & Friends Feed',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textBlack),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Follow fellow JAIHIND runners or invite friends to see their workout posts, routes, pace and personal records here!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.4),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        icon: const Icon(Icons.person_search_rounded, size: 18),
                        label: const Text('Find Friends to Follow 👥', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            AppRouteTransitions.slideHorizontal(const SearchUsersScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primaryOrange,
          onRefresh: () => _loadFeed(refresh: true),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final post = posts[index];
              return _buildSocialPostCard(context, post);
            },
          ),
        );
      },
    );

    if (!widget.showAppBar) {
      return bodyContent;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            JaihindBrandLogo(fontSize: 18, emblemHeight: 26, showSubtitle: false),
            SizedBox(width: 8),
            Text(
              'Community Feed',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_outlined, color: Colors.black87, size: 25),
            tooltip: 'Find Friends',
            onPressed: () => Navigator.push(
              context,
              AppRouteTransitions.slideHorizontal(const SearchUsersScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black87, size: 24),
            tooltip: 'Refresh Feed',
            onPressed: () => _loadFeed(refresh: true),
          ),
        ],
      ),
      body: bodyContent,
    );
  }

  // ---------------------------------------------------------------------------
  // SOCIAL POST CARD
  // ---------------------------------------------------------------------------
  Widget _buildSocialPostCard(BuildContext context, SocialPost post) {
    final isMyPost = post.userId == SocialService.instance.currentUserId;

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header: Avatar, Name, Username, Location, Options Menu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _openUserProfile(context, post.userId, post.username, post.userDisplayName),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFEFF6FF),
                    backgroundImage: post.userProfileImage != null
                        ? AssetImage(post.userProfileImage!)
                        : const AssetImage('assets/images/running_athletes.png'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openUserProfile(context, post.userId, post.username, post.userDisplayName),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              post.username,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: _getActivityColor(post.activityType).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                post.activityType,
                                style: TextStyle(
                                  color: _getActivityColor(post.activityType),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          post.locationName,
                          style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.black87),
                  onPressed: () => _showPostOptions(context, post, isMyPost),
                ),
              ],
            ),
          ),

          // Post Media (Image or Workout Stat Visual Card)
          _buildPostMedia(context, post),

          // Workout Metric Strip (if metrics attached)
          if (post.distanceKm != null || post.durationSeconds != null)
            _buildMetricsStrip(post),

          // Action Row: Like, Comment, WhatsApp Share
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: post.isLiked ? Colors.redAccent : Colors.black87,
                    size: 26,
                  ),
                  onPressed: () => SocialService.instance.toggleLike(post),
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 23, color: Colors.black87),
                  onPressed: () => _showCommentsSheet(context, post),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, size: 22, color: Colors.black87),
                  tooltip: 'Share via WhatsApp',
                  onPressed: () => _sharePostViaWhatsApp(post),
                ),
              ],
            ),
          ),

          // Likes Counter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              post.likesCount > 0
                  ? '${post.likesCount} like${post.likesCount > 1 ? 's' : ''}'
                  : 'Be the first to like this',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
          const SizedBox(height: 4),

          // Caption
          if (post.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black, fontSize: 13.5, height: 1.35),
                  children: [
                    TextSpan(
                      text: '${post.username} ',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    TextSpan(text: post.caption),
                  ],
                ),
              ),
            ),

          // Comments Preview / Link
          if (post.commentsCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: GestureDetector(
                onTap: () => _showCommentsSheet(context, post),
                child: Text(
                  'View all ${post.commentsCount} comments',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey, fontWeight: FontWeight.w500),
                ),
              ),
            ),

          // Timestamp
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              _formatDate(post.createdAt),
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // POST MEDIA (Photo with Double-Tap to Like)
  // ---------------------------------------------------------------------------
  Widget _buildPostMedia(BuildContext context, SocialPost post) {
    if (post.imageUrl != null && post.imageUrl!.isNotEmpty) {
      final isLocal = !post.imageUrl!.startsWith('http');

      return GestureDetector(
        onDoubleTap: () {
          if (!post.isLiked) {
            SocialService.instance.toggleLike(post);
          }
        },
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 400),
          color: const Color(0xFFF1F5F9),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              isLocal
                  ? Image.file(File(post.imageUrl!), fit: BoxFit.cover)
                  : Image.network(
                      post.imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          height: 260,
                          color: const Color(0xFFF1F5F9),
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => _buildFallbackVisualCard(post),
                    ),
              if (post.distanceKm != null && post.distanceKm! > 0)
                StravaWorkoutOverlay(
                  distanceKm: post.distanceKm!,
                  pace: post.pace ?? '6:23 /km',
                  durationSeconds: post.durationSeconds ?? 0,
                  routePoints: post.routePoints ?? const [],
                  brandName: 'JAIHIND',
                  isCompact: true,
                ),
            ],
          ),
        ),
      );
    }

    return _buildFallbackVisualCard(post);
  }

  Widget _buildFallbackVisualCard(SocialPost post) {
    return GestureDetector(
      onDoubleTap: () {
        if (!post.isLiked) SocialService.instance.toggleLike(post);
      },
      child: Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _getActivityGradient(post.activityType),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: 0.2,
              child: Icon(_getActivityIcon(post.activityType), size: 100, color: Colors.white),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: Icon(_getActivityIcon(post.activityType), size: 36, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  '${post.activityType.toUpperCase()} SESSION',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
                ),
                if (post.distanceKm != null && post.distanceKm! > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${post.distanceKm!.toStringAsFixed(2)} KM COMPLETED',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsStrip(SocialPost post) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFF8FAFC),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (post.distanceKm != null && post.distanceKm! > 0)
            _buildMetricItem('Distance', '${post.distanceKm!.toStringAsFixed(2)} km'),
          if (post.durationSeconds != null && post.durationSeconds! > 0)
            _buildMetricItem(
              'Time',
              '${(post.durationSeconds! ~/ 60)}:${(post.durationSeconds! % 60).toString().padLeft(2, '0')}',
            ),
          if (post.pace != null) _buildMetricItem('Pace', post.pace!),
          if (post.calories != null && post.calories! > 0)
            _buildMetricItem('Calories', '${post.calories} kcal'),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.textBlack)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textGrey, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // COMMENTS SHEET
  // ---------------------------------------------------------------------------
  void _showCommentsSheet(BuildContext context, SocialPost post) {
    final commentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return FractionallySizedBox(
              heightFactor: 0.75,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                  ),
                  const Text('Comments', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const Divider(height: 16),
                  Expanded(
                    child: FutureBuilder<List<SocialComment>>(
                      future: SocialService.instance.getComments(post.id),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
                        }
                        final comments = snapshot.data!;
                        if (comments.isEmpty) {
                          return const Center(
                            child: Text('No comments yet. Start the conversation!', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: comments.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final c = comments[i];
                            final isMyComment = c.userId == SocialService.instance.currentUserId;
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 15,
                                  backgroundColor: const Color(0xFFEFF6FF),
                                  child: Text(c.username.isNotEmpty ? c.username[0].toUpperCase() : 'A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                          style: const TextStyle(color: Colors.black87, fontSize: 13),
                                          children: [
                                            TextSpan(text: '${c.username} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                                            TextSpan(text: c.text),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(_formatDate(c.createdAt), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                if (isMyComment)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.grey),
                                    onPressed: () async {
                                      await SocialService.instance.deleteComment(post.id, c.id);
                                      setSheetState(() {});
                                    },
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: EdgeInsets.only(
                      left: 14,
                      right: 14,
                      top: 8,
                      bottom: MediaQuery.of(ctx).viewInsets.bottom + 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentCtrl,
                            style: const TextStyle(fontSize: 13.5),
                            decoration: const InputDecoration(
                              hintText: 'Add a comment...',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_upward_rounded, color: AppColors.primaryBlue),
                          onPressed: () async {
                            final text = commentCtrl.text.trim();
                            if (text.isNotEmpty) {
                              commentCtrl.clear();
                              await SocialService.instance.addComment(post, text);
                              setSheetState(() {});
                            }
                          },
                        ),
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
  }

  // ---------------------------------------------------------------------------
  // POST OPTIONS MENU (Edit/Delete)
  // ---------------------------------------------------------------------------
  void _showPostOptions(BuildContext context, SocialPost post, bool isMyPost) {
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
              title: const Text('Share via WhatsApp'),
              onTap: () {
                Navigator.pop(ctx);
                _sharePostViaWhatsApp(post);
              },
            ),
            if (isMyPost) ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: AppColors.primaryBlue),
                title: const Text('Edit Caption'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditCaptionDialog(context, post);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                title: const Text('Delete Post', style: TextStyle(color: Colors.redAccent)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await SocialService.instance.deletePost(post.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Post deleted successfully')),
                    );
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditCaptionDialog(BuildContext context, SocialPost post) {
    final editCtrl = TextEditingController(text: post.caption);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Caption', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: editCtrl,
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await SocialService.instance.editPost(post.id, editCtrl.text.trim());
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _sharePostViaWhatsApp(SocialPost post) async {
    final text =
        '🏃‍♂️ *${post.username} completed a ${post.activityType}!* 🇮🇳\n\n'
        '${post.caption.isNotEmpty ? '"${post.caption}"\n\n' : ''}'
        '${post.distanceKm != null ? '📏 Distance: ${post.distanceKm!.toStringAsFixed(2)} km\n' : ''}'
        '${post.pace != null ? '⚡ Pace: ${post.pace}\n' : ''}'
        '${post.calories != null ? '🔥 Calories: ${post.calories} kcal\n' : ''}'
        '📍 ${post.locationName}\n\n'
        'Join me on JAIHIND Fitness Tracker! 🚀';

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

  void _openUserProfile(BuildContext context, String uid, String username, String displayName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          userId: uid,
          username: username,
          displayName: displayName,
        ),
      ),
    );
  }

  Color _getActivityColor(String type) {
    switch (type.toLowerCase()) {
      case 'running':
        return const Color(0xFFEA580C);
      case 'cycling':
        return const Color(0xFF0284C7);
      case 'walking':
        return const Color(0xFF16A34A);
      case 'hike':
      case 'hiking':
      case 'gym':
        return const Color(0xFF0D9488);
      default:
        return AppColors.primaryBlue;
    }
  }

  List<Color> _getActivityGradient(String type) {
    switch (type.toLowerCase()) {
      case 'running':
        return [const Color(0xFFEA580C), const Color(0xFFF97316)];
      case 'cycling':
        return [const Color(0xFF0369A1), const Color(0xFF0284C7)];
      case 'walking':
        return [const Color(0xFF15803D), const Color(0xFF22C55E)];
      case 'hike':
      case 'hiking':
      case 'gym':
        return [const Color(0xFF0F766E), const Color(0xFF14B8A6)];
      default:
        return [const Color(0xFF0379CE), const Color(0xFF14A847)];
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'running':
        return Icons.directions_run_rounded;
      case 'cycling':
        return Icons.directions_bike_rounded;
      case 'walking':
        return Icons.directions_walk_rounded;
      case 'hike':
      case 'hiking':
        return Icons.hiking_rounded;
      case 'gym':
        return Icons.fitness_center_rounded;
      default:
        return Icons.sports_score_rounded;
    }
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
