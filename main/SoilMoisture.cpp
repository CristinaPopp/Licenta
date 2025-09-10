#include "SoilMoisture.h"

void setupSoilMoisture(uint8_t pin){
  pinMode(pin, INPUT);
}

float getSoilMoisture(uint8_t pin){
  return analogRead(pin);
}