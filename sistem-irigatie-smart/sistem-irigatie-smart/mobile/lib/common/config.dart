class AppConfig {
  static String apiBase = 'http://localhost:8000';
  static String mqttHost = 'localhost';
  static int mqttPort = 9001; //pentru WebSocket cand vom folosi MQTT din browser
}

//Reguli simplificate pentru irigar
class AppRules {
  //Prag minim dorit pentru umiditatea solului(%)
  static double soilMin = 70;

  //Ritmul mediu de scadere a umiditatii solului(% pe oră).
  //mock momentan
  static double soilDecayPerHour = 6;

  //Daca prognoza anunta ploaie în mai putin de x ore, amanam udarea
  static int rainDeferralHours = 6;
}
