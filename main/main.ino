// MEGA 2560 — irigare pe baza familiei plantei + prognoza meteo (de la ESP32)
#include "config.h"        // RELAY_WATER_1, DHT_PIN, SOIL_SENSOR1, WATER_PUMP_DELAY (ms)
#include "relay.h"         // setupRelay/turnOnRelay/turnOffRelay
#include "SoilMoisture.h"  // setupSoilMoisture/getSoilMoisture
#include "Temperature.h"   // setupTemperatureSensors/readTemperature, readHumidity
#include <Arduino.h>
#include <ArduinoJson.h>

//Calibrare senzor sol 
int SOIL_ADC_DRY = 780;  //  „uscat”
int SOIL_ADC_WET = 520;  //  „ud”

int soilPctFromAdc(int adc) {
  long dry = SOIL_ADC_DRY, wet = SOIL_ADC_WET;
  if (dry == wet) return 0;
  long pct = (dry - adc) * 100L / (dry - wet);// capacitiv: ADC mai MARE = mai uscat
  if (pct < 0) pct = 0;
  if (pct > 100) pct = 100;
  return (int)pct;
}

//Tabel familie -> umiditate optima
struct FamMoist { const char* name; int pct; };
const FamMoist FAMILY_TABLE[] = {
  {"Bromeliaceae",60}, {"Betulaceae",55}, {"Asteridaceae",55},
  {"Caryophyllaceae",50}, {"Apiaceae",55}, {"Asparagaceae",55},
  {"Asteraceae",55}, {"Brassicaceae",55}, {"Chenopodiaceae",50},
  {"Cupressaceae",45}, {"Fabaceae",55}, {"Cucurbitaceae",60},
  {"Fagaceae",55}, {"Heatheraceae",55}, {"Lamiaceae",55},
  {"Malvaceae",55}, {"Myrtaceae",55},
};
const uint8_t FAMILY_TABLE_LEN = sizeof(FAMILY_TABLE) / sizeof(FAMILY_TABLE[0]);

int  defaultTargetPct = 55; // tinta obiectiva
int  targetSoilPct = defaultTargetPct;
int  targetSoilAdc = 0;      
char currentFamily[32] = "Unknown";

int lookupTargetPct(const char* family) {
  if (!family || !*family) return defaultTargetPct;
  for (uint8_t i = 0; i < FAMILY_TABLE_LEN; ++i)
    if (strcasecmp(family, FAMILY_TABLE[i].name) == 0) return FAMILY_TABLE[i].pct;
  return defaultTargetPct;
}

// Conversie % in ADC 
int adcFromPct(int pct) {
  long dry = SOIL_ADC_DRY, wet = SOIL_ADC_WET;
  return (int)(dry - (long)pct * (dry - wet) / 100L);
}

// apel dupa primirea de la esp
void setFamilyFromString(const String& famStr) {
  String s = famStr; s.trim(); s.replace("\"", "");
  if (!s.length()) return;

  strncpy(currentFamily, s.c_str(), sizeof(currentFamily) - 1);
  currentFamily[sizeof(currentFamily) - 1] = '\0';

  targetSoilPct = lookupTargetPct(currentFamily); 
  targetSoilAdc = adcFromPct(targetSoilPct);      

  Serial.print(F("[FAMILY] ")); Serial.print(currentFamily);
  Serial.print(F("  target%=")); Serial.print(targetSoilPct);
  Serial.print(F("  targetADC=")); Serial.println(targetSoilAdc);
}

// Control pompa
const uint16_t HYST_ADC = 20; 
bool     pumpOn = false;
uint32_t pumpLastSwitchMs = 0;
const uint32_t MIN_SWITCH_INTERVAL_MS = 5000;

void pumpSet(bool on) {
  if (pumpOn == on) return;
  if (millis() - pumpLastSwitchMs < MIN_SWITCH_INTERVAL_MS) return;
  pumpLastSwitchMs = millis();
  pumpOn = on;
  if (on) turnOnRelay(RELAY_WATER_1);
  else    turnOffRelay(RELAY_WATER_1);
}

// Stare meteo venita de la ESP32
bool wxRainingNow = false;
bool wxWillRainToday = false;
bool wxPrevWill = false;
bool wxRainJustFinished = false;

// RX from ESP32 pe Serial1 
static char   rxBuf[256];
static uint8_t rxIdx = 0;

// Override manual (ex: {"cmd":"water","seconds":10})
unsigned long manualWaterUntilMs = 0;

