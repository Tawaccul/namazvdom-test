/// Возвращает строку, где первая значимая буква переведена в верхний регистр.
/// Используется для транслитерации и переводов аятов/шагов — данные могут
/// прийти с маленькой буквы, а UI ожидает заглавную.
String capitalizeFirst(String input) {
  final trimmed = input.trimLeft();
  if (trimmed.isEmpty) return input;
  // Сохраняем ведущие пробелы/символы.
  final leadingLength = input.length - trimmed.length;
  final leading = input.substring(0, leadingLength);
  // Найти первый буквенный символ и заменить его на верхний регистр.
  for (var i = 0; i < trimmed.length; i++) {
    final ch = trimmed[i];
    final upper = ch.toUpperCase();
    if (upper != ch.toLowerCase()) {
      return '$leading${trimmed.substring(0, i)}$upper${trimmed.substring(i + 1)}';
    }
  }
  return input;
}
