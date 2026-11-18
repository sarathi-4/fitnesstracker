import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkoutActivity {
  final String id;
  final String title;
  final String mode; // Running, Cycling, Walking, Gym
  final double distanceKm;
  final int durationSeconds;
  final int calories;
  final String avgPace;
  final DateTime dateTime;
  final String locationName;
  final String? feeling;
  final String? notes;
  final int heartRateBpm;
  final double avgSpeedKmH;
  final List<LatLng> gpsRoutePoints;
  final String? imagePath;

  WorkoutActivity({
    required this.id,
    required this.title,
    required this.mode,
    required this.distanceKm,
    required this.durationSeconds,
    required this.calories,
    required this.avgPace,
    required this.dateTime,
    this.locationName = 'Outdoor',
    this.feeling,
    this.notes,
    this.heartRateBpm = 142,
    this.avgSpeedKmH = 0.0,
    this.gpsRoutePoints = const [],
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'mode': mode,
    'distanceKm': distanceKm,
    'durationSeconds': durationSeconds,
    'calories': calories,
    'avgPace': avgPace,
    'dateTime': dateTime.toIso8601String(),
    'locationName': locationName,
    'feeling': feeling,
    'notes': notes,
    'heartRateBpm': heartRateBpm,
    'avgSpeedKmH': avgSpeedKmH,
    'gpsRoutePoints': gpsRoutePoints
        .map((p) => {'lat': p.latitude, 'lng': p.longitude})
        .toList(),
    'imagePath': imagePath,
  };

  factory WorkoutActivity.fromJson(Map<String, dynamic> json) {
    List<LatLng> points = [];
    if (json['gpsRoutePoints'] != null) {
      try {
        final rawList = json['gpsRoutePoints'] as List;
        for (final item in rawList) {
          if (item is Map && item['lat'] != null && item['lng'] != null) {
            points.add(LatLng(
              (item['lat'] as num).toDouble(),
              (item['lng'] as num).toDouble(),
            ));
          }
        }
      } catch (_) {}
    }

    return WorkoutActivity(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Workout',
      mode: json['mode'] ?? 'Running',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: json['durationSeconds'] ?? 0,
      calories: json['calories'] ?? 0,
      avgPace: json['avgPace'] ?? '-:--',
      dateTime: DateTime.tryParse(json['dateTime'] ?? '') ?? DateTime.now(),
      locationName: json['locationName'] ?? 'Outdoor',
      feeling: json['feeling'],
      notes: json['notes'],
      heartRateBpm: json['heartRateBpm'] ?? 142,
      avgSpeedKmH: (json['avgSpeedKmH'] as num?)?.toDouble() ?? 0.0,
      gpsRoutePoints: points,
      imagePath: json['imagePath'],
    );
  }
}

/// Instagram-style Workout Post published to Athlete Profile
class ProfilePost {
  final String id;
  final String activityId;
  final String title;
  final String mode; // Running, Cycling, Walking
  final double distanceKm;
  final int durationSeconds;
  final int calories;
  final String avgPace;
  final double avgSpeedKmH;
  final int heartRateBpm;
  final DateTime dateTime;
  final String locationName;
  final List<LatLng> gpsRoutePoints;
  final String caption;
  final String? imagePath;
  int likes;
  bool isLiked;
  final List<String> comments;

  ProfilePost({
    required this.id,
    required this.activityId,
    required this.title,
    required this.mode,
    required this.distanceKm,
    required this.durationSeconds,
    required this.calories,
    required this.avgPace,
    required this.avgSpeedKmH,
    required this.heartRateBpm,
    required this.dateTime,
    required this.locationName,
    required this.gpsRoutePoints,
    this.caption = '',
    this.imagePath,
    this.likes = 0,
    this.isLiked = false,
    this.comments = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'activityId': activityId,
    'title': title,
    'mode': mode,
    'distanceKm': distanceKm,
    'durationSeconds': durationSeconds,
    'calories': calories,
    'avgPace': avgPace,
    'avgSpeedKmH': avgSpeedKmH,
    'heartRateBpm': heartRateBpm,
    'dateTime': dateTime.toIso8601String(),
    'locationName': locationName,
    'gpsRoutePoints': gpsRoutePoints
        .map((p) => {'lat': p.latitude, 'lng': p.longitude})
        .toList(),
    'caption': caption,
    'imagePath': imagePath,
    'likes': likes,
    'isLiked': isLiked,
    'comments': comments,
  };

  factory ProfilePost.fromJson(Map<String, dynamic> json) {
    List<LatLng> points = [];
    if (json['gpsRoutePoints'] != null) {
      try {
        final rawList = json['gpsRoutePoints'] as List;
        for (final item in rawList) {
          if (item is Map && item['lat'] != null && item['lng'] != null) {
            points.add(LatLng(
              (item['lat'] as num).toDouble(),
              (item['lng'] as num).toDouble(),
            ));
          }
        }
      } catch (_) {}
    }

    return ProfilePost(
      id: json['id'] ?? '',
      activityId: json['activityId'] ?? '',
      title: json['title'] ?? 'Running Post',
      mode: json['mode'] ?? 'Running',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: json['durationSeconds'] ?? 0,
      calories: json['calories'] ?? 0,
      avgPace: json['avgPace'] ?? '-:--',
      avgSpeedKmH: (json['avgSpeedKmH'] as num?)?.toDouble() ?? 0.0,
      heartRateBpm: json['heartRateBpm'] ?? 142,
      dateTime: DateTime.tryParse(json['dateTime'] ?? '') ?? DateTime.now(),
      locationName: json['locationName'] ?? 'Outdoor',
      gpsRoutePoints: points,
      caption: json['caption'] ?? '',
      imagePath: json['imagePath'],
      likes: json['likes'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      comments: (json['comments'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class UserService extends ChangeNotifier {
  static final UserService instance = UserService._internal();
  UserService._internal();

  bool _isLoggedIn = false;
  String _name = 'Sarathi (JAIHIND Runner)';
  String _email = 'sarathi@gmail.com';
  String _password = 'password123';
  String _dateOfJoining = 'Nov 1, 2024';
  String? _profileImagePath;
  // ignore: prefer_final_fields
  int _streakWeeks = 0;

  // Instagram Profile Fields (Fresh Profile Page)
  String _username = 'sarathi_joy4';
  String _displayName = 'Sarathi (JAIHIND Runner)';
  String _bio = '';
  String _website = '';
  int _followersCount = 0;
  int _followingCount = 0;

  // List of completed workouts saved to profile
  final List<WorkoutActivity> _savedActivities = [];

  // Completed streak dates manually or dynamically logged
  final Set<String> _manualStreakDates = {};

  // List of Instagram-style published workout posts (Strictly from completed workouts)
  final List<ProfilePost> _profilePosts = [];

  bool get isLoggedIn => _isLoggedIn;
  String get name => _displayName.isNotEmpty ? _displayName : _name;
  String get email => _email;
  String get password => _password;
  String get dateOfJoining => _dateOfJoining;
  String? get profileImagePath => _profileImagePath;
  int get streakWeeks => _streakWeeks;
  List<WorkoutActivity> get savedActivities => List.unmodifiable(_savedActivities);

  // Instagram Getters
  String get username => _username;
  String get displayName => _displayName;
  String get bio => _bio;
  String get website => _website;
  int get followersCount => _followersCount;
  int get followingCount => _followingCount;
  int get postsCount => _profilePosts.length;
  List<ProfilePost> get profilePosts => List.unmodifiable(_profilePosts);

  double get totalDistanceKm => _savedActivities.fold(0.0, (sum, a) => sum + a.distanceKm);
  int get totalCalories => _savedActivities.fold(0, (sum, a) => sum + a.calories);
  int get totalWorkouts => _savedActivities.length;

  // Streak Getters & Helpers
  Set<String> get manualStreakDates => Set.unmodifiable(_manualStreakDates);

  /// Check whether a workout was completed on a given date
  bool hasWorkoutOnDate(DateTime date) {
    final y = date.year;
    final m = date.month;
    final d = date.day;
    for (final a in _savedActivities) {
      if (a.dateTime.year == y && a.dateTime.month == m && a.dateTime.day == d) {
        return true;
      }
    }
    final key = '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
    return _manualStreakDates.contains(key);
  }

  /// Returns all day numbers (1..31) in the given month/year that have completed runs/workouts
  Set<int> getCompletedDaysForMonth(int year, int month) {
    final days = <int>{};
    for (final a in _savedActivities) {
      if (a.dateTime.year == year && a.dateTime.month == month) {
        days.add(a.dateTime.day);
      }
    }
    for (final dateStr in _manualStreakDates) {
      try {
        final d = DateTime.parse(dateStr);
        if (d.year == year && d.month == month) {
          days.add(d.day);
        }
      } catch (_) {}
    }
    return days;
  }

  /// Toggle or mark a date as a completed streak day
  void toggleStreakDate(DateTime date) {
    final key = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (_manualStreakDates.contains(key)) {
      _manualStreakDates.remove(key);
    } else {
      _manualStreakDates.add(key);
    }
    _saveSession();
    notifyListeners();
  }

  /// Calculate real active consecutive days streak up to today (or yesterday)
  int get activeStreakDays {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Check if today has a workout
    final hasToday = hasWorkoutOnDate(today);
    
    DateTime checkDate = hasToday ? today : today.subtract(const Duration(days: 1));
    int streak = 0;
    while (hasWorkoutOnDate(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Calculate the best streak ever
  int get bestStreakDays {
    final current = activeStreakDays;
    final Set<DateTime> dates = {};
    for (final a in _savedActivities) {
      dates.add(DateTime(a.dateTime.year, a.dateTime.month, a.dateTime.day));
    }
    for (final str in _manualStreakDates) {
      try {
        final d = DateTime.parse(str);
        dates.add(DateTime(d.year, d.month, d.day));
      } catch (_) {}
    }
    if (dates.isEmpty) return current;
    final sorted = dates.toList()..sort();
    int maxStreak = 1;
    int curStreak = 1;
    for (int i = 1; i < sorted.length; i++) {
      final diff = sorted[i].difference(sorted[i - 1]).inDays;
      if (diff == 1) {
        curStreak++;
        if (curStreak > maxStreak) maxStreak = curStreak;
      } else if (diff > 1) {
        curStreak = 1;
      }
    }
    return maxStreak > current ? maxStreak : current;
  }

  /// Calculate consistency % for a given month
  int getMonthConsistency(int year, int month) {
    final days = getCompletedDaysForMonth(year, month);
    final now = DateTime.now();
    int totalDays = DateUtils.getDaysInMonth(year, month);
    if (year == now.year && month == now.month) {
      totalDays = now.day;
    }
    if (totalDays <= 0) return 0;
    final pct = (days.length / totalDays * 100).round();
    return pct.clamp(0, 100);
  }

  // Add a newly completed workout and persist
  void addActivity(WorkoutActivity activity) {
    _savedActivities.insert(0, activity); // Newest on top
    _saveSession();
    notifyListeners();
  }

  // Delete a saved workout
  void deleteActivity(String id) {
    _savedActivities.removeWhere((a) => a.id == id);
    _saveSession();
    notifyListeners();
  }

  // Publish a workout as an Instagram Profile Post (Strictly from completed running/workouts)
  void addProfilePost(ProfilePost post) {
    // Avoid duplicate post of same activity or id
    _profilePosts.removeWhere((p) => (p.id == post.id) || (p.activityId == post.activityId && post.activityId.isNotEmpty));
    _profilePosts.insert(0, post); // Newest on top
    _saveSession();
    notifyListeners();
  }

  // Toggle Like on a Post (Interactive instant update)
  void toggleLikePost(String postId) {
    final index = _profilePosts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _profilePosts[index];
      post.isLiked = !post.isLiked;
      if (post.isLiked) {
        post.likes += 1;
      } else {
        post.likes = (post.likes > 0) ? post.likes - 1 : 0;
      }
      _saveSession();
      notifyListeners();
    }
  }

  // Add Comment to Post
  void addCommentToPost(String postId, String commentText) {
    final index = _profilePosts.indexWhere((p) => p.id == postId);
    if (index != -1 && commentText.trim().isNotEmpty) {
      final post = _profilePosts[index];
      final updatedComments = List<String>.from(post.comments)..add(commentText.trim());
      final updatedPost = ProfilePost(
        id: post.id,
        activityId: post.activityId,
        title: post.title,
        mode: post.mode,
        distanceKm: post.distanceKm,
        durationSeconds: post.durationSeconds,
        calories: post.calories,
        avgPace: post.avgPace,
        avgSpeedKmH: post.avgSpeedKmH,
        heartRateBpm: post.heartRateBpm,
        dateTime: post.dateTime,
        locationName: post.locationName,
        gpsRoutePoints: post.gpsRoutePoints,
        caption: post.caption,
        imagePath: post.imagePath,
        likes: post.likes,
        isLiked: post.isLiked,
        comments: updatedComments,
      );
      _profilePosts[index] = updatedPost;
      _saveSession();
      notifyListeners();
    }
  }

  // Delete Post
  void deleteProfilePost(String postId) {
    _profilePosts.removeWhere((p) => p.id == postId);
    _saveSession();
    notifyListeners();
  }

  // Update Instagram Profile details (Edit Profile Functionality)
  void updateInstagramProfile({
    required String displayName,
    required String username,
    required String bio,
    required String website,
  }) {
    _displayName = displayName.trim();
    _name = _displayName;
    _username = username.trim().replaceAll(' ', '_');
    _bio = bio.trim();
    _website = website.trim();
    _saveSession();
    notifyListeners();
  }

  // Follow & Following Counter Management
  void incrementFollowing() {
    _followingCount++;
    _saveSession();
    notifyListeners();
  }

  void decrementFollowing() {
    if (_followingCount > 0) {
      _followingCount--;
      _saveSession();
      notifyListeners();
    }
  }

  void incrementFollowers() {
    _followersCount++;
    _saveSession();
    notifyListeners();
  }

  void decrementFollowers() {
    if (_followersCount > 0) {
      _followersCount--;
      _saveSession();
      notifyListeners();
    }
  }

  void syncFollowingCount(int count) {
    final safeCount = count < 0 ? 0 : count;
    if (_followingCount != safeCount) {
      _followingCount = safeCount;
      _saveSession();
      notifyListeners();
    }
  }

  void syncFollowersCount(int count) {
    final safeCount = count < 0 ? 0 : count;
    if (_followersCount != safeCount) {
      _followersCount = safeCount;
      _saveSession();
      notifyListeners();
    }
  }

  // Initialize session on app startup
  Future<void> initSession() async {
    // 1. Try SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final loggedIn = prefs.getBool('isLoggedIn') ?? false;
      if (loggedIn) {
        _isLoggedIn = true;
        _name = prefs.getString('userName') ?? _name;
        _email = prefs.getString('userEmail') ?? _email;
        _password = prefs.getString('userPassword') ?? _password;
        _dateOfJoining = prefs.getString('userDateOfJoining') ?? _dateOfJoining;
        _profileImagePath = prefs.getString('userProfileImage');
        _username = prefs.getString('userInstagramUsername') ?? _username;
        _displayName = prefs.getString('userInstagramDisplayName') ?? _displayName;
        _bio = prefs.getString('userInstagramBio') ?? _bio;
        _website = prefs.getString('userInstagramWebsite') ?? _website;
        _followersCount = prefs.getInt('userFollowersCount') ?? _followersCount;
        _followingCount = prefs.getInt('userFollowingCount') ?? _followingCount;

        if (_followersCount == 444) _followersCount = 0;
        if (_followingCount == 454) _followingCount = 0;
        if (_bio.contains('kabaddi....4')) _bio = '';
        if (_website.contains('sarathis.netlify.app')) _website = '';

        // If a local user was registered with this email, prioritize their actual chosen username & name!
        final localUsersJson = prefs.getString('local_registered_users');
        if (localUsersJson != null && _email.isNotEmpty) {
          try {
            final map = jsonDecode(localUsersJson) as Map<String, dynamic>;
            if (map.containsKey(_email.toLowerCase())) {
              final saved = map[_email.toLowerCase()] as Map<String, dynamic>;
              if (saved['username'] != null && (saved['username'] as String).isNotEmpty) {
                _username = saved['username'] as String;
              }
              if (saved['fullName'] != null && (saved['fullName'] as String).isNotEmpty) {
                _displayName = saved['fullName'] as String;
                _name = _displayName;
              }
            }
          } catch (_) {}
        }

        final savedJson = prefs.getString('savedActivities');
        if (savedJson != null) {
          final list = jsonDecode(savedJson) as List;
          _savedActivities.clear();
          _savedActivities.addAll(list.map((e) => WorkoutActivity.fromJson(e as Map<String, dynamic>)));
        }

        final postsJson = prefs.getString('userProfilePosts');
        if (postsJson != null) {
          final list = jsonDecode(postsJson) as List;
          _profilePosts.clear();
          _profilePosts.addAll(list.map((e) => ProfilePost.fromJson(e as Map<String, dynamic>)));
        }

        final streakDates = prefs.getStringList('manualStreakDates');
        if (streakDates != null) {
          _manualStreakDates.clear();
          _manualStreakDates.addAll(streakDates);
        }

        notifyListeners();
        return;
      }
    } catch (_) {}

    // 2. Fallback to local session file
    try {
      final file = await _getSessionFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        if (data['isLoggedIn'] == true) {
          _isLoggedIn = true;
          _name = data['name'] ?? _name;
          _email = data['email'] ?? _email;
          _password = data['password'] ?? _password;
          _dateOfJoining = data['dateOfJoining'] ?? _dateOfJoining;
          _profileImagePath = data['profileImagePath'];
          _username = data['username'] ?? _username;
          _displayName = data['displayName'] ?? _displayName;
          _bio = data['bio'] ?? _bio;
          _website = data['website'] ?? _website;
          _followersCount = data['followersCount'] ?? _followersCount;
          _followingCount = data['followingCount'] ?? _followingCount;

          if (_followersCount == 444) _followersCount = 0;
          if (_followingCount == 454) _followingCount = 0;
          if (_bio.contains('kabaddi....4')) _bio = '';
          if (_website.contains('sarathis.netlify.app')) _website = '';

          try {
            final prefs = await SharedPreferences.getInstance();
            final localUsersJson = prefs.getString('local_registered_users');
            if (localUsersJson != null && _email.isNotEmpty) {
              final map = jsonDecode(localUsersJson) as Map<String, dynamic>;
              if (map.containsKey(_email.toLowerCase())) {
                final saved = map[_email.toLowerCase()] as Map<String, dynamic>;
                if (saved['username'] != null && (saved['username'] as String).isNotEmpty) {
                  _username = saved['username'] as String;
                }
                if (saved['fullName'] != null && (saved['fullName'] as String).isNotEmpty) {
                  _displayName = saved['fullName'] as String;
                  _name = _displayName;
                }
              }
            }
          } catch (_) {}

          if (data['savedActivities'] != null) {
            final list = data['savedActivities'] as List;
            _savedActivities.clear();
            _savedActivities.addAll(list.map((e) => WorkoutActivity.fromJson(e as Map<String, dynamic>)));
          }
          if (data['profilePosts'] != null) {
            final list = data['profilePosts'] as List;
            _profilePosts.clear();
            _profilePosts.addAll(list.map((e) => ProfilePost.fromJson(e as Map<String, dynamic>)));
          }
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  // Save session across both SharedPreferences & local file
  Future<void> _saveSession() async {
    // 1. Save to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', _isLoggedIn);
      await prefs.setString('userName', _name);
      await prefs.setString('userEmail', _email);
      await prefs.setString('userPassword', _password);
      await prefs.setString('userDateOfJoining', _dateOfJoining);
      await prefs.setString('userInstagramUsername', _username);
      await prefs.setString('userInstagramDisplayName', _displayName);
      await prefs.setString('userInstagramBio', _bio);
      await prefs.setString('userInstagramWebsite', _website);
      await prefs.setInt('userFollowersCount', _followersCount);
      await prefs.setInt('userFollowingCount', _followingCount);

      if (_profileImagePath != null) {
        await prefs.setString('userProfileImage', _profileImagePath!);
      } else {
        await prefs.remove('userProfileImage');
      }
      final activitiesJson = jsonEncode(_savedActivities.map((a) => a.toJson()).toList());
      await prefs.setString('savedActivities', activitiesJson);

      final postsJson = jsonEncode(_profilePosts.map((p) => p.toJson()).toList());
      await prefs.setString('userProfilePosts', postsJson);

      await prefs.setStringList('manualStreakDates', _manualStreakDates.toList());
    } catch (_) {}

    // 2. Save to local fallback file
    try {
      final file = await _getSessionFile();
      final data = {
        'isLoggedIn': _isLoggedIn,
        'name': _name,
        'email': _email,
        'password': _password,
        'dateOfJoining': _dateOfJoining,
        'profileImagePath': _profileImagePath,
        'username': _username,
        'displayName': _displayName,
        'bio': _bio,
        'website': _website,
        'followersCount': _followersCount,
        'followingCount': _followingCount,
        'savedActivities': _savedActivities.map((a) => a.toJson()).toList(),
        'profilePosts': _profilePosts.map((p) => p.toJson()).toList(),
      };
      await file.writeAsString(jsonEncode(data));
    } catch (_) {}
  }

  // File location resolver
  Future<File> _getSessionFile() async {
    String dirPath = Directory.systemTemp.path;

    // Standard Android App internal storage path
    if (Platform.isAndroid) {
      final androidDir = Directory('/data/data/com.inpand.jaihindrunnerclub/files');
      final legacyDir = Directory('/data/data/com.example.jaihind/files');
      if (await androidDir.exists()) {
        dirPath = androidDir.path;
      } else if (await legacyDir.exists()) {
        dirPath = legacyDir.path;
      }
    } else if (Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        final linuxDir = Directory('$home/.jaihind');
        if (!await linuxDir.exists()) {
          await linuxDir.create(recursive: true);
        }
        dirPath = linuxDir.path;
      }
    }

    return File('$dirPath/session.json');
  }

  // Register new user -> Persists and logs in
  void registerUser({
    required String name,
    required String email,
    required String password,
    required String dateOfJoining,
  }) {
    _isLoggedIn = true;
    _name = name.trim();
    _displayName = _name;
    _email = email.trim();
    _password = password;
    _dateOfJoining = dateOfJoining;
    _profileImagePath = null;
    _saveSession();
    notifyListeners();
  }

  // Login existing user -> Persists and logs in
  void loginUser({
    required String email,
    required String password,
  }) {
    _isLoggedIn = true;
    _email = email.trim();
    _password = password;
    if (_displayName.isEmpty || _displayName == 'User') {
      _displayName = email.split('@').first;
      _name = _displayName;
    }
    _saveSession();
    notifyListeners();
  }

  // Update profile details
  void updateProfile({
    required String name,
    required String email,
    required String password,
    String? dateOfJoining,
    String? username,
  }) {
    _isLoggedIn = true;
    _name = name.trim();
    _displayName = _name;
    _email = email.trim();
    _password = password;
    if (dateOfJoining != null && dateOfJoining.isNotEmpty) {
      _dateOfJoining = dateOfJoining;
    }
    if (username != null && username.trim().isNotEmpty) {
      _username = username.trim().replaceAll(' ', '_');
    }
    _saveSession();
    notifyListeners();
  }

  // Update profile image
  void updateImage(String? imagePath) {
    _profileImagePath = imagePath;
    _saveSession();
    notifyListeners();
  }

  // Log Out -> Clears session
  Future<void> logOut() async {
    _isLoggedIn = false;
    await _saveSession();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
    } catch (_) {}

    try {
      final file = await _getSessionFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}

    notifyListeners();
  }
}
