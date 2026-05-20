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
      const routes = ['', '/scan', '/status', '/settings'];
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

  // â”€â”€ DESKTOP GRID LAYOUT â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

  // â”€â”€ MOBILE LAYOUT â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

  // â”€â”€ DESKTOP SUBCOMPONENTS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

  // Top Header Area â€” premium cinematic design matching reference
  Widget _buildHeader(BuildContext context) {
    return Consumer2<BleProvider, TelemetryProvider>(
      builder: (context, ble, tele, _) {
        final avgBatteryL = tele.leftData.batteryLevel;
        final avgBatteryR = tele.rightData.batteryLevel;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF060E1E),
                Color(0xFF0B1A30),
                Color(0xFF0D1F38),
                Color(0xFF0B1A30),
                Color(0xFF060E1E),
              ],
              stops: [0.0, 0.2, 0.5, 0.8, 1.0],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF00E5FF).withOpacity(0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withOpacity(0.04),
                blurRadius: 30,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ambient center glow behind AI graphic
              Positioned(
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 280,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF0080FF).withOpacity(0.12),
                          Colors.transparent,
                        ],
                        radius: 1.0,
                      ),
                    ),
                  ),
                ),
              ),

              // Main layout row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // â”€â”€ LEFT: Title + Subtitle â”€â”€
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.white, Color(0xFFB8D4F0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: Text(
                            'FOG Detection System',
                            style: GoogleFonts.orbitron(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'AI-Assisted Gait Monitoring & Adaptive Cueing',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF6B8FAF),
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // â”€â”€ CENTER: AI Holographic Visualization â”€â”€

                  // â”€â”€ RIGHT: Notification + Profile â”€â”€
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Notification bell
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D1B2E),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF00E5FF).withOpacity(0.2),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withOpacity(0.08),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: Color(0xFFE8F4FF),
                              size: 18,
                            ),
                          ),
                          Positioned(
                            top: -1,
                            right: -1,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppColors.alertRed,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.alertRed.withOpacity(0.6),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),

                      // Premium profile card
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0E1F35), Color(0xFF121E30)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF00E5FF).withOpacity(0.18),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withOpacity(0.06),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Avatar
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1A3A5C), Color(0xFF0D2240)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                  color: const Color(0xFF00E5FF).withOpacity(0.35),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00E5FF).withOpacity(0.15),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Color(0xFF00E5FF),
                                size: 17,
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Name + stats
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Robert Jensen',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFFE8F4FF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      color: Color(0xFF5A7A9A),
                                      size: 9,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      _formatDuration(_sessionDuration),
                                      style: GoogleFonts.orbitron(
                                        color: const Color(0xFF5A7A9A),
                                        fontSize: 9,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.sync_rounded,
                                      color: Color(0xFF00FF88),
                                      size: 9,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Synchronized',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF00FF88),
                                        fontSize: 9,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'L: $avgBatteryL%  R: $avgBatteryR%',
                                      style: const TextStyle(
                                        color: Color(0xFF5A7A9A),
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF5A7A9A),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // â”€â”€ LEFT SIDE GRIDS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

  // Desktop Individual Insole Card â€” premium pixel-faithful to reference image
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
          // â”€â”€ Header: Name | BLE badge + battery ring â”€â”€
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

          // â”€â”€ Body: Foot + Metrics â”€â”€
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

          // â”€â”€ ECG heartbeat wave â”€â”€
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

  // â”€â”€ RIGHT SIDE GRIDS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

// 1. Premium Glowing Walking Human Silhouette (Header Center) — matches reference image 2
class _HeaderWalkingPreview extends StatelessWidget {
  final double animValue;

  const _HeaderWalkingPreview({required this.animValue});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0x99050A1A),
            Color(0xCC09162A),
            Color(0x99050A1A),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryCyan.withOpacity(0.14),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.glowCyan.withOpacity(0.14),
            blurRadius: 16,
            spreadRadius: -2,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _HeaderWalkingFigurePainter(animValue: animValue),
      ),
    );
  }
}

class _HeaderWalkingFigurePainter extends CustomPainter {
  final double animValue;

  _HeaderWalkingFigurePainter({required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    const cyan = Color(0xFF7DEBFF);
    const cyanCore = Color(0xFF35DFFF);
    const cyanDim = Color(0xFF4EB7D8);

    Paint glowStroke(Color color, double width, double blurSigma) => Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma)
      ..style = PaintingStyle.stroke;

    Paint crispStroke(Color color, double width) => Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    Paint glowFill(Color color, double blurSigma) => Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma)
      ..style = PaintingStyle.fill;

