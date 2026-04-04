// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:namazvdom/core/audio/ayah_audio.dart';
import 'package:namazvdom/features/quran/model/quran_ayah.dart';
import 'package:namazvdom/features/stage/models/rakaat_models.dart';
import 'package:namazvdom/features/stage/stage_step_screen.dart';

void main() {
  testWidgets('App starts on stage step screen', (WidgetTester tester) async {
    final audio = _FakeAyahAudio();
    final rakaats = _fakeRakaats();

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return MaterialApp(
            home: StageStepScreen(rakaats: rakaats, audio: audio),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Al-Fatiha'), findsWidgets);
    expect(find.text('The Opening'), findsWidgets);
  });
}

List<RakaatData> _fakeRakaats() {
  return const [
    RakaatData(
      number: 1,
      imageAsset: 'assets/icons/salat-1.png',
      steps: [
        RakaatStep(
          title: 'Recitation',
          movementDescription: 'Demo movement',
          arabic: 'الفاتحة',
          transliteration: 'Al-Fatiha',
          translation: 'The Opening',
          audioUrl: 'https://example.com/audio.mp3',
        ),
      ],
    ),
  ];
}

class _FakeAyahAudio extends ChangeNotifier implements AyahAudio {
  QuranAyah? _current;
  bool _isPlaying = false;
  double _progress = 0.25;

  @override
  QuranAyah? get current => _current;

  @override
  bool get isPlaying => _isPlaying;

  @override
  double get progress => _progress;

  @override
  bool get isCompleted => false;

  @override
  Future<void> setAyah(QuranAyah ayah) async {
    _current = ayah;
    _progress = 0;
    notifyListeners();
  }

  @override
  Future<void> toggle() async {
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  @override
  Future<void> play() async {
    _isPlaying = true;
    notifyListeners();
  }

  @override
  Future<void> pause() async {
    _isPlaying = false;
    notifyListeners();
  }

  @override
  Future<void> stop() async {
    _isPlaying = false;
    _progress = 0;
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    super.dispose();
  }
}
