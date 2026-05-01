import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/user_profile.dart';
import '../auth_controller.dart';
import '../profile_controller.dart';
import 'admin_dashboard_view.dart';
import 'dashboard_view.dart';
import 'login_guest_view.dart';
import 'profile_setup_view.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();
    return StreamBuilder<User?>(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _GateLoading();
        }
        final user = snapshot.data;
        if (user == null) return const LoginGuestView();

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
            return DashboardView(profile: profile);
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
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
