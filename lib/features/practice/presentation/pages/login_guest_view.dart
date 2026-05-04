import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../guest_session_controller.dart';
import '../widgets/practice_ui.dart';

class LoginGuestView extends StatelessWidget {
  const LoginGuestView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: PracticeUi.appGradient),
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Stack(
                            children: [
                              SizedBox(
                                height: 230,
                                width: double.infinity,
                                child: Image.asset(
                                  PracticeUi.kaabahHeroAsset,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                ),
                              ),
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.03),
                                        Colors.black.withValues(alpha: 0.24),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Transform.translate(
                            offset: const Offset(0, -34),
                            child: PracticeSurfaceCard(
                              padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(28),
                                bottom: Radius.circular(26),
                              ),
                              borderColor: PracticeUi.line,
                              child: Column(
                                children: [
                                  Transform.translate(
                                    offset: const Offset(0, -34),
                                    child: Container(
                                      width: 62,
                                      height: 62,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: PracticeUi.sand,
                                          width: 4,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.12,
                                            ),
                                            blurRadius: 16,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.mosque_rounded,
                                        color: PracticeUi.deepGold,
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                  Transform.translate(
                                    offset: const Offset(0, -22),
                                    child: Column(
                                      children: [
                                        RichText(
                                          textAlign: TextAlign.center,
                                          text: TextSpan(
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall
                                                ?.copyWith(
                                                  color: PracticeUi.forest,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                            children: const [
                                              TextSpan(text: 'MyUmrah'),
                                              TextSpan(
                                                text: 'Guide',
                                                style: TextStyle(
                                                  color: PracticeUi.deepGold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'Pilgrim Companion',
                                          style: TextStyle(
                                            color: PracticeUi.forest,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          width: 54,
                                          height: 1,
                                          color: PracticeUi.deepGold,
                                        ),
                                        const SizedBox(height: 20),
                                        FilledButton(
                                          onPressed: () => Navigator.pushNamed(
                                            context,
                                            '/login-form',
                                          ),
                                          style: PracticeUi.primaryButtonStyle(
                                            backgroundColor:
                                                PracticeUi.deepGold,
                                          ),
                                          child: const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Log in',
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              Icon(Icons.arrow_forward_rounded),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        OutlinedButton(
                                          onPressed: () => Navigator.pushNamed(
                                            context,
                                            '/register',
                                          ),
                                          style:
                                              PracticeUi.outlineButtonStyle(),
                                          child: const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Create an Account',
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              Icon(Icons.group_add_outlined),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        OutlinedButton(
                                          onPressed: () => context
                                              .read<GuestSessionController>()
                                              .enterGuestMode(),
                                          style: PracticeUi.outlineButtonStyle(
                                            foregroundColor: PracticeUi.forest,
                                            borderColor: PracticeUi.forest
                                                .withValues(alpha: 0.35),
                                            backgroundColor: const Color(
                                              0xFFFBFFF9,
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Enter as Guest',
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              Icon(Icons.person_outline),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        const Wrap(
                                          alignment: WrapAlignment.center,
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            _TrustMiniChip(
                                              icon: Icons.verified_user,
                                              label: 'Trusted Guidance',
                                            ),
                                            _TrustMiniChip(
                                              icon: Icons.cloud_done_outlined,
                                              label: 'Offline Ready',
                                            ),
                                            _TrustMiniChip(
                                              icon: Icons.lock_outline,
                                              label: 'Privacy Safe',
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -18),
                      child: Text(
                        'Guest mode keeps everything local on this device. You can still sign in later for Firebase-backed sync.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const _WelcomeTrustList(),
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

class _TrustMiniChip extends StatelessWidget {
  const _TrustMiniChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: PracticeUi.warmSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PracticeUi.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: PracticeUi.forest),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: PracticeUi.ink,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeTrustList extends StatelessWidget {
  const _WelcomeTrustList();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _TrustCueRow(
          icon: Icons.verified_user,
          label: 'Trusted Guidance',
          message: 'Ritual flow, guidance, and demo-safe checkpoints.',
        ),
        SizedBox(height: 10),
        _TrustCueRow(
          icon: Icons.cloud_done_outlined,
          label: 'Offline Ready',
          message: 'Cached recommendations and local progress recovery.',
        ),
        SizedBox(height: 10),
        _TrustCueRow(
          icon: Icons.lock_outline,
          label: 'Privacy Safe',
          message: 'Guest mode stays local until sign-in is used.',
        ),
      ],
    );
  }
}

class _TrustCueRow extends StatelessWidget {
  const _TrustCueRow({
    required this.icon,
    required this.label,
    required this.message,
  });

  final IconData icon;
  final String label;
  final String message;

  @override
  Widget build(BuildContext context) {
    return PracticeSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: PracticeUi.compactRadius,
      borderColor: PracticeUi.line,
      boxShadow: const [],
      child: Row(
        children: [
          PracticeIconBadge(icon: icon, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: PracticeUi.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    color: PracticeUi.body,
                    height: 1.3,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
