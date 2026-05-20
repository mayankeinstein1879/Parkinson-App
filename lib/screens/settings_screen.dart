import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parkinson_insole_app/constants/app_colors.dart';
import 'package:parkinson_insole_app/constants/app_strings.dart';
import 'package:parkinson_insole_app/providers/settings_provider.dart';
import 'package:parkinson_insole_app/widgets/cue_toggle_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(AppStrings.titleSettings)),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [

              // ── Cue Settings ──────────────────────────────────────────
              _SectionTitle('Adaptive Cue Settings'),
              const SizedBox(height: 8),
              CueToggleCard(
                title: AppStrings.visualCue,
                subtitle: AppStrings.visualCueSub,
                icon: Icons.light_mode_outlined,
                enabled: settings.cueSettings.visualCueEnabled,
                intensity: settings.cueSettings.visualIntensity,
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

              const SizedBox(height: 24),

              // ── App Settings ─────────────────────────────────────────
              _SectionTitle('App Settings'),
              const SizedBox(height: 8),
              _SettingsTile(
                title: AppStrings.settingsAutoReconnect,
                subtitle: 'Reconnect automatically if signal drops',
                value: settings.autoReconnect,
                onChanged: (_) => settings.toggleAutoReconnect(),
              ),
              _SettingsTile(
                title: AppStrings.settingsNotifications,
                subtitle: 'FOG risk alerts and fall notifications',
                value: settings.notificationsEnabled,
                onChanged: (_) => settings.toggleNotifications(),
              ),
              _SettingsTile(
                title: AppStrings.settingsMockData,
                subtitle: 'Use simulated data (no hardware needed)',
                value: settings.useMockData,
                onChanged: (_) => settings.toggleMockData(),
                accentColor: AppColors.warningOrange,
              ),
              _SettingsTile(
                title: AppStrings.settingsDeveloperMode,
                subtitle: 'Show debug console and raw BLE data',
                value: settings.isDeveloperMode,
                onChanged: (_) => settings.toggleDeveloperMode(),
                accentColor: AppColors.secondaryPurple,
              ),

              const SizedBox(height: 16),

              // ── Target Device Name ────────────────────────────────────
              _SectionTitle('BLE Device Name Prefix'),
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingController(text: settings.targetDeviceName),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'e.g. Parkinson_',
                  helperText: 'Devices whose name starts with this will be shown in scan',
                  helperStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check, color: AppColors.primaryCyan),
                    onPressed: () {},
                  ),
                ),
                onSubmitted: settings.setTargetDeviceName,
              ),

              const SizedBox(height: 24),

              // ── About ─────────────────────────────────────────────────
              _SectionTitle('About'),
              const SizedBox(height: 8),
              _AboutTile('App Version', AppStrings.appVersion),
              _AboutTile('Package', AppStrings.appPackage),
              _AboutTile('BLE Target', 'ESP32 (STM32WB55 ready)'),
              _AboutTile('Architecture', 'Clean + Provider'),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.code, size: 16),
                label: const Text('View on GitHub'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.titleSmall?.copyWith(
      color: AppColors.primaryCyan, letterSpacing: 0.5),
  );
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? accentColor;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primaryCyan;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyMedium),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            activeTrackColor: color.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}

class _AboutTile extends StatelessWidget {
  final String label;
  final String value;
  const _AboutTile(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary)),
        const Spacer(),
        Text(value, style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.textPrimary)),
      ],
    ),
  );
}
