#include "relay.h"
#include "config.h"
void setupRelay(uint8_t pin) {
  pinMode(pin, OUTPUT);
  digitalWrite(pin, HIGH);
}

void turnOnRelay(uint8_t relay) {
  digitalWrite(relay, LOW);
}

void turnOffRelay(uint8_t relay) {
  digitalWrite(relay, HIGH);
}

void autoStopWaterPump(uint8_t relay, unsigned long relayTime, bool& relayWaterActive) {
  unsigned long currentMillis = millis();
  if (relayWaterActive && (currentMillis - relayTime > WATER_PUMP_DELAY)) {
    turnOffRelay(relay);
    relayWaterActive = false;  
  }

}