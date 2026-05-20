import 'dart:async';
import 'dart:math' as math;
import 'package:parkinson_insole_app/constants/ble_constants.dart';
import 'package:parkinson_insole_app/models/cue_settings.dart';
import 'package:parkinson_insole_app/models/insole_device.dart';
import 'package:parkinson_insole_app/models/telemetry_data.dart';
import 'package:parkinson_insole_app/services/ble/ble_manager.dart';
import 'package:parkinson_insole_app/utils/logger.dart';

/// Mock BLE service for development and testing without real hardware.
///
/// Implements [BleManager] so it can be used anywhere a real BLE manager is used.
/// Toggle between real BLE and mock via [SettingsProvider.useMockData].
///
/// Simulates:
/// - BLE scanning (2 fake devices appear after 1.5s)
/// - Connection (succeeds after 2s delay)
/// - Periodic telemetry stream (every 500ms)
/// - RSSI fluctuation
/// - Occasional FOG risk spikes
class MockBleService implements BleManager {
  // ── State ─────────────────────────────────────────────────────────────────
  final math.Random _rng = math.Random();
  bool _isScanning = false;
  InsoleDevice? _connectedDevice;
  Timer? _scanTimer;
  Timer? _telemetryTimer;

  final StreamController<List<InsoleDevice>> _scanController =
      StreamController<List<InsoleDevice>>.broadcast();
  final StreamController<ConnectionStatus>   _statusController =
      StreamController<ConnectionStatus>.broadcast();
  final StreamController<List<int>>          _telemetryController =
      StreamController<List<int>>.broadcast();

  // Pre-defined mock devices
  static final InsoleDevice _mockLeftDevice = InsoleDevice(
    id:    'AA:BB:CC:DD:EE:01',
    name:  'Parkinson_L_Insole',
    side:  InsoleSide.left,
    rssi:  -65,
    lastSeen: DateTime.now(),
  );

  static final InsoleDevice _mockRightDevice = InsoleDevice(
    id:    'AA:BB:CC:DD:EE:02',
    name:  'Parkinson_R_Insole',
    side:  InsoleSide.right,
    rssi:  -68,
    lastSeen: DateTime.now(),
  );

  // ── BleManager Implementation ─────────────────────────────────────────────

  @override
  Stream<List<InsoleDevice>> get scanResultsStream => _scanController.stream;

  @override
  Stream<ConnectionStatus> get connectionStatusStream => _statusController.stream;

  @override
  Stream<List<int>> get rawTelemetryStream => _telemetryController.stream;

  @override
  bool get isScanning => _isScanning;

  @override
  InsoleDevice? get connectedDevice => _connectedDevice;

  // ── Scanning ──────────────────────────────────────────────────────────────

