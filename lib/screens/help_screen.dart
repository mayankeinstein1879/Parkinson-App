import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parkinson_insole_app/constants/app_colors.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1050) {
          return const _HelpDesktopScreen();
        }
        return const _HelpMobileScreen();
      },
    );
  }
}

class _HelpDesktopScreen extends StatelessWidget {
  const _HelpDesktopScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const _HelpSidebar(),
          Container(width: 1, color: AppColors.cardBorder),
          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _HubHero(),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 7,
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Expanded(child: _SystemOverviewCard()),
                                  SizedBox(width: 14),
                                  Expanded(child: _MonitoringGuideCard()),
                                  SizedBox(width: 14),
                                  Expanded(child: _AnalyticsExplanationCard()),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const _EmergencyFeaturesCard(),
                              const SizedBox(height: 14),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Expanded(child: _AdaptiveCueGuideCard()),
                                  SizedBox(width: 14),
                                  Expanded(child: _BleGuideCard()),
                                  SizedBox(width: 14),
                                  Expanded(child: _FutureAiCard()),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          flex: 2,
                          child: _AssistantTipsCard(),
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

class _HelpMobileScreen extends StatelessWidget {
  const _HelpMobileScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('System Intelligence Hub')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _HubHero(compact: true),
          SizedBox(height: 16),
          _HelpMobilePlaceholder(),
        ],
      ),
    );
  }
}

