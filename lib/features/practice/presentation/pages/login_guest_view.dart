import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth_controller.dart';
import '../widgets/practice_ui.dart';

class LoginGuestView extends StatefulWidget {
  const LoginGuestView({super.key});

  @override
  State<LoginGuestView> createState() => _LoginGuestViewState();
}

class _LoginGuestViewState extends State<LoginGuestView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = context.read<AuthController>();
    final success = _isRegisterMode
        ? await controller.register(
            email: _emailController.text,
            password: _passwordController.text,
          )
        : await controller.signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
    if (!success || !mounted) return;
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.account_circle_outlined,
                            size: 42,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const PracticeSectionHeader(
                        title: 'MyUmrahGuide',
                        subtitle:
                            'Sign in to access personalized Tawaf and Sa\'i guidance.',
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          PracticeStatusChip(
                            label: _isRegisterMode
                                ? 'Create account'
                                : 'Welcome back',
                            icon: _isRegisterMode
                                ? Icons.person_add
                                : Icons.lock_open,
                            backgroundColor: Colors.white,
                            borderColor: Colors.amber.shade100,
                            foregroundColor: PracticeUi.gold,
                          ),
                          const PracticeStatusChip(
                            label: 'Demo-ready',
                            icon: Icons.verified,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      PracticeSurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.mail_outline),
                              ),
                              validator: (value) {
                                final email = value?.trim() ?? '';
                                if (!email.contains('@') ||
                                    !email.contains('.')) {
                                  return 'Enter a valid email.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                              validator: (value) {
                                if ((value ?? '').length < 6) {
                                  return 'Password must be at least 6 characters.';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) => _submit(),
                            ),
                            if (auth.errorMessage != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                auth.errorMessage!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: auth.isLoading ? null : _submit,
                              icon: auth.isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      _isRegisterMode
                                          ? Icons.person_add
                                          : Icons.login,
                                    ),
                              label: Text(
                                _isRegisterMode ? 'Register' : 'Login',
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: auth.isLoading
                                  ? null
                                  : () {
                                      auth.clearError();
                                      setState(
                                        () =>
                                            _isRegisterMode = !_isRegisterMode,
                                      );
                                    },
                              child: Text(
                                _isRegisterMode
                                    ? 'Already have an account? Login'
                                    : 'New user? Create account',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
