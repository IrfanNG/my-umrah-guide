import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_umrah_guide/features/practice/data/crowd_density_repository.dart';
import 'package:my_umrah_guide/features/practice/domain/adaptive_schedule.dart';

void main() {
  test('parses adaptive scheduling advice from API response', () async {
    final repository = CrowdDensityRepository(
      client: MockClient(
        (_) async => http.Response('''
{
  "ritualType": "tawaf",
  "crowdLevel": "high",
  "densityScore": 0.84,
  "recommendedWindow": "Delay if possible",
  "rerouteAdvice": "Use outer lanes.",
  "generatedAt": "2026-05-02T10:00:00Z"
}
''', 200),
      ),
    );

    final advice = await repository.getAdvice('tawaf');

    expect(advice.ritualType, 'tawaf');
    expect(advice.crowdLevel, CrowdLevel.high);
    expect(advice.shouldReroute, isTrue);
    expect(advice.rerouteAdvice, 'Use outer lanes.');
  });

  test('falls back to deterministic low-crowd advice when API fails', () async {
    final repository = CrowdDensityRepository(
      now: () => DateTime(2026, 5, 2, 2),
      client: MockClient((_) async => http.Response('offline', 500)),
    );

    final advice = await repository.getAdvice('sai');

    expect(advice.ritualType, 'sai');
    expect(advice.crowdLevel, CrowdLevel.low);
    expect(advice.shouldReroute, isFalse);
    expect(advice.recommendedWindow, 'Current window is suitable');
  });

  test('fallback recommends rerouting during high-crowd hours', () async {
    final repository = CrowdDensityRepository(
      now: () => DateTime(2026, 5, 2, 13),
      client: MockClient((_) async => throw Exception('offline')),
    );

    final advice = await repository.getAdvice('tawaf');

    expect(advice.crowdLevel, CrowdLevel.high);
    expect(advice.shouldReroute, isTrue);
    expect(advice.rerouteAdvice, contains('outer lanes'));
  });
}
