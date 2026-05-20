/*
 * NeuroStep ESP32 BLE Test Firmware
 * ===================================
 * Parkinson's AI Smart Insole — ESP32 BLE Test Sketch
 *
 * PURPOSE: Tests BLE communication with the NeuroStep Flutter app.
 * This sends realistic fake telemetry so you can verify the full
 * BLE pipeline (scan → connect → notify → parse → display).
 *
 * HARDWARE: Any ESP32 board (ESP32 DevKit, ESP32-S3, ESP32-C3, etc.)
 *
 * DEPENDENCIES (install in Arduino IDE):
 *   - ESP32 Arduino Core >= 2.0.0  (by Espressif)
 *
 * USAGE:
 *   1. Set INSOLE_SIDE to "LEFT" or "RIGHT"
 *   2. Flash this to your ESP32
 *   3. Open NeuroStep app → Scan → device will appear
 *   4. Connect → see live data in dashboard
 *
 * BLE Protocol matches BLE_PROTOCOL.md exactly.
 */

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <math.h>

// ── Configuration ─────────────────────────────────────────────────────────────
#define INSOLE_SIDE "LEFT"    // Change to "RIGHT" for the other insole
#define NOTIFY_INTERVAL_MS 500 // Match app's expected 500ms interval

// Build device name from side
#if defined(INSOLE_SIDE) && (INSOLE_SIDE[0] == 'L')
  #define DEVICE_NAME "Parkinson_L_Insole"
#else
  #define DEVICE_NAME "Parkinson_R_Insole"
#endif

// ── UUIDs — MUST match BleConstants in the Flutter app exactly ────────────────
#define TELEMETRY_SERVICE_UUID    "12345678-1234-1234-1234-123456789abc"
#define COMBINED_TELEMETRY_UUID   "abcdef08-1234-1234-1234-123456789abc"
#define CUE_CONTROL_UUID          "abcdef07-1234-1234-1234-123456789abc"
#define BATTERY_SERVICE_UUID      "0000180f-0000-1000-8000-00805f9b34fb"
#define BATTERY_CHAR_UUID         "00002a19-0000-1000-8000-00805f9b34fb"

// ── Packet type identifier ────────────────────────────────────────────────────
#define PACKET_TYPE_COMBINED 0x04

// ── Global state ──────────────────────────────────────────────────────────────
BLEServer*         pServer              = nullptr;
BLECharacteristic* pTelemetryChar       = nullptr;
BLECharacteristic* pCueControlChar      = nullptr;
BLECharacteristic* pBatteryChar         = nullptr;

bool deviceConnected    = false;
bool oldDeviceConnected = false;
uint8_t batteryLevel    = 85;
unsigned long lastNotifyTime = 0;

// Simulated sensor state (evolves over time for realistic data)
float simTime     = 0.0f;
float fogRisk     = 15.0f;   // starts low
bool  cueActive   = false;

// Received cue settings from app
uint8_t visualIntensity = 0;
uint8_t hapticIntensity = 0;
uint8_t audioVolume     = 0;

// ── BLE Server Callbacks ──────────────────────────────────────────────────────
class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) override {
    deviceConnected = true;
    Serial.println("[BLE] Device connected!");
    // Stop advertising once connected (single device)
    BLEDevice::getAdvertising()->stop();
  }

  void onDisconnect(BLEServer* pServer) override {
    deviceConnected = false;
    Serial.println("[BLE] Device disconnected. Restarting advertising...");
  }
};

// ── Cue Control Write Callback ────────────────────────────────────────────────
class CueControlCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pChar) override {
    std::string value = pChar->getValue();
    if (value.length() >= 3) {
      visualIntensity = (uint8_t)value[0];
      hapticIntensity = (uint8_t)value[1];
      audioVolume     = (uint8_t)value[2];

      cueActive = (visualIntensity > 0 || hapticIntensity > 0 || audioVolume > 0);

      Serial.printf("[CUE] Visual=%d Haptic=%d Audio=%d Active=%s\n",
        visualIntensity, hapticIntensity, audioVolume,
        cueActive ? "YES" : "NO");

      // TODO: Apply cues to actual hardware (laser, LRA motor, buzzer)
      applyAdaptiveCues();
    }
  }
};

// ── Setup ─────────────────────────────────────────────────────────────────────
void setup() {
  Serial.begin(115200);
  delay(500);
  Serial.println("===========================================");
  Serial.printf("NeuroStep ESP32 Firmware — %s\n", DEVICE_NAME);
  Serial.println("===========================================");

  setupBLE();

  Serial.println("[READY] Broadcasting BLE. Open NeuroStep app to connect.");
}

void setupBLE() {
  // Init BLE with device name
  BLEDevice::init(DEVICE_NAME);
  BLEDevice::setMTU(512); // Match app's MTU request

  // Create BLE server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());

  // ── Telemetry Service ──────────────────────────────────────────────────────
  BLEService* pTelemetryService = pServer->createService(TELEMETRY_SERVICE_UUID);

  // Combined Telemetry Characteristic (NOTIFY — app subscribes to this)
  pTelemetryChar = pTelemetryService->createCharacteristic(
    COMBINED_TELEMETRY_UUID,
    BLECharacteristic::PROPERTY_NOTIFY
  );
  // REQUIRED: 2902 descriptor enables client to subscribe to notifications
  pTelemetryChar->addDescriptor(new BLE2902());

  // Cue Control Characteristic (WRITE — app sends cue intensity commands)
  pCueControlChar = pTelemetryService->createCharacteristic(
    CUE_CONTROL_UUID,
    BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR
  );
  pCueControlChar->setCallbacks(new CueControlCallbacks());

  pTelemetryService->start();

  // ── Battery Service (Standard BLE) ────────────────────────────────────────
  BLEService* pBatteryService = pServer->createService(BATTERY_SERVICE_UUID);
  pBatteryChar = pBatteryService->createCharacteristic(
    BATTERY_CHAR_UUID,
    BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
  );
  pBatteryChar->addDescriptor(new BLE2902());
  pBatteryService->start();

  // ── Start Advertising ──────────────────────────────────────────────────────
  BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(TELEMETRY_SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06); // Helps iOS with discovery
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();

  Serial.printf("[BLE] Advertising as: %s\n", DEVICE_NAME);
  Serial.printf("[BLE] Telemetry UUID: %s\n", TELEMETRY_SERVICE_UUID);
}

