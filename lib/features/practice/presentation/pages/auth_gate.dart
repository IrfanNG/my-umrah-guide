import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/user_profile.dart';
import '../auth_controller.dart';
import '../guest_session_controller.dart';
import '../privacy_consent_controller.dart';
import '../profile_controller.dart';
import '../widgets/practice_ui.dart';
import 'admin_dashboard_view.dart';
import 'dashboard_view.dart';
import 'login_guest_view.dart';
import 'privacy_consent_view.dart';
import 'profile_setup_view.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();
    return Consumer<GuestSessionController>(
      builder: (context, guestSession, _) {
        if (!guestSession.isLoaded) {
          guestSession.load();
          return const _GateLoading();
        }
        return StreamBuilder<User?>(
          stream: auth.authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _GateLoading();
            }
            final user = snapshot.data;
            if (user == null) {
              if (guestSession.isGuestMode) {
                return Consumer<PrivacyConsentController>(
                  builder: (context, consent, _) {
                    if (!consent.isLoaded) {
                      consent.load();
                      return const _GateLoading();
                    }
                    if (!consent.hasLocationConsent) {
                      return const PrivacyConsentView();
                    }
                    return DashboardView(profile: GuestSessionController.guestProfile);
                  },
                );
              }
              return const LoginGuestView();
            }

            return StreamBuilder<UserProfile?>(
              stream: context.read<ProfileController>().watchProfile(user.uid),
              builder: (context, profileSnapshot) {
                if (profileSnapshot.connectionState == ConnectionState.waiting) {
                  return const _GateLoading();
                }
                final profile = profileSnapshot.data;
                if (profile == null || !profile.isComplete) {
                  return ProfileSetupView(user: user, existingProfile: profile);
                }
                if (profile.role == UserRole.admin) {
                  return const AdminDashboardView();
                }
                return Consumer<PrivacyConsentController>(
                  builder: (context, consent, _) {
                    if (!consent.isLoaded) {
                      consent.load();
                      return const _GateLoading();
                    }
                    if (!consent.hasLocationConsent) {
                      return const PrivacyConsentView();
                    }
                    return DashboardView(profile: profile);
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _GateLoading extends StatelessWidget {
  const _GateLoading();

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: PracticeUi.mutedSurface,
      body: Center(
        child: Padding(
          padding: PracticeUi.pagePadding,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: PracticeSurfaceCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.sync,
                      color: primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Syncing your profile',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: PracticeUi.ink,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Securing your journey data and preferences.',
                    style: TextStyle(color: Colors.grey.shade700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    color: primaryColor,
                    backgroundColor: primaryColor.withValues(alpha: 0.12),
                    minHeight: 4,
                  ),
                  const SizedBox(height: 16),
                  const PracticeStatusChip(
                    label: 'Secure sync',
                    icon: Icons.verified_user,
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
