import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routes/app_router.dart';
import 'common/app_state.dart';
import 'common/api_service.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    //seteaza IP-ul ESP(din Serial Monitor:WiFi.localIP())
    const String espBaseUrl = 'http://192.168.1.109';
    const bool useSimulator = false; //pune true doar daca e o metoda startSimulator()

    return ChangeNotifierProvider(
      create: (_) {
        final api = ApiService(espBaseUrl);
        final state = AppState(api);
        state.startPolling(every: const Duration(seconds: 8));
        return state;
      },
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Greenhouse',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
        routerConfig: AppRouter.router,
      ),
    );
  }
}
