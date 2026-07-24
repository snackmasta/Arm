#include <Arduino.h>
#include <ESP8266WiFi.h>
#include <WiFiUdp.h>
#include <Servo.h>

// Wi-Fi Credentials
const char* ST_SSID = "configurator";
const char* ST_PASS = "tolakangin";

// UDP Port
const uint16_t UDP_PORT = 8888;

// Servo pin definitions:
// GPIO 1: Elbow Pitch (J3)
// GPIO 3: Shoulder Pitch (J2)
// GPIO 5: Base Yaw (J1)
// GPIO 4: Wrist Pitch (J4)
// Note: GPIO 1 (TX) and GPIO 3 (RX) share pins with default Serial, 
// so Serial logging is omitted to prevent interference with servo signals.
const int SERVO1_PIN = 1; // GPIO 1 (Elbow Pitch J3)
const int SERVO2_PIN = 3; // GPIO 3 (Shoulder Pitch J2)
const int SERVO3_PIN = 5; // GPIO 5 (Base Yaw J1)
const int SERVO4_PIN = 4; // GPIO 4 (Wrist Pitch J4)

Servo servo1;
Servo servo2;
Servo servo3;
Servo servo4;

WiFiUDP udp;
char packetBuffer[256];

void processPacket(int packetSize) {
  if (packetSize <= 0) return;

  int len = udp.read(packetBuffer, sizeof(packetBuffer) - 1);
  if (len < 0) return;
  packetBuffer[len] = '\0';

  int a1 = -1, a2 = -1, a3 = -1, a4 = -1;

  // Option 1: Binary payload
  if (len == 4) {
    a1 = (uint8_t)packetBuffer[0];
    a2 = (uint8_t)packetBuffer[1];
    a3 = (uint8_t)packetBuffer[2];
    a4 = (uint8_t)packetBuffer[3];
  } else if (len == 3) {
    a1 = (uint8_t)packetBuffer[0];
    a2 = (uint8_t)packetBuffer[1];
    a3 = (uint8_t)packetBuffer[2];
    a4 = 90; // Default if 3 bytes provided
  } else {
    // Option 2: ASCII string formats like "90,45,180,90", "90 45 180 90"
    int parsed = sscanf(packetBuffer, "%d,%d,%d,%d", &a1, &a2, &a3, &a4);
    if (parsed < 4) {
      parsed = sscanf(packetBuffer, "%d %d %d %d", &a1, &a2, &a3, &a4);
    }
    if (parsed < 3) {
      // Fallback for 3 parameters
      parsed = sscanf(packetBuffer, "%d,%d,%d", &a1, &a2, &a3);
      if (parsed < 3) {
        sscanf(packetBuffer, "%d %d %d", &a1, &a2, &a3);
      }
      a4 = 90;
    }
  }

  // Update servo angles if valid angles parsed
  if (a1 >= 0 && a2 >= 0 && a3 >= 0) {
    a1 = constrain(a1, 0, 180);
    a2 = constrain(a2, 0, 180);
    a3 = constrain(a3, 0, 180);
    a4 = (a4 >= 0) ? constrain(a4, 0, 180) : 90;

    servo1.write(a1);
    servo2.write(a2);
    servo3.write(a3);
    servo4.write(a4);
  }
}

void setup() {
  // Attach servos with standard MG90S pulse width range (544us to 2400us)
  servo1.attach(SERVO1_PIN, 544, 2400);
  servo2.attach(SERVO2_PIN, 544, 2400);
  servo3.attach(SERVO3_PIN, 544, 2400);
  servo4.attach(SERVO4_PIN, 544, 2400);

  // Set default initial neutral position (90 degrees)
  servo1.write(90);
  servo2.write(90);
  servo3.write(90);
  servo4.write(90);

  // Connect to Wi-Fi Access Point
  WiFi.mode(WIFI_STA);
  WiFi.begin(ST_SSID, ST_PASS);

  while (WiFi.status() != WL_CONNECTED) {
    delay(250);
  }

  udp.begin(UDP_PORT);
}

void loop() {
  if (WiFi.status() == WL_CONNECTED) {
    int packetSize = udp.parsePacket();
    if (packetSize) {
      processPacket(packetSize);
    }
  } else {
    // Reconnect if Wi-Fi disconnects
    WiFi.begin(ST_SSID, ST_PASS);
    delay(500);
  }

  yield();
}

