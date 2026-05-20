/*
 * ============================================================
 *  NeuroStep — ESP32 BLE Static Test Firmware
 *  Compatible with Flutter app BLE backend
 * ============================================================
 *
 *  PURPOSE
 *  -------
 *  Transmit hardcoded static sensor values over BLE so you
 *  can confirm real data is reaching the Flutter app.
 *
 *  If you see EXACTLY these values in the app → BLE is working:
 *    Heel pressure      → 45.0 kPa
 *    Midfoot pressure   → 20.0 kPa
 *    Forefoot pressure  → 30.0 kPa
 *    Toe pressure       → 15.0 kPa
 *    Gait stability     → 75%
 *    FOG risk           → 25%
 *    Cadence            → 95.0 steps/min
 *    Gait asymmetry     → 10%
 *    Walking confidence → 80%
 *    Battery level      → 87%
 *    Cue active         → OFF
 *
 *  HOW TO USE
 *  ----------
 *  1. Open Arduino IDE
 *  2. Board Manager → install "ESP32 by Espressif Systems"
 *  3. Select board: Tools → Board → ESP32 Dev Module
 *     (or ESP32-S3, ESP32-WROOM-32 — whatever you have)
 *  4. Select the correct COM port
 *  5. Upload this sketch
 *  6. Open Serial Monitor at 115200 baud
 *  7. In Chrome → open localhost:8080 → tap SCAN
 *     Chrome shows a device picker → select "Parkinson_L_Insole"
 *  8. App connects → check Dashboard and Debug screens
 *
 *  WHAT TO LOOK FOR ON SERIAL MONITOR
 *  ------------------------------------
 *  When connected:  "[TX #001] Sent 20-byte packet ..."
 *  When cue sent:   "[CUE] Visual=X Haptic=X Audio=X"
 *
 * ============================================================
 */

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// ── Device Name ─────────────────────────────────────────────────────────────
// MUST match BleConstants.deviceNameLeft in the Flutter app
// Change to "Parkinson_R_Insole" if testing right insole
#define DEVICE_NAME "Parkinson_L_Insole"

// ── Service & Characteristic UUIDs ──────────────────────────────────────────
// These must EXACTLY match BleConstants in the Flutter app (ble_constants.dart)
// DO NOT change these unless you also change them in the app
#define TELEMETRY_SERVICE_UUID   "12345678-1234-1234-1234-123456789abc"
#define COMBINED_TELEMETRY_UUID  "abcdef08-1234-1234-1234-123456789abc"
#define CUE_CONTROL_UUID         "abcdef07-1234-1234-1234-123456789abc"
#define BATTERY_SERVICE_UUID     "0000180f-0000-1000-8000-00805f9b34fb"
#define BATTERY_CHAR_UUID        "00002a19-0000-1000-8000-00805f9b34fb"

// ── Packet Format ────────────────────────────────────────────────────────────
// 20 bytes total — matches BleParser in Flutter app exactly:
//
//  [0]      Packet type = 0x04 (combined telemetry)
//  [1][2]   Heel pressure    uint16 big-endian  (kPa × 10)
//  [3][4]   Midfoot pressure uint16 big-endian  (kPa × 10)
//  [5][6]   Forefoot pressure uint16 big-endian (kPa × 10)
//  [7][8]   Toe pressure     uint16 big-endian  (kPa × 10)
//  [9]      Gait stability   uint8  (0–100 %)
//  [10]     FOG risk         uint8  (0–100 %)
//  [11][12] Cadence          uint16 big-endian  (steps/min × 10)
//  [13]     Gait asymmetry   uint8  (0–100 %)
//  [14]     Walk confidence  uint8  (0–100 %)
//  [15]     Battery level    uint8  (0–100 %)
//  [16]     Cue active       uint8  (0=false, 1=true)
//  [17–19]  Padding          0x00

#define PACKET_TYPE_COMBINED  0x04
#define PACKET_SIZE           20

// ── Hardcoded Static Test Values ─────────────────────────────────────────────
// NOTHING here ever changes. You should see these EXACT numbers in the app.
// Scale factor = × 10 for pressure and cadence (to keep them as integers)
const uint16_t VAL_HEEL      = 450;   // → 45.0 kPa
const uint16_t VAL_MIDFOOT   = 200;   // → 20.0 kPa
const uint16_t VAL_FOREFOOT  = 300;   // → 30.0 kPa
const uint16_t VAL_TOE       = 150;   // → 15.0 kPa
const uint8_t  VAL_STABILITY =  75;   // → 75%
const uint8_t  VAL_FOG_RISK  =  25;   // → 25%
const uint16_t VAL_CADENCE   = 950;   // → 95.0 steps/min
const uint8_t  VAL_ASYMMETRY =  10;   // → 10%
const uint8_t  VAL_CONFIDENCE = 80;   // → 80%
const uint8_t  VAL_BATTERY   =  87;   // → 87%
const uint8_t  VAL_CUE_ACTIVE = 0;    // → false

