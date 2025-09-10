import 'package:flutter/material.dart';

class StatTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final String? subtitle;

  const StatTile({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: icon != null ? Icon(icon) : null,
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
