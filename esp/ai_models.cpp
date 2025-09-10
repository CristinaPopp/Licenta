#include "ai_models.h"

static String buildInvokeUrl(const String& functionId, int labelCount) {
  String u = "https://www.nyckel.com/v1/functions/";
  u += functionId;
  u += "/invoke";
  if (labelCount > 0) { u += "?labelCount="; u += labelCount; }
  return u;
}

bool nyckelEnsureToken(const NyckelCreds& creds, NyckelTokenCache& cache) {
  if (cache.accessToken.length() && (millis() - cache.tsMs) < cache.ttlMs) return true;

  WiFiClientSecure client;
  client.setTimeout(15000);
  if (creds.insecureTLS) client.setInsecure();

  HTTPClient http;
  if (!http.begin(client, creds.tokenUrl)) return false;
  http.addHeader("Content-Type", "application/x-www-form-urlencoded");

  String body = "grant_type=client_credentials";
  body += "&client_id=" + creds.clientId;
  body += "&client_secret=" + creds.clientSecret;

  int code = http.POST(body);
  if (code != 200) { http.end(); return false; }
  String resp = http.getString();
  http.end();

  StaticJsonDocument<1024> doc;
  auto err = deserializeJson(doc, resp);
  if (err) return false;

  cache.accessToken = String((const char*)doc["access_token"]);
  if (!cache.accessToken.length()) return false;

  unsigned long exp = doc["expires_in"] | 3600UL;
  cache.tsMs = millis();
  cache.ttlMs = (exp > 120 ? (exp - 60) : exp) * 1000UL; 
  return true;
}

bool nyckelSendImage(const NyckelCreds& creds,
                     NyckelTokenCache& cache,
                     const String& functionId,
                     int labelCount,
                     camera_fb_t* fb,
                     String& responseOut) {
  if (!fb) return false;
  if (!nyckelEnsureToken(creds, cache)) return false;

  String url = buildInvokeUrl(functionId, labelCount);

  WiFiClientSecure client;
  client.setTimeout(20000);
  if (creds.insecureTLS) client.setInsecure();

  HTTPClient http;
  if (!http.begin(client, url)) return false;

  http.addHeader("Authorization", "Bearer " + cache.accessToken);

  // multipart/form-data (buffer simplu - foloseste PSRAM la ESP)
  const String boundary = "NyckelBoundary";
  http.addHeader("Content-Type", "multipart/form-data; boundary=" + boundary);

  String head = "--" + boundary + "\r\n";
  head += "Content-Disposition: form-data; name=\"data\"; filename=\"frame.jpg\"\r\n";
  head += "Content-Type: image/jpeg\r\n\r\n";
  String tail = "\r\n--" + boundary + "--\r\n";

  const int totalLen = head.length() + fb->len + tail.length();
  uint8_t* buf = (uint8_t*)malloc(totalLen);
  if (!buf) { http.end(); return false; }

  memcpy(buf, head.c_str(), head.length());
  memcpy(buf + head.length(), fb->buf, fb->len);
  memcpy(buf + head.length() + fb->len, tail.c_str(), tail.length());

  int code = http.POST(buf, totalLen);
  free(buf);

  bool ok = false;
  if (code > 0) {
    responseOut = http.getString();
    ok = (code == 200);
  }
  http.end();
  return ok;
}

bool nyckelCaptureAndSend(const NyckelCreds& creds,
                          NyckelTokenCache& cache,
                          const String& functionId,
                          int labelCount,
                          String& responseOut,
                          uint8_t flashPin,
                          uint16_t flashMs) {
  if (flashPin != 255 && flashMs > 0) {
    pinMode(flashPin, OUTPUT);
    digitalWrite(flashPin, HIGH);
    delay(flashMs);
    digitalWrite(flashPin, LOW);
  }
  camera_fb_t* fb = esp_camera_fb_get();
  if (!fb) return false;
  bool ok = nyckelSendImage(creds, cache, functionId, labelCount, fb, responseOut);
  esp_camera_fb_return(fb);
  return ok;
}

int nyckelParseTopK(const String& json, NyckelPred* out, int maxOut) {
  if (!out || maxOut <= 0) return 0;

  // buffer mai generos daca Nyckel returneaza campuri extra
  StaticJsonDocument<4096> doc;
  DeserializationError err = deserializeJson(doc, json);
  if (err) {
    Serial.print("[NYCKEL] JSON parse error: ");
    Serial.println(err.c_str());
    Serial.println("[NYCKEL] RAW: " + json);
    return 0;
  }

  // Caz 1: array de predictii
  if (doc.is<JsonArray>()) {
    int i = 0;
    for (JsonObject p : doc.as<JsonArray>()) {
      if (i >= maxOut) break;
      out[i].labelName  = String(p["labelName"]  | "");
      out[i].confidence = (float)(double)(p["confidence"] | 0.0);
      ++i;
    }
    if (i == 0) {
      Serial.println("[NYCKEL] Empty predictions array.");
      Serial.println("[NYCKEL] RAW: " + json);
    }
    return i;
  }

  // Caz 2: obiect unic (top-1)
  if (doc.is<JsonObject>()) {
    JsonObject p = doc.as<JsonObject>();
    out[0].labelName  = String(p["labelName"]  | "");
    out[0].confidence = (float)(double)(p["confidence"] | 0.0);
    if (out[0].labelName.length() == 0) {
      Serial.println("[NYCKEL] Object but missing fields.");
      Serial.println("[NYCKEL] RAW: " + json);
      return 0;
    }
    return 1;
  }

  Serial.println("[NYCKEL] Unexpected JSON type.");
  Serial.println("[NYCKEL] RAW: " + json);
  return 0;
}

