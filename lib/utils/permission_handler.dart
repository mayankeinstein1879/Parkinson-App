import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:parkinson_insole_app/utils/logger.dart';

/// Handles all BLE and location runtime permissions.
///
/// Android 12+ (API 31+) requires BLUETOOTH_SCAN and BLUETOOTH_CONNECT.
/// Android <12 requires ACCESS_FINE_LOCATION for BLE scanning.
/// Web: permissions are handled natively by the browser — skip all requests.
class BlePermissionHandler {
  BlePermissionHandler._();

  // ── Main Entry Point ──────────────────────────────────────────────────────

  /// Request all permissions needed for BLE operation.
  /// Returns [true] if all required permissions are granted.
  static Future<bool> requestAllRequiredPermissions(BuildContext context) async {
    // Web uses the browser's native BLE permission dialog — no app-level request needed
    if (kIsWeb) {
      AppLogger.ble('Web platform — skipping permission_handler (browser handles BLE permissions)');
      return true;
    }

    AppLogger.ble('Requesting BLE permissions');

    final btGranted = await requestBlePermissions();
    if (!btGranted) {
      AppLogger.ble('Bluetooth permissions denied');
      return false;
    }

    final locGranted = await requestLocationPermission();
    if (!locGranted) {
      AppLogger.ble('Location permission denied (needed for BLE scan on Android <12)');
      // Not fatal on Android 12+ — still continue
    }

    return btGranted;
  }

  // ── Bluetooth Permissions ─────────────────────────────────────────────────

  static Future<bool> checkBlePermissions() async {
    if (kIsWeb) return true;
    // Android 12+ specific permissions
    final scan    = await Permission.bluetoothScan.status;
    final connect = await Permission.bluetoothConnect.status;
    return scan.isGranted && connect.isGranted;
  }

  static Future<bool> requestBlePermissions() async {
    if (kIsWeb) return true;

    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetooth,
    ].request();

    final allGranted = statuses.values
        .every((s) => s.isGranted || s.isLimited);

    AppLogger.ble(
      'BLE permission results: '
      'scan=${statuses[Permission.bluetoothScan]?.name}, '
      'connect=${statuses[Permission.bluetoothConnect]?.name}',
    );

    return allGranted;
  }

  // ── Location Permission ───────────────────────────────────────────────────

  static Future<bool> checkLocationPermission() async {
    if (kIsWeb) return true;
    final status = await Permission.locationWhenInUse.status;
    return status.isGranted;
  }

  static Future<bool> requestLocationPermission() async {
    if (kIsWeb) return true;
    final status = await Permission.locationWhenInUse.request();
    AppLogger.ble('Location permission: ${status.name}');
    return status.isGranted || status.isLimited;
  }

  // ── Bluetooth Adaptor ─────────────────────────────────────────────────────

  /// Check if the device's Bluetooth adaptor is turned on.
  static Future<bool> isBluetoothEnabled() async {
    if (kIsWeb) return true; // Web BLE availability is checked at scan time
    final adapterState = await FlutterBluePlus.adapterState.first;
    return adapterState == BluetoothAdapterState.on;
  }

  /// Show a dialog prompting the user to enable Bluetooth.
  static Future<void> promptEnableBluetooth(BuildContext context) async {
    if (kIsWeb || !context.mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bluetooth Required'),
        content: const Text(
          'Please enable Bluetooth to connect to your insoles.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // On Android, this opens Bluetooth settings
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // ── Convenience getter ────────────────────────────────────────────────────

  /// Human-readable status string for the current permission state.
  static Future<String> get statusMessage async {
    if (kIsWeb) return 'Web — browser handles BLE permissions';
    final btOk  = await checkBlePermissions();
    final locOk = await checkLocationPermission();
    final bleOn = await isBluetoothEnabled();

    if (!bleOn) return 'Bluetooth is off';
    if (!btOk)  return 'Bluetooth permission not granted';
    if (!locOk) return 'Location permission not granted';
    return 'All permissions granted';
  }
}
