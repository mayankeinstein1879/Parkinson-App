import 'package:parkinson_insole_app/models/insole_device.dart';
import 'package:parkinson_insole_app/models/cue_settings.dart';

/// Abstract BLE manager interface.
///
/// Architecture Decision:
/// All BLE operations go through this abstract class.
/// This makes it trivial to swap hardware targets:
///   - [Esp32BleManager] → current (flutter_blue_plus implementation)
///   - [Stm32BleManager] → future STM32WB55 (same interface, different UUIDs/protocol)
///   - [MockBleService]  → for testing without hardware
///
/// The BleProvider (state layer) only ever holds a reference to BleManager,
/// never to the concrete implementation.
abstract class BleManager {

  // ── Streams ───────────────────────────────────────────────────────────────

  /// Emits the current list of discovered insole devices during scanning.
  Stream<List<InsoleDevice>> get scanResultsStream;

  /// Emits connection status changes for the currently active device.
  Stream<ConnectionStatus> get connectionStatusStream;

  /// Raw byte stream from the BLE notification characteristic.
  /// Parsed by [BleParser] into [TelemetryData].
  Stream<List<int>> get rawTelemetryStream;

  // ── Scanning ──────────────────────────────────────────────────────────────

  /// Starts BLE scan with optional timeout and device name filter.
  /// Filters by [filterName] prefix if provided; otherwise returns all devices.
  Future<void> startScan({
    Duration timeout = const Duration(seconds: 15),
    String? filterName,
  });

  /// Stops an active BLE scan immediately.
  Future<void> stopScan();

  /// Whether a BLE scan is currently active.
  bool get isScanning;

  // ── Connection ────────────────────────────────────────────────────────────

  /// Connect to a discovered [InsoleDevice].
  /// Returns [true] on success, [false] on failure.
  Future<bool> connectToDevice(InsoleDevice device);

  /// Disconnect from the currently connected device.
  Future<void> disconnect();

  /// Enable/disable automatic reconnect on unexpected disconnection.
  Future<void> enableAutoReconnect(bool enabled);

  /// The currently connected device, or null if disconnected.
  InsoleDevice? get connectedDevice;

  // ── Characteristics ───────────────────────────────────────────────────────

  /// Read a single BLE characteristic value.
  /// Returns the raw bytes, or null if read failed.
  Future<List<int>?> readCharacteristic(
    String serviceUuid,
    String characteristicUuid,
  );

  /// Write bytes to a BLE characteristic.
  /// Returns [true] if the write succeeded.
  Future<bool> writeCharacteristic(
    String serviceUuid,
    String characteristicUuid,
    List<int> data,
  );

  /// Subscribe to notifications on a BLE characteristic.
  /// Returns a stream of raw bytes emitted whenever the device notifies.
  Stream<List<int>> subscribeToCharacteristic(
    String serviceUuid,
    String characteristicUuid,
  );

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Initialize BLE adaptor and request platform permissions.
  Future<void> initialize();

  /// Clean up all streams, subscriptions and connections.
  Future<void> dispose();

  // ── Convenience: Send Cue Command ─────────────────────────────────────────

  /// Convenience method: convert [CueSettings] into a BLE write.
  Future<bool> sendCueCommand(CueSettings settings);
}
