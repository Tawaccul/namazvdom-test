# namazvdom

Namaz learning UI (Flutter + `flutter_screenutil`) with an ayah audio block.

## Getting Started

- `StageStepScreen` — layout/styling based on the provided screenshot, includes a compact ayah audio block.
- Ayah audio/text is loaded from HuggingFace dataset-server via `dio` (Surah 1 for now).

### Run

```bash
flutter pub get
flutter run
```

### Where to swap icons/assets later

- Screen 1: `lib/features/stage/stage_step_screen.dart`
- Quran API: `lib/features/quran/data/quran_md_api.dart`
- Audio controller: `lib/core/audio/ayah_audio_controller.dart`
- Colors/tokens: `lib/app/theme/app_colors.dart`, `lib/app/theme/app_radii.dart`

Right now all icons are Material Icons (per your request). Replace them with your SVG/assets when ready.
