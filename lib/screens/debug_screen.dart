import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parkinson_insole_app/constants/app_colors.dart';
import 'package:parkinson_insole_app/constants/app_strings.dart';
import 'package:parkinson_insole_app/providers/ble_provider.dart';
import 'package:parkinson_insole_app/providers/settings_provider.dart';
import 'package:parkinson_insole_app/providers/telemetry_provider.dart';

/// Developer debug console — raw BLE data, logs, and controls.
/// Only fully useful when developer mode is ON in settings.
class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _logs.add('[${_ts()}] Debug console started');
    _logs.add('[${_ts()}] Listening for BLE events...');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _ts() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
  }

  void _addLog(String msg) {
    setState(() {
      _logs.add('[${_ts()}] $msg');
      if (_logs.length > 200) _logs.removeAt(0); // cap log size
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.titleDebug),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.alertRed),
            tooltip: AppStrings.btnClearLog,
            onPressed: () => setState(() => _logs.clear()),
          ),
        ],
      ),
      body: Consumer3<BleProvider, TelemetryProvider, SettingsProvider>(
        builder: (context, ble, tele, settings, _) {
          return Column(
            children: [

              // ── Live Telemetry Summary ─────────────────────────────────
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LIVE TELEMETRY',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.primaryCyan, letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _DebugChip('BLE', ble.connectionStatus.name,
                            ble.isConnected ? AppColors.accentGreen : AppColors.alertRed),
                        const SizedBox(width: 8),
                        _DebugChip('FOG L',
                            '${tele.leftData.fogRisk.toStringAsFixed(0)}%',
                            AppColors.fogRiskColor(tele.leftData.fogRisk)),
                        const SizedBox(width: 8),
                        _DebugChip('FOG R',
                            '${tele.rightData.fogRisk.toStringAsFixed(0)}%',
                            AppColors.fogRiskColor(tele.rightData.fogRisk)),
                        const SizedBox(width: 8),
                        _DebugChip('CAD',
                            '${tele.leftData.stepCadence.toStringAsFixed(0)} spm',
                            AppColors.primaryCyan),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Raw telemetry JSON
                    Text(
                      'LEFT:  ${_telemetryJson(tele, isLeft: true)}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 10,
                          fontFamily: 'monospace'),
                    ),
                    Text(
                      'RIGHT: ${_telemetryJson(tele, isLeft: false)}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 10,
                          fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),

              // ── Control Buttons ────────────────────────────────────────
              Container(
                color: AppColors.cardBackground,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    _DebugButton(
                      'Scan',
                      Icons.search,
                      AppColors.primaryCyan,
                      onPressed: () {
                        _addLog('Manual scan triggered');
                        ble.startScan();
                      },
                    ),
                    const SizedBox(width: 8),
                    _DebugButton(
                      'Disconnect',
                      Icons.bluetooth_disabled,
                      AppColors.alertRed,
                      onPressed: () {
                        _addLog('Manual disconnect triggered');
                        ble.disconnect();
                      },
                    ),
                    const SizedBox(width: 8),
                    _DebugButton(
                      'Mock: ${settings.useMockData ? "ON" : "OFF"}',
                      Icons.science_outlined,
                      settings.useMockData
                          ? AppColors.warningOrange
                          : AppColors.textDisabled,
                      onPressed: () {
                        _addLog('Mock data toggled → ${!settings.useMockData}');
                        settings.toggleMockData();
                      },
                    ),
                    const SizedBox(width: 8),
                    _DebugButton(
                      'Reset',
                      Icons.restart_alt,
                      AppColors.secondaryPurple,
                      onPressed: () {
                        _addLog('Telemetry history reset');
                        tele.resetHistory();
                      },
                    ),
                  ],
                ),
              ),

              // ── Log Console ────────────────────────────────────────────
              Expanded(
                child: Container(
                  color: const Color(0xFF020810),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final line = _logs[index];
                      Color color = AppColors.textSecondary;
                      if (line.contains('error') || line.contains('ERROR')) {
                        color = AppColors.alertRed;
                      } else if (line.contains('BLE') || line.contains('connect')) {
                        color = AppColors.primaryCyan;
                      } else if (line.contains('FOG') || line.contains('risk')) {
                        color = AppColors.warningOrange;
                      }
                      return Text(
                        line,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontFamily: 'monospace',
                          height: 1.5,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _telemetryJson(TelemetryProvider tele, {required bool isLeft}) {
    final d = isLeft ? tele.leftData : tele.rightData;
    return 'stab:${d.gaitStability.toStringAsFixed(0)} '
        'fog:${d.fogRisk.toStringAsFixed(0)} '
        'cad:${d.stepCadence.toStringAsFixed(0)} '
        'bat:${d.batteryLevel}%';
  }
}

class _DebugChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DebugChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebugButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _DebugButton(this.label, this.icon, this.color,
      {required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      color: color, fontSize: 9, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
