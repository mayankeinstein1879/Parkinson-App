import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parkinson_insole_app/constants/app_colors.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1050) {
          return const _AnalyticsDesktopScreen();
        }
        return _AnalyticsMobileScreen();
      },
    );
  }
}

class _AnalyticsDesktopScreen extends StatefulWidget {
  const _AnalyticsDesktopScreen();

  @override
  State<_AnalyticsDesktopScreen> createState() => _AnalyticsDesktopScreenState();
}

class _AnalyticsDesktopScreenState extends State<_AnalyticsDesktopScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _chartController;

  @override
  void initState() {
    super.initState();
    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _chartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          _AnalyticsSidebar(),
          Container(width: 1, color: AppColors.cardBorder),
          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _AnalyticsHeroHeader(),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: _AnalyticsCard(
                            title: 'Gait Asymmetry & Balance Radar Chart',
                            child: Column(
                              children: [
                                const SizedBox(height: 6),
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _MiniStat(label: 'Asymmetry Index', value: '-11.3%', color: AppColors.primaryCyan),
                                    _MiniStat(label: 'Left Balance', value: '', color: AppColors.textSecondary),
                                    _MiniStat(label: 'L/R Distribution', value: '20.9%', color: Color(0xFFA66BFF), alignEnd: true),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 170,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CustomPaint(
                                        size: const Size(double.infinity, 170),
                                        painter: _AnalyticsRadarPainter(),
                                      ),
                                      Positioned(
                                        left: 8,
                                        top: 48,
                                        child: _AxisLabel('Left\nBalance'),
                                      ),
                                      Positioned(
                                        right: 8,
                                        top: 48,
                                        child: _AxisLabel('Right\nBalance', alignEnd: true),
                                      ),
                                      Positioned(
                                        left: 54,
                                        bottom: 10,
                                        child: _AxisLabel('Stance Time\n(L/R)'),
                                      ),
                                      Positioned(
                                        right: 44,
                                        bottom: 10,
                                        child: _AxisLabel('Swing Time\n(L/R)', alignEnd: true),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _FootMetric(
                                      icon: Icons.accessibility_new_rounded,
                                      label: 'Asymmetry Index',
                                      value: '-0.37%',
                                    ),
                                    _FootMetric(
                                      icon: Icons.accessibility_new_rounded,
                                      label: 'L / R Distribution',
                                      value: '-1.35%',
                                      alignEnd: true,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 9,
                          child: Column(
                            children: [
                              _AnalyticsCard(
                                title: 'Live Gait Waveform & Rhythm Analysis',
                                trailing: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _TagChip(label: 'Medical Glow'),
                                    SizedBox(width: 8),
                                    _TagChip(label: 'Medical Glow'),
                                  ],
                                ),
                                child: AnimatedBuilder(
                                  animation: _chartController,
                                  builder: (context, _) {
                                    return SizedBox(
                                      height: 155,
                                      child: CustomPaint(
                                        painter: _WaveformPainter(
                                          phase: _chartController.value,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 14),
                              _AnalyticsCard(
                                title: 'FOG Probability Timeline Trend Chart',
                                trailing: const _LegendDot(label: 'Risk zone', color: Color(0xFFFF537A)),
                                child: AnimatedBuilder(
                                  animation: _chartController,
                                  builder: (context, _) {
                                    return SizedBox(
                                      height: 120,
                                      child: CustomPaint(
                                        painter: _FogTrendPainter(
                                          phase: _chartController.value,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 7,
                          child: _AnalyticsCard(
                            title: 'AI Neurologist Commentary Panel',
                            leadingIcon: Icons.psychology_alt_outlined,
                            child: const _CommentaryList(),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 4,
                          child: _AnalyticsCard(
                            title: 'Key Stride Metrics Summary',
                            child: const _MetricCircleGrid(),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 4,
                          child: _AnalyticsCard(
                            title: 'Predictive FOG Warning & Confidence',
                            child: const _PredictionPanel(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsMobileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Gait Analytics & Insights')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _AnalyticsHeroHeader(compact: true),
          SizedBox(height: 16),
          _MobilePlaceholderCard(title: 'Gait Analytics Dashboard'),
        ],
      ),
    );
  }
}

class _AnalyticsSidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      color: AppColors.cardBackground,
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primaryCyan, AppColors.secondaryPurple],
              ),
              boxShadow: [
                BoxShadow(color: AppColors.glowCyan, blurRadius: 10),
              ],
            ),
            child: const Center(
              child: Icon(Icons.circle_outlined, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(height: 40),
          _SidebarIcon(
            icon: Icons.grid_view_rounded,
            active: false,
            onTap: () => Navigator.pushReplacementNamed(context, '/dashboard'),
          ),
          _SidebarIcon(
            icon: Icons.analytics_outlined,
            active: true,
            onTap: () {},
          ),
          _SidebarIcon(
            icon: Icons.monitor_heart_outlined,
            active: false,
            onTap: () => Navigator.pushNamed(context, '/status'),
          ),
          _SidebarIcon(
            icon: Icons.settings_outlined,
            active: false,
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
          _SidebarIcon(
            icon: Icons.help_outline,
            active: false,
            onTap: () => Navigator.pushNamed(context, '/help'),
          ),
          const Spacer(),
          _SidebarIcon(
            icon: Icons.logout_rounded,
            active: false,
            onTap: () => Navigator.pushReplacementNamed(context, '/auth'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SidebarIcon extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _SidebarIcon({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: active ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: active ? Border.all(color: AppColors.cardBorder) : null,
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.glowCyan.withOpacity(0.18),
                      blurRadius: 12,
                      spreadRadius: -2,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            color: active ? AppColors.primaryCyan : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _AnalyticsHeroHeader extends StatelessWidget {
  final bool compact;

  const _AnalyticsHeroHeader({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 20,
        vertical: compact ? 16 : 14,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF081323),
            Color(0xFF0E1F35),
            Color(0xFF0A1628),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.glowCyan.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 48 : 62,
            height: compact ? 48 : 62,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.surface,
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: CustomPaint(
              painter: _HeaderBarsPainter(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gait Analytics & Insights',
                  style: GoogleFonts.orbitron(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 22 : 28,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AI-Assisted Neurological Movement Analysis',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF9EB8CC),
                    fontSize: compact ? 12 : 14,
                  ),
                ),
              ],
            ),
          ),
          if (!compact)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const _LegendDot(label: 'Live Walking Session', color: Color(0xFFFF4D73)),
                  const SizedBox(height: 8),
                  Text(
                    'Last Sync: [1:32 PM PT]',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 12,
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

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final IconData? leadingIcon;

  const _AnalyticsCard({
    required this.title,
    required this.child,
    this.trailing,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.glowCyan.withOpacity(0.05),
            blurRadius: 18,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, color: AppColors.primaryCyan, size: 18),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.orbitron(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool alignEnd;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 10),
        ),
        if (value.isNotEmpty)
          Text(
            value,
            style: GoogleFonts.orbitron(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

class _AxisLabel extends StatelessWidget {
  final String label;
  final bool alignEnd;

  const _AxisLabel(this.label, {this.alignEnd = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: alignEnd ? TextAlign.end : TextAlign.start,
      style: GoogleFonts.orbitron(
        color: AppColors.textPrimary,
        fontSize: 10,
        height: 1.2,
      ),
    );
  }
}

class _FootMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool alignEnd;

  const _FootMetric({
    required this.icon,
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (!alignEnd) Icon(icon, size: 18, color: AppColors.textDisabled),
        if (!alignEnd) const SizedBox(width: 8),
        Column(
          crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 10),
            ),
            Text(
              value,
              style: GoogleFonts.orbitron(
                color: AppColors.primaryCyan,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        if (alignEnd) const SizedBox(width: 8),
        if (alignEnd) Icon(icon, size: 18, color: AppColors.textDisabled),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF173042),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: const Color(0xFF8BE6F5),
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 10),
        ),
      ],
    );
  }
}

class _CommentaryList extends StatelessWidget {
  const _CommentaryList();

  @override
  Widget build(BuildContext context) {
    const items = [
      'Patient demonstrates mild gait asymmetry (L-R). Periodic step variability observed.',
      'Current movement pattern indicates elevated FOG risk during transitions.',
      'Intermittent cadence fluctuation noted. Right foot pressure dominance identified.',
      'Overall gait consistency is moderate, with FOG risk elevated on irregular surfaces.',
      'Stability score is good, but predictive FOG warning active.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '– $item',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MetricCircleGrid extends StatelessWidget {
  const _MetricCircleGrid();

  @override
  Widget build(BuildContext context) {
    const metrics = [
      ('75', 'Stride Rhythm', AppColors.accentGreen),
      ('25', 'FOG Risk', Color(0xFFA66BFF)),
      ('75', 'Step Consistency', AppColors.accentGreen),
      ('75', 'Stride Rhythm', Color(0xFFFF8A5B)),
      ('30', 'Cadence Variability', Color(0xFFA66BFF)),
      ('95', 'Step Consistency', AppColors.primaryCyan),
    ];

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: metrics
          .map(
            (metric) => SizedBox(
              width: 74,
              child: Column(
                children: [
                  SizedBox(
                    width: 42,
                    height: 42,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: (double.parse(metric.$1) / 100).clamp(0.0, 1.0),
                          strokeWidth: 4,
                          backgroundColor: const Color(0xFF162739),
                          valueColor: AlwaysStoppedAnimation<Color>(metric.$3),
                        ),
                        Text(
                          metric.$1,
                          style: GoogleFonts.orbitron(
                            color: metric.$3,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    metric.$2,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PredictionPanel extends StatelessWidget {
  const _PredictionPanel();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _PredictionOrb(
            label: 'FOG\n%',
            subtitle: 'FOG Prediction Confidence (%)',
            glowColor: AppColors.primaryCyan,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _PredictionOrb(
            label: 'Elevated',
            subtitle: 'Current FOG Warning Level',
            glowColor: Color(0xFFFF6B7B),
          ),
        ),
      ],
    );
  }
}

class _PredictionOrb extends StatelessWidget {
  final String label;
  final String subtitle;
  final Color glowColor;

  const _PredictionOrb({
    required this.label,
    required this.subtitle,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                glowColor.withOpacity(0.22),
                const Color(0xFF0B1829),
              ],
            ),
            border: Border.all(color: glowColor.withOpacity(0.8), width: 2),
            boxShadow: [
              BoxShadow(
                color: glowColor.withOpacity(0.35),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.orbitron(
                color: glowColor,
                fontSize: label == 'Elevated' ? 22 : 30,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _MobilePlaceholderCard extends StatelessWidget {
  final String title;

  const _MobilePlaceholderCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        '$title is optimized for the desktop-style dashboard layout.',
        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
      ),
    );
  }
}

class _HeaderBarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bars = [
      (size.width * 0.18, size.height * 0.62, AppColors.primaryCyan),
      (size.width * 0.38, size.height * 0.40, const Color(0xFF7AE7FF)),
      (size.width * 0.58, size.height * 0.82, AppColors.primaryCyan),
      (size.width * 0.78, size.height * 0.20, AppColors.secondaryPurple),
    ];

    for (final bar in bars) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(bar.$1 - 4, size.height * 0.15, 8, bar.$2),
        const Radius.circular(3),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..color = bar.$3.withOpacity(0.85)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawRRect(rect, Paint()..color = bar.$3);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AnalyticsRadarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.34;

    final gridPaint = Paint()
      ..color = const Color(0xFF2C415A)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int r = 1; r <= 5; r++) {
      final path = Path();
      final currentRadius = radius * (r / 5);
      for (int i = 0; i < 5; i++) {
        final angle = (2 * math.pi / 5) * i - math.pi / 2;
        final point = Offset(
          center.dx + currentRadius * math.cos(angle),
          center.dy + currentRadius * math.sin(angle),
        );
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    for (int i = 0; i < 5; i++) {
      final angle = (2 * math.pi / 5) * i - math.pi / 2;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(center, point, gridPaint);
    }

    final cyanValues = [0.55, 0.72, 0.48, 0.42, 0.65];
    final purpleValues = [0.32, 0.40, 0.68, 0.52, 0.35];
    _drawRadarData(canvas, center, radius, cyanValues, AppColors.primaryCyan);
    _drawRadarData(canvas, center, radius, purpleValues, const Color(0xFFA66BFF));
  }

  void _drawRadarData(
    Canvas canvas,
    Offset center,
    double radius,
    List<double> values,
    Color color,
  ) {
    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final angle = (2 * math.pi / 5) * i - math.pi / 2;
      final point = Offset(
        center.dx + radius * values[i] * math.cos(angle),
        center.dy + radius * values[i] * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withOpacity(0.16)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WaveformPainter extends CustomPainter {
  final double phase;

  _WaveformPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF213548)
      ..strokeWidth = 1;

    for (int i = 0; i <= 6; i++) {
      final x = size.width * (i / 6);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (int i = 0; i <= 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final cyanPath = Path()..moveTo(0, size.height * 0.65);
    final purplePath = Path()..moveTo(0, size.height * 0.80);

    for (double x = 0; x <= size.width; x++) {
      final normalized = x / size.width;
      final animated = normalized + (phase * 1.8);
      final cyanY = size.height *
          (0.50 +
              0.22 * math.sin(animated * 8 * math.pi) +
              0.08 * math.sin(animated * 20 * math.pi));
      final purpleY = size.height *
          (0.56 +
              0.20 * math.sin(animated * 7 * math.pi + 1.4) +
              0.10 * math.sin(animated * 18 * math.pi + 0.6));
      cyanPath.lineTo(x, cyanY);
      purplePath.lineTo(x, purpleY);
    }

    _drawGlowPath(canvas, cyanPath, AppColors.primaryCyan);
    _drawGlowPath(canvas, purplePath, const Color(0xFFA66BFF));

    final markerPaint = Paint()
      ..color = const Color(0xFF7C8FA8)
      ..strokeWidth = 1;
    final markerX1 = size.width * 0.42;
    final markerX2 = size.width * 0.60;
    canvas.drawLine(Offset(markerX1, 0), Offset(markerX1, size.height), markerPaint);
    canvas.drawLine(Offset(markerX2, 0), Offset(markerX2, size.height), markerPaint);

    _drawTooltip(canvas, Offset(markerX1 - 42, 8), 'Stride Rhythm\nStride Rhythm: 18.56');
    _drawTooltip(canvas, Offset(markerX2 + 8, 8), 'Gait Oscillation\nStride Rhythm: ~12 m');
  }

  void _drawGlowPath(Canvas canvas, Path path, Color color) {
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withOpacity(0.22)
        ..strokeWidth = 10
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [color.withOpacity(0.9), color.withOpacity(0.4)],
        ).createShader(const Rect.fromLTWH(0, 0, 900, 200))
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawTooltip(Canvas canvas, Offset offset, String text) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(offset.dx, offset.dy, 94, 34),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      rect,
      Paint()..color = const Color(0xCC1A2736),
    );
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFFE8F4FF),
          fontSize: 9,
          height: 1.15,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: 88);
    painter.paint(canvas, Offset(offset.dx + 4, offset.dy + 5));
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) =>
      oldDelegate.phase != phase;
}

class _FogTrendPainter extends CustomPainter {
  final double phase;

  _FogTrendPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final topZone = Rect.fromLTWH(0, 0, size.width, size.height * 0.38);
    canvas.drawRect(
      topZone,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x33FF537A), Color(0x11FF537A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(topZone),
    );

    final gridPaint = Paint()
      ..color = const Color(0xFF22364B)
      ..strokeWidth = 1;
    for (int i = 0; i <= 5; i++) {
      final y = size.height * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (int i = 0; i <= 7; i++) {
      final x = size.width * (i / 7);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    final baseValues = [0.82, 0.72, 0.56, 0.66, 0.36, 0.54, 0.40, 0.14];
    final points = <Offset>[];
    for (int i = 0; i < baseValues.length; i++) {
      final wave = 0.10 * math.sin((phase * 2 * math.pi) + (i * 0.72));
      final drift = 0.04 * math.cos((phase * 4 * math.pi) + (i * 0.45));
      final animatedValue = (baseValues[i] + wave + drift).clamp(0.10, 0.88);
      points.add(
        Offset(
          size.width * (i / (baseValues.length - 1)),
          size.height * animatedValue,
        ),
      );
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final cx = (p1.dx + p2.dx) / 2;
      path.cubicTo(cx, p1.dy, cx, p2.dy, p2.dx, p2.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF5CF2B0),
            Color(0xFF7B9BFF),
            Color(0xFFE96FFF),
            Color(0xFFFF667A),
          ],
        ).createShader(Offset.zero & size)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );

    for (int i = 0; i < points.length; i++) {
      final color = Color.lerp(const Color(0xFF5CF2B0), const Color(0xFFFF667A), i / (points.length - 1))!;
      canvas.drawCircle(
        points[i],
        7,
        Paint()
          ..color = color.withOpacity(0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(points[i], 3.5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _FogTrendPainter oldDelegate) =>
      oldDelegate.phase != phase;
}
