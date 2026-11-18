import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaihind/core/navigation/main_navigation_screen.dart';
import 'package:jaihind/core/services/user_service.dart';
import 'package:jaihind/features/onboarding/welcome_screen.dart';
import 'package:jaihind/features/home/home_screen.dart';
import 'package:jaihind/features/maps/maps_screen.dart';
import 'package:jaihind/features/workout/workout_screen.dart';
import 'package:jaihind/features/profile/profile_screen.dart';
import 'package:jaihind/features/workout/active_workout_screen.dart';
import 'package:jaihind/features/workout/save_activity_screen.dart';

void main() {
  group('JAIHIND App - Comprehensive Feature Tests', () {
    // TEST 1: Welcome Screen UI Elements
    testWidgets('1. Welcome Screen displays branding, buttons and location',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomeScreen(),
        ),
      );

      // Verify Brand Text & Tagline
      expect(find.byType(RichText), findsWidgets);
      expect(find.text('TRACK. TRAIN. ACHIEVE.'), findsOneWidget);

      // Verify Buttons
      expect(find.text('CREATE AN ACCOUNT'), findsOneWidget);
      expect(find.text('LOGIN'), findsOneWidget);

      // Verify Location Footer Text
      expect(find.byType(RichText), findsWidgets);
    });

    // TEST 2: Navigation to Register and Login Screens
    testWidgets('2. Tapping Create Account navigates to Register Screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomeScreen(),
        ),
      );

      // Tap "CREATE AN ACCOUNT"
      await tester.tap(find.text('CREATE AN ACCOUNT'));
      await tester.pumpAndSettle();

      // Register Screen is loaded
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
    });

    // TEST 3: Home Dashboard Features
    testWidgets('3. Home Dashboard displays all sections and banner',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // Welcome Banner
      expect(find.text('Welcome to'), findsOneWidget);
      expect(find.text('Start Your Activity'), findsOneWidget);

      // About Card
      expect(find.text('About JAIHIND'), findsOneWidget);

      // "How It's Used" Activities
      expect(find.text("How It's Used"), findsOneWidget);
      expect(find.text('Run'), findsOneWidget);
      expect(find.text('Cycling'), findsOneWidget);
      expect(find.text('Walk'), findsOneWidget);
      expect(find.text('Hike'), findsOneWidget);

      // Key Benefits
      expect(find.text('Key Benefits'), findsOneWidget);
      expect(find.text('Track Progress'), findsOneWidget);
      expect(find.text('Set Goals'), findsOneWidget);
      expect(find.text('Join Community'), findsOneWidget);
      expect(find.text('Stay Healthy'), findsOneWidget);
    });

    // TEST 4: Bottom Navigation Bar Tab Switching (5 Tabs: Home, Maps, Start, Streak, You)
    testWidgets('4. Bottom Navigation switches across 5 tabs in order',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainNavigationScreen(),
        ),
      );

      // Verify 5 navigation tabs exist in exact order
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Maps'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('Streak'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);

      // Switch to Maps (Tab 1)
      await tester.tap(find.text('Maps'));
      await tester.pumpAndSettle();
      expect(find.text('Satellite'), findsOneWidget);

      // Switch to Start (Tab 2)
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      expect(find.text('Workout Modes'), findsOneWidget);

      // Switch to Streak (Tab 3)
      await tester.tap(find.text('Streak'));
      await tester.pumpAndSettle();
      expect(find.text('Running Streak'), findsOneWidget);
      expect(find.textContaining('DAYS STREAK'), findsOneWidget);

      // Switch to You / Profile (Tab 4)
      await tester.tap(find.text('You'));
      await tester.pumpAndSettle();
      expect(find.text(UserService.instance.name), findsOneWidget);
    });

    // TEST 5: Workout Modes & Card Selection
    testWidgets('5. Workout Screen renders 4 modes and allows selection',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WorkoutScreen(),
        ),
      );

      expect(find.text('Workout Modes'), findsOneWidget);
      expect(find.text('Running'), findsOneWidget);
      expect(find.text('Walking'), findsOneWidget);
      expect(find.text('Cycling'), findsOneWidget);
      expect(find.text('Hike'), findsOneWidget);
      expect(find.text('Start New Session'), findsOneWidget);

      // Tap on Hike card
      await tester.tap(find.text('Hike'));
      await tester.pumpAndSettle();
    });

    // TEST 6: Maps GPS Route Screen
    testWidgets('6. Maps Screen renders map types and controls',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MapsScreen(),
        ),
      );

      expect(find.text('Default'), findsOneWidget);
      expect(find.text('Satellite'), findsOneWidget);
      expect(find.text('Terrain'), findsOneWidget);
      expect(find.text('Hybrid'), findsOneWidget);

      // Toggle to Satellite mode
      await tester.tap(find.text('Satellite'));
      await tester.pumpAndSettle();
    });

    // TEST 7: Profile & Instagram-style Athlete Screen
    testWidgets('7. Profile Screen displays user info and calendar grid',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );

      expect(find.text(UserService.instance.username), findsOneWidget);
      expect(find.text(UserService.instance.displayName), findsOneWidget);
      expect(find.text('Edit profile'), findsOneWidget);
      expect(find.text('Share profile'), findsOneWidget);
      expect(find.text('posts'), findsOneWidget);
      expect(find.text('followers'), findsOneWidget);
      expect(find.text('following'), findsOneWidget);
    });

    // TEST 8: Active Workout Live Satellite GPS Screen & Controls
    testWidgets('8. Active Workout Screen displays metrics, satellite map and controls',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ActiveWorkoutScreen(initialMode: 'Running'),
        ),
      );

      // Verify Metrics Card
      expect(find.textContaining('Run'), findsWidgets);
      expect(find.text('Duration'), findsOneWidget);
      expect(find.text('00:00'), findsOneWidget);
      expect(find.text('Distance'), findsOneWidget);
      expect(find.text('Speed'), findsOneWidget);

      // Verify Controls
      expect(find.text('3D'), findsOneWidget);

      // Verify Start Tracking Button & Tap it
      expect(find.text('Start Tracking'), findsOneWidget);
      await tester.tap(find.text('Start Tracking'));
      await tester.pumpAndSettle();

      // Workout is now running -> Pause button and Flag icon are visible
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(find.byIcon(Icons.flag_rounded), findsOneWidget);

      // Tap Pause to enter Paused state
      await tester.tap(find.byIcon(Icons.pause_rounded));
      await tester.pumpAndSettle();

      // Verify Paused state ('Resume' and 'Finish' are visible)
      expect(find.text('Resume'), findsOneWidget);
      expect(find.text('Finish'), findsOneWidget);
    });

    // TEST 9: Save Activity Screen & Profile Integration
    testWidgets('9. Save Activity Screen saves workout to User Profile',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SaveActivityScreen(
            mode: 'Running',
            distanceKm: 4.50,
            durationSeconds: 1500,
            calories: 320,
            avgPace: "5'33\"",
          ),
        ),
      );

      // Verify UI
      expect(find.text('Save Activity'), findsWidgets);
      expect(find.text('Sport Type'), findsOneWidget);
      expect(find.text('How did it feel?'), findsOneWidget);
      expect(find.text('4.50 km'), findsOneWidget);
      expect(find.text('320 kcal'), findsOneWidget);

      // Tap Save Activity
      await tester.tap(find.text('Save Activity').last);
      await tester.pumpAndSettle();
    });
  });
}
