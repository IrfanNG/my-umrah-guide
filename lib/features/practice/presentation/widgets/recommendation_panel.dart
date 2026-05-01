import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/ritual_recommendation.dart';
import '../recommendation_controller.dart';

class RecommendationPanel extends StatefulWidget {
  const RecommendationPanel({required this.ritualType, super.key});

  final RitualType ritualType;

  @override
  State<RecommendationPanel> createState() => _RecommendationPanelState();
}

class _RecommendationPanelState extends State<RecommendationPanel> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecommendationController>().loadRecommendation(
            widget.ritualType,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RecommendationController>();
    final recommendation = controller.recommendationFor(widget.ritualType);
    final profile = controller.profileFor(widget.ritualType);
    final isLoading = controller.isLoading(widget.ritualType);

    if (isLoading && recommendation == null) {
      return const LinearProgressIndicator(minHeight: 2);
    }
    if (recommendation == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        border: Border(bottom: BorderSide(color: Colors.amber.shade100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_graph,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '${recommendation.ritualType.label} ML Suggestion',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                recommendation.label,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Refresh recommendation',
                visualDensity: VisualDensity.compact,
                onPressed: isLoading
                    ? null
                    : () => context
                        .read<RecommendationController>()
                        .refreshRecommendation(widget.ritualType),
                icon: const Icon(Icons.refresh, size: 18),
              ),
            ],
          ),
          if (profile != null) ...[
            const SizedBox(height: 4),
            Text(
              'Based on age ${profile.age}, ${profile.abilityLevel.label}'
              '${profile.healthConditions.trim().isEmpty ? '' : ', ${profile.healthConditions.trim()}'}',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricChip(
                label: 'Distance',
                value:
                    '${recommendation.distanceMinMeters.round()}-${recommendation.distanceMaxMeters.round()} m',
              ),
              _MetricChip(
                label: 'Pace',
                value:
                    '${recommendation.paceMinMps.toStringAsFixed(2)}-${recommendation.paceMaxMps.toStringAsFixed(2)} m/s',
              ),
              _MetricChip(
                label: 'Time',
                value:
                    '${recommendation.timeMinMinutes.round()}-${recommendation.timeMaxMinutes.round()} min',
              ),
              _MetricChip(
                label: 'Rest',
                value: 'Every ${recommendation.restEveryMinutes} min',
              ),
            ],
          ),
          if (recommendation.advice.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              recommendation.advice,
              style: TextStyle(color: Colors.grey.shade800, height: 1.35),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
