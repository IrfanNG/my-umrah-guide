import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/analytics_repository.dart';
import '../../domain/ritual_recommendation.dart';
import '../auth_controller.dart';
import '../widgets/practice_ui.dart';

class SessionHistoryView extends StatefulWidget {
  const SessionHistoryView({super.key});

  @override
  State<SessionHistoryView> createState() => _SessionHistoryViewState();
}

class _SessionHistoryViewState extends State<SessionHistoryView> {
  final AnalyticsRepository _repository = AnalyticsRepository();
  List<RitualSessionRecord> _tawafSessions = [];
  List<RitualSessionRecord> _saiSessions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final results = await Future.wait([
        _repository.getUserSessions(
          uid: user.uid,
          ritualType: RitualType.tawaf,
          limit: 5,
        ),
        _repository.getUserSessions(
          uid: user.uid,
          ritualType: RitualType.sai,
          limit: 5,
        ),
      ]);

      if (!mounted) return;
      setState(() {
        _tawafSessions = results[0];
        _saiSessions = results[1];
        _isLoading = false;
      });
    } catch (e, st) {
      debugPrint('Session history load failed: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load session history.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PracticeUi.warmSurface,
      appBar: AppBar(
        title: const Text('Session History'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadSessions,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => context.read<AuthController>().signOut(),
            icon: const Icon(Icons.logout, color: PracticeUi.forest),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: PracticeUi.body,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _loadSessions,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSessions,
                  child: ListView(
                    padding: PracticeUi.pagePadding,
                    children: [
                  _buildSection(
                    context,
                    ritualType: RitualType.tawaf,
                    sessions: _tawafSessions,
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    ritualType: RitualType.sai,
                    sessions: _saiSessions,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required RitualType ritualType,
    required List<RitualSessionRecord> sessions,
  }) {
    final label = ritualType.label;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: PracticeUi.forest,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        if (sessions.isEmpty)
          PracticeSurfaceCard(
            padding: const EdgeInsets.all(20),
            borderColor: PracticeUi.line,
            boxShadow: const [],
            child: Text(
              'No $label sessions yet.',
              style: const TextStyle(color: PracticeUi.body),
            ),
          )
        else
          ...List.generate(sessions.length, (i) {
            final session = sessions[i];
            return Padding(
              padding: EdgeInsets.only(bottom: i < sessions.length - 1 ? 10 : 0),
              child: _SessionCard(index: i, session: session),
            );
          }),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.index,
    required this.session,
  });

  final int index;
  final RitualSessionRecord session;

  @override
  Widget build(BuildContext context) {
    return PracticeSurfaceCard(
      padding: const EdgeInsets.all(16),
      borderColor: PracticeUi.line,
      boxShadow: const [],
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: PracticeUi.greenSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: PracticeUi.forest,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Session ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: PracticeUi.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  session.formattedDate,
                  style: const TextStyle(
                    color: PracticeUi.body,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                session.formattedDuration,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: PracticeUi.ink,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                session.formattedPace,
                style: const TextStyle(
                  color: PracticeUi.body,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
