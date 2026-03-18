import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../../domain/event/config_providers.dart';
import '../../../domain/event/event_config.dart';
import '../../../domain/event/excel_import_service.dart';

/// Экран импорта участников из Excel/CSV.
/// 3-шаговый wizard: Загрузка → Маппинг колонок → Превью и назначение дисциплин.
class ExcelImportScreen extends ConsumerStatefulWidget {
  const ExcelImportScreen({super.key});

  @override
  ConsumerState<ExcelImportScreen> createState() => _ExcelImportScreenState();
}

class _ExcelImportScreenState extends ConsumerState<ExcelImportScreen> {
  int _step = 0; // 0=upload, 1=mapping, 2=preview

  // Step 0
  ParsedSheet? _sheet;
  String? _fileName;

  // Step 1
  Map<int, ImportField> _mapping = {};

  // Step 2: per-row data
  List<_ImportRow> _rows = [];
  Set<int> _selectedRows = {};

  // ─── Step 0: Загрузка файла ───
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'csv', 'xls'],
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final bytes = file.bytes ?? (file.path != null ? File(file.path!).readAsBytesSync() : null);
    if (bytes == null) {
      if (mounted) AppSnackBar.error(context, 'Не удалось прочитать файл');
      return;
    }

    try {
      ParsedSheet sheet;
      if (file.extension?.toLowerCase() == 'csv') {
        sheet = ExcelImportService.parseCsv(String.fromCharCodes(bytes));
      } else {
        sheet = ExcelImportService.parseXlsx(bytes);
      }

      if (sheet.rows.isEmpty) {
        if (mounted) AppSnackBar.error(context, 'Файл пустой');
        return;
      }

      setState(() {
        _sheet = sheet;
        _fileName = file.name;
        _mapping = ExcelImportService.autoDetectMapping(sheet.headers);
        _step = 1;
      });
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Ошибка чтения: $e');
    }
  }

  // ─── Step 1 → Step 2: Построить превью ───
  void _buildPreview() {
    if (!_mapping.values.contains(ImportField.name)) {
      AppSnackBar.error(context, 'Укажите колонку с ФИО');
      return;
    }

    final disciplines = ref.read(disciplineConfigsProvider);
    final hasDisciplineCol = _mapping.values.contains(ImportField.discipline);

    final rows = <_ImportRow>[];
    for (int i = 0; i < _sheet!.rows.length; i++) {
      final rawRow = _sheet!.rows[i];
      final fields = ExcelImportService.extractFields(rawRow, _mapping);
      final name = fields[ImportField.name]?.trim() ?? '';
      if (name.isEmpty) continue;

      // Determine discipline from Excel column or leave unassigned
      String? discId;
      String? discName;
      if (hasDisciplineCol && fields[ImportField.discipline] != null) {
        final excelDisc = fields[ImportField.discipline]!.trim().toLowerCase();
        for (final d in disciplines) {
          if (d.name.toLowerCase().contains(excelDisc) || excelDisc.contains(d.name.toLowerCase())) {
            discId = d.id;
            discName = d.name;
            break;
          }
        }
      }

      rows.add(_ImportRow(
        index: i,
        fields: fields,
        disciplineId: discId,
        disciplineName: discName,
      ));
    }

    setState(() {
      _rows = rows;
      _selectedRows = Set<int>.from(List.generate(rows.length, (i) => i));
      _step = 2;
    });
  }

  // ─── Step 2: Импорт ───
  void _doImport() {
    final toAdd = <Participant>[];
    int noDisc = 0;
    int idx = 0;

    for (final i in _selectedRows.toList()..sort()) {
      final row = _rows[i];
      if (row.disciplineId == null) {
        noDisc++;
        continue;
      }

      final p = ExcelImportService.createParticipant(
        fields: row.fields,
        disciplineId: row.disciplineId!,
        disciplineName: row.disciplineName ?? '',
        index: idx,
      );
      if (p != null) toAdd.add(p);
      idx++;
    }

    if (noDisc > 0 && toAdd.isEmpty) {
      AppSnackBar.error(context, 'У $noDisc участников не выбрана дисциплина');
      return;
    }

    // Check for duplicates with existing participants
    final existing = ref.read(participantsProvider);
    final existingNames = existing.map((p) => p.name.toLowerCase()).toSet();
    int duplicates = 0;
    final unique = <Participant>[];
    for (final p in toAdd) {
      if (existingNames.contains(p.name.toLowerCase()) && existing.any(
        (e) => e.name.toLowerCase() == p.name.toLowerCase() && e.disciplineId == p.disciplineId,
      )) {
        duplicates++;
      } else {
        unique.add(p);
      }
    }

    final notifier = ref.read(participantsProvider.notifier);
    for (final p in unique) {
      notifier.add(p);
    }

    final msg = StringBuffer('Импортировано ${unique.length} участников');
    if (duplicates > 0) msg.write(' ($duplicates дублей пропущено)');
    if (noDisc > 0) msg.write(' ($noDisc без дисциплины пропущено)');
    AppSnackBar.success(context, msg.toString());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppAppBar(
        title: Text(_step == 0 ? 'Импорт из Excel' : _step == 1 ? 'Маппинг колонок' : 'Превью и назначение'),
        actions: [
          if (_step > 0)
            TextButton.icon(
              onPressed: () => setState(() => _step--),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Назад'),
            ),
        ],
      ),
      body: switch (_step) {
        0 => _buildUploadStep(cs),
        1 => _buildMappingStep(cs),
        2 => _buildPreviewStep(cs),
        _ => const SizedBox(),
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // STEP 0: Загрузка
  // ═══════════════════════════════════════════════════════════════
  Widget _buildUploadStep(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.upload_file, size: 40, color: cs.primary),
            ),
            const SizedBox(height: 24),
            Text('Загрузите список спортсменов', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
            const SizedBox(height: 8),
            Text(
              'Поддерживаются форматы .xlsx и .csv\n'
              'Система автоматически определит колонки.\n'
              'Если в таблице есть колонка «Дисциплина»,\n'
              'спортсмены будут распределены автоматически.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.outline, height: 1.5),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.folder_open),
              label: const Text('Выбрать файл', style: TextStyle(fontSize: 16)),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.lightbulb_outline, size: 14, color: cs.tertiary),
                    const SizedBox(width: 6),
                    Text('Пример формата', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.tertiary)),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    'ФИО | Пол | Дисциплина | Город | Клуб | Собака\n'
                    'Петров Алексей | М | Скиджоринг | Екатеринбург | Сноу Дог | Rex',
                    style: TextStyle(fontSize: 11, color: cs.outline, fontFamily: 'monospace', height: 1.6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // STEP 1: Маппинг колонок
  // ═══════════════════════════════════════════════════════════════
  Widget _buildMappingStep(ColorScheme cs) {
    final hasDisciplineMapping = _mapping.values.contains(ImportField.discipline);

    return Column(children: [
      // File info bar
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: cs.primaryContainer.withValues(alpha: 0.15),
        child: Row(children: [
          Icon(Icons.description, size: 16, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(child: Text('$_fileName — ${_sheet!.rows.length} строк', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary))),
        ]),
      ),

      // Discipline detection info
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: hasDisciplineMapping
            ? Colors.green.withValues(alpha: 0.08)
            : Colors.orange.withValues(alpha: 0.08),
        child: Row(children: [
          Icon(
            hasDisciplineMapping ? Icons.auto_awesome : Icons.info_outline,
            size: 14,
            color: hasDisciplineMapping ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(
            hasDisciplineMapping
                ? '✅ Колонка «Дисциплина» найдена — спортсмены будут распределены автоматически'
                : 'ℹ Колонка «Дисциплина» не найдена — назначите дисциплину на следующем шаге',
            style: TextStyle(
              fontSize: 12,
              color: hasDisciplineMapping ? Colors.green.shade800 : Colors.orange.shade800,
            ),
          )),
        ]),
      ),

      Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
        // Column mapping
        Text('Сопоставление колонок', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cs.onSurface)),
        const SizedBox(height: 4),
        Text('Укажите какое поле соответствует каждой колонке', style: TextStyle(fontSize: 12, color: cs.outline)),
        const SizedBox(height: 12),

        ...List.generate(_sheet!.columnCount, (i) {
          final header = _sheet!.headers[i];
          final preview = _sheet!.rows.isNotEmpty && i < _sheet!.rows.first.length
              ? _sheet!.rows.first[i]
              : '';
          final currentField = _mapping[i] ?? ImportField.skip;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: currentField == ImportField.discipline
                  ? Colors.green.withValues(alpha: 0.08)
                  : currentField != ImportField.skip
                      ? cs.primaryContainer.withValues(alpha: 0.1)
                      : cs.surfaceContainerHighest.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: currentField == ImportField.discipline
                    ? Colors.green.withValues(alpha: 0.4)
                    : currentField != ImportField.skip ? cs.primary.withValues(alpha: 0.3) : cs.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            child: Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(header.isNotEmpty ? header : 'Колонка ${i + 1}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
                  if (preview.isNotEmpty)
                    Text(preview, style: TextStyle(fontSize: 11, color: cs.outline), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              )),
              const SizedBox(width: 12),
              Icon(Icons.arrow_forward, size: 14, color: cs.outline),
              const SizedBox(width: 12),
              SizedBox(
                width: 160,
                child: AppSelect<ImportField>(
                  label: '',
                  value: currentField,
                  items: ImportField.values.map((f) => SelectItem(value: f, label: f.label)).toList(),
                  onChanged: (v) {
                    setState(() {
                      if (v == ImportField.skip) {
                        _mapping.remove(i);
                      } else {
                        _mapping.removeWhere((_, val) => val == v);
                        _mapping[i] = v;
                      }
                    });
                  },
                ),
              ),
            ]),
          );
        }),

        // Preview table
        if (_sheet!.rows.length > 1) ...[
          const SizedBox(height: 16),
          Text('Превью данных (первые 3 строки)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.outline)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              headingRowHeight: 32,
              dataRowMinHeight: 28,
              dataRowMaxHeight: 28,
              columns: List.generate(_sheet!.columnCount, (i) =>
                DataColumn(label: Text(_sheet!.headers[i], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cs.primary))),
              ),
              rows: _sheet!.rows.take(3).map((row) =>
                DataRow(cells: List.generate(_sheet!.columnCount, (i) =>
                  DataCell(Text(i < row.length ? row[i] : '', style: TextStyle(fontSize: 10, color: cs.onSurface))),
                )),
              ).toList(),
            ),
          ),
        ],
      ])),

      // Bottom action
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2))),
        ),
        child: SizedBox(width: double.infinity, child: FilledButton.icon(
          onPressed: _buildPreview,
          icon: const Icon(Icons.check),
          label: Text('Далее → Превью (${_sheet!.rows.length} строк)', style: const TextStyle(fontSize: 16)),
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
        )),
      ),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════
  // STEP 2: Превью с назначением дисциплин
  // ═══════════════════════════════════════════════════════════════
  Widget _buildPreviewStep(ColorScheme cs) {
    final disciplines = ref.watch(disciplineConfigsProvider);
    final assignedCount = _rows.where((r) => r.disciplineId != null).length;
    final unassignedCount = _rows.length - assignedCount;

    // Discipline breakdown
    final discCounts = <String, int>{};
    for (final r in _rows) {
      if (r.disciplineName != null) {
        discCounts[r.disciplineName!] = (discCounts[r.disciplineName!] ?? 0) + 1;
      }
    }

    return Column(children: [
      // Stats bar
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: cs.primaryContainer.withValues(alpha: 0.15),
        child: Row(children: [
          Icon(Icons.people, size: 16, color: cs.primary),
          const SizedBox(width: 8),
          Text('${_rows.length} участников', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary)),
          const Spacer(),
          if (unassignedCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: cs.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('⚠ $unassignedCount без дисциплины', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.error)),
            ),
          if (unassignedCount == 0)
            Text('✅ Все назначены', style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
        ]),
      ),

      // Discipline breakdown chips
      if (discCounts.isNotEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Wrap(spacing: 6, runSpacing: 4, children: discCounts.entries.map((e) => Chip(
            label: Text('${e.key} (${e.value})', style: const TextStyle(fontSize: 11)),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          )).toList()),
        ),

      // Toolbar: select all, batch assign
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(children: [
          TextButton.icon(
            onPressed: () => setState(() => _selectedRows = Set<int>.from(List.generate(_rows.length, (i) => i))),
            icon: const Icon(Icons.select_all, size: 14), label: const Text('Все', style: TextStyle(fontSize: 11)),
          ),
          TextButton.icon(
            onPressed: () => setState(() => _selectedRows = Set<int>.from(
              List.generate(_rows.length, (i) => i).where((i) => _rows[i].disciplineId == null),
            )),
            icon: Icon(Icons.warning_amber, size: 14, color: cs.error),
            label: Text('Без дисциплины', style: TextStyle(fontSize: 11, color: cs.error)),
          ),
          const Spacer(),
          if (_selectedRows.isNotEmpty)
            PopupMenuButton<String>(
              tooltip: 'Назначить дисциплину выбранным',
              icon: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.sports, size: 14, color: cs.primary),
                const SizedBox(width: 4),
                Text('Назначить (${_selectedRows.length})', style: TextStyle(fontSize: 11, color: cs.primary, fontWeight: FontWeight.w600)),
                Icon(Icons.arrow_drop_down, size: 16, color: cs.primary),
              ]),
              onSelected: (discId) => _batchAssignDiscipline(discId, disciplines),
              itemBuilder: (ctx) => disciplines.map((d) => PopupMenuItem(
                value: d.id,
                child: Text(d.name, style: const TextStyle(fontSize: 13)),
              )).toList(),
            ),
        ]),
      ),
      const Divider(height: 1),

      // Participant list with discipline selectors
      Expanded(
        child: ListView.builder(
          itemCount: _rows.length,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          itemBuilder: (context, i) {
            final row = _rows[i];
            final isSelected = _selectedRows.contains(i);
            final name = row.fields[ImportField.name]?.trim() ?? '';
            final hasDisc = row.disciplineId != null;

            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: !hasDisc
                    ? cs.error.withValues(alpha: 0.04)
                    : isSelected
                        ? cs.primaryContainer.withValues(alpha: 0.1)
                        : cs.surfaceContainerHighest.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: !hasDisc
                      ? cs.error.withValues(alpha: 0.3)
                      : isSelected ? cs.primary.withValues(alpha: 0.3) : Colors.transparent,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(children: [
                  // Checkbox
                  SizedBox(
                    width: 28,
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) { _selectedRows.add(i); } else { _selectedRows.remove(i); }
                        });
                      },
                      activeColor: cs.primary,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),

                  // Name and details
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
                      Text(
                        [
                          if (row.fields[ImportField.gender] != null) row.fields[ImportField.gender]!,
                          if (row.fields[ImportField.city] != null) row.fields[ImportField.city]!,
                          if (row.fields[ImportField.club] != null) row.fields[ImportField.club]!,
                          if (row.fields[ImportField.dogName] != null) '🐕 ${row.fields[ImportField.dogName]}',
                        ].join(' · '),
                        style: TextStyle(fontSize: 10, color: cs.outline),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  )),

                  // Discipline selector
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 160,
                    child: AppSelect<String>(
                      label: '',
                      value: row.disciplineId,
                      items: disciplines.map((d) => SelectItem(
                        value: d.id,
                        label: d.name,
                      )).toList(),
                      onChanged: (v) {
                        final disc = disciplines.firstWhere((d) => d.id == v);
                        setState(() {
                          _rows[i] = row.copyWith(disciplineId: disc.id, disciplineName: disc.name);
                        });
                      },
                    ),
                  ),
                ]),
              ),
            );
          },
        ),
      ),

      // Import button
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2))),
        ),
        child: Column(children: [
          if (unassignedCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '⚠ $unassignedCount участников без дисциплины будут пропущены',
                style: TextStyle(fontSize: 12, color: cs.error),
              ),
            ),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: _selectedRows.isEmpty ? null : _doImport,
            icon: const Icon(Icons.download_done),
            label: Text('Импортировать ${_selectedRows.length} участников', style: const TextStyle(fontSize: 16)),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          )),
        ]),
      ),
    ]);
  }

  // ─── Batch assign discipline ───
  void _batchAssignDiscipline(String discId, List disciplines) {
    final disc = disciplines.firstWhere((d) => d.id == discId);
    setState(() {
      for (final i in _selectedRows) {
        _rows[i] = _rows[i].copyWith(disciplineId: disc.id, disciplineName: disc.name);
      }
    });
    AppSnackBar.success(context, '${disc.name} назначена ${_selectedRows.length} участникам');
  }
}

/// Строка импорта с назначенной дисциплиной.
class _ImportRow {
  final int index;
  final Map<ImportField, String> fields;
  final String? disciplineId;
  final String? disciplineName;

  const _ImportRow({
    required this.index,
    required this.fields,
    this.disciplineId,
    this.disciplineName,
  });

  _ImportRow copyWith({String? disciplineId, String? disciplineName}) => _ImportRow(
    index: index,
    fields: fields,
    disciplineId: disciplineId ?? this.disciplineId,
    disciplineName: disciplineName ?? this.disciplineName,
  );
}
