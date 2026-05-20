# BLE Protocol Specification
## Parkinson's AI Smart Insole System

**Document Version:** 0.1  
**Hardware Target:** ESP32 (current) → STM32WB55 (future)  
**App Package:** `com.parkinsonsai.parkinson_insole_app`

---

## 1. BLE Advertisement

| Field | Value |
|---|---|
| Left Insole Name | `Parkinson_L_Insole` |
| Right Insole Name | `Parkinson_R_Insole` |
| Advertising Interval | 100 ms |
| Connectable | Yes |

---

## 2. GATT Services

### 2.1 Telemetry Service
**UUID:** `12345678-1234-1234-1234-123456789abc`

| Characteristic | UUID | Properties | Size | Description |
|---|---|---|---|---|
| Combined Telemetry | `abcdef08-...abc` | Notify | 20 bytes | All data in one packet |
| Cue Control | `abcdef07-...abc` | Write | 3 bytes | Send cue commands |
| FOG Risk | `abcdef04-...abc` | Notify | 1 byte | FOG score 0–100 |

### 2.2 Gait Service
**UUID:** `12345678-1234-1234-1234-123456789abd`

| Characteristic | UUID | Properties | Size | Description |
|---|---|---|---|---|
| Pressure Data | `abcdef01-...abc` | Notify | 9 bytes | 4 pressure zones |
| Gait Stability | `abcdef02-...abc` | Notify | 1 byte | 0–100% |
| Step Cadence | `abcdef03-...abc` | Notify | 2 bytes | steps/min × 10 |
| Asymmetry | `abcdef05-...abc` | Notify | 1 byte | 0–100% |
| Confidence | `abcdef06-...abc` | Notify | 1 byte | 0–100% |

### 2.3 Battery Service (Standard BLE)
**UUID:** `0000180f-0000-1000-8000-00805f9b34fb`

---

## 3. Packet Formats

### 3.1 Combined Telemetry Packet (20 bytes) — PRIMARY

This is the main packet the ESP32 should send every 500ms via BLE Notify.

```
Byte  0:     Packet type = 0x04 (COMBINED)
Bytes 1-2:   Heel pressure    (uint16 big-endian, × 10 = kPa)
Bytes 3-4:   Midfoot pressure (uint16 big-endian, × 10 = kPa)
Bytes 5-6:   Forefoot pressure(uint16 big-endian, × 10 = kPa)
Bytes 7-8:   Toe pressure     (uint16 big-endian, × 10 = kPa)
Byte  9:     Gait stability   (uint8, 0–100 %)
Byte  10:    FOG risk score   (uint8, 0–100 %)
Bytes 11-12: Step cadence     (uint16 big-endian, steps/min × 10)
Byte  13:    Gait asymmetry   (uint8, 0–100 %)
Byte  14:    Walk confidence  (uint8, 0–100 %)
Byte  15:    Battery level    (uint8, 0–100 %)
Byte  16:    Cue active       (uint8, 0=off 1=on)
Bytes 17-19: Reserved/padding (set to 0x00)
```

**Example ESP32 Arduino code to send this packet:**
```cpp
uint8_t packet[20] = {0};
packet[0]  = 0x04;                        // Combined type
packet[1]  = (uint8_t)(heel_kpa * 10) >> 8;
packet[2]  = (uint8_t)(heel_kpa * 10) & 0xFF;
packet[3]  = (uint8_t)(mid_kpa  * 10) >> 8;
packet[4]  = (uint8_t)(mid_kpa  * 10) & 0xFF;
packet[5]  = (uint8_t)(fore_kpa * 10) >> 8;
packet[6]  = (uint8_t)(fore_kpa * 10) & 0xFF;
packet[7]  = (uint8_t)(toe_kpa  * 10) >> 8;
packet[8]  = (uint8_t)(toe_kpa  * 10) & 0xFF;
packet[9]  = gait_stability;              // 0–100
packet[10] = fog_risk;                    // 0–100
packet[11] = (cadence_x10) >> 8;
packet[12] = (cadence_x10) & 0xFF;
packet[13] = asymmetry;                   // 0–100
packet[14] = walk_confidence;             // 0–100
packet[15] = battery_percent;             // 0–100
packet[16] = cue_active ? 1 : 0;
// bytes 17-19 stay 0

telemetryCharacteristic.setValue(packet, 20);
telemetryCharacteristic.notify();
```

---

### 3.2 Cue Control Command (3 bytes) — App → ESP32

The app writes this to `cueControlCharUuid` to activate cues.

```
Byte 0: Visual intensity  (0–255, 0 = off)
Byte 1: Haptic intensity  (0–255, 0 = off)
Byte 2: Audio volume      (0–255, 0 = off)
```

**Example ESP32 handler:**
```cpp
void onCueWrite(BLECharacteristic* pChar) {
  uint8_t* data = pChar->getData();
  visualIntensity = data[0];
  hapticIntensity = data[1];
  audioVolume     = data[2];
  applyAdaptiveCues();
}
```

---

## 4. Packet Type IDs

| Type | Hex | Description |
|---|---|---|
| Pressure only | `0x01` | 9-byte pressure packet |
| Gait only | `0x02` | 7-byte gait packet |
| Battery only | `0x03` | 2-byte battery packet |
| Combined | `0x04` | 20-byte full packet (PREFERRED) |
| ACK | `0x05` | Acknowledgement from device |
| Error | `0xFF` | Error response |

---

## 5. Connection Parameters

| Parameter | Value |
|---|---|
| Scan timeout | 15 seconds |
| Connect timeout | 10 seconds |
| MTU | 512 bytes (requested) |
| Notify interval | 500 ms |
| Auto-reconnect | Yes, exponential backoff |
| Max reconnect attempts | 5 |

---

## 6. ESP32 Arduino Setup Checklist

To make the ESP32 work with this app:

1. ✅ Set BLE device name to exactly `Parkinson_L_Insole` or `Parkinson_R_Insole`
2. ✅ Create the Telemetry Service with UUID `12345678-1234-1234-1234-123456789abc`
3. ✅ Create the Combined Telemetry characteristic with UUID `abcdef08-1234-1234-1234-123456789abc`
4. ✅ Set characteristic properties: **NOTIFY**
5. ✅ Create the Cue Control characteristic with UUID `abcdef07-1234-1234-1234-123456789abc`
6. ✅ Set cue control properties: **WRITE** and **WRITE_NO_RESPONSE**
7. ✅ Enable notifications support (add 2902 descriptor)
8. ✅ Send 20-byte packet every 500ms using the format in section 3.1
9. ✅ Handle cue writes from the app (section 3.2)

---

## 7. STM32WB55 Migration Path

When migrating from ESP32 to STM32WB55:

1. Update `BleConstants.deviceNameLeft/Right` with new device names
2. Update service/characteristic UUIDs if they change
3. Create `Stm32BleManager implements BleManager` (same interface as `Esp32BleManager`)
4. Swap the manager in `main.dart`
5. No other app code changes needed

---

## 8. Debugging Tips

- Use the **Debug Screen** in the app to see raw telemetry values
- If scan finds no devices: check device name exactly matches `Parkinson_L_Insole`
- If connection drops: check BLE notify is enabled with the 2902 descriptor on ESP32
- If no telemetry shows: verify the service and characteristic UUIDs match exactly
- Enable mock data in Settings to test the full UI without hardware
