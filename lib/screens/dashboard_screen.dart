import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parkinson_insole_app/constants/app_colors.dart';
import 'package:parkinson_insole_app/constants/app_strings.dart';
import 'package:parkinson_insole_app/models/insole_device.dart';
import 'package:parkinson_insole_app/providers/ble_provider.dart';
import 'package:parkinson_insole_app/providers/telemetry_provider.dart';
import 'package:parkinson_insole_app/providers/settings_provider.dart';
import 'package:parkinson_insole_app/models/cue_settings.dart';
import 'package:parkinson_insole_app/models/telemetry_data.dart';

/// Fully Responsive Dashboard Screen.
/// Fits wide desktop viewports (exactly matching the user design) and narrow mobile screens.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  int _selectedTab = 0;
  late Timer _sessionTimer;
  Duration _sessionDuration = const Duration(hours: 1, minutes: 30, seconds: 13);
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    // Live session duration ticking
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _sessionDuration += const Duration(seconds: 1);
        });
      }
    });

    // Wave animation controller (for animated ECG waves and haptic vibrations)
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _sessionTimer.cancel();
    _waveController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${d.inHours}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}';
  }

  void _onTabTapped(int index) {
    if (index == 0) {
      setState(() => _selectedTab = 0);
    } else {
      const routes = ['', '/scan', '/status', '/settings', '/debug'];
      Navigator.pushNamed(context, routes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 1050;
        if (isDesktop) {
          return _buildDesktopLayout(context);
        } else {
          return _buildMobileLayout(context);
        }
      },
    );
  }

  // ── DESKTOP GRID LAYOUT ──────────────────────────────────────────────────
  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // 1. Sidebar Navigation (Left)
          _buildSidebar(context),

          // Divider line
          Container(
            width: 1,
            color: AppColors.cardBorder,
          ),

          // 2. Main content viewport
          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Header
                    _buildHeader(context),
                    const SizedBox(height: 24),

                    // Grid Workspace
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Grid Area (Telemetry, Insoles, Cues)
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildRealTimeMonitoringSection(context),
                              const SizedBox(height: 20),
                              _buildAdaptiveCueSettingsSection(context),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),

                        // Right Grid Area (AI Analytics, Emergency)
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildAnalyticsSection(context),
                              const SizedBox(height: 20),
                              _buildEmergencySection(context),
                            ],
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

  // ── MOBILE LAYOUT ────────────────────────────────────────────────────────
  Widget _buildMobileLayout(BuildContext context) {
    return Consumer3<BleProvider, TelemetryProvider, SettingsProvider>(
      builder: (context, ble, tele, settings, _) {
        final hasFOGAlert = tele.fogRiskLevel >= 50;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.appName, style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(
                  AppStrings.appTagline,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: AppColors.primaryCyan),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Insole Cards (stacked)
                _buildMobileInsoleCard(context, true, ble.connectedDeviceLeft, tele.leftData),
                const SizedBox(height: 16),
                _buildMobileInsoleCard(context, false, ble.connectedDeviceRight, tele.rightData),
                const SizedBox(height: 16),

                // FOG Alert status banner if elevated
                if (hasFOGAlert) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.alertRed.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.alertRed.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.alertRed),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'FOG risk Status',
                                style: GoogleFonts.orbitron(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'Freezing Risk probability is currently high (${tele.fogRiskLevel.toStringAsFixed(0)}%)',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                      .fade(duration: 1000.ms, begin: 0.7, end: 1.0),
                  const SizedBox(height: 16),
                ],

                // Audio Cue widget
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.volume_up_outlined, color: AppColors.primaryCyan),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.audioCue,
                                  style: GoogleFonts.orbitron(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'LRA Vibration / Audio cues',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: settings.cueSettings.audioCueEnabled,
                            onChanged: (v) => settings.updateCueSettings(
                              settings.cueSettings.copyWith(audioCueEnabled: v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Intensity', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          Expanded(
                            child: Slider(
                              value: settings.cueSettings.audioVolume,
                              onChanged: (v) => settings.updateCueSettings(
                                settings.cueSettings.copyWith(audioVolume: v),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Sound pattern', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          DropdownButton<CuePattern>(
                            value: settings.cueSettings.pattern,
                            dropdownColor: AppColors.surface,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                            onChanged: (pat) {
                              if (pat != null) {
                                settings.updateCueSettings(
                                  settings.cueSettings.copyWith(pattern: pat),
                                );
                              }
                            },
                            items: const [
                              DropdownMenuItem(value: CuePattern.rhythmic, child: Text('Sound (Rhythmic)')),
                              DropdownMenuItem(value: CuePattern.adaptive, child: Text('Adaptive')),
                              DropdownMenuItem(value: CuePattern.burst, child: Text('Burst')),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Large mobile SOS trigger button
                Container(
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.alertRed.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.alertRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => _showSosAlert(context),
                    child: Text(
                      'SOS',
                      style: GoogleFonts.orbitron(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
          bottomNavigationBar: _BottomNav(
            selectedIndex: _selectedTab,
            onTap: _onTabTapped,
          ),
        );
      },
    );
  }

  // ── DESKTOP SUBCOMPONENTS ────────────────────────────────────────────────

  // Left Navigation Sidebar
  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 72,
      color: AppColors.cardBackground,
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Logo Icon
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

          // Menu items
          _buildSidebarIcon(Icons.grid_view_rounded, true, () {}),
          _buildSidebarIcon(Icons.analytics_outlined, false, () {}),
          _buildSidebarIcon(Icons.monitor_heart_outlined, false, () => Navigator.pushNamed(context, '/status')),
          _buildSidebarIcon(Icons.settings_outlined, false, () => Navigator.pushNamed(context, '/settings')),
          _buildSidebarIcon(Icons.bug_report_outlined, false, () => Navigator.pushNamed(context, '/debug')),
          _buildSidebarIcon(Icons.help_outline, false, () {}),

          const Spacer(),

          // Logout
          _buildSidebarIcon(Icons.logout_rounded, false, () {
            // Direct navigate back to authentication screen
            Navigator.pushReplacementNamed(context, '/auth');
          }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSidebarIcon(IconData icon, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
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
          ),
          child: Icon(
            icon,
            color: active ? AppColors.primaryCyan : AppColors.textSecondary,
            size: 22,
          ),
        ),
      ),
    );
  }

  // Top Header Area
  Widget _buildHeader(BuildContext context) {
    return Consumer2<BleProvider, TelemetryProvider>(
      builder: (context, ble, tele, _) {
        final avgBatteryL = tele.leftData.batteryLevel;
        final avgBatteryR = tele.rightData.batteryLevel;

        return Row(
          children: [
            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FOG Detection System',
                    style: GoogleFonts.orbitron(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    AppStrings.appTagline,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // AI node graphics placeholder
            Container(
              width: 140,
              height: 50,
              margin: const EdgeInsets.only(right: 24),
              child: CustomPaint(
                painter: _AiNetworkPainter(),
              ),
            ),

            // Session Stats, Profile, Bell
            Row(
              children: [
                // Notification Bell
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none, color: AppColors.textPrimary, size: 22),
                      onPressed: () {},
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.alertRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                // Stats & Profile Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      // Profile Avatar
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.surface,
                        child: const Icon(Icons.person, color: AppColors.primaryCyan, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Robert Jensen',
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.access_time_filled, color: AppColors.textSecondary, size: 10),
                              const SizedBox(width: 4),
                              Text(
                                _formatDuration(_sessionDuration),
                                style: GoogleFonts.orbitron(color: AppColors.textSecondary, fontSize: 10),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.sync, color: AppColors.accentGreen, size: 10),
                              const SizedBox(width: 4),
                              Text(
                                'L: $avgBatteryL% | R: $avgBatteryR%',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ── LEFT SIDE GRIDS ──────────────────────────────────────────────────────

  // Real-Time Monitoring Insoles
  Widget _buildRealTimeMonitoringSection(BuildContext context) {
    return Consumer2<BleProvider, TelemetryProvider>(
      builder: (context, ble, tele, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Real-Time Monitoring',
                    style: GoogleFonts.orbitron(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.alertRed,
                          shape: BoxShape.circle,
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true))
                          .fade(duration: 800.ms),
                      const SizedBox(width: 6),
                      Text(
                        'Live Walking Session',
                        style: GoogleFonts.orbitron(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Insoles Side-by-Side
              Row(
                children: [
                  Expanded(
                    child: _buildDesktopInsoleCard(
                      context,
                      true,
                      ble.connectedDeviceLeft,
                      tele.leftData,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDesktopInsoleCard(
                      context,
                      false,
                      ble.connectedDeviceRight,
                      tele.rightData,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Desktop Individual Insole Card
  Widget _buildDesktopInsoleCard(
    BuildContext context,
    bool isLeft,
    InsoleDevice? device,
    TelemetryData telemetry,
  ) {
    final color = isLeft ? AppColors.leftInsole : AppColors.rightInsole;
    final name = isLeft ? 'Left Insole' : 'Right Insole';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Text(
                name,
                style: GoogleFonts.orbitron(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              const Icon(Icons.bluetooth, color: AppColors.accentGreen, size: 12),
              const SizedBox(width: 4),
              const Text('Connected', style: TextStyle(color: AppColors.accentGreen, fontSize: 10)),
              const SizedBox(width: 8),
              Icon(Icons.battery_4_bar_rounded, color: color, size: 14),
              Text('${telemetry.batteryLevel}%', style: TextStyle(color: color, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 16),

          // Foot visualization & Telemetry parameters
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom foot painter widget
              SizedBox(
                width: 90,
                height: 160,
                child: CustomPaint(
                  painter: _FootSilhouettePainter(
                    isLeft: isLeft,
                    pressure: telemetry.pressure,
                    accentColor: color,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Telemetry values columns
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTelemetryProgressRow('Gait Stability', telemetry.gaitStability, '%', AppColors.accentGreen, 0.7),
                    const SizedBox(height: 12),
                    _buildTelemetryProgressRow('FOG Risk', telemetry.fogRisk, '%', AppColors.warningOrange, 0.1),
                    const SizedBox(height: 12),
                    _buildTelemetryProgressRow('Step Cadence', telemetry.stepCadence, '', color, 0.8),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Bottom live ECG wave
          SizedBox(
            height: 24,
            child: CustomPaint(
              painter: _LiveWavePainter(
                animValue: _waveController.value,
                lineColor: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryProgressRow(String label, double value, String unit, Color tint, double progressRatio) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
              Row(
                textBaseline: TextBaseline.alphabetic,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                children: [
                  Text(
                    value.toStringAsFixed(1),
                    style: GoogleFonts.orbitron(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(unit, style: const TextStyle(color: AppColors.textSecondary, fontSize: 8)),
                ],
              ),
            ],
          ),
        ),
        // Visual circular progress ring
        SizedBox(
          width: 32,
          height: 32,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progressRatio,
                strokeWidth: 3,
                backgroundColor: AppColors.surface,
                valueColor: AlwaysStoppedAnimation<Color>(tint),
              ),
              Text(
                '${(progressRatio * 100).toInt()}',
                style: const TextStyle(fontSize: 8, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Mobile Foot Outline Layout Card
  Widget _buildMobileInsoleCard(
    BuildContext context,
    bool isLeft,
    InsoleDevice? device,
    TelemetryData telemetry,
  ) {
    final color = isLeft ? AppColors.leftInsole : AppColors.rightInsole;
    final name = isLeft ? 'Left Insole' : 'Right Insole';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                name,
                style: GoogleFonts.orbitron(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              const Icon(Icons.bluetooth, color: AppColors.accentGreen, size: 14),
              const SizedBox(width: 4),
              const Text('Connected', style: TextStyle(color: AppColors.accentGreen, fontSize: 11)),
              const SizedBox(width: 10),
              Icon(Icons.battery_4_bar_rounded, color: color, size: 16),
              Text('${telemetry.batteryLevel}%', style: TextStyle(color: color, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Foot Outline
              SizedBox(
                width: 70,
                height: 120,
                child: CustomPaint(
                  painter: _FootSilhouettePainter(
                    isLeft: isLeft,
                    pressure: telemetry.pressure,
                    accentColor: color,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Gait Stability', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        Text('${telemetry.gaitStability.toStringAsFixed(0)}%', style: TextStyle(color: AppColors.accentGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('FOG Risk', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        Text('${telemetry.fogRisk.toStringAsFixed(0)}%', style: TextStyle(color: AppColors.warningOrange, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Step Cadence', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        Text('${telemetry.stepCadence.toStringAsFixed(0)} steps/min', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Adaptive Cue Settings Panel
  Widget _buildAdaptiveCueSettingsSection(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final modeIsAuto = settings.cueSettings.mode == CueMode.auto;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title Header & Mode Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Adaptive Cue Settings Panel',
                    style: GoogleFonts.orbitron(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Row(
                      children: [
                        _buildModeButton('Auto', modeIsAuto, () {
                          settings.updateCueSettings(settings.cueSettings.copyWith(mode: CueMode.auto));
                        }),
                        _buildModeButton('Manual', !modeIsAuto, () {
                          settings.updateCueSettings(settings.cueSettings.copyWith(mode: CueMode.manual));
                        }),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Cues Grid Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Visual Cue
                  Expanded(
                    child: _buildCueTile(
                      'Visual Cue',
                      'Laser Projection',
                      settings.cueSettings.visualCueEnabled,
                      settings.cueSettings.visualIntensity,
                      AppColors.primaryCyan,
                      (v) => settings.updateCueSettings(settings.cueSettings.copyWith(visualCueEnabled: v)),
                      (val) => settings.updateCueSettings(settings.cueSettings.copyWith(visualIntensity: val)),
                      null,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Haptic Cue
                  Expanded(
                    child: _buildCueTile(
                      'Haptic Cue',
                      'LRA Vibration',
                      settings.cueSettings.hapticCueEnabled,
                      settings.cueSettings.hapticIntensity,
                      AppColors.secondaryPurple,
                      (v) => settings.updateCueSettings(settings.cueSettings.copyWith(hapticCueEnabled: v)),
                      (val) => settings.updateCueSettings(settings.cueSettings.copyWith(hapticIntensity: val)),
                      SizedBox(
                        height: 24,
                        child: CustomPaint(
                          painter: _LiveWavePainter(
                            animValue: _waveController.value,
                            lineColor: AppColors.secondaryPurple,
                            isSine: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Audio Cue
                  Expanded(
                    child: _buildCueTile(
                      'Audio Cue',
                      'Rhythmic Tones',
                      settings.cueSettings.audioCueEnabled,
                      settings.cueSettings.audioVolume,
                      AppColors.accentGreen,
                      (v) => settings.updateCueSettings(settings.cueSettings.copyWith(audioCueEnabled: v)),
                      (val) => settings.updateCueSettings(settings.cueSettings.copyWith(audioVolume: val)),
                      DropdownButtonHideUnderline(
                        child: Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: DropdownButton<CuePattern>(
                            value: settings.cueSettings.pattern,
                            dropdownColor: AppColors.surface,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
                            icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 16),
                            onChanged: (pat) {
                              if (pat != null) {
                                settings.updateCueSettings(settings.cueSettings.copyWith(pattern: pat));
                              }
                            },
                            items: const [
                              DropdownMenuItem(value: CuePattern.rhythmic, child: Text('Sound (Rhythmic)')),
                              DropdownMenuItem(value: CuePattern.adaptive, child: Text('Adaptive')),
                              DropdownMenuItem(value: CuePattern.burst, child: Text('Burst')),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Sync Checkbox / toggle
              Row(
                children: [
                  const Text('Sync', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  const SizedBox(width: 8),
                  Transform.scale(
                    scale: 0.8,
                    child: Checkbox(
                      value: settings.cueSettings.syncLeftRight,
                      activeColor: AppColors.primaryCyan,
                      onChanged: (v) {
                        if (v != null) {
                          settings.updateCueSettings(settings.cueSettings.copyWith(syncLeftRight: v));
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeButton(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.cardBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.primaryCyan : AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCueTile(
    String title,
    String desc,
    bool enabled,
    double intensity,
    Color activeColor,
    ValueChanged<bool> onToggle,
    ValueChanged<double> onSlider,
    Widget? extraChild,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.orbitron(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 9)),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: enabled,
                  activeColor: activeColor,
                  onChanged: onToggle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Intensity', style: TextStyle(color: AppColors.textSecondary, fontSize: 9)),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: activeColor,
                    thumbColor: activeColor,
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  ),
                  child: Slider(
                    value: intensity,
                    onChanged: onSlider,
                  ),
                ),
              ),
            ],
          ),
          if (extraChild != null) ...[
            const SizedBox(height: 8),
            extraChild,
          ],
        ],
      ),
    );
  }

  // ── RIGHT SIDE GRIDS ─────────────────────────────────────────────────────

  // AI Analytics Cards
  Widget _buildAnalyticsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'AI Analytics',
            style: GoogleFonts.orbitron(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),

          // 2x2 Grid of analytics charts
          Row(
            children: [
              // Gait Asymmetry Radar Graph
              Expanded(
                child: _buildChartBox(
                  'Gait Asymmetry Graph',
                  SizedBox(
                    height: 110,
                    child: CustomPaint(
                      painter: _RadarChartPainter(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // FOG Probability Timeline
              Expanded(
                child: _buildChartBox(
                  'FOG Probability Timeline',
                  SizedBox(
                    height: 110,
                    child: CustomPaint(
                      painter: _TimelineChartPainter(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Pressure Distribution Graph
              Expanded(
                child: _buildChartBox(
                  'Pressure Distribution Graph',
                  SizedBox(
                    height: 110,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildDoubleBar(0.8, 0.7, 'Zone'),
                        _buildDoubleBar(0.4, 0.5, 'Zones'),
                        _buildDoubleBar(0.6, 0.8, 'Zonet'),
                        _buildDoubleBar(0.9, 0.7, 'Zonest'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Confidence Score Progress circles
              Expanded(
                child: _buildChartBox(
                  'Walking Confidence Score & AI Prediction Confidence',
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCircularIndicator('50', '% Score', AppColors.primaryCyan),
                      _buildCircularIndicator('30', 'AI Prediction', AppColors.secondaryPurple),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartBox(String title, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(12),
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.orbitron(color: AppColors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 14),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(child: Center(child: chart)),
        ],
      ),
    );
  }

  Widget _buildDoubleBar(double valL, double valR, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 6,
              height: 70 * valL,
              decoration: BoxDecoration(
                color: AppColors.primaryCyan,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 3),
            Container(
              width: 6,
              height: 70 * valR,
              decoration: BoxDecoration(
                color: AppColors.secondaryPurple,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 8, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildCircularIndicator(String value, String label, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: double.parse(value) / 100,
                strokeWidth: 4.5,
                backgroundColor: AppColors.surface,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Text(
                value,
                style: GoogleFonts.orbitron(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 7, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Emergency & Safety Section
  Widget _buildEmergencySection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Emergency & Safety Features',
            style: GoogleFonts.orbitron(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column (Fall detection, caregiver panel)
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Fall Detection Status Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.alertRed.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.alertRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Fall Detection', style: TextStyle(color: AppColors.textSecondary, fontSize: 9)),
                                Text('Monitoring Active', style: GoogleFonts.orbitron(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Caregiver Notification Panel (Logs list)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Caregiver Notification Panel', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          _buildLogItem('Status update log', true),
                          const SizedBox(height: 4),
                          _buildLogItem('Status update log', false),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Right Column (Emergency contact, SOS trigger)
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Emergency Contact Button
                    InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.phone_in_talk_outlined, color: AppColors.textSecondary, size: 14),
                            SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Emergency Contact', style: TextStyle(color: AppColors.textPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
                                  Text('Quick dial/message', style: TextStyle(color: AppColors.textSecondary, fontSize: 8)),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 12),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // SOS Trigger Button
                    Container(
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.alertRed.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.alertRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _showSosAlert(context),
                        child: Text(
                          'SOS Trigger',
                          style: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Overall Health Status
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, color: AppColors.accentGreen, size: 12),
                          SizedBox(width: 6),
                          Text('Overall Health Status', style: TextStyle(color: AppColors.accentGreen, fontSize: 9, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(String message, bool isCyan) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: isCyan ? AppColors.primaryCyan : AppColors.secondaryPurple,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(message, style: const TextStyle(color: AppColors.textSecondary, fontSize: 9)),
      ],
    );
  }

  void _showSosAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('SOS Alert Triggered'),
        content: const Text(
          'An emergency notification is being dispatched to Robert Jensen\'s caregivers. Keep BLE connection active.',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.alertRed),
            onPressed: () => Navigator.pop(context),
            child: const Text('DISMISS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── CUSTOM PAINTERS ─────────────────────────────────────────────────────────

// 1. Brain/AI Node network graphics (Header Center)
class _AiNetworkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = AppColors.primaryCyan.withOpacity(0.3)
      ..strokeWidth = 1;
    final paintNode = Paint()
      ..color = AppColors.primaryCyan
      ..style = PaintingStyle.fill;
    final paintCenter = Paint()
      ..color = AppColors.secondaryPurple
      ..style = PaintingStyle.fill;

    // Node locations
    final nodes = [
      Offset(15, size.height / 2),
      Offset(40, 10),
      Offset(40, size.height - 10),
      Offset(70, size.height / 2), // AI box
      Offset(100, 10),
      Offset(100, size.height - 10),
      Offset(125, size.height / 2),
    ];

    // Connections
    canvas.drawLine(nodes[0], nodes[1], paintLine);
    canvas.drawLine(nodes[0], nodes[2], paintLine);
    canvas.drawLine(nodes[1], nodes[3], paintLine);
    canvas.drawLine(nodes[2], nodes[3], paintLine);
    canvas.drawLine(nodes[3], nodes[4], paintLine);
    canvas.drawLine(nodes[3], nodes[5], paintLine);
    canvas.drawLine(nodes[4], nodes[6], paintLine);
    canvas.drawLine(nodes[5], nodes[6], paintLine);
    canvas.drawLine(nodes[1], nodes[4], paintLine);
    canvas.drawLine(nodes[2], nodes[5], paintLine);

    // Draw node circles
    for (int i = 0; i < nodes.length; i++) {
      if (i == 3) {
        // Center node represents AI
        canvas.drawCircle(nodes[i], 6, paintCenter);
      } else {
        canvas.drawCircle(nodes[i], 3, paintNode);
      }
    }

    // AI Badge Text
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'AI',
        style: TextStyle(
          color: Colors.white,
          fontSize: 7,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(nodes[3].dx - 4, nodes[3].dy - 5));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 2. High fidelity foot outline with pressure hotspots
class _FootSilhouettePainter extends CustomPainter {
  final bool isLeft;
  final PressureZone pressure;
  final Color accentColor;

  _FootSilhouettePainter({
    required this.isLeft,
    required this.pressure,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Draw general foot outline path
    final outlinePaint = Paint()
      ..color = accentColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fillPaint = Paint()
      ..color = accentColor.withOpacity(0.04)
      ..style = PaintingStyle.fill;

    final path = Path();
    if (isLeft) {
      // Draw left foot outline silhouette
      path.moveTo(w * 0.5, h * 0.05); // Toes top
      path.quadraticBezierTo(w * 0.15, h * 0.15, w * 0.25, h * 0.4); // Outer side
      path.quadraticBezierTo(w * 0.45, h * 0.6, w * 0.4, h * 0.78); // Inner arch
      path.quadraticBezierTo(w * 0.35, h * 0.95, w * 0.55, h * 0.95); // Heel base
      path.quadraticBezierTo(w * 0.75, h * 0.9, w * 0.7, h * 0.75); // Inner heel
      path.quadraticBezierTo(w * 0.6, h * 0.5, w * 0.8, h * 0.3); // Inner ball
      path.quadraticBezierTo(w * 0.8, h * 0.05, w * 0.5, h * 0.05); // Back to toes
    } else {
      // Draw right foot outline silhouette (mirrored)
      path.moveTo(w * 0.5, h * 0.05);
      path.quadraticBezierTo(w * 0.85, h * 0.15, w * 0.75, h * 0.4);
      path.quadraticBezierTo(w * 0.55, h * 0.6, w * 0.6, h * 0.78);
      path.quadraticBezierTo(w * 0.65, h * 0.95, w * 0.45, h * 0.95);
      path.quadraticBezierTo(w * 0.25, h * 0.9, w * 0.3, h * 0.75);
      path.quadraticBezierTo(w * 0.4, h * 0.5, w * 0.2, h * 0.3);
      path.quadraticBezierTo(w * 0.2, h * 0.05, w * 0.5, h * 0.05);
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, outlinePaint);

    // Dynamic Pressure Hotspots
    final zones = pressure.normalized; // [heel, midfoot, forefoot, toe]

    final heelCenter = Offset(w * 0.5, h * 0.8);
    final midfootCenter = isLeft ? Offset(w * 0.45, h * 0.55) : Offset(w * 0.55, h * 0.55);
    final forefootCenter = isLeft ? Offset(w * 0.42, h * 0.3) : Offset(w * 0.58, h * 0.3);
    final toeCenter = Offset(w * 0.5, h * 0.13);

    _drawHotspot(canvas, heelCenter, zones[0], AppColors.glowCyan);
    _drawHotspot(canvas, midfootCenter, zones[1], AppColors.glowGreen);
    _drawHotspot(canvas, forefootCenter, zones[2], AppColors.glowOrange);
    _drawHotspot(canvas, toeCenter, zones[3], AppColors.glowRed);
  }

  void _drawHotspot(Canvas canvas, Offset center, double intensity, Color baseColor) {
    if (intensity <= 0.02) return;

    final radius = 10.0 + (intensity * 25.0);
    final paintGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          baseColor.withOpacity(0.9 * intensity),
          baseColor.withOpacity(0.3 * intensity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paintGlow);

    // Inner bright point
    final paintPoint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2, paintPoint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 3. Animated Live ECG wave & vibrating wave lines
class _LiveWavePainter extends CustomPainter {
  final double animValue;
  final Color lineColor;
  final bool isSine;

  _LiveWavePainter({
    required this.animValue,
    required this.lineColor,
    this.isSine = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(0, h / 2);

    if (isSine) {
      // Smooth sinusoidal vibration wave (Haptic representation)
      for (double x = 0; x <= w; x++) {
        final double phase = (x / w) * 4 * math.pi + (animValue * 2 * math.pi);
        final double y = (h / 2) + math.sin(phase) * (h / 2.5);
        path.lineTo(x, y);
      }
    } else {
      // Heartbeat/ECG spike style wave (Live gait sensor representation)
      for (double x = 0; x <= w; x++) {
        double y = h / 2;

        // Create cyclic spike groups
        final double relativeX = (x / w) - animValue;
        final double cyclePos = (relativeX * 3) % 1.0;

        if (cyclePos > 0.4 && cyclePos < 0.45) {
          // Sharp QRS Spike
          y = (h / 2) - ((cyclePos - 0.4) * 20 * h);
        } else if (cyclePos >= 0.45 && cyclePos < 0.5) {
          // Deep drop
          y = (h / 2) + ((0.5 - cyclePos) * 15 * h);
        } else if (cyclePos >= 0.6 && cyclePos < 0.7) {
          // Small bump
          y = (h / 2) - (math.sin((cyclePos - 0.6) * 10 * math.pi) * (h / 4));
        }

        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 4. Gait Asymmetry Radar pentagon grid & filled region
class _RadarChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.height / 2.5;

    final linePaint = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = AppColors.primaryCyan.withOpacity(0.35)
      ..style = PaintingStyle.fill;

    final strokeDataPaint = Paint()
      ..color = AppColors.primaryCyan
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw concentric pentagons (3 levels)
    for (int r = 1; r <= 3; r++) {
      final currentRadius = radius * (r / 3.0);
      final path = Path();
      for (int i = 0; i < 5; i++) {
        final angle = (i * 2 * math.pi / 5) - (math.pi / 2);
        final x = center.dx + currentRadius * math.cos(angle);
        final y = center.dy + currentRadius * math.sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, linePaint);
    }

    // Draw axis lines from center
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi / 5) - (math.pi / 2);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), linePaint);
    }

    // Draw patient gait asymmetrical data points (simulated values)
    final values = [0.8, 0.55, 0.75, 0.45, 0.85];
    final dataPath = Path();
    for (int i = 0; i < 5; i++) {
      final currentRadius = radius * values[i];
      final angle = (i * 2 * math.pi / 5) - (math.pi / 2);
      final x = center.dx + currentRadius * math.cos(angle);
      final y = center.dy + currentRadius * math.sin(angle);
      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();

    canvas.drawPath(dataPath, fillPaint);
    canvas.drawPath(dataPath, strokeDataPaint);

    // Small data dots
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 5; i++) {
      final currentRadius = radius * values[i];
      final angle = (i * 2 * math.pi / 5) - (math.pi / 2);
      final x = center.dx + currentRadius * math.cos(angle);
      final y = center.dy + currentRadius * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 5. Smooth curve line chart showing FOG probability timeline
class _TimelineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final gridPaint = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 0.5;

    final linePaint = Paint()
      ..color = AppColors.secondaryPurple
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final gradientPaint = Paint()
      ..style = PaintingStyle.fill;

    // Draw horizontal grid lines
    canvas.drawLine(Offset(0, h * 0.25), Offset(w, h * 0.25), gridPaint);
    canvas.drawLine(Offset(0, h * 0.5), Offset(w, h * 0.5), gridPaint);
    canvas.drawLine(Offset(0, h * 0.75), Offset(w, h * 0.75), gridPaint);

    // Timeline spline data points
    final points = [
      Offset(0, h * 0.8),
      Offset(w * 0.15, h * 0.75),
      Offset(w * 0.3, h * 0.4),
      Offset(w * 0.45, h * 0.65),
      Offset(w * 0.6, h * 0.2),
      Offset(w * 0.75, h * 0.35),
      Offset(w * 0.9, h * 0.5),
      Offset(w, h * 0.45),
    ];

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final controlX = p1.dx + (p2.dx - p1.dx) / 2;
      path.cubicTo(controlX, p1.dy, controlX, p2.dy, p2.dx, p2.dy);
    }

    // Gradient fill path underneath curve
    final fillPath = Path.from(path);
    fillPath.lineTo(w, h);
    fillPath.lineTo(0, h);
    fillPath.close();

    final gradient = LinearGradient(
      colors: [
        AppColors.secondaryPurple.withOpacity(0.4),
        Colors.transparent,
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    gradientPaint.shader = gradient.createShader(Rect.fromLTRB(0, h * 0.2, w, h));

    canvas.drawPath(fillPath, gradientPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Shared Bottom Navigation widget ─────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bluetooth_searching),
          label: 'Scan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.monitor_heart_outlined),
          label: 'Status',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          label: 'Settings',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bug_report_outlined),
          label: 'Debug',
        ),
      ],
    );
  }
}
