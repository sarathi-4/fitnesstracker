import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'user_service.dart';

/// Model representing a Social Post in JAIHIND
class SocialPost {
  final String id;
  final String userId;
  final String username;
  final String userDisplayName;
  final String? userProfileImage;
  final String? imageUrl;
  final String caption;
  final String activityType; // Running, Walking, Cycling, Gym, Workout
  final double? distanceKm;
  final int? durationSeconds;
  final int? calories;
  final String? pace;
  final List<LatLng>? routePoints;
  int likesCount;
  int commentsCount;
  bool isLiked;
  final DateTime createdAt;
  final String locationName;

  SocialPost({
    required this.id,
    required this.userId,
    required this.username,
    required this.userDisplayName,
    this.userProfileImage,
    this.imageUrl,
    required this.caption,
    this.activityType = 'Running',
    this.distanceKm,
    this.durationSeconds,
    this.calories,
    this.pace,
    this.routePoints,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    required this.createdAt,
    this.locationName = 'Tamil Nadu',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'username': username,
        'userDisplayName': userDisplayName,
        'userProfileImage': userProfileImage,
        'imageUrl': imageUrl,
        'caption': caption,
        'activityType': activityType,
        'distanceKm': distanceKm,
        'durationSeconds': durationSeconds,
        'calories': calories,
        'pace': pace,
        'routePoints': routePoints
            ?.map((p) => {'lat': p.latitude, 'lng': p.longitude})
            .toList(),
        'likesCount': likesCount,
        'commentsCount': commentsCount,
        'createdAt': FieldValue.serverTimestamp(),
        'createdAtIso': createdAt.toIso8601String(),
        'locationName': locationName,
      };

  factory SocialPost.fromDoc(DocumentSnapshot doc, {bool isLikedByMe = false}) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    DateTime parsedDate = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      parsedDate = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAtIso'] is String) {
      parsedDate = DateTime.tryParse(data['createdAtIso']) ?? DateTime.now();
    }

    List<LatLng>? parsedRoute;
    if (data['routePoints'] is List) {
      try {
        parsedRoute = (data['routePoints'] as List)
            .whereType<Map>()
            .map((m) => LatLng(
                  (m['lat'] as num).toDouble(),
                  (m['lng'] as num).toDouble(),
                ))
            .toList();
      } catch (_) {}
    }

    return SocialPost(
      id: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? 'runner',
      userDisplayName: data['userDisplayName'] ?? 'Athlete',
      userProfileImage: data['userProfileImage'],
      imageUrl: data['imageUrl'],
      caption: data['caption'] ?? '',
      activityType: data['activityType'] ?? 'Running',
      distanceKm: (data['distanceKm'] as num?)?.toDouble(),
      durationSeconds: data['durationSeconds'] as int?,
      calories: data['calories'] as int?,
      pace: data['pace'],
      routePoints: parsedRoute,
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      isLiked: isLikedByMe,
      createdAt: parsedDate,
      locationName: data['locationName'] ?? 'Tamil Nadu, India',
    );
  }
}

/// Model representing a Comment on a Post
class SocialComment {
  final String id;
  final String postId;
  final String userId;
  final String username;
  final String? userProfileImage;
  final String text;
  final DateTime createdAt;

  SocialComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    this.userProfileImage,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'postId': postId,
        'userId': userId,
        'username': username,
        'userProfileImage': userProfileImage,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        'createdAtIso': createdAt.toIso8601String(),
      };

  factory SocialComment.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    DateTime parsedDate = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      parsedDate = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAtIso'] is String) {
      parsedDate = DateTime.tryParse(data['createdAtIso']) ?? DateTime.now();
    }

    return SocialComment(
      id: doc.id,
      postId: data['postId'] ?? '',
      userId: data['userId'] ?? '',
      username: data['username'] ?? 'runner',
      userProfileImage: data['userProfileImage'],
      text: data['text'] ?? '',
      createdAt: parsedDate,
    );
  }
}

/// Model representing a Registered Social Athlete Profile
class SocialUser {
  final String uid;
  final String username;
  final String displayName;
  final String? bio;
  final String? profileImageUrl;
  final String location;
  final String fitnessInfo;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  bool isFollowing;

  SocialUser({
    required this.uid,
    required this.username,
    required this.displayName,
    this.bio,
    this.profileImageUrl,
    this.location = 'Tamil Nadu',
    this.fitnessInfo = '10K Marathon Athlete',
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.isFollowing = false,
  });

  factory SocialUser.fromDoc(DocumentSnapshot doc, {bool isFollowing = false}) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return SocialUser(
      uid: doc.id,
      username: data['username'] ?? 'athlete',
      displayName: data['fullName'] ?? data['displayName'] ?? 'Runner',
      bio: data['bio'],
      profileImageUrl: data['profileImageUrl'],
      location: data['location'] ?? data['city'] ?? 'Tamil Nadu',
      fitnessInfo: data['fitnessInfo'] ?? data['primarySport'] ?? '10K Runner • 4:50 pace',
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      postsCount: data['postsCount'] ?? 0,
      isFollowing: isFollowing,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'username': username,
        'displayName': displayName,
        'bio': bio,
        'profileImageUrl': profileImageUrl,
        'location': location,
        'fitnessInfo': fitnessInfo,
        'followersCount': followersCount,
        'followingCount': followingCount,
        'postsCount': postsCount,
        'isFollowing': isFollowing,
      };