class _HelpSidebar extends StatelessWidget {
  const _HelpSidebar();

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
          _HelpSidebarIcon(
            icon: Icons.grid_view_rounded,
            active: false,
            onTap: () => Navigator.pushReplacementNamed(context, '/dashboard'),
          ),
          _HelpSidebarIcon(
            icon: Icons.analytics_outlined,
            active: false,
            onTap: () => Navigator.pushReplacementNamed(context, '/analytics'),
          ),
          _HelpSidebarIcon(
            icon: Icons.monitor_heart_outlined,
            active: false,
            onTap: () => Navigator.pushNamed(context, '/status'),
          ),
          _HelpSidebarIcon(
            icon: Icons.settings_outlined,
            active: false,
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
          _HelpSidebarIcon(
            icon: Icons.help_outline,
            active: true,
            onTap: () {},
          ),
          const Spacer(),
          _HelpSidebarIcon(
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

class _HelpSidebarIcon extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _HelpSidebarIcon({
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
            border: active ? Border.all(color: AppColors.primaryCyan.withOpacity(0.6)) : null,
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.glowCyan.withOpacity(0.28),
                      blurRadius: 14,
                      spreadRadius: -1,
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

class _HubHero extends StatelessWidget {
  final bool compact;

  const _HubHero({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 18, vertical: compact ? 16 : 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0A182B),
            Color(0xFF11243D),
            Color(0xFF0D1B2E),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x507E59F8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.glowCyan.withOpacity(0.08),
            blurRadius: 24,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _StarMeshPainter()),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System Intelligence Hub',
                      style: GoogleFonts.orbitron(
                        color: const Color(0xFFD6F7FF),
                        fontSize: compact ? 24 : 34,
                        fontWeight: FontWeight.w800,
                        shadows: [
                          Shadow(
                            color: AppColors.glowCyan.withOpacity(0.35),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AI-Assisted Guidance & Feature Overview',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFAFC7D8),
                        fontSize: compact ? 13 : 16,
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact) ...[
                const _AiBadge(),
                const SizedBox(width: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF213245),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Live system status',
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentGreen.withOpacity(0.45),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AiBadge extends StatelessWidget {
  const _AiBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.primaryCyan.withOpacity(0.28),
            Colors.transparent,
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF13283A),
            border: Border.all(color: AppColors.primaryCyan.withOpacity(0.45)),
          ),
          child: Center(
            child: Text(
              'AI',
              style: GoogleFonts.orbitron(
                color: AppColors.primaryCyan,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Color borderColor;

  const _HelpCard({
    required this.title,
    required this.child,
    this.borderColor = const Color(0x2A8AB8DB),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 16,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: GoogleFonts.orbitron(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SystemOverviewCard extends StatelessWidget {
  const _SystemOverviewCard();

  @override
  Widget build(BuildContext context) {
    return _HelpCard(
      title: 'System Overview',
      borderColor: const Color(0x5F7A59F8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 118,
            child: Row(
              children: const [
                Expanded(child: _InsoleVisualTile()),
                SizedBox(width: 10),
                Expanded(child: _MedicalFigureTile()),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Parkinson’s assistance purpose, initiation, gait purpose, FOG monitoring, adaptive cueing overview',
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          const _FlowMiniDiagram(),
        ],
      ),
    );
  }
}

class _MonitoringGuideCard extends StatelessWidget {
  const _MonitoringGuideCard();

  @override
  Widget build(BuildContext context) {
    return _HelpCard(
      title: 'Real-Time Monitoring Guide',
      borderColor: const Color(0x557E59F8),
      child: Column(
        children: [
          SizedBox(
            height: 92,
            child: Row(
              children: const [
                Expanded(child: _MiniPanelPreview()),
                SizedBox(width: 10),
                Expanded(child: _GuideMetricStack()),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'BLE indicators, gait stability, FOG risk, and cadence explain the main monitoring cards.',
            style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsExplanationCard extends StatelessWidget {
  const _AnalyticsExplanationCard();

  @override
  Widget build(BuildContext context) {
    return _HelpCard(
      title: 'AI Analytics Explanation',
      child: Column(
        children: [
          SizedBox(
            height: 92,
            child: Row(
              children: const [
                Expanded(child: _MiniChartCard()),
                SizedBox(width: 10),
                Expanded(child: _NeuralGraphTile()),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI commentary example, neural-network visual accents, and analytics graph guidance.',
            style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _EmergencyFeaturesCard extends StatelessWidget {
  const _EmergencyFeaturesCard();

  @override
  Widget build(BuildContext context) {
    return _HelpCard(
      title: 'Emergency & Safety Features',
      borderColor: const Color(0x77FF6B7B),
      child: Row(
        children: const [
          Expanded(child: _EmergencyVisualsTile()),
          SizedBox(width: 14),
          Expanded(child: _EmergencyExplainerTile()),
        ],
      ),
    );
  }
}

class _AdaptiveCueGuideCard extends StatelessWidget {
  const _AdaptiveCueGuideCard();

  @override
  Widget build(BuildContext context) {
    return _HelpCard(
      title: 'Adaptive Cueing System',
      child: Column(
        children: [
          const SizedBox(
            height: 110,
            child: _CueModesVisual(),
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Expanded(child: _CueLabelTile(title: 'Visual\n(laser)')),
              SizedBox(width: 8),
              Expanded(child: _CueLabelTile(title: 'Haptic\n(vibration)')),
              SizedBox(width: 8),
              Expanded(child: _CueLabelTile(title: 'Rhythmic Audio\n(tones)')),
            ],
          ),
        ],
      ),
    );
  }
}


class _FutureAiCard extends StatelessWidget {
  const _FutureAiCard();

  @override
  Widget build(BuildContext context) {
    return _HelpCard(
      title: 'Future AI Features',
      child: Column(
        children: [
          const SizedBox(height: 92, child: _FutureAiVisual()),
          const SizedBox(height: 8),
          Text(
            'A visionary, next-generation roadmap for predictive gait analysis, personalized therapy, caregiver cloud, adaptive ML, long-term tracking.',
            style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _AssistantTipsCard extends StatelessWidget {
  const _AssistantTipsCard();

  @override
  Widget build(BuildContext context) {
    return _HelpCard(
      title: 'AI Assistant Tips',
      borderColor: const Color(0x6A8AE7F5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF213245),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              'Medical-tech assistant',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '- Stable gait detected.\n- Low BLE signal strength.\n- Cadence improving.\n- Battery optimization active.\n\n- Converse by the pageim tips.',
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 12,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpMobilePlaceholder extends StatelessWidget {
  const _HelpMobilePlaceholder();

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
        'System Intelligence Hub is optimized for the desktop sidebar experience.',
        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
      ),
    );
  }
}

class _InsoleVisualTile extends StatelessWidget {
  const _InsoleVisualTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF102337), Color(0xFF0C1727)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CustomPaint(painter: _InsoleTilePainter()),
    );
  }
}

class _MedicalFigureTile extends StatelessWidget {
  const _MedicalFigureTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF111F34), Color(0xFF0A1323)],
        ),
      ),
      child: CustomPaint(painter: _MedicalFigurePainter()),
    );
  }
}

class _FlowMiniDiagram extends StatelessWidget {
  const _FlowMiniDiagram();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: CustomPaint(painter: _FlowDiagramPainter()),
    );
  }
}

class _MiniPanelPreview extends StatelessWidget {
  const _MiniPanelPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF162536),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: CustomPaint(painter: _MiniPanelPainter()),
    );
  }
}

class _GuideMetricStack extends StatelessWidget {
  const _GuideMetricStack();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Expanded(child: _MetricPill(label: 'Gait Stability', value: 'FOG', color: Color(0xFFFFCC4D))),
        SizedBox(height: 8),
        Expanded(child: _MetricPill(label: 'BLE Indicators', value: '9.3', color: AppColors.primaryCyan)),
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF162536),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: GoogleFonts.orbitron(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChartCard extends StatelessWidget {
  const _MiniChartCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF162536),
        borderRadius: BorderRadius.circular(10),
      ),
      child: CustomPaint(painter: _MiniChartPainter()),
    );
  }
}

class _NeuralGraphTile extends StatelessWidget {
  const _NeuralGraphTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF162536),
        borderRadius: BorderRadius.circular(10),
      ),
      child: CustomPaint(painter: _NeuralGraphPainter()),
    );
  }
}

class _EmergencyVisualsTile extends StatelessWidget {
  const _EmergencyVisualsTile();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: Row(
        children: const [
          Expanded(child: _WarningBubble(icon: Icons.warning_amber_rounded)),
          SizedBox(width: 10),
          Expanded(child: _WarningBubble(icon: Icons.notifications_active_outlined)),
          SizedBox(width: 10),
          Expanded(child: _SafetyWaveVisual()),
        ],
      ),
    );
  }
}

class _EmergencyExplainerTile extends StatelessWidget {
  const _EmergencyExplainerTile();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: const [
            Expanded(child: _TinyAlertCard(label: 'Fall detection')),
            SizedBox(width: 8),
            Expanded(child: _TinyAlertCard(label: 'SOS trigger')),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Futuristic safety visuals for fall detection, SOS trigger, caregiver alerts, emergency comms.',
          style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12, height: 1.35),
        ),
      ],
    );
  }
}

class _CueModesVisual extends StatelessWidget {
  const _CueModesVisual();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Expanded(child: _CueWaveRow()),
        SizedBox(height: 8),
        Expanded(child: _CueIconsRow()),
      ],
    );
  }
}

class _CueWaveRow extends StatelessWidget {
  const _CueWaveRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _CuePreviewTile(icon: Icons.back_hand_outlined)),
        SizedBox(width: 8),
        Expanded(flex: 3, child: _CueWaveTile()),
      ],
    );
  }
}

class _CueIconsRow extends StatelessWidget {
  const _CueIconsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _CuePreviewTile(icon: Icons.linear_scale_rounded, accent: Color(0xFFFF4D73))),
        SizedBox(width: 8),
        Expanded(child: _CuePreviewTile(icon: Icons.sensors)),
        SizedBox(width: 8),
        Expanded(child: _CuePreviewTile(icon: Icons.graphic_eq_rounded, accent: Color(0xFFA66BFF))),
      ],
    );
  }
}

