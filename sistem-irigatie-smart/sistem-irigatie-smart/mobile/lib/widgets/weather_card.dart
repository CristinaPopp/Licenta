import 'package:flutter/material.dart';

class WeatherCard extends StatelessWidget {
  final bool rainingNow;
  final bool willRainToday;
  final double precipNow;     
  final double todayTotalMm; 

  const WeatherCard({
    super.key,
    required this.rainingNow,
    required this.willRainToday,
    required this.precipNow,
    required this.todayTotalMm,
  });

  String _yesNo(bool v) => v ? 'Da' : 'Nu';
  String _num(num v, {int frac = 2, String unit = ''}) =>
      '${v.toStringAsFixed(frac)}$unit';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget chip(IconData icon, String label, String value,
        {bool highlight = false}) {
      final bg = highlight
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surface;
      final fg = highlight
          ? theme.colorScheme.onPrimaryContainer
          : theme.colorScheme.onSurfaceVariant;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
          Text('$label: ', style: theme.textTheme.bodyMedium?.copyWith(color: fg)),
          Text(value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600, color: fg)),
        ]),
      );
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.cloud_outlined, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Text('Meteo', style: theme.textTheme.titleLarge),
          ]),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              chip(Icons.cloud, 'Plouă acum', _yesNo(rainingNow),
                  highlight: rainingNow),
              chip(Icons.water_drop, 'Va ploua azi', _yesNo(willRainToday),
                  highlight: willRainToday),
              chip(Icons.opacity, 'Intensitate', _num(precipNow, frac: 2, unit: ' mm/h')),
              chip(Icons.toll, 'Total azi', _num(todayTotalMm, frac: 2, unit: ' mm')),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
             
              value: (precipNow.clamp(0, 5) / 5),
              minHeight: 8,
              backgroundColor: theme.colorScheme.surface.withOpacity(.5),
            ),
          ),
        ]),
      ),
    );
  }
}