    final pulse = 0.55 + (math.sin(animValue * 2 * math.pi) * 0.18);
    final floorGlowCenter = Offset(size.width * 0.66, size.height * 0.78);

    final backgroundGlow = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          AppColors.primaryCyan.withOpacity(0.06),
          Colors.transparent,
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, backgroundGlow);

    canvas.drawOval(
      Rect.fromCenter(
        center: floorGlowCenter,
        width: size.width * 0.22,
        height: size.height * 0.10,
      ),
      glowFill(AppColors.primaryCyan.withOpacity(0.20 * pulse), 10),
    );

    canvas.drawLine(
      Offset(size.width * 0.18, size.height * 0.82),
      Offset(size.width * 0.84, size.height * 0.82),
      glowStroke(AppColors.primaryCyan.withOpacity(0.12), 2, 4),
    );

    final figureHeight = size.height * 0.70;
    final figureWidth = figureHeight * 0.42;
    final origin = Offset(size.width * 0.42, size.height * 0.12);

    double x(double fraction) => origin.dx + figureWidth * fraction;
    double y(double fraction) => origin.dy + figureHeight * fraction;

    final headCenter = Offset(x(0.46), y(0.10));
    final headRadius = figureHeight * 0.09;
    final neck = Offset(x(0.43), y(0.22));
    final shoulderBack = Offset(x(0.30), y(0.27));
    final shoulderFront = Offset(x(0.53), y(0.29));
    final chest = Offset(x(0.51), y(0.40));
    final spineMid = Offset(x(0.40), y(0.43));
    final hipFront = Offset(x(0.48), y(0.60));
    final hipBack = Offset(x(0.36), y(0.60));

    final frontElbow = Offset(x(0.62), y(0.46));
    final frontHand = Offset(x(0.56), y(0.66));
    final backElbow = Offset(x(0.23), y(0.44));
    final backHand = Offset(x(0.18), y(0.62));

    final frontKnee = Offset(x(0.61), y(0.76));
    final frontAnkle = Offset(x(0.68), y(0.95));
    final frontToe = Offset(x(0.80), y(0.96));
    final backKnee = Offset(x(0.29), y(0.78));
    final backAnkle = Offset(x(0.24), y(0.97));
    final backToe = Offset(x(0.14), y(0.98));

    final torsoPath = Path()
      ..moveTo(neck.dx, neck.dy)
      ..quadraticBezierTo(x(0.56), y(0.31), chest.dx, chest.dy)
      ..quadraticBezierTo(x(0.49), y(0.53), hipFront.dx, hipFront.dy)
      ..lineTo(hipBack.dx, hipBack.dy)
      ..quadraticBezierTo(x(0.28), y(0.46), spineMid.dx, spineMid.dy)
      ..quadraticBezierTo(x(0.24), y(0.31), shoulderBack.dx, shoulderBack.dy)
      ..close();

    canvas.drawPath(
      torsoPath,
      glowFill(AppColors.primaryCyan.withOpacity(0.12), 8),
    );
    canvas.drawPath(torsoPath, glowStroke(cyanCore.withOpacity(0.45), 3, 5));
    canvas.drawPath(torsoPath, crispStroke(cyanDim, 1.4));

    void drawLimb(List<Offset> points, {double glowWidth = 4.0, double crispWidth = 1.6}) {
      for (int i = 0; i < points.length - 1; i++) {
        canvas.drawLine(
          points[i],
          points[i + 1],
          glowStroke(cyanCore.withOpacity(0.42), glowWidth, 4),
        );
        canvas.drawLine(
          points[i],
          points[i + 1],
          crispStroke(cyan, crispWidth),
        );
      }
    }

    drawLimb([neck, shoulderFront, frontElbow, frontHand], glowWidth: 4.2);
    drawLimb([shoulderBack, backElbow, backHand], glowWidth: 3.8, crispWidth: 1.4);
    drawLimb([hipFront, frontKnee, frontAnkle, frontToe], glowWidth: 4.6, crispWidth: 1.8);
    drawLimb([hipBack, backKnee, backAnkle, backToe], glowWidth: 4.0, crispWidth: 1.5);
    drawLimb([shoulderBack, shoulderFront], glowWidth: 3.6, crispWidth: 1.3);
    drawLimb([neck, spineMid, hipBack], glowWidth: 3.4, crispWidth: 1.2);

    for (final joint in [
      shoulderFront,
      frontElbow,
      hipFront,
      frontKnee,
      frontAnkle,
    ]) {
      canvas.drawCircle(joint, figureHeight * 0.015, glowFill(cyanCore.withOpacity(0.40), 4));
      canvas.drawCircle(joint, figureHeight * 0.009, Paint()..color = cyan);
    }

    canvas.drawCircle(
      headCenter,
      headRadius * 1.35,
      glowFill(AppColors.primaryCyan.withOpacity(0.16), 8),
    );
    canvas.drawCircle(
      headCenter,
      headRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(0.28),
            cyanCore.withOpacity(0.20),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: headCenter, radius: headRadius))
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(headCenter, headRadius, glowStroke(cyanCore.withOpacity(0.50), 3, 4));
    canvas.drawCircle(headCenter, headRadius, crispStroke(cyan, 1.3));

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(frontToe.dx, frontToe.dy + 1),
        width: figureWidth * 0.34,
        height: figureHeight * 0.06,
      ),
      glowFill(AppColors.primaryCyan.withOpacity(0.28 * pulse), 8),
    );
  }

  @override
  bool shouldRepaint(covariant _HeaderWalkingFigurePainter old) =>
      old.animValue != animValue;
}

