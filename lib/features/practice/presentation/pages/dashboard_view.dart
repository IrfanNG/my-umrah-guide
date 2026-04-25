import 'package:flutter/material.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Umrah Practice'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Journey Steps',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete each step to finish your practice session.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            _buildTimelineItem(
              context,
              title: 'Umrah Intent at Miqat',
              description: 'Set your intent at the designated Miqat zone.',
              isCompleted: true,
              isFirst: true,
              onTap: () {},
            ),
            _buildTimelineItem(
              context,
              title: 'Tawaf (7 Rounds)',
              description: 'Practice rounds around the Kaabah.',
              isCompleted: false,
              isActive: true,
              onTap: () {
                Navigator.pushNamed(context, '/tawaf-simulator');
              },
            ),
            _buildTimelineItem(
              context,
              title: 'Sa\'i (Safa to Marwa)',
              description: 'Walk between Safa and Marwa 7 times.',
              isCompleted: false,
              isActive: true,
              isLast: true,
              onTap: () {
                Navigator.pushNamed(context, '/sai-simulator');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context, {
    required String title,
    required String description,
    bool isCompleted = false,
    bool isActive = false,
    bool isFirst = false,
    bool isLast = false,
    required VoidCallback onTap,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Line and Dot
          Column(
            children: [
              Container(
                width: 2,
                height: 20,
                color: isFirst ? Colors.transparent : Colors.grey.shade300,
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? secondaryColor
                      : (isActive ? primaryColor : Colors.white),
                  border: Border.all(
                    color: isCompleted
                        ? secondaryColor
                        : (isActive ? primaryColor : Colors.grey.shade300),
                    width: 2,
                  ),
                  shape: BoxShape.circle,
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : (isActive
                        ? const Icon(Icons.play_arrow, size: 16, color: Colors.white)
                        : null),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: isLast ? Colors.transparent : Colors.grey.shade300,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Content Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive ? primaryColor.withValues(alpha: 0.3) : Colors.transparent,
                      width: 1,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isActive ? primaryColor : (isCompleted ? Colors.grey : Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (isActive)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Row(
                            children: [
                              const Text(
                                'Start Practice',
                                style: TextStyle(
                                  color: Color(0xFFD4AF37), // Use primary color value
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(Icons.chevron_right, size: 16, color: primaryColor),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
