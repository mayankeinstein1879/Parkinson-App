import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:parkinson_insole_app/constants/app_colors.dart';
import 'package:parkinson_insole_app/models/insole_device.dart';

/// BLE connection status badge with animated pulse when connected.
class BleStatusBadge extends StatelessWidget {
  final ConnectionStatus status;
  final bool compact; // If true, shows icon-only; else icon + label

  const BleStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(status);
    final label = _labelFor(status);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pulsing BT icon
        Stack(
          alignment: Alignment.center,
          children: [
            // Glow ring — only when connected
            if (status == ConnectionStatus.connected)
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.25),
                ),
              ).animate(onPlay: (c) => c.repeat())
                  .scale(duration: 1200.ms, begin: const Offset(0.7, 0.7),
                         end: const Offset(1.4, 1.4), curve: Curves.easeOut)
                  .fade(duration: 1200.ms, begin: 0.8, end: 0.0),

            Icon(Icons.bluetooth, size: 14, color: color),
          ],
        ),

        if (!compact) ...[
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }

  Color _colorFor(ConnectionStatus s) {
    switch (s) {
      case ConnectionStatus.connected:    return AppColors.connected;
      case ConnectionStatus.scanning:     return AppColors.scanning;
      case ConnectionStatus.connecting:   return AppColors.scanning;
      case ConnectionStatus.reconnecting: return AppColors.reconnecting;
      case ConnectionStatus.error:        return AppColors.alertRed;
      case ConnectionStatus.disconnected: return AppColors.disconnected;
    }
  }

  String _labelFor(ConnectionStatus s) {
    switch (s) {
      case ConnectionStatus.connected:    return 'Connected';
      case ConnectionStatus.scanning:     return 'Scanning';
      case ConnectionStatus.connecting:   return 'Connecting';
      case ConnectionStatus.reconnecting: return 'Reconnecting';
      case ConnectionStatus.error:        return 'Error';
      case ConnectionStatus.disconnected: return 'Disconnected';
    }
  }
}
