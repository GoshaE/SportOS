import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import 'package:sportos_app/domain/timing/timing.dart';

/// Screen ID: R3 — Маршал (с модалками R3.1–R3.3)
class MarshalScreen extends StatefulWidget {
  const MarshalScreen({super.key});

  @override
  State<MarshalScreen> createState() => _MarshalScreenState();
}

class _MarshalScreenState extends State<MarshalScreen> {
  bool _isSynced = false;

  // ── Timing Engine ──
  late final RaceClock _raceClock;
  late final StartListService _startListService;
  late final MarkingService _markingService;
  final ElapsedCalculator _elapsedCalc = const ElapsedCalculator();

  @override
  void initState() {
    super.initState();

    final raceStart = DateTime.now().subtract(const Duration(minutes: 10));

    final config = DisciplineConfig(
      id: 'disc-marshal',
      name: 'Sprint 5km',
      distanceKm: 5.0,
      startType: StartType.individual,
      interval: const Duration(seconds: 30),
      firstStartTime: raceStart,
      laps: 3,
      minLapTime: const Duration(seconds: 10),
    );

    _raceClock = RaceClock();
    _raceClock.start(raceStart);

    _startListService = StartListService(config: config);
    _startListService.buildStartList([
      (entryId: 'e1', bib: '07', name: 'Петров', category: 'Скидж.', waveId: null),
      (entryId: 'e2', bib: '12', name: 'Сидоров', category: 'Скидж.', waveId: null),
      (entryId: 'e3', bib: '24', name: 'Иванов', category: 'Нарты', waveId: null),
      (entryId: 'e4', bib: '31', name: 'Козлов', category: 'Нарты', waveId: null),
      (entryId: 'e5', bib: '42', name: 'Морозов', category: 'Скидж.', waveId: null),
      (entryId: 'e6', bib: '55', name: 'Волков', category: 'Пулка', waveId: null),
      (entryId: 'e7', bib: '63', name: 'Лебедев', category: 'Скидж.', waveId: null),
      (entryId: 'e8', bib: '77', name: 'Новиков', category: 'Нарты', waveId: null),
      (entryId: 'e9', bib: '88', name: 'Кузнецов', category: 'Скидж.', waveId: null),
    ]);

    // Все стартовали
    for (final entry in _startListService.all) {
      _startListService.markStarted(entry.bib, actualTime: entry.plannedStartTime);
    }

    _markingService = MarkingService(
      minLapTime: const Duration(seconds: 10),
      totalLaps: 3,
    );
  }

