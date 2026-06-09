import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/ritual_recommendation.dart';
import '../recommendation_controller.dart';
import 'practice_ui.dart';

class RecommendationPanel extends StatefulWidget {
  const RecommendationPanel({required this.ritualType, this.currentRadius, super.key});

  final RitualType ritualType;
  final double? currentRadius;

  @override
  State<RecommendationPanel> createState() => _RecommendationPanelState();
}

class RecommendationSheetButton extends StatefulWidget {
  const RecommendationSheetButton({required this.ritualType, this.currentRadius, super.key});

  final RitualType ritualType;
  final double? currentRadius;

  @override
  State<RecommendationSheetButton> createState() =>
      _RecommendationSheetButtonState();
}

class _RecommendationSheetButtonState extends State<RecommendationSheetButton> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecommendationController>().loadRecommendation(
        widget.ritualType,
        currentRadius: widget.currentRadius,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RecommendationController>();
    final recommendation = controller.recommendationFor(widget.ritualType);
    final isLoading = controller.isLoading(widget.ritualType);

    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: PracticeUi.forest,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.18),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: Colors.amber.shade100),
        ),
      ),
      onPressed: () => _showRecommendationSheet(context),
      icon: isLoading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.auto_awesome, size: 18, color: PracticeUi.forest),
      label: Text(
        recommendation == null ? 'ML Suggestion' : recommendation.label,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }

  void _showRecommendationSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: PracticeUi.mutedSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 180),
              child: RecommendationPanel(ritualType: widget.ritualType, currentRadius: widget.currentRadius),
            ),
          ),
        );
      },
    );
  }
}

class _RecommendationPanelState extends State<RecommendationPanel> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecommendationController>().loadRecommendation(
        widget.ritualType,
        currentRadius: widget.currentRadius,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RecommendationController>();
    final recommendation = controller.recommendationFor(widget.ritualType);
    final profile = controller.profileFor(widget.ritualType);
    final isLoading = controller.isLoading(widget.ritualType);
    final syncMessage = controller.syncMessage;

    if (isLoading && recommendation == null) {
      return PracticeSurfaceCard(
        padding: const EdgeInsets.all(18),
        backgroundColor: const Color(0xFFFFFBEB),
        borderColor: Colors.amber.shade100,
        borderRadius: PracticeUi.panelRadius,
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Loading ML suggestion...',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
    }
    if (recommendation == null) {
      return PracticeSurfaceCard(
        padding: const EdgeInsets.all(18),
        backgroundColor: const Color(0xFFFFFBEB),
        borderColor: Colors.amber.shade100,
        borderRadius: PracticeUi.panelRadius,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_graph, size: 18, color: PracticeUi.gold),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ML Suggestion',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'No recommendation is available yet. Try refreshing in a moment.',
              style: TextStyle(color: Colors.grey.shade700, height: 1.35),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => context
                    .read<RecommendationController>()
                    .refreshRecommendation(widget.ritualType, currentRadius: widget.currentRadius),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
              ),
            ),
          ],
        ),
      );
    }

    return PracticeSurfaceCard(
      padding: const EdgeInsets.all(18),
      backgroundColor: Colors.white,
      borderColor: PracticeUi.line,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PracticeIconBadge(
                icon: Icons.auto_awesome,
                backgroundColor: PracticeUi.warmSurface,
                foregroundColor: PracticeUi.deepGold,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${recommendation.ritualType.label} ML Suggestion',
                  style: const TextStyle(
                    color: PracticeUi.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              PracticeStatusChip(
                label: recommendation.label,
                backgroundColor: PracticeUi.greenSoft,
                foregroundColor: PracticeUi.forest,
                borderColor: PracticeUi.forest.withValues(alpha: 0.12),
              ),
              IconButton(
                tooltip: 'Refresh recommendation',
                visualDensity: VisualDensity.compact,
                onPressed: isLoading
                    ? null
                    : () => context
                          .read<RecommendationController>()
                          .refreshRecommendation(widget.ritualType, currentRadius: widget.currentRadius),
                icon: const Icon(Icons.refresh, size: 18),
              ),
            ],
          ),
          if (profile != null) ...[
            const SizedBox(height: 8),
            Text(
              'Based on age ${profile.age}, ${profile.abilityLevel.label}'
              '${profile.healthConditions.trim().isEmpty ? '' : ', ${profile.healthConditions.trim()}'}',
              style: const TextStyle(color: PracticeUi.body, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PracticeMetricChip(
                label: 'Distance',
                value:
                    '${recommendation.distanceMinMeters.round()}-${recommendation.distanceMaxMeters.round()} m',
                borderColor: PracticeUi.line,
              ),
              PracticeMetricChip(
                label: 'Pace',
                value:
                    '${recommendation.paceMinMps.toStringAsFixed(2)}-${recommendation.paceMaxMps.toStringAsFixed(2)} m/s',
                borderColor: PracticeUi.line,
              ),
              PracticeMetricChip(
                label: 'Time',
                value:
                    '${recommendation.timeMinMinutes.round()}-${recommendation.timeMaxMinutes.round()} min',
                borderColor: PracticeUi.line,
              ),
              PracticeMetricChip(
                label: 'Rest',
                value: 'Every ${recommendation.restEveryMinutes} min',
                borderColor: PracticeUi.line,
              ),
            ],
          ),
          if (recommendation.advice.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              recommendation.advice,
              style: const TextStyle(color: PracticeUi.ink, height: 1.4),
            ),
          ],
          if (controller.isCached(widget.ritualType) ||
              syncMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              controller.isCached(widget.ritualType)
                  ? 'Cached recommendation shown while refreshing.'
                  : syncMessage!,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              style: PracticeUi.primaryButtonStyle(
                backgroundColor: PracticeUi.deepGold,
              ),
              icon: const Icon(Icons.thumb_up_alt_outlined),
              label: const Text('Got it, thanks'),
            ),
          ),
        ],
      ),
    );
  }
}
