import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/l10n/app_localization.dart';
import 'features/onboarding/data/onboarding_repository_memory.dart';
import 'features/settings/language/data/language_repository_memory.dart';
import 'features/settings/gender/data/gender_repository_memory.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await LanguageRepositoryMemory.instance.init();
  await GenderRepositoryMemory.instance.init();
  await OnboardingRepositoryMemory.instance.init();
  runApp(
    EasyLocalization(
      supportedLocales: appSupportedLocales,
      fallbackLocale: appFallbackLocale,
      path: appTranslationsPath,
      startLocale: LanguageRepositoryMemory.instance.selectedLocale,
      child: const App(),
    ),
  );
}
