import '../../features/settings/gender/data/gender_repository_memory.dart';
import '../../features/settings/language/data/language_repository_memory.dart';

/// Применяет гендерные замены к описанию шага (намаз / омовение).
///
/// Если выбран женский профиль:
///   RU: «он»  → «она», «его»  → «её», глаголы «-ает/-ит» в конце слова
///       не трогаем — структура предложения в исходных переводах сделана
///       так, что глагол согласован с местоимением, поэтому замена только
///       местоимений уже даёт корректный текст;
///   EN: "He" → "She", "his" → "her", "him" → "her", "himself" → "herself".
///
/// Возвращает исходную строку для мужского профиля или если язык
/// не поддерживается.
String genderedDescription(String input) {
  if (input.isEmpty) return input;
  final gender =
      GenderRepositoryMemory.instance.getSelectedGender().id.trim().toLowerCase();
  if (gender != 'female') return input;

  final lang =
      LanguageRepositoryMemory.instance.getSelectedLanguage().id.trim().toLowerCase();
  if (lang == 'ru') return _swapRu(input);
  return _swapEn(input);
}

/// Применяет гендерные замены не зная контекст приложения (вызывается из
/// тестов или из мест, где `BuildContext` недоступен).
String genderedDescriptionRaw({
  required String input,
  required bool isFemale,
  required String languageCode,
}) {
  if (!isFemale || input.isEmpty) return input;
  final lang = languageCode.trim().toLowerCase();
  if (lang == 'ru') return _swapRu(input);
  return _swapEn(input);
}

// Локализуем глаголы в RU: 3-е лицо ед.ч. для женского рода в прошедшем
// (которое в этих текстах не встречается) или настоящем времени не
// отличается. Тексты сейчас написаны в форме настоящего времени
// (например «он совершает», «он моет», «он говорит») — для «она» эти
// формы не меняются. Достаточно подменить местоимения.
final List<_Replacement> _ruReplacements = <_Replacement>[
  // Местоимения с границами слова, регистр сохраняем у первой буквы.
  _Replacement(RegExp(r'\bОн\b'), 'Она'),
  _Replacement(RegExp(r'\bон\b'), 'она'),
  _Replacement(RegExp(r'\bЕму\b'), 'Ей'),
  _Replacement(RegExp(r'\bему\b'), 'ей'),
  _Replacement(RegExp(r'\bего\b'), 'её'),
  _Replacement(RegExp(r'\bЕго\b'), 'Её'),
  _Replacement(RegExp(r'\bим\b'), 'ей'),
  _Replacement(RegExp(r'\bИм\b'), 'Ей'),
  _Replacement(RegExp(r'\bмусульманина\b'), 'мусульманки'),
  _Replacement(RegExp(r'\bмусульманину\b'), 'мусульманке'),
];

final List<_Replacement> _enReplacements = <_Replacement>[
  // Сначала составные («himself» → «herself»), затем простые («him» → «her»)
  _Replacement(RegExp(r'\bHimself\b'), 'Herself'),
  _Replacement(RegExp(r'\bhimself\b'), 'herself'),
  _Replacement(RegExp(r'\bHis\b'), 'Her'),
  _Replacement(RegExp(r'\bhis\b'), 'her'),
  _Replacement(RegExp(r'\bHe\b'), 'She'),
  _Replacement(RegExp(r'\bhe\b'), 'she'),
  // «him» отдельно (без «himself»), безопасно — границы слова сохраняем.
  _Replacement(RegExp(r'\bhim\b'), 'her'),
  _Replacement(RegExp(r'\bHim\b'), 'Her'),
  _Replacement(RegExp(r'\bMuslim man\b'), 'Muslim woman'),
  _Replacement(RegExp(r'\bmuslim man\b'), 'muslim woman'),
];

String _swapRu(String s) {
  var out = s;
  for (final r in _ruReplacements) {
    out = out.replaceAll(r.pattern, r.replacement);
  }
  return out;
}

String _swapEn(String s) {
  var out = s;
  for (final r in _enReplacements) {
    out = out.replaceAll(r.pattern, r.replacement);
  }
  return out;
}

class _Replacement {
  const _Replacement(this.pattern, this.replacement);
  final RegExp pattern;
  final String replacement;
}
