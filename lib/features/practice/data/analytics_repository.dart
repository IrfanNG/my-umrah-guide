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

  Stream<List<RitualSessionRecord>> watchUserSessions(String uid) {
    return _firestore
        .collection('ritual_sessions')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RitualSessionRecord.fromFirestore(doc))
              .toList(),
        );
  }

  Future<List<RitualSessionRecord>> getUserSessions({
    required String uid,
    required RitualType ritualType,
    int limit = 5,
  }) async {
    final snapshot = await _firestore
        .collection('ritual_sessions')
        .where('uid', isEqualTo: uid)
        .limit(50)
        .get();

    final records = snapshot.docs
        .map((doc) => RitualSessionRecord.fromFirestore(doc))
        .where((record) => record.ritualType == ritualType)
        .toList();

    records.sort((a, b) {
      final aDate = a.completedAt ?? a.startedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.completedAt ?? b.startedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return records.take(limit).toList();
  }

  Future<void> seedDemoData() async {
    final now = DateTime.now();
    final samples = <RitualSessionLog>[
      _sample('18-29', 'high', RitualType.tawaf, 2850, 1.05, 45, now.subtract(const Duration(days: 1))),
      _sample('18-29', 'medium', RitualType.sai, 3150, 0.92, 57, now.subtract(const Duration(days: 1))),
      _sample('30-44', 'medium', RitualType.tawaf, 2780, 0.86, 54, now.subtract(const Duration(days: 2))),
      _sample('30-44', 'low', RitualType.sai, 3020, 0.68, 74, now.subtract(const Duration(days: 2))),
      _sample('45-59', 'medium', RitualType.tawaf, 2900, 0.72, 67, now.subtract(const Duration(days: 3))),
      _sample('45-59', 'low', RitualType.sai, 3180, 0.58, 91, now.subtract(const Duration(days: 3))),
      _sample('60+', 'low', RitualType.tawaf, 2680, 0.48, 93, now.subtract(const Duration(days: 4))),
      _sample('60+', 'medium', RitualType.sai, 3050, 0.61, 83, now.subtract(const Duration(days: 4))),
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
    DateTime date,
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
      startedAt: date.subtract(const Duration(minutes: 30)),
      completedAt: date,
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
    this.startedAt,
    this.completedAt,
  });

  final RitualType ritualType;
  final String ageGroup;
  final String abilityLevel;
  final double distanceMeters;
  final double averagePaceMps;
  final double durationMinutes;
  final DateTime? startedAt;
  final DateTime? completedAt;

  double get paceDistanceRatio {
    if (distanceMeters == 0) return 0;
    return averagePaceMps / distanceMeters;
  }

  String get formattedDate {
    final date = completedAt ?? startedAt;
    if (date == null) return '';
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final h = (date.hour % 12 == 0 ? 12 : date.hour % 12).toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    final amPm = date.hour < 12 ? 'AM' : 'PM';
    return '${date.year}-$m-$d $h:$min $amPm';
  }

  String get formattedDuration {
    final totalMin = durationMinutes.round();
    final hours = totalMin ~/ 60;
    final mins = totalMin % 60;
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }

  String get formattedPace {
    return '${averagePaceMps.toStringAsFixed(2)} m/s';
  }

  String get formattedDistance {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(2)} km';
    }
    return '${distanceMeters.round()} m';
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
      startedAt: _parseTimestamp(data['startedAt']),
      completedAt: _parseTimestamp(data['completedAt']),
    );
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
