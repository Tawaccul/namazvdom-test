import 'package:flutter/material.dart';

import '../../features/stage/stage_splash_screen.dart';

abstract class AppRoutes {
  static const splash = '/';
}

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const StageSplashScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => _UnknownRouteScreen(routeName: settings.name),
        );
    }
  }
}

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen({required this.routeName});

  final String? routeName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Unknown route: ${routeName ?? "(null)"}')),
    );
  }
}
