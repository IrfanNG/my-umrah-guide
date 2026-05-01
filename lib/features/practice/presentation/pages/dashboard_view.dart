import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/practice_mode.dart';
import '../../domain/user_profile.dart';
import '../auth_controller.dart';
import '../ritual_progress_controller.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({required this.profile, super.key});

  final UserProfile profile;

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final progress = context.read<RitualProgressController>();
      if (!progress.isLoaded) {
        progress.load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<RitualProgressController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Umrah Practice'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => context.read<AuthController>().signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Journey Steps',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 24,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.profile.age} years old | ${widget.profile.abilityLevel.label}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 20),
            _ModeSelector(progress: progress),
            const SizedBox(height: 28),
            _buildTimelineItem(
              context,
              title: 'Umrah Intent at Miqat',
              description: progress.mode == PracticeMode.manual
                  ? 'Manual mode keeps this checkpoint open for revision.'
                  : 'Complete Niyyah before unlocking Tawaf.',
              isCompleted: progress.mode == PracticeMode.manual ||
                  progress.niyyahCompleted,
              isActive: progress.mode == PracticeMode.locationBased &&
                  !progress.niyyahCompleted,
              isFirst: true,
              actionLabel: progress.mode == PracticeMode.locationBased &&
                      !progress.niyyahCompleted
                  ? 'Mark Niyyah Done'
                  : null,
              onTap: progress.mode == PracticeMode.locationBased &&
                      !progress.niyyahCompleted
                  ? progress.markNiyyahCompleted
                  : null,
            ),
            _buildTimelineItem(
              context,
              title: 'Tawaf (7 Rounds)',
              description: progress.canOpenTawaf
                  ? 'Practice rounds with ML pace and time suggestion.'
                  : 'Locked until Miqat/Niyyah is completed.',
              isCompleted: progress.tawafCompleted,
              isActive: progress.canOpenTawaf,
              isLocked: !progress.canOpenTawaf,
              onTap: progress.canOpenTawaf
                  ? () => Navigator.pushNamed(context, '/tawaf-simulator')
                  : null,
            ),
            _buildTimelineItem(
              context,
              title: 'Sa\'i (Safa to Marwa)',
              description: progress.canOpenSai
                  ? 'Track Safa/Marwa progress with personal guidance.'
                  : 'Locked until Tawaf checkpoint is completed.',
              isActive: progress.canOpenSai,
              isLocked: !progress.canOpenSai,
              isLast: true,
              onTap: progress.canOpenSai
                  ? () => Navigator.pushNamed(context, '/sai-simulator')
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context, {
    required String title,
    required String description,
    bool isCompleted = false,
    bool isActive = false,
    bool isLocked = false,
    bool isFirst = false,
    bool isLast = false,
    String? actionLabel,
    VoidCallback? onTap,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    final mutedColor = Colors.grey.shade400;
    final dotColor = isCompleted
        ? secondaryColor
        : isLocked
            ? Colors.white
            : (isActive ? primaryColor : Colors.white);
    final borderColor = isCompleted
        ? secondaryColor
        : isLocked
            ? mutedColor
            : (isActive ? primaryColor : Colors.grey.shade300);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 2,
                height: 20,
                color: isFirst ? Colors.transparent : Colors.grey.shade300,
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: dotColor,
                  border: Border.all(color: borderColor, width: 2),
                  shape: BoxShape.circle,
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : isLocked
                        ? Icon(Icons.lock, size: 14, color: mutedColor)
                        : (isActive
                            ? const Icon(
                                Icons.play_arrow,
                                size: 16,
                                color: Colors.white,
                              )
                            : null),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: isLast ? Colors.transparent : Colors.grey.shade300,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isLocked ? const Color(0xFFF9FAFB) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isLocked
                          ? Colors.grey.shade200
                          : primaryColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: isLocked
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isLocked
                                    ? Colors.grey.shade600
                                    : primaryColor,
                              ),
                            ),
                          ),
                          if (isLocked)
                            Icon(Icons.lock_outline, color: mutedColor),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (actionLabel != null || (isActive && onTap != null))
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Row(
                            children: [
                              Text(
                                actionLabel ?? 'Start Practice',
                                style: const TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: primaryColor,
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
        ],
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.progress});

  final RitualProgressController progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Practice Mode',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (progress.mode == PracticeMode.locationBased)
                TextButton.icon(
                  onPressed: progress.resetLocationProgress,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reset'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SegmentedButton<PracticeMode>(
            segments: PracticeMode.values
                .map(
                  (mode) => ButtonSegment<PracticeMode>(
                    value: mode,
                    label: Text(mode.label),
                  ),
                )
                .toList(),
            selected: {progress.mode},
            onSelectionChanged: (selection) {
              progress.setMode(selection.first);
            },
          ),
          const SizedBox(height: 10),
          Text(
            progress.mode.description,
            style: TextStyle(color: Colors.grey.shade700, height: 1.35),
          ),
        ],
      ),
    );
  }
}
