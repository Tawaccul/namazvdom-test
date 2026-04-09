import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_dependencies_scope.dart';
import 'l10n/app_localization.dart';
import 'app_scope.dart';
import 'di/app_di.dart';
import 'router/app_router.dart';
import 'router/app_routes.dart';
import 'theme/app_theme.dart';
import 'theme/app_theme_mode_controller.dart';
import '../features/onboarding/data/onboarding_repository_memory.dart';
import '../features/prayer/domain/repositories/prayer_repository.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AppThemeModeController _themeController;
  late final Future<void> _themeControllerInitFuture;
  late Future<PrayerRepository> _prayerRepositoryFuture;

  @override
  void initState() {
    super.initState();
    _themeController = AppThemeModeController();
    _themeControllerInitFuture = _themeController.init();
    _reloadDependencies();
  }

  void _reloadDependencies() {
    _prayerRepositoryFuture = AppDi.createPrayerRepository();
  }

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      themeController: _themeController,
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, _) {
          return FutureBuilder<void>(
            future: _themeControllerInitFuture,
            builder: (context, themeSnapshot) {
              return AnimatedBuilder(
                animation: _themeController,
                builder: (context, child) {
                  if (themeSnapshot.connectionState != ConnectionState.done) {
                    return MaterialApp(
                      debugShowCheckedModeBanner: false,
                      title: 'PRAYDAY',
                      theme: AppTheme.light(),
                      darkTheme: AppTheme.dark(),
                      themeMode: _themeController.mode,
                      locale: context.locale,
                      supportedLocales: context.supportedLocales,
                      localizationsDelegates: context.localizationDelegates,
                      home: const _BootstrapLoadingScreen(),
                    );
                  }

                  return FutureBuilder(
                    future: _prayerRepositoryFuture,
                    builder: (context, snapshot) {
                      final repo = snapshot.data;
                      if (snapshot.hasError) {
                        return MaterialApp(
                          debugShowCheckedModeBanner: false,
                          title: 'PRAYDAY',
                          theme: AppTheme.light(),
                          darkTheme: AppTheme.dark(),
                          themeMode: _themeController.mode,
                          locale: context.locale,
                          supportedLocales: context.supportedLocales,
                          localizationsDelegates: context.localizationDelegates,
                          home: _BootstrapErrorScreen(
                            error: snapshot.error,
                            onRetry: () => setState(_reloadDependencies),
                          ),
                        );
                      }

                      if (!snapshot.hasData || repo == null) {
                        return MaterialApp(
                          debugShowCheckedModeBanner: false,
                          title: 'PRAYDAY',
                          theme: AppTheme.light(),
                          darkTheme: AppTheme.dark(),
                          themeMode: _themeController.mode,
                          locale: context.locale,
                          supportedLocales: context.supportedLocales,
                          localizationsDelegates: context.localizationDelegates,
                          home: const _BootstrapLoadingScreen(),
                        );
                      }

                      return AppDependenciesScope(
                        prayerRepository: repo,
                        child: MaterialApp(
                          debugShowCheckedModeBanner: false,
                          title: 'PRAYDAY',
                          theme: AppTheme.light(),
                          darkTheme: AppTheme.dark(),
                          themeMode: _themeController.mode,
                          locale: context.locale,
                          supportedLocales: context.supportedLocales,
                          localizationsDelegates:
                              context.localizationDelegates,
                          onGenerateRoute: AppRouter.onGenerateRoute,
                          initialRoute:
                              OnboardingRepositoryMemory
                                      .instance
                                      .hasCompletedStart
                                  ? AppRoutes.home
                                  : AppRoutes.onboardingStart,
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _BootstrapLoadingScreen extends StatelessWidget {
  const _BootstrapLoadingScreen();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              context.t('app.loading'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _BootstrapErrorScreen extends StatelessWidget {
  const _BootstrapErrorScreen({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.t('app.failedToStart'),
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                (error ?? context.t('app.unknownError')).toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                ),
                child: Text(context.t('common.retry')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
