#include "Weather.h"
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

WeatherClient::WeatherClient(const WeatherConfig& cfg) : cfg_(cfg) {}

String WeatherClient::buildUrl() const {
  String url = F("https://api.open-meteo.com/v1/forecast?");
  url += "latitude=";  url += String(cfg_.lat, 6);
  url += "&longitude="; url += String(cfg_.lon, 6);
  url += "&current=temperature_2m,relative_humidity_2m,precipitation,wind_speed_10m,weather_code";
  url += "&hourly=precipitation,precipitation_probability";
  url += "&forecast_days=1";
  url += "&timeformat=iso8601";
  url += "&precipitation_unit=mm";
  url += "&timezone="; url += cfg_.timezoneUrlEnc; 
  return url;
}

bool WeatherClient::fetchJsonPayload(String& payload) {
  WiFiClientSecure client;
  client.setTimeout(cfg_.httpTimeoutMs);
  if (cfg_.insecureTLS) {
    client.setInsecure(); 
  }
  HTTPClient http;
  String url = buildUrl();
  if (!http.begin(client, url)) {
    return false;
  }
  int code = http.GET();
  if (code != 200) {
    http.end();
    return false;
  }
  payload = http.getString();
  http.end();
  return true;
}

bool WeatherClient::fetchToday(TodayWeather& out) {
  String payload;
  if (!fetchJsonPayload(payload)) return false;

  DynamicJsonDocument doc(60000);
  if (deserializeJson(doc, payload)) return false;

  JsonObject cur = doc["current"];
  if (cur.isNull()) return false;

  out.currentISO  = String((const char*)cur["time"]);          // ex. 2025-03-26T14:23
  out.currentDate = out.currentISO.substring(0, 10);           // 2025-03-26
  out.tempC       = cur["temperature_2m"]        | NAN;
  out.rh          = cur["relative_humidity_2m"]  | NAN;
  out.wind        = cur["wind_speed_10m"]        | NAN;
  out.precipNow   = cur["precipitation"]         | NAN;
  out.rainingNow  = (!isnan(out.precipNow) && out.precipNow > cfg_.rainNow_mm_per_h);

  JsonArray times = doc["hourly"]["time"];
  JsonArray prec  = doc["hourly"]["precipitation"];
  JsonArray prob  = doc["hourly"]["precipitation_probability"];


  String nowHour = out.currentISO.substring(0, 13);
  int idxNow = -1;
  for (size_t i = 0; i < times.size(); ++i) {
    const char* ts = times[i];
    if (!ts) continue;
    String hour = String(ts).substring(0, 13);
    if (hour == nowHour) { idxNow = (int)i; break; }
  }
  if (idxNow < 0) idxNow = 0; // fallback: de la începutul zilei

  out.willRainToday = false;
  out.windowsCount  = 0;
  bool inWindow     = false;
  RainWindow w{};

  for (size_t i = idxNow; i < times.size(); ++i) {
    const char* ts = times[i];
    if (!ts) continue;
    String tISO = String(ts);
    if (tISO.substring(0, 10) != out.currentDate) break; // doar orele de azi

    // Protejeaza accesul array-urile pot fi mai scurte sau lipsa
    float pmm = (i < prec.size() && prec[i].is<float>()) ? prec[i].as<float>() : 0.0f;
    int   pp  = (i < prob.size() && prob[i].is<int>())   ? prob[i].as<int>()   : 0;


    bool rainy = (pmm >= cfg_.forecast_mm_threshold) || (pp >= cfg_.forecast_prob_threshold);
    if (rainy) out.willRainToday = true;

    if (rainy && !inWindow) {
      inWindow = true;
      w = RainWindow{};
      w.startISO = tISO;
      w.endISO   = tISO;
      w.totalMm  = pmm;
      w.hours    = 1;
    } else if (rainy && inWindow) {
      w.endISO   = tISO;
      w.totalMm += pmm;
      w.hours   += 1;
    } else if (!rainy && inWindow) {
      if (out.windowsCount < TodayWeather::MAX_WINDOWS) out.windows[out.windowsCount++] = w;
      inWindow = false;
    }
  }
  if (inWindow && out.windowsCount < TodayWeather::MAX_WINDOWS) out.windows[out.windowsCount++] = w;

  return true;
}


const char* WeatherClient::weatherCodeToText(int c) {
  if (c == 0) return "senin";
  if (c >= 1 && c <= 3) return "variabil";
  if (c == 45 || c == 48) return "ceata";
  if (c == 51 || c == 53 || c == 55) return "burnita";
  if (c == 61 || c == 63 || c == 65) return "ploaie";
  if (c == 66 || c == 67) return "ploaie inghetata";
  if (c == 71 || c == 73 || c == 75) return "ninsoare";
  if (c == 80 || c == 81 || c == 82) return "averse";
  if (c == 85 || c == 86) return "averse de ninsoare";
  if (c == 95) return "furtuna";
  if (c == 96 || c == 99) return "furtuna cu grindina";
  return "necunoscut";
}
