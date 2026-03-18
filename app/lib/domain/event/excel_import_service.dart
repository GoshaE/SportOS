import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

import 'event_config.dart';

/// Поля для маппинга колонок Excel → поля Participant.
enum ImportField {
  skip('— Пропустить —'),
  name('ФИО'),
  gender('Пол'),
  birthDate('Дата рождения'),
  phone('Телефон'),
  email('Email'),
  city('Город'),
  club('Клуб / Команда'),
  dogName('Кличка собаки'),
  rank('Разряд'),
  insuranceNo('Страховка'),
  category('Категория'),
  discipline('Дисциплина');

  final String label;
  const ImportField(this.label);
}

/// Результат парсинга файла.
class ParsedSheet {
  final List<String> headers;
  final List<List<String>> rows;

  const ParsedSheet({required this.headers, required this.rows});

  int get columnCount => headers.length;
}

/// Сервис импорта участников из Excel/CSV.
class ExcelImportService {
  /// Парсит .xlsx файл.
  static ParsedSheet parseXlsx(Uint8List bytes) {
    final decoder = SpreadsheetDecoder.decodeBytes(bytes);
    final table = decoder.tables.values.first; // первый лист

    if (table.rows.isEmpty) {
      return const ParsedSheet(headers: [], rows: []);
    }

    final headers = table.rows.first.map((c) => c?.toString().trim() ?? '').toList();
    final dataRows = table.rows.skip(1).map(
      (row) => row.map((c) => c?.toString().trim() ?? '').toList(),
    ).where((row) => row.any((c) => c.isNotEmpty)).toList();

    return ParsedSheet(headers: headers, rows: dataRows);
  }

  /// Парсит .csv файл.
  static ParsedSheet parseCsv(String csvContent) {
    final rows = const CsvToListConverter(eol: '\n', shouldParseNumbers: false)
        .convert(csvContent);
    
    if (rows.isEmpty) {
      return const ParsedSheet(headers: [], rows: []);
    }

    final headers = rows.first.map((c) => c.toString().trim()).toList();
    final dataRows = rows.skip(1)
        .map((row) => row.map((c) => c.toString().trim()).toList())
        .where((row) => row.any((c) => c.isNotEmpty))
        .toList();

    return ParsedSheet(headers: headers, rows: dataRows);
  }

  /// Авто-определяет маппинг колонок по названиям заголовков.
  static Map<int, ImportField> autoDetectMapping(List<String> headers) {
    final mapping = <int, ImportField>{};
    
    for (int i = 0; i < headers.length; i++) {
      final h = headers[i].toLowerCase().trim();
      final field = _detectField(h);
      if (field != null) {
        mapping[i] = field;
      }
    }
    return mapping;
  }

  static ImportField? _detectField(String h) {
    if (h.contains('фио') || h.contains('имя') || h.contains('фамилия') || h.contains('name') || h.contains('спортсмен') || h.contains('участник')) return ImportField.name;
    if (h.contains('пол') || h.contains('gender') || h.contains('sex')) return ImportField.gender;
    if (h.contains('дата рожд') || h.contains('birth') || h.contains('д.р.') || h.contains('год рожд')) return ImportField.birthDate;
    if (h.contains('телефон') || h.contains('phone') || h.contains('тел')) return ImportField.phone;
    if (h.contains('email') || h.contains('почта') || h.contains('e-mail')) return ImportField.email;
    if (h.contains('город') || h.contains('city') || h.contains('населённый')) return ImportField.city;
    if (h.contains('клуб') || h.contains('команда') || h.contains('club') || h.contains('team') || h.contains('организация')) return ImportField.club;
    if (h.contains('собак') || h.contains('кличка') || h.contains('dog')) return ImportField.dogName;
    if (h.contains('разряд') || h.contains('квалификация') || h.contains('rank')) return ImportField.rank;
    if (h.contains('страховка') || h.contains('insurance') || h.contains('полис')) return ImportField.insuranceNo;
    if (h.contains('категория') || h.contains('category') || h.contains('группа')) return ImportField.category;
    if (h.contains('дисциплина') || h.contains('вид') || h.contains('discipline') || h.contains('дист') || h.contains('event')) return ImportField.discipline;
    return null;
  }

