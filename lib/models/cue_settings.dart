import 'dart:convert';
import 'dart:math' as math;

// ── Enums ──────────────────────────────────────────────────────────────────

/// When the adaptive cueing system activates
enum CueMode {
  auto,   // Triggers automatically based on FOG risk score
  manual, // Only triggers when user presses the cue button
  off,    // Cueing completely disabled
}

/// The timing/rhythm pattern of the cue signal
enum CuePattern {
  rhythmic,  // Regular steady beat — most common for Parkinson's
  adaptive,  // Beat adjusts to patient's current cadence
  burst,     // Short rapid pulses — for severe FOG episodes
}

// ── CueSettings Model ──────────────────────────────────────────────────────

/// Stores all adaptive cueing preferences.
/// Persisted to SharedPreferences via toJson/fromJson.
class CueSettings {
  bool visualCueEnabled;   // Laser projection cue
  bool hapticCueEnabled;   // LRA vibration motor cue
  bool audioCueEnabled;    // Rhythmic audio tone cue
  double visualIntensity;  // 0.0 – 1.0
  double hapticIntensity;  // 0.0 – 1.0
  double audioVolume;      // 0.0 – 1.0
  CueMode mode;            // auto / manual / off
  CuePattern pattern;      // rhythmic / adaptive / burst
  bool syncLeftRight;      // Keep left/right insole cues in sync

  CueSettings({
    required this.visualCueEnabled,
    required this.hapticCueEnabled,
    required this.audioCueEnabled,
    required this.visualIntensity,
    required this.hapticIntensity,
    required this.audioVolume,
    required this.mode,
    required this.pattern,
    required this.syncLeftRight,
  });

  /// Sensible defaults for a new user
  factory CueSettings.defaults() => CueSettings(
    visualCueEnabled: true,
    hapticCueEnabled: true,
    audioCueEnabled:  false,
    visualIntensity:  0.7,
    hapticIntensity:  0.8,
    audioVolume:      0.5,
    mode:             CueMode.auto,
    pattern:          CuePattern.rhythmic,
    syncLeftRight:    true,
  );

  // ── copyWith ──────────────────────────────────────────────────────────────

  CueSettings copyWith({
    bool?        visualCueEnabled,
    bool?        hapticCueEnabled,
    bool?        audioCueEnabled,
    double?      visualIntensity,
    double?      hapticIntensity,
    double?      audioVolume,
    CueMode?     mode,
    CuePattern?  pattern,
    bool?        syncLeftRight,
  }) {
    return CueSettings(
      visualCueEnabled: visualCueEnabled ?? this.visualCueEnabled,
      hapticCueEnabled: hapticCueEnabled ?? this.hapticCueEnabled,
      audioCueEnabled:  audioCueEnabled  ?? this.audioCueEnabled,
      visualIntensity:  visualIntensity  ?? this.visualIntensity,
      hapticIntensity:  hapticIntensity  ?? this.hapticIntensity,
      audioVolume:      audioVolume      ?? this.audioVolume,
      mode:             mode             ?? this.mode,
      pattern:          pattern          ?? this.pattern,
      syncLeftRight:    syncLeftRight    ?? this.syncLeftRight,
    );
  }

  // ── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'visualCueEnabled': visualCueEnabled,
    'hapticCueEnabled': hapticCueEnabled,
    'audioCueEnabled':  audioCueEnabled,
    'visualIntensity':  visualIntensity,
    'hapticIntensity':  hapticIntensity,
    'audioVolume':      audioVolume,
    'mode':             mode.name,
    'pattern':          pattern.name,
    'syncLeftRight':    syncLeftRight,
  };

  factory CueSettings.fromJson(Map<String, dynamic> json) => CueSettings(
    visualCueEnabled: json['visualCueEnabled'] as bool? ?? true,
    hapticCueEnabled: json['hapticCueEnabled'] as bool? ?? true,
    audioCueEnabled:  json['audioCueEnabled']  as bool? ?? false,
    visualIntensity:  (json['visualIntensity'] as num?)?.toDouble() ?? 0.7,
    hapticIntensity:  (json['hapticIntensity'] as num?)?.toDouble() ?? 0.8,
    audioVolume:      (json['audioVolume']      as num?)?.toDouble() ?? 0.5,
    mode:    CueMode.values.firstWhere(
                 (e) => e.name == json['mode'], orElse: () => CueMode.auto),
    pattern: CuePattern.values.firstWhere(
                 (e) => e.name == json['pattern'], orElse: () => CuePattern.rhythmic),
    syncLeftRight: json['syncLeftRight'] as bool? ?? true,
  );

  /// Encode to JSON string for SharedPreferences storage
  String toJsonString() => jsonEncode(toJson());

  factory CueSettings.fromJsonString(String jsonStr) =>
      CueSettings.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);

  // ── BLE Command Bytes ─────────────────────────────────────────────────────

  /// Build the 3-byte command to send over BLE to the insole.
  /// Byte 0: visual intensity (0–255)
  /// Byte 1: haptic intensity (0–255)
  /// Byte 2: audio volume (0–255)
  List<int> toBleCommand() {
    return [
      visualCueEnabled ? (visualIntensity * 255).round() : 0,
      hapticCueEnabled ? (hapticIntensity * 255).round() : 0,
      audioCueEnabled  ? (audioVolume     * 255).round() : 0,
    ];
  }

  @override
  String toString() =>
      'CueSettings(visual:$visualCueEnabled, haptic:$hapticCueEnabled, '
      'audio:$audioCueEnabled, mode:${mode.name})';
}
