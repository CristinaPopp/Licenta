import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  final ApiService api;
  Telemetry? latest;
  final List<Telemetry> history = [];

  Timer? _timer;

  AppState(this.api);

  void startPolling({Duration every = const Duration(seconds: 10)}) {
    _timer?.cancel();
    _timer = Timer.periodic(every, (_) => _pullOnce());
    _pullOnce(); //imediat
  }

  Future<void> _pullOnce() async {
    try {
      final t = await api.fetchTelemetry();
      latest = t;
      history.add(t);
      if (history.length > 200) history.removeAt(0);
      notifyListeners();
    } catch (_) {
      //ignore sau log
    }
  }

  Future<void> waterFor(int seconds) async {
    await api.startWatering(seconds);
  }

  Future<void> refreshPredictions() async {
    await api.runPredict();
    await _pullOnce();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
