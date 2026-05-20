import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parkinson_insole_app/constants/ble_constants.dart';
import 'package:parkinson_insole_app/models/cue_settings.dart';
import 'package:parkinson_insole_app/utils/logger.dart';

/// Manages user-configurable app settings, persisted via SharedPreferences.
class SettingsProvider extends ChangeNotifier {
  // ── Prefs Keys ────────────────────────────────────────────────────────────
  static const _keyCueSettings      = 'cue_settings';
  static const _keyDevMode           = 'dev_mode';
  static const _keyMockData          = 'mock_data';
  static const _keyNotifications     = 'notifications';
  static const _keyTargetDevice      = 'target_device';
  static const _keyAutoReconnect     = 'auto_reconnect';

  // ── State ─────────────────────────────────────────────────────────────────
  CueSettings _cueSettings        = CueSettings.defaults();
  bool        _isDeveloperMode     = false;
  bool        _useMockData         = true;   // Default ON so app works without hardware
  bool        _notificationsEnabled = true;
  bool        _autoReconnect       = true;
  String      _targetDeviceName    = BleConstants.deviceNamePrefix;

  bool _isLoaded = false;

  // ── Getters ───────────────────────────────────────────────────────────────
  CueSettings get cueSettings         => _cueSettings;
  bool        get isDeveloperMode      => _isDeveloperMode;
  bool        get useMockData          => _useMockData;
  bool        get notificationsEnabled => _notificationsEnabled;
  bool        get autoReconnect        => _autoReconnect;
  String      get targetDeviceName     => _targetDeviceName;
  bool        get isLoaded             => _isLoaded;

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final cueJson = prefs.getString(_keyCueSettings);
      if (cueJson != null) {
        _cueSettings = CueSettings.fromJsonString(cueJson);
      }

      _isDeveloperMode      = prefs.getBool(_keyDevMode)        ?? false;
      _useMockData          = prefs.getBool(_keyMockData)        ?? true;
      _notificationsEnabled = prefs.getBool(_keyNotifications)   ?? true;
      _autoReconnect        = prefs.getBool(_keyAutoReconnect)   ?? true;
      _targetDeviceName     = prefs.getString(_keyTargetDevice)  ?? BleConstants.deviceNamePrefix;

      _isLoaded = true;
      AppLogger.ui('Settings loaded');
      notifyListeners();
    } catch (e) {
      AppLogger.error('Failed to load settings', e, null);
      _isLoaded = true;
      notifyListeners();
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCueSettings,    _cueSettings.toJsonString());
      await prefs.setBool(_keyDevMode,           _isDeveloperMode);
      await prefs.setBool(_keyMockData,          _useMockData);
      await prefs.setBool(_keyNotifications,     _notificationsEnabled);
      await prefs.setBool(_keyAutoReconnect,     _autoReconnect);
      await prefs.setString(_keyTargetDevice,    _targetDeviceName);
    } catch (e) {
      AppLogger.error('Failed to save settings', e, null);
    }
  }

  // ── Update Methods ────────────────────────────────────────────────────────

  Future<void> updateCueSettings(CueSettings settings) async {
    _cueSettings = settings;
    notifyListeners();
    await _save();
  }

  Future<void> toggleDeveloperMode() async {
    _isDeveloperMode = !_isDeveloperMode;
    notifyListeners();
    await _save();
    AppLogger.ui('Developer mode: $_isDeveloperMode');
  }

  Future<void> toggleMockData() async {
    _useMockData = !_useMockData;
    notifyListeners();
    await _save();
    AppLogger.ui('Mock data: $_useMockData');
  }

  Future<void> toggleNotifications() async {
    _notificationsEnabled = !_notificationsEnabled;
    notifyListeners();
    await _save();
  }

  Future<void> toggleAutoReconnect() async {
    _autoReconnect = !_autoReconnect;
    notifyListeners();
    await _save();
  }

  Future<void> setTargetDeviceName(String name) async {
    _targetDeviceName = name.trim();
    notifyListeners();
    await _save();
  }
}
