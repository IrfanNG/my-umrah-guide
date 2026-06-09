import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/user_profile.dart';
import '../auth_controller.dart';
import '../profile_controller.dart';
import '../widgets/practice_ui.dart';

class ProfileSetupView extends StatefulWidget {
  const ProfileSetupView({
    required this.user,
    required this.existingProfile,
    super.key,
  });

  final User user;
  final UserProfile? existingProfile;

  @override
  State<ProfileSetupView> createState() => _ProfileSetupViewState();
}

class _ProfileSetupViewState extends State<ProfileSetupView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _healthController;
  AbilityLevel _abilityLevel = AbilityLevel.medium;

  @override
  void initState() {
    super.initState();
    _ageController = TextEditingController(
      text: widget.existingProfile?.age == 0
          ? ''
          : widget.existingProfile?.age.toString() ?? '',
    );
    _heightController = TextEditingController(
      text: widget.existingProfile?.heightCm?.toString() ?? '',
    );
    _weightController = TextEditingController(
      text: widget.existingProfile?.weightKg?.toString() ?? '',
    );
    _healthController = TextEditingController(
      text: widget.existingProfile?.healthConditions ?? '',
    );
    _abilityLevel = widget.existingProfile?.abilityLevel ?? AbilityLevel.medium;
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _healthController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final age = int.parse(_ageController.text.trim());
    final heightCm = double.parse(_heightController.text.trim());
    final weightKg = double.parse(_weightController.text.trim());
    final profile = UserProfile(
      uid: widget.user.uid,
      email: widget.user.email ?? '',
      role: widget.existingProfile?.role ?? UserRole.user,
      age: age,
      heightCm: heightCm,
      weightKg: weightKg,
      abilityLevel: _abilityLevel,
      healthConditions: _healthController.text.trim(),
      createdAt: widget.existingProfile?.createdAt,
    );
    await context.read<ProfileController>().saveProfile(profile);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProfileController>();
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Setup'),
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
              child: Form(
                key: _formKey,
                child: PracticeSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const PracticeSectionHeader(
                        title: 'Personalize your Umrah guidance',
                        subtitle:
                            'These details help the system suggest pace, distance, time, and rest intervals safely.',
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: const [
                          PracticeStatusChip(
                            label: 'Safe defaults',
                            icon: Icons.health_and_safety,
                          ),
                          PracticeStatusChip(
                            label: 'Account-linked',
                            icon: Icons.verified_user,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Age',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final age = int.tryParse(value?.trim() ?? '');
                          if (age == null || age < 12 || age > 100) {
                            return 'Enter an age between 12 and 100.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _heightController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Height (cm)',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                final h = double.tryParse(value?.trim() ?? '');
                                if (h == null || h < 50 || h > 250) {
                                  return 'Enter height 50-250 cm.';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _weightController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Weight (kg)',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                final w = double.tryParse(value?.trim() ?? '');
                                if (w == null || w < 20 || w > 300) {
                                  return 'Enter weight 20-300 kg.';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Ability level',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<AbilityLevel>(
                        segments: AbilityLevel.values
                            .map(
                              (level) => ButtonSegment<AbilityLevel>(
                                value: level,
                                label: Text(level.label),
                              ),
                            )
                            .toList(),
                        selected: {_abilityLevel},
                        onSelectionChanged: (selection) {
                          setState(() => _abilityLevel = selection.first);
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _healthController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Health conditions or notes (optional)',
                          hintText:
                              'Example: knee pain, asthma, wheelchair user',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (controller.errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          controller.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                      const SizedBox(height: 28),
                      FilledButton.icon(
                        onPressed: controller.isSaving ? null : _save,
                        icon: controller.isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check),
                        label: const Text('Save Profile'),
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
