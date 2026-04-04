import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'app/l10n/app_localization.dart';
import 'app/app.dart';
import 'features/settings/gender/data/gender_repository_memory.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await GenderRepositoryMemory.instance.init();
  runApp(
    EasyLocalization(
      supportedLocales: appSupportedLocales,
      fallbackLocale: appFallbackLocale,
      path: appTranslationsPath,
      child: const App(),
    ),
  );
}