class _CuePreviewTile extends StatelessWidget {
  final IconData icon;
  final Color accent;

  const _CuePreviewTile({
    required this.icon,
    this.accent = AppColors.primaryCyan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF162536),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Icon(icon, color: accent, size: 28),
    );
  }
}

class _CueWaveTile extends StatelessWidget {
  const _CueWaveTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF162536),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: CustomPaint(painter: _CueWavePainter()),
    );
  }
}

class _CueLabelTile extends StatelessWidget {
  final String title;

  const _CueLabelTile({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        color: AppColors.textPrimary,
        fontSize: 11,
        height: 1.2,
      ),
    );
  }
}

class _BleGuideCard extends StatelessWidget {
  const _BleGuideCard();

  @override
  Widget build(BuildContext context) {
    return _HelpCard(
      title: 'BLE Connectivity Guide',
      child: Column(
        children: [
          const SizedBox(height: 92, child: _BleFlowVisual()),
          const SizedBox(height: 8),
          Text(
            'Explain pairing, device states, sync, battery, and live connection status.',
            style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _BleFlowVisual extends StatelessWidget {
  const _BleFlowVisual();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BleFlowPainter());
  }
}

class _FutureAiVisual extends StatelessWidget {
  const _FutureAiVisual();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _FutureAiPainter());
  }
}

class _WarningBubble extends StatelessWidget {
  final IconData icon;

  const _WarningBubble({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF201E2F),
        border: Border.all(color: const Color(0x88FF6B7B)),
        boxShadow: [
          BoxShadow(color: const Color(0x44FF6B7B), blurRadius: 12),
        ],
      ),
      child: Icon(icon, color: const Color(0xFFFF6B7B)),
    );
  }
}

