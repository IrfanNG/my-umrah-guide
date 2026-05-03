import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth_controller.dart';
import '../widgets/practice_ui.dart';

class LoginGuestView extends StatelessWidget {
  const LoginGuestView({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF9E8), Color(0xFFFAFAFA), Color(0xFFF4F7F4)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: PracticeUi.pagePadding,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    PracticeSurfaceCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            height: 170,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: const Color(0xFFFFF5E1),
                              border: Border.all(
                                color: const Color(0xFFF3E2B7),
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Positioned(
                                  top: 16,
                                  left: 16,
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.08,
                                          ),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.mosque,
                                      color: PracticeUi.gold,
                                    ),
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_outlined,
                                      size: 40,
                                      color: primaryColor.withValues(
                                        alpha: 0.45,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Kaabah hero placeholder',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Welcome to',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: PracticeUi.body),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'MyUmrahGuide',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: PracticeUi.ink,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your trusted companion for a meaningful and easy Umrah.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: PracticeUi.body),
                          ),
                          const SizedBox(height: 16),
                          _TrustCueRow(
                            icon: Icons.verified_user,
                            label: 'Trusted Guidance',
                            message: 'Verified content from reliable sources.',
                            color: primaryColor,
                          ),
                          const SizedBox(height: 10),
                          _TrustCueRow(
                            icon: Icons.cloud_done,
                            label: 'Offline Access',
                            message: 'Key guides available anywhere, anytime.',
                            color: primaryColor,
                          ),
                          const SizedBox(height: 10),
                          _TrustCueRow(
                            icon: Icons.lock_outline,
                            label: 'Your Privacy Matters',
                            message: 'We respect and protect your data.',
                            color: primaryColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/login-form'),
                      style: FilledButton.styleFrom(
                        backgroundColor: PracticeUi.gold,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Log in'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/register'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PracticeUi.ink,
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: Colors.white,
                      ),
                      child: const Text('Create an Account'),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'By continuing, you agree to our Terms & Conditions and Privacy Policy.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
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

class _TrustCueRow extends StatelessWidget {
  const _TrustCueRow({
    required this.icon,
    required this.label,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: PracticeUi.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                message,
                style: TextStyle(color: Colors.grey.shade700, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
