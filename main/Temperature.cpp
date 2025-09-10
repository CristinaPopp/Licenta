#include "Temperature.h"
#include <DHT22.h>
#include "config.h"

DHT22 dht(DHT_PIN);

void setupTemperatureSensors() {
}

float readTemperature(int dhtPin) {
  if (dhtPin == DHT_PIN) return dht.getTemperature();
  return -999.0; //eroare daca pinul nu este gasit
}
float readHumidity(int pin) { (void)pin; return dht.getHumidity(); }
