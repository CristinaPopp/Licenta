// ESP primeste JSON pe Serial, ofera REST pentru Flutter (WebServer sincron)
#include <Arduino.h>
#include <ArduinoJson.h>
#include "esp_camera.h"
#include <WiFi.h>
#include <HTTPClient.h>
#include <WebServer.h>  //sincron  în loc de ESPAsyncWebServer
#include "weather.h"
#include "ai_models.h"
#include <WiFiClientSecure.h>

// Camera 
#define CAMERA_MODEL_AI_THINKER
#include "camera_pins.h"

// WiFi 
const char* ssid = "DIGI-24-215E02";
const char* password = "5E04004981";

// Web server HTTP
WebServer server(80);

// Meteo
TodayWeather WX;
WeatherConfig cfg;  // lat/lon/timezone & praguri valori implicite
WeatherClient weather(cfg);

// Buffer pentru o linie JSON primita de la Mega (UART0 pe GPIO3/1)
static char lineBuf[256];
static size_t idx = 0;

// Date primite de la Mega (ultimele valori)
struct FromMega {
  int soilRaw = -1;
  int soilPct = -1;
  float tC = NAN;    // temperatura aer
  float hPct = NAN;  // umiditate aer
} MEGA;

// Tabel simplu family umiditate sol optima
struct FamMoist {
  const char* name;
  int pct;
};
const FamMoist FAMILY_TABLE[] = {
  { "Solanaceae", 65 },
  { "Fabaceae", 55 },
  { "Asteraceae", 50 },
  { "Rosaceae", 55 },
  { "Poaceae", 45 },
  { "Cucurbitaceae", 60 },
};
const int defaultTargetPct = 55;

int lookupTargetPct(const char* family) {
  if (!family || !*family) return -1;
  for (auto& f : FAMILY_TABLE) {
    if (strcasecmp(family, f.name) == 0) return f.pct;
  }
  return defaultTargetPct;
}

void handleMegaLine(char* s) {
  // ex: {"soil_raw":612,"soil_pct":42,"t_c":23.6,"h_pct":55.0}
  StaticJsonDocument<256> doc;
  DeserializationError err = deserializeJson(doc, s);
  if (err) return;

  MEGA.soilRaw = doc["soil_raw"] | -1;
  MEGA.soilPct = doc["soil_pct"] | -1;
  MEGA.tC = doc["t_c"].is<float>() ? doc["t_c"].as<float>() : NAN;

  if (doc["h_pct"].is<float>()) MEGA.hPct = doc["h_pct"].as<float>();
  else if (doc["humidity"].is<float>()) MEGA.hPct = doc["humidity"].as<float>();
  else if (doc["h"].is<float>()) MEGA.hPct = doc["h"].as<float>();
  else MEGA.hPct = NAN;
}

float todayTotalMm() {
  float s = 0;
  for (int i = 0; i < WX.windowsCount; ++i) s += WX.windows[i].totalMm;
  return s;
}

// Nyckel (AI) 
//NyckelCreds nyCreds{
// .clientId = "gnqficn3v23jiznynfhwhum61sueefxu",
//  .clientSecret = "pgmwjsojkrk09plmmb7mgayl0jepi9pg59u2dqfvrybp9mxb67s28adei0v0ey0b",
//  .tokenUrl = "https://www.nyckel.com/connect/token",
// .insecureTLS = true
//};
NyckelCreds nyCreds{
  .clientId = "y7ak0iixq0ypbv0645iw2ohlw2d0c6h4",
  .clientSecret = "za6ddik1ptgitz0vaz9f0jz9ppoy5ikkjup0pmsllg798ysw2hpdx13fawnotmw6",
  .tokenUrl = "https://www.nyckel.com/connect/token",
  .insecureTLS = true
};

NyckelTokenCache nyTok;

const char* FUNC_INVASIVE = "invasive-plant-species";
const char* FUNC_FAMILY = "plant-family";
const int TOP_K = 3;

// Ultimele predictii
static String lastFamily = "";
static float lastFamilyOptSoil = NAN;
static String lastInvasive = "";
static float lastInvasiveScore = 0;