// ── Interval ─────────────────────────────────────────────────────────────────
// Send telemetry every 1000ms (1 second) — easy to count in Debug screen
const uint32_t NOTIFY_INTERVAL_MS = 1000;

// ── BLE Handles ───────────────────────────────────────────────────────────────
BLEServer*         pServer         = nullptr;
BLECharacteristic* pTelemetryChar  = nullptr;
BLECharacteristic* pCueChar        = nullptr;
BLECharacteristic* pBatteryChar    = nullptr;

bool deviceConnected    = false;
bool oldDeviceConnected = false;
uint32_t lastNotifyMs   = 0;
uint32_t packetCount    = 0;

// ─────────────────────────────────────────────────────────────────────────────
// BLE Server Callbacks
// ─────────────────────────────────────────────────────────────────────────────
class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) override {
    deviceConnected = true;
    Serial.println(F("\n╔══════════════════════════════════════╗"));
    Serial.println(F(  "║   ✓  APP CONNECTED VIA BLE!          ║"));
    Serial.println(F(  "║   Sending static data every 1 sec.   ║"));
    Serial.println(F(  "╚══════════════════════════════════════╝\n"));
    BLEDevice::getAdvertising()->stop();
  }

  void onDisconnect(BLEServer* pServer) override {
    deviceConnected = false;
    packetCount = 0;
    Serial.println(F("\n[DISCONNECTED] Restarting advertising..."));
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// Cue Control Write Callback — fires when app sends a cue command
// ─────────────────────────────────────────────────────────────────────────────
class CueControlCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pChar) override {
    std::string val = pChar->getValue();
    if (val.length() >= 3) {
      uint8_t visual  = (uint8_t)val[0];
      uint8_t haptic  = (uint8_t)val[1];
      uint8_t audio   = (uint8_t)val[2];

      Serial.println(F("\n┌─────────────────────────────────────┐"));
      Serial.println(F(  "│   CUE COMMAND RECEIVED FROM APP     │"));
      Serial.printf(    "│   Visual intensity : %-3d             │\n", visual);
      Serial.printf(    "│   Haptic intensity : %-3d             │\n", haptic);
      Serial.printf(    "│   Audio volume     : %-3d             │\n", audio);
      Serial.println(F(  "└─────────────────────────────────────┘\n"));

      // TODO: Wire to your actual actuators here:
      // analogWrite(LASER_PIN,  visual);
      // analogWrite(HAPTIC_PIN, haptic);
      // analogWrite(BUZZER_PIN, audio);
    }
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// Setup
// ─────────────────────────────────────────────────────────────────────────────
void setup() {
  Serial.begin(115200);
  delay(500);
  printStartupBanner();
  initBLE();
  Serial.println(F("[READY] Now open Chrome → localhost:8080 → tap SCAN"));
  Serial.println(F("        Chrome will show a BLE picker dialog."));
  Serial.println(F("        Select \"Parkinson_L_Insole\" to connect.\n"));
}

// ─────────────────────────────────────────────────────────────────────────────
// Loop
// ─────────────────────────────────────────────────────────────────────────────
void loop() {
  // Restart advertising after disconnect
  if (!deviceConnected && oldDeviceConnected) {
    delay(500);
    BLEDevice::getAdvertising()->start();
    Serial.println(F("[ADV] Advertising restarted. Waiting for app..."));
    oldDeviceConnected = false;
  }

  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = true;
  }

