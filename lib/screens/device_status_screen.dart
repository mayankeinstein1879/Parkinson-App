import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parkinson_insole_app/constants/app_colors.dart';
import 'package:parkinson_insole_app/constants/app_strings.dart';
import 'package:parkinson_insole_app/models/insole_device.dart';
import 'package:parkinson_insole_app/providers/ble_provider.dart';
import 'package:parkinson_insole_app/providers/telemetry_provider.dart';
import 'package:parkinson_insole_app/widgets/battery_indicator.dart';
import 'package:parkinson_insole_app/widgets/ble_status_badge.dart';
import 'package:parkinson_insole_app/widgets/glow_button.dart';

/// Device status screen — detailed BLE device information.
class DeviceStatusScreen extends StatelessWidget {
  const DeviceStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(AppStrings.titleStatus)),
      body: Consumer2<BleProvider, TelemetryProvider>(
        builder: (context, ble, tele, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Connection Status Card ───────────────────────────────
                _StatusCard(
                  title: 'BLE Connection',
                  children: [
                    _StatusRow('Status', ble.connectionStatus.name.toUpperCase(),
                        color: ble.isConnected ? AppColors.accentGreen : AppColors.alertRed),
                    _StatusRow('Auto-Reconnect',
                        ble.autoReconnectEnabled ? 'Enabled' : 'Disabled'),
                    _StatusRow('Devices Found', '${ble.scanResults.length}'),
                  ],
                  trailing: BleStatusBadge(status: ble.connectionStatus),
                ),
                const SizedBox(height: 12),

                // ── Left Insole ──────────────────────────────────────────
                _InsoleStatusCard(
                  device: ble.connectedDeviceLeft,
                  telemetryBattery: tele.leftData.batteryLevel,
                  side: InsoleSide.left,
                  onReconnect: () => ble.reconnectDeviceOfSide(InsoleSide.left),
                ),
                const SizedBox(height: 12),

                // ── Right Insole ─────────────────────────────────────────
                _InsoleStatusCard(
                  device: ble.connectedDeviceRight,
                  telemetryBattery: tele.rightData.batteryLevel,
                  side: InsoleSide.right,
                  onReconnect: () => ble.reconnectDeviceOfSide(InsoleSide.right),
                ),
                const SizedBox(height: 12),

                // ── BLE Services (placeholder) ───────────────────────────
                _StatusCard(
                  title: 'BLE Services',
                  children: [
                    _StatusRow('Telemetry Service', 'Active'),
                    _StatusRow('Gait Service', 'Active'),
                    _StatusRow('Battery Service', 'Active'),
                    _StatusRow('Cue Control', 'Writable'),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Disconnect button ────────────────────────────────────
                Center(
                  child: GlowButton(
                    label: AppStrings.btnDisconnect,
                    icon: Icons.bluetooth_disabled,
                    isDestructive: true,
                    onPressed: (ble.isConnected || ble.hasAnyDeviceConnected)
                        ? () => ble.disconnect()
                        : null,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InsoleStatusCard extends StatelessWidget {
  final InsoleDevice? device;
  final int telemetryBattery;
  final InsoleSide side;
  final VoidCallback onReconnect;

  const _InsoleStatusCard({
    required this.device,
    required this.telemetryBattery,
    required this.side,
    required this.onReconnect,
  });

  @override
  Widget build(BuildContext context) {
    final isLeft  = side == InsoleSide.left;
    final color   = isLeft ? AppColors.leftInsole : AppColors.rightInsole;
    final label   = isLeft ? AppStrings.leftInsole : AppStrings.rightInsole;
    final dev     = device;

    return _StatusCard(
      title: label,
      accentColor: color,
      trailing: dev != null
          ? BatteryIndicator(level: telemetryBattery)
          : null,
      children: dev != null
          ? [
              _StatusRow('ID', dev.id),
              _StatusRow('RSSI', '${dev.rssi ?? "--"} dBm'),
              _StatusRow('Signal', '${dev.rssiStrength}/4 bars'),
              _StatusRow('Status', dev.statusLabel),
              _StatusRow('Reconnect Attempts', '${dev.reconnectAttempts}'),
            ]
          : [
              _StatusRow('Status', 'Not Connected', color: AppColors.alertRed),
            ],
      footer: dev == null
          ? TextButton.icon(
              onPressed: onReconnect,
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text(AppStrings.btnReconnect),
            )
          : null,
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? trailing;
  final Widget? footer;
  final Color? accentColor;

  const _StatusCard({
    required this.title,
    required this.children,
    this.trailing,
    this.footer,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primaryCyan;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color)),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const Divider(height: 16),
          ...children,
          if (footer != null) ...[
            const SizedBox(height: 8),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatusRow(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary)),
          const Spacer(),
          Text(value, style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color ?? AppColors.textPrimary,
            fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
