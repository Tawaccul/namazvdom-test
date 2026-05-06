import 'package:flutter/material.dart';

/// Базовый билдер переходов между шагами намаза.
///
/// Каждая реализация описывает «карусельное» поведение:
/// контент текущего шага сдвигается по жесту пальца, а сбоку
/// частично виден соседний шаг.
abstract class StageStepTransition {
  const StageStepTransition();

  /// Уникальный код анимации (для выбора в настройках).
  String get id;

  /// Человекочитаемое имя.
  String get label;

  /// Строит контейнер переходов.
  ///
  /// [pageCount] — общее количество страниц шагов в текущем ракаате.
  /// [currentIndex] — индекс активной страницы.
  /// [onIndexChanged] — вызывается, когда пользователь долистал до новой страницы.
  /// [pageBuilder] — рисует содержимое страницы по индексу.
  Widget build({
    required BuildContext context,
    required int pageCount,
    required int currentIndex,
    required ValueChanged<int> onIndexChanged,
    required IndexedWidgetBuilder pageBuilder,
  });
}
