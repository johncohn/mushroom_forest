#include <Adafruit_TinyUSB.h>
#include <MIDI.h>
#include <Wire.h>
#include <Adafruit_MPR121.h>
#include "TouchFilter.h"

Adafruit_USBD_MIDI usb_midi;
MIDI_CREATE_INSTANCE(Adafruit_USBD_MIDI, usb_midi, MIDI);

// Configuration - Easy to adjust
#define NUM_SENSORS 5
const byte MIDI_NOTES[NUM_SENSORS] = {48, 49, 50, 51, 52}; // MIDI notes for each sensor
const byte MIDI_CHANNEL = 1;  // TinyUSB MIDI channels are 1-16
const byte MIDI_VELOCITY = 64;

// Set to true to print baseline values for debugging/calibration
#define DEBUG_BASELINES false
#define DEBUG_INTERVAL 2000  // Print baseline every 2 seconds when debugging

// MPR121 Setup
Adafruit_MPR121 cap = Adafruit_MPR121();

// Each electrode must settle released, then sustain a touch and a release.
TouchFilter touchFilters[NUM_SENSORS];

void setup() {
  MIDI.begin(MIDI_CHANNEL_OMNI);
  Serial.begin(115200);

  // Initialize built-in LED for status indication
  pinMode(LED_BUILTIN, OUTPUT);

  // Blink 3 times to show we're starting
  for (int i = 0; i < 3; i++) {
    digitalWrite(LED_BUILTIN, HIGH);
    delay(200);
    digitalWrite(LED_BUILTIN, LOW);
    delay(200);
  }

  Serial.println("\n\n=== QTPY RP2040 Touch MIDI Controller ===");
  Serial.println("Initializing MPR121...");

  // Initialize MPR121 on Wire1 (Qwiic connector uses secondary I2C on QTPY RP2040)
  if (!cap.begin(0x5A, &Wire1)) {
    Serial.println("MPR121 not found, check wiring!");
    // Rapid blink = error
    while (1) {
      digitalWrite(LED_BUILTIN, HIGH);
      delay(100);
      digitalWrite(LED_BUILTIN, LOW);
      delay(100);
    }
  }
  Serial.println("MPR121 found!");

  // Configure auto-calibration for custom sensors with varying lead lengths
  // These settings make the MPR121 adaptively adjust to different capacitances

  // Set touch and release thresholds for all electrodes (lower = more sensitive)
  // Adjust these if sensors are too sensitive or not sensitive enough
  cap.setThresholds(12, 6);  // touch threshold, release threshold

  // Enable auto-configuration
  // This allows the MPR121 to automatically adjust to baseline capacitance changes
  cap.writeRegister(MPR121_AUTOCONFIG0, 0x0B);  // Enable auto-config
  cap.writeRegister(MPR121_UPLIMIT, 200);       // Upper limit for auto-config
  cap.writeRegister(MPR121_LOWLIMIT, 130);      // Lower limit for auto-config
  cap.writeRegister(MPR121_TARGETLIMIT, 180);   // Target baseline value

  Serial.println("Auto-calibration enabled!");
  Serial.println("Waiting for sensors to stabilize...");
  delay(1000);  // Give sensors time to establish baseline

  Serial.println("Ready! Touch sensors will auto-calibrate to their geometry.");
}

void noteOn(byte channel, byte pitch, byte velocity) {
  MIDI.sendNoteOn(pitch, velocity, channel);
}

void noteOff(byte channel, byte pitch, byte velocity) {
  MIDI.sendNoteOff(pitch, velocity, channel);
}

void loop() {
  // Optional: Print baseline values for debugging calibration
  #if DEBUG_BASELINES
    static unsigned long lastDebugTime = 0;
    if (millis() - lastDebugTime > DEBUG_INTERVAL) {
      Serial.println("\n--- Sensor Baselines ---");
      for (int i = 0; i < NUM_SENSORS; i++) {
        Serial.print("Sensor ");
        Serial.print(i);
        Serial.print(": Baseline=");
        Serial.print(cap.baselineData(i + 1));
        Serial.print(" Filtered=");
        Serial.println(cap.filteredData(i + 1));
      }
      lastDebugTime = millis();
    }
  #endif

  // Get current touch state from MPR121
  uint16_t currtouched = cap.touched();

  // Check each sensor
  for (int i = 0; i < NUM_SENSORS; i++) {
    bool isTouched = (currtouched & (1 << (i + 1)));  // sensors on electrodes 1-5, not 0-4

    if (touchFilters[i].update(isTouched, millis())) {
      // Touch detected - send note on then off
      digitalWrite(LED_BUILTIN, HIGH);  // LED on when touch detected

      Serial.print("Mush");
      Serial.print(i + 1);
      Serial.println(" touched");
      Serial.print("Sending note: ");
      Serial.println(MIDI_NOTES[i]);

      noteOn(MIDI_CHANNEL, MIDI_NOTES[i], MIDI_VELOCITY);
      delay(10);
      noteOff(MIDI_CHANNEL, MIDI_NOTES[i], MIDI_VELOCITY);

      Serial.println("Note Off");

      digitalWrite(LED_BUILTIN, LOW);  // LED off after touch processed

    }
  }

  delay(10); // Small delay for stability
}