class _SafetyWaveVisual extends StatelessWidget {
  const _SafetyWaveVisual();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF162536),
        borderRadius: BorderRadius.circular(10),
      ),
      child: CustomPaint(painter: _SafetyWavePainter()),
    );
  }
}

class _TinyAlertCard extends StatelessWidget {
  final String label;

  const _TinyAlertCard({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF251D2B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x88FF6B7B)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF6B7B), size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StarMeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final starPaint = Paint()..color = const Color(0x66A7EEFF);
    final stars = [
      Offset(size.width * 0.62, size.height * 0.18),
      Offset(size.width * 0.70, size.height * 0.30),
      Offset(size.width * 0.78, size.height * 0.18),
      Offset(size.width * 0.86, size.height * 0.34),
      Offset(size.width * 0.74, size.height * 0.56),
      Offset(size.width * 0.67, size.height * 0.48),
    ];
    for (final star in stars) {
      canvas.drawCircle(star, 2.2, starPaint);
      canvas.drawCircle(
        star,
        8,
        Paint()
          ..color = const Color(0x22A7EEFF)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    final linePaint = Paint()
      ..color = const Color(0x2247B5FF)
      ..strokeWidth = 1;
    for (int i = 0; i < stars.length - 1; i++) {
      canvas.drawLine(stars[i], stars[i + 1], linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InsoleTilePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.38, size.height * 0.54);
    final path = Path()
      ..moveTo(center.dx, size.height * 0.14)
      ..cubicTo(size.width * 0.72, size.height * 0.18, size.width * 0.74, size.height * 0.40, size.width * 0.58, size.height * 0.54)
      ..cubicTo(size.width * 0.46, size.height * 0.66, size.width * 0.48, size.height * 0.86, size.width * 0.30, size.height * 0.90)
      ..cubicTo(size.width * 0.14, size.height * 0.86, size.width * 0.10, size.height * 0.66, size.width * 0.18, size.height * 0.50)
      ..cubicTo(size.width * 0.24, size.height * 0.34, size.width * 0.18, size.height * 0.18, center.dx, size.height * 0.14)
      ..close();
    canvas.drawShadow(path, AppColors.primaryCyan, 10, false);
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF8DF5FF), Color(0xFF3C8FFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Offset.zero & size),
    );
    final labelPainter = TextPainter(
      text: TextSpan(
        text: 'Insole\nvisualization',
        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 9),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 60);
    labelPainter.paint(canvas, Offset(size.width * 0.72, size.height * 0.10));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MedicalFigurePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF142942), Color(0xFF0E1727)],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      bg,
    );
    final bodyPaint = Paint()
      ..color = const Color(0x66B8E7FF)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final cx = size.width * 0.50;
    final top = size.height * 0.14;
    canvas.drawCircle(Offset(cx, top + 10), 8, bodyPaint..style = PaintingStyle.stroke);
    canvas.drawLine(Offset(cx, top + 20), Offset(cx, size.height * 0.56), bodyPaint);
    canvas.drawLine(Offset(cx, size.height * 0.26), Offset(size.width * 0.36, size.height * 0.40), bodyPaint);
    canvas.drawLine(Offset(cx, size.height * 0.26), Offset(size.width * 0.64, size.height * 0.40), bodyPaint);
    canvas.drawLine(Offset(cx, size.height * 0.56), Offset(size.width * 0.40, size.height * 0.84), bodyPaint);
    canvas.drawLine(Offset(cx, size.height * 0.56), Offset(size.width * 0.60, size.height * 0.84), bodyPaint);
    final chest = Rect.fromCenter(center: Offset(cx, size.height * 0.44), width: 18, height: 22);
    canvas.drawOval(
      chest,
      Paint()
        ..color = const Color(0x66FF4D73)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    final labelPainter = TextPainter(
      text: TextSpan(
        text: 'AI medical illustration',
        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 9),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: size.width);
    labelPainter.paint(canvas, Offset(size.width * 0.08, size.height * 0.88));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FlowDiagramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final nodes = [
      Rect.fromLTWH(0, 18, 56, 28),
      Rect.fromLTWH(size.width * 0.36, 4, 68, 28),
      Rect.fromLTWH(size.width * 0.36, 36, 68, 28),
      Rect.fromLTWH(size.width - 58, 18, 56, 28),
    ];
    final labels = ['FOG\nmonitor', 'Neural\nanalysis', 'Cueing\nsystem', 'Caregiver\nalerts'];
    final paint = Paint()
      ..color = const Color(0x99253D56)
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = AppColors.primaryCyan.withOpacity(0.35)
      ..style = PaintingStyle.stroke;
    final linePaint = Paint()
      ..color = AppColors.primaryCyan.withOpacity(0.28)
      ..strokeWidth = 1.2;
    for (int i = 0; i < nodes.length; i++) {
      final r = RRect.fromRectAndRadius(nodes[i], const Radius.circular(8));
      canvas.drawRRect(r, paint);
      canvas.drawRRect(r, border);
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 8)),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: nodes[i].width);
      tp.paint(canvas, Offset(nodes[i].left, nodes[i].top + 5));
    }
    canvas.drawLine(nodes[0].centerRight, nodes[1].centerLeft, linePaint);
    canvas.drawLine(nodes[0].centerRight, nodes[2].centerLeft, linePaint);
    canvas.drawLine(nodes[1].centerRight, nodes[3].centerLeft, linePaint);
    canvas.drawLine(nodes[2].centerRight, nodes[3].centerLeft, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniPanelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cardPaint = Paint()..color = const Color(0xFF223548);
    for (int i = 0; i < 4; i++) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(6 + (i % 2) * (size.width * 0.47), 8 + (i ~/ 2) * 34, size.width * 0.40, 24),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, cardPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = const Color(0xFF213548);
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final path = Path()..moveTo(0, size.height * 0.70);
    for (double x = 0; x <= size.width; x++) {
      final t = x / size.width;
      final y = size.height * (0.62 - 0.18 * math.sin(t * 5 * math.pi) - 0.08 * math.sin(t * 12 * math.pi));
      path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(colors: [AppColors.primaryCyan, Color(0xFFA66BFF)]).createShader(Offset.zero & size)
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NeuralGraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pointsA = [
      Offset(size.width * 0.18, size.height * 0.25),
      Offset(size.width * 0.18, size.height * 0.50),
      Offset(size.width * 0.18, size.height * 0.75),
    ];
    final pointsB = [
      Offset(size.width * 0.52, size.height * 0.18),
      Offset(size.width * 0.52, size.height * 0.50),
      Offset(size.width * 0.52, size.height * 0.82),
    ];
    final pointsC = [
      Offset(size.width * 0.84, size.height * 0.28),
      Offset(size.width * 0.84, size.height * 0.70),
    ];
    final linePaint = Paint()
      ..color = const Color(0x668AE7F5)
      ..strokeWidth = 1.2;
    for (final a in pointsA) {
      for (final b in pointsB) {
        canvas.drawLine(a, b, linePaint);
      }
    }
    for (final b in pointsB) {
      for (final c in pointsC) {
        canvas.drawLine(b, c, linePaint);
      }
    }
    for (final p in [...pointsA, ...pointsB, ...pointsC]) {
      canvas.drawCircle(p, 4, Paint()..color = const Color(0xFFA66BFF));
      canvas.drawCircle(p, 10, Paint()..color = const Color(0x22A66BFF));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CueWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(0, size.height / 2);
    for (double x = 0; x <= size.width; x++) {
      final t = x / size.width;
      final mix = Color.lerp(AppColors.primaryCyan, const Color(0xFFA66BFF), t)!;
      final y = size.height / 2 + math.sin(t * 8 * math.pi) * (size.height * 0.22);
      path.lineTo(x, y);
      canvas.drawCircle(Offset(x, y), 0.7, Paint()..color = mix);
    }
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(colors: [AppColors.primaryCyan, Color(0xFFA66BFF)]).createShader(Offset.zero & size)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BleFlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0x668AE7F5)
      ..strokeWidth = 1.4;
    final left = [Offset(20, 18), Offset(20, 46), Offset(20, 74)];
    final center = Offset(size.width / 2, size.height / 2);
    final right = [Offset(size.width - 26, 18), Offset(size.width - 26, 46), Offset(size.width - 26, 74)];
    for (final p in left) {
      canvas.drawLine(p, center, line);
    }
    for (final p in right) {
      canvas.drawLine(center, p, line);
    }
    canvas.drawCircle(center, 18, Paint()..color = const Color(0x2219D8FF));
    canvas.drawCircle(center, 16, Paint()..color = const Color(0xFF102E44));
    final tp = TextPainter(
      text: TextSpan(text: 'B', style: GoogleFonts.orbitron(color: AppColors.primaryCyan, fontSize: 18, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
    for (final p in [...left, ...right]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: 30, height: 18), const Radius.circular(6)),
        Paint()..color = const Color(0xFF213245),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FutureAiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final horizon = size.height * 0.64;
    final path = Path()..moveTo(0, horizon);
    for (double x = 0; x <= size.width; x++) {
      final t = x / size.width;
      final y = horizon - math.sin(t * 3 * math.pi) * 12 - math.sin(t * 8 * math.pi) * 4;
      path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(colors: [AppColors.primaryCyan, Color(0xFFA66BFF)]).createShader(Offset.zero & size)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    for (final x in [0.12, 0.36, 0.58, 0.76, 0.90]) {
      final c = Offset(size.width * x, horizon - 10 - (x * 10));
      canvas.drawCircle(c, 8, Paint()..color = const Color(0x2219D8FF));
      canvas.drawCircle(c, 2.4, Paint()..color = const Color(0xFFA7EEFF));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SafetyWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final colors = [const Color(0xFFFF6B7B), AppColors.primaryCyan, const Color(0xFFFF6B7B)];
    for (int i = 0; i < 12; i++) {
      final x = size.width * (i + 1) / 13;
      final height = (i.isEven ? 0.62 : 0.34) * size.height;
      canvas.drawLine(
        Offset(x, size.height / 2 - height / 2),
        Offset(x, size.height / 2 + height / 2),
        Paint()
          ..color = colors[i % colors.length]
          ..strokeWidth = 2.2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
