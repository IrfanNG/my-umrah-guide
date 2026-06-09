import 'package:cloud_firestore/cloud_firestore.dart';

enum RitualType {
  tawaf,
  sai;

  String get label => this == RitualType.tawaf ? 'Tawaf' : 'Sa\'i';

  static RitualType fromValue(String? value) {
    return RitualType.values.firstWhere(
      (ritual) => ritual.name == value,
      orElse: () => RitualType.tawaf,
    );
  }
}

class RitualRecommendation {
  const RitualRecommendation({
    required this.ritualType,
    required this.distanceMinMeters,
    required this.distanceMaxMeters,
    required this.paceMinMps,
    required this.paceMaxMps,
    required this.timeMinMinutes,
    required this.timeMaxMinutes,
    required this.restEveryMinutes,
    required this.label,
    required this.advice,
  });

  final RitualType ritualType;
  final double distanceMinMeters;
  final double distanceMaxMeters;
  final double paceMinMps;
  final double paceMaxMps;
  final double timeMinMinutes;
  final double timeMaxMinutes;
  final int restEveryMinutes;
  final String label;
  final String advice;

  Map<String, dynamic> toJson() {
    return {
      'ritualType': ritualType.name,
      'distanceMinMeters': distanceMinMeters,
      'distanceMaxMeters': distanceMaxMeters,
      'paceMinMps': paceMinMps,
      'paceMaxMps': paceMaxMps,
      'timeMinMinutes': timeMinMinutes,
      'timeMaxMinutes': timeMaxMinutes,
      'restEveryMinutes': restEveryMinutes,
      'label': label,
      'advice': advice,
    };
  }

  factory RitualRecommendation.fromJson(Map<String, dynamic> json) {
    return RitualRecommendation(
      ritualType: RitualType.fromValue(json['ritualType'] as String?),
      distanceMinMeters: (json['distanceMinMeters'] as num).toDouble(),
      distanceMaxMeters: (json['distanceMaxMeters'] as num).toDouble(),
      paceMinMps: (json['paceMinMps'] as num).toDouble(),
      paceMaxMps: (json['paceMaxMps'] as num).toDouble(),
      timeMinMinutes: (json['timeMinMinutes'] as num).toDouble(),
      timeMaxMinutes: (json['timeMaxMinutes'] as num).toDouble(),
      restEveryMinutes: (json['restEveryMinutes'] as num).toInt(),
      label: json['label'] as String? ?? 'Personalized pace',
      advice: json['advice'] as String? ?? '',
    );
  }

  factory RitualRecommendation.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return RitualRecommendation.fromJson(doc.data() ?? <String, dynamic>{});
  }
}

class RitualSessionLog {
  const RitualSessionLog({
    required this.uid,
    required this.ritualType,
    required this.ageGroup,
    required this.abilityLevel,
    required this.distanceMeters,
    required this.averagePaceMps,
    required this.durationMinutes,
    required this.recommendationSnapshot,
    required this.startedAt,
    required this.completedAt,
  });

  final String uid;
  final RitualType ritualType;
  final String ageGroup;
  final String abilityLevel;
  final double distanceMeters;
  final double averagePaceMps;
  final double durationMinutes;
  final Map<String, dynamic> recommendationSnapshot;
  final DateTime startedAt;
  final DateTime completedAt;

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'ritualType': ritualType.name,
      'ageGroup': ageGroup,
      'abilityLevel': abilityLevel,
      'distanceMeters': distanceMeters,
      'averagePaceMps': averagePaceMps,
      'durationMinutes': durationMinutes,
      'recommendationSnapshot': recommendationSnapshot,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'ritualType': ritualType.name,
      'ageGroup': ageGroup,
      'abilityLevel': abilityLevel,
      'distanceMeters': distanceMeters,
      'averagePaceMps': averagePaceMps,
      'durationMinutes': durationMinutes,
      'paceDistanceRatio': distanceMeters == 0
          ? 0
          : averagePaceMps / distanceMeters,
      'recommendationSnapshot': recommendationSnapshot,
      'startedAt': startedAt,
      'completedAt': completedAt,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory RitualSessionLog.fromJson(Map<String, dynamic> json) {
    return RitualSessionLog(
      uid: json['uid'] as String? ?? '',
      ritualType: RitualType.fromValue(json['ritualType'] as String?),
      ageGroup: json['ageGroup'] as String? ?? 'Unknown',
      abilityLevel: json['abilityLevel'] as String? ?? 'medium',
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0,
      averagePaceMps: (json['averagePaceMps'] as num?)?.toDouble() ?? 0,
      durationMinutes: (json['durationMinutes'] as num?)?.toDouble() ?? 0,
      recommendationSnapshot: Map<String, dynamic>.from(
        json['recommendationSnapshot'] as Map? ?? <String, dynamic>{},
      ),
      startedAt: _parseDate(json['startedAt']),
      completedAt: _parseDate(json['completedAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    if (value is Timestamp) {
      return value.toDate();
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
