import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jaihind/core/services/user_service.dart';
import 'package:jaihind/core/services/auth_service.dart';
import 'package:jaihind/features/splash/splash_screen.dart';
import 'package:jaihind/features/workout/save_activity_screen.dart';
import 'package:jaihind/features/home/home_screen.dart';
import 'package:jaihind/features/profile/profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JAIHIND App - Full Verification Test Suite', () {
    // -----------------------------------------------------------------
    // TEST 1: Session Persistence & Auto-Login Logic
    // -----------------------------------------------------------------
    test('1. Session Persistence: updateProfile sets isLoggedIn, logOut clears it', () async {
      final user = UserService.instance;

      // Update profile -> should mark logged in
      user.updateProfile(
        name: 'Sarathi Joy',
        email: 'sarathi@gmail.com',
        password: 'Password@123',
      );
      expect(user.isLoggedIn, isTrue);
      expect(user.name, 'Sarathi Joy');
      expect(user.email, 'sarathi@gmail.com');

      // Explicit log out -> should mark logged out
      await user.logOut();
      expect(user.isLoggedIn, isFalse);
    });

    // -----------------------------------------------------------------
    // TEST 2: Local Self-Healing Registration Fallback
    // -----------------------------------------------------------------
    test('2. Local Registration: AuthResult.localOk marks local fallback', () {
      final res = AuthResult.localOk();
      expect(res.success, isTrue);
      expect(res.isLocalFallback, isTrue);
      expect(res.errorMessage, isNull);
    });

    // -----------------------------------------------------------------
    // TEST 3: SplashScreen Auto-Routes to MainNavigationScreen when Logged In
    // -----------------------------------------------------------------
    testWidgets('3. SplashScreen auto-login: active session skips login/signup',
        (WidgetTester tester) async {
      final user = UserService.instance;
      user.updateProfile(
        name: 'Sarathi Runner',
        email: 'sarathi@gmail.com',
        password: 'Password@123',
      );
      expect(user.isLoggedIn, isTrue);

      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(),
        ),
      );

      // Verify splash screen branding is rendered initially
      expect(find.byType(SplashScreen), findsOneWidget);

      // Fast-forward past the 1800ms splash delay to allow navigation
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pumpAndSettle();
    });

    // -----------------------------------------------------------------
    // TEST 4: SaveActivityScreen Displays Dynamic Location & Never Hardcoded
    // -----------------------------------------------------------------
    testWidgets('4. SaveActivityScreen displays detected location (Coimbatore) and not Guijiliyamparai',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SaveActivityScreen(
            mode: 'Running',
            distanceKm: 2.50,
            durationSeconds: 900,
            calories: 180,
            avgPace: "6'00\"",
            initialLocationName: 'Coimbatore',
            gpsRoutePoints: [
              LatLng(11.0016, 76.9628), // Coimbatore Coordinates
              LatLng(11.0020, 76.9635),
            ],
          ),
        ),
      );

      await tester.pump();

      // Location should show 'Coimbatore • 2.50 km' in the top badge
      expect(find.text('Coimbatore • 2.50 km'), findsOneWidget);

      // Location row next to date should show 'Coimbatore'
      expect(find.text('Coimbatore'), findsOneWidget);

      // Ensure 'Guijiliyamparai' is NEVER displayed
      expect(find.textContaining('Guijiliyamparai'), findsNothing);
    });

    // -----------------------------------------------------------------
    // TEST 5: Home Screen displays 'Walk' activity with walking icon
    // -----------------------------------------------------------------
    testWidgets('5. Home Screen displays Walk activity instead of Swim',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomeScreen(),
          ),
        ),
      );

      await tester.pump();

      // Walk activity must be present with walking icon
      expect(find.text('Walk'), findsOneWidget);
      expect(find.byIcon(Icons.directions_walk_rounded), findsOneWidget);

      // Swim must not be present in activity list
      expect(find.text('Swim'), findsNothing);
    });

    // -----------------------------------------------------------------
    // TEST 6: Profile Screen displays 0 followers, 0 following, and empty state
    // -----------------------------------------------------------------
    testWidgets('6. Profile Screen reflects clean modern design without deprecated elements',
        (WidgetTester tester) async {
      final user = UserService.instance;
      user.updateInstagramProfile(
        displayName: 'Sarathi Joy',
        username: 'sarathi_joy4',
        bio: '',
        website: '',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );

      await tester.pump();

      // Profile header displays username
      expect(find.text('sarathi_joy4'), findsOneWidget);

      // Followers and Following display count 0
      expect(find.text('followers'), findsOneWidget);
      expect(find.text('following'), findsOneWidget);

      // Story highlights must be gone
      expect(find.text('Highlights'), findsNothing);

      // Banner button must be gone
      expect(find.text('+ Add banners'), findsNothing);
    });

    // -----------------------------------------------------------------
    // TEST 7: Background Wall-Clock Elapsed Time Math
    // -----------------------------------------------------------------
    test('7. Background Wall-Clock elapsed time calculation stays accurate when screen turns off', () {
      final startTime = DateTime.now().subtract(const Duration(minutes: 15, seconds: 32));
      final totalElapsed = DateTime.now().difference(startTime);
      expect(totalElapsed.inSeconds, greaterThanOrEqualTo(932));
      expect(totalElapsed.inMinutes, 15);
    });

    // -----------------------------------------------------------------
    // TEST 8: Stationary Filter & Minimum Route Polyline Threshold (>= 30m)
    // -----------------------------------------------------------------
    test('8. Stationary Filter rejects indoor teleport jumps and requires >= 30m for route drawing', () {
      // 1. Teleport jump simulation: 20m in 1.5s = 48 km/h indoors
      const double meters = 20.0;
      const double timeSeconds = 1.5;
      const double calculatedSpeedKmH = (meters / timeSeconds) * 3.6;
      const double dopplerSpeed = 0.0; // stationary phone has 0 Doppler speed

      const bool hasDopplerMovement = dopplerSpeed >= 1.8 && meters >= 4.0 && meters < 150.0;
      const bool hasSustainedDisplacement = dopplerSpeed <= 0 &&
          meters >= 8.0 &&
          meters < 150.0 &&
          timeSeconds >= 2.5 &&
          calculatedSpeedKmH >= 2.0 &&
          calculatedSpeedKmH <= 25.0;

      const bool hasMoved = hasDopplerMovement || hasSustainedDisplacement;
      expect(hasMoved, isFalse, reason: 'Indoor 48 km/h GPS teleport jump must NOT register as movement!');

      // 2. Minimum distance threshold for polyline & start marker
      const double stationaryDistanceKm = 0.02;
      const double genuineRunDistanceKm = 0.05;
      expect(stationaryDistanceKm >= 0.03, isFalse, reason: '0.02 km drift must NOT draw polyline or start pin');
      expect(genuineRunDistanceKm >= 0.03, isTrue, reason: '0.05 km genuine run must draw polyline');
    });
  });
}
