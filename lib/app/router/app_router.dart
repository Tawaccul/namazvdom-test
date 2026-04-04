import 'package:flutter/material.dart';

import '../l10n/app_localization.dart';
import '../../features/home/home_screen.dart';
import '../../features/onboarding/data/onboarding_repository_memory.dart';
import '../../features/onboarding/presentation/onboarding_madhhab_screen.dart';
import '../../features/onboarding/presentation/onboarding_start_screen.dart';
import '../../features/settings/language/presentation/language_screen.dart';
import '../../features/stage/stage_splash_screen.dart';
import 'app_route_args.dart';
import 'app_routes.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case AppRoutes.onboardingStart:
        return MaterialPageRoute(
          builder: (context) => OnboardingStartScreen(
            onNext: () {
              Navigator.of(
                context,
              ).pushReplacementNamed(AppRoutes.onboardingMadhhab);
            },
          ),
        );
      case AppRoutes.onboardingMadhhab:
        return MaterialPageRoute(
          builder: (context) => OnboardingMadhhabScreen(
            onNext: () {
              OnboardingRepositoryMemory.instance.triggerStageOnboarding();
              Navigator.of(context).pushReplacementNamed(AppRoutes.home);
            },
          ),
        );
      case AppRoutes.onboardingLanguage:
        return MaterialPageRoute(
          builder: (context) => LanguageScreen(
            mode: LanguageScreenMode.onboarding,
            onCompleted: () {
              OnboardingRepositoryMemory.instance.triggerStageOnboarding();
              Navigator.of(context).pushReplacementNamed(AppRoutes.home);
            },
          ),
        );
      case AppRoutes.stageSplash:
        final args = settings.arguments;
        final stageArgs = args is StageSplashArgs
            ? args
            : const StageSplashArgs(prayerCode: 'fajr', prayerTitle: 'Fajr');
        return MaterialPageRoute(
          builder: (_) => StageSplashScreen(
            prayerCode: stageArgs.prayerCode,
            prayerTitle: stageArgs.prayerTitle,
          ),
        );
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
      body: Center(
        child: Text(
          context.t(
            'app.unknownRoute',
            namedArgs: {'route': routeName ?? '(null)'},
          ),
        ),
      ),
    );
  }
}
