# NeuroStep — Parkinson's AI Smart Insole System

<div align="center">

![NeuroStep Banner](docs/assets/banner.png)

**AI-Assisted Gait Monitoring & Adaptive Cueing for Parkinson's Disease**

[![Flutter](https://img.shields.io/badge/Flutter-3.32.0-blue?logo=flutter)](https://flutter.dev)
[![BLE](https://img.shields.io/badge/BLE-ESP32-green?logo=bluetooth)](https://docs.espressif.com)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android-brightgreen?logo=android)](https://android.com)

</div>

---

## Overview

NeuroStep is a production-grade Flutter mobile application for a Parkinson's Disease AI Smart Insole system. It connects to ESP32-powered smart insoles over BLE and provides real-time:

- 👣 **Gait stability monitoring** with pressure zone visualization
- 🧠 **FOG (Freezing of Gait) risk detection** with 0–100% scoring
- 📳 **Adaptive cueing** — visual laser, haptic LRA, audio rhythm
- 📊 **Step cadence & gait asymmetry** tracking
- 🔋 **Battery monitoring** for both insoles

---

## Architecture

```
lib/
├── constants/          # Colors, strings, BLE UUIDs
├── models/             # InsoleDevice, TelemetryData, CueSettings
├── services/
│   ├── ble/            # BLE layer (scanner, connection, parser, ESP32 impl)
│   └── mock/           # MockBleService (no hardware needed for dev)
├── providers/          # State: BleProvider, TelemetryProvider, SettingsProvider
├── screens/            # 7 screens: splash, scan, connect, dashboard, status, settings, debug
├── widgets/            # 8 widgets: InsoleCard, FogGauge, CueToggle, BatteryBar...
├── theme/              # Dark futuristic AppTheme (Orbitron + Inter)
└── utils/              # Logger, PermissionHandler, RetryHelper
```

### BLE Stack (hardware-agnostic)

```
[ESP32 Hardware]
      │  20-byte BLE notify packet (500ms)
      ▼
[Esp32BleManager]         ← concrete implementation
  ├── BleScanner          ← device discovery by name prefix
  ├── BleConnection       ← GATT connect + auto-reconnect (exponential backoff)
  └── BleCharacteristic   ← read / write / notify
      │
      ▼
[BleParser]               ← raw bytes → TelemetryData
      │
      ▼
[TelemetryProvider]       ← ChangeNotifier, rolling 60-reading history
      │
      ▼
[UI Widgets]              ← InsoleCard, FogRiskIndicator, MetricCard...
```

> To migrate from ESP32 to STM32WB55: create `Stm32BleManager implements BleManager`. No other code changes needed.

---

## Hardware Targets

| Target | Status | Notes |
|---|---|---|
| ESP32 DevKit | ✅ Current | Use `docs/esp32_ble_firmware_test.ino` |
| STM32WB55 | 🔜 Planned | Same BLE interface, swap manager class |

---

## Getting Started

### Prerequisites

- Flutter SDK 3.32.0+ ([install guide](https://docs.flutter.dev/get-started/install/windows))
- Android Studio / VS Code
- Android device with BLE (API 22+) or emulator
- ESP32 (for real hardware testing)

### Install & Run

```bash
# Clone the repo
git clone https://github.com/mayankeinstein1879/Parkinson-App.git
cd Parkinson-App

# Install dependencies
flutter pub get

# Run in mock mode (no hardware needed)
flutter run

# Run on real device with ESP32
# 1. Set useMock = false in lib/main.dart
# 2. Flash docs/esp32_ble_firmware_test.ino to ESP32
# 3. flutter run
```

### First Run Flow

1. App requests BLE + Location permissions
2. Tap **Scan for Insoles** — radar animation shows nearby devices
3. ESP32 appears as `Parkinson_L_Insole` / `Parkinson_R_Insole`
4. Tap **Connect** — GATT services are discovered automatically
5. Dashboard shows live telemetry from both insoles

---

## BLE Protocol

See [`BLE_PROTOCOL.md`](BLE_PROTOCOL.md) for the complete protocol spec including:
- Service & characteristic UUIDs
- 20-byte combined telemetry packet format
- Cue control command format
- ESP32 Arduino code examples

### Quick UUID Reference

| Service | UUID |
|---|---|
| Telemetry | `12345678-1234-1234-1234-123456789abc` |
| Battery (standard) | `0000180f-0000-1000-8000-00805f9b34fb` |

| Characteristic | UUID | Direction |
|---|---|---|
| Combined Telemetry | `abcdef08-...abc` | ESP32 → App (Notify) |
| Cue Control | `abcdef07-...abc` | App → ESP32 (Write) |

---

## Android Permissions

The following permissions are declared in `AndroidManifest.xml`:

```xml
<!-- Android 12+ -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<!-- Android < 12 -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

All permissions are also requested at runtime via `BlePermissionHandler`.

---

## Development Mode

The app has a **mock data mode** (default ON) that simulates two connected insoles with realistic telemetry including FOG spikes — no hardware needed.

Toggle in: **Settings → Use Mock Data**  
Or in code: `const bool useMock = true;` in `lib/main.dart`

---

## Project Structure

```
parkinson_app/
├── lib/                          # All Dart source (37 files)
├── android/                      # Android config (BLE permissions)
│   └── app/src/main/
│       └── AndroidManifest.xml   ← Critical BLE permissions
├── docs/
│   └── esp32_ble_firmware_test.ino  ← ESP32 test sketch
├── BLE_PROTOCOL.md               ← Full BLE spec + ESP32 examples
├── pubspec.yaml
└── README.md
```

---

## Roadmap

- [x] BLE scan & connect (ESP32)
- [x] Live telemetry parsing
- [x] FOG risk indicator
- [x] Adaptive cue controls (visual/haptic/audio)
- [x] Mock mode for development
- [ ] AI gait model (on-device inference)
- [ ] STM32WB55 migration
- [ ] Fall detection
- [ ] Caregiver notification panel
- [ ] Cloud telemetry sync

---

## License

MIT © 2025 Mayank Mukherjee