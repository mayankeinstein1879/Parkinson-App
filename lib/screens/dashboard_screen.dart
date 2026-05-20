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

  // Desktop Individual Insole Card — premium pixel-faithful to reference image
  Widget _buildDesktopInsoleCard(
    BuildContext context,
    bool isLeft,
    InsoleDevice? device,
    TelemetryData telemetry,
  ) {
    final color = isLeft ? AppColors.leftInsole : AppColors.rightInsole;
    final glowColor = isLeft
        ? const Color(0xFF00E5FF).withOpacity(0.18)
        : const Color(0xFF7B2FFF).withOpacity(0.18);
    final borderGlow = isLeft
        ? const Color(0xFF00E5FF).withOpacity(0.45)
        : const Color(0xFF7B2FFF).withOpacity(0.45);
    final name = isLeft ? 'Left Insole' : 'Right Insole';
    final isConnected = device != null;

    final gaitStability = isConnected ? telemetry.gaitStability : 0.0;
    final fogRisk       = isConnected ? telemetry.fogRisk       : 0.0;
    final stepCadence   = isConnected ? telemetry.stepCadence   : 0.0;
    final battery       = isConnected ? telemetry.batteryLevel  : 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF071526),
            const Color(0xFF0C1F3A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderGlow, width: 1.5),
        boxShadow: [
          BoxShadow(color: glowColor, blurRadius: 24, spreadRadius: 2, offset: Offset.zero),
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 12, spreadRadius: -2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header: Name | BLE badge + battery ring ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                name,
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              // BLE label
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.bluetooth, color: AppColors.primaryCyan, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        'BLE',
                        style: GoogleFonts.orbitron(
                          color: AppColors.primaryCyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Circular battery gauge
                      _GlowRing(
                        size: 34,
                        value: isConnected ? battery / 100.0 : 0.0,
                        ringColor: AppColors.accentGreen,
                        strokeWidth: 3.0,
                        child: Icon(
                          Icons.battery_charging_full,
                          color: isConnected ? AppColors.accentGreen : AppColors.textDisabled,
                          size: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                        color: isConnected ? AppColors.accentGreen : AppColors.alertRed,
                        size: 11,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        isConnected ? 'Connected' : 'Disconnected',
                        style: TextStyle(
                          color: isConnected ? AppColors.accentGreen : AppColors.alertRed,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Body: Foot + Metrics ──
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Glowing foot silhouette
                SizedBox(
                  width: 88,
                  child: CustomPaint(
                    painter: _FootSilhouettePainter(
                      isLeft: isLeft,
                      pressure: telemetry.pressure,
                      accentColor: color,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Metrics column
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _PremiumMetricRow(
                        label: 'Gait Stability',
                        subLabel: 'Score (%)',
                        value: gaitStability,
                        displaySuffix: '',
                        ringColor: AppColors.accentGreen,
                        ringValue: isConnected ? gaitStability / 100.0 : 0.0,
                        ringLabel: gaitStability.toStringAsFixed(0),
                      ),
                      const SizedBox(height: 8),
                      _PremiumMetricRow(
                        label: 'FOG Risk',
                        subLabel: 'Percentage',
                        value: fogRisk,
                        displaySuffix: '%',
                        ringColor: AppColors.warningOrange,
                        ringValue: isConnected ? fogRisk / 100.0 : 0.0,
                        ringLabel: fogRisk.toStringAsFixed(0),
                      ),
                      const SizedBox(height: 8),
                      _PremiumMetricRow(
                        label: 'Step Cadence',
                        subLabel: '(steps/min)',
                        value: stepCadence,
                        displaySuffix: '',
                        ringColor: color,
                        ringValue: isConnected ? (stepCadence / 200.0).clamp(0.0, 1.0) : 0.0,
                        ringLabel: stepCadence.toStringAsFixed(0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── ECG heartbeat wave ──
          SizedBox(
            height: 30,
            child: CustomPaint(
              painter: _LiveWavePainter(
                animValue: _waveController.value,
                lineColor: isConnected ? color : AppColors.textSecondary.withOpacity(0.15),
                strokeWidth: isConnected ? 1.8 : 1.0,
                glowColor: isConnected ? color.withOpacity(0.4) : Colors.transparent,
                isFlat: !isConnected,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageStyleMetricRow({
    required String label,
    required String subLabel,
    required double value,
    required String displaySuffix,
    required Color ringColor,
    required double ringValue,
    required String ringLabel,
  }) {
    return _PremiumMetricRow(
      label: label,
      subLabel: subLabel,
      value: value,
      displaySuffix: displaySuffix,
      ringColor: ringColor,
      ringValue: ringValue,
      ringLabel: ringLabel,
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

    final isConnected = device != null;

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
                  color: isConnected ? color : AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Icon(
                isConnected ? Icons.bluetooth : Icons.bluetooth_disabled,
                color: isConnected ? AppColors.accentGreen : AppColors.alertRed,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                isConnected ? 'Connected' : 'Disconnected',
                style: TextStyle(
                  color: isConnected ? AppColors.accentGreen : AppColors.alertRed,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                isConnected ? Icons.battery_4_bar_rounded : Icons.battery_0_bar_rounded,
                color: isConnected ? color : AppColors.textSecondary,
                size: 16,
              ),
              Text(
                isConnected ? '${telemetry.batteryLevel}%' : '0%',
                style: TextStyle(
                  color: isConnected ? color : AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
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

// ── PREMIUM REUSABLE WIDGETS ─────────────────────────────────────────────────

/// A circular progress ring with optional glow shadow and a centered child widget.
class _GlowRing extends StatelessWidget {
  final double size;
  final double value;      // 0.0 – 1.0
  final Color ringColor;
  final double strokeWidth;
  final Widget child;

  const _GlowRing({
    required this.size,
    required this.value,
    required this.ringColor,
    required this.strokeWidth,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft glow behind the ring
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ringColor.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          CircularProgressIndicator(
            value: value,
            strokeWidth: strokeWidth,
            backgroundColor: const Color(0xFF0D1B2E),
            valueColor: AlwaysStoppedAnimation<Color>(ringColor),
          ),
          child,
        ],
      ),
    );
  }
}

/// Premium metric row matching the reference image:
/// bold white label → large purple Orbitron value → grey sublabel | neon ring w/ number
class _PremiumMetricRow extends StatelessWidget {
  final String label;
  final String subLabel;
  final double value;
  final String displaySuffix;
  final Color ringColor;
  final double ringValue;   // 0.0 – 1.0
  final String ringLabel;

  const _PremiumMetricRow({
    required this.label,
    required this.subLabel,
    required this.value,
    required this.displaySuffix,
    required this.ringColor,
    required this.ringValue,
    required this.ringLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left: label stack
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value.toStringAsFixed(1) + displaySuffix,
                style: GoogleFonts.orbitron(
                  color: const Color(0xFF9B6FFF), // vivid purple matching reference
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              Text(
                subLabel,
                style: const TextStyle(
                  color: Color(0xFF5A7A9A),
                  fontSize: 9,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        // Right: neon circular ring
        _GlowRing(
          size: 48,
          value: ringValue,
          ringColor: ringColor,
          strokeWidth: 3.5,
          child: Text(
            ringLabel,
            style: TextStyle(
              color: ringColor,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ── CUSTOM PAINTERS ───────────────────────────────────────────────────────────

// 2. Premium foot outline — gradient fill + glow border + bright pressure hotspots
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

    final path = _buildFootPath(w, h);

    // ── 1. Outer ambient glow (large soft shadow around foot shape) ──
    final glowPaint = Paint()
      ..color = accentColor.withOpacity(0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, glowPaint);

    // ── 2. Gradient fill inside foot ──
    final rect = Rect.fromLTWH(0, 0, w, h);
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          accentColor.withOpacity(0.22),
          accentColor.withOpacity(0.06),
          const Color(0xFF0080FF).withOpacity(0.04),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // ── 3. Glowing outline ──
    final outlineGlowPaint = Paint()
      ..color = accentColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, outlineGlowPaint);

    final outlinePaint = Paint()
      ..color = accentColor.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, outlinePaint);

    // ── 4. Pulse ring at midfoot ──
    final midCenter = Offset(w * 0.5, h * 0.62);
    _drawPulseRing(canvas, midCenter, w * 0.38, accentColor);

    // ── 5. Pressure hotspots ──
    final zones = pressure.normalized;
    final heelCenter     = Offset(w * 0.50, h * 0.82);
    final midfootCenter  = isLeft ? Offset(w * 0.44, h * 0.56) : Offset(w * 0.56, h * 0.56);
    final forefootCenter = isLeft ? Offset(w * 0.40, h * 0.30) : Offset(w * 0.60, h * 0.30);
    final toeCenter      = Offset(w * 0.50, h * 0.11);

    _drawHotspot(canvas, heelCenter,     math.max(zones[0], 0.4), accentColor);
    _drawHotspot(canvas, midfootCenter,  math.max(zones[1], 0.25), accentColor.withOpacity(0.9));
    _drawHotspot(canvas, forefootCenter, math.max(zones[2], 0.3), accentColor);
    _drawHotspot(canvas, toeCenter,      math.max(zones[3], 0.2), accentColor.withOpacity(0.8));
  }

  Path _buildFootPath(double w, double h) {
    final path = Path();
    if (isLeft) {
      path.moveTo(w * 0.52, h * 0.04);
      path.cubicTo(w * 0.72, h * 0.04, w * 0.82, h * 0.10, w * 0.80, h * 0.26);
      path.cubicTo(w * 0.78, h * 0.40, w * 0.65, h * 0.45, w * 0.68, h * 0.58);
      path.cubicTo(w * 0.72, h * 0.72, w * 0.76, h * 0.86, w * 0.60, h * 0.95);
      path.cubicTo(w * 0.46, h * 1.00, w * 0.30, h * 0.96, w * 0.26, h * 0.86);
      path.cubicTo(w * 0.22, h * 0.76, w * 0.34, h * 0.62, w * 0.30, h * 0.50);
      path.cubicTo(w * 0.26, h * 0.38, w * 0.14, h * 0.28, w * 0.18, h * 0.16);
      path.cubicTo(w * 0.22, h * 0.06, w * 0.36, h * 0.04, w * 0.52, h * 0.04);
    } else {
      path.moveTo(w * 0.48, h * 0.04);
      path.cubicTo(w * 0.28, h * 0.04, w * 0.18, h * 0.10, w * 0.20, h * 0.26);
      path.cubicTo(w * 0.22, h * 0.40, w * 0.35, h * 0.45, w * 0.32, h * 0.58);
      path.cubicTo(w * 0.28, h * 0.72, w * 0.24, h * 0.86, w * 0.40, h * 0.95);
      path.cubicTo(w * 0.54, h * 1.00, w * 0.70, h * 0.96, w * 0.74, h * 0.86);
      path.cubicTo(w * 0.78, h * 0.76, w * 0.66, h * 0.62, w * 0.70, h * 0.50);
      path.cubicTo(w * 0.74, h * 0.38, w * 0.86, h * 0.28, w * 0.82, h * 0.16);
      path.cubicTo(w * 0.78, h * 0.06, w * 0.64, h * 0.04, w * 0.48, h * 0.04);
    }
    path.close();
    return path;
  }

  void _drawPulseRing(Canvas canvas, Offset center, double radius, Color color) {
    for (int i = 1; i <= 2; i++) {
      final r = radius * (0.5 + i * 0.3);
      final paint = Paint()
        ..color = color.withOpacity(0.08 / i)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(center, r, paint);
    }
  }

  void _drawHotspot(Canvas canvas, Offset center, double intensity, Color color) {
    if (intensity <= 0.01) return;
    final radius = 6.0 + intensity * 12.0;

    // Outer soft glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(0.75 * intensity),
          color.withOpacity(0.25 * intensity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.8));
    canvas.drawCircle(center, radius * 1.8, glowPaint);

    // Inner bright core
    final corePaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2.5, corePaint);
  }

  @override
  bool shouldRepaint(covariant _FootSilhouettePainter old) =>
      old.pressure != pressure || old.accentColor != accentColor;
}

// 3. Animated Live ECG wave with glow
class _LiveWavePainter extends CustomPainter {
  final double animValue;
  final Color lineColor;
  final Color glowColor;
  final bool isSine;
  final bool isFlat;
  final double strokeWidth;

  _LiveWavePainter({
    required this.animValue,
    required this.lineColor,
    this.glowColor = Colors.transparent,
    this.isSine = false,
    this.isFlat = false,
    this.strokeWidth = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path();
    path.moveTo(0, h / 2);

    if (isFlat) {
      path.lineTo(w, h / 2);
      final flatPaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawPath(path, flatPaint);
      return;
    }

    if (isSine) {
      for (double x = 0; x <= w; x++) {
        final double phase = (x / w) * 4 * math.pi + (animValue * 2 * math.pi);
        final double y = (h / 2) + math.sin(phase) * (h / 2.5);
        path.lineTo(x, y);
      }
    } else {
      for (double x = 0; x <= w; x++) {
        double y = h / 2;
        final double relativeX = (x / w) - animValue;
        final double cyclePos = (relativeX * 3) % 1.0;
        if (cyclePos > 0.4 && cyclePos < 0.45) {
          y = (h / 2) - ((cyclePos - 0.4) * 20 * h);
        } else if (cyclePos >= 0.45 && cyclePos < 0.5) {
          y = (h / 2) + ((0.5 - cyclePos) * 15 * h);
        } else if (cyclePos >= 0.6 && cyclePos < 0.7) {
          y = (h / 2) - (math.sin((cyclePos - 0.6) * 10 * math.pi) * (h / 4));
        }
        path.lineTo(x, y);
      }
    }

    // Glow pass (blurred wider stroke under the crisp line)
    if (glowColor != Colors.transparent) {
      final glowPaint = Paint()
        ..color = glowColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawPath(path, glowPaint);
    }

    // Crisp line on top
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
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
