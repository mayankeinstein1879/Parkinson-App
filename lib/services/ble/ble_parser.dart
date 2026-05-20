import 'dart:typed_data';
import 'package:parkinson_insole_app/constants/ble_constants.dart';
import 'package:parkinson_insole_app/models/cue_settings.dart';
import 'package:parkinson_insole_app/models/insole_device.dart';
import 'package:parkinson_insole_app/models/telemetry_data.dart';
import 'package:parkinson_insole_app/utils/logger.dart';

/// Converts raw BLE byte packets → typed [TelemetryData] objects.
///
/// Packet Format (Combined Telemetry — 20 bytes):
/// ┌────────┬──────────┬─────────────┬──────────────┬──────────┬──────────────────────┐
/// │ Byte 0 │ Bytes 1-8│ Byte 9      │ Byte 10      │Bytes11-12│ Byte 13              │
/// │ type   │ pressure │ gaitStab(%) │ fogRisk(%)   │ cadence  │ asymmetry(%)         │
/// ├────────┼──────────┼─────────────┼──────────────┼──────────┼──────────────────────┤
/// │ Byte 14│ Byte 15  │ Byte 16     │ Byte 17      │Bytes18-19│                      │
/// │confid% │ battery% │ cueActive   │ reserved     │ padding  │                      │
/// └────────┴──────────┴─────────────┴──────────────┴──────────┴──────────────────────┘
///
/// Pressure bytes 1-8: 4 × uint16 big-endian, scaled by [BleConstants.pressureScaleFactor]
/// Cadence bytes 11-12: uint16 big-endian, scaled by [BleConstants.cadenceScaleFactor]
///
/// This format is intentionally extensible — add more packet types as needed.
class BleParser {

  // ── Public API ────────────────────────────────────────────────────────────

  /// Parse a raw BLE byte packet into [TelemetryData].
  /// Returns [null] if the packet is invalid or too short.
  TelemetryData? parseTelemetryPacket(List<int> bytes, InsoleSide side) {
    if (bytes.isEmpty) return null;

    final packetType = bytes[0];

    switch (packetType) {
      case BleConstants.packetTypeCombined:
        return _parseCombinedPacket(bytes, side);
      case BleConstants.packetTypePressure:
        return _parsePressureOnlyPacket(bytes, side);
      case BleConstants.packetTypeGait:
        return _parseGaitOnlyPacket(bytes, side);
      case BleConstants.packetTypeBattery:
        // Battery-only packet — not full telemetry, return null
        AppLogger.ble('Battery-only packet received');
        return null;
      default:
        AppLogger.ble('Unknown packet type: 0x${packetType.toRadixString(16)}');
        return null;
    }
  }

  /// Parse battery level from a battery packet.
  /// Returns battery percentage (0–100), or -1 if invalid.
  int parseBatteryData(List<int> bytes) {
    if (bytes.length < 2) return -1;
    return bytes[1].clamp(0, 100);
  }

  /// Build a BLE write command from [CueSettings].
  List<int> buildCueCommand(CueSettings settings) {
    return settings.toBleCommand();
  }

  // ── Combined Packet (main path) ───────────────────────────────────────────

  TelemetryData? _parseCombinedPacket(List<int> bytes, InsoleSide side) {
    if (bytes.length < BleConstants.combinedPacketSize) {
      AppLogger.ble(
        'Combined packet too short: ${bytes.length}/${BleConstants.combinedPacketSize}');
      return null;
    }

    try {
      final pressure   = _extractPressure(bytes, offset: 1);
      final stability  = bytes[9].toDouble().clamp(0, 100);
      final fogRisk    = bytes[10].toDouble().clamp(0, 100);
      final cadence    = _readUint16BE(bytes, 11) / BleConstants.cadenceScaleFactor;
      final asymmetry  = bytes[13].toDouble().clamp(0, 100);
      final confidence = bytes[14].toDouble().clamp(0, 100);
      final battery    = bytes[15].clamp(0, 100);
      final cueActive  = bytes[16] != 0;

      return TelemetryData(
        timestamp:         DateTime.now(),
        side:              side,
        pressure:          pressure,
        gaitStability:     stability,
        fogRisk:           fogRisk,
        stepCadence:       cadence,
        gaitAsymmetry:     asymmetry,
        batteryLevel:      battery,
        cueActive:         cueActive,
        walkingConfidence: confidence,
      );
    } catch (e) {
      AppLogger.ble('Combined packet parse error', error: e);
      return null;
    }
  }

  // ── Pressure-only packet ──────────────────────────────────────────────────

  TelemetryData? _parsePressureOnlyPacket(List<int> bytes, InsoleSide side) {
    if (bytes.length < BleConstants.pressurePacketSize) return null;
    final pressure = _extractPressure(bytes, offset: 1);

    // Return partial telemetry — other fields stay at defaults
    return TelemetryData(
      timestamp:         DateTime.now(),
      side:              side,
      pressure:          pressure,
      gaitStability:     0,
      fogRisk:           0,
      stepCadence:       0,
      gaitAsymmetry:     0,
      batteryLevel:      0,
      cueActive:         false,
      walkingConfidence: 0,
    );
  }

  // ── Gait-only packet ──────────────────────────────────────────────────────

  TelemetryData? _parseGaitOnlyPacket(List<int> bytes, InsoleSide side) {
    if (bytes.length < BleConstants.gaitPacketSize) return null;

    return TelemetryData(
      timestamp:         DateTime.now(),
      side:              side,
      pressure:          PressureZone.zero(),
      gaitStability:     bytes[1].toDouble().clamp(0, 100),
      fogRisk:           bytes[2].toDouble().clamp(0, 100),
      stepCadence:       _readUint16BE(bytes, 3) / BleConstants.cadenceScaleFactor,
      gaitAsymmetry:     bytes[5].toDouble().clamp(0, 100),
      batteryLevel:      0,
      cueActive:         bytes[6] != 0,
      walkingConfidence: 0,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Extract 4 pressure zones from 8 bytes (4 × uint16 big-endian) at [offset].
  PressureZone _extractPressure(List<int> bytes, {required int offset}) {
    return PressureZone(
      heel:     _readUint16BE(bytes, offset + 0) / BleConstants.pressureScaleFactor,
      midfoot:  _readUint16BE(bytes, offset + 2) / BleConstants.pressureScaleFactor,
      forefoot: _readUint16BE(bytes, offset + 4) / BleConstants.pressureScaleFactor,
      toe:      _readUint16BE(bytes, offset + 6) / BleConstants.pressureScaleFactor,
    );
  }

  /// Read a uint16 big-endian value from [bytes] starting at [index].
  double _readUint16BE(List<int> bytes, int index) {
    if (index + 1 >= bytes.length) return 0;
    return ((bytes[index] << 8) | bytes[index + 1]).toDouble();
  }
}
