enum CrowdLevel {
  low,
  moderate,
  high;

  String get label {
    switch (this) {
      case CrowdLevel.low:
        return 'Low crowd';
      case CrowdLevel.moderate:
        return 'Moderate crowd';
      case CrowdLevel.high:
        return 'High crowd';
    }
  }

  static CrowdLevel fromValue(String? value) {
    return CrowdLevel.values.firstWhere(
      (level) => level.name == value,
      orElse: () => CrowdLevel.moderate,
    );
  }
}

class AdaptiveScheduleAdvice {
  const AdaptiveScheduleAdvice({
    required this.ritualType,
    required this.crowdLevel,
    required this.densityScore,
    required this.recommendedWindow,
    required this.rerouteAdvice,
    required this.generatedAt,
  });

  final String ritualType;
  final CrowdLevel crowdLevel;
  final double densityScore;
  final String recommendedWindow;
  final String rerouteAdvice;
  final DateTime generatedAt;

  bool get shouldReroute => crowdLevel == CrowdLevel.high;

  Map<String, dynamic> toJson() {
    return {
      'ritualType': ritualType,
      'crowdLevel': crowdLevel.name,
      'densityScore': densityScore,
      'recommendedWindow': recommendedWindow,
      'rerouteAdvice': rerouteAdvice,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory AdaptiveScheduleAdvice.fromJson(Map<String, dynamic> json) {
    return AdaptiveScheduleAdvice(
      ritualType: json['ritualType'] as String? ?? 'tawaf',
      crowdLevel: CrowdLevel.fromValue(json['crowdLevel'] as String?),
      densityScore: (json['densityScore'] as num?)?.toDouble() ?? 0.5,
      recommendedWindow:
          json['recommendedWindow'] as String? ?? 'Continue with caution',
      rerouteAdvice: json['rerouteAdvice'] as String? ?? '',
      generatedAt:
          DateTime.tryParse(json['generatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
