import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:parkinson_insole_app/models/cue_settings.dart';
import 'package:parkinson_insole_app/models/insole_device.dart';
import 'package:parkinson_insole_app/services/ble/ble_manager.dart';
import 'package:parkinson_insole_app/utils/logger.dart';

/// BleProvider — State management layer for all BLE operations.
///
/// Consumed by widgets via [Consumer<BleProvider>] or [context.watch<BleProvider>()].
/// Holds a reference to the abstract [BleManager] — meaning it works with
/// both the real [Esp32BleManager] and the [MockBleService] transparently.
class BleProvider extends ChangeNotifier {
  // ── Dependencies ──────────────────────────────────────────────────────────
  final BleManager _bleManager;

  BleProvider(this._bleManager) {
    _init();
  }

  // ── State ─────────────────────────────────────────────────────────────────
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  List<InsoleDevice> _scanResults    = [];
  InsoleDevice? _connectedDeviceLeft;
  InsoleDevice? _connectedDeviceRight;
  bool _isScanning               = false;
  bool _autoReconnectEnabled     = true;
  String? _errorMessage;
  int? _rssi;

  StreamSubscription<List<InsoleDevice>>? _scanSub;
  StreamSubscription<ConnectionStatus>?   _statusSub;

  // ── Getters ───────────────────────────────────────────────────────────────
  ConnectionStatus   get connectionStatus      => _connectionStatus;
  List<InsoleDevice> get scanResults           => List.unmodifiable(_scanResults);
  InsoleDevice?      get connectedDeviceLeft   => _connectedDeviceLeft;
  InsoleDevice?      get connectedDeviceRight  => _connectedDeviceRight;
  bool               get isScanning            => _isScanning;
  bool               get autoReconnectEnabled  => _autoReconnectEnabled;
  String?            get errorMessage          => _errorMessage;
  int?               get rssi                  => _rssi;
  bool               get isConnected           =>
      _connectionStatus == ConnectionStatus.connected;
  bool               get hasAnyDeviceConnected =>
      _connectedDeviceLeft != null || _connectedDeviceRight != null;

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> _init() async {
    await _bleManager.initialize();

    // Listen to scan results
    _scanSub = _bleManager.scanResultsStream.listen((devices) {
      _scanResults = devices;
      _isScanning  = _bleManager.isScanning;
      _clearError();
      notifyListeners();
    });

    // Listen to connection status changes
    _statusSub = _bleManager.connectionStatusStream.listen((status) {
      _connectionStatus = status;

      if (status == ConnectionStatus.connected) {
        final dev = _bleManager.connectedDevice;
        if (dev != null) {
          if (dev.isLeft)  _connectedDeviceLeft  = dev;
          if (dev.isRight) _connectedDeviceRight = dev;
        }
        _clearError();
      } else if (status == ConnectionStatus.error) {
        _setError('Connection failed. Please retry.');
      } else if (status == ConnectionStatus.disconnected) {
        _connectedDeviceLeft  = null;
        _connectedDeviceRight = null;
        _clearError();
      }

      _isScanning = _bleManager.isScanning;
      notifyListeners();
    });
  }

  // ── Scanning ──────────────────────────────────────────────────────────────

  Future<void> startScan() async {
    _scanResults = [];
    _clearError();
    _isScanning = true;
    notifyListeners();

    try {
      await _bleManager.startScan();
    } catch (e) {
      _setError('Scan failed: $e');
      _isScanning = false;
      notifyListeners();
      AppLogger.ble('startScan error', error: e);
    }
  }

  Future<void> stopScan() async {
    await _bleManager.stopScan();
    _isScanning = false;
    notifyListeners();
  }

  // ── Connection ────────────────────────────────────────────────────────────

  Future<void> connectToDevice(InsoleDevice device) async {
    _clearError();
    _connectionStatus = ConnectionStatus.connecting;
    notifyListeners();

    try {
      final success = await _bleManager.connectToDevice(device);
      if (!success) {
        _setError('Could not connect to ${device.displayName}');
      }
    } catch (e) {
      _setError('Connection error: $e');
      AppLogger.ble('connectToDevice error', error: e);
    }
    notifyListeners();
  }

  Future<void> disconnect() async {
    try {
      await _bleManager.disconnect();
    } catch (e) {
      AppLogger.error('Failed to disconnect cleanly', e, null);
    } finally {
      _connectedDeviceLeft  = null;
      _connectedDeviceRight = null;
      _connectionStatus     = ConnectionStatus.disconnected;
      notifyListeners();
    }
  }

  Future<void> reconnectDeviceOfSide(InsoleSide side) async {
    _clearError();
    _isScanning = true;
    notifyListeners();

    try {
      final completer = Completer<InsoleDevice?>();
      
      StreamSubscription<List<InsoleDevice>>? tempSub;
      tempSub = _bleManager.scanResultsStream.listen((devices) {
        for (final device in devices) {
          if (device.side == side) {
            if (!completer.isCompleted) {
              completer.complete(device);
            }
            break;
          }
        }
      });

      // Start the scan
      await _bleManager.startScan();

      // Wait for matching device or timeout (e.g. 15 seconds)
      final device = await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => null,
      );

      await tempSub.cancel();
      await _bleManager.stopScan();
      _isScanning = false;
      notifyListeners();

      if (device != null) {
        // Connect to it!
        await connectToDevice(device);
      } else {
        _setError('No device found for ${side == InsoleSide.left ? "Left" : "Right"} insole.');
      }
    } catch (e) {
      _setError('Reconnect error: $e');
      _isScanning = false;
      notifyListeners();
    }
  }

  // ── Auto-Reconnect ────────────────────────────────────────────────────────

  Future<void> toggleAutoReconnect() async {
    _autoReconnectEnabled = !_autoReconnectEnabled;
    await _bleManager.enableAutoReconnect(_autoReconnectEnabled);
    notifyListeners();
  }

  // ── Cue Command ───────────────────────────────────────────────────────────

  Future<void> sendCueCommand(CueSettings settings) async {
    final success = await _bleManager.sendCueCommand(settings);
    if (!success) {
      AppLogger.ble('Failed to send cue command');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _setError(String message) {
    _errorMessage     = message;
    _connectionStatus = ConnectionStatus.error;
  }

  void _clearError() {
    _errorMessage = null;
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  Future<void> dispose() async {
    await _scanSub?.cancel();
    await _statusSub?.cancel();
    await _bleManager.dispose();
    super.dispose();
  }
}