// helper JSON escape 
String jsonEsc(const String& s) {
  String out;
  out.reserve(s.length() + 8);
  for (size_t i = 0; i < s.length(); ++i) {
    char c = s[i];
    if (c == '"' || c == '\\') {
      out += '\\';
      out += c;
    } else if (c == '\n') {
      out += "\\n";
    } else out += c;
  }
  return out;
}

//CORS helpers
void addCORS() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET,POST,OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "Content-Type");
}
void handleOPTIONS() {
  addCORS();
  server.send(204);
}

void setup() {
  // UART0 pe pinii 3 (RX0) și 1 (TX0) 
  // ESP comunica cu Mega
  Serial.begin(115200, SERIAL_8N1, 3, 1);

  // Camera
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sccb_sda = SIOD_GPIO_NUM;
  config.pin_sccb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.frame_size = FRAMESIZE_QVGA;
  config.pixel_format = PIXFORMAT_JPEG;
  config.grab_mode = CAMERA_GRAB_WHEN_EMPTY;
  config.fb_location = CAMERA_FB_IN_PSRAM;
  config.jpeg_quality = 12;
  config.fb_count = 1;

  if (esp_camera_init(&config) != ESP_OK) {
    // daca pica camera se opreste
    return;
  }

  // WiFi
  WiFi.begin(ssid, password);
  WiFi.setSleep(false);
  while (WiFi.status() != WL_CONNECTED) { delay(250); }
  // Serial.println();
  //Serial.print("WiFi OK, IP: ");
  // Serial.println(WiFi.localIP());

  // Meteo config
  cfg.lat = 45.7928;      // Sibiu
cfg.lon = 24.1521;      // Sibiu
cfg.timezoneUrlEnc = "Europe%2FBucharest";
cfg.rainNow_mm_per_h = 0.05f;      
cfg.forecast_mm_threshold = 0.10f; // prag mai jos pentru “va ploua azi?”
cfg.forecast_prob_threshold = 50;  

  weather = WeatherClient(cfg);
  (void)weather.fetchToday(WX); 

  // RUTE 
  server.on("/telemetry", HTTP_OPTIONS, handleOPTIONS);
  server.on("/predict", HTTP_OPTIONS, handleOPTIONS);
  server.on("/water", HTTP_OPTIONS, handleOPTIONS);


  // GET /telemetry
  server.on("/telemetry", HTTP_GET, []() {
    StaticJsonDocument<384> doc;

    // airTempC: double sau null
    if (isnan(MEGA.tC)) doc["airTempC"] = nullptr;
    else doc["airTempC"] = MEGA.tC;  // ex. 30.8

    // airHum: int sau null
    if (isnan(MEGA.hPct)) doc["airHum"] = nullptr;
    else doc["airHum"] = (int)round(MEGA.hPct);

    // soilPct: int sau null (daca nu e citirea)
    if (MEGA.soilPct < 0) doc["soilPct"] = nullptr;
    else doc["soilPct"] = MEGA.soilPct;

    // weather
    JsonObject w = doc.createNestedObject("weather");
    w["precipNow"] = WX.precipNow;
    w["rainingNow"] = WX.rainingNow;
    w["willRainToday"] = WX.willRainToday;
    w["todayTotalMm"] = todayTotalMm();

    // ai
    JsonObject ai = doc.createNestedObject("ai");
    ai["family"] = lastFamily;  
    ai["familyOptimalSoil"] = isnan(lastFamilyOptSoil) ? -1 : (int)lastFamilyOptSoil;
    ai["invasive"] = lastInvasive; 
    ai["invasiveScore"] = lastInvasiveScore;

    String out;
    serializeJson(doc, out);

    addCORS();
    server.send(200, "application/json", out);
  });


  // POST /predict  — captura + Nyckel
  // POST /predict  — captura + Nyckel (invasive + family)
  server.on("/predict", HTTP_POST, []() {
    camera_fb_t* fb = esp_camera_fb_get();
    if (!fb) {
      addCORS();
      server.send(500, "application/json", "{\"error\":\"camera\"}");
      return;
    }

    String rawInv, rawFam;
    NyckelPred invPreds[TOP_K];
    int invN = 0;
    NyckelPred famPreds[TOP_K];
    int famN = 0;

    // Invasive
    if (nyckelSendImage(nyCreds, nyTok, FUNC_INVASIVE, TOP_K, fb, rawInv)) {
      invN = nyckelParseTopK(rawInv, invPreds, TOP_K);
    }
    // Family
    if (nyckelSendImage(nyCreds, nyTok, FUNC_FAMILY, TOP_K, fb, rawFam)) {
      famN = nyckelParseTopK(rawFam, famPreds, TOP_K);
    }

    esp_camera_fb_return(fb);

    // memoreaza top-1 pentru /telemetry
    if (invN > 0) {
      lastInvasive = invPreds[0].labelName;
      lastInvasiveScore = invPreds[0].confidence;
    }
    if (famN > 0) {
      lastFamily = famPreds[0].labelName;
      lastFamilyOptSoil = lookupTargetPct(lastFamily.c_str());
    }

    if (famN > 0) {
      lastFamily = famPreds[0].labelName;
      lastFamilyOptSoil = lookupTargetPct(lastFamily.c_str());

      // trimite familia la MEGA (UART0: GPIO1/3)
      StaticJsonDocument<96> m;
      m["family"] = lastFamily;
      serializeJson(m, Serial);  // Serial = legatura cu MEGA
      Serial.println();          // newline terminator
    }
    
    // raspuns JSON cu top-K
    String j = "{\"invasive\":[";
    for (int i = 0; i < invN; i++) {
      if (i) j += ",";
      j += "{\"label\":\"" + jsonEsc(invPreds[i].labelName) + "\",\"score\":" + String(invPreds[i].confidence, 3) + "}";
    }
    j += "],\"family\":[";
    for (int i = 0; i < famN; i++) {
      if (i) j += ",";
      j += "{\"label\":\"" + jsonEsc(famPreds[i].labelName) + "\",\"score\":" + String(famPreds[i].confidence, 3) + "}";
    }
    j += "]}";

    addCORS();
    server.send(200, "application/json", j);
  });



  // POST /water?seconds=10  — forward la Mega prin UART
  server.on("/water", HTTP_POST, []() {
    int seconds = 0;
    if (server.hasArg("seconds")) seconds = server.arg("seconds").toInt();
    if (seconds <= 0 || seconds > 600) {
      addCORS();
      server.send(400, "application/json", "{\"error\":\"seconds invalid\"}");
      return;
    }
    // Trimite comanda la Mega
    Serial.print("{\"cmd\":\"water\",\"seconds\":");
    Serial.print(seconds);
    Serial.println("}");

    String ok = String("{\"ok\":true,\"forwarded\":true,\"seconds\":") + seconds + "}";
    addCORS();
    server.send(200, "application/json", ok);
  });

  server.begin();
  //Serial.println("HTTP server pornit");
}

//Meteo refresh
uint32_t lastMeteo = 0;
const uint32_t METEO_PERIOD_MS = 15UL * 60UL * 1000UL;

void loop() {
  server.handleClient();  

  // 1) Citeste linii JSON de la Mega
  while (Serial.available()) {
    char c = (char)Serial.read();
    if (c == '\n' || c == '\r') {
      if (idx > 0) {
        lineBuf[idx] = '\0';
        handleMegaLine(lineBuf);
        idx = 0;
      }
    } else {
      if (idx < sizeof(lineBuf) - 1) lineBuf[idx++] = c;
      else idx = 0;  // overflow -> reset
    }
  }

  // 2) Refresh meteo periodic
  if (millis() - lastMeteo > METEO_PERIOD_MS || lastMeteo == 0) {
    lastMeteo = millis();
    if (weather.fetchToday(WX)) {
      // log optional
      Serial.print("{\"rainingNow\":");
      Serial.print(WX.rainingNow ? "true" : "false");
      Serial.print(",\"willRainToday\":");
      Serial.print(WX.willRainToday ? "true" : "false");
      Serial.println("}");
    }
  }

  delay(5);
}
