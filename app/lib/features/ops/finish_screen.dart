import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import 'package:sportos_app/domain/timing/timing.dart';

/// Screen ID: R2 — Финиш (с модалками R2.1–R2.4)
class FinishScreen extends ConsumerStatefulWidget {
  const FinishScreen({super.key});

  @override
  ConsumerState<FinishScreen> createState() => _FinishScreenState();
}

class _FinishScreenState extends ConsumerState<FinishScreen> {
  final ElapsedCalculator _elapsedCalc = const ElapsedCalculator();

  // ═══════════════════════════════════════
  // Actions
  // ═══════════════════════════════════════

  void _addMark() {
    HapticFeedback.heavyImpact();
    ref.read(raceSessionProvider.notifier).addMark();
    AppSnackBar.success(context, 'Отсечка зафиксирована!');
  }

  // R2.1 — BIB picker
  void _showBibPicker(String markId) {
    final cs = Theme.of(context).colorScheme;

    AppBottomSheet.show(
      context,
      title: 'Назначить BIB',
      initialHeight: 0.6,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Поиск по BIB / фамилии',
            prefixIcon: Icon(Icons.search, color: cs.primary),
            filled: true,
            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.5), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _buildGlassChip('Все', true, cs),
            const SizedBox(width: 8),
            _buildGlassChip('Скидж.', false, cs),
            const SizedBox(width: 8),
            _buildGlassChip('Нарты', false, cs),
          ]),
        ),
        const SizedBox(height: 16),
        Builder(builder: (ctx) {
          final session = ref.read(raceSessionProvider);
          if (session == null) return const SizedBox();
          return GridView.extent(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            maxCrossAxisExtent: 130,
            childAspectRatio: 1.25,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: session.startedAthletes.map((a) {
              final bibMarks = session.marking.marksForBib(a.bib).where((m) => m.type == MarkType.finish).toList();
              final isFinished = bibMarks.isNotEmpty;
              return AppBibTile(
                bib: a.bib,
                name: a.name,
                lapInfo: isFinished
                    ? _fmtDur(_elapsedCalc.netTime(a, bibMarks.last.correctedTime))
                    : 'На трассе',
                state: isFinished ? BibState.finished : BibState.available,
                onTap: isFinished ? null : () {
                  ref.read(raceSessionProvider.notifier).assignBib(markId, a.bib, entryId: a.bib);
                  Navigator.of(context, rootNavigator: true).pop();
                  AppSnackBar.success(context, 'BIB ${a.bib} назначен');
                },
              );
            }).toList(),
          );
        }),
      ]),
    );
  }

  Widget _buildGlassChip(String label, bool selected, ColorScheme cs) {
    return FilterChip(
      label: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal, color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant)),
      selected: selected,
      onSelected: (_) {},
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.2),
      selectedColor: cs.primaryContainer.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? cs.primary.withValues(alpha: 0.3) : cs.outlineVariant.withValues(alpha: 0.1)),
      ),
      showCheckmark: false,
    );
  }

  // R2.2 — Судейское решение
  void _showTimeEdit(TimeMark mark) {
    final cs = Theme.of(context).colorScheme;
    String status = 'OK';

    AppBottomSheet.show(
      context,
      title: 'Судейское решение — BIB ${mark.bib ?? '???'}',
      initialHeight: 0.8,
      actions: [
        AppButton.primary(
          text: 'Применить',
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            AppSnackBar.info(context, 'Решение применено → Audit Log');
          },
        ),
      ],
      child: StatefulBuilder(builder: (ctx, setModal) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Статус', style: Theme.of(ctx).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'OK', label: Text('OK')),
            ButtonSegment(value: 'DNS', label: Text('DNS')),
            ButtonSegment(value: 'DNF', label: Text('DNF')),
            ButtonSegment(value: 'DSQ', label: Text('DSQ')),
          ],
          selected: {status},
          onSelectionChanged: (s) => setModal(() => status = s.first),
        ),
        const SizedBox(height: 16),
        Text('Штрафы / Компенсации', style: Theme.of(ctx).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ActionChip(avatar: Icon(Icons.add_circle, size: 16, color: cs.error), label: const Text('+15 с'), onPressed: () {}),
          ActionChip(avatar: Icon(Icons.add_circle, size: 16, color: cs.error), label: const Text('+1 мин'), onPressed: () {}),
          ActionChip(avatar: Icon(Icons.remove_circle, size: 16, color: cs.primary), label: const Text('−15 с'), onPressed: () {}),
        ]),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.all(12),
          children: [
            Text('Ручное время', style: Theme.of(ctx).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              decoration: _glassInputDecoration('Точное время (HH:mm:ss.SSS)', cs),
              controller: TextEditingController(text: _fmtDurMs(mark.correctedTime.difference(ref.read(raceSessionProvider)!.clock.zeroTime!))),
            ),
            const SizedBox(height: 16),
            Text('Обоснование', style: Theme.of(ctx).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              decoration: _glassInputDecoration('Правило 4.2.1, нарушение зоны...', cs),
              maxLines: 2,
            ),
          ]
        ),
        const SizedBox(height: 12),
        Row(children: [
          Icon(Icons.warning_amber, color: cs.tertiary, size: 16),
          const SizedBox(width: 4),
          Text('Запись в Audit Log', style: TextStyle(color: cs.tertiary, fontSize: 11)),
        ]),
      ])),
    );
  }

  // R2.3 — Вставка метки
  void _showInsertMark() {
    final cs = Theme.of(context).colorScheme;
    AppBottomSheet.show(
      context,
      title: 'Вставить метку',
      initialHeight: 0.5,
      actions: [
        AppButton.primary(
          text: 'Добавить',
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            ref.read(raceSessionProvider.notifier).insertMark(DateTime.now(), reason: 'Ручная вставка');
            AppSnackBar.info(context, 'Метка добавлена → Audit Log');
          },
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            padding: const EdgeInsets.all(12),
            children: [
              TextField(decoration: _glassInputDecoration('Время (HH:mm:ss.SSS)', cs)),
              const SizedBox(height: 12),
              TextField(decoration: _glassInputDecoration('BIB (опционально)', cs)),
              const SizedBox(height: 12),
              TextField(decoration: _glassInputDecoration('Причина *', cs, hint: 'Не сработал сенсор...'), maxLines: 2),
            ]
          ),
        ],
      ),
    );
  }

  void _showTimeSyncWizard() {
    final cs = Theme.of(context).colorScheme;
    AppBottomSheet.show(
      context,
      title: 'Мастер Времени (Финиш)',
      initialHeight: 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Это устройство транслирует точное время (NTP) по Mesh-сети.'),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(16),
            children: [
              const ListTile(leading: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)), title: Text('Ожидание подключений...')),
              const Divider(),
              AppStatusRow(icon: Icons.smartphone, title: 'Стартёр (Samsung S21)', subtitle: 'Синхронизировано (Δ = -0.012 с)', trailing: Icon(Icons.check_circle, color: cs.primary)),
              AppStatusRow(icon: Icons.smartphone, title: 'Маршал КП1 (iPhone 12)', subtitle: 'Синхронизировано (Δ = +0.034 с)', trailing: Icon(Icons.check_circle, color: cs.primary)),
            ]
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════

  String _fmtDur(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _fmtDurMs(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds.remainder(1000)).toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  InputDecoration _glassInputDecoration(String label, ColorScheme cs, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.5), width: 2)),
      isDense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final session = ref.watch(raceSessionProvider);
    if (session == null) {
      return Scaffold(
        appBar: AppAppBar(title: const Text('Финиш')),
        body: const Center(child: Text('Нет активной сессии.')),
      );
    }
    final marks = session.marking.marks;
    final finishCount = session.marking.finishedCount;
    final startedAthletes = session.startedAthletes;
    final totalAthletes = startedAthletes.length;

    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Финиш'),
        actions: [
          IconButton(icon: const Icon(Icons.add_circle_outline), tooltip: 'Вставить метку', onPressed: _showInsertMark),
          IconButton(icon: const Icon(Icons.sync_alt), tooltip: 'Синхронизация', onPressed: _showTimeSyncWizard),
        ],
      ),
      body: Column(children: [
        // ── Инфо-панель (Bento) ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(children: [
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(session.config.name, style: TextStyle(fontSize: 13, color: cs.onSurface, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text('Мастер Времени', style: TextStyle(fontSize: 10, color: cs.primary, fontWeight: FontWeight.bold)),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              backgroundColor: cs.primaryContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              children: [
                Row(children: [
                  Icon(Icons.flag, size: 14, color: cs.primary),
                  const SizedBox(width: 6),
                  Text('$finishCount/$totalAthletes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: cs.primary)),
                ]),
              ],
            ),
          ]),
        ),

        // ── Список отсечек ──
        Expanded(
          child: ListView.builder(
            itemCount: marks.length,
            itemBuilder: (context, index) {
              final mark = marks[index];
              final assigned = mark.isAssigned;
              final raceTime = mark.correctedTime.difference(session.clock.zeroTime!);

              // Formatted time
              String timeStr;
              if (assigned) {
                final athlete = session.startList.findByBib(mark.bib!);
                if (athlete != null) {
                  timeStr = _fmtDurMs(_elapsedCalc.netTime(athlete, mark.correctedTime));
                } else {
                  timeStr = _fmtDurMs(raceTime);
                }
              } else {
                timeStr = _fmtDurMs(raceTime);
              }

              return Dismissible(
                key: ValueKey('mark-${mark.id}'),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async {
                  if (!assigned) return true;
                  return AppDialog.confirm(context, title: 'Удалить метку?', message: 'BIB ${mark.bib} — $timeStr\nМетка будет удалена. Продолжить?');
                },
                onDismissed: (_) => ref.read(raceSessionProvider.notifier).deleteMark(mark.id),
                background: Container(color: cs.error, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), child: Icon(Icons.delete, color: cs.onError)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    backgroundColor: assigned ? cs.surfaceContainerHighest.withValues(alpha: 0.15) : cs.tertiaryContainer.withValues(alpha: 0.1),
                    borderColor: assigned ? cs.outlineVariant.withValues(alpha: 0.15) : cs.tertiary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    children: [
                      InkWell(
                        onTap: () => assigned ? null : _showBibPicker(mark.id),
                        onLongPress: () => _showTimeEdit(mark),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(color: (assigned ? cs.primary : cs.tertiary).withValues(alpha: 0.1), shape: BoxShape.circle),
                              child: Center(child: Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: assigned ? cs.primary : cs.tertiary))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(timeStr, style: TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.w900, color: cs.onSurface)),
                                const SizedBox(height: 4),
                                if (assigned)
                                  Row(children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: cs.surface.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(4)),
                                      child: Text('BIB ${mark.bib}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: cs.onSurfaceVariant)),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(session.startList.findByBib(mark.bib!)?.name ?? '?', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600, fontSize: 12)),
                                  ])
                                else
                                  Text('Назначить BIB', style: TextStyle(color: cs.tertiary, fontWeight: FontWeight.bold, fontSize: 13)),
                              ]),
                            ),
                            Icon(assigned ? Icons.check_circle : Icons.touch_app, color: assigned ? cs.primary : cs.tertiary, size: 24),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // ── Большая кнопка ОТСЕЧКА ──
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: AppCard(
              padding: EdgeInsets.zero,
              backgroundColor: cs.errorContainer.withValues(alpha: 0.1),
              borderColor: cs.error.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(24),
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _addMark,
                    splashColor: cs.error.withValues(alpha: 0.2),
                    highlightColor: cs.error.withValues(alpha: 0.1),
                    child: Container(
                      width: double.infinity,
                      height: 120,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.timer_sharp, size: 40, color: cs.error),
                          const SizedBox(height: 8),
                          Text('ОТСЕЧКА', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: cs.error, letterSpacing: 3)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}
