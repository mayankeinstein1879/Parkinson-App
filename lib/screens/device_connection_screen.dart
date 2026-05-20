import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:parkinson_insole_app/constants/app_colors.dart';
import 'package:parkinson_insole_app/constants/app_strings.dart';
import 'package:parkinson_insole_app/models/insole_device.dart';
import 'package:parkinson_insole_app/providers/ble_provider.dart';
import 'package:parkinson_insole_app/widgets/glow_button.dart';

/// Connection progress screen — shown while connecting to a BLE device.
/// Auto-navigates to dashboard on success, shows retry on failure.
class DeviceConnectionScreen extends StatelessWidget {
  const DeviceConnectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final device = ModalRoute.of(context)?.settings.arguments as InsoleDevice?;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(AppStrings.titleConnect)),
      body: Consumer<BleProvider>(
        builder: (context, ble, _) {
          final status = ble.connectionStatus;

          // Auto-navigate to dashboard when connected
          if (status == ConnectionStatus.connected) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/dashboard');
              }
            });
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Connection animation ──────────────────────────────────
                  _ConnectionAnimation(status: status),
                  const SizedBox(height: 36),

                  // ── Device name ───────────────────────────────────────────
                  Text(
                    device?.displayName ?? 'Insole Device',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.primaryCyan,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // ── Status label ──────────────────────────────────────────
                  Text(
                    _statusText(status),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // ── Error + retry ─────────────────────────────────────────
                  if (status == ConnectionStatus.error) ...[
                    Text(
                      ble.errorMessage ?? AppStrings.errGeneric,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.alertRed,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    GlowButton(
                      label: AppStrings.btnRetry,
                      icon: Icons.refresh,
                      onPressed: device != null
                          ? () => ble.connectToDevice(device)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back to Scan'),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _statusText(ConnectionStatus s) {
    switch (s) {
      case ConnectionStatus.connecting:   return AppStrings.bleConnecting;
      case ConnectionStatus.connected:    return AppStrings.bleConnected + '! Navigating...';
      case ConnectionStatus.reconnecting: return AppStrings.bleReconnecting;
      case ConnectionStatus.error:        return AppStrings.bleError;
      default:                            return AppStrings.bleConnecting;
    }
  }
}

// ── Connection Animation ──────────────────────────────────────────────────────

class _ConnectionAnimation extends StatelessWidget {
  final ConnectionStatus status;
  const _ConnectionAnimation({required this.status});

  @override
  Widget build(BuildContext context) {
    final isError    = status == ConnectionStatus.error;
    final isSuccess  = status == ConnectionStatus.connected;
    final color = isError
        ? AppColors.alertRed
        : isSuccess ? AppColors.accentGreen : AppColors.primaryCyan;

    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotating ring (hidden on error/success)
          if (!isError && !isSuccess)
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryCyan.withOpacity(0.5)),
              ),
            ).animate(onPlay: (c) => c.repeat())
                .rotate(duration: 2000.ms),

          // Center icon
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
              border: Border.all(color: color.withOpacity(0.5), width: 2),
              boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 16)],
            ),
            child: Icon(
              isError ? Icons.bluetooth_disabled
                  : isSuccess ? Icons.check
                  : Icons.bluetooth_searching,
              color: color,
              size: 30,
            ),
          ).animate().scale(
            duration: 300.ms,
            curve: Curves.elasticOut,
          ),
        ],
      ),
    );
  }
}
