import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:parkinson_insole_app/constants/app_colors.dart';
import 'package:parkinson_insole_app/constants/app_strings.dart';
import 'package:parkinson_insole_app/models/insole_device.dart';
import 'package:parkinson_insole_app/providers/ble_provider.dart';
import 'package:parkinson_insole_app/providers/telemetry_provider.dart';
import 'package:parkinson_insole_app/providers/settings_provider.dart';
import 'package:parkinson_insole_app/widgets/insole_card.dart';
import 'package:parkinson_insole_app/widgets/fog_risk_indicator.dart';
import 'package:parkinson_insole_app/widgets/cue_toggle_card.dart';
import 'package:parkinson_insole_app/widgets/analytics_placeholder.dart';
import 'package:parkinson_insole_app/widgets/ble_status_badge.dart';
import 'package:parkinson_insole_app/widgets/battery_indicator.dart';

/// Main Dashboard — the primary screen users see when connected.
/// Displays live insole telemetry, FOG risk, cue controls, and analytics.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTab = 0;

  final List<Widget> _screens = const [
    _DashboardBody(),
    SizedBox(), // Scan — navigated via pushNamed
    SizedBox(), // Status — navigated via pushNamed
    SizedBox(), // Settings — navigated via pushNamed
    SizedBox(), // Debug — navigated via pushNamed
  ];

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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _DashboardAppBar(),
      body: _DashboardBody(),
      floatingActionButton: _SosFab(),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedTab,
        onTap: _onTabTapped,
      ),
    );
  }
}

// ── App Bar ───────────────────────────────────────────────────────────────────

