import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:parkinson_insole_app/constants/ble_constants.dart';
import 'package:parkinson_insole_app/models/insole_device.dart';
import 'package:parkinson_insole_app/utils/logger.dart';

/// Handles BLE device scanning using flutter_blue_plus.
///
/// Filters scan results to only return Parkinson's insole devices
/// by matching the device name prefix [BleConstants.deviceNamePrefix].
class BleScanner {
  // ── State ─────────────────────────────────────────────────────────────────
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  final StreamController<List<InsoleDevice>> _devicesController =
      StreamController<List<InsoleDevice>>.broadcast();

  final Map<String, InsoleDevice> _foundDevices = {};
  bool _isScanning = false;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Stream of filtered insole devices discovered during scanning.
  Stream<List<InsoleDevice>> get devicesStream => _devicesController.stream;

  bool get isScanning => _isScanning;

  /// Start BLE scan. Filters results by [filterName] (or default prefix).
  Future<void> startScan({
    Duration timeout = BleConstants.scanTimeout,
    String? filterName,
  }) async {
    if (_isScanning) {
      AppLogger.ble('Scan already in progress — skipping start');
      return;
    }

    _foundDevices.clear();
    _isScanning = true;
    AppLogger.ble('Starting BLE scan (timeout: ${timeout.inSeconds}s)');

    try {
      // Cancel any lingering subscription
      await _scanSubscription?.cancel();

      // flutter_blue_plus scan with optional name filter
      await FlutterBluePlus.startScan(
        timeout: timeout,
        withNames: filterName != null ? [filterName] : [],
      );

      _scanSubscription = FlutterBluePlus.onScanResults.listen(
        (results) => _onScanResults(results, filterName),
        onError: (Object e) {
          AppLogger.ble('Scan error', error: e);
        },
        onDone: _onScanDone,
      );

      // Fallback: auto-stop after timeout + 1s buffer
      Timer(timeout + const Duration(seconds: 1), () {
        if (_isScanning) stopScan();
      });
    } catch (e) {
      AppLogger.ble('Failed to start scan', error: e);
      _isScanning = false;
    }
  }

  /// Stop an active BLE scan.
  Future<void> stopScan() async {
    if (!_isScanning) return;
    AppLogger.ble('Stopping BLE scan');
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      AppLogger.ble('Error stopping scan', error: e);
    } finally {
      _isScanning = false;
    }
  }

  // ── Internal Handlers ─────────────────────────────────────────────────────

  void _onScanResults(List<ScanResult> results, String? filterName) {
    for (final result in results) {
      final name = result.device.platformName;

      // Filter: only show devices whose name matches the target prefix
      final matches = filterName != null
          ? name.contains(filterName)
          : name.contains(BleConstants.deviceNamePrefix);

      if (!matches) continue;

      final side = InsoleDevice.detectSide(name);
      final id   = result.device.remoteId.str;

      // Update or add device to found map
      _foundDevices[id] = InsoleDevice(
        id:       id,
        name:     name,
        side:     side,
        rssi:     result.rssi,
        lastSeen: DateTime.now(),
        status:   ConnectionStatus.disconnected,
      );

      AppLogger.ble(
        'Found: $name | Side: ${side.name} | RSSI: ${result.rssi} dBm');
    }

    // Emit updated list sorted: left insole first
    final sorted = _foundDevices.values.toList()
      ..sort((a, b) => a.side.index.compareTo(b.side.index));

    if (!_devicesController.isClosed) {
      _devicesController.add(sorted);
    }
  }

  void _onScanDone() {
    _isScanning = false;
    AppLogger.ble('Scan completed. Found ${_foundDevices.length} insole(s).');
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    await _scanSubscription?.cancel();
    await _devicesController.close();
    _isScanning = false;
  }
}
