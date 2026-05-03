import 'package:flutter/material.dart';

import '../widgets/practice_ui.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  Future<void> _navigateToLogin() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF7E6),
              Color(0xFFFFFBF4),
              Color(0xFFF4F7F4),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: PracticeUi.pagePadding,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.mosque,
                        size: 56,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'MyUmrahGuide',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: PracticeUi.ink,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pilgrim Companion',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: PracticeUi.body,
                          ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: const [
                        PracticeStatusChip(
                          label: 'Trusted guidance',
                          icon: Icons.verified,
                        ),
                        PracticeStatusChip(
                          label: 'Offline-ready',
                          icon: Icons.cloud_done_outlined,
                        ),
                        PracticeStatusChip(
                          label: 'Safe pace',
                          icon: Icons.favorite_border,
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),
                    const CircularProgressIndicator.adaptive(),
                    const SizedBox(height: 12),
                    Text(
                      'Preparing your journey...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: PracticeUi.body,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
