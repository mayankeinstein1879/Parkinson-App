import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:parkinson_insole_app/constants/ble_constants.dart';
import 'package:parkinson_insole_app/models/cue_settings.dart';
import 'package:parkinson_insole_app/models/insole_device.dart';
import 'package:parkinson_insole_app/services/ble/ble_characteristic.dart';
import 'package:parkinson_insole_app/services/ble/ble_connection.dart';
import 'package:parkinson_insole_app/services/ble/ble_manager.dart';
import 'package:parkinson_insole_app/services/ble/ble_scanner.dart';
import 'package:parkinson_insole_app/utils/logger.dart';

/// Concrete BLE manager targeting ESP32 hardware.
///
/// This is the real implementation used when talking to the physical ESP32
/// insole device. It wires together:
///   - [BleScanner]               → device discovery
///   - [BleConnection]            → connect / disconnect / auto-reconnect
///   - [BleCharacteristicManager] → read / write / notifications
///
/// When the hardware migrates to STM32WB55, create a new class
/// (e.g. Stm32BleManager) implementing the same [BleManager] interface.
/// No other code in the app needs to change.
///
/// ─────────────────────────────────────────────────────────────────────────
/// HOW IT WORKS (end-to-end flow):
///
///  1. Call [startScan()] → BleScanner finds "Parkinson_L_Insole" or
///     "Parkinson_R_Insole" by name and emits them via [scanResultsStream].
///
///  2. Call [connectToDevice(device)] → BleConnection.connect() opens the
///     GATT connection. MTU is negotiated to 512 bytes.
///
///  3. [_onConnected()] triggers [BleCharacteristicManager.discoverServices()]
///     then subscribes to the Combined Telemetry characteristic notifications.
///
///  4. Every 500 ms the ESP32 pushes a 20-byte packet.
///     The raw bytes are forwarded to [rawTelemetryStream] where
///     [BleParser] (in TelemetryProvider) converts them to [TelemetryData].
///
///  5. Cue commands (visual/haptic/audio intensity) are written to
///     [BleConstants.cueControlCharUuid] via [writeCharacteristic()].
/// ─────────────────────────────────────────────────────────────────────────
class Esp32BleManager implements BleManager {

  // ── Sub-services ──────────────────────────────────────────────────────────
  final BleScanner                _scanner   = BleScanner();
  final BleConnection             _connection = BleConnection();
  final BleCharacteristicManager  _chars     = BleCharacteristicManager();

  // ── Telemetry stream (raw bytes from BLE notifications) ───────────────────
  final StreamController<List<int>> _telemetryController =
      StreamController<List<int>>.broadcast();

  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<ConnectionStatus>? _connStatusSub;

  InsoleDevice? _currentDevice;
  bool _autoReconnect = true;

  // ── BleManager interface ───────────────────────────────────────────────────

  @override
  Stream<List<InsoleDevice>> get scanResultsStream => _scanner.devicesStream;

  @override
  Stream<ConnectionStatus> get connectionStatusStream =>
      _connection.statusStream;

  @override
  Stream<List<int>> get rawTelemetryStream => _telemetryController.stream;

  @override
  bool get isScanning => _scanner.isScanning;

  @override
  InsoleDevice? get connectedDevice => _connection.connectedInsole;

  // ── Initialise ────────────────────────────────────────────────────────────

  @override
  Future<void> initialize() async {
    AppLogger.ble('Esp32BleManager initialising');

    // Watch the Bluetooth adaptor state (Android/desktop only)
    if (!kIsWeb) {
      FlutterBluePlus.adapterState.listen((state) {
        AppLogger.ble('BT Adapter state → $state');
        if (state == BluetoothAdapterState.off) {
          _telemetryController.add([]);
        }
      });
    } else {
      AppLogger.ble('Web — skipping adapterState listener (browser manages BT)');
    }

    // When connection state changes, react accordingly
    _connStatusSub = _connection.statusStream.listen(_onConnectionStatus);
  }

  // ── Scanning ──────────────────────────────────────────────────────────────

  @override
  Future<void> startScan({
    Duration timeout = BleConstants.scanTimeout,
    String? filterName,
  }) async {
    // Filter by device name prefix so we don't flood the list
    await _scanner.startScan(
      timeout: timeout,
      filterName: filterName ?? BleConstants.deviceNamePrefix,
    );
  }

