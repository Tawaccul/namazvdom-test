import 'package:flutter/material.dart';

import '../l10n/app_localization.dart';
import '../../features/home/home_screen.dart';
import '../../features/onboarding/data/onboarding_repository_memory.dart';
import '../../features/onboarding/presentation/onboarding_start_screen.dart';
import '../../features/settings/language/presentation/language_screen.dart';
import '../../features/splash/presentation/app_launch_splash_screen.dart';
import '../../features/stage/stage_splash_screen.dart';
import 'app_route_args.dart';
import 'app_routes.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.appSplash:
        return MaterialPageRoute(builder: (_) => const AppLaunchSplashScreen());
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case AppRoutes.onboardingStart:
        return MaterialPageRoute(
          builder: (context) => OnboardingStartScreen(
            onNext: () {
              OnboardingRepositoryMemory.instance.completeStartOnboarding();
              OnboardingRepositoryMemory.instance.triggerStageOnboarding();
              Navigator.of(context).pushReplacementNamed(AppRoutes.home);
            },
          ),
        );
      case AppRoutes.onboardingMadhhab:
        return MaterialPageRoute(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              OnboardingRepositoryMemory.instance.triggerStageOnboarding();
              Navigator.of(context).pushReplacementNamed(AppRoutes.home);
            });
            return const Scaffold(body: SizedBox.shrink());
          },
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
        return MaterialPageRoute(
          builder: (context) {
            final stageArgs = args is StageSplashArgs
                ? args
                : StageSplashArgs(
                    prayerCode: 'fajr',
                    prayerTitle: localizedPrayerLabel(context, 'fajr'),
                  );
            return StageSplashScreen(
              prayerCode: stageArgs.prayerCode,
              prayerTitle: localizedPrayerLabel(
                context,
                stageArgs.prayerCode,
                fallbackTitle: stageArgs.prayerTitle,
              ),
            );
          },
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
