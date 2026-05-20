import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:parkinson_insole_app/models/insole_device.dart';
import 'package:parkinson_insole_app/models/telemetry_data.dart';
import 'package:parkinson_insole_app/services/ble/ble_manager.dart';
import 'package:parkinson_insole_app/services/ble/ble_parser.dart';
import 'package:parkinson_insole_app/utils/logger.dart';

/// Manages live telemetry data from both insoles.
///
/// Listens to the raw BLE byte stream from [BleManager],
/// parses packets via [BleParser], and notifies widgets of updates.
/// Also keeps a rolling history buffer for chart widgets.
class TelemetryProvider extends ChangeNotifier {
  // ── Dependencies ──────────────────────────────────────────────────────────
  final BleManager _bleManager;
  final BleParser  _parser = BleParser();

  TelemetryProvider(this._bleManager) {
    _subscribeToTelemetry();
  }

  // ── State ─────────────────────────────────────────────────────────────────
  TelemetryData _leftData  = TelemetryData.empty(InsoleSide.left);
  TelemetryData _rightData = TelemetryData.empty(InsoleSide.right);

  /// Rolling history — last 60 readings per side (≈30 seconds at 500ms interval)
  final List<TelemetryData> _leftHistory  = [];
  final List<TelemetryData> _rightHistory = [];

  static const int _maxHistoryLength = 60;

  StreamSubscription<List<int>>? _telemetrySub;

  // ── Getters ───────────────────────────────────────────────────────────────
  TelemetryData get leftData  => _leftData;
  TelemetryData get rightData => _rightData;

  List<TelemetryData> get leftHistory  => List.unmodifiable(_leftHistory);
  List<TelemetryData> get rightHistory => List.unmodifiable(_rightHistory);

  /// Average gait asymmetry across recent history
  double get avgGaitAsymmetry {
    final all = [..._leftHistory, ..._rightHistory];
    if (all.isEmpty) return 0;
    return all.map((d) => d.gaitAsymmetry).reduce((a, b) => a + b) / all.length;
  }

  /// Highest FOG risk across both insoles at this moment
  double get fogRiskLevel => _leftData.fogRisk > _rightData.fogRisk
      ? _leftData.fogRisk
      : _rightData.fogRisk;

  /// Whether FOG risk is at a critical threshold (≥70%)
  bool get isCriticalFogRisk => fogRiskLevel >= 70;

  /// Average battery across both connected insoles
  double get avgBattery {
    final levels = <int>[];
    if (_leftData.batteryLevel  > 0) levels.add(_leftData.batteryLevel);
    if (_rightData.batteryLevel > 0) levels.add(_rightData.batteryLevel);
    if (levels.isEmpty) return 0;
    return levels.reduce((a, b) => a + b) / levels.length;
  }

  /// FOG risk sparkline data (last 20 readings) for mini chart
  List<double> get fogRiskHistory {
    final combined = [
      ..._leftHistory.map((d) => d.fogRisk),
      ..._rightHistory.map((d) => d.fogRisk),
    ];
    if (combined.length > 20) return combined.sublist(combined.length - 20);
    return combined;
  }

  // ── Telemetry Subscription ────────────────────────────────────────────────

  void _subscribeToTelemetry() {
    _telemetrySub?.cancel();
    _telemetrySub = _bleManager.rawTelemetryStream.listen(
      _onRawPacket,
      onError: (Object e) => AppLogger.telemetry('Telemetry stream error: $e'),
    );
  }

  void _onRawPacket(List<int> bytes) {
    // Try parsing as left insole first, then right
    // In practice the BleProvider knows which device sent the packet
    // and would call updateFromPacket(bytes, side) directly.
    // For now we detect from context (mock always sends left+right alternating).
    _updateSide(bytes, InsoleSide.left);
  }

  /// Called by BleProvider when a packet arrives with known side information.
  void updateFromPacket(List<int> bytes, InsoleSide side) {
    _updateSide(bytes, side);
  }

  /// Directly inject a [TelemetryData] object (e.g., from MockBleService decoded).
  void updateFromTelemetry(TelemetryData data) {
    if (data.side == InsoleSide.left) {
      _leftData = data;
      _appendHistory(_leftHistory, data);
    } else if (data.side == InsoleSide.right) {
      _rightData = data;
      _appendHistory(_rightHistory, data);
    }
    notifyListeners();
  }

  void _updateSide(List<int> bytes, InsoleSide side) {
    final parsed = _parser.parseTelemetryPacket(bytes, side);
    if (parsed == null) return;

    if (side == InsoleSide.left) {
      _leftData = parsed;
      _appendHistory(_leftHistory, parsed);
    } else {
      _rightData = parsed;
      _appendHistory(_rightHistory, parsed);
    }

    AppLogger.telemetry(
      '${side.name.toUpperCase()} — '
      'Stab:${parsed.gaitStability.toStringAsFixed(1)}% '
      'FOG:${parsed.fogRisk.toStringAsFixed(1)}% '
      'Cad:${parsed.stepCadence.toStringAsFixed(0)} spm',
    );

    notifyListeners();
  }

  void _appendHistory(List<TelemetryData> history, TelemetryData data) {
    history.add(data);
    if (history.length > _maxHistoryLength) {
      history.removeAt(0);
    }
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  void resetHistory() {
    _leftHistory.clear();
    _rightHistory.clear();
    _leftData  = TelemetryData.empty(InsoleSide.left);
    _rightData = TelemetryData.empty(InsoleSide.right);
    notifyListeners();
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  Future<void> dispose() async {
    await _telemetrySub?.cancel();
    super.dispose();
  }
}
