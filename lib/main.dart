import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'features/practice/presentation/geofence_provider.dart';
import 'features/practice/presentation/adaptive_schedule_controller.dart';
import 'features/practice/presentation/auth_controller.dart';
import 'features/practice/presentation/background_geofence_controller.dart';
import 'features/practice/presentation/pages/auth_gate.dart';
import 'features/practice/presentation/pages/login_guest_view.dart';
import 'features/practice/presentation/pages/tawaf_simulator_view.dart';
import 'features/practice/presentation/pages/sai_simulator_view.dart';
import 'features/practice/presentation/profile_controller.dart';
import 'features/practice/presentation/privacy_consent_controller.dart';
import 'features/practice/presentation/recommendation_controller.dart';
import 'features/practice/presentation/ritual_progress_controller.dart';
import 'features/practice/presentation/sai_provider.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => AdaptiveScheduleController()),
        ChangeNotifierProvider(create: (_) => BackgroundGeofenceController()),
        ChangeNotifierProvider(create: (_) => ProfileController()),
        ChangeNotifierProvider(create: (_) => PrivacyConsentController()),
        ChangeNotifierProvider(create: (_) => RecommendationController()),
        ChangeNotifierProvider(create: (_) => RitualProgressController()),
        ChangeNotifierProvider(create: (_) => GeofenceProvider()),
        ChangeNotifierProvider(create: (_) => SaiProvider()),
      ],
      child: const MyUmrahGuide(),
    ),
  );
}

class MyUmrahGuide extends StatelessWidget {
  const MyUmrahGuide({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyUmrahGuide',
      navigatorKey: NotificationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: NotificationService.messengerKey,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFAFAFA), // Zinc-50
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4AF37), // Mecca Gold
          primary: const Color(0xFFD4AF37),
          onPrimary: Colors.white,
          secondary: const Color(0xFFB2D8B2), // Rawdah Green
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          bodyLarge: TextStyle(color: Color(0xFF4B5563)),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        '/login': (context) => const LoginGuestView(),
        '/admin': (context) => const AuthGate(),
        '/dashboard': (context) => const _DashboardRouteFallback(),
        '/profile': (context) => const _ProfileRouteFallback(),
        '/tawaf-simulator': (context) => const TawafSimulatorView(),
        '/sai-simulator': (context) => const SaiSimulatorView(),
      },
    );
  }
}

class _DashboardRouteFallback extends StatelessWidget {
  const _DashboardRouteFallback();

  @override
  Widget build(BuildContext context) {
    return const AuthGate();
  }
}

class _ProfileRouteFallback extends StatelessWidget {
  const _ProfileRouteFallback();

  @override
  Widget build(BuildContext context) {
    return const AuthGate();
  }
}
