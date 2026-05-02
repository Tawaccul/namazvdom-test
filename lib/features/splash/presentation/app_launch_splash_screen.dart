import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../app/router/app_routes.dart';
import '../../content/data/app_content_preloader.dart';
import '../../onboarding/data/onboarding_repository_memory.dart';

class AppLaunchSplashScreen extends StatefulWidget {
  const AppLaunchSplashScreen({super.key});

  @override
  State<AppLaunchSplashScreen> createState() => _AppLaunchSplashScreenState();
}

class _AppLaunchSplashScreenState extends State<AppLaunchSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  bool _navigated = false;
  bool _animationCompleted = false;
  bool _contentPreloadCompleted = false;
  bool _contentPreloadStarted = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this)
      ..addStatusListener(_handleStatusChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_contentPreloadStarted) return;
    _contentPreloadStarted = true;
    unawaited(_preloadContent());
  }

  @override
  void dispose() {
    _animationController
      ..removeStatusListener(_handleStatusChanged)
      ..dispose();
    super.dispose();
  }

  void _handleStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _animationCompleted = true;
    _navigateWhenReady();
  }

  Future<void> _preloadContent() async {
    try {
      await AppContentPreloader.preload(context);
    } catch (_) {
      // Local assets are the fallback if startup sync cannot complete.
    }
    if (!mounted) return;
    _contentPreloadCompleted = true;
    _navigateWhenReady();
  }

  void _navigateWhenReady() {
    if (!_animationCompleted || !_contentPreloadCompleted || _navigated) {
      return;
    }
    _navigated = true;
    Future<void>.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      final nextRoute = OnboardingRepositoryMemory.instance.hasCompletedStart
          ? AppRoutes.home
          : AppRoutes.onboardingStart;
      Navigator.of(context).pushReplacementNamed(nextRoute);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Transform.scale(
          scale: 0.7,
          child: Lottie.asset(
            'assets/lottie/anim_logo.json',
            controller: _animationController,
            repeat: false,
            onLoaded: (composition) {
              _animationController
                ..duration = composition.duration
                ..forward(from: 0);
            },
          ),
        ),
      ),
    );
  }
}
