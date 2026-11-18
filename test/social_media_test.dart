import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jaihind/core/services/social_service.dart';
import 'package:jaihind/core/services/user_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JAIHIND Social Networking & Instagram Features Test Suite', () {
    test('1. SocialPost model handles metrics and serialization properly', () {
      final post = SocialPost(
        id: 'post_1001',
        userId: 'sarathi_joy4_uid',
        username: 'sarathi_joy4',
        userDisplayName: 'Joy... 🧡👀',
        caption: '10K Morning Sprint in Guijiliyamparai 🏃‍♂️⚡',
        activityType: 'Running',
        distanceKm: 10.25,
        durationSeconds: 3120, // 52m 00s
        calories: 680,
        pace: '5\'04"/km',
        likesCount: 14,
        commentsCount: 3,
        createdAt: DateTime(2026, 11, 17, 6, 30),
      );

      expect(post.id, 'post_1001');
      expect(post.username, 'sarathi_joy4');
      expect(post.distanceKm, 10.25);
      expect(post.durationSeconds, 3120);
      expect(post.isLiked, isFalse);

      final map = post.toMap();
      expect(map['id'], 'post_1001');
      expect(map['activityType'], 'Running');
      expect(map['distanceKm'], 10.25);
      expect(map['likesCount'], 14);
      expect(map['commentsCount'], 3);
    });

    test('2. SocialComment model handles author, text and timestamp', () {
      final comment = SocialComment(
        id: 'comm_01',
        postId: 'post_1001',
        userId: 'runner_siva',
        username: 'siva_runner',
        text: 'Super pace bro! Keep crushing it 🔥',
        createdAt: DateTime.now(),
      );

      expect(comment.id, 'comm_01');
      expect(comment.username, 'siva_runner');
      expect(comment.text, contains('Super pace'));
      final map = comment.toMap();
      expect(map['postId'], 'post_1001');
      expect(map['text'], 'Super pace bro! Keep crushing it 🔥');
    });

    test('3. SocialNotification model handles follow, like, comment events', () {
      final followNotif = SocialNotification(
        id: 'notif_01',
        recipientId: 'sarathi_joy4_uid',
        senderId: 'athlete_karthik',
        senderUsername: 'karthik_pace',
        type: 'follow',
        message: 'started following you',
        isRead: false,
        createdAt: DateTime.now(),
      );

      expect(followNotif.type, 'follow');
      expect(followNotif.isRead, isFalse);
      expect(followNotif.senderUsername, 'karthik_pace');

      final likeNotif = SocialNotification(
        id: 'notif_02',
        recipientId: 'sarathi_joy4_uid',
        senderId: 'athlete_priya',
        senderUsername: 'priya_fitness',
        type: 'like',
        postId: 'post_1001',
        message: 'liked your running post',
        isRead: false,
        createdAt: DateTime.now(),
      );

      expect(likeNotif.type, 'like');
      expect(likeNotif.postId, 'post_1001');
    });

    test('4. UserService profile fields match user fresh profile details', () {
      final user = UserService.instance;
      expect(user.username, 'sarathi_joy4');
      expect(user.displayName, contains('Sarathi'));
      expect(user.followersCount, 0);
      expect(user.followingCount, 0);
      expect(user.bio, isEmpty);
      expect(user.website, isEmpty);
    });

    test('5. ProfilePost addition and duplicate prevention', () {
      final user = UserService.instance;
      final initialCount = user.postsCount;

      final post1 = ProfilePost(
        id: 'test_post_01',
        activityId: 'act_01',
        title: 'Morning 5K',
        mode: 'Running',
        distanceKm: 5.0,
        durationSeconds: 1500,
        calories: 320,
        avgPace: '5\'00"/km',
        avgSpeedKmH: 12.0,
        heartRateBpm: 145,
        dateTime: DateTime.now(),
        locationName: 'Guijiliyamparai',
        gpsRoutePoints: const [LatLng(10.6, 78.1), LatLng(10.61, 78.11)],
        caption: 'Great tempo run today! ⚡',
      );

      user.addProfilePost(post1);
      expect(user.postsCount, initialCount + 1);

      // Adding the same post ID or activity ID should update rather than duplicate
      user.addProfilePost(post1);
      expect(user.postsCount, initialCount + 1);

      // Interactive like toggle on profile post
      expect(post1.likes, 0);
      user.toggleLikePost(post1.id);
      expect(post1.likes, 1);
      expect(post1.isLiked, isTrue);

      user.toggleLikePost(post1.id);
      expect(post1.likes, 0);
      expect(post1.isLiked, isFalse);

      // Clean up test post
      user.deleteProfilePost(post1.id);
      expect(user.postsCount, initialCount);
    });

    test('6. SocialService toggleLike updates count and state consistently', () async {
      final post = SocialPost(
        id: 'test_like_post',
        userId: 'athlete_siva',
        username: 'siva_runner',
        userDisplayName: 'Siva',
        caption: 'Trail run test',
        activityType: 'Running',
        likesCount: 5,
        isLiked: false,
        createdAt: DateTime.now(),
      );

      await SocialService.instance.toggleLike(post);
      expect(post.isLiked, isTrue);
      expect(post.likesCount, 6);

      await SocialService.instance.toggleLike(post);
      expect(post.isLiked, isFalse);
      expect(post.likesCount, 5);
    });

    test('7. SocialClub model serialization, search and membership toggle', () async {
      final club = SocialClub(
        id: 'club_test_01',
        name: 'Guijiliyamparai Trail Runners',
        description: 'Morning trail running club',
        sportType: 'Running',
        location: 'Guijiliyamparai',
        membersCount: 25,
        isJoined: false,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(club.id, 'club_test_01');
      expect(club.name, contains('Guijiliyamparai'));
      expect(club.isJoined, isFalse);

      final map = club.toMap();
      expect(map['name'], 'Guijiliyamparai Trail Runners');
      expect(map['sportType'], 'Running');
      expect(map['membersCount'], 25);

      // Join club
      await SocialService.instance.joinClub(club);
      expect(club.isJoined, isTrue);

      // Leave club
      await SocialService.instance.leaveClub(club.id, club);
      expect(club.isJoined, isFalse);
    });

    test('8. QR Code resolution extracts valid athlete and rejects invalid QR', () async {
      // 1. Valid custom scheme
      const validCustomQr = 'jaihind://user/athlete_siva_01?username=siva_runner';
      final athlete1 = await SocialService.instance.getUserByQrCode(validCustomQr);
      expect(athlete1, isNotNull);
      expect(athlete1!.username, 'siva_runner');

      // 2. Valid web profile URL
      const validWebQr = 'https://jaihind-runner.web.app/@siva_runner';
      final athlete2 = await SocialService.instance.getUserByQrCode(validWebQr);
      expect(athlete2, isNotNull);
      expect(athlete2!.username, 'siva_runner');

      // 3. Invalid QR code
      const invalidQr = '';
      final invalidAthlete = await SocialService.instance.getUserByQrCode(invalidQr);
      expect(invalidAthlete, isNull);
    });

    test('9. SocialUser model displays location and fitness short information', () {
      final athlete = SocialUser(
        uid: 'ath_99',
        username: 'siva_speed',
        displayName: 'Siva',
        location: 'Guijiliyamparai, Dindigul',
        fitnessInfo: '10K Marathon • 4:50 pace',
      );

      expect(athlete.location, contains('Guijiliyamparai'));
      expect(athlete.fitnessInfo, contains('10K Marathon'));
    });

    test('10. SocialPost handles real routePoints without generating fake circles', () {
      final points = [
        const LatLng(10.5, 78.1),
        const LatLng(10.51, 78.12),
        const LatLng(10.52, 78.15),
      ];
      final post = SocialPost(
        id: 'post_route_test',
        userId: 'sarathi_uid',
        username: 'sarathi_01',
        userDisplayName: 'Sarathi',
        caption: 'Outdoor Run Route',
        routePoints: points,
        createdAt: DateTime.now(),
      );

      final map = post.toMap();
      expect(map['routePoints'], isNotNull);
      final rawList = map['routePoints'] as List;
      expect(rawList.length, 3);
      expect(rawList.first['lat'], 10.5);
    });

    test('11. Following counter increments (+1) on follow and decrements (-1) on unfollow', () {
      final user = UserService.instance;
      final initialFollowing = user.followingCount;

      user.incrementFollowing();
      expect(user.followingCount, initialFollowing + 1);

      user.decrementFollowing();
      expect(user.followingCount, initialFollowing);
    });

    test('12. getFollowingUsers returns followed athlete IDs and removes them on unfollow', () async {
      final social = SocialService.instance;
      final athlete = SocialUser(
        uid: 'test_friend_01',
        username: 'karthik_pace',
        displayName: 'Karthik Raja',
        location: 'Dindigul',
      );

      await social.followUser(athlete);
      final followedList = await social.getFollowingUsers();
      expect(followedList.any((u) => u.uid == 'test_friend_01' && u.username == 'karthik_pace'), isTrue);

      await social.unfollowUser('test_friend_01');
      final afterUnfollow = await social.getFollowingUsers();
      expect(afterUnfollow.any((u) => u.uid == 'test_friend_01'), isFalse);
    });
  });
}
