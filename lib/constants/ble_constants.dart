import 'dart:core';

/// BLE Configuration Constants for the Parkinson's Smart Insole System.
///
/// Architecture Note:
/// These constants are designed to be hardware-agnostic where possible.
/// Current target: ESP32 (development/testing)
/// Future target:  STM32WB55 (production)
///
/// When migrating to STM32WB55, only the UUIDs and device names below
/// should need updating — the rest of the BLE architecture remains identical.
class BleConstants {
  BleConstants._();

  // ── Target Device Names ───────────────────────────────────────────────────
  // These names must match exactly what the ESP32 advertises over BLE.
  // Update these when switching to STM32WB55 hardware.
  static const String deviceNameLeft  = 'Parkinson_L_Insole';
  static const String deviceNameRight = 'Parkinson_R_Insole';
  static const String deviceNamePrefix = 'Parkinson_'; // For fuzzy matching

  // ── Timing Configuration ──────────────────────────────────────────────────
  static const Duration scanTimeout       = Duration(seconds: 15);
  static const Duration connectTimeout    = Duration(seconds: 10);
  static const Duration reconnectDelay    = Duration(seconds: 3);
  static const Duration notifyDebounce    = Duration(milliseconds: 100);
  static const int maxReconnectAttempts   = 5;

  // ── MTU Configuration ─────────────────────────────────────────────────────
  // Request larger MTU to allow bigger telemetry packets in the future
  static const int mtuSize = 512;
  static const int defaultMtu = 23; // BLE default

  // ── Primary Service UUID ──────────────────────────────────────────────────
  // Main telemetry service — custom 128-bit UUID
  static const String telemetryServiceUuid =
      '12345678-1234-1234-1234-123456789abc';

  // ── Gait & Pressure Service ───────────────────────────────────────────────
  static const String gaitServiceUuid =
      '12345678-1234-1234-1234-123456789abd';

  // ── Battery Service (standard BLE Battery Service) ────────────────────────
  static const String batteryServiceUuid    = '0000180f-0000-1000-8000-00805f9b34fb';
  static const String batteryCharUuid       = '00002a19-0000-1000-8000-00805f9b34fb';

  // ── Telemetry Characteristics (Custom UUIDs) ──────────────────────────────
  // Pressure data — 8 bytes: [heel_hi, heel_lo, mid_hi, mid_lo,
  //                            fore_hi, fore_lo, toe_hi, toe_lo]
  static const String pressureCharUuid =
      'abcdef01-1234-1234-1234-123456789abc';

  // Gait stability — 1 byte: 0–100 percentage
  static const String gaitStabilityCharUuid =
      'abcdef02-1234-1234-1234-123456789abc';

  // Step cadence — 2 bytes uint16 big-endian: steps/min × 10
  static const String cadenceCharUuid =
      'abcdef03-1234-1234-1234-123456789abc';

  // FOG risk score — 1 byte: 0–100 percentage
  static const String fogRiskCharUuid =
      'abcdef04-1234-1234-1234-123456789abc';

  // Gait asymmetry — 1 byte: 0–100 percentage
  static const String asymmetryCharUuid =
      'abcdef05-1234-1234-1234-123456789abc';

  // Walking confidence — 1 byte: 0–100 percentage
  static const String confidenceCharUuid =
      'abcdef06-1234-1234-1234-123456789abc';

  // Adaptive cue control — writable — 3 bytes:
  // [visual_intensity (0–255), haptic_intensity (0–255), audio_volume (0–255)]
  static const String cueControlCharUuid =
      'abcdef07-1234-1234-1234-123456789abc';

  // Combined telemetry notification — all data in one packet for efficiency
  // 20 bytes: [type(1), heel(2), mid(2), fore(2), toe(2),
  //            stability(1), fog(1), cadence(2), asymmetry(1),
  //            confidence(1), battery(1), cue_active(1), padding(3)]
  static const String combinedTelemetryCharUuid =
      'abcdef08-1234-1234-1234-123456789abc';

  // ── Packet Type Identifiers ───────────────────────────────────────────────
  // Byte 0 of any BLE packet identifies its type
  static const int packetTypePressure   = 0x01;
  static const int packetTypeGait       = 0x02;
  static const int packetTypeBattery    = 0x03;
  static const int packetTypeCombined   = 0x04;
  static const int packetTypeAck        = 0x05;
  static const int packetTypeError      = 0xFF;

  // ── Packet Sizes ──────────────────────────────────────────────────────────
  static const int pressurePacketSize  = 9;  // type(1) + 4×uint16(8)
  static const int gaitPacketSize      = 7;  // type(1) + fields(6)
  static const int combinedPacketSize  = 20; // Full combined telemetry

  // ── Scale Factors ─────────────────────────────────────────────────────────
  // Raw values from sensor are scaled — divide by these to get real units
  static const double pressureScaleFactor  = 10.0;  // → kPa
  static const double cadenceScaleFactor   = 10.0;  // → steps/min

  // ── Signal Strength Thresholds ────────────────────────────────────────────
  static const int rssiGood     = -60;  // dBm — strong signal
  static const int rssiWeak     = -80;  // dBm — weak, may drop
  static const int rssiCritical = -95;  // dBm — likely to disconnect
}
