import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/constants/app_colors.dart';
import 'core/services/auth_service.dart';
import 'core/services/user_service.dart';
import 'features/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  // Initialize Firebase Authentication & Services
  await AuthService.instance.ensureInitialized();
  // Restore user session if already registered or logged in
  await UserService.instance.initSession();

  runApp(const JaihindApp());
}

class JaihindApp extends StatelessWidget {
  const JaihindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: UserService.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'JAIHIND',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            scaffoldBackgroundColor: AppColors.backgroundWhite,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primaryBlue,
              primary: AppColors.primaryBlue,
            ),
            useMaterial3: true,
          ),
          // Starts with big official splash logo screen, then automatically transitions seamlessly!
          home: const SplashScreen(),
        );
      },
    );
  }
}
