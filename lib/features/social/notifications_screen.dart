import 'package:flutter/material.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/social_service.dart';
import 'user_profile_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<SocialNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final notifs = await SocialService.instance.getNotifications();
    if (!mounted) return;
    setState(() {
      _notifications = notifs;
      _isLoading = false;
    });
  }

  Future<void> _markAllAsRead() async {
    await SocialService.instance.markAllNotificationsAsRead();
    if (!mounted) return;
    setState(() {
      for (var n in _notifications) {
        n.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read ✓'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _notifications.any((n) => !n.isRead);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
              ),
            )
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: AppColors.primaryOrange,
                  onRefresh: _loadNotifications,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      thickness: 0.6,
                      color: Color(0xFFF3F4F6),
                      indent: 72,
                    ),
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      return _buildNotificationTile(notif);
                    },
                  ),
                ),
    );
  }

  Widget _buildNotificationTile(SocialNotification notif) {
    IconData typeIcon;
    Color iconColor;

    switch (notif.type) {
      case 'follow':
        typeIcon = Icons.person_add_rounded;
        iconColor = AppColors.primaryOrange;
        break;
      case 'like':
        typeIcon = Icons.favorite_rounded;
        iconColor = const Color(0xFFED4956);
        break;
      case 'comment':
        typeIcon = Icons.mode_comment_rounded;
        iconColor = const Color(0xFF0095F6);
        break;
      default:
        typeIcon = Icons.notifications_rounded;
        iconColor = Colors.grey;
    }

    return InkWell(
      onTap: () async {
        if (!notif.isRead) {
          await SocialService.instance.markNotificationAsRead(notif.id);
          setState(() => notif.isRead = true);
        }

        if (notif.type == 'follow') {
          // Open target user profile
          final user = SocialUser(
            uid: notif.senderId,
            username: notif.senderUsername,
            displayName: notif.senderUsername,
            bio: 'Athlete @ JAIHIND Runners Club',
          );
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => UserProfileScreen(user: user)),
            );
          }
        }
      },
      child: Container(
        color: notif.isRead ? Colors.white : const Color(0xFFFFF9F5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Sender Avatar with notification type badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFFFF3E0),
                  child: Text(
                    notif.senderUsername.isNotEmpty
                        ? notif.senderUsername[0].toUpperCase()
                        : 'A',
                    style: const TextStyle(
                      color: AppColors.primaryOrange,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: iconColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Icon(typeIcon, size: 10, color: Colors.white),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 14),

            // Notification Message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: const TextStyle(fontSize: 13.5, color: Colors.black87),
                      children: [
                        TextSpan(
                          text: notif.senderUsername,
                          style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black),
                        ),
                        const TextSpan(text: ' '),
                        TextSpan(text: notif.message),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatTimeAgo(notif.createdAt),
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Action: Follow Back or Unread Dot
            if (notif.type == 'follow') ...[
              BouncingTap(
                onTap: () {
                  final target = SocialUser(
                    uid: notif.senderId,
                    username: notif.senderUsername,
                    displayName: notif.senderUsername,
                  );
                  SocialService.instance.followUser(target);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('You are now following @${notif.senderUsername}! 🏃‍♂️')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Follow Back',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ] else if (!notif.isRead) ...[
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primaryOrange,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryOrange.withOpacity(0.3), width: 2),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 38,
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Notifications Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'When fellow runners follow your profile, like your training sessions, or comment on your routes, you will be notified here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: Color(0xFF6B7280), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
