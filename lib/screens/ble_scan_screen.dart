import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:parkinson_insole_app/constants/app_colors.dart';
import 'package:parkinson_insole_app/constants/app_strings.dart';
import 'package:parkinson_insole_app/models/insole_device.dart';
import 'package:parkinson_insole_app/providers/ble_provider.dart';
import 'package:parkinson_insole_app/widgets/glow_button.dart';
import 'package:parkinson_insole_app/widgets/ble_status_badge.dart';

/// BLE scan screen — discovers and lists nearby insole devices.
class BleScanScreen extends StatefulWidget {
  const BleScanScreen({super.key});

  @override
  State<BleScanScreen> createState() => _BleScanScreenState();
}

class _BleScanScreenState extends State<BleScanScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.titleScan),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<BleProvider>(
        builder: (context, ble, _) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ── Radar Animation ─────────────────────────────────────────
                _RadarWidget(
                  isScanning: ble.isScanning,
                  controller: _radarController,
                ),
                const SizedBox(height: 24),

                // ── Status text ─────────────────────────────────────────────
                Text(
                  ble.isScanning
                      ? AppStrings.bleScanning
                      : ble.scanResults.isEmpty
                          ? AppStrings.bleNotFound
                          : '${ble.scanResults.length} device(s) found',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // ── Scan / Stop button ──────────────────────────────────────
                GlowButton(
                  label: ble.isScanning
                      ? AppStrings.btnStopScan
                      : AppStrings.btnScan,
                  icon: ble.isScanning ? Icons.stop : Icons.search,
                  isLoading: false,
                  onPressed: ble.isScanning
                      ? () => ble.stopScan()
                      : () => ble.startScan(),
                ),
                const SizedBox(height: 24),

                // ── Error message ───────────────────────────────────────────
                if (ble.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.alertRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.alertRed.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.alertRed, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ble.errorMessage!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.alertRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Device list ─────────────────────────────────────────────
                Expanded(
                  child: ble.scanResults.isEmpty && !ble.isScanning
                      ? _EmptyState()
                      : ListView.separated(
                          itemCount: ble.scanResults.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          padding: const EdgeInsets.only(top: 8),
                          itemBuilder: (context, index) {
                            final device = ble.scanResults[index];
                            return _DeviceListTile(
                              device: device,
                              onConnect: () => _connectToDevice(context, ble, device),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _connectToDevice(
    BuildContext ctx, BleProvider ble, InsoleDevice device) async {
    Navigator.pushNamed(ctx, '/connect', arguments: device);
    await ble.connectToDevice(device);
  }
}

// ── Radar Animation ───────────────────────────────────────────────────────────

class _RadarWidget extends StatelessWidget {
  final bool isScanning;
  final AnimationController controller;

  const _RadarWidget({required this.isScanning, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isScanning)
            ...List.generate(3, (i) =>
              AnimatedBuilder(
                animation: controller,
                builder: (_, __) {
                  final progress = (controller.value + i / 3) % 1.0;
                  return Transform.scale(
                    scale: 0.4 + progress * 0.6,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryCyan.withOpacity(
                            (1 - progress) * 0.6),
                          width: 1.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isScanning
                  ? AppColors.primaryCyan.withOpacity(0.15)
                  : AppColors.surface,
              border: Border.all(
                color: isScanning ? AppColors.primaryCyan : AppColors.disconnected,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.bluetooth_searching,
              color: isScanning ? AppColors.primaryCyan : AppColors.disconnected,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Device Tile ───────────────────────────────────────────────────────────────

class _DeviceListTile extends StatelessWidget {
  final InsoleDevice device;
  final VoidCallback onConnect;

  const _DeviceListTile({required this.device, required this.onConnect});

  @override
  Widget build(BuildContext context) {
    final isLeft = device.isLeft;
    final color  = isLeft ? AppColors.leftInsole : AppColors.rightInsole;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          // Side badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Center(
              child: Text(
                device.sideLabel,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Orbitron',
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Device info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.displayName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    // RSSI bars
                    _RssiBars(strength: device.rssiStrength),
                    const SizedBox(width: 6),
                    Text(
                      device.rssi != null ? '${device.rssi} dBm' : '--',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Connect button
          TextButton(
            onPressed: onConnect,
            child: Text(
              AppStrings.btnConnect,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 300.ms).slideX(begin: 0.1, end: 0);
  }
}

class _RssiBars extends StatelessWidget {
  final int strength; // 0 – 4

  const _RssiBars({required this.strength});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(4, (i) {
        final active = i < strength;
        return Container(
          width: 4,
          height: 4.0 + i * 3,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: active ? AppColors.accentGreen : AppColors.textDisabled,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bluetooth_disabled,
              size: 48, color: AppColors.textDisabled),
          const SizedBox(height: 12),
          Text(
            AppStrings.bleNotFoundHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