  // Send telemetry at interval
  if (deviceConnected && (millis() - lastNotifyMs >= NOTIFY_INTERVAL_MS)) {
    lastNotifyMs = millis();
    sendPacket();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Build and send the 20-byte combined telemetry packet
// ─────────────────────────────────────────────────────────────────────────────
void sendPacket() {
  uint8_t pkt[PACKET_SIZE] = {0};

  pkt[0] = PACKET_TYPE_COMBINED;      // byte 0:  packet type

  writeU16BE(pkt, 1, VAL_HEEL);       // bytes 1-2:  heel pressure
  writeU16BE(pkt, 3, VAL_MIDFOOT);    // bytes 3-4:  midfoot pressure
  writeU16BE(pkt, 5, VAL_FOREFOOT);   // bytes 5-6:  forefoot pressure
  writeU16BE(pkt, 7, VAL_TOE);        // bytes 7-8:  toe pressure

  pkt[9]  = VAL_STABILITY;            // byte 9:  gait stability %
  pkt[10] = VAL_FOG_RISK;             // byte 10: FOG risk %

  writeU16BE(pkt, 11, VAL_CADENCE);   // bytes 11-12: cadence

  pkt[13] = VAL_ASYMMETRY;            // byte 13: asymmetry %
  pkt[14] = VAL_CONFIDENCE;           // byte 14: walk confidence %
  pkt[15] = VAL_BATTERY;              // byte 15: battery %
  pkt[16] = VAL_CUE_ACTIVE;          // byte 16: cue active flag
  // pkt[17..19] = 0x00 padding (already zeroed)

  // Send via BLE NOTIFY
  pTelemetryChar->setValue(pkt, PACKET_SIZE);
  pTelemetryChar->notify();

  // Also update standard battery service
  uint8_t bat = VAL_BATTERY;
  pBatteryChar->setValue(&bat, 1);
  pBatteryChar->notify();

  // Print to Serial Monitor every packet
  packetCount++;
  Serial.printf("[TX #%04lu] Heel=%.1f Mid=%.1f Fore=%.1f Toe=%.1f kPa | "
                "Stab=%d%% FOG=%d%% Cad=%.1fspm Bat=%d%%\n",
    (unsigned long)packetCount,
    VAL_HEEL     / 10.0f,
    VAL_MIDFOOT  / 10.0f,
    VAL_FOREFOOT / 10.0f,
    VAL_TOE      / 10.0f,
    VAL_STABILITY,
    VAL_FOG_RISK,
    VAL_CADENCE  / 10.0f,
    VAL_BATTERY
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// BLE Initialisation
// ─────────────────────────────────────────────────────────────────────────────
void initBLE() {
  BLEDevice::init(DEVICE_NAME);
  // Do NOT call setMTU on web-facing tests — browser handles this
  // BLEDevice::setMTU(512);

  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // ── Custom Telemetry Service ───────────────────────────────────────────────
  BLEService* pTelSvc = pServer->createService(TELEMETRY_SERVICE_UUID);

  // Combined Telemetry: NOTIFY — app subscribes to receive data
  pTelemetryChar = pTelSvc->createCharacteristic(
    COMBINED_TELEMETRY_UUID,
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pTelemetryChar->addDescriptor(new BLE2902());

  // Cue Control: WRITE — app sends 3-byte intensity command
  pCueChar = pTelSvc->createCharacteristic(
    CUE_CONTROL_UUID,
    BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR
  );
  pCueChar->setCallbacks(new CueControlCallbacks());

  pTelSvc->start();

  // ── Standard BLE Battery Service ──────────────────────────────────────────
  BLEService* pBatSvc = pServer->createService(BATTERY_SERVICE_UUID);
  pBatteryChar = pBatSvc->createCharacteristic(
    BATTERY_CHAR_UUID,
    BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
  );
  pBatteryChar->addDescriptor(new BLE2902());
  pBatSvc->start();

  // ── Advertising ────────────────────────────────────────────────────────────
  // IMPORTANT: addServiceUUID tells Chrome which devices to show in picker
  BLEAdvertising* pAdv = BLEDevice::getAdvertising();
  pAdv->addServiceUUID(TELEMETRY_SERVICE_UUID);
  pAdv->setScanResponse(true);
  pAdv->setMinPreferred(0x06);   // helps with iOS compatibility
  pAdv->setMinPreferred(0x12);
  BLEDevice::startAdvertising();

  Serial.println(F("[BLE] Advertising started."));
  Serial.print(F("[BLE] Device name   : ")); Serial.println(F(DEVICE_NAME));
  Serial.print(F("[BLE] Service UUID  : ")); Serial.println(F(TELEMETRY_SERVICE_UUID));
  Serial.print(F("[BLE] Telemetry UUID: ")); Serial.println(F(COMBINED_TELEMETRY_UUID));
  Serial.print(F("[BLE] Cue UUID      : ")); Serial.println(F(CUE_CONTROL_UUID));
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: write uint16 big-endian into buffer at index i
// ─────────────────────────────────────────────────────────────────────────────
void writeU16BE(uint8_t* buf, int i, uint16_t val) {
  buf[i]   = (val >> 8) & 0xFF;
  buf[i+1] =  val       & 0xFF;
}

// ─────────────────────────────────────────────────────────────────────────────
// Startup banner + expected values table
// ─────────────────────────────────────────────────────────────────────────────
void printStartupBanner() {
  Serial.println(F("\n╔══════════════════════════════════════════════╗"));
  Serial.println(F(  "║  NeuroStep ESP32 — Static BLE Test Mode      ║"));
  Serial.println(F(  "╠══════════════════════════════════════════════╣"));
  Serial.println(F(  "║  EXPECTED VALUES IN THE APP (all fixed):     ║"));
  Serial.println(F(  "║  Heel pressure       →  45.0 kPa            ║"));
  Serial.println(F(  "║  Midfoot pressure    →  20.0 kPa            ║"));
  Serial.println(F(  "║  Forefoot pressure   →  30.0 kPa            ║"));
  Serial.println(F(  "║  Toe pressure        →  15.0 kPa            ║"));
  Serial.println(F(  "║  Gait stability      →  75%                 ║"));
  Serial.println(F(  "║  FOG risk            →  25%                 ║"));
  Serial.println(F(  "║  Step cadence        →  95.0 spm            ║"));
  Serial.println(F(  "║  Gait asymmetry      →  10%                 ║"));
  Serial.println(F(  "║  Walking confidence  →  80%                 ║"));
  Serial.println(F(  "║  Battery level       →  87%                 ║"));
  Serial.println(F(  "╚══════════════════════════════════════════════╝\n"));
}
