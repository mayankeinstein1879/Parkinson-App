import 'dart:math' as math;
import 'insole_device.dart';

// ── Pressure Zone Model ────────────────────────────────────────────────────

/// Represents pressure readings across 4 foot zones (in kPa).
class PressureZone {
  final double heel;      // Heel zone pressure
  final double midfoot;   // Midfoot arch pressure
  final double forefoot;  // Ball-of-foot pressure
  final double toe;       // Toe zone pressure

  const PressureZone({
    required this.heel,
    required this.midfoot,
    required this.forefoot,
    required this.toe,
  });

  /// Total combined pressure across all zones
  double get total => heel + midfoot + forefoot + toe;

  /// Highest single-zone pressure
  double get max => [heel, midfoot, forefoot, toe].reduce(math.max);

  /// Pressure as normalized percentages (0–1) per zone
  List<double> get normalized {
    if (total == 0) return [0, 0, 0, 0];
    return [heel / total, midfoot / total, forefoot / total, toe / total];
  }

  /// Center of pressure: 0 = heel, 1 = toe (for gait phase detection)
  double get centerOfPressure {
    if (total == 0) return 0.5;
    return (forefoot + toe * 2) / total;
  }

  factory PressureZone.zero() => const PressureZone(
    heel: 0, midfoot: 0, forefoot: 0, toe: 0);

  /// Generate realistic mock pressure for a given gait phase
  factory PressureZone.mock({math.Random? rng}) {
    final r = rng ?? math.Random();
    return PressureZone(
      heel:     20 + r.nextDouble() * 60,
      midfoot:  10 + r.nextDouble() * 30,
      forefoot: 15 + r.nextDouble() * 50,
      toe:       5 + r.nextDouble() * 25,
    );
  }

  PressureZone copyWith({
    double? heel, double? midfoot, double? forefoot, double? toe}) {
    return PressureZone(
      heel:     heel     ?? this.heel,
      midfoot:  midfoot  ?? this.midfoot,
      forefoot: forefoot ?? this.forefoot,
      toe:      toe      ?? this.toe,
    );
  }

  @override
  String toString() =>
      'PressureZone(heel:$heel, mid:$midfoot, fore:$forefoot, toe:$toe)';
}

// ── TelemetryData Model ────────────────────────────────────────────────────

/// Complete telemetry snapshot from one insole at a point in time.
///
/// Designed to be easily extended — future AI model outputs
/// (e.g. stride length, fall prediction confidence) can be added here.
class TelemetryData {
  final DateTime timestamp;
  final InsoleSide side;
  final PressureZone pressure;
  final double gaitStability;    // 0–100 % (higher = more stable)
  final double fogRisk;          // 0–100 % (higher = more risk of freezing)
  final double stepCadence;      // steps/min
  final double gaitAsymmetry;    // 0–100 % (0 = perfectly symmetric)
  final int batteryLevel;        // 0–100 %
  final bool cueActive;          // Is adaptive cue currently firing?
  final double walkingConfidence;// 0–100 % AI walking confidence score

  const TelemetryData({
    required this.timestamp,
    required this.side,
    required this.pressure,
    required this.gaitStability,
    required this.fogRisk,
    required this.stepCadence,
    required this.gaitAsymmetry,
    required this.batteryLevel,
    required this.cueActive,
    required this.walkingConfidence,
  });

  // ── Factories ─────────────────────────────────────────────────────────────

  /// Returns zeroed-out telemetry (used before first real reading)
  factory TelemetryData.empty(InsoleSide side) => TelemetryData(
    timestamp:        DateTime.now(),
    side:             side,
    pressure:         PressureZone.zero(),
    gaitStability:    0,
    fogRisk:          0,
    stepCadence:      0,
    gaitAsymmetry:    0,
    batteryLevel:     0,
    cueActive:        false,
    walkingConfidence:0,
  );

  /// Generates realistic mock data — used during development without hardware.
  factory TelemetryData.mock(InsoleSide side, {math.Random? rng}) {
    final r = rng ?? math.Random();

    // Slightly different baselines for left vs right (realistic asymmetry)
    final isLeft = side == InsoleSide.left;
    final baseStability = isLeft ? 72.0 : 68.0;
    final baseFog       = isLeft ? 18.0 : 22.0;

    return TelemetryData(
      timestamp:    DateTime.now(),
      side:         side,
      pressure:     PressureZone.mock(rng: r),
      gaitStability: (baseStability + (r.nextDouble() - 0.5) * 20)
                        .clamp(0, 100),
      fogRisk:      (baseFog + (r.nextDouble() - 0.5) * 30)
                        .clamp(0, 100),
      stepCadence:  (105 + (r.nextDouble() - 0.5) * 40)
                        .clamp(0, 200),
      gaitAsymmetry:(15  + (r.nextDouble() - 0.5) * 20)
                        .clamp(0, 100),
      batteryLevel: 70 + r.nextInt(25),
      cueActive:    r.nextDouble() < 0.2, // 20% chance cue is active
      walkingConfidence: (78 + (r.nextDouble() - 0.5) * 30)
                        .clamp(0, 100),
    );
  }

  // ── Computed Properties ────────────────────────────────────────────────────

  bool get isFogCritical => fogRisk >= 70;
  bool get isFogModerate => fogRisk >= 30 && fogRisk < 70;
  bool get isStableGait  => gaitStability >= 70;
  bool get isBatteryLow  => batteryLevel <= 20;

  // ── copyWith ──────────────────────────────────────────────────────────────

  TelemetryData copyWith({
    DateTime? timestamp,
    InsoleSide? side,
    PressureZone? pressure,
    double? gaitStability,
    double? fogRisk,
    double? stepCadence,
    double? gaitAsymmetry,
    int? batteryLevel,
    bool? cueActive,
    double? walkingConfidence,
  }) {
    return TelemetryData(
      timestamp:         timestamp         ?? this.timestamp,
      side:              side              ?? this.side,
      pressure:          pressure          ?? this.pressure,
      gaitStability:     gaitStability     ?? this.gaitStability,
      fogRisk:           fogRisk           ?? this.fogRisk,
      stepCadence:       stepCadence       ?? this.stepCadence,
      gaitAsymmetry:     gaitAsymmetry     ?? this.gaitAsymmetry,
      batteryLevel:      batteryLevel      ?? this.batteryLevel,
      cueActive:         cueActive         ?? this.cueActive,
      walkingConfidence: walkingConfidence ?? this.walkingConfidence,
    );
  }

  Map<String, dynamic> toJson() => {
    'timestamp':         timestamp.toIso8601String(),
    'side':              side.name,
    'gaitStability':     gaitStability,
    'fogRisk':           fogRisk,
    'stepCadence':       stepCadence,
    'gaitAsymmetry':     gaitAsymmetry,
    'batteryLevel':      batteryLevel,
    'cueActive':         cueActive,
    'walkingConfidence': walkingConfidence,
    'pressure': {
      'heel':     pressure.heel,
      'midfoot':  pressure.midfoot,
      'forefoot': pressure.forefoot,
      'toe':      pressure.toe,
    },
  };

  @override
  String toString() =>
      'TelemetryData(side:$side, stability:${gaitStability.toStringAsFixed(1)}, '
      'fog:${fogRisk.toStringAsFixed(1)}, cadence:${stepCadence.toStringAsFixed(0)})';
}