  @override
  Future<void> stopScan() => _scanner.stopScan();

  // ── Connection ────────────────────────────────────────────────────────────

  @override
  Future<bool> connectToDevice(InsoleDevice device) async {
    _currentDevice = device;
    final success = await _connection.connect(device);

    if (success) {
      await _onConnected(device);
    }
    return success;
  }

  @override
  Future<void> disconnect() async {
    await _notifySub?.cancel();
    _notifySub = null;
    await _connection.disconnect();
    _currentDevice = null;
  }

  @override
  Future<void> enableAutoReconnect(bool enabled) async {
    _autoReconnect = enabled;
    _connection.autoReconnectEnabled = enabled;
  }

  // ── Characteristics ───────────────────────────────────────────────────────

  @override
  Future<List<int>?> readCharacteristic(
    String serviceUuid,
    String characteristicUuid,
  ) {
    return _chars.readCharacteristic(serviceUuid, characteristicUuid);
  }

  @override
  Future<bool> writeCharacteristic(
    String serviceUuid,
    String characteristicUuid,
    List<int> data,
  ) {
    return _chars.writeCharacteristic(serviceUuid, characteristicUuid, data);
  }

  @override
  Stream<List<int>> subscribeToCharacteristic(
    String serviceUuid,
    String characteristicUuid,
  ) {
    return _chars.subscribeToNotifications(serviceUuid, characteristicUuid);
  }

  // ── Cue Command ───────────────────────────────────────────────────────────

  /// Sends a 3-byte cue intensity command to the ESP32.
  ///
  /// Byte layout (matches ESP32 firmware expectation):
  ///   [0] visual intensity 0–255
  ///   [1] haptic intensity 0–255
  ///   [2] audio volume     0–255
  @override
  Future<bool> sendCueCommand(CueSettings settings) async {
    final data = settings.toBleCommand();
    AppLogger.ble('Sending cue command → $data');
    return _chars.writeCharacteristic(
      BleConstants.telemetryServiceUuid,
      BleConstants.cueControlCharUuid,
      data,
    );
  }

  // ── Private: post-connect setup ───────────────────────────────────────────

  /// Called immediately after a successful GATT connection.
  /// Discovers services, then subscribes to the telemetry notification.
  Future<void> _onConnected(InsoleDevice insole) async {
    try {
      final btDevice = BluetoothDevice.fromId(insole.id);

      // 1. Discover all GATT services on the ESP32
      AppLogger.ble('Discovering services for ${insole.displayName}');
      await _chars.discoverServices(btDevice);

      // 2. Subscribe to combined telemetry notifications
      //    The ESP32 pushes 20-byte packets on this characteristic at ~2 Hz
      _subscribeToTelemetry();

    } catch (e) {
      AppLogger.ble('Post-connect setup failed', error: e);
    }
  }

  /// Subscribe to the combined telemetry characteristic and
  /// forward every incoming packet to [rawTelemetryStream].
  void _subscribeToTelemetry() {
    _notifySub?.cancel();

    final stream = _chars.subscribeToNotifications(
      BleConstants.telemetryServiceUuid,
      BleConstants.combinedTelemetryCharUuid,
    );

    _notifySub = stream.listen(
      (bytes) {
        if (bytes.isNotEmpty && !_telemetryController.isClosed) {
          _telemetryController.add(bytes);
        }
      },
      onError: (Object e) {
        AppLogger.ble('Telemetry notification error', error: e);
      },
      onDone: () {
        AppLogger.ble('Telemetry notification stream closed');
      },
    );

    AppLogger.ble('Subscribed to combined telemetry notifications');
  }

  /// React to BLE connection state changes.
  void _onConnectionStatus(ConnectionStatus status) {
    AppLogger.ble('Connection status → $status');

    if (status == ConnectionStatus.connected) {
      // Re-subscribe if we reconnected after a drop
      if (_currentDevice != null) {
        _onConnected(_currentDevice!);
      }
    } else if (status == ConnectionStatus.disconnected ||
               status == ConnectionStatus.error) {
      _notifySub?.cancel();
      _notifySub = null;
    }
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  Future<void> dispose() async {
    await _notifySub?.cancel();
    await _connStatusSub?.cancel();
    await _scanner.dispose();
    await _connection.dispose();
    _chars.dispose();
    await _telemetryController.close();
    AppLogger.ble('Esp32BleManager disposed');
  }
}
