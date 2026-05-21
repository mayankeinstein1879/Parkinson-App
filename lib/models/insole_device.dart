/// Represents a BLE-connected insole device (left or right).
/// Hardware-agnostic: works with ESP32 now, STM32WB55 in the future.

// ── Enums ─────────────────────────────────────────────────────────────────

/// Which foot the insole belongs to
enum InsoleSide { left, right, unknown }

/// All possible BLE connection lifecycle states
enum ConnectionStatus {
  disconnected,
  scanning,
  connecting,
  connected,
  reconnecting,
  error,
}

// ── InsoleDevice Model ─────────────────────────────────────────────────────

/// Represents a discovered or connected BLE insole device.
class InsoleDevice {
  final String id;          // BLE device ID (MAC address or platform ID)
  final String name;        // Advertised device name
  final InsoleSide side;    // Detected from device name
  ConnectionStatus status;  // Current connection state
  int? rssi;                // Signal strength in dBm (null if unknown)
  DateTime? lastSeen;       // Last time device was seen during scan
  int reconnectAttempts;    // How many reconnect tries have been made

  InsoleDevice({
    required this.id,
    required this.name,
    required this.side,
    this.status = ConnectionStatus.disconnected,
    this.rssi,
    this.lastSeen,
    this.reconnectAttempts = 0,
  });

  // ── Computed Properties ──────────────────────────────────────────────────

  bool get isConnected => status == ConnectionStatus.connected;
  bool get isConnecting => status == ConnectionStatus.connecting;
  bool get isScanning => status == ConnectionStatus.scanning;
  bool get isReconnecting => status == ConnectionStatus.reconnecting;
  bool get hasError => status == ConnectionStatus.error;
  bool get isLeft => side == InsoleSide.left;
  bool get isRight => side == InsoleSide.right;

  /// Human-readable display name (e.g., "Left Insole")
  String get displayName {
    switch (side) {
      case InsoleSide.left:  return 'Left Insole';
      case InsoleSide.right: return 'Right Insole';
      case InsoleSide.unknown: return name;
    }
  }

  /// Short side label ("L" or "R")
  String get sideLabel {
    switch (side) {
      case InsoleSide.left:  return 'L';
      case InsoleSide.right: return 'R';
      case InsoleSide.unknown: return '?';
    }
  }

  /// Human-readable connection status label
  String get statusLabel {
    switch (status) {
      case ConnectionStatus.disconnected:  return 'Disconnected';
      case ConnectionStatus.scanning:      return 'Scanning...';
      case ConnectionStatus.connecting:    return 'Connecting...';
      case ConnectionStatus.connected:     return 'Connected';
      case ConnectionStatus.reconnecting:  return 'Reconnecting...';
      case ConnectionStatus.error:         return 'Error';
    }
  }

  /// Signal strength bar count (0–4) based on RSSI
  int get rssiStrength {
    final r = rssi;
    if (r == null) return 0;
    if (r >= -60) return 4; // Excellent
    if (r >= -70) return 3; // Good
    if (r >= -80) return 2; // Fair
    if (r >= -90) return 1; // Weak
    return 0;               // Very weak
  }

  // ── Detect side from device name ─────────────────────────────────────────

  /// Automatically detect insole side from the BLE device name.
  /// The ESP32 is expected to advertise as 'Parkinson_L_Insole' or 'Parkinson_R_Insole'.
  static InsoleSide detectSide(String deviceName) {
    final lower = deviceName.toLowerCase();
    if (lower.contains('_l') || lower.contains('left')) {
      return InsoleSide.left;
    } else if (lower.contains('_r') || lower.contains('right')) {
      return InsoleSide.right;
    }
    return InsoleSide.unknown;
  }

  // ── copyWith ─────────────────────────────────────────────────────────────

  InsoleDevice copyWith({
    String? id,
    String? name,
    InsoleSide? side,
    ConnectionStatus? status,
    int? rssi,
    DateTime? lastSeen,
    int? reconnectAttempts,
  }) {
    return InsoleDevice(
      id:                 id                ?? this.id,
      name:               name              ?? this.name,
      side:               side              ?? this.side,
      status:             status            ?? this.status,
      rssi:               rssi              ?? this.rssi,
      lastSeen:           lastSeen          ?? this.lastSeen,
      reconnectAttempts:  reconnectAttempts ?? this.reconnectAttempts,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InsoleDevice && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'InsoleDevice(id: $id, name: $name, side: $side, status: $status, rssi: $rssi)';
}
