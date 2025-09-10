import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/app_state.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final hist = context.watch<AppState>().history.reversed.toList(); //cele mai noi sus
    return Scaffold(
      appBar: AppBar(title: const Text('Istoric')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: hist.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final r = hist[i];
          final hh = r.ts.hour.toString().padLeft(2, '0');
          final mm = r.ts.minute.toString().padLeft(2, '0');
          return Card(
            child: ListTile(
              leading: const Icon(Icons.timeline),
              title: Text(
                '$hh:$mm  •  T:${r.airTempC.toStringAsFixed(1)}°C  H:${r.airHum}%  Soil:${r.soilPct}%'
              ),
              subtitle: Text(r.ts.toIso8601String()),
            ),
          );
        },
      ),
    );
  }
}
