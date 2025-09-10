import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/home/home_page.dart';
import '../features/weeds/weeds_page.dart';
import '../features/plants/plants_page.dart';
import '../features/history/history_page.dart';
import '../features/settings/settings_page.dart';

class AppRouter {
  static final _rootKey = GlobalKey<NavigatorState>();
  static final _shellKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

  static final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/home',
    routes: [
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) {
          final idx = _locationToIndex(state.uri.path);
          return Scaffold(
            body: child,
            bottomNavigationBar: NavigationBar(
              selectedIndex: idx,
              onDestinationSelected: (i) => _onTapNav(context, i),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Acasă'),
                NavigationDestination(icon: Icon(Icons.grass), label: 'Buruieni'),
                NavigationDestination(icon: Icon(Icons.local_florist), label: 'Plante'),
                NavigationDestination(icon: Icon(Icons.timeline), label: 'Istoric'),
               // NavigationDestination(icon: Icon(Icons.settings), label: 'Setări'),
              ],
            ),
          );
        },
        routes: [
          GoRoute(path: '/home',     builder: (_, __) => const HomePage()),
          GoRoute(path: '/weeds',    builder: (_, __) => const WeedsPage()),
          GoRoute(path: '/plants',   builder: (_, __) => const PlantsPage()),
          GoRoute(path: '/history',  builder: (_, __) => const HistoryPage()),
         // GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
        ],
      ),
    ],
  );

  static int _locationToIndex(String loc) {
    switch (loc) {
      case '/home': return 0;
      case '/weeds': return 1;
      case '/plants': return 2;
      case '/history': return 3;
     // case '/settings': return 4;
      default: return 0;
    }
  }

  static void _onTapNav(BuildContext context, int i) {
    switch (i) {
      case 0: context.go('/home'); break;
      case 1: context.go('/weeds'); break;
      case 2: context.go('/plants'); break;
      case 3: context.go('/history'); break;
      //case 4: context.go('/settings'); break;
    }
  }
}
