import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:parkinson_insole_app/utils/logger.dart';

/// Manages BLE service discovery and characteristic read/write/notify.
///
/// Always discover services first ([discoverServices]) before reading
/// or subscribing to characteristics.
class BleCharacteristicManager {
  BluetoothDevice? _device;
  final Map<String, BluetoothService> _serviceCache = {};

  // ── Service Discovery ─────────────────────────────────────────────────────

  /// Discover all BLE services on the connected device.
  /// Must be called after connecting before using read/write/notify.
  Future<void> discoverServices(BluetoothDevice device) async {
    _device = device;
    _serviceCache.clear();

    AppLogger.ble('Discovering services on ${device.platformName}');

    try {
      final services = await device.discoverServices();

      for (final service in services) {
        _serviceCache[service.uuid.str.toLowerCase()] = service;
      }

      AppLogger.ble('Discovered ${services.length} service(s)');
    } catch (e) {
      AppLogger.ble('Service discovery failed', error: e);
      rethrow;
    }
  }

  // ── Read Characteristic ───────────────────────────────────────────────────

  /// Read a characteristic value once.
  /// Returns raw bytes, or [null] if the characteristic is not found.
  Future<List<int>?> readCharacteristic(
    String serviceUuid,
    String charUuid,
  ) async {
    final char = _findCharacteristic(serviceUuid, charUuid);
    if (char == null) return null;

    try {
      final value = await char.read();
      AppLogger.ble('Read ${charUuid.substring(0, 8)}... → $value');
      return value;
    } catch (e) {
      AppLogger.ble('Read failed for $charUuid', error: e);
      return null;
    }
  }

  // ── Write Characteristic ──────────────────────────────────────────────────

  /// Write bytes to a characteristic.
  /// Returns [true] if write succeeded.
  Future<bool> writeCharacteristic(
    String serviceUuid,
    String charUuid,
    List<int> data,
  ) async {
    final char = _findCharacteristic(serviceUuid, charUuid);
    if (char == null) return false;

    try {
      // Prefer write-without-response for low-latency cue commands
      await char.write(data, withoutResponse: char.properties.writeWithoutResponse);
      AppLogger.ble('Wrote to ${charUuid.substring(0, 8)}... → $data');
      return true;
    } catch (e) {
      AppLogger.ble('Write failed for $charUuid', error: e);
      return false;
    }
  }

  // ── Subscribe to Notifications ────────────────────────────────────────────

  /// Subscribe to BLE notifications on a characteristic.
  /// Returns a [Stream<List<int>>] that emits every time the device notifies.
  Stream<List<int>> subscribeToNotifications(
    String serviceUuid,
    String charUuid,
  ) {
    final char = _findCharacteristic(serviceUuid, charUuid);
    if (char == null) {
      AppLogger.ble('Cannot subscribe: char $charUuid not found');
      return const Stream.empty();
    }

    if (!char.properties.notify && !char.properties.indicate) {
      AppLogger.ble('Characteristic $charUuid does not support notifications');
      return const Stream.empty();
    }

    AppLogger.ble('Subscribing to notifications: ${charUuid.substring(0, 8)}...');

    // Enable notifications on the device
    char.setNotifyValue(true).catchError((Object e) {
      AppLogger.ble('setNotifyValue failed', error: e);
      return false;
    });

    return char.onValueReceived;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Find a [BluetoothCharacteristic] by service and char UUID (case-insensitive).
  BluetoothCharacteristic? _findCharacteristic(
    String serviceUuid,
    String charUuid,
  ) {
    final normalizedSvcUuid = serviceUuid.toLowerCase();
    final normalizedCharUuid = charUuid.toLowerCase();

    final service = _serviceCache[normalizedSvcUuid];
    if (service == null) {
      AppLogger.ble('Service $serviceUuid not found in cache');
      return null;
    }

    try {
      return service.characteristics.firstWhere(
        (c) => c.uuid.str.toLowerCase() == normalizedCharUuid,
      );
    } catch (_) {
      AppLogger.ble('Characteristic $charUuid not found in service $serviceUuid');
      return null;
    }
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  void dispose() {
    _serviceCache.clear();
    _device = null;
  }
}