void handleEspLine(char* s) {
  String raw = String(s); raw.trim();
  Serial.print(F("[RX RAW] ")); Serial.println(raw);

  // doar numele familiei sau JSON
  if (raw.length() > 0 && raw.charAt(0) != '{') {
    setFamilyFromString(raw);
    return;
  }

  StaticJsonDocument<256> doc;
  DeserializationError err = deserializeJson(doc, raw);
  if (err) {
    Serial.print(F("[RX JSON err] ")); Serial.println(err.c_str());
    return;
  }

  if (doc.containsKey("cmd")) {
    const char* cmd = doc["cmd"];
    if (cmd && strcmp(cmd, "water") == 0) {
      int seconds = doc["seconds"] | 0;
      if (seconds > 0 && seconds <= 600) {
        manualWaterUntilMs = millis() + (unsigned long)seconds * 1000UL;
        pumpSet(true);
        // ACK (opțional)
        Serial1.print("{\"ack\":\"water\",\"seconds\":");
        Serial1.print(seconds);
        Serial1.println("}");
      }
    }
  }

  // 1) family
  if (doc.containsKey("family")) {
    const char* fam = doc["family"];
    if (fam) setFamilyFromString(String(fam));
  }

  // 2) meteo
  bool hasWx = false;
  bool rn = wxRainingNow, wr = wxWillRainToday;
  if (doc.containsKey("rainingNow"))    { rn = doc["rainingNow"];    hasWx = true; }
  if (doc.containsKey("willRainToday")) { wr = doc["willRainToday"]; hasWx = true; }

  if (hasWx) {
    wxPrevWill         = wxWillRainToday;
    wxRainingNow       = rn;
    wxWillRainToday    = wr;
    wxRainJustFinished = (wxPrevWill == true && wxWillRainToday == false);
    Serial.print(F("[WX] now=")); Serial.print(wxRainingNow ? F("RAIN") : F("DRY"));
    Serial.print(F(", willToday=")); Serial.print(wxWillRainToday ? F("YES") : F("NO"));
    if (wxRainJustFinished) Serial.print(F("  (rain finished)"));
    Serial.println();
  }
}

void setup() {
  Serial.begin(115200);    // debug USB
  Serial1.begin(115200);   // link cu ESP32 Mega TX1=18 RX1=19

  setupRelay(RELAY_WATER_1);
  setupSoilMoisture(SOIL_SENSOR1);
  setupTemperatureSensors();

  // tinta implicita
  targetSoilAdc = adcFromPct(targetSoilPct);
  pumpSet(false);

  Serial.println(F("MEGA: JSON RX<-ESP32 (family+weather) & TX->ESP32 (soil/temp/hum)"));
}

void loop() {
  // RX family/meteo de la ESP32
  while (Serial1.available()) {
    char c = (char)Serial1.read();
    if (c == '\n' || c == '\r') {
      if (rxIdx > 0) { rxBuf[rxIdx] = '\0'; handleEspLine(rxBuf); rxIdx = 0; }
    } else {
      if (rxIdx < sizeof(rxBuf) - 1) rxBuf[rxIdx++] = c;
      else rxIdx = 0;
    }
  }

  // masuratori
  int   soilRaw = (int)getSoilMoisture(SOIL_SENSOR1);
  int   soilPct = soilPctFromAdc(soilRaw);
  float tC      = readTemperature(DHT_PIN);
  float hPct    = readHumidity(DHT_PIN);

  // Control pompa: manual override sau auto meteo 
  if (manualWaterUntilMs) {
    if (millis() >= manualWaterUntilMs) { manualWaterUntilMs = 0; pumpSet(false); }
    else                                { pumpSet(true); }
  } else {
    if (wxRainingNow)            pumpSet(false); // acum ploua
    else if (wxWillRainToday)    pumpSet(false); // va ploua azi
    else {
      if (soilRaw > (int)targetSoilAdc + HYST_ADC)      pumpSet(true);   // prea uscat
      else if (soilRaw < (int)targetSoilAdc - HYST_ADC) pumpSet(false);  // suficient de umed
      // daca e inn banda de isterezis, se pastreaza starea curenta
    }
  }

  //Trimite linia JSON spre ESP32 (sol + temperatura + umiditate aer)
  Serial1.print(F("{\"soil_raw\":"));   Serial1.print(soilRaw);
  Serial1.print(F(",\"soil_pct\":"));   Serial1.print(soilPct);
  Serial1.print(F(",\"t_c\":"));        if (isnan(tC)) Serial1.print(F("null")); else Serial1.print(tC, 1);
  Serial1.print(F(",\"h_pct\":"));      if (isnan(hPct)) Serial1.print(F("null")); else Serial1.print((int)round(hPct));
  Serial1.println(F("}"));

  Serial.print(F("ADC=")); Serial.print(soilRaw);
  Serial.print(F(" (~"));  Serial.print(soilPct); Serial.print(F("%)"));
  Serial.print(F("  tgtADC=")); Serial.print(targetSoilAdc);
  Serial.print(F("  tgt%="));   Serial.print(targetSoilPct);
  Serial.print(F(" (±")); Serial.print(HYST_ADC); Serial.print(F(")  | pump:"));
  Serial.print(pumpOn ? F("ON") : F("OFF"));
  Serial.print(F(" | WX now=")); Serial.print(wxRainingNow?F("RAIN"):F("DRY"));
  Serial.print(F(", willToday=")); Serial.println(wxWillRainToday?F("YES"):F("NO"));

  delay(2000);
}