// ── Main Loop ─────────────────────────────────────────────────────────────────
void loop() {
  // Handle reconnect after disconnect
  if (!deviceConnected && oldDeviceConnected) {
    delay(500);
    pServer->startAdvertising();
    Serial.println("[BLE] Restarted advertising");
    oldDeviceConnected = false;
  }

  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = true;
  }

  // Send telemetry every NOTIFY_INTERVAL_MS
  if (deviceConnected && (millis() - lastNotifyTime >= NOTIFY_INTERVAL_MS)) {
    lastNotifyTime = millis();
    sendTelemetryPacket();
  }

  delay(10);
}

// ── Build and Send 20-byte Combined Telemetry Packet ─────────────────────────
void sendTelemetryPacket() {
  simTime += 0.5f; // Advance simulation time

  // Simulate realistic gait sensor values
  float heelKPa    = 35.0f + 25.0f * sin(simTime * 1.2f);
  float midfootKPa = 15.0f + 10.0f * sin(simTime * 1.2f + 0.5f);
  float forefootKPa= 28.0f + 20.0f * sin(simTime * 1.2f + 1.0f);
  float toeKPa     = 12.0f + 8.0f  * sin(simTime * 1.2f + 1.5f);

  // Clamp to non-negative
  heelKPa     = max(0.0f, heelKPa);
  midfootKPa  = max(0.0f, midfootKPa);
  forefootKPa = max(0.0f, forefootKPa);
  toeKPa      = max(0.0f, toeKPa);

  // Simulate FOG risk — spikes every ~30 seconds to test alerts
  if (fmod(simTime, 60.0f) > 55.0f) {
    fogRisk = min(100.0f, fogRisk + 3.0f); // FOG episode
  } else {
    fogRisk = max(5.0f, fogRisk - 1.5f);   // Recovery
  }

  uint8_t gaitStability = (uint8_t)(80.0f - fogRisk * 0.6f);  // inversely related
  uint8_t fogRiskByte   = (uint8_t)constrain(fogRisk, 0, 100);
  uint16_t cadenceX10   = 1080;  // 108.0 steps/min × 10
  uint8_t asymmetry     = 12;    // 12% asymmetry (realistic)
  uint8_t confidence    = 78;    // 78% walking confidence
  uint8_t cueActiveByte = cueActive ? 1 : 0;

  // Drain battery slowly
  if ((int)simTime % 120 == 0 && batteryLevel > 1) {
    batteryLevel--;
  }

  // ── Build the 20-byte packet ───────────────────────────────────────────────
  uint8_t packet[20] = {0};
  packet[0]  = PACKET_TYPE_COMBINED;

  // Pressure: 4 × uint16 big-endian (value × 10 for 1 decimal place)
  writeUint16BE(packet, 1, (uint16_t)(heelKPa     * 10));
  writeUint16BE(packet, 3, (uint16_t)(midfootKPa  * 10));
  writeUint16BE(packet, 5, (uint16_t)(forefootKPa * 10));
  writeUint16BE(packet, 7, (uint16_t)(toeKPa      * 10));

  packet[9]  = constrain(gaitStability, 0, 100);
  packet[10] = fogRiskByte;
  writeUint16BE(packet, 11, cadenceX10);
  packet[13] = asymmetry;
  packet[14] = confidence;
  packet[15] = batteryLevel;
  packet[16] = cueActiveByte;
  // bytes 17-19 = 0x00 (padding/reserved)

  // Send via BLE notify
  pTelemetryChar->setValue(packet, 20);
  pTelemetryChar->notify();

  // Update battery characteristic
  pBatteryChar->setValue(&batteryLevel, 1);
  pBatteryChar->notify();

  // Debug print every 10 packets
  static int packetCount = 0;
  if (++packetCount % 10 == 0) {
    Serial.printf("[TX] FOG=%.0f%% Stab=%d%% Cad=%.1fspm Bat=%d%% Cue=%s\n",
      fogRisk, gaitStability, cadenceX10 / 10.0f, batteryLevel,
      cueActive ? "ON" : "OFF");
  }
}

// ── Helper: Write uint16 big-endian ──────────────────────────────────────────
void writeUint16BE(uint8_t* buf, int idx, uint16_t value) {
  buf[idx]     = (value >> 8) & 0xFF;
  buf[idx + 1] = value & 0xFF;
}

// ── Apply Cues to Hardware ────────────────────────────────────────────────────
void applyAdaptiveCues() {
  // TODO: Wire these to your actual actuators:
  //
  // Visual (laser):
  //   analogWrite(LASER_PIN, visualIntensity);
  //
  // Haptic (LRA motor via DRV2605 or PWM):
  //   analogWrite(HAPTIC_PIN, hapticIntensity);
  //
  // Audio (buzzer/speaker):
  //   analogWrite(AUDIO_PIN, audioVolume);
  //
  // For now, just print to Serial:
  Serial.printf("[ACT] Applying cues — V:%d H:%d A:%d\n",
    visualIntensity, hapticIntensity, audioVolume);
}