  factory SocialUser.fromJson(Map<String, dynamic> data) {
    return SocialUser(
      uid: data['uid'] ?? '',
      username: data['username'] ?? 'athlete',
      displayName: data['displayName'] ?? 'Runner',
      bio: data['bio'],
      profileImageUrl: data['profileImageUrl'],
      location: data['location'] ?? 'Tamil Nadu',
      fitnessInfo: data['fitnessInfo'] ?? '10K Marathon Athlete',
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      postsCount: data['postsCount'] ?? 0,
      isFollowing: data['isFollowing'] ?? true,
    );
  }
}

/// Model representing a JAIHIND Fitness & Sports Club
class SocialClub {
  final String id;
  final String name;
  final String description;
  final String sportType; // Running, Cycling, Multi-Sport, Trail
  final String location;
  final String? imageUrl;
  final String creatorId;
  final int membersCount;
  bool isJoined;
  final DateTime createdAt;

  SocialClub({
    required this.id,
    required this.name,
    required this.description,
    this.sportType = 'Running',
    this.location = 'Tamil Nadu',
    this.imageUrl,
    this.creatorId = 'admin',
    this.membersCount = 1,
    this.isJoined = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'sportType': sportType,
        'location': location,
        'imageUrl': imageUrl,
        'creatorId': creatorId,
        'membersCount': membersCount,
        'createdAt': FieldValue.serverTimestamp(),
        'createdAtIso': createdAt.toIso8601String(),
      };

  factory SocialClub.fromDoc(DocumentSnapshot doc, {bool isJoined = false}) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    DateTime parsed = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      parsed = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAtIso'] is String) {
      parsed = DateTime.tryParse(data['createdAtIso']) ?? DateTime.now();
    }
    return SocialClub(
      id: doc.id,
      name: data['name'] ?? 'JAIHIND Club',
      description: data['description'] ?? 'Community fitness club',
      sportType: data['sportType'] ?? 'Running',
      location: data['location'] ?? 'Tamil Nadu, India',
      imageUrl: data['imageUrl'],
      creatorId: data['creatorId'] ?? '',
      membersCount: data['membersCount'] ?? 1,
      isJoined: isJoined,
      createdAt: parsed,
    );
  }
}

/// Model representing an In-App Notification (Follow, Like, Comment)
class SocialNotification {
  final String id;
  final String recipientId;
  final String senderId;
  final String senderUsername;
  final String? senderProfileImage;
  final String type; // 'follow', 'like', 'comment'
  final String? postId;
  final String message;
  bool isRead;
  final DateTime createdAt;

  SocialNotification({
    required this.id,
    required this.recipientId,
    required this.senderId,
    required this.senderUsername,
    this.senderProfileImage,
    required this.type,
    this.postId,
    required this.message,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'recipientId': recipientId,
        'senderId': senderId,
        'senderUsername': senderUsername,
        'senderProfileImage': senderProfileImage,
        'type': type,
        'postId': postId,
        'message': message,
        'isRead': isRead,
        'createdAt': FieldValue.serverTimestamp(),
        'createdAtIso': createdAt.toIso8601String(),
      };

  factory SocialNotification.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    DateTime parsedDate = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      parsedDate = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAtIso'] is String) {
      parsedDate = DateTime.tryParse(data['createdAtIso']) ?? DateTime.now();
    }

    return SocialNotification(
      id: doc.id,
      recipientId: data['recipientId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderUsername: data['senderUsername'] ?? 'runner',
      senderProfileImage: data['senderProfileImage'],
      type: data['type'] ?? 'like',
      postId: data['postId'],
      message: data['message'] ?? '',
      isRead: data['isRead'] ?? false,
      createdAt: parsedDate,
    );
  }
}

/// Central Social Networking Service for JAIHIND
/// Handles Follow/Unfollow, Post Creation, Image Uploads to Firebase Storage,
/// Feed Fetching, Likes, Comments, and Real-Time Notifications.
class SocialService extends ChangeNotifier {
  static final SocialService instance = SocialService._internal();
  SocialService._internal();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;

  // Local caching for high-speed responsiveness + persistent follow storage
  final Set<String> _followingUserIds = {};
  final Map<String, SocialUser> _followedUsersMap = {};
  bool _hasLoadedLocalFollows = false;
  final Set<String> _likedPostIds = {};
  final List<SocialPost> _cachedFeedPosts = [];
  final List<SocialNotification> _cachedNotifications = [];

  List<SocialPost> get cachedFeedPosts => List.unmodifiable(_cachedFeedPosts);
  List<SocialNotification> get cachedNotifications => List.unmodifiable(_cachedNotifications);
  int get unreadNotificationCount => _cachedNotifications.where((n) => !n.isRead).length;

  String get _localFollowsStorageKey => 'followed_users_v1_$currentUserId';

  Future<void> _ensureLocalFollowsLoaded() async {
    if (_hasLoadedLocalFollows) return;
    _hasLoadedLocalFollows = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localFollowsStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            final u = SocialUser.fromJson(item);
            if (u.uid.isNotEmpty) {
              u.isFollowing = true;
              _followingUserIds.add(u.uid);
              _followedUsersMap[u.uid] = u;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[SocialService] loadLocalFollows notice: $e');
    }
  }

