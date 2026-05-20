import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:parkinson_insole_app/constants/app_colors.dart';
import 'package:parkinson_insole_app/constants/app_strings.dart';

/// Placeholder analytics card with a mocked line chart.
/// Shows a "Coming Soon" overlay for features not yet implemented.
class AnalyticsPlaceholder extends StatefulWidget {
  final String title;
  final String subtitle;
  final Color? accentColor;
  final bool showComingSoon;

  const AnalyticsPlaceholder({
    super.key,
    required this.title,
    this.subtitle = AppStrings.analyticsComingSoon,
    this.accentColor,
    this.showComingSoon = true,
  });

  @override
  State<AnalyticsPlaceholder> createState() => _AnalyticsPlaceholderState();
}

class _AnalyticsPlaceholderState extends State<AnalyticsPlaceholder> {
  late final List<FlSpot> _spots;
  final math.Random _rng = math.Random(42); // Fixed seed for consistent demo

  @override
  void initState() {
    super.initState();
    // Generate smooth mock data
    _spots = _generateSpots();
  }

  List<FlSpot> _generateSpots() {
    final spots = <FlSpot>[];
    double y = 30 + _rng.nextDouble() * 20;
    for (int i = 0; i < 20; i++) {
      y = (y + (_rng.nextDouble() - 0.45) * 15).clamp(10, 90);
      spots.add(FlSpot(i.toDouble(), y));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.accentColor ?? AppColors.primaryCyan;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.analytics_outlined, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right, size: 16, color: AppColors.textDisabled),
            ],
          ),
          const SizedBox(height: 12),

          // Chart area
          SizedBox(
            height: 80,
            child: Stack(
              children: [
                // Mocked line chart
                LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _spots,
                        isCurved: true,
                        color: color.withOpacity(0.7),
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              color.withOpacity(0.25),
                              color.withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                    minX: 0,
                    maxX: 19,
                    minY: 0,
                    maxY: 100,
                  ),
                ),

                // Coming soon overlay
                if (widget.showComingSoon)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.smart_toy_outlined,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            AppStrings.analyticsComingSoon,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                      .fade(duration: 2000.ms, begin: 0.6, end: 1.0),
              ],
            ),
          ),

          const SizedBox(height: 6),
          Text(
            widget.subtitle,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }
}
