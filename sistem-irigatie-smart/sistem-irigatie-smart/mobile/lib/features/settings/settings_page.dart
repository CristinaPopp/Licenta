import 'package:flutter/material.dart';
import '../../common/config.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController apiCtrl;
  late final TextEditingController hostCtrl;
  late final TextEditingController portCtrl;

  @override
  void initState() {
    super.initState();
    apiCtrl = TextEditingController(text: AppConfig.apiBase);
    hostCtrl = TextEditingController(text: AppConfig.mqttHost);
    portCtrl = TextEditingController(text: AppConfig.mqttPort.toString());
  }

  @override
  void dispose() {
    apiCtrl.dispose(); hostCtrl.dispose(); portCtrl.dispose();
    super.dispose();
  }

  void _save() {
    setState(() {
      AppConfig.apiBase = apiCtrl.text.trim();
      AppConfig.mqttHost = hostCtrl.text.trim();
      AppConfig.mqttPort = int.tryParse(portCtrl.text.trim()) ?? AppConfig.mqttPort;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Setări salvate (runtime)')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setări')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: apiCtrl, decoration: const InputDecoration(labelText: 'API Base (ex: http://localhost:8000)')),
            const SizedBox(height: 12),
            TextField(controller: hostCtrl, decoration: const InputDecoration(labelText: 'MQTT Host (ex: localhost)')),
            const SizedBox(height: 12),
            TextField(controller: portCtrl, decoration: const InputDecoration(labelText: 'MQTT Port (ex: 9001 - WebSocket)')),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Salvează')),
          ],
        ),
      ),
    );
  }
}
