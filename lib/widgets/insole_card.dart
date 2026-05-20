import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:parkinson_insole_app/constants/app_colors.dart';
import 'package:parkinson_insole_app/constants/app_strings.dart';
import 'package:parkinson_insole_app/models/insole_device.dart';
import 'package:parkinson_insole_app/models/telemetry_data.dart';
import 'package:parkinson_insole_app/widgets/ble_status_badge.dart';
import 'package:parkinson_insole_app/widgets/battery_indicator.dart';

/// Displays a single insole's live telemetry in a glassmorphism card.
/// Left insole uses cyan theme; right insole uses purple theme.
class InsoleCard extends StatelessWidget {
  final InsoleDevice device;
  final TelemetryData telemetry;
  final VoidCallback? onTap;

  const InsoleCard({
    super.key,
    required this.device,
    required this.telemetry,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLeft  = device.isLeft;
    final color   = isLeft ? AppColors.leftInsole : AppColors.rightInsole;
    final glow    = isLeft ? AppColors.glowCyan   : AppColors.glowPurple;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(color: glow, blurRadius: 16, spreadRadius: 2),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Row(
              children: [
                Text(
                  device.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                BleStatusBadge(
                  status: device.status,
                  compact: true,
                ),
                const SizedBox(width: 6),
                BatteryIndicator(
                  level: telemetry.batteryLevel,
                  isCharging: false,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Foot Pressure Visualization ───────────────────────────────
            _FootPressureWidget(
              pressure: telemetry.pressure,
              color: color,
              isLeft: isLeft,
            ),
            const SizedBox(height: 12),

            // ── Metrics ───────────────────────────────────────────────────
            _MetricRow(
              label: AppStrings.gaitStability,
              value: telemetry.gaitStability,
              unit: AppStrings.unitPercent,
              color: _stabilityColor(telemetry.gaitStability),
            ),
            const SizedBox(height: 4),
            _MetricRow(
              label: AppStrings.fogRisk,
              value: telemetry.fogRisk,
              unit: AppStrings.unitPercent,
              color: AppColors.fogRiskColor(telemetry.fogRisk),
              isAlert: telemetry.isFogCritical,
            ),
            const SizedBox(height: 4),
            _MetricRow(
              label: AppStrings.stepCadence,
              value: telemetry.stepCadence,
              unit: AppStrings.unitStepsMin,
              color: color,
            ),

            // ── Cue Active Banner ─────────────────────────────────────────
            if (telemetry.cueActive) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warningOrange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.warningOrange.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.vibration, size: 12, color: AppColors.warningOrange),
                    const SizedBox(width: 4),
                    Text(
                      'CUE ACTIVE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.warningOrange,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
                  .fade(duration: 800.ms, begin: 0.5, end: 1.0),
            ],
          ],
        ),
      ),
    );
  }

  Color _stabilityColor(double v) {
    if (v >= 70) return AppColors.accentGreen;
    if (v >= 40) return AppColors.warningOrange;
    return AppColors.alertRed;
  }
}

// ── Foot Pressure Visualization ───────────────────────────────────────────────

class _FootPressureWidget extends StatelessWidget {
  final PressureZone pressure;
  final Color color;
  final bool isLeft;

  const _FootPressureWidget({
    required this.pressure,
    required this.color,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    final zones = pressure.normalized;
    return Row(
      children: [
        // Simple vertical zone bars representing pressure distribution
        Expanded(
          child: SizedBox(
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _PressureBar(label: 'H', value: zones[0], color: color),
                _PressureBar(label: 'M', value: zones[1], color: color),
                _PressureBar(label: 'F', value: zones[2], color: color),
                _PressureBar(label: 'T', value: zones[3], color: color),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Total pressure indicator
        Column(
          children: [
            Text(
              '${pressure.total.toStringAsFixed(0)}',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              AppStrings.unitKPa,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ],
    );
  }
}

class _PressureBar extends StatelessWidget {
  final String label;
  final double value; // 0.0 – 1.0
  final Color color;

  const _PressureBar({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 14,
          height: 50 * value.clamp(0.05, 1.0),
          decoration: BoxDecoration(
            color: color.withOpacity(0.7),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 6)],
          ),
        ).animate().scaleY(
          duration: 400.ms,
          curve: Curves.easeOut,
          alignment: Alignment.bottomCenter,
        ),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

// ── Metric Row ────────────────────────────────────────────────────────────────

class _MetricRow extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final Color color;
  final bool isAlert;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        if (isAlert)
          Icon(Icons.warning_rounded, size: 12, color: AppColors.alertRed),
        const SizedBox(width: 2),
        Text(
          '${value.toStringAsFixed(1)} $unit',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
