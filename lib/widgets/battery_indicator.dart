import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:parkinson_insole_app/constants/app_colors.dart';

/// Compact battery level indicator with color coding and charging animation.
class BatteryIndicator extends StatelessWidget {
  final int level;        // 0 – 100
  final bool isCharging;
  final bool compact;     // True = icon only (no percentage label)

  const BatteryIndicator({
    super.key,
    required this.level,
    this.isCharging = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorForLevel(level);

    Widget battery = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BatteryIcon(level: level, color: color, isCharging: isCharging),
        if (!compact) ...[
          const SizedBox(width: 4),
          Text(
            '$level%',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );

    // Animate charging pulse
    if (isCharging) {
      battery = battery
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .fade(duration: 700.ms, begin: 0.5, end: 1.0);
    }

    return battery;
  }

  Color _colorForLevel(int pct) {
    if (pct > 50) return AppColors.accentGreen;
    if (pct > 20) return AppColors.warningOrange;
    return AppColors.alertRed;
  }
}

// ── Custom Battery Icon ───────────────────────────────────────────────────────

class _BatteryIcon extends StatelessWidget {
  final int level;
  final Color color;
  final bool isCharging;

  const _BatteryIcon({
    required this.level,
    required this.color,
    required this.isCharging,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 12,
      child: CustomPaint(
        painter: _BatteryPainter(
          fill: level / 100,
          color: color,
          isCharging: isCharging,
        ),
      ),
    );
  }
}

class _BatteryPainter extends CustomPainter {
  final double fill;  // 0.0 – 1.0
  final Color color;
  final bool isCharging;

  _BatteryPainter({
    required this.fill,
    required this.color,
    required this.isCharging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Battery body border
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width - 3, size.height),
      const Radius.circular(2),
    );
    canvas.drawRRect(bodyRect, borderPaint);

    // Battery terminal (positive nub)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - 3, size.height * 0.3,
                       3, size.height * 0.4),
        const Radius.circular(1),
      ),
      fillPaint,
    );

    // Fill level
    final fillWidth = ((size.width - 7) * fill).clamp(0.0, size.width - 7);
    if (fillWidth > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(2, 2, fillWidth, size.height - 4),
          const Radius.circular(1),
        ),
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_BatteryPainter old) =>
      old.fill != fill || old.color != color;
}
