class Telemetry {
  final DateTime ts;
  final double airTempC;
  final int airHum;
  final int soilPct;
  final double precipNow;
  final bool rainingNow;
  final bool willRainToday;
  final double todayTotalMm;
  final String family;
  final int familyOptimalSoil;
  final String invasive;
  final double invasiveScore;

  Telemetry({
    required this.ts,
    required this.airTempC,
    required this.airHum,
    required this.soilPct,
    required this.precipNow,
    required this.rainingNow,
    required this.willRainToday,
    required this.todayTotalMm,
    required this.family,
    required this.familyOptimalSoil,
    required this.invasive,
    required this.invasiveScore,
  });

  factory Telemetry.fromJson(Map<String, dynamic> j) {
    final ai = j['ai'] ?? {};
    final w  = j['weather'] ?? {};
    return Telemetry(
      ts: DateTime.now(),
      airTempC: (j['airTempC'] ?? double.nan).toDouble(),
      airHum: (j['airHum'] ?? 0).toInt(),
      soilPct: (j['soilPct'] ?? 0).toInt(),
      precipNow: (w['precipNow'] ?? 0).toDouble(),
      rainingNow: (w['rainingNow'] ?? false) == true,
      willRainToday: (w['willRainToday'] ?? false) == true,
      todayTotalMm: (w['todayTotalMm'] ?? 0).toDouble(),
      family: (ai['family'] ?? '') as String,
      familyOptimalSoil: ((ai['familyOptimalSoil'] ?? -1) as num).toInt(),
      invasive: (ai['invasive'] ?? '') as String,
      invasiveScore: (ai['invasiveScore'] ?? 0).toDouble(),
    );
  }
}