class _AiHolographicPainter extends CustomPainter {
  final double animValue;
  _AiHolographicPainter({required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // The figure is centered horizontally, anchored so feet sit near bottom
    final cx = w / 2;
    // Scale factor — figure height = ~90% of canvas height
    final scale = h * 0.92;

    // — Anatomy proportions (top = 0, bottom = 1 in figure space) —
    // All positions as fractions of `scale`, centered on cx
    final headR   = scale * 0.075;
    final headCY  = headR + 2;                           // top of figure
    final neckT   = headCY + headR;
    final neckB   = neckT + scale * 0.04;
    final shouldY = neckB;
    final shouldW = scale * 0.22;
    final torsoB  = shouldY + scale * 0.26;
    final pelvisW = scale * 0.16;

    final handR     = scale * 0.025;

    // — Paint helpers —
    Paint glowFill(Color c, double blurSigma) => Paint()
      ..color = c
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma)
      ..style = PaintingStyle.fill;

    Paint glowStroke(Color c, double sw, double blurSigma) => Paint()
      ..color = c
      ..strokeWidth = sw
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma)
      ..style = PaintingStyle.stroke;

    Paint crispStroke(Color c, double sw) => Paint()
      ..color = c
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    const cyan       = Color(0xFF00D8F0);
    const cyanDim    = Color(0xFF0090B8);
    const cyanBright = Color(0xFF40EEFF);

