/// Maps logical step codes / surah ayahs / ablution steps to bundled mp3
/// files under `assets/audios/`. Returns an empty string if no asset matches.
class AudioAssetResolver {
  AudioAssetResolver._();

  static const String _base = 'assets/audios';

  static const Map<String, String> _stageStepFiles = {
    'takbir': 'takbir.mp3',
    'istigfar': 'istigfar_auzubillyahi.mp3',
    'auzubillah': 'istigfar_auzubillyahi.mp3',
    'protection_from_devil': 'istigfar_auzubillyahi.mp3',
    'dua_istiftah': 'dua_istiftah.mp3',
    'basmallah': 'basmallah.mp3',
    'bismillah': 'basmallah.mp3',
    'ameen': 'ameen.mp3',
    'amin': 'ameen.mp3',
    'ruku': 'ruquy.mp3',
    'sujud': 'sajda.mp3',
    'sajda': 'sajda.mp3',
    'jalsa': 'posle_ruquy.mp3',
    'posle_ruku': 'posle_ruquy_stoya.mp3',
    'after_ruku': 'posle_ruquy_stoya.mp3',
    'qiyam_after_ruku': 'posle_ruquy_stoya.mp3',
    'taslim_left': 'salam.mp3',
    'taslim_right': 'salam.mp3',
    'salam': 'salam.mp3',
  };

  static const Map<String, List<String>> _surahFiles = {
    // Note: bundled fatiha_*.mp3 start from Al-hamdu, not Bismillah.
    // Bismillah is the first ayah → uses basmallah.mp3.
    'al_fatiha': [
      'basmallah.mp3',
      'fatiha_1.mp3',
      'fatiha_2.mp3',
      'fatiha_3.mp3',
      'fatiha_4.mp3',
      'fatiha_5.mp3',
      'fatiha_6.mp3',
    ],
    // Surahs in JSON start with Bismillah as the first ayah.
    // Bundled surah_*_N.mp3 files start from the actual surah content,
    // so we prepend basmallah.mp3 for ayah index 0.
    'al_ikhlas': [
      'basmallah.mp3',
      'surah_ihlas_1.mp3',
      'surah_ihlas_2.mp3',
      'surah_ihlas_3.mp3',
      'surah_ihlas_4.mp3',
    ],
    'al_falaq': [
      'basmallah.mp3',
      'surah_falaq_1.mp3',
      'surah_falaq_2.mp3',
      'surah_falaq_3.mp3',
      'surah_falaq_4.mp3',
      'surah_falaq_5.mp3',
    ],
    'an_nas': [
      'basmallah.mp3',
      'surah_nas_1.mp3',
      'surah_nas_2.mp3',
      'surah_nas_3.mp3',
      'surah_nas_4.mp3',
      'surah_nas_5.mp3',
      'surah_nas_6.mp3',
    ],
    'at_tahiyat': [
      'tahiya_1.mp3',
      'tahiya_2.mp3',
      'tahiya_3.mp3',
      'tahiya_4.mp3',
    ],
    'salawat': [
      'salavat_1.mp3',
      'salavat_2.mp3',
      'salavat_3.mp3',
      'salavat_4.mp3',
      'salavat_5.mp3',
      'salavat_6.mp3',
    ],
  };

  static const Map<int, String> _ablutionStepFiles = {
    // Ablution uses a shorter version of the Basmalla recitation.
    1: 'basmalla_short.mp3',
  };

  static String forStageStep(String stepCode) {
    final key = stepCode.trim().toLowerCase();
    final file = _stageStepFiles[key];
    return file == null ? '' : '$_base/$file';
  }

  /// Resolves an audio file by the Arabic incipit of the step's recitation.
  /// This is the most reliable signal — different steps share the same image
  /// or stepCode, but the Arabic phrase uniquely identifies the dhikr.
  static String forStageArabic(String arabic) {
    final stripped = _stripArabicDiacritics(arabic);
    if (stripped.isEmpty) return '';

    // Allahu akbar → takbir
    if (stripped.startsWith('الله اكبر') ||
        stripped.startsWith('اللهاكبر')) {
      return '$_base/takbir.mp3';
    }
    // A'oodhu billah → istigfar
    if (stripped.startsWith('اعوذ بالله') ||
        stripped.startsWith('اعوذبالله')) {
      return '$_base/istigfar_auzubillyahi.mp3';
    }
    // Ameen
    if (stripped.startsWith('امين') || stripped.startsWith('آمين')) {
      return '$_base/ameen.mp3';
    }
    // Subhaana rabbiyal 'atheem → ruku
    if (stripped.startsWith('سبحان ربي العظيم') ||
        stripped.startsWith('سبحانربيالعظيم')) {
      return '$_base/ruquy.mp3';
    }
    // Sami'-Allaahu liman hamidah → posle_ruquy (Straightening, rising from ruku)
    if (stripped.startsWith('سمع الله لمن حمده') ||
        stripped.startsWith('سمعاللهلمنحمده')) {
      return '$_base/posle_ruquy.mp3';
    }
    // Rabbanaa wa lakal hamd → posle_ruquy_stoya (Standing after ruku)
    if (stripped.startsWith('ربنا ولك الحمد') ||
        stripped.startsWith('ربناولكالحمد')) {
      return '$_base/posle_ruquy_stoya.mp3';
    }
    // Subhaana rabbiyal 'alaa → sajda (sujood)
    if (stripped.startsWith('سبحان ربي الاعلى') ||
        stripped.startsWith('سبحانربيالاعلى')) {
      return '$_base/sajda.mp3';
    }
    // Rabbi-ghfir-li → rabbigfirli (sitting between the two prostrations)
    if (stripped.startsWith('رب اغفر لي') ||
        stripped.startsWith('رباغفرلي')) {
      return '$_base/rabbigfirli.mp3';
    }
    // Assalaamu 'alaykum → salam (taslim left/right)
    if (stripped.startsWith('السلام عليكم') ||
        stripped.startsWith('السلامعليكم')) {
      return '$_base/salam.mp3';
    }
    // Bismillah
    if (stripped.startsWith('بسم الله') || stripped.startsWith('بسمالله')) {
      return '$_base/basmallah.mp3';
    }
    return '';
  }

  /// Removes Arabic diacritical marks (tashkeel) so plain Arabic
  /// substring matching becomes stable across slightly different sources.
  static String _stripArabicDiacritics(String input) {
    final buffer = StringBuffer();
    for (final code in input.runes) {
      // Skip combining marks: 0x064B..0x065F (tashkeel), 0x0670 (superscript alef),
      // 0x06D6..0x06ED (small high signs), 0x08D3..0x08FF, tatweel 0x0640.
      if ((code >= 0x064B && code <= 0x065F) ||
          code == 0x0670 ||
          (code >= 0x06D6 && code <= 0x06ED) ||
          code == 0x0640) {
        continue;
      }
      // Normalize alef variants → bare alef (so أ/إ/آ match).
      if (code == 0x0623 || code == 0x0625 || code == 0x0622) {
        buffer.writeCharCode(0x0627);
        continue;
      }
      buffer.writeCharCode(code);
    }
    return buffer.toString().trim();
  }

  static String forSurahAyah(String surahCode, int ayahIndex) {
    final key = surahCode.trim().toLowerCase();
    final files = _surahFiles[key];
    if (files == null || ayahIndex < 0 || ayahIndex >= files.length) return '';
    return '$_base/${files[ayahIndex]}';
  }

  static String forAblutionStep(int stepId) {
    final file = _ablutionStepFiles[stepId];
    return file == null ? '' : '$_base/$file';
  }
}
