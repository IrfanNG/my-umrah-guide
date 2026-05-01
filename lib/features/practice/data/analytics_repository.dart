import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/ritual_recommendation.dart';

class AnalyticsRepository {
  AnalyticsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> logSession(RitualSessionLog log) {
    return _firestore.collection('ritual_sessions').add(log.toFirestore());
  }

  Stream<List<RitualSessionRecord>> watchSessions() {
    return _firestore
        .collection('ritual_sessions')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RitualSessionRecord.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> seedDemoData() async {
    final samples = <RitualSessionLog>[
      _sample('18-29', 'high', RitualType.tawaf, 2850, 1.05, 45),
      _sample('18-29', 'medium', RitualType.sai, 3150, 0.92, 57),
      _sample('30-44', 'medium', RitualType.tawaf, 2780, 0.86, 54),
      _sample('30-44', 'low', RitualType.sai, 3020, 0.68, 74),
      _sample('45-59', 'medium', RitualType.tawaf, 2900, 0.72, 67),
      _sample('45-59', 'low', RitualType.sai, 3180, 0.58, 91),
      _sample('60+', 'low', RitualType.tawaf, 2680, 0.48, 93),
      _sample('60+', 'medium', RitualType.sai, 3050, 0.61, 83),
    ];
    final batch = _firestore.batch();
    for (final sample in samples) {
      final ref = _firestore.collection('ritual_sessions').doc();
      batch.set(ref, sample.toFirestore());
    }
    await batch.commit();
  }

  RitualSessionLog _sample(
    String ageGroup,
    String abilityLevel,
    RitualType ritualType,
    double distance,
    double pace,
    double duration,
  ) {
    return RitualSessionLog(
      uid: 'seeded-demo',
      ritualType: ritualType,
      ageGroup: ageGroup,
      abilityLevel: abilityLevel,
      distanceMeters: distance,
      averagePaceMps: pace,
      durationMinutes: duration,
      recommendationSnapshot: const {'source': 'seeded-demo'},
    );
  }
}

class RitualSessionRecord {
  const RitualSessionRecord({
    required this.ritualType,
    required this.ageGroup,
    required this.abilityLevel,
    required this.distanceMeters,
    required this.averagePaceMps,
    required this.durationMinutes,
  });

  final RitualType ritualType;
  final String ageGroup;
  final String abilityLevel;
  final double distanceMeters;
  final double averagePaceMps;
  final double durationMinutes;

  double get paceDistanceRatio {
    if (distanceMeters == 0) return 0;
    return averagePaceMps / distanceMeters;
  }

  factory RitualSessionRecord.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return RitualSessionRecord(
      ritualType: RitualType.fromValue(data['ritualType'] as String?),
      ageGroup: data['ageGroup'] as String? ?? 'Unknown',
      abilityLevel: data['abilityLevel'] as String? ?? 'medium',
      distanceMeters: (data['distanceMeters'] as num?)?.toDouble() ?? 0,
      averagePaceMps: (data['averagePaceMps'] as num?)?.toDouble() ?? 0,
      durationMinutes: (data['durationMinutes'] as num?)?.toDouble() ?? 0,
    );
  }
}