    // — 1. Ground radial glow —
    final groundY = h - 2.0;
    final groundPulse = 0.25 + math.sin(animValue * 2 * math.pi) * 0.06;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, groundY), width: scale * 0.5, height: scale * 0.06),
      glowFill(Color.fromRGBO(0, 128, 192, groundPulse), 12),
    );

    // actual top offset so figure is vertically centered in canvas
    final topOff = (h - scale) / 2;

    // shorthand
    double y(double frac) => topOff + frac * scale;

    // — 2. Full-body ambient glow (wide blurred fill path) —
    void drawBodySegment(Path path, {double glowSigma = 8, double fillAlpha = 0.18}) {
      canvas.drawPath(path, glowFill(cyan.withValues(alpha: fillAlpha), glowSigma));
      canvas.drawPath(path, glowStroke(cyanBright, 4, 4));
      canvas.drawPath(path, crispStroke(cyan, 1.2));
    }

    // — 3. Walking pose keypoints —
    // Head
    final headCenter = Offset(cx + scale * 0.02, y(0.04) + headR);

    // Neck
    final neckTop    = Offset(cx, headCenter.dy + headR * 0.85);
    final neckBot    = Offset(cx - scale * 0.01, neckTop.dy + scale * 0.045);

    // Shoulders
    final shoulderL  = Offset(cx - shouldW * 0.5, neckBot.dy + scale * 0.01);
    final shoulderR  = Offset(cx + shouldW * 0.5, neckBot.dy + scale * 0.01);

    final torsoBot = Offset(cx, shoulderL.dy + scale * 0.26);

    // Pelvis
    final hipL       = Offset(cx - pelvisW * 0.5, torsoBot.dy + scale * 0.06);
    final hipR       = Offset(cx + pelvisW * 0.5, torsoBot.dy + scale * 0.06);

    // — RIGHT ARM (forward — raised, elbow bent up) —
    final rElbow     = Offset(shoulderR.dx + scale * 0.10, shoulderR.dy + scale * 0.11);
    final rWrist     = Offset(rElbow.dx + scale * 0.04, rElbow.dy - scale * 0.10);
    final rHand      = Offset(rWrist.dx + scale * 0.01, rWrist.dy - scale * 0.03);

    // — LEFT ARM (back — hanging down, elbow slightly bent) —
    final lElbow     = Offset(shoulderL.dx - scale * 0.09, shoulderL.dy + scale * 0.14);
    final lWrist     = Offset(lElbow.dx - scale * 0.03, lElbow.dy + scale * 0.12);
    final lHand      = Offset(lWrist.dx, lWrist.dy + scale * 0.03);

    // — LEFT LEG (forward stride — knee lifted) —
    final lKnee      = Offset(hipL.dx - scale * 0.06, hipL.dy + scale * 0.18);
    final lAnkle     = Offset(lKnee.dx + scale * 0.04, lKnee.dy + scale * 0.20);
    final lToe       = Offset(lAnkle.dx + scale * 0.07, lAnkle.dy + scale * 0.015);

    // â”€â”€ RIGHT LEG (back stride â€” extended behind) â”€â”€
    final rKnee      = Offset(hipR.dx + scale * 0.03, hipR.dy + scale * 0.19);
    final rAnkle     = Offset(rKnee.dx + scale * 0.01, rKnee.dy + scale * 0.19);
    final rToe       = Offset(rAnkle.dx - scale * 0.05, rAnkle.dy + scale * 0.01);

    // â”€â”€ Draw body fill paths â”€â”€

    // Torso outline (trapezoid)
    final torsoPath = Path()
      ..moveTo(shoulderL.dx, shoulderL.dy)
      ..lineTo(shoulderR.dx, shoulderR.dy)
      ..cubicTo(shoulderR.dx + scale*0.04, torsoBot.dy - scale*0.06,
                torsoBot.dx + pelvisW*0.4, torsoBot.dy,
                torsoBot.dx + pelvisW*0.35, torsoBot.dy)
      ..lineTo(torsoBot.dx - pelvisW*0.35, torsoBot.dy)
      ..cubicTo(torsoBot.dx - pelvisW*0.4, torsoBot.dy,
                shoulderL.dx - scale*0.04, torsoBot.dy - scale*0.06,
                shoulderL.dx, shoulderL.dy)
      ..close();
    drawBodySegment(torsoPath, glowSigma: 6, fillAlpha: 0.14);

    // Pelvis/hips
    final pelvisPath = Path()
      ..moveTo(torsoBot.dx - pelvisW*0.35, torsoBot.dy)
      ..lineTo(torsoBot.dx + pelvisW*0.35, torsoBot.dy)
      ..lineTo(hipR.dx, hipR.dy)
      ..lineTo(hipL.dx, hipL.dy)
      ..close();
    drawBodySegment(pelvisPath, glowSigma: 5, fillAlpha: 0.12);

    // â”€â”€ Neck â”€â”€
    canvas.drawLine(neckTop, neckBot, glowStroke(cyan, 5, 4));
    canvas.drawLine(neckTop, neckBot, crispStroke(cyan, 2.0));

    // â”€â”€ Shoulders across â”€â”€
    canvas.drawLine(shoulderL, shoulderR, glowStroke(cyan, 4, 3));
    canvas.drawLine(shoulderL, shoulderR, crispStroke(cyan, 1.5));

    // â”€â”€ Spine line â”€â”€
    canvas.drawLine(neckBot, torsoBot, glowStroke(cyanDim.withOpacity(0.4), 3, 4));
    canvas.drawLine(neckBot, torsoBot, crispStroke(cyanDim.withOpacity(0.6), 0.8));

    // â”€â”€ RIGHT ARM â”€â”€
    canvas.drawLine(shoulderR, rElbow, glowStroke(cyan, 5, 4));
    canvas.drawLine(shoulderR, rElbow, crispStroke(cyan, 1.8));
    canvas.drawLine(rElbow, rWrist, glowStroke(cyan, 4, 3));
    canvas.drawLine(rElbow, rWrist, crispStroke(cyan, 1.5));
    canvas.drawCircle(rHand, handR * scale, glowFill(cyan.withOpacity(0.4), 4));
    canvas.drawCircle(rHand, handR * scale, crispStroke(cyan, 1.2));

    // â”€â”€ LEFT ARM â”€â”€
    canvas.drawLine(shoulderL, lElbow, glowStroke(cyan, 5, 4));
    canvas.drawLine(shoulderL, lElbow, crispStroke(cyan, 1.8));
    canvas.drawLine(lElbow, lWrist, glowStroke(cyan, 4, 3));
    canvas.drawLine(lElbow, lWrist, crispStroke(cyan, 1.5));
    canvas.drawCircle(lHand, handR * scale, glowFill(cyan.withOpacity(0.4), 4));
    canvas.drawCircle(lHand, handR * scale, crispStroke(cyan, 1.2));

    // â”€â”€ LEFT LEG â”€â”€
    canvas.drawLine(hipL, lKnee, glowStroke(cyan, 6, 5));
    canvas.drawLine(hipL, lKnee, crispStroke(cyan, 2.0));
    canvas.drawLine(lKnee, lAnkle, glowStroke(cyan, 5, 4));
    canvas.drawLine(lKnee, lAnkle, crispStroke(cyan, 1.8));
    canvas.drawLine(lAnkle, lToe, glowStroke(cyan, 4, 3));
    canvas.drawLine(lAnkle, lToe, crispStroke(cyan, 1.5));

    // â”€â”€ RIGHT LEG â”€â”€
    canvas.drawLine(hipR, rKnee, glowStroke(cyan, 6, 5));
    canvas.drawLine(hipR, rKnee, crispStroke(cyan, 2.0));
    canvas.drawLine(rKnee, rAnkle, glowStroke(cyan, 5, 4));
    canvas.drawLine(rKnee, rAnkle, crispStroke(cyan, 1.8));
    canvas.drawLine(rAnkle, rToe, glowStroke(cyan, 4, 3));
    canvas.drawLine(rAnkle, rToe, crispStroke(cyan, 1.5));

    // â”€â”€ Joint dots â”€â”€
    for (final joint in [
      shoulderL, shoulderR, rElbow, lElbow, hipL, hipR,
      lKnee, rKnee, lAnkle, rAnkle,
    ]) {
      canvas.drawCircle(joint, scale * 0.018,
        glowFill(cyanBright.withOpacity(0.35), 5));
      canvas.drawCircle(joint, scale * 0.012,
        Paint()..color = cyanBright..style = PaintingStyle.fill);
    }

    // â”€â”€ HEAD (drawn last so it's on top) â”€â”€
    // Outer glow
    canvas.drawCircle(headCenter, headR * 1.6,
      glowFill(cyan.withOpacity(0.15), 10));
    // Fill
    canvas.drawCircle(headCenter, headR,
      Paint()
        ..shader = RadialGradient(
          colors: [cyanBright.withOpacity(0.3), cyan.withOpacity(0.1)],
        ).createShader(Rect.fromCircle(center: headCenter, radius: headR))
        ..style = PaintingStyle.fill);
    // Glow stroke
    canvas.drawCircle(headCenter, headR, glowStroke(cyanBright, 4, 5));
    // Crisp stroke
    canvas.drawCircle(headCenter, headR, crispStroke(cyan, 1.5));

    // â”€â”€ Animated pulse aura around whole figure â”€â”€
    final pulseOpacity = 0.07 + math.sin(animValue * 2 * math.pi) * 0.04;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, (headCenter.dy + rToe.dy) / 2),
        width: scale * 0.55,
        height: (rToe.dy - headCenter.dy) * 1.1,
      ),
      Paint()
        ..color = cyan.withOpacity(pulseOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );
  }

  @override
  bool shouldRepaint(covariant _AiHolographicPainter old) => old.animValue != animValue;
}


