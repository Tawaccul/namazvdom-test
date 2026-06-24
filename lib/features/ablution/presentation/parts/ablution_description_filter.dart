import '../../../settings/gender/data/gender_repository_memory.dart';

bool _isFemale() {
  final id = GenderRepositoryMemory.instance
      .getSelectedGender()
      .id
      .trim()
      .toLowerCase();
  return id == 'female';
}

/// Для женского профиля подставляет ключ `*.descriptionFemale` вместо
/// `*.description`. Если такого ключа в переводах нет — вернёт исходный.
///
/// Использование:
/// ```dart
/// final key = genderedDescriptionKey(step.descriptionKey);
/// Text(context.t(key));
/// ```
String genderedDescriptionKey(String key) {
  if (!_isFemale()) return key;
  if (key.isEmpty) return key;
  if (key.endsWith('.description')) {
    return '${key.substring(0, key.length - '.description'.length)}.descriptionFemale';
  }
  return key;
}

/// Возвращает текст описания шага омовения. Если выбран женский профиль,
/// удаляет круглые скобки с уточнением для мужчин (про бороду).
///
/// Оставлено как страховка для текстов, где ещё не подготовлен ключ
/// `descriptionFemale`. Если такой ключ есть — там скобки убраны вручную,
/// и эта функция ничего не сделает.
String filteredAblutionDescription(String description) {
  if (!_isFemale()) return description;

  final result = description.replaceAllMapped(
    RegExp(r'\s*\([^()]*\)', dotAll: true),
    (match) {
      final inner = match.group(0)!.toLowerCase();
      if (inner.contains('бород') || inner.contains('beard')) {
        return '';
      }
      return match.group(0)!;
    },
  );
  return result.trim();
}