  @override
  Future<void> startScan({
    Duration timeout = const Duration(seconds: 15),
    String? filterName,
  }) async {
    _isScanning = true;
    AppLogger.ble('[MOCK] Scanning for devices...');
    _emit(status: ConnectionStatus.scanning);

    // Emit first device after 1.5s, second after 2.5s (realistic feel)
    _scanTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!_scanController.isClosed) {
        _scanController.add([_mockLeftDevice]);
      }
      Timer(const Duration(milliseconds: 1000), () {
        if (!_scanController.isClosed) {
          _scanController.add([_mockLeftDevice, _mockRightDevice]);
        }
        _isScanning = false;
        AppLogger.ble('[MOCK] Scan complete — 2 devices found');
      });
    });
  }

  @override
  Future<void> stopScan() async {
    _scanTimer?.cancel();
    _isScanning = false;
    AppLogger.ble('[MOCK] Scan stopped');
  }

  // ── Connection ────────────────────────────────────────────────────────────

  @override
  Future<bool> connectToDevice(InsoleDevice device) async {
    AppLogger.ble('[MOCK] Connecting to ${device.displayName}...');
    _emit(status: ConnectionStatus.connecting);

    // Simulate 2s connection delay
    await Future.delayed(const Duration(seconds: 2));

    _connectedDevice = device.copyWith(status: ConnectionStatus.connected);
    _emit(status: ConnectionStatus.connected);
    AppLogger.ble('[MOCK] Connected to ${device.displayName}');

    // Start streaming mock telemetry
    _startTelemetryStream(device.side);
    return true;
  }

  @override
  Future<void> disconnect() async {
    AppLogger.ble('[MOCK] Disconnecting');
    _telemetryTimer?.cancel();
    _connectedDevice = null;
    _emit(status: ConnectionStatus.disconnected);
  }

  @override
  Future<void> enableAutoReconnect(bool enabled) async {
    AppLogger.ble('[MOCK] Auto-reconnect: $enabled');
  }

  // ── Characteristics ───────────────────────────────────────────────────────

  @override
  Future<List<int>?> readCharacteristic(String serviceUuid, String charUuid) async {
    await Future.delayed(const Duration(milliseconds: 100));
    // Return mock battery data
    return [BleConstants.packetTypeBattery, 85];
  }

  @override
  Future<bool> writeCharacteristic(
    String serviceUuid,
    String charUuid,
    List<int> data,
  ) async {
    AppLogger.ble('[MOCK] Write to $charUuid → $data');
    await Future.delayed(const Duration(milliseconds: 50));
    return true;
  }

  @override
  Stream<List<int>> subscribeToCharacteristic(
    String serviceUuid,
    String charUuid,
  ) {
    return _telemetryController.stream;
  }

  @override
  Future<bool> sendCueCommand(CueSettings settings) async {
    final bytes = settings.toBleCommand();
    AppLogger.ble('[MOCK] Cue command: $bytes');
    return true;
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  Future<void> initialize() async {
    AppLogger.ble('[MOCK] MockBleService initialized');
  }

  @override
  Future<void> dispose() async {
    _scanTimer?.cancel();
    _telemetryTimer?.cancel();
    await _scanController.close();
    await _statusController.close();
    await _telemetryController.close();
  }

  // ── Telemetry Stream ──────────────────────────────────────────────────────

  /// Emits a new mock telemetry packet every 500ms.
  /// Occasionally spikes FOG risk to simulate Freezing of Gait events.
  void _startTelemetryStream(InsoleSide side) {
    _telemetryTimer?.cancel();

    int tick = 0;
    _telemetryTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      tick++;

      // Simulate a FOG spike every ~30 ticks (15 seconds)
      final isFogSpike = tick % 30 == 0;

      final data = TelemetryData.mock(side, rng: _rng);
      final fogRisk = isFogSpike
          ? 75.0 + _rng.nextDouble() * 20
          : data.fogRisk;

      // Build a simplified 20-byte mock packet (type=combined)
      final packet = _buildMockPacket(data.copyWith(fogRisk: fogRisk));

      if (!_telemetryController.isClosed) {
        _telemetryController.add(packet);
      }
    });
  }

  /// Build a 20-byte combined telemetry packet from [TelemetryData].
  List<int> _buildMockPacket(TelemetryData d) {
    final bytes = List<int>.filled(20, 0);
    bytes[0] = BleConstants.packetTypeCombined;

    // Pressure (bytes 1-8): 4 × uint16 big-endian
    _writeUint16BE(bytes, 1, (d.pressure.heel     * BleConstants.pressureScaleFactor).round());
    _writeUint16BE(bytes, 3, (d.pressure.midfoot  * BleConstants.pressureScaleFactor).round());
    _writeUint16BE(bytes, 5, (d.pressure.forefoot * BleConstants.pressureScaleFactor).round());
    _writeUint16BE(bytes, 7, (d.pressure.toe      * BleConstants.pressureScaleFactor).round());

    bytes[9]  = d.gaitStability.round().clamp(0, 255);
    bytes[10] = d.fogRisk.round().clamp(0, 255);
    _writeUint16BE(bytes, 11, (d.stepCadence * BleConstants.cadenceScaleFactor).round());
    bytes[13] = d.gaitAsymmetry.round().clamp(0, 255);
    bytes[14] = d.walkingConfidence.round().clamp(0, 255);
    bytes[15] = d.batteryLevel.clamp(0, 255);
    bytes[16] = d.cueActive ? 1 : 0;

    return bytes;
  }

  void _writeUint16BE(List<int> bytes, int index, int value) {
    bytes[index]     = (value >> 8) & 0xFF;
    bytes[index + 1] = value & 0xFF;
  }

  void _emit({required ConnectionStatus status}) {
    if (!_statusController.isClosed) _statusController.add(status);
  }
}


