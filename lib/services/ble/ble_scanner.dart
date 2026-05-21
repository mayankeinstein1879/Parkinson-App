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

      if (!kIsWeb) {
        _addSystemAndBondedDevices(filterName).catchError((e) {
          AppLogger.ble('Error adding system/bonded devices', error: e);
        });
      }

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

  Future<void> _addSystemAndBondedDevices(String? filterName) async {
    if (kIsWeb) return;

    final targetFilter = filterName ?? BleConstants.deviceNamePrefix;
    AppLogger.ble('Querying bonded and system BLE devices matching prefix: "$targetFilter"');

    // 1. Query connected system devices (already connected to OS by system bluetooth)
    List<BluetoothDevice> system = [];
    try {
      system = await FlutterBluePlus.systemDevices([Guid(BleConstants.telemetryServiceUuid)]);
    } catch (e) {
      AppLogger.ble('Error getting system devices', error: e);
    }

    // 2. Query bonded/paired devices (Android only)
    List<BluetoothDevice> bonded = [];
    try {
      bonded = await FlutterBluePlus.bondedDevices;
    } catch (e) {
      AppLogger.ble('Error getting bonded devices', error: e);
    }

    final allDevices = <BluetoothDevice>{...system, ...bonded};
    bool updated = false;

    for (final device in allDevices) {
      final name = device.platformName;
      final matches = name.contains(targetFilter);
      if (!matches) continue;

      final side = InsoleDevice.detectSide(name);
      final id = device.remoteId.str;

      if (!_foundDevices.containsKey(id)) {
        _foundDevices[id] = InsoleDevice(
          id: id,
          name: name.isEmpty ? 'Insole (${id.substring(0, 5)})' : name,
          side: side,
          rssi: null, // RSSI unknown/null for system/bonded devices until connected
          lastSeen: DateTime.now(),
          status: ConnectionStatus.disconnected,
        );
        AppLogger.ble('Retrieved system/bonded device: $name | Side: ${side.name} | ID: $id');
        updated = true;
      }
    }

    if (updated) {
      _emitUpdatedList();
    }
  }

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

    _emitUpdatedList();
  }

  void _emitUpdatedList() {
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
