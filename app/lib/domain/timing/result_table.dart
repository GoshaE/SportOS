/// Result Table Engine — column-driven display model.
///
/// Чистый Dart, без Flutter. Единый источник отображения результатов
/// для всех экранов (LiveResults, Coach, Protocol, Export).
///
/// ```
/// RaceResult[]  ─┐
///                ├→  ResultTableBuilder  →  ResultTable
/// DisplaySettings┘         ↑                   ├ columns: [ColumnDef]
/// DisciplineConfig ────────┘                   └ rows: [ResultRow]
///                                                     └ cells: {id: CellValue}
/// ```
library;

// ─────────────────────────────────────────────────────────────────
// COLUMN TYPE
// ─────────────────────────────────────────────────────────────────

/// Тип данных колонки (определяет выравнивание и стиль по умолчанию).
enum ColumnType {
  /// Числовое значение (место, BIB).
  number,
  /// Текст (имя, категория).
  text,
  /// Время (Duration → formatted string).
  time,
  /// Скорость / темп.
  speed,
  /// Gap / delta.
  gap,
  /// Статус (DNS, DNF, DSQ, LIVE).
  status,
}

/// Выравнивание текста в колонке.
enum ColumnAlign { left, center, right }

// ─────────────────────────────────────────────────────────────────
// COLUMN DEF
// ─────────────────────────────────────────────────────────────────

/// Определение колонки таблицы результатов.
///
/// Каждая колонка имеет:
/// - `id` — уникальный ключ (используется как ключ в `ResultRow.cells`)
/// - `label` — заголовок для отображения
/// - `type` — тип данных (влияет на дефолтное выравнивание)
/// - `flex` — относительная ширина (распределение оставшегося места)
/// - `minWidth` — минимальная ширина в dp (для определения горизонтального скролла)
class ColumnDef {
  final String id;
  final String label;
  final ColumnType type;
  final ColumnAlign align;
  final double flex;

  /// Минимальная ширина колонки в logical pixels.
  ///
  /// Используется виджетом `AppResultTable` для определения
  /// необходимости горизонтального скролла:
  /// - sum(minWidth) > viewport → scroll ON
  /// - sum(minWidth) ≤ viewport → columns stretch via flex
  ///
  /// Значение задаётся в `ResultTableBuilder` с учётом
  /// семантики колонки и ожидаемой длины контента.
  final double minWidth;

  const ColumnDef({
    required this.id,
    required this.label,
    this.type = ColumnType.text,
    this.align = ColumnAlign.left,
    this.flex = 1.0,
    this.minWidth = 50,
  });
}

// ─────────────────────────────────────────────────────────────────
// CELL STYLE
// ─────────────────────────────────────────────────────────────────

/// Стиль ячейки (UI может маппить на конкретные цвета/стили).
enum CellStyle {
  /// Обычная ячейка.
  normal,
  /// Выделенная (лидер, лучший круг).
  highlight,
  /// Приглушённая (DNS, ожидание).
  muted,
  /// Жирная (финальное время).
  bold,
  /// Ошибка / предупреждение (DSQ, штраф).
  error,
  /// Успех (финишировал).
  success,
}

// ─────────────────────────────────────────────────────────────────
// CELL VALUE
// ─────────────────────────────────────────────────────────────────

/// Значение ячейки таблицы.
///
/// Содержит:
/// - `raw` — исходное значение (Duration, double, int, String) для сортировки/экспорта
/// - `display` — отформатированная строка для UI
/// - `style` — стиль отображения
class CellValue {
  /// Исходное значение для сортировки и экспорта.
  final dynamic raw;

  /// Отформатированная строка для отображения.
  final String display;

  /// Стиль ячейки.
  final CellStyle style;

  const CellValue({
    this.raw,
    required this.display,
    this.style = CellStyle.normal,
  });

  /// Пустая / placeholder ячейка.
  static const empty = CellValue(display: '—');

  /// Ячейка не применима (колонка не имеет значения для данной строки).
  static const na = CellValue(display: '');
}

// ─────────────────────────────────────────────────────────────────
// ROW TYPE
// ─────────────────────────────────────────────────────────────────

/// Тип строки результата (определяет общий стиль строки в UI).
enum RowType {
  finished,
  onTrack,
  waiting,
  dnf,
  dns,
  dsq,
}

// ─────────────────────────────────────────────────────────────────
// RESULT ROW
// ─────────────────────────────────────────────────────────────────

/// Строка результата с готовыми значениями ячеек.
///
/// UI получает `ResultRow` и рендерит `cells[columnId].display`.
/// Не содержит бизнес-логики — только данные.
class ResultRow {
  /// ID записи (для навигации, выделения, экспорта).
  final String entryId;

  /// Значения ячеек: columnId → CellValue.
  final Map<String, CellValue> cells;

  /// Тип строки (для стилизации всей строки).
  final RowType type;

  const ResultRow({
    required this.entryId,
    required this.cells,
    this.type = RowType.finished,
  });

  /// Получить отображаемое значение по columnId.
  String cell(String columnId) => cells[columnId]?.display ?? '';

  /// Получить raw значение для сортировки.
  dynamic rawCell(String columnId) => cells[columnId]?.raw;
}

// ─────────────────────────────────────────────────────────────────
// RESULT TABLE
// ─────────────────────────────────────────────────────────────────

/// Готовая таблица результатов: колонки + строки.
///
/// UI рендерит:
/// - `columns` → заголовки
/// - `rows` → данные (каждая строка содержит cells по column.id)
///
/// Таблица уже отсортирована и содержит готовые display-строки.
class ResultTable {
  /// Определения колонок (порядок = порядок в таблице).
  final List<ColumnDef> columns;

  /// Строки результатов (отсортированы: finished → onTrack → DNF → DNS → DSQ).
  final List<ResultRow> rows;

  const ResultTable({
    required this.columns,
    required this.rows,
  });

  /// Количество строк.
  int get rowCount => rows.length;

  /// Количество колонок.
  int get columnCount => columns.length;

  /// IDs всех колонок.
  List<String> get columnIds => columns.map((c) => c.id).toList();
}
