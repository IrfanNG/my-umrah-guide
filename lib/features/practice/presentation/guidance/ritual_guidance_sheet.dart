import 'package:flutter/material.dart';

import 'ritual_guidance.dart';
import '../widgets/practice_ui.dart';

class RitualGuidanceSheet extends StatelessWidget {
  const RitualGuidanceSheet({super.key, required this.guidance});

  final RitualGuidance guidance;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: PracticeSurfaceCard(
          padding: const EdgeInsets.all(20),
          backgroundColor: Colors.white,
          borderColor: PracticeUi.line,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const PracticeIconBadge(
                    icon: Icons.menu_book_rounded,
                    backgroundColor: PracticeUi.warmSurface,
                    foregroundColor: PracticeUi.deepGold,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      guidance.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: PracticeUi.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close guidance',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: PracticeUi.body),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                guidance.body,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Color(0xFF4B5563),
                ),
              ),
              if (guidance.ritualText != null) ...[
                const SizedBox(height: 14),
                PracticeSurfaceCard(
                  padding: const EdgeInsets.all(14),
                  backgroundColor: PracticeUi.warmSurface,
                  borderColor: PracticeUi.line,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guidance.ritualLabel ?? 'Panduan ritual',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: PracticeUi.deepGold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        guidance.ritualText!,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ...guidance.steps.map(
                (step) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: PracticeUi.forest,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          step,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: PracticeUi.primaryButtonStyle(
                    backgroundColor: PracticeUi.deepGold,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text('Got it', textAlign: TextAlign.center),
                      ),
                      Icon(Icons.check_circle_outline),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
