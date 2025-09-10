#ifndef WEATHER_H
#define WEATHER_H

#include <Arduino.h>

/**
 * Simple ESP32 Weather client for Open-Meteo.
 * Fetches "current" and "hourly" (precipitation & probability) for TODAY,
 * computes:
 *  - rainingNow: based on current precipitation rate
 *  - willRainToday: if any remaining hour today meets thresholds
 *  - rain windows: continuous intervals [startISO, endISO] with total mm
 *
 * Dependencies (add via Library Manager):
 *  - ArduinoJson
 *  - (Core) WiFiClientSecure, HTTPClient
 */

struct RainWindow {
  String startISO;
  String endISO;
  float  totalMm = 0.0f;
  int    hours   = 0;
};

struct TodayWeather {
  // current
  String currentISO;     // e.g., "2025-08-11T14:00"
  String currentDate;    // "YYYY-MM-DD"
  float  tempC      = NAN;
  float  rh         = NAN;
  float  wind       = NAN;
  float  precipNow  = NAN;   // mm/h
  bool   rainingNow = false;

  // forecast
  bool   willRainToday = false;

  // windows of rain for the rest of today
  static const int MAX_WINDOWS = 16;
  int    windowsCount = 0;
  RainWindow windows[MAX_WINDOWS];
};

struct WeatherConfig {
  double    lat = 45.7982;//44.4268;
  double    lon = 24.1256;//26.1025;
  const char* timezoneUrlEnc = "Europe%2FBucharest";
  uint32_t  httpTimeoutMs = 15000;

  // thresholds
  float rainNow_mm_per_h        = 0.05f; // > this => "raining now"
  float forecast_mm_threshold   = 0.10f; // an hour with >= this means "rain hour"
  int   forecast_prob_threshold = 10;    // or precip probability >= this (%)

  bool insecureTLS = true; // set to false and use certificate pinning for production
};

class WeatherClient {
public:
  explicit WeatherClient(const WeatherConfig& cfg);

  // Fetch current + hourly for TODAY and populate 'out'.
  // Returns true on success.
  bool fetchToday(TodayWeather& out);

  // Optional helper: textual description for Open-Meteo weather codes (subset)
  static const char* weatherCodeToText(int code);

private:
  WeatherConfig cfg_;
  bool fetchJsonPayload(String& payload);
  String buildUrl() const;
};

#endif // WEATHER_H
