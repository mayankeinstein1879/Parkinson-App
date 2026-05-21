import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:parkinson_insole_app/constants/ble_constants.dart';
import 'package:parkinson_insole_app/models/insole_device.dart';
import 'package:parkinson_insole_app/utils/logger.dart';

/// Handles BLE device scanning using flutter_blue_plus.
///
/// On ANDROID: filters by device name prefix — shows our custom radar UI.
/// On WEB:     passes withServices UUID so Chrome's native device picker
///             only shows devices advertising our telemetry service.
///             After user picks, device appears in devicesStream normally.
class BleScanner {
  // ── State ─────────────────────────────────────────────────────────────────
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  final StreamController<List<InsoleDevice>> _devicesController =
      StreamController<List<InsoleDevice>>.broadcast();

  final Map<String, InsoleDevice> _foundDevices = {};
  bool _isScanning = false;

  // ── Public API ────────────────────────────────────────────────────────────

  Stream<List<InsoleDevice>> get devicesStream => _devicesController.stream;
  bool get isScanning => _isScanning;

  /// Start BLE scan.
  /// - On Android: scans continuously, filters by name prefix.
  /// - On Web: opens Chrome device picker filtered by service UUID.
  Future<void> startScan({
    Duration timeout = BleConstants.scanTimeout,
    String? filterName,
  }) async {
    if (_isScanning) {
      AppLogger.ble('Scan already in progress — skipping');
      return;
    }

    _foundDevices.clear();
    _isScanning = true;
    AppLogger.ble(kIsWeb
        ? 'Web scan: opening Chrome BLE device picker...'
        : 'Android scan: scanning for ${timeout.inSeconds}s...');

    try {
      await _scanSubscription?.cancel();

      if (kIsWeb) {
        // ── WEB ──────────────────────────────────────────────────────────────
        // Web Bluetooth API: pass withServices so Chrome picker shows only
        // devices advertising our telemetry service UUID.
        // User sees a browser dialog — they pick Parkinson_L_Insole or _R_Insole.
        await FlutterBluePlus.startScan(
          withServices: [Guid(BleConstants.telemetryServiceUuid)],
          timeout: timeout,
        );
      } else {
        // ── ANDROID ──────────────────────────────────────────────────────────
        // Filter by name so we don't flood the list with unrelated devices
        // Scan all devices, manual filtering is performed in onScanResults listener below
        await FlutterBluePlus.startScan(
          timeout: timeout,
        );
      }

      _scanSubscription = FlutterBluePlus.onScanResults.listen(
        (results) => _onScanResults(results, filterName),
        onError: (Object e) => AppLogger.ble('Scan error', error: e),
        onDone: _onScanDone,
      );

      // Safety: auto-stop after timeout
      Timer(timeout + const Duration(seconds: 2), () {
        if (_isScanning) stopScan();
      });

    } catch (e) {
      AppLogger.ble('Failed to start scan', error: e);
      _isScanning = false;
    }
  }

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
      final name = result.device.platformName.isNotEmpty
          ? result.device.platformName
          : result.advertisementData.advName;

      // On web the browser already filtered — accept all results
      // On Android filter by name prefix
      if (!kIsWeb) {
        final matches = filterName != null
            ? name.contains(filterName)
            : name.contains(BleConstants.deviceNamePrefix);
        if (!matches) continue;
      }

      final side = InsoleDevice.detectSide(name);
      final id   = result.device.remoteId.str;

      _foundDevices[id] = InsoleDevice(
        id:       id,
        name:     name.isEmpty ? 'Insole (${id.substring(0, 5)})' : name,
        side:     side,
        rssi:     result.rssi,
        lastSeen: DateTime.now(),
        status:   ConnectionStatus.disconnected,
      );

      AppLogger.ble('Found: $name | Side: ${side.name} | RSSI: ${result.rssi} dBm');
    }

    final sorted = _foundDevices.values.toList()
      ..sort((a, b) => a.side.index.compareTo(b.side.index));

    if (!_devicesController.isClosed) {
      _devicesController.add(sorted);
    }
  }

  void _onScanDone() {
    _isScanning = false;
    AppLogger.ble('Scan done. Found ${_foundDevices.length} insole(s).');
  }

  Future<void> dispose() async {
    await _scanSubscription?.cancel();
    await _devicesController.close();
    _isScanning = false;
  }
}
