import 'package:flutter/material.dart';

class PracticeUi {
  static const Color gold = Color(0xFFD4AF37);
  static const Color green = Color(0xFFB2D8B2);
  static const Color ink = Color(0xFF1F2937);
  static const Color body = Color(0xFF4B5563);
  static const Color mutedSurface = Color(0xFFF9FAFB);

  static const EdgeInsets pagePadding = EdgeInsets.all(24);
  static const EdgeInsets cardPadding = EdgeInsets.all(20);

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(24));
  static const BorderRadius panelRadius = BorderRadius.all(Radius.circular(18));

  static BoxDecoration surfaceDecoration({
    Color backgroundColor = Colors.white,
    Color borderColor = const Color(0xFFE5E7EB),
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: borderRadius ?? cardRadius,
      border: Border.all(color: borderColor),
      boxShadow:
          boxShadow ??
          [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
    );
  }
}

class PracticeSurfaceCard extends StatelessWidget {
  const PracticeSurfaceCard({
    required this.child,
    super.key,
    this.padding = PracticeUi.cardPadding,
    this.backgroundColor = Colors.white,
    this.borderColor = const Color(0xFFE5E7EB),
    this.borderRadius,
    this.boxShadow,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: PracticeUi.surfaceDecoration(
        backgroundColor: backgroundColor,
        borderColor: borderColor,
        borderRadius: borderRadius,
        boxShadow: boxShadow,
      ),
      child: child,
    );
  }
}

class PracticeSectionHeader extends StatelessWidget {
  const PracticeSectionHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: PracticeUi.ink,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(color: PracticeUi.body, height: 1.45),
                ),
              ],
            ],
          ),
        ),
        trailing ?? const SizedBox.shrink(),
      ],
    );
  }
}

class PracticeStatusChip extends StatelessWidget {
  const PracticeStatusChip({
    required this.label,
    super.key,
    this.icon,
    this.backgroundColor = const Color(0xFFF7F7F3),
    this.foregroundColor = PracticeUi.ink,
    this.borderColor = const Color(0xFFE5E7EB),
  });

  final String label;
  final IconData? icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foregroundColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class PracticeMetricChip extends StatelessWidget {
  const PracticeMetricChip({
    required this.label,
    required this.value,
    super.key,
    this.borderColor = const Color(0xFFE5E7EB),
  });

  final String label;
  final String value;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: PracticeUi.body),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: PracticeUi.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class PracticeInfoBanner extends StatelessWidget {
  const PracticeInfoBanner({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
    this.backgroundColor = const Color(0xFFF7F7F3),
    this.foregroundColor = PracticeUi.ink,
    this.borderColor = const Color(0xFFE5E7EB),
  });

  final IconData icon;
  final String title;
  final String message;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: foregroundColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: foregroundColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    color: foregroundColor.withValues(alpha: 0.9),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