  @override
  void dispose() {
    _raceClock.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════
  // Marking actions
  // ═══════════════════════════════════════

  bool _isMarked(String bib) => _markingService.marksForBib(bib).isNotEmpty;

  void _tryTogglePassed(String bib) {
    if (!mounted) return;
    if (_isMarked(bib)) {
      _togglePassed(bib);
    } else if (!_isSynced) {
      AppDialog.confirm(
        context,
        title: 'Нет синхронизации',
        message: 'Связь с Мастер-нодой (Финишем) отсутствует.\nЗаписанное время сплита может быть неточным!',
        confirmText: 'Записать всё равно',
        isDanger: true,
      ).then((ok) {
        if (ok == true && mounted) {
          _togglePassed(bib);
        }
      });
    } else {
      _togglePassed(bib);
    }
  }

  void _togglePassed(String bib) {
    if (_isMarked(bib)) {
      AppDialog.confirm(context, title: 'Отменить отметку BIB $bib?', message: 'Атлет будет снова показан как "не прошёл", а время отсечки будет удалено.').then((ok) {
        if (ok == true) {
          setState(() {
            final bibMarks = _markingService.marksForBib(bib);
            for (final m in bibMarks) {
              _markingService.deleteMark(m.id);
            }
          });
        }
      });
    } else {
      HapticFeedback.mediumImpact();
      setState(() {
        final mark = _markingService.addMark(type: MarkType.checkpoint);
        _markingService.assignBib(mark.id, bib, entryId: bib);
      });

      final athlete = _startListService.findByBib(bib);
      final bibMarks = _markingService.marksForBib(bib);
      if (athlete != null && bibMarks.isNotEmpty) {
        final elapsed = _elapsedCalc.netTime(athlete, bibMarks.last.correctedTime);
        AppSnackBar.success(context, 'BIB $bib — отсечка: ${_fmtDur(elapsed)}');
      }
    }
  }

  // ═══════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════

  String _fmtDur(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  // ═══════════════════════════════════════
  // R3.1 — Нарушение
  // ═══════════════════════════════════════
  void _showViolation(String bib, String name) {
    final cs = Theme.of(context).colorScheme;
    AppBottomSheet.show(
      context,
      title: 'Нарушение — BIB $bib $name',
      initialHeight: 0.65,
      actions: [
        SizedBox(width: double.infinity, child: FilledButton(
          style: FilledButton.styleFrom(backgroundColor: cs.tertiary),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            AppSnackBar.info(context, 'Нарушение BIB $bib → отправлено судье');
          },
          child: const Text('Отправить судье', style: TextStyle(fontSize: 16)),
        )),
      ],
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Тип нарушения:', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ChoiceChip(label: const Text('Помеха обгоняющему'), selected: false, onSelected: (_) {}),
          ChoiceChip(label: const Text('Срезка трассы'), selected: true, onSelected: (_) {}),
          ChoiceChip(label: const Text('Грубость с собакой'), selected: false, onSelected: (_) {}),
          ChoiceChip(label: const Text('Посторонняя помощь'), selected: false, onSelected: (_) {}),
          ChoiceChip(label: const Text('Потеря собаки'), selected: false, onSelected: (_) {}),
          ChoiceChip(label: const Text('Фальстарт'), selected: false, onSelected: (_) {}),
          ChoiceChip(label: const Text('Другое'), selected: false, onSelected: (_) {}),
        ]),
        const SizedBox(height: 4),
        AppInfoBanner.info(title: 'Наказание назначает судья. Маршал только фиксирует факт нарушения.'),
        const SizedBox(height: 12),
        const TextField(decoration: InputDecoration(labelText: 'Описание нарушения', border: OutlineInputBorder(), hintText: 'Cобака без поводка, помощь извне...'), maxLines: 2),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.camera_alt), label: const Text('Прикрепить фото')),
      ]),
    );
  }

  // R3.2 — DNF
  void _showDnfRequest(String bib, String name) {
    final cs = Theme.of(context).colorScheme;
    AppBottomSheet.show(
      context,
      title: 'Запрос DNF — BIB $bib',
      initialHeight: 0.5,
      actions: [
        AppButton.primary(
          text: 'Запросить DNF',
          backgroundColor: cs.error,
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            AppSnackBar.info(context, 'DNF запрос BIB $bib → ожидает подтверждения');
          },
        ),
      ],
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text('Этап 1: Маршал запрашивает DNF\nЭтап 2: Главный судья подтверждает или отклоняет', style: TextStyle(color: cs.onSurfaceVariant)),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.all(12),
          children: const [
            TextField(decoration: InputDecoration(labelText: 'Причина DNF *', border: OutlineInputBorder(), hintText: 'Атлет сошёл с трассы, травма собаки...'), maxLines: 2),
          ]
        ),
      ]),
    );
  }

  // R3.3 — SOS
  void _showSos() {
    final cs = Theme.of(context).colorScheme;
    AppBottomSheet.show(
      context,
      title: 'ЭКСТРЕННАЯ СИТУАЦИЯ',
      initialHeight: 0.65,
      actions: [
        AppButton.primary(
          text: 'ОТПРАВИТЬ SOS',
          backgroundColor: cs.error,
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            AppSnackBar.error(context, 'SOS ОТПРАВЛЕН! → alert всему mesh');
          },
        ),
      ],
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppInfoBanner.error(title: 'Alert будет отправлен на ВСЕ устройства в mesh-сети!'),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.all(12),
          children: [
            const TextField(decoration: InputDecoration(labelText: 'Checkpoint', border: OutlineInputBorder(), hintText: '3 км')),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Описание ситуации *', border: OutlineInputBorder(), hintText: 'Травма атлета, собака убежала...'), maxLines: 3),
            const SizedBox(height: 12),
            Text('Время и GPS будут зафиксированы автоматически', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
          ]
        ),
      ]),
    );
  }

  void _showTimeSyncWizard() {
    AppBottomSheet.show(
      context,
      title: 'Авто-Синхронизация Часов',
      initialHeight: 0.5,
      actions: [
        AppButton.primary(
          text: 'Симулировать успех',
          onPressed: () {
            setState(() => _isSynced = true);
            Navigator.of(context, rootNavigator: true).pop();
            AppSnackBar.success(context, 'Часы синхронизированы! (Δ = +0.034 с)');
          },
        ),
      ],
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('SportOS автоматически ищет Финиш (Master Node) по Mesh-сети для выравнивания таймеров.'),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.all(12),
          children: const [
            ListTile(leading: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)), title: Text('Поиск Master Node...')),
          ]
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final athletes = _startListService.all;
    final passedCount = _markingService.assigned.length;

    // Сортировка: непрошедшие первые
    final sorted = List<StartEntry>.from(athletes)
      ..sort((a, b) {
        final ap = _isMarked(a.bib);
        final bp = _isMarked(b.bib);
        if (ap == bp) return 0;
        return ap ? 1 : -1;
      });

    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Маршал'),
        actions: [
          IconButton(icon: Icon(Icons.bluetooth_connected, color: _isSynced ? cs.primary : cs.onSurfaceVariant), onPressed: () {}),
          IconButton(icon: Icon(Icons.sync_alt, color: _isSynced ? cs.primary : cs.tertiary), onPressed: _showTimeSyncWizard),
        ],
      ),
      body: Column(children: [
        // ── Предупреждение ──
        if (!_isSynced) Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: AppCard(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
            backgroundColor: cs.tertiaryContainer.withValues(alpha: 0.2),
            borderColor: cs.tertiary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            children: [
              Row(children: [
                Icon(Icons.warning_amber, size: 16, color: cs.tertiary),
                const SizedBox(width: 6),
                Expanded(child: Text('Время не синхронизировано с Финишем', style: TextStyle(color: cs.tertiary, fontWeight: FontWeight.bold, fontSize: 12))),
              ]),
            ],
          ),
        ),

        // ── Инфо-панель ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(children: [
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                children: [
                  Row(children: [
                    Icon(Icons.location_on, size: 18, color: cs.primary),
                    const SizedBox(width: 6),
                    Text('Checkpoint: 3 км', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
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
                  Icon(Icons.people_alt, size: 14, color: cs.primary),
                  const SizedBox(width: 6),
                  Text('$passedCount/${athletes.length}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: cs.primary)),
                ]),
              ],
            ),
          ]),
        ),

        // ── BIB Grid ──
        Expanded(
          child: GridView.extent(
            maxCrossAxisExtent: 130,
            childAspectRatio: 0.9,
            padding: const EdgeInsets.all(16),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: sorted.map((a) {
              final passed = _isMarked(a.bib);
              String? timeStr;
              if (passed) {
                final bibMarks = _markingService.marksForBib(a.bib);
                if (bibMarks.isNotEmpty) {
                  timeStr = _fmtDur(_elapsedCalc.netTime(a, bibMarks.last.correctedTime));
                }
              }

              return GestureDetector(
                onLongPress: () => AppBottomSheet.show(context,
                  title: 'BIB ${a.bib} — ${a.name}',
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    ListTile(leading: Icon(Icons.gavel, color: cs.tertiary), title: const Text('Зафиксировать нарушение'), onTap: () { Navigator.of(context, rootNavigator: true).pop(); _showViolation(a.bib, a.name); }),
                    ListTile(leading: Icon(Icons.block, color: cs.error), title: const Text('Запрос DNF'), onTap: () { Navigator.of(context, rootNavigator: true).pop(); _showDnfRequest(a.bib, a.name); }),
                  ]),
                ),
                child: AppBibTile(
                  bib: a.bib,
                  name: a.name,
                  lapInfo: passed ? timeStr : a.categoryName,
                  state: passed ? BibState.finished : BibState.available,
                  onTap: () => _tryTogglePassed(a.bib),
                ),
              );
            }).toList(),
          ),
        ),

        // ── Кнопки ──
        SafeArea(
          child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [
            Expanded(child: SizedBox(height: 52, child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: cs.tertiary),
              onPressed: () => _showViolation('—', '(выбрать)'),
              icon: const Icon(Icons.gavel), label: const Text('Нарушение'),
            ))),
            const SizedBox(width: 8),
            Expanded(child: SizedBox(height: 52, child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: cs.error),
              onPressed: _showSos,
              icon: const Icon(Icons.emergency), label: const Text('SOS'),
            ))),
          ])),
        ),
      ]),
    );
  }
}
