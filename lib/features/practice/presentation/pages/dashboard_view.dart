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
      if (!progress.isLoaded) progress.load();

      final background = context.read<BackgroundGeofenceController>();
      if (!background.isLoaded) background.load();

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
      backgroundColor: PracticeUi.warmSurface,
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => context.read<AuthController>().signOut(),
            icon: const Icon(Icons.logout, color: PracticeUi.forest),
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
                _DashboardHeader(profile: widget.profile, progress: progress),
                const SizedBox(height: 18),
                _NextStepCard(profile: widget.profile, progress: progress),
                const SizedBox(height: 18),
                _RitualTimeline(progress: progress),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 760;
                    final cards = [
                      _ModeSelector(progress: progress),
                      _BackgroundMonitoringCard(controller: background),
                      _AdaptiveSchedulingCard(controller: adaptive),
                    ];
                    if (!isWide) {
                      return Column(
                        children: cards
                            .map(
                              (card) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: card,
                              ),
                            )
                            .toList(),
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: cards
                          .map(
                            (card) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: card,
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.profile, required this.progress});

  final UserProfile profile;
  final RitualProgressController progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Umrah Practice',
          style: TextStyle(
            color: PracticeUi.forest,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: PracticeUi.surfaceDecoration(
                borderRadius: PracticeUi.compactRadius,
                borderColor: PracticeUi.line,
                boxShadow: const [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: PracticeUi.greenSoft,
                    child: Icon(
                      Icons.person,
                      size: 18,
                      color: PracticeUi.forest,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Age ${profile.age} · ${profile.abilityLevel.label}',
                    style: const TextStyle(
                      color: PracticeUi.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            PracticeStatusChip(
              label: progress.mode == PracticeMode.manual
                  ? 'Manual Mode'
                  : 'Location-Based',
              icon: progress.mode == PracticeMode.manual
                  ? Icons.edit_location_alt
                  : Icons.gps_fixed,
              backgroundColor: PracticeUi.greenSoft,
              borderColor: PracticeUi.forest.withValues(alpha: 0.14),
              foregroundColor: PracticeUi.forest,
            ),
          ],
        ),
      ],
    );
  }
}

class _NextStepCard extends StatelessWidget {
  const _NextStepCard({required this.profile, required this.progress});

  final UserProfile profile;
  final RitualProgressController progress;

