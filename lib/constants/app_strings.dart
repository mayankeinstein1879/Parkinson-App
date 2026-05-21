/// All user-facing strings, labels, and messages for the Parkinson's Insole App.
/// Centralizing strings makes localization easy in the future.
class AppStrings {
  AppStrings._();

  // ── App Identity ──────────────────────────────────────────────────────────
  static const String appName        = 'NeuroPark';
  static const String appTagline     = 'AI-Assisted Gait Monitoring & Adaptive Cueing';
  static const String appVersion     = 'v0.1.0 (Beta)';
  static const String appPackage     = 'com.parkinsonsai.parkinson_insole_app';

  // ── Screen Titles ─────────────────────────────────────────────────────────
  static const String titleSplash       = 'NeuroPark';
  static const String titleScan         = 'Find Insoles';
  static const String titleConnect      = 'Connecting';
  static const String titleDashboard    = 'Dashboard';
  static const String titleStatus       = 'Device Status';
  static const String titleSettings     = 'Settings';
  static const String titleDebug        = 'Developer Console';

  // ── BLE Messages ──────────────────────────────────────────────────────────
  static const String bleScanning         = 'Scanning for insoles...';
  static const String bleScanComplete     = 'Scan complete';
  static const String bleConnecting       = 'Establishing BLE connection...';
  static const String bleConnected        = 'Connected';
  static const String bleDisconnected     = 'Disconnected';
  static const String bleReconnecting     = 'Reconnecting...';
  static const String bleError            = 'Connection error';
  static const String bleNotFound         = 'No insoles found nearby';
  static const String bleNotFoundHint     = 'Ensure the insole device is powered on and in range.';
  static const String bleConnectedTo      = 'Connected to';
  static const String bleDiscovering      = 'Discovering services...';
  static const String blePairingFailed    = 'Pairing failed. Please retry.';
  static const String blePermissionDenied = 'Bluetooth permission denied';
  static const String bleAdapterOff       = 'Bluetooth is turned off';
  static const String bleEnableBt         = 'Please enable Bluetooth to continue.';
  static const String bleAutoReconnect    = 'Auto-reconnect enabled';
  static const String bleReconnectFailed  = 'Reconnect failed after max attempts';

  // ── Insole Labels ─────────────────────────────────────────────────────────
  static const String leftInsole    = 'Left Insole';
  static const String rightInsole   = 'Right Insole';
  static const String leftShort     = 'L';
  static const String rightShort    = 'R';
  static const String bothInsoles   = 'Both Insoles';

  // ── Telemetry Labels ──────────────────────────────────────────────────────
  static const String gaitStability    = 'Gait Stability';
  static const String fogRisk          = 'FOG Risk';
  static const String stepCadence      = 'Step Cadence';
  static const String gaitAsymmetry    = 'Gait Asymmetry';
  static const String battery          = 'Battery';
  static const String pressure         = 'Pressure';
  static const String heelPressure     = 'Heel';
  static const String midfootPressure  = 'Midfoot';
  static const String forefootPressure = 'Forefoot';
  static const String toePressure      = 'Toe';
  static const String walkingConfidence = 'Walk Confidence';
  static const String rssi             = 'Signal Strength';

  // ── Units ─────────────────────────────────────────────────────────────────
  static const String unitPercent    = '%';
  static const String unitStepsMin   = 'steps/min';
  static const String unitDbm        = 'dBm';
  static const String unitKPa        = 'kPa';
  static const String unitMs         = 'ms';

  // ── FOG Risk Labels ───────────────────────────────────────────────────────
  static const String fogLow        = 'LOW RISK';
  static const String fogModerate   = 'MODERATE';
  static const String fogHigh       = 'HIGH RISK';
  static const String fogCritical   = 'CRITICAL';

  // ── Cue Controls ──────────────────────────────────────────────────────────
  static const String visualCue     = 'Visual Cue';
  static const String hapticCue     = 'Haptic Cue';
  static const String audioCue      = 'Audio Cue';
  static const String visualCueSub  = 'Laser Projection';
  static const String hapticCueSub  = 'LRA Vibration';
  static const String audioCueSub   = 'Rhythmic Tones';
  static const String cueIntensity  = 'Intensity';
  static const String cueMode       = 'Cue Mode';
  static const String cueAuto       = 'Auto';
  static const String cueManual     = 'Manual';
  static const String cueOff        = 'Off';
  static const String cueSync       = 'Sync L+R';
  static const String cuePattern    = 'Sound Pattern';

  // ── Buttons ───────────────────────────────────────────────────────────────
  static const String btnScan       = 'Scan for Insoles';
  static const String btnStopScan   = 'Stop Scanning';
  static const String btnConnect    = 'Connect';
  static const String btnDisconnect = 'Disconnect';
  static const String btnRetry      = 'Retry';
  static const String btnContinue   = 'Continue';
  static const String btnSave       = 'Save Settings';
  static const String btnClearLog   = 'Clear Log';
  static const String btnSOS        = 'SOS';
  static const String btnReconnect  = 'Reconnect';

  // ── Settings ──────────────────────────────────────────────────────────────
  static const String settingsDeveloperMode   = 'Developer Mode';
  static const String settingsMockData        = 'Use Mock Data';
  static const String settingsAutoReconnect   = 'Auto Reconnect';
  static const String settingsNotifications   = 'Notifications';
  static const String settingsTargetDevice    = 'Target Device Name';
  static const String settingsAbout           = 'About';
  static const String settingsGitHub          = 'View on GitHub';
  static const String settingsVersion         = 'App Version';

  // ── Analytics Section ─────────────────────────────────────────────────────
  static const String analyticsTitle       = 'AI Analytics';
  static const String analyticsGaitGraph   = 'Gait Asymmetry Graph';
  static const String analyticsFogTimeline = 'FOG Probability Timeline';
  static const String analyticsPressure    = 'Pressure Distribution';
  static const String analyticsConfidence  = 'Walking Confidence Score';
  static const String analyticsComingSoon  = 'Coming in next update';
  static const String analyticsPlaceholder = 'AI model training in progress...';

  // ── Emergency ─────────────────────────────────────────────────────────────
  static const String emergencyTitle    = 'Emergency & Safety';
  static const String fallDetection     = 'Fall Detection';
  static const String fallMonitoring    = 'Monitoring Active';
  static const String emergencyContact  = 'Emergency Contact';
  static const String caregiverPanel    = 'Caregiver Notification Panel';
  static const String overallHealth     = 'Overall Health Status';

  // ── Errors ────────────────────────────────────────────────────────────────
  static const String errGeneric        = 'Something went wrong. Please try again.';
  static const String errNoInternet     = 'No internet connection.';
  static const String errBleUnavailable = 'Bluetooth is not available on this device.';
  static const String errPermission     = 'Required permissions were not granted.';
  static const String errTimeout        = 'Operation timed out. Please retry.';
  static const String errParseFailure   = 'Data parsing error — invalid packet received.';
}
