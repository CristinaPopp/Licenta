import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/stat_tile.dart';
import '../../common/app_state.dart';
import '../../widgets/weather_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final latest = context.watch<AppState>().latest;

    String tempText() {
      if (latest == null) return '—';
      final t = latest.airTempC;
      if (t.isNaN) return '—';
      return '${t.toStringAsFixed(1)}°C';
    }

    String airHumText() =>
        latest == null ? '—' : '${latest.airHum}%';

    String soilText() =>
        latest == null ? '—' : '${latest.soilPct}%';

    String? soilSubtitle() {
      if (latest == null) return null;
      if (latest.familyOptimalSoil >= 0 && latest.family.isNotEmpty) {
        return 'Optim pt ${latest.family}: ~${latest.familyOptimalSoil}%';
      }
      return null;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Acasa')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StatTile(
              title: 'Temperatura aer',
              value: tempText(),
              icon: Icons.thermostat,
            ),
            StatTile(
              title: 'Umiditate aer',
              value: airHumText(),
              icon: Icons.water_drop_outlined,
            ),
            StatTile(
              title: 'Umiditate sol',
              value: soilText(),
              subtitle: soilSubtitle(),
              icon: Icons.grass,
            ),

            const SizedBox(height: 8),
            if (latest != null) WeatherCard(
              rainingNow:    latest.rainingNow,
              willRainToday: latest.willRainToday,
              precipNow:     latest.precipNow,
              todayTotalMm:  latest.todayTotalMm,
            ) else Card(
              elevation: 0,
              child: ListTile(
                leading: const Icon(Icons.cloud_outlined),
                title: const Text('Meteo'),
                subtitle: const Text('—'),
              ),
            ),

            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: latest == null
                  ? null
                  : () async {
                      try {
                        await context.read<AppState>().waterFor(10);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Udare pornita 10s')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Eroare udare: $e')),
                          );
                        }
                      }
                    },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Porneste udarea 10s'),
            ),
          ],
        ),
      ),
    );
  }
}
