import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/adaptive_schedule.dart';
import '../../domain/practice_mode.dart';
import '../../domain/user_profile.dart';
import '../adaptive_schedule_controller.dart';
import '../auth_controller.dart';
import '../background_geofence_controller.dart';
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
      final background = context.read<BackgroundGeofenceController>();
      if (!background.isLoaded) {
        background.load();
      }
      final adaptive = context.read<AdaptiveScheduleController>();
      adaptive.loadAdvice('tawaf');
      adaptive.loadAdvice('sai');
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<RitualProgressController>();
    final background = context.watch<BackgroundGeofenceController>();
    final adaptive = context.watch<AdaptiveScheduleController>();

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
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.profile.age} years old | ${widget.profile.abilityLevel.label}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 20),
            _ModeSelector(progress: progress),
            const SizedBox(height: 16),
            _BackgroundMonitoringCard(controller: background),
            const SizedBox(height: 16),
            _AdaptiveSchedulingCard(controller: adaptive),
            const SizedBox(height: 28),
            _buildTimelineItem(
              context,
              title: 'Umrah Intent at Miqat',
              description: progress.mode == PracticeMode.manual
                  ? 'Manual mode keeps this checkpoint open for revision.'
                  : 'Complete Niyyah before unlocking Tawaf.',
              isCompleted:
                  progress.mode == PracticeMode.manual ||
                  progress.niyyahCompleted,
              isActive:
                  progress.mode == PracticeMode.locationBased &&
                  !progress.niyyahCompleted,
              isFirst: true,
              actionLabel:
                  progress.mode == PracticeMode.locationBased &&
                      !progress.niyyahCompleted
                  ? 'Mark Niyyah Done'
                  : null,
              onTap:
                  progress.mode == PracticeMode.locationBased &&
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

class _AdaptiveSchedulingCard extends StatelessWidget {
  const _AdaptiveSchedulingCard({required this.controller});

  final AdaptiveScheduleController controller;

  @override
  Widget build(BuildContext context) {
    final tawaf = controller.adviceFor('tawaf');
    final sai = controller.adviceFor('sai');
    final isLoading =
        controller.isLoading('tawaf') || controller.isLoading('sai');

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
              Icon(
                Icons.manage_history_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Adaptive Scheduling',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                tooltip: 'Refresh crowd advice',
                onPressed: isLoading
                    ? null
                    : () {
                        controller.loadAdvice('tawaf');
                        controller.loadAdvice('sai');
                      },
                icon: const Icon(Icons.refresh, size: 18),
              ),
            ],
          ),
          if (isLoading && tawaf == null && sai == null)
            const LinearProgressIndicator(minHeight: 2)
          else ...[
            if (tawaf != null) _ScheduleAdviceRow(advice: tawaf),
            if (sai != null) _ScheduleAdviceRow(advice: sai),
          ],
          if (controller.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              controller.errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScheduleAdviceRow extends StatelessWidget {
  const _ScheduleAdviceRow({required this.advice});

  final AdaptiveScheduleAdvice advice;

  @override
  Widget build(BuildContext context) {
    final color = switch (advice.crowdLevel) {
      CrowdLevel.low => Colors.green,
      CrowdLevel.moderate => Colors.orange,
      CrowdLevel.high => Colors.red,
    };
    final ritualLabel = advice.ritualType == 'sai' ? 'Sa\'i' : 'Tawaf';

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$ritualLabel: ${advice.crowdLevel.label} • ${advice.recommendedWindow}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  advice.rerouteAdvice,
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

class _BackgroundMonitoringCard extends StatelessWidget {
  const _BackgroundMonitoringCard({required this.controller});

  final BackgroundGeofenceController controller;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isReady = controller.readiness == BackgroundGeofenceReadiness.ready;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isReady ? Colors.green.shade200 : Colors.amber.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.radar_rounded, color: primaryColor),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Background Geofence Readiness',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Switch(
                value: controller.isEnabled,
                onChanged: controller.isLoaded
                    ? (value) => controller.setEnabled(value)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            controller.statusMessage,
            style: TextStyle(color: Colors.grey.shade700, height: 1.35),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                isReady ? Icons.check_circle : Icons.info_outline,
                color: isReady ? Colors.green.shade700 : Colors.orange.shade700,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isReady
                      ? 'Ready for FYP demo monitoring.'
                      : 'Opt-in mode; full native always-on service remains a future production step.',
                  style: TextStyle(
                    color: isReady
                        ? Colors.green.shade800
                        : Colors.orange.shade800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
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
