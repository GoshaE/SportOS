import 'package:flutter/foundation.dart';

/// Настройки отображения таблицы результатов Quick Timer.
///
/// Позволяют тренеру настроить визуализацию под свои нужды:
/// - подсветка лучшего круга
/// - показ/скрытие колонок
@immutable
class QtDisplaySettings {
  /// Подсвечивать лучший круг primary-цветом.
  final bool showBestLap;

  /// Показывать колонку Δ (разрыв от лидера).
  final bool showGapColumn;

  /// Показывать колонки отдельных кругов (L1, L2...).
  final bool showLapColumns;

  const QtDisplaySettings({
    this.showBestLap = true,
    this.showGapColumn = true,
    this.showLapColumns = true,
  });

  QtDisplaySettings copyWith({
    bool? showBestLap,
    bool? showGapColumn,
    bool? showLapColumns,
  }) => QtDisplaySettings(
    showBestLap: showBestLap ?? this.showBestLap,
    showGapColumn: showGapColumn ?? this.showGapColumn,
    showLapColumns: showLapColumns ?? this.showLapColumns,
  );
}
