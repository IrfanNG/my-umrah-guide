import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/practice/presentation/geofence_provider.dart';
import 'features/practice/presentation/pages/splash_view.dart';
import 'features/practice/presentation/pages/login_guest_view.dart';
import 'features/practice/presentation/pages/dashboard_view.dart';
import 'features/practice/presentation/pages/tawaf_simulator_view.dart';
import 'features/practice/presentation/pages/sai_simulator_view.dart';
import 'features/practice/presentation/sai_provider.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(
    MultiProvider(
      providers: [
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
      debugShowCheckedModeBanner: false,
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
        '/': (context) => const SplashView(),
        '/login': (context) => const LoginGuestView(),
        '/dashboard': (context) => const DashboardView(),
        '/tawaf-simulator': (context) => const TawafSimulatorView(),
        '/sai-simulator': (context) => const SaiSimulatorView(),
      },
    );
  }
}
