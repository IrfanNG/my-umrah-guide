import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/analytics_repository.dart';
import '../../domain/ritual_recommendation.dart';
import '../auth_controller.dart';
import '../widgets/practice_ui.dart';

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = AnalyticsRepository();
    return Scaffold(
      backgroundColor: PracticeUi.mutedSurface,
      appBar: AppBar(
        title: const Text('Admin Analytics'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'Seed demo data',
            onPressed: repository.seedDemoData,
            icon: const Icon(Icons.dataset),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => context.read<AuthController>().signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<List<RitualSessionRecord>>(
        stream: repository.watchSessions(),
        builder: (context, snapshot) {
          final sessions = snapshot.data ?? const <RitualSessionRecord>[];
          if (snapshot.connectionState == ConnectionState.waiting &&
              sessions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (sessions.isEmpty) {
            return _EmptyAnalytics(onSeed: repository.seedDemoData);
          }
          return _AnalyticsContent(sessions: sessions);
        },
      ),
    );
  }
}

class _EmptyAnalytics extends StatelessWidget {
  const _EmptyAnalytics({required this.onSeed});

  final VoidCallback onSeed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: PracticeSurfaceCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.bar_chart_rounded,
                  size: 64,
                  color: PracticeUi.gold,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No analytics data yet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: PracticeUi.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Seed demo data to preview aggregate graphs for FYP.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onSeed,
                  icon: const Icon(Icons.dataset),
                  label: const Text('Seed Demo Data'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({required this.sessions});

  final List<RitualSessionRecord> sessions;

  @override
  Widget build(BuildContext context) {
    final tawafCount = sessions
        .where((s) => s.ritualType == RitualType.tawaf)
        .length;
    final saiCount = sessions
        .where((s) => s.ritualType == RitualType.sai)
        .length;
    return SingleChildScrollView(
      padding: PracticeUi.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PracticeSectionHeader(
            title: 'Aggregate Overview',
            subtitle:
                'Aggregate-only view for the FYP demo. No individual pilgrim data is shown.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatCard(label: 'Sessions', value: '${sessions.length}'),
              _StatCard(label: 'Tawaf', value: '$tawafCount'),
              _StatCard(label: 'Sa\'i', value: '$saiCount'),
            ],
          ),
          const SizedBox(height: 20),
          _ChartCard(
            title: 'Age Distribution',
            child: _BarList(values: _countBy(sessions, (s) => s.ageGroup)),
          ),
          _ChartCard(
            title: 'Average Pace by Age Group',
            child: _BarList(
              values: _averageBy(
                sessions,
                key: (s) => s.ageGroup,
                value: (s) => s.averagePaceMps,
              ),
              suffix: ' m/s',
            ),
          ),
          _ChartCard(
            title: 'Average Distance by Ability',
            child: _BarList(
              values: _averageBy(
                sessions,
                key: (s) => s.abilityLevel,
                value: (s) => s.distanceMeters,
              ),
              suffix: ' m',
            ),
          ),
          _ChartCard(
            title: 'Pace vs Distance',
            child: _ScatterPlot(sessions: sessions),
          ),
        ],
      ),
    );
  }

  Map<String, double> _countBy(
    List<RitualSessionRecord> sessions,
    String Function(RitualSessionRecord record) key,
  ) {
    final counts = <String, double>{};
    for (final session in sessions) {
      counts.update(key(session), (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  Map<String, double> _averageBy(
    List<RitualSessionRecord> sessions, {
    required String Function(RitualSessionRecord record) key,
    required double Function(RitualSessionRecord record) value,
  }) {
    final totals = <String, double>{};
    final counts = <String, int>{};
    for (final session in sessions) {
      final group = key(session);
      totals.update(
        group,
        (current) => current + value(session),
        ifAbsent: () => value(session),
      );
      counts.update(group, (current) => current + 1, ifAbsent: () => 1);
    }
    return totals.map((key, total) => MapEntry(key, total / counts[key]!));
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: PracticeSurfaceCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: PracticeUi.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: PracticeSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _BarList extends StatelessWidget {
  const _BarList({required this.values, this.suffix = ''});

  final Map<String, double> values;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const Text('No data');
    final maxValue = values.values.reduce((a, b) => a > b ? a : b);
    final entries = values.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Column(
      children: entries.map((entry) {
        final percent = maxValue == 0 ? 0.0 : entry.value / maxValue;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(width: 70, child: Text(entry.key)),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 12,
                    value: percent,
                    backgroundColor: Colors.grey.shade100,
                    color: const Color(0xFFD4AF37),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 70,
                child: Text(
                  '${entry.value.toStringAsFixed(suffix == ' m' ? 0 : 2)}$suffix',
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ScatterPlot extends StatelessWidget {
  const _ScatterPlot({required this.sessions});

  final List<RitualSessionRecord> sessions;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: CustomPaint(
        painter: _ScatterPainter(sessions),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ScatterPainter extends CustomPainter {
  const _ScatterPainter(this.sessions);

  final List<RitualSessionRecord> sessions;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 44.0;
    const top = 30.0;
    const right = 18.0;
    const bottom = 34.0;
    final chart = Rect.fromLTWH(
      left,
      top,
      size.width - left - right,
      size.height - top - bottom,
    );

    final axisPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;
    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;

    for (var i = 0; i <= 4; i++) {
      final x = chart.left + (chart.width * i / 4);
      final y = chart.top + (chart.height * i / 4);
      canvas.drawLine(Offset(x, chart.top), Offset(x, chart.bottom), gridPaint);
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
    }

    canvas.drawLine(
      Offset(chart.left, chart.bottom),
      Offset(chart.right, chart.bottom),
      axisPaint,
    );
    canvas.drawLine(
      Offset(chart.left, chart.top),
      Offset(chart.left, chart.bottom),
      axisPaint,
    );

    if (sessions.isEmpty) {
      _drawText(
        canvas,
        'No session data',
        Offset(chart.center.dx, chart.center.dy),
        color: PracticeUi.body,
        fontSize: 12,
        align: TextAlign.center,
      );
      return;
    }

    final maxDistance = sessions
        .map((s) => s.distanceMeters)
        .reduce((a, b) => a > b ? a : b);
    final maxPace = sessions
        .map((s) => s.averagePaceMps)
        .reduce((a, b) => a > b ? a : b);
    final safeMaxDistance = maxDistance == 0 ? 1.0 : maxDistance;
    final safeMaxPace = maxPace == 0 ? 1.0 : maxPace;

    _drawText(
      canvas,
      '0',
      Offset(chart.left, chart.bottom + 8),
      color: PracticeUi.body,
      fontSize: 10,
      align: TextAlign.left,
    );
    _drawText(
      canvas,
      '${(safeMaxDistance / 1000).toStringAsFixed(1)} km',
      Offset(chart.right, chart.bottom + 8),
      color: PracticeUi.body,
      fontSize: 10,
      align: TextAlign.right,
    );
    _drawText(
      canvas,
      safeMaxPace.toStringAsFixed(2),
      Offset(chart.left - 6, chart.top - 5),
      color: PracticeUi.body,
      fontSize: 10,
      align: TextAlign.right,
    );
    _drawText(
      canvas,
      'Distance (km)',
      Offset(chart.center.dx, size.height - 14),
      color: PracticeUi.ink,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      align: TextAlign.center,
    );
    _drawText(
      canvas,
      'Pace (m/s)',
      Offset(chart.left, 0),
      color: PracticeUi.ink,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      align: TextAlign.left,
    );

    for (final session in sessions) {
      final x =
          chart.left +
          ((session.distanceMeters / safeMaxDistance) * chart.width);
      final y =
          chart.bottom -
          ((session.averagePaceMps / safeMaxPace) * chart.height);
      final point = Offset(x, y);
      final isTawaf = session.ritualType == RitualType.tawaf;
      final dotPaint = Paint()
        ..color = isTawaf ? PracticeUi.deepGold : PracticeUi.forest;
      final ringPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(point, 5, dotPaint);
      canvas.drawCircle(point, 5.8, ringPaint);
    }

    _drawLegend(canvas, Offset(chart.right - 104, 4));
  }

  void _drawLegend(Canvas canvas, Offset origin) {
    _drawLegendItem(canvas, origin, PracticeUi.deepGold, 'Tawaf');
    _drawLegendItem(
      canvas,
      origin + const Offset(58, 0),
      PracticeUi.forest,
      'Sa\'i',
    );
  }

  void _drawLegendItem(
    Canvas canvas,
    Offset origin,
    Color color,
    String label,
  ) {
    canvas.drawCircle(origin + const Offset(5, 5), 4, Paint()..color = color);
    _drawText(
      canvas,
      label,
      origin + const Offset(14, -1),
      color: PracticeUi.body,
      fontSize: 10,
      align: TextAlign.left,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    required Color color,
    required double fontSize,
    TextAlign align = TextAlign.left,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout();

    final dx = switch (align) {
      TextAlign.center => offset.dx - painter.width / 2,
      TextAlign.right => offset.dx - painter.width,
      _ => offset.dx,
    };
    painter.paint(canvas, Offset(dx, offset.dy));
  }

  @override
  bool shouldRepaint(covariant _ScatterPainter oldDelegate) {
    return oldDelegate.sessions != sessions;
  }
}
