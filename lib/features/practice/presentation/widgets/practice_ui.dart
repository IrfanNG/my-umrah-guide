import 'package:flutter/material.dart';

class PracticeUi {
  static const Color gold = Color(0xFFD4AF37);
  static const Color deepGold = Color(0xFFB88917);
  static const Color forest = Color(0xFF1F5C34);
  static const Color green = Color(0xFFB2D8B2);
  static const Color greenSoft = Color(0xFFEAF4EA);
  static const Color ink = Color(0xFF1F2937);
  static const Color body = Color(0xFF4B5563);
  static const Color mutedSurface = Color(0xFFF9FAFB);
  static const Color warmSurface = Color(0xFFFFFBF2);
  static const Color sand = Color(0xFFF7ECD4);
  static const Color line = Color(0xFFE8DEC9);

  static const EdgeInsets pagePadding = EdgeInsets.all(24);
  static const EdgeInsets cardPadding = EdgeInsets.all(20);

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(24));
  static const BorderRadius panelRadius = BorderRadius.all(Radius.circular(18));
  static const BorderRadius compactRadius = BorderRadius.all(
    Radius.circular(14),
  );

  static const LinearGradient appGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF7E6), Color(0xFFFFFCF6), Color(0xFFF2F8F1)],
  );

  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2D7141), Color(0xFF174D2B)],
  );

  static const String kaabahHeroAsset = 'assets/images/kaabah_hero.png';

  static String formatDistance(double? distanceMeters) {
    if (distanceMeters == null || distanceMeters < 0) {
      return 'Jarak belum tersedia';
    }
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(2)} km';
  }

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

  static BoxDecoration overlayDecoration({
    Color backgroundColor = const Color(0xF7FFFFFF),
    Color borderColor = const Color(0xFFE8DEC9),
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: borderRadius ?? panelRadius,
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  static ButtonStyle primaryButtonStyle({Color backgroundColor = gold}) {
    return FilledButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  static ButtonStyle outlineButtonStyle({
    Color foregroundColor = ink,
    Color borderColor = line,
    Color backgroundColor = Colors.white,
  }) {
    return OutlinedButton.styleFrom(
      foregroundColor: foregroundColor,
      side: BorderSide(color: borderColor),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: backgroundColor,
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

class PracticeIconBadge extends StatelessWidget {
  const PracticeIconBadge({
    required this.icon,
    super.key,
    this.size = 42,
    this.backgroundColor = PracticeUi.greenSoft,
    this.foregroundColor = PracticeUi.forest,
  });

  final IconData icon;
  final double size;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: foregroundColor.withValues(alpha: 0.12)),
      ),
      child: Icon(icon, color: foregroundColor, size: size * 0.46),
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

class PracticeMapPill extends StatelessWidget {
  const PracticeMapPill({
    required this.label,
    required this.icon,
    required this.color,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: PracticeUi.overlayDecoration(
        borderRadius: BorderRadius.circular(999),
        borderColor: color.withValues(alpha: 0.18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
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

class PracticeCommandBar extends StatelessWidget {
  const PracticeCommandBar({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: PracticeUi.overlayDecoration(
        backgroundColor: Colors.white.withValues(alpha: 0.96),
        borderRadius: const BorderRadius.all(Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    );
  }
}

class PracticeCommandButton extends StatelessWidget {
  const PracticeCommandButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final color = isPrimary ? PracticeUi.forest : PracticeUi.ink;
    final backgroundColor = isPrimary ? PracticeUi.forest : Colors.white;
    final foregroundColor = isPrimary ? Colors.white : color;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        width: 92,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: foregroundColor,
            backgroundColor: backgroundColor,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: isPrimary ? PracticeUi.forest : PracticeUi.line,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ),
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
