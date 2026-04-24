import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_dependencies_scope.dart';
import 'platform/app_launcher_icon_controller.dart';
import 'l10n/app_localization.dart';
import 'app_scope.dart';
import 'di/app_di.dart';
import 'router/app_router.dart';
import 'router/app_routes.dart';
import 'theme/app_theme.dart';
import 'theme/app_theme_mode_controller.dart';
import '../features/prayer/domain/repositories/prayer_repository.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  late final AppThemeModeController _themeController;
  late final Future<void> _themeControllerInitFuture;
  late Future<PrayerRepository> _prayerRepositoryFuture;
  late final AppLauncherIconController _launcherIconController;
  int _launcherIconSyncToken = 0;
  bool _didBootstrapIconSync = false;

  Widget _withFixedTextScale(BuildContext context, Widget? child) {
    final mediaQuery = MediaQuery.of(context);
    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: const TextScaler.linear(1)),
      child: child ?? const SizedBox.shrink(),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _themeController = AppThemeModeController();
    _themeControllerInitFuture = _themeController.init();
    _launcherIconController = AppLauncherIconController();
    _themeController.addListener(_handleThemeModeChanged);
    _themeControllerInitFuture.then((_) => _syncLauncherIconWithRetry());
    _reloadDependencies();
  }

  void _reloadDependencies() {
    _prayerRepositoryFuture = AppDi.createPrayerRepository();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _themeController.removeListener(_handleThemeModeChanged);
    _themeController.dispose();
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    if (_themeController.mode == ThemeMode.system) {
      _syncLauncherIconWithRetry();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncLauncherIconWithRetry();
    }
  }

  void _handleThemeModeChanged() {
    _syncLauncherIconWithRetry();
  }

  void _syncLauncherIconWithRetry() {
    final token = ++_launcherIconSyncToken;
    unawaited(_syncLauncherIcon());
    Future<void>.delayed(const Duration(milliseconds: 280), () {
      if (!mounted || token != _launcherIconSyncToken) return;
      unawaited(_syncLauncherIcon());
    });
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted || token != _launcherIconSyncToken) return;
      unawaited(_syncLauncherIcon());
    });
  }

  Future<void> _syncLauncherIcon() async {
    if (!mounted) return;
    if (defaultTargetPlatform != TargetPlatform.android) {
      await _launcherIconController.setDarkIconEnabled(false);
      return;
    }
    final platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final isDark = switch (_themeController.mode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => platformBrightness == Brightness.dark,
    };
    await _launcherIconController.setDarkIconEnabled(isDark);
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
                      title: 'PrayDay',
                      builder: _withFixedTextScale,
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
                          title: 'PrayDay',
                          builder: _withFixedTextScale,
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
                          title: 'PrayDay',
                          builder: _withFixedTextScale,
                          theme: AppTheme.light(),
                          darkTheme: AppTheme.dark(),
                          themeMode: _themeController.mode,
                          locale: context.locale,
                          supportedLocales: context.supportedLocales,
                          localizationsDelegates: context.localizationDelegates,
                          home: const _BootstrapLoadingScreen(),
                        );
                      }

                      if (!_didBootstrapIconSync) {
                        _didBootstrapIconSync = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          _syncLauncherIconWithRetry();
                        });
                      }

                      return AppDependenciesScope(
                        prayerRepository: repo,
                        child: MaterialApp(
                          debugShowCheckedModeBanner: false,
                          title: 'PrayDay',
                          builder: _withFixedTextScale,
                          theme: AppTheme.light(),
                          darkTheme: AppTheme.dark(),
                          themeMode: _themeController.mode,
                          locale: context.locale,
                          supportedLocales: context.supportedLocales,
                          localizationsDelegates: context.localizationDelegates,
                          onGenerateRoute: AppRouter.onGenerateRoute,
                          initialRoute: AppRoutes.appSplash,
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
