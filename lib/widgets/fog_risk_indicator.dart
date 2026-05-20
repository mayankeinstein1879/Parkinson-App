import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:parkinson_insole_app/constants/app_colors.dart';
import 'package:parkinson_insole_app/constants/app_strings.dart';

/// Large circular FOG risk gauge.
/// Color-coded: green → orange → red as risk increases.
/// Pulses with alert animation when risk exceeds 70%.
class FogRiskIndicator extends StatelessWidget {
  final double riskPercent; // 0 – 100
  final double size;

  const FogRiskIndicator({
    super.key,
    required this.riskPercent,
    this.size = 160,
  });

  @override
  Widget build(BuildContext context) {
    final color   = AppColors.fogRiskColor(riskPercent);
    final isCritical = riskPercent >= 70;
    final label   = _riskLabel(riskPercent);

    Widget indicator = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 24, spreadRadius: 4)],
      ),
      child: CustomPaint(
        painter: _ArcGaugePainter(
          progress: riskPercent / 100,
          color: color,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Risk percentage
              Text(
                '${riskPercent.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: color,
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Orbitron',
                  shadows: [Shadow(color: color.withOpacity(0.6), blurRadius: 12)],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                AppStrings.fogRisk.toUpperCase(),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: size * 0.08,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              // Risk label badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.5)),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: size * 0.075,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Add pulsing animation for critical risk
    if (isCritical) {
      indicator = indicator
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            duration: 800.ms,
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.03, 1.03),
            curve: Curves.easeInOut,
          );
    }

    return indicator;
  }

  String _riskLabel(double pct) {
    if (pct < 30) return AppStrings.fogLow;
    if (pct < 60) return AppStrings.fogModerate;
    if (pct < 80) return AppStrings.fogHigh;
    return AppStrings.fogCritical;
  }
}

// ── Arc Gauge Painter ─────────────────────────────────────────────────────────

class _ArcGaugePainter extends CustomPainter {
  final double progress; // 0.0 – 1.0
  final Color color;

  _ArcGaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final strokeWidth = 10.0;

    // Background track
    final trackPaint = Paint()
      ..color = AppColors.surface
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75,
      math.pi * 1.5,
      false,
      trackPaint,
    );

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75,
      math.pi * 1.5 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ArcGaugePainter old) =>
      old.progress != progress || old.color != color;
}