class _DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.appName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          Text(
            AppStrings.appTagline,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary, fontSize: 9),
          ),
        ],
      ),
      actions: [
        // BLE connection status
        Consumer<BleProvider>(
          builder: (_, ble, __) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: BleStatusBadge(status: ble.connectionStatus),
          ),
        ),
        // Battery indicator
        Consumer<TelemetryProvider>(
          builder: (_, tele, __) => Padding(
            padding: const EdgeInsets.only(right: 14),
            child: BatteryIndicator(
              level: tele.avgBattery.round(),
              isCharging: false,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Dashboard Body ────────────────────────────────────────────────────────────

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    return Consumer3<BleProvider, TelemetryProvider, SettingsProvider>(
      builder: (context, ble, tele, settings, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Section: Insole Cards ───────────────────────────────────
              _SectionHeader(title: 'Real-Time Monitoring',
                  badge: ble.isConnected ? 'LIVE' : 'OFFLINE'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: InsoleCard(
                      device: ble.connectedDeviceLeft ??
                          InsoleDevice(
                            id: 'mock_l', name: 'Parkinson_L_Insole',
                            side: InsoleSide.left,
                            status: ble.connectionStatus,
                          ),
                      telemetry: tele.leftData,
                      onTap: () => Navigator.pushNamed(context, '/status'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InsoleCard(
                      device: ble.connectedDeviceRight ??
                          InsoleDevice(
                            id: 'mock_r', name: 'Parkinson_R_Insole',
                            side: InsoleSide.right,
                            status: ble.connectionStatus,
                          ),
                      telemetry: tele.rightData,
                      onTap: () => Navigator.pushNamed(context, '/status'),
                    ),
                  ),
                ],
              ).animate().fade(duration: 400.ms).slideY(begin: 0.1),

              const SizedBox(height: 20),

              // ── Section: FOG Risk ───────────────────────────────────────
              _SectionHeader(title: 'FOG Risk Assessment'),
              const SizedBox(height: 12),
              Center(
                child: FogRiskIndicator(
                  riskPercent: tele.fogRiskLevel,
                  size: 180,
                ),
              ).animate().fade(duration: 400.ms, delay: 100.ms),

              const SizedBox(height: 20),

              // ── Section: Adaptive Cue Settings ──────────────────────────
              _SectionHeader(title: 'Adaptive Cue Controls'),
              const SizedBox(height: 10),
              Column(
                children: [
                  CueToggleCard(
                    title: AppStrings.visualCue,
                    subtitle: AppStrings.visualCueSub,
                    icon: Icons.light_mode_outlined,
                    enabled: settings.cueSettings.visualCueEnabled,
                    intensity: settings.cueSettings.visualIntensity,
                    accentColor: AppColors.primaryCyan,
                    onToggle: (v) => settings.updateCueSettings(
                      settings.cueSettings.copyWith(visualCueEnabled: v)),
                    onIntensityChanged: (v) => settings.updateCueSettings(
                      settings.cueSettings.copyWith(visualIntensity: v)),
                  ),
                  const SizedBox(height: 8),
                  CueToggleCard(
                    title: AppStrings.hapticCue,
                    subtitle: AppStrings.hapticCueSub,
                    icon: Icons.vibration,
                    enabled: settings.cueSettings.hapticCueEnabled,
                    intensity: settings.cueSettings.hapticIntensity,
                    accentColor: AppColors.secondaryPurple,
                    onToggle: (v) => settings.updateCueSettings(
                      settings.cueSettings.copyWith(hapticCueEnabled: v)),
                    onIntensityChanged: (v) => settings.updateCueSettings(
                      settings.cueSettings.copyWith(hapticIntensity: v)),
                  ),
                  const SizedBox(height: 8),
                  CueToggleCard(
                    title: AppStrings.audioCue,
                    subtitle: AppStrings.audioCueSub,
                    icon: Icons.volume_up_outlined,
                    enabled: settings.cueSettings.audioCueEnabled,
                    intensity: settings.cueSettings.audioVolume,
                    accentColor: AppColors.accentGreen,
                    onToggle: (v) => settings.updateCueSettings(
                      settings.cueSettings.copyWith(audioCueEnabled: v)),
                    onIntensityChanged: (v) => settings.updateCueSettings(
                      settings.cueSettings.copyWith(audioVolume: v)),
                  ),
                ],
              ).animate().fade(duration: 400.ms, delay: 150.ms),

              const SizedBox(height: 20),

              // ── Section: AI Analytics ───────────────────────────────────
              _SectionHeader(title: AppStrings.analyticsTitle),
              const SizedBox(height: 10),
              AnalyticsPlaceholder(
                title: AppStrings.analyticsGaitGraph,
                accentColor: AppColors.primaryCyan,
              ),
              const SizedBox(height: 10),
              AnalyticsPlaceholder(
                title: AppStrings.analyticsFogTimeline,
                accentColor: AppColors.secondaryPurple,
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: AnalyticsPlaceholder(
                      title: AppStrings.analyticsPressure,
                      accentColor: AppColors.warningOrange,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AnalyticsPlaceholder(
                      title: AppStrings.analyticsConfidence,
                      accentColor: AppColors.accentGreen,
                    ),
                  ),
                ],
              ).animate().fade(duration: 400.ms, delay: 200.ms),

              const SizedBox(height: 80), // Padding for FAB
            ],
          ),
        );
      },
    );
  }
}

// ── SOS FAB ───────────────────────────────────────────────────────────────────

class _SosFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showSosDialog(context),
      backgroundColor: AppColors.alertRed,
      icon: const Icon(Icons.sos, color: Colors.white),
      label: const Text(
        'SOS',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontFamily: 'Orbitron',
          letterSpacing: 2,
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
        .boxShadow(
          duration: 1000.ms,
          begin: const BoxShadow(
            color: Color(0x44FF1744), blurRadius: 8, spreadRadius: 1),
          end: const BoxShadow(
            color: Color(0x88FF1744), blurRadius: 20, spreadRadius: 4),
        );
  }

  void _showSosDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Emergency SOS'),
        content: const Text(
          'This will alert your emergency contact and log a fall event. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.alertRed),
            onPressed: () => Navigator.pop(context),
            child: const Text('Send Alert',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Bottom Navigation ─────────────────────────────────────────────────────────

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

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? badge;

  const _SectionHeader({required this.title, this.badge});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.accentGreen.withOpacity(0.4)),
            ),
            child: Text(
              badge!,
              style: const TextStyle(
                color: AppColors.accentGreen,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
