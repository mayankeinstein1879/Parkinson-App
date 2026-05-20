import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:parkinson_insole_app/constants/ble_constants.dart';
import 'package:parkinson_insole_app/models/insole_device.dart';
import 'package:parkinson_insole_app/utils/logger.dart';

/// Manages the BLE connection lifecycle for a single insole device.
///
/// Handles:
/// - connect / disconnect
/// - connection state monitoring
/// - auto-reconnect with exponential backoff
/// - emitting [ConnectionStatus] events to listeners
class BleConnection {
  // ── State ─────────────────────────────────────────────────────────────────
  BluetoothDevice? _device;
  StreamSubscription<BluetoothConnectionState>? _stateSub;
  Timer? _reconnectTimer;

  bool _autoReconnectEnabled = true;
  int  _reconnectAttempts    = 0;
  bool _intentionalDisconnect = false;

  final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();

  InsoleDevice? _connectedInsole;

  // ── Public API ────────────────────────────────────────────────────────────

  Stream<ConnectionStatus> get statusStream => _statusController.stream;
  InsoleDevice? get connectedInsole => _connectedInsole;
  bool get isConnected => _device != null &&
      _device!.isConnected;

  set autoReconnectEnabled(bool value) {
    _autoReconnectEnabled = value;
    AppLogger.ble('Auto-reconnect: ${value ? "ON" : "OFF"}');
  }

  // ── Connect ───────────────────────────────────────────────────────────────

  /// Connect to the given [InsoleDevice].
  /// Returns [true] if connection succeeds within timeout.
  Future<bool> connect(InsoleDevice insole) async {
    _intentionalDisconnect = false;
    _reconnectAttempts = 0;

    AppLogger.ble('Connecting to ${insole.displayName} (${insole.id})');
    _emit(ConnectionStatus.connecting);

    try {
      // Locate the BluetoothDevice from flutter_blue_plus
      final btDevice = BluetoothDevice.fromId(insole.id);
      _device = btDevice;

      // Listen for connection state changes from the OS
      _stateSub?.cancel();
      _stateSub = btDevice.connectionState.listen(_onConnectionStateChange);

      // Attempt connection with timeout
      await btDevice.connect(
        timeout: BleConstants.connectTimeout,
        autoConnect: false,
      );

      // Request larger MTU for bigger telemetry packets
      await _requestMtu(btDevice);

      _connectedInsole = insole.copyWith(status: ConnectionStatus.connected);
      _emit(ConnectionStatus.connected);
      AppLogger.ble('Connected to ${insole.displayName}');
      return true;

    } catch (e) {
      AppLogger.ble('Connection failed: $e', error: e);
      _emit(ConnectionStatus.error);
      return false;
    }
  }

  // ── Disconnect ────────────────────────────────────────────────────────────

  /// Intentionally disconnect from the current device.
  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    _cancelReconnectTimer();
    AppLogger.ble('Intentionally disconnecting');

    try {
      await _device?.disconnect();
    } catch (e) {
      AppLogger.ble('Disconnect error', error: e);
    } finally {
      _device = null;
      _connectedInsole = null;
      _emit(ConnectionStatus.disconnected);
    }
  }

  // ── Connection State Handler ──────────────────────────────────────────────

  void _onConnectionStateChange(BluetoothConnectionState state) {
    AppLogger.ble('BLE state change → $state');

    switch (state) {
      case BluetoothConnectionState.connected:
        _reconnectAttempts = 0;
        _emit(ConnectionStatus.connected);
        break;

      case BluetoothConnectionState.disconnected:
        if (_intentionalDisconnect) {
          _emit(ConnectionStatus.disconnected);
        } else {
          // Unexpected disconnect — try auto-reconnect
          _handleUnexpectedDisconnect();
        }
        break;

      default:
        break;
    }
  }

  void _handleUnexpectedDisconnect() {
    AppLogger.ble('Unexpected disconnect detected');

    if (!_autoReconnectEnabled ||
        _reconnectAttempts >= BleConstants.maxReconnectAttempts) {
      AppLogger.ble('Max reconnect attempts reached or auto-reconnect disabled');
      _emit(ConnectionStatus.error);
      return;
    }

    _emit(ConnectionStatus.reconnecting);

    // Exponential backoff: 3s, 6s, 12s, 24s, 48s
    final delay = BleConstants.reconnectDelay * (1 << _reconnectAttempts);
    _reconnectAttempts++;

    AppLogger.ble(
      'Reconnect attempt $_reconnectAttempts/${BleConstants.maxReconnectAttempts} '
      'in ${delay.inSeconds}s',
    );

    _reconnectTimer = Timer(delay, () async {
      if (_connectedInsole != null && !_intentionalDisconnect) {
        final success = await connect(_connectedInsole!);
        if (!success) _handleUnexpectedDisconnect();
      }
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _requestMtu(BluetoothDevice device) async {
    try {
      await device.requestMtu(BleConstants.mtuSize);
      AppLogger.ble('MTU negotiated: ${BleConstants.mtuSize}');
    } catch (e) {
      AppLogger.ble('MTU negotiation failed (will use default)', error: e);
    }
  }

  void _emit(ConnectionStatus status) {
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    _intentionalDisconnect = true;
    _cancelReconnectTimer();
    await _stateSub?.cancel();
    await _statusController.close();
  }
}