  Future<void> _saveLocalFollows() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = _followedUsersMap.values.map((u) => u.toJson()).toList();
      await prefs.setString(_localFollowsStorageKey, jsonEncode(payload));
    } catch (e) {
      debugPrint('[SocialService] saveLocalFollows notice: $e');
    }
  }

  List<SocialUser> _buildSeedAthletes() {
    return [
      SocialUser(
        uid: 'athlete_siva_01',
        username: 'siva_runner',
        displayName: 'Siva Prakash',
        bio: '10K Marathon Athlete • Guijiliyamparai',
        location: 'Guijiliyamparai, Dindigul',
        fitnessInfo: '10K Marathon • 4:52 pace',
        followersCount: 520,
        followingCount: 310,
        postsCount: 14,
        isFollowing: _followingUserIds.contains('athlete_siva_01'),
      ),
      SocialUser(
        uid: 'athlete_karthik_02',
        username: 'karthik_pace',
        displayName: 'Karthik Raja',
        bio: 'Trail Running & Cycling Champion 🚴‍♂️',
        location: 'Karur Road, Tamil Nadu',
        fitnessInfo: 'Cycling & Trail Running • 24 km/h',
        followersCount: 890,
        followingCount: 420,
        postsCount: 26,
        isFollowing: _followingUserIds.contains('athlete_karthik_02'),
      ),
      SocialUser(
        uid: 'athlete_priya_03',
        username: 'priya_fitness',
        displayName: 'Priya Dharshini',
        bio: 'Daily 5K Runner • Chennai Road Runners',
        location: 'Chennai / Dindigul',
        fitnessInfo: 'Daily 5K Runner • 5:10 pace',
        followersCount: 640,
        followingCount: 290,
        postsCount: 18,
        isFollowing: _followingUserIds.contains('athlete_priya_03'),
      ),
      SocialUser(
        uid: 'athlete_arun_04',
        username: 'arun_speed',
        displayName: 'Arun Kumar',
        bio: 'Fitness & Stamina Enthusiast • JAIHIND Club',
        location: 'Madurai Highway, Tamil Nadu',
        fitnessInfo: 'Endurance Runner • 5K PB: 22m',
        followersCount: 310,
        followingCount: 180,
        postsCount: 8,
        isFollowing: _followingUserIds.contains('athlete_arun_04'),
      ),
    ];
  }

  /// Current user UID
  String get currentUserId {
    try {
      return _auth.currentUser?.uid ?? 'sarathi_joy4_uid';
    } catch (_) {
      return 'sarathi_joy4_uid';
    }
  }

  /// Current user username
  String get currentUsername {
    return UserService.instance.username;
  }

  /// Current user display name
  String get currentDisplayName {
    return UserService.instance.displayName;
  }

  // ---------------------------------------------------------------------------
  // 1. FOLLOW & UNFOLLOW FRIENDS
  // ---------------------------------------------------------------------------

  /// Checks whether current user is following targetUserId
  Future<bool> isFollowing(String targetUserId) async {
    if (targetUserId == currentUserId) return false;
    await _ensureLocalFollowsLoaded();
    if (_followingUserIds.contains(targetUserId)) return true;

    await AuthService.instance.ensureInitialized();
    try {
      final doc = await _firestore
          .collection('follows')
          .doc('${currentUserId}_$targetUserId')
          .get();
      if (doc.exists) {
        _followingUserIds.add(targetUserId);
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Follow an athlete
  Future<bool> followUser(SocialUser targetUser) async {
    if (targetUser.uid == currentUserId) return false; // Prevent following oneself

    await _ensureLocalFollowsLoaded();
    final bool alreadyFollowing = _followingUserIds.contains(targetUser.uid);

    await AuthService.instance.ensureInitialized();
    final followDocId = '${currentUserId}_${targetUser.uid}';

    final followedSnapshot = SocialUser(
      uid: targetUser.uid,
      username: targetUser.username,
      displayName: targetUser.displayName,
      bio: targetUser.bio,
      profileImageUrl: targetUser.profileImageUrl,
      location: targetUser.location,
      fitnessInfo: targetUser.fitnessInfo,
      followersCount: alreadyFollowing ? targetUser.followersCount : targetUser.followersCount + 1,
      followingCount: targetUser.followingCount,
      postsCount: targetUser.postsCount,
      isFollowing: true,
    );

    try {
      final batch = _firestore.batch();

      // 1. Create follow relationship document with user snapshot metadata
      final followRef = _firestore.collection('follows').doc(followDocId);
      batch.set(followRef, {
        'followerId': currentUserId,
        'followerUsername': currentUsername,
        'followerDisplayName': currentDisplayName,
        'followedId': targetUser.uid,
        'followedUsername': targetUser.username,
        'followedDisplayName': targetUser.displayName,
        'followedLocation': targetUser.location,
        'followedFitnessInfo': targetUser.fitnessInfo,
        'followedProfileImage': targetUser.profileImageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Increment target user followersCount (ignore failure if seed athlete doc doesn't exist)
      final targetUserRef = _firestore.collection('users').doc(targetUser.uid);
      batch.set(
        targetUserRef,
        {'followersCount': FieldValue.increment(1)},
        SetOptions(merge: true),
      );

      // 3. Increment current user followingCount
      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      batch.set(
        currentUserRef,
        {'followingCount': FieldValue.increment(1)},
        SetOptions(merge: true),
      );

      // 4. Create Notification for target user
      final notifRef = _firestore.collection('notifications').doc();
      batch.set(notifRef, {
        'recipientId': targetUser.uid,
        'senderId': currentUserId,
        'senderUsername': currentUsername,
        'senderProfileImage': null,
        'type': 'follow',
        'message': 'started following you',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'createdAtIso': DateTime.now().toIso8601String(),
      });

      await batch.commit();
    } catch (e) {
      debugPrint('[SocialService] followUser notice: $e');
    }

    _followingUserIds.add(targetUser.uid);
    _followedUsersMap[targetUser.uid] = followedSnapshot;
    targetUser.isFollowing = true;
    await _saveLocalFollows();
    if (!alreadyFollowing) {
      UserService.instance.incrementFollowing();
    }
    notifyListeners();
    return true;
  }

  /// Unfollow an athlete
  Future<bool> unfollowUser(String targetUserId) async {
    if (targetUserId == currentUserId) return false;

    await _ensureLocalFollowsLoaded();
    final bool wasFollowing = _followingUserIds.contains(targetUserId) ||
        _followedUsersMap.containsKey(targetUserId);

    await AuthService.instance.ensureInitialized();
    final followDocId = '${currentUserId}_$targetUserId';

    try {
      final batch = _firestore.batch();

      // 1. Delete follow relationship document
      final followRef = _firestore.collection('follows').doc(followDocId);
      batch.delete(followRef);

      // 2. Decrement target user followersCount
      final targetUserRef = _firestore.collection('users').doc(targetUserId);
      batch.set(
        targetUserRef,
        {'followersCount': FieldValue.increment(-1)},
        SetOptions(merge: true),
      );

      // 3. Decrement current user followingCount
      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      batch.set(
        currentUserRef,
        {'followingCount': FieldValue.increment(-1)},
        SetOptions(merge: true),
      );

      await batch.commit();
    } catch (e) {
      debugPrint('[SocialService] unfollowUser notice: $e');
    }

    _followingUserIds.remove(targetUserId);
    _followedUsersMap.remove(targetUserId);
    await _saveLocalFollows();
    if (wasFollowing || UserService.instance.followingCount > _followedUsersMap.length) {
      UserService.instance.decrementFollowing();
    }
    notifyListeners();
    return true;
  }

  /// Returns the full list of athletes currently followed by the signed-in user.
  Future<List<SocialUser>> getFollowingUsers() async {
    await _ensureLocalFollowsLoaded();
    await AuthService.instance.ensureInitialized();

    final seedById = {for (final s in _buildSeedAthletes()) s.uid: s};

    try {
      final snapshot = await _firestore
          .collection('follows')
          .where('followerId', isEqualTo: currentUserId)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final followedId = (data['followedId'] ?? '').toString();
        if (followedId.isEmpty || followedId == currentUserId) continue;

        _followingUserIds.add(followedId);

        // Try loading live profile from `users/{followedId}`
        SocialUser? resolved;
        try {
          final userDoc = await _firestore.collection('users').doc(followedId).get();
          if (userDoc.exists && (userDoc.data()?.containsKey('username') == true)) {
            resolved = SocialUser.fromDoc(userDoc, isFollowing: true);
          }
        } catch (_) {}

        // Fallback 1: match built-in JAIHIND club seed athlete
        if (resolved == null && seedById.containsKey(followedId)) {
          resolved = seedById[followedId]!..isFollowing = true;
        }

        // Fallback 2: snapshot metadata stored on the follow document
        resolved ??= SocialUser(
          uid: followedId,
          username: (data['followedUsername'] ?? followedId).toString(),
          displayName: (data['followedDisplayName'] ?? data['followedUsername'] ?? 'JAIHIND Athlete').toString(),
          profileImageUrl: data['followedProfileImage'] as String?,
          location: (data['followedLocation'] ?? 'Tamil Nadu').toString(),
          fitnessInfo: (data['followedFitnessInfo'] ?? 'JAIHIND Runner').toString(),
          isFollowing: true,
        );

        _followedUsersMap[followedId] = resolved;
      }
      await _saveLocalFollows();
    } catch (e) {
      debugPrint('[SocialService] getFollowingUsers notice: $e');
    }

    // Ensure every ID in _followingUserIds has a displayable profile entry
    for (final uid in _followingUserIds) {
      if (!_followedUsersMap.containsKey(uid)) {
        if (seedById.containsKey(uid)) {
          _followedUsersMap[uid] = seedById[uid]!..isFollowing = true;
        } else {
          _followedUsersMap[uid] = SocialUser(
            uid: uid,
            username: uid,
            displayName: 'JAIHIND Athlete',
            isFollowing: true,
          );
        }
      }
    }

    final list = _followedUsersMap.values.toList();
    // Keep profile counter strictly consistent with the actual list of followed people
    UserService.instance.syncFollowingCount(list.length);
    return list;
  }

  /// Returns the list of athletes who follow the current user.
  Future<List<SocialUser>> getFollowersUsers() async {
    await _ensureLocalFollowsLoaded();
    await AuthService.instance.ensureInitialized();

    final List<SocialUser> followers = [];
    try {
      final snapshot = await _firestore
          .collection('follows')
          .where('followedId', isEqualTo: currentUserId)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final followerId = (data['followerId'] ?? '').toString();
        if (followerId.isEmpty || followerId == currentUserId) continue;

        final isFolBack = await isFollowing(followerId);
        SocialUser? resolved;
        try {
          final userDoc = await _firestore.collection('users').doc(followerId).get();
          if (userDoc.exists && (userDoc.data()?.containsKey('username') == true)) {
            resolved = SocialUser.fromDoc(userDoc, isFollowing: isFolBack);
          }
        } catch (_) {}

        resolved ??= SocialUser(
          uid: followerId,
          username: (data['followerUsername'] ?? followerId).toString(),
          displayName: (data['followerDisplayName'] ?? 'JAIHIND Athlete').toString(),
          isFollowing: isFolBack,
        );

        followers.add(resolved);
      }
      UserService.instance.syncFollowersCount(followers.length);
    } catch (e) {
      debugPrint('[SocialService] getFollowersUsers notice: $e');
    }
    return followers;
  }

  /// Discover & Search Registered Athletes
  Future<List<SocialUser>> searchUsers(String query) async {
    await _ensureLocalFollowsLoaded();
    await AuthService.instance.ensureInitialized();
    final cleanQuery = query.trim().toLowerCase();

    List<SocialUser> results = [];
    try {
      final snapshot = await _firestore
          .collection('users')
          .limit(25)
          .get();

      for (var doc in snapshot.docs) {
        if (doc.id == currentUserId) continue; // Don't show self in search
        final data = doc.data();
        final username = (data['username'] ?? '').toString().toLowerCase();
        final name = (data['fullName'] ?? data['displayName'] ?? '').toString().toLowerCase();

        if (cleanQuery.isEmpty || username.contains(cleanQuery) || name.contains(cleanQuery)) {
          final isFol = await isFollowing(doc.id);
          results.add(SocialUser.fromDoc(doc, isFollowing: isFol));
        }
      }
    } catch (_) {}

    // Fallback seed list of active JAIHIND club athletes if database is initial
    if (results.isEmpty) {
      final seedAthletes = _buildSeedAthletes();

      results = seedAthletes.where((a) {
        if (cleanQuery.isEmpty) return true;
        return a.username.toLowerCase().contains(cleanQuery) ||
            a.displayName.toLowerCase().contains(cleanQuery);
      }).toList();
    }

    return results;
  }

  // ---------------------------------------------------------------------------
  // 2. CREATE POSTS & FIREBASE STORAGE UPLOAD
  // ---------------------------------------------------------------------------

  /// Creates a new social post with photo & workout metrics
  Future<SocialPost?> createPost({
    required File? imageFile,
    required String caption,
    required String activityType,
    double? distanceKm,
    int? durationSeconds,
    int? calories,
    String? pace,
    List<LatLng>? routePoints,
    String locationName = 'Tamil Nadu',
    void Function(double progress)? onProgress,
  }) async {
    await AuthService.instance.ensureInitialized();
    final postId = 'post_${DateTime.now().millisecondsSinceEpoch}';

    String? uploadedImageUrl;

    // 1. Upload photo to Firebase Storage if an image was provided
    if (imageFile != null && await imageFile.exists()) {
      try {
        final storageRef = _storage
            .ref()
            .child('posts')
            .child(currentUserId)
            .child('$postId.jpg');

        final uploadTask = storageRef.putFile(
          imageFile,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        uploadTask.snapshotEvents.listen((event) {
          if (event.totalBytes > 0 && onProgress != null) {
            final progress = event.bytesTransferred / event.totalBytes;
            onProgress(progress);
          }
        });

        final snapshot = await uploadTask;
        uploadedImageUrl = await snapshot.ref.getDownloadURL();
      } catch (e) {
        debugPrint('[SocialService] Image upload notice: $e');
        // Fallback: keep local file path for immediate display
        uploadedImageUrl = imageFile.path;
      }
    }

    // 2. Create SocialPost model
    final post = SocialPost(
      id: postId,
      userId: currentUserId,
      username: currentUsername,
      userDisplayName: currentDisplayName,
      userProfileImage: UserService.instance.profileImagePath,
      imageUrl: uploadedImageUrl,
      caption: caption.trim(),
      activityType: activityType,
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
      calories: calories,
      pace: pace,
      routePoints: routePoints,
      likesCount: 0,
      commentsCount: 0,
      isLiked: false,
      createdAt: DateTime.now(),
      locationName: locationName,
    );

    // 3. Save post to Firestore
    try {
      await _firestore.collection('posts').doc(postId).set(post.toMap());
      // Increment user posts count
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .update({'postsCount': FieldValue.increment(1)});
    } catch (_) {}

    // Note: Community Feed displays ONLY friends' / other athletes' posts.
    // The user's own post is tracked on their Profile tab.
    // Sync with ProfilePost for athlete's personal profile grid
    UserService.instance.addProfilePost(ProfilePost(
      id: postId,
      activityId: postId,
      title: '$activityType Session',
      mode: activityType,
      distanceKm: distanceKm ?? 0.0,
      durationSeconds: durationSeconds ?? 0,
      calories: calories ?? 0,
      avgPace: pace ?? '-:--',
      avgSpeedKmH: (distanceKm != null && durationSeconds != null && durationSeconds > 0)
          ? (distanceKm / (durationSeconds / 3600))
          : 0.0,
      heartRateBpm: 142,
      dateTime: DateTime.now(),
      locationName: locationName,
      gpsRoutePoints: routePoints ?? const [],
      caption: caption,
      imagePath: imageFile?.path,
    ));

    notifyListeners();
    return post;
  }

  /// Edit post caption
  Future<bool> editPost(String postId, String newCaption) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'caption': newCaption.trim(),
      });
      final index = _cachedFeedPosts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final old = _cachedFeedPosts[index];
        _cachedFeedPosts[index] = SocialPost(
          id: old.id,
          userId: old.userId,
          username: old.username,
          userDisplayName: old.userDisplayName,
          userProfileImage: old.userProfileImage,
          imageUrl: old.imageUrl,
          caption: newCaption.trim(),
          activityType: old.activityType,
          distanceKm: old.distanceKm,
          durationSeconds: old.durationSeconds,
          calories: old.calories,
          pace: old.pace,
          likesCount: old.likesCount,
          commentsCount: old.commentsCount,
          isLiked: old.isLiked,
          createdAt: old.createdAt,
          locationName: old.locationName,
        );
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Delete own post
  Future<bool> deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .update({'postsCount': FieldValue.increment(-1)});
    } catch (_) {}

    _cachedFeedPosts.removeWhere((p) => p.id == postId);
    UserService.instance.deleteProfilePost(postId);
    notifyListeners();
    return true;
  }

  // ---------------------------------------------------------------------------
  // 3. HOME SOCIAL FEED
  // ---------------------------------------------------------------------------

  /// Fetches feed posts from followed friends and other athletes.
  /// (User's own posts are excluded from this feed and belong in their own Profile tab).
  Future<List<SocialPost>> getFeedPosts({bool refresh = false}) async {
    if (!refresh && _cachedFeedPosts.isNotEmpty) {
      return _cachedFeedPosts;
    }

    await AuthService.instance.ensureInitialized();
    List<SocialPost> loadedPosts = [];

    try {
      final snapshot = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(30)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final postUserId = data['userId']?.toString() ?? '';
        final postUsername = data['username']?.toString() ?? '';

        // Exclude current user's own posts - Friends Feed displays other athletes only!
        if (postUserId == currentUserId ||
            (currentUsername.isNotEmpty && postUsername.toLowerCase() == currentUsername.toLowerCase())) {
          continue;
        }

        final isLikedByMe = _likedPostIds.contains(doc.id);
        loadedPosts.add(SocialPost.fromDoc(doc, isLikedByMe: isLikedByMe));
      }
    } catch (_) {}

    // Feed starts fresh and clean (empty) until followed friends post!
    _cachedFeedPosts.clear();
    _cachedFeedPosts.addAll(loadedPosts);
    notifyListeners();
    return _cachedFeedPosts;
  }

  // ---------------------------------------------------------------------------
  // 4. LIKES & COMMENTS
  // ---------------------------------------------------------------------------

  /// Toggle like on a post with instant optimistic UI update
  Future<bool> toggleLike(SocialPost post) async {
    final newLikedState = !post.isLiked;
    post.isLiked = newLikedState;
    if (newLikedState) {
      post.likesCount += 1;
      _likedPostIds.add(post.id);
    } else {
      post.likesCount = (post.likesCount > 0) ? post.likesCount - 1 : 0;
      _likedPostIds.remove(post.id);
    }
    notifyListeners();

    try {
      await AuthService.instance.ensureInitialized();
      final likeRef = _firestore
          .collection('posts')
          .doc(post.id)
          .collection('likes')
          .doc(currentUserId);

      if (newLikedState) {
        await likeRef.set({'userId': currentUserId, 'createdAt': FieldValue.serverTimestamp()});
        await _firestore.collection('posts').doc(post.id).update({
          'likesCount': FieldValue.increment(1),
        });

        // Create like notification if not self-like
        if (post.userId != currentUserId) {
          await _firestore.collection('notifications').add({
            'recipientId': post.userId,
            'senderId': currentUserId,
            'senderUsername': currentUsername,
            'senderProfileImage': null,
            'type': 'like',
            'postId': post.id,
            'message': 'liked your ${post.activityType.toLowerCase()} post',
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
            'createdAtIso': DateTime.now().toIso8601String(),
          });
        }
      } else {
        await likeRef.delete();
        await _firestore.collection('posts').doc(post.id).update({
          'likesCount': FieldValue.increment(-1),
        });
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Add comment to post
  Future<SocialComment?> addComment(SocialPost post, String text) async {
    if (text.trim().isEmpty) return null;

    final commentId = 'com_${DateTime.now().millisecondsSinceEpoch}';
    final comment = SocialComment(
      id: commentId,
      postId: post.id,
      userId: currentUserId,
      username: currentUsername,
      userProfileImage: UserService.instance.profileImagePath,
      text: text.trim(),
      createdAt: DateTime.now(),
    );

    post.commentsCount += 1;
    notifyListeners();

    await AuthService.instance.ensureInitialized();
    try {
      await _firestore
          .collection('posts')
          .doc(post.id)
          .collection('comments')
          .doc(commentId)
          .set(comment.toMap());

      await _firestore.collection('posts').doc(post.id).update({
        'commentsCount': FieldValue.increment(1),
      });

      // Notification to post author if not self
      if (post.userId != currentUserId) {
        await _firestore.collection('notifications').add({
          'recipientId': post.userId,
          'senderId': currentUserId,
          'senderUsername': currentUsername,
          'senderProfileImage': null,
          'type': 'comment',
          'postId': post.id,
          'message': 'commented: "${text.trim().length > 30 ? '${text.trim().substring(0, 30)}...' : text.trim()}"',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
          'createdAtIso': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {}

    return comment;
  }

  /// Delete own comment
  Future<bool> deleteComment(String postId, String commentId) async {
    try {
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .delete();

      await _firestore.collection('posts').doc(postId).update({
        'commentsCount': FieldValue.increment(-1),
      });

      final postIndex = _cachedFeedPosts.indexWhere((p) => p.id == postId);
      if (postIndex != -1 && _cachedFeedPosts[postIndex].commentsCount > 0) {
        _cachedFeedPosts[postIndex].commentsCount -= 1;
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Fetch comments for a post
  Future<List<SocialComment>> getComments(String postId) async {
    await AuthService.instance.ensureInitialized();
    List<SocialComment> comments = [];
    try {
      final snapshot = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .orderBy('createdAt', descending: false)
          .get();

      for (var doc in snapshot.docs) {
        comments.add(SocialComment.fromDoc(doc));
      }
    } catch (_) {}
    return comments;
  }

  // ---------------------------------------------------------------------------
  // 5. NOTIFICATIONS
  // ---------------------------------------------------------------------------

  /// Fetch notifications for current user
  Future<List<SocialNotification>> getNotifications() async {
    await AuthService.instance.ensureInitialized();
    List<SocialNotification> notifications = [];

    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .limit(40)
          .get();

      for (var doc in snapshot.docs) {
        notifications.add(SocialNotification.fromDoc(doc));
      }
    } catch (_) {}

    if (notifications.isEmpty) {
      notifications = [
        SocialNotification(
          id: 'seed_notif_01',
          recipientId: currentUserId,
          senderId: 'athlete_siva_01',
          senderUsername: 'siva_runner',
          type: 'follow',
          message: 'started following you',
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
        ),
        SocialNotification(
          id: 'seed_notif_02',
          recipientId: currentUserId,
          senderId: 'athlete_karthik_02',
          senderUsername: 'karthik_pace',
          type: 'like',
          message: 'liked your running post',
          isRead: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        ),
      ];
    }

    _cachedNotifications.clear();
    _cachedNotifications.addAll(notifications);
    notifyListeners();
    return _cachedNotifications;
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    final index = _cachedNotifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _cachedNotifications[index].isRead = true;
      notifyListeners();
    }

    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (_) {}
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    for (var n in _cachedNotifications) {
      n.isRead = true;
    }
    notifyListeners();

    try {
      final unread = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();
      final batch = _firestore.batch();
      for (var doc in unread.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (_) {}
  }

  /// Get posts by a specific user for UserProfileScreen
  Future<List<SocialPost>> getUserPosts(String userId) async {
    await AuthService.instance.ensureInitialized();
    List<SocialPost> userPosts = [];

    try {
      final snapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(30)
          .get();

      for (var doc in snapshot.docs) {
        final isLikedByMe = _likedPostIds.contains(doc.id);
        userPosts.add(SocialPost.fromDoc(doc, isLikedByMe: isLikedByMe));
      }
    } catch (_) {}

    if (userPosts.isEmpty) {
      userPosts = _cachedFeedPosts.where((p) => p.userId == userId).toList();
    }
    return userPosts;
  }

  // ---------------------------------------------------------------------------
  // 6. CLUBS & COMMUNITIES
  // ---------------------------------------------------------------------------
  final Set<String> _joinedClubIds = {'club_jaihind_01'};
  final List<SocialClub> _cachedClubs = [];

  List<SocialClub> get cachedClubs => List.unmodifiable(_cachedClubs);

  /// Check whether current user is a member of a club
  Future<bool> isMemberOfClub(String clubId) async {
    if (_joinedClubIds.contains(clubId)) return true;
    try {
      final doc = await _firestore
          .collection('clubs')
          .doc(clubId)
          .collection('members')
          .doc(currentUserId)
          .get();
      if (doc.exists) {
        _joinedClubIds.add(clubId);
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Search & discover JAIHIND sports clubs
  Future<List<SocialClub>> searchClubs(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    List<SocialClub> results = [];

    try {
      await AuthService.instance.ensureInitialized();
      final snapshot = await _firestore.collection('clubs').limit(25).get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final name = (data['name'] ?? '').toString().toLowerCase();
        final desc = (data['description'] ?? '').toString().toLowerCase();
        final sport = (data['sportType'] ?? '').toString().toLowerCase();

        if (cleanQuery.isEmpty ||
            name.contains(cleanQuery) ||
            desc.contains(cleanQuery) ||
            sport.contains(cleanQuery)) {
          final isMem = await isMemberOfClub(doc.id);
          results.add(SocialClub.fromDoc(doc, isJoined: isMem));
        }
      }
    } catch (_) {}

    // Fallback seed clubs
    if (results.isEmpty) {
      final seedClubs = [
        SocialClub(
          id: 'club_jaihind_01',
          name: 'JAIHIND Runners Club Guijiliyamparai',
          description:
              'Official athletic club for road running, morning intervals, and stamina training across Guijiliyamparai.',
          sportType: 'Running',
          location: 'Guijiliyamparai, Dindigul',
          membersCount: 142,
          isJoined: _joinedClubIds.contains('club_jaihind_01'),
          createdAt: DateTime(2024, 1, 1),
        ),
        SocialClub(
          id: 'club_tn_marathoners_02',
          name: 'Tamil Nadu Marathon & Ultra Club',
          description:
              'Dedicated long-distance marathoners preparing for 10K, 21K Half Marathon and 42K Full Marathon events.',
          sportType: 'Running',
          location: 'Tamil Nadu, India',
          membersCount: 389,
          isJoined: _joinedClubIds.contains('club_tn_marathoners_02'),
          createdAt: DateTime(2024, 3, 15),
        ),
        SocialClub(
          id: 'club_dindigul_cyclists_03',
          name: 'Dindigul Peloton Cycling Squad',
          description:
              'Weekend endurance rides, hill climbs up Palani foothills, and highway time trials.',
          sportType: 'Cycling',
          location: 'Dindigul & Karur Route',
          membersCount: 88,
          isJoined: _joinedClubIds.contains('club_dindigul_cyclists_03'),
          createdAt: DateTime(2024, 5, 20),
        ),
        SocialClub(
          id: 'club_cross_training_04',
          name: 'JAIHIND Multi-Sport & Trail Squad',
          description:
              'Combined running, walking, trail trekking and strength conditioning for all athlete levels.',
          sportType: 'Multi-Sport',
          location: 'Tamil Nadu Trail Routes',
          membersCount: 64,
          isJoined: _joinedClubIds.contains('club_cross_training_04'),
          createdAt: DateTime(2024, 7, 10),
        ),
      ];

      results = seedClubs.where((c) {
        if (cleanQuery.isEmpty) return true;
        return c.name.toLowerCase().contains(cleanQuery) ||
            c.description.toLowerCase().contains(cleanQuery) ||
            c.sportType.toLowerCase().contains(cleanQuery);
      }).toList();
    }

    _cachedClubs.clear();
    _cachedClubs.addAll(results);
    notifyListeners();
    return _cachedClubs;
  }

  /// Join a JAIHIND Club
  Future<bool> joinClub(SocialClub club) async {
    _joinedClubIds.add(club.id);
    club.isJoined = true;
    notifyListeners();

    try {
      await AuthService.instance.ensureInitialized();
      await _firestore
          .collection('clubs')
          .doc(club.id)
          .collection('members')
          .doc(currentUserId)
          .set({
        'userId': currentUserId,
        'username': currentUsername,
        'joinedAt': FieldValue.serverTimestamp(),
      });
      await _firestore.collection('clubs').doc(club.id).update({
        'membersCount': FieldValue.increment(1),
      });
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Leave a JAIHIND Club
  Future<bool> leaveClub(String clubId, [SocialClub? club]) async {
    _joinedClubIds.remove(clubId);
    if (club != null) {
      club.isJoined = false;
    }
    final idx = _cachedClubs.indexWhere((c) => c.id == clubId);
    if (idx != -1) {
      _cachedClubs[idx].isJoined = false;
    }
    notifyListeners();

    try {
      await AuthService.instance.ensureInitialized();
      await _firestore
          .collection('clubs')
          .doc(clubId)
          .collection('members')
          .doc(currentUserId)
          .delete();
      await _firestore.collection('clubs').doc(clubId).update({
        'membersCount': FieldValue.increment(-1),
      });
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Create a new JAIHIND Club
  Future<SocialClub?> createClub({
    required String name,
    required String description,
    required String sportType,
    required String location,
  }) async {
    final clubId = 'club_${DateTime.now().millisecondsSinceEpoch}';
    final club = SocialClub(
      id: clubId,
      name: name.trim(),
      description: description.trim(),
      sportType: sportType,
      location: location.trim(),
      creatorId: currentUserId,
      membersCount: 1,
      isJoined: true,
      createdAt: DateTime.now(),
    );

    _joinedClubIds.add(clubId);
    _cachedClubs.insert(0, club);
    notifyListeners();

    try {
      await AuthService.instance.ensureInitialized();
      await _firestore.collection('clubs').doc(clubId).set(club.toMap());
      await _firestore
          .collection('clubs')
          .doc(clubId)
          .collection('members')
          .doc(currentUserId)
          .set({
        'userId': currentUserId,
        'username': currentUsername,
        'role': 'founder',
        'joinedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    return club;
  }

  // ---------------------------------------------------------------------------
  // 7. QR CODE RESOLVER
  // ---------------------------------------------------------------------------

  /// Parse and resolve an athlete profile from scanned QR code data
  Future<SocialUser?> getUserByQrCode(String qrData) async {
    final clean = qrData.trim();
    if (clean.isEmpty) return null;

    String? extractedUid;
    String? extractedUsername;

    // Check custom scheme: jaihind://user/{uid}?username={user}
    if (clean.startsWith('jaihind://user/')) {
      final uri = Uri.tryParse(clean);
      if (uri != null) {
        extractedUid = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
        extractedUsername = uri.queryParameters['username'];
      }
    } else if (clean.startsWith('https://jaihind-runner.web.app/@')) {
      extractedUsername = clean.split('@').last.trim();
    } else if (clean.contains('@')) {
      extractedUsername = clean.replaceAll('@', '').trim();
    } else {
      extractedUid = clean;
    }

    // Try finding user in Firestore
    try {
      await AuthService.instance.ensureInitialized();
      if (extractedUid != null && extractedUid.isNotEmpty) {
        final doc = await _firestore.collection('users').doc(extractedUid).get();
        if (doc.exists) {
          final isFol = await isFollowing(doc.id);
          return SocialUser.fromDoc(doc, isFollowing: isFol);
        }
      }
      if (extractedUsername != null && extractedUsername.isNotEmpty) {
        final querySnap = await _firestore
            .collection('users')
            .where('username', isEqualTo: extractedUsername.toLowerCase())
            .limit(1)
            .get();
        if (querySnap.docs.isNotEmpty) {
          final doc = querySnap.docs.first;
          final isFol = await isFollowing(doc.id);
          return SocialUser.fromDoc(doc, isFollowing: isFol);
        }
      }
    } catch (_) {}

    // Check seed athletes
    final seedUsers = await searchUsers(extractedUsername ?? extractedUid ?? '');
    if (seedUsers.isNotEmpty) {
      return seedUsers.first;
    }

    return null;
  }
}
