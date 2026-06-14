import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'features/practice/presentation/geofence_provider.dart';
import 'features/practice/presentation/adaptive_schedule_controller.dart';
import 'features/practice/presentation/auth_controller.dart';
import 'features/practice/presentation/background_geofence_controller.dart';
import 'features/practice/presentation/guest_session_controller.dart';
import 'features/practice/presentation/pages/auth_gate.dart';
import 'features/practice/presentation/pages/login_guest_view.dart';
import 'features/practice/presentation/pages/login_form_view.dart';
import 'features/practice/presentation/pages/register_view.dart';
import 'features/practice/presentation/pages/tawaf_simulator_view.dart';
import 'features/practice/presentation/pages/sai_simulator_view.dart';
import 'features/practice/presentation/pages/session_history_view.dart';
import 'features/practice/presentation/pages/splash_view.dart';
import 'features/practice/presentation/profile_controller.dart';
import 'features/practice/presentation/privacy_consent_controller.dart';
import 'features/practice/presentation/recommendation_controller.dart';
import 'features/practice/presentation/ritual_progress_controller.dart';
import 'features/practice/presentation/sai_provider.dart';
import 'core/services/notification_service.dart';

Future<bool> _initializeFirebaseIfSupported() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  } catch (e) {
    debugPrint('Firebase skipped: $e');
    return false;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isFirebaseAvailable = await _initializeFirebaseIfSupported();
  await NotificationService().init();
  runApp(MyUmrahGuide(isFirebaseAvailable: isFirebaseAvailable));
}

class MyUmrahGuide extends StatelessWidget {
  const MyUmrahGuide({required this.isFirebaseAvailable, super.key});
  final bool isFirebaseAvailable;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GuestSessionController()),
        if (isFirebaseAvailable)
          ChangeNotifierProxyProvider<GuestSessionController, AuthController>(
            create: (context) => AuthController(
              guestSessionController: context.read<GuestSessionController>(),
            ),
            update: (_, guestSession, controller) =>
                controller ??
                AuthController(guestSessionController: guestSession),
          ),
        ChangeNotifierProvider(create: (_) => AdaptiveScheduleController()),
        ChangeNotifierProxyProvider<
            GuestSessionController,
            BackgroundGeofenceController>(
          create: (context) => BackgroundGeofenceController(
            guestSessionController: context.read<GuestSessionController>(),
          ),
          update: (_, guestSession, controller) =>
              controller ??
              BackgroundGeofenceController(
                guestSessionController: guestSession,
              ),
        ),
        if (isFirebaseAvailable)
          ChangeNotifierProvider(create: (_) => ProfileController()),
        ChangeNotifierProvider(create: (_) => PrivacyConsentController()),
        if (isFirebaseAvailable)
          ChangeNotifierProvider(create: (_) => RecommendationController()),
        ChangeNotifierProxyProvider<
            GuestSessionController,
            RitualProgressController>(
          create: (context) => RitualProgressController(
            guestSessionController: context.read<GuestSessionController>(),
          ),
          update: (_, guestSession, controller) =>
              controller ??
              RitualProgressController(guestSessionController: guestSession),
        ),
        ChangeNotifierProvider(create: (_) => GeofenceProvider()),
        ChangeNotifierProvider(create: (_) => SaiProvider()),
      ],
      child: MaterialApp(
        title: 'MyUmrahGuide',
        navigatorKey: NotificationService.navigatorKey,
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: NotificationService.messengerKey,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFFAFAFA),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFD4AF37),
            primary: const Color(0xFFD4AF37),
            onPrimary: Colors.white,
            secondary: const Color(0xFFB2D8B2),
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
        initialRoute: '/splash',
        routes: isFirebaseAvailable
            ? {
                '/splash': (context) => const SplashView(),
                '/': (context) => const AuthGate(),
                '/login': (context) => const LoginGuestView(),
                '/login-form': (context) => const LoginFormView(),
                '/register': (context) => const RegisterView(),
                '/admin': (context) => const AuthGate(),
                '/dashboard': (context) => const _DashboardRouteFallback(),
                '/profile': (context) => const _ProfileRouteFallback(),
                '/tawaf-simulator': (context) => const TawafSimulatorView(),
                '/sai-simulator': (context) => const SaiSimulatorView(),
                '/session-history': (context) => const SessionHistoryView(),
              }
            : {
                '/splash': (context) => const SplashView(),
                '/': (context) => const _FirebaseUnavailableScreen(),
              },
      ),
    );
  }
}

class _FirebaseUnavailableScreen extends StatelessWidget {
  const _FirebaseUnavailableScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'Firebase unavailable on this platform',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Run on Web or Android for login and session history.',
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
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