// â”€â”€ PREMIUM REUSABLE WIDGETS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// A circular progress ring with optional glow shadow and a centered child widget.
class _GlowRing extends StatelessWidget {
  final double size;
  final double value;      // 0.0 â€“ 1.0
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
/// bold white label â†’ large purple Orbitron value â†’ grey sublabel | neon ring w/ number
class _PremiumMetricRow extends StatelessWidget {
  final String label;
  final String subLabel;
  final double value;
  final String displaySuffix;
  final Color ringColor;
  final double ringValue;   // 0.0 â€“ 1.0
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

// â”€â”€ CUSTOM PAINTERS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

// 2. Premium foot outline â€” gradient fill + glow border + bright pressure hotspots
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

    // â”€â”€ 1. Outer ambient glow (large soft shadow around foot shape) â”€â”€
    final glowPaint = Paint()
      ..color = accentColor.withOpacity(0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, glowPaint);

    // â”€â”€ 2. Gradient fill inside foot â”€â”€
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

    // â”€â”€ 3. Glowing outline â”€â”€
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

    // â”€â”€ 4. Pulse ring at midfoot â”€â”€
    final midCenter = Offset(w * 0.5, h * 0.62);
    _drawPulseRing(canvas, midCenter, w * 0.38, accentColor);

    // â”€â”€ 5. Pressure hotspots â”€â”€
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

// â”€â”€ Shared Bottom Navigation widget â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
      ],
    );
  }
}
