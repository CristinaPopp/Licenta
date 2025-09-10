#ifndef AI_MODELS_H
#define AI_MODELS_H

#include <Arduino.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include "esp_camera.h"

struct NyckelCreds {
  String clientId;
  String clientSecret;
  String tokenUrl = "https://www.nyckel.com/connect/token";
  bool   insecureTLS = true;// pentru test
};

struct NyckelTokenCache {
  String accessToken;
  unsigned long tsMs = 0; //cand e primit tokenul
  unsigned long ttlMs = 50UL * 60UL * 1000UL; // reinnoire cu aprox 50m (înainte de 60m)
};

bool nyckelEnsureToken(const NyckelCreds& creds, NyckelTokenCache& cache);

bool nyckelSendImage(const NyckelCreds& creds,
                     NyckelTokenCache& cache,
                     const String& functionId,
                     int labelCount,
                     camera_fb_t* fb,
                     String& responseOut);

/// se face captura si apoi cheama nyckelSendImage().
bool nyckelCaptureAndSend(const NyckelCreds& creds,
                          NyckelTokenCache& cache,
                          const String& functionId,
                          int labelCount,
                          String& responseOut,
                          uint8_t flashPin = 255,
                          uint16_t flashMs = 0);


struct NyckelPred { String labelName; float confidence = 0.0f; };
int nyckelParseTopK(const String& json, NyckelPred* out, int maxOut);

#endif