  /// Извлекает поля из одной строки Excel по маппингу.
  static Map<ImportField, String> extractFields(List<String> row, Map<int, ImportField> mapping) {
    final fields = <ImportField, String>{};
    for (final entry in mapping.entries) {
      if (entry.key < row.length && entry.value != ImportField.skip) {
        fields[entry.value] = row[entry.key];
      }
    }
    return fields;
  }

  /// Создаёт Participant из маппированных полей.
  ///
  /// [disciplineId] / [disciplineName] — назначенная дисциплина.
  /// БИБ НЕ назначается при импорте — только при жеребьёвке.
  static Participant? createParticipant({
    required Map<ImportField, String> fields,
    required String disciplineId,
    required String disciplineName,
    required int index,
  }) {
    final name = fields[ImportField.name]?.trim() ?? '';
    if (name.isEmpty) return null;

    return Participant(
      id: 'p-import-${DateTime.now().millisecondsSinceEpoch}-$index',
      name: name,
      phone: fields[ImportField.phone],
      email: fields[ImportField.email],
      disciplineId: disciplineId,
      disciplineName: disciplineName,
      bib: '',  // BIB назначается при жеребьёвке
      category: fields[ImportField.category],
      dogName: fields[ImportField.dogName],
      registeredAt: DateTime.now(),
      gender: _parseGender(fields[ImportField.gender]),
      birthDate: _parseBirthDate(fields[ImportField.birthDate]),
      city: fields[ImportField.city],
      club: fields[ImportField.club],
      rank: fields[ImportField.rank],
      insuranceNo: fields[ImportField.insuranceNo],
    );
  }

  /// Применяет маппинг к сырым строкам → создаёт Participant (legacy, всех в одну дисциплину).
  static List<Participant> applyMapping({
    required List<List<String>> rows,
    required Map<int, ImportField> mapping,
    required String disciplineId,
    required String disciplineName,
    required int startBib,
  }) {
    final result = <Participant>[];
    int idx = 0;
    for (final row in rows) {
      final fields = extractFields(row, mapping);
      final p = createParticipant(fields: fields, disciplineId: disciplineId, disciplineName: disciplineName, index: idx);
      if (p != null) result.add(p);
      idx++;
    }
    return result;
  }

  /// Парсим пол из строки.
  static String? _parseGender(String? value) {
    if (value == null || value.isEmpty) return null;
    final v = value.toLowerCase().trim();
    if (v == 'м' || v == 'муж' || v == 'мужской' || v == 'male' || v == 'm') return 'male';
    if (v == 'ж' || v == 'жен' || v == 'женский' || v == 'female' || v == 'f' || v == 'ж.') return 'female';
    return null;
  }

  /// Парсим дату рождения.
  static DateTime? _parseBirthDate(String? value) {
    if (value == null || value.isEmpty) return null;
    // Попробуем разные форматы
    // dd.MM.yyyy
    final dotParts = value.split('.');
    if (dotParts.length == 3) {
      final day = int.tryParse(dotParts[0]);
      final month = int.tryParse(dotParts[1]);
      final year = int.tryParse(dotParts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year < 100 ? year + 2000 : year, month, day);
      }
    }
    // yyyy-MM-dd
    final dashParts = value.split('-');
    if (dashParts.length == 3) {
      final year = int.tryParse(dashParts[0]);
      final month = int.tryParse(dashParts[1]);
      final day = int.tryParse(dashParts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    // dd/MM/yyyy
    final slashParts = value.split('/');
    if (slashParts.length == 3) {
      final day = int.tryParse(slashParts[0]);
      final month = int.tryParse(slashParts[1]);
      final year = int.tryParse(slashParts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year < 100 ? year + 2000 : year, month, day);
      }
    }
    // Только год (4 цифры)
    final yearOnly = int.tryParse(value);
    if (yearOnly != null && yearOnly > 1900 && yearOnly < 2100) {
      return DateTime(yearOnly, 1, 1);
    }
    return null;
  }
}
