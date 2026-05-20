import 'package:flutter/material.dart';
import 'package:parkinson_insole_app/constants/app_colors.dart';

/// Adaptive cue toggle card with intensity slider.
/// Used in the dashboard's Adaptive Cue Settings section.
class CueToggleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final double intensity;       // 0.0 – 1.0
  final ValueChanged<double> onIntensityChanged;
  final Color? accentColor;

  const CueToggleCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    required this.onToggle,
    required this.intensity,
    required this.onIntensityChanged,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primaryCyan;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled ? color.withOpacity(0.4) : AppColors.cardBorder,
          width: 1.2,
        ),
        boxShadow: enabled
            ? [BoxShadow(color: color.withOpacity(0.1), blurRadius: 12)]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(
            children: [
              // Icon with glow
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: enabled ? color.withOpacity(0.15) : AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: enabled ? color : AppColors.textDisabled,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: enabled ? AppColors.textPrimary : AppColors.textDisabled,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Toggle switch
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: enabled,
                  onChanged: onToggle,
                  activeColor: color,
                  activeTrackColor: color.withOpacity(0.3),
                ),
              ),
            ],
          ),

          // ── Intensity Slider (visible only when enabled) ─────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: enabled
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            'Intensity',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(intensity * 100).round()}%',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: color,
                          thumbColor: color,
                          overlayColor: color.withOpacity(0.2),
                          inactiveTrackColor: AppColors.surface,
                          trackHeight: 3,
                        ),
                        child: Slider(
                          value: intensity,
                          onChanged: onIntensityChanged,
                          min: 0,
                          max: 1,
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