  @override
  Widget build(BuildContext context) {
    final canStartTawaf = progress.canOpenTawaf;
    final canStartSai = progress.canOpenSai;
    final title = progress.tawafCompleted ? 'Sa\'i' : 'Tawaf';
    final subtitle = canStartSai || canStartTawaf
        ? 'Ready to start'
        : 'Complete Miqat/Niyyah first';
    final route = progress.tawafCompleted
        ? '/sai-simulator'
        : '/tawaf-simulator';
    final canOpen = progress.tawafCompleted ? canStartSai : canStartTawaf;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Next Step',
          style: TextStyle(
            color: PracticeUi.ink,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: PracticeUi.greenGradient,
            borderRadius: PracticeUi.cardRadius,
            boxShadow: [
              BoxShadow(
                color: PracticeUi.forest.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: SizedBox(
                  width: 86,
                  height: 86,
                  child: Image.asset(
                    PracticeUi.kaabahHeroAsset,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          canOpen ? Icons.circle : Icons.lock_outline,
                          size: 10,
                          color: canOpen ? PracticeUi.green : PracticeUi.sand,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.86),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: canOpen
                          ? () => Navigator.pushNamed(context, route)
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        disabledBackgroundColor: Colors.white.withValues(
                          alpha: 0.45,
                        ),
                        foregroundColor: PracticeUi.forest,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            progress.tawafCompleted
                                ? 'Start Sa\'i'
                                : 'Start Tawaf',
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RitualTimeline extends StatelessWidget {
  const _RitualTimeline({required this.progress});

  final RitualProgressController progress;

  @override
  Widget build(BuildContext context) {
    return PracticeSurfaceCard(
      padding: const EdgeInsets.all(16),
      borderColor: PracticeUi.line,
      boxShadow: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ritual Timeline',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: PracticeUi.ink,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _TimelineNode(
                label: 'Miqat /\nNiyyah',
                icon: Icons.mosque_outlined,
                isActive:
                    progress.mode == PracticeMode.locationBased &&
                    !progress.niyyahCompleted,
                isCompleted:
                    progress.mode == PracticeMode.manual ||
                    progress.niyyahCompleted,
                onTap:
                    progress.mode == PracticeMode.locationBased &&
                        !progress.niyyahCompleted
                    ? progress.markNiyyahCompleted
                    : null,
              ),
              const _TimelineArrow(),
              _TimelineNode(
                label: 'Tawaf',
                icon: Icons.my_location,
                isActive: progress.canOpenTawaf && !progress.tawafCompleted,
                isCompleted: progress.tawafCompleted,
                isLocked: !progress.canOpenTawaf,
                onTap: progress.canOpenTawaf
                    ? () => Navigator.pushNamed(context, '/tawaf-simulator')
                    : null,
              ),
              const _TimelineArrow(),
              _TimelineNode(
                label: 'Sa\'i',
                icon: Icons.directions_walk,
                isActive: progress.canOpenSai,
                isLocked: !progress.canOpenSai,
                onTap: progress.canOpenSai
                    ? () => Navigator.pushNamed(context, '/sai-simulator')
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineNode extends StatelessWidget {
  const _TimelineNode({
    required this.label,
    required this.icon,
    this.isActive = false,
    this.isCompleted = false,
    this.isLocked = false,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final bool isCompleted;
  final bool isLocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isCompleted || isActive
        ? PracticeUi.deepGold
        : isLocked
        ? Colors.grey.shade500
        : PracticeUi.forest;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isActive || isCompleted
                    ? PracticeUi.sand
                    : const Color(0xFFF4EFE6),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.18)),
              ),
              child: Icon(
                isCompleted
                    ? Icons.check_circle
                    : (isLocked ? Icons.lock : icon),
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: PracticeUi.ink,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineArrow extends StatelessWidget {
  const _TimelineArrow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 28),
      child: Icon(Icons.arrow_forward_rounded, color: PracticeUi.deepGold),
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

    return _DashboardUtilityCard(
      icon: Icons.event_available_outlined,
      title: 'Adaptive Scheduling',
      subtitle: isLoading
          ? 'Refreshing plan'
          : tawaf?.recommendedWindow ??
                sai?.recommendedWindow ??
                'Personalized plan',
      action: IconButton(
        tooltip: 'Refresh crowd advice',
        onPressed: isLoading
            ? null
            : () {
                controller.loadAdvice('tawaf');
                controller.loadAdvice('sai');
              },
        icon: const Icon(Icons.refresh, size: 18),
      ),
      footer: controller.errorMessage ?? _adviceSummary(tawaf, sai),
    );
  }

  String _adviceSummary(
    AdaptiveScheduleAdvice? tawaf,
    AdaptiveScheduleAdvice? sai,
  ) {
    final parts = <String>[];
    if (tawaf != null) parts.add('Tawaf ${tawaf.crowdLevel.label}');
    if (sai != null) parts.add('Sa\'i ${sai.crowdLevel.label}');
    return parts.isEmpty
        ? 'Crowd advice loads with offline fallback.'
        : parts.join(' · ');
  }
}

class _BackgroundMonitoringCard extends StatelessWidget {
  const _BackgroundMonitoringCard({required this.controller});

  final BackgroundGeofenceController controller;

  @override
  Widget build(BuildContext context) {
    return _DashboardUtilityCard(
      icon: Icons.radar_rounded,
      title: 'Background Geofence',
      subtitle: controller.isEnabled ? 'Readiness monitoring' : 'Off for now',
      action: Switch(
        value: controller.isEnabled,
        onChanged: controller.isLoaded ? controller.setEnabled : null,
        activeThumbColor: PracticeUi.forest,
      ),
      footer: controller.statusMessage,
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.progress});

  final RitualProgressController progress;

  @override
  Widget build(BuildContext context) {
    return _DashboardUtilityCard(
      icon: Icons.shield_outlined,
      title: 'Practice Mode',
      subtitle: progress.mode == PracticeMode.manual
          ? 'Manual practice with guidance'
          : 'Follow Miqat sequence',
      footer: progress.mode.description,
      action: PopupMenuButton<PracticeMode>(
        tooltip: 'Change practice mode',
        initialValue: progress.mode,
        onSelected: progress.setMode,
        itemBuilder: (context) => PracticeMode.values
            .map((mode) => PopupMenuItem(value: mode, child: Text(mode.label)))
            .toList(),
        child: const Icon(Icons.keyboard_arrow_down_rounded),
      ),
    );
  }
}

class _DashboardUtilityCard extends StatelessWidget {
  const _DashboardUtilityCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.footer,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String footer;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return PracticeSurfaceCard(
      padding: const EdgeInsets.all(14),
      borderColor: PracticeUi.line,
      borderRadius: PracticeUi.panelRadius,
      boxShadow: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PracticeIconBadge(icon: icon, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: PracticeUi.forest,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: PracticeUi.body,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: 10),
          Text(
            footer,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: PracticeUi.body,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
