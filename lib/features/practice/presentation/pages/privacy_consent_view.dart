import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth_controller.dart';
import '../privacy_consent_controller.dart';
import '../widgets/practice_ui.dart';

class PrivacyConsentView extends StatelessWidget {
  const PrivacyConsentView({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Location Consent'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => context.read<AuthController>().signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: PracticeUi.pagePadding,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PracticeSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.privacy_tip_outlined,
                          color: primaryColor,
                          size: 36,
                        ),
                        const SizedBox(height: 16),
                        const PracticeSectionHeader(
                          title: 'Before location-based practice',
                          subtitle:
                              'MyUmrahGuide uses location only to support Tawaf, Sa\'i, Miqat detection, progress recovery, and safety-oriented practice guidance.',
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: const [
                            PracticeStatusChip(
                              label: 'Location only when needed',
                              icon: Icons.my_location,
                            ),
                            PracticeStatusChip(
                              label: 'User-controlled',
                              icon: Icons.lock_outline,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const _ConsentPoint(
                          icon: Icons.my_location,
                          title: 'Location access',
                          body:
                              'Requested only when you open tracking features or pin ritual points.',
                        ),
                        const _ConsentPoint(
                          icon: Icons.health_and_safety_outlined,
                          title: 'Profile-based guidance',
                          body:
                              'Age, ability level, and optional health notes personalize pace and rest suggestions.',
                        ),
                        const _ConsentPoint(
                          icon: Icons.cloud_sync_outlined,
                          title: 'Firebase storage',
                          body:
                              'Profile, recommendations, and completed-session analytics are saved to your account.',
                        ),
                        const _ConsentPoint(
                          icon: Icons.lock_outline,
                          title: 'Your control',
                          body:
                              'You can sign out or revoke consent later; tracking stops when consent is not granted.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context
                        .read<PrivacyConsentController>()
                        .acceptLocationConsent(),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('I Agree, Continue'),
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.read<AuthController>().signOut(),
                    icon: const Icon(Icons.close),
                    label: const Text('Decline and Sign Out'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'This notice supports PDPA/GDPR-style informed consent for FYP demonstration purposes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConsentPoint extends StatelessWidget {
  const _ConsentPoint({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
