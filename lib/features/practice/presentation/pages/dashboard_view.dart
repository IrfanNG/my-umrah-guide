import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/adaptive_schedule.dart';
import '../../domain/practice_mode.dart';
import '../../domain/user_profile.dart';
import '../adaptive_schedule_controller.dart';
import '../auth_controller.dart';
import '../background_geofence_controller.dart';
import '../ritual_progress_controller.dart';
import '../widgets/practice_ui.dart';

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
      backgroundColor: PracticeUi.mutedSurface,
      appBar: AppBar(
        title: const Text('Umrah Practice'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
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
        padding: PracticeUi.pagePadding,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PracticeSectionHeader(
                  title: 'Journey Steps',
                  subtitle:
                      '${widget.profile.age} years old · ${widget.profile.abilityLevel.label}',
                  trailing: PracticeStatusChip(
                    label: progress.mode == PracticeMode.manual
                        ? 'Manual mode'
                        : 'Location-based',
                    icon: progress.mode == PracticeMode.manual
                        ? Icons.edit_location_alt
                        : Icons.gps_fixed,
                    backgroundColor: Colors.white,
                    borderColor: Colors.amber.shade100,
                    foregroundColor: PracticeUi.gold,
                  ),
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
    final statusLabel = isCompleted
        ? 'Completed'
        : isLocked
        ? 'Locked'
        : (isActive ? 'Ready' : 'Pending');
    final statusIcon = isCompleted
        ? Icons.check_circle_outline
        : isLocked
        ? Icons.lock_outline
        : (isActive ? Icons.play_circle_outline : Icons.radio_button_unchecked);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: Colors.transparent,
        borderRadius: PracticeUi.cardRadius,
        child: InkWell(
          onTap: isLocked ? null : onTap,
          borderRadius: PracticeUi.cardRadius,
          child: PracticeSurfaceCard(
            backgroundColor: isLocked ? const Color(0xFFF9FAFB) : Colors.white,
            borderColor: isCompleted
                ? secondaryColor.withValues(alpha: 0.24)
                : isLocked
                ? Colors.grey.shade200
                : primaryColor.withValues(alpha: 0.22),
            boxShadow: isLocked
                ? const []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 2,
                      height: isFirst ? 10 : 20,
                      color: isFirst
                          ? Colors.transparent
                          : Colors.grey.shade300,
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
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
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
                    Container(
                      width: 2,
                      height: isLast ? 10 : 32,
                      color: isLast ? Colors.transparent : Colors.grey.shade300,
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
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
                                fontWeight: FontWeight.w800,
                                color: isLocked
                                    ? Colors.grey.shade600
                                    : PracticeUi.ink,
                              ),
                            ),
                          ),
                          PracticeStatusChip(
                            label: statusLabel,
                            icon: statusIcon,
                            backgroundColor: isCompleted
                                ? secondaryColor.withValues(alpha: 0.12)
                                : isLocked
                                ? Colors.white
                                : primaryColor.withValues(alpha: 0.08),
                            foregroundColor: isCompleted
                                ? secondaryColor
                                : isLocked
                                ? Colors.grey.shade600
                                : primaryColor,
                            borderColor: isCompleted
                                ? secondaryColor.withValues(alpha: 0.2)
                                : isLocked
                                ? Colors.grey.shade200
                                : primaryColor.withValues(alpha: 0.16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.35,
                        ),
                      ),
                      if (actionLabel != null || (isActive && onTap != null))
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Row(
                            children: [
                              Text(
                                actionLabel ?? 'Start Practice',
                                style: TextStyle(
                                  color: isLocked
                                      ? Colors.grey.shade500
                                      : PracticeUi.gold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: isLocked
                                    ? Colors.grey.shade500
                                    : primaryColor,
                              ),
                            ],
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

    return PracticeSurfaceCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: Colors.white,
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
                  style: TextStyle(fontWeight: FontWeight.w800),
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

    return PracticeSurfaceCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: isReady ? Colors.white : const Color(0xFFFFFCF2),
      borderColor: isReady ? Colors.green.shade200 : Colors.amber.shade100,
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
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              PracticeStatusChip(
                label: controller.isEnabled ? 'Enabled' : 'Off',
                icon: controller.isEnabled ? Icons.toggle_on : Icons.toggle_off,
                backgroundColor: controller.isEnabled
                    ? primaryColor.withValues(alpha: 0.08)
                    : Colors.white,
                foregroundColor:
                    controller.isEnabled ? primaryColor : Colors.grey.shade700,
                borderColor: controller.isEnabled
                    ? primaryColor.withValues(alpha: 0.16)
                    : Colors.grey.shade200,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            controller.statusMessage,
            style: TextStyle(color: Colors.grey.shade700, height: 1.35),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PracticeStatusChip(
                label: isReady ? 'Ready' : 'Waiting',
                icon: isReady ? Icons.check_circle_outline : Icons.info_outline,
                backgroundColor:
                    isReady ? Colors.green.shade50 : Colors.orange.shade50,
                foregroundColor:
                    isReady ? Colors.green.shade800 : Colors.orange.shade800,
                borderColor:
                    isReady ? Colors.green.shade100 : Colors.orange.shade100,
              ),
              const PracticeStatusChip(
                label: 'Demo-safe',
                icon: Icons.school_outlined,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'This stays opt-in and ready for the demo. Full always-on native background service remains a production extension, not a Phase 4 blocker.',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: controller.isLoaded
                  ? () => controller.setEnabled(!controller.isEnabled)
                  : null,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(controller.isEnabled ? 'Turn off' : 'Turn on'),
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
    return PracticeSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Practice Mode',
                  style: TextStyle(fontWeight: FontWeight.w800),
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
