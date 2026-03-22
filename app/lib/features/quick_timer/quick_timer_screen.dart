import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../domain/quick_timer/quick_timer_models.dart';
import '../../domain/quick_timer/quick_timer_providers.dart';
import '../../domain/timing/time_formatter.dart';
import '../../domain/timing/result_table.dart';

/// QT — Единый экран быстрого секундомера.
///
/// Точка входа: `/quick-timer`. Сессия создаётся автоматически.
/// Настройки — через кнопку ⚙️ в AppBar (bottom sheet).
/// Добавление участников — на лету через вкладку Старт.
///
/// 3 закладки: Старт · Финиш · Таблица
///
/// Компоненты: [AppResultTable], [AppInfoBanner], [AppQueueItem],
/// [AppBibTile], [AppStatCard], [AppBottomSheet], [AppButton],
/// [AppUserTile], [AppTextField].
class QuickTimerScreen extends ConsumerStatefulWidget {
  const QuickTimerScreen({super.key});

  @override
  ConsumerState<QuickTimerScreen> createState() => _QuickTimerScreenState();
}

class _QuickTimerScreenState extends ConsumerState<QuickTimerScreen>
    with SingleTickerProviderStateMixin {
  Timer? _uiTimer;
  Duration _elapsed = Duration.zero;
  late TabController _tabCtrl;
  bool _showCards = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);

    // Авто-создание пустой сессии если нет
    Future.microtask(() {
      final session = ref.read(quickSessionProvider);
      if (session == null) {
        ref.read(quickSessionProvider.notifier).createSession(
          mode: QuickStartMode.mass,
          totalLaps: 1,
          athletes: [],
        );
      }
    });

    _uiTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final s = ref.read(quickSessionProvider);
      if (s == null || s.status != QuickSessionStatus.running || !mounted) return;
      final start = s.globalStartTime;
      if (start != null) {
        setState(() => _elapsed = DateTime.now().difference(start));
      }
      if (s.mode == QuickStartMode.interval) {
        _autoStartCheck(s);
      }
    });
  }

  void _autoStartCheck(QuickSession session) {
    if (session.globalStartTime == null) return;
    final now = DateTime.now();
    final sorted = [...session.athletes]
      ..sort((a, b) => a.startOrder.compareTo(b.startOrder));
    for (final a in sorted) {
      if (a.startTime != null) continue;
      final planned = session.plannedStartTime(a);
      if (planned == null) continue;
      if (now.isAfter(planned) || now.isAtSameMomentAs(planned)) {
        ref.read(quickSessionProvider.notifier).startIndividualAt(a.id, planned);
      } else {
        break;
      }
    }
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _tabCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════
  // Actions
  // ═══════════════════════════════════════

  void _startMass() {
    final session = ref.read(quickSessionProvider);
    if (session == null || session.athletes.isEmpty) {
      AppSnackBar.info(context, 'Добавьте участников');
      return;
    }
    HapticFeedback.heavyImpact();
    ref.read(quickSessionProvider.notifier).startMass();
  }

  void _startIndividual(String athleteId) {
    HapticFeedback.mediumImpact();
    ref.read(quickSessionProvider.notifier).startIndividual(athleteId);
  }

  void _recordSplit(String athleteId) {
    HapticFeedback.heavyImpact();
    ref.read(quickSessionProvider.notifier).recordSplit(athleteId);
    final session = ref.read(quickSessionProvider);
    if (session == null) return;

    final athlete = session.athletes.firstWhere((a) => a.id == athleteId);
    final displayName = athlete.name.isNotEmpty ? athlete.name : 'BIB ${athlete.bib}';

    if (session.allFinished) {
      ref.read(quickSessionProvider.notifier).finishSession();
      ref.read(quickSessionProvider.notifier).saveToHistory();
      ref.read(quickHistoryProvider.notifier).refresh();
      if (mounted) {
        _tabCtrl.animateTo(2);
        AppSnackBar.success(context, 'Все финишировали! Результаты сохранены.');
      }
    } else if (mounted) {
      // SnackBar с кнопкой Отменить
      AppSnackBar.withUndo(
        context,
        '⏱ Отсечка: $displayName',
        onUndo: () {
          ref.read(quickSessionProvider.notifier).undoLastSplit(athleteId);
          HapticFeedback.mediumImpact();
        },
      );
    }
  }

  void _undoSplitWithConfirm(String athleteId) async {
    final session = ref.read(quickSessionProvider);
    if (session == null) return;
    final athlete = session.athletes.firstWhere((a) => a.id == athleteId);
    final displayName = athlete.name.isNotEmpty ? athlete.name : 'BIB ${athlete.bib}';
    final laps = athlete.completedLaps;

    final confirm = await AppDialog.confirm(
      context,
      title: 'Отменить отсечку?',
      message: '$displayName — круг $laps/${session.totalLaps}\nПоследняя отсечка будет удалена.',
    );
    if (confirm == true) {
      HapticFeedback.mediumImpact();
      ref.read(quickSessionProvider.notifier).undoLastSplit(athleteId);
      if (mounted) {
        AppSnackBar.info(context, 'Отсечка $displayName отменена');
      }
    }
  }

  void _removeAthleteWithConfirm(String athleteId) async {
    final session = ref.read(quickSessionProvider);
    if (session == null) return;
    final athlete = session.athletes.firstWhere((a) => a.id == athleteId);
    final displayName = athlete.name.isNotEmpty ? athlete.name : 'BIB ${athlete.bib}';

    final confirm = await AppDialog.confirm(
      context,
      title: 'Удалить участника?',
      message: '$displayName будет удалён из сессии.',
    );
    if (confirm == true) {
      HapticFeedback.mediumImpact();
      ref.read(quickSessionProvider.notifier).removeAthlete(athleteId);
      setState(() {});
      if (mounted) {
        AppSnackBar.info(context, '$displayName удалён');
      }
    }
  }

  void _finishManually() {
    ref.read(quickSessionProvider.notifier).finishSession();
    ref.read(quickSessionProvider.notifier).saveToHistory();
    ref.read(quickHistoryProvider.notifier).refresh();
    if (mounted) {
      _tabCtrl.animateTo(2);
      AppSnackBar.success(context, 'Сессия завершена. Результаты сохранены.');
    }
  }

  void _resetSession() {
    ref.read(quickSessionProvider.notifier).createSession(
      mode: QuickStartMode.mass,
      totalLaps: 1,
      athletes: [],
    );
    _elapsed = Duration.zero;
    setState(() {});
    _tabCtrl.animateTo(0);
    AppSnackBar.info(context, 'Новая сессия создана');
  }

  // ═══════════════════════════════════════
  // Settings Bottom Sheet ⚙️
  // ═══════════════════════════════════════

  void _showSettingsSheet() {
    final session = ref.read(quickSessionProvider);
    if (session == null) return;
    final isRunning = session.status == QuickSessionStatus.running;

    var mode = session.mode;
    var laps = session.totalLaps;
    var interval = session.intervalSeconds;

    AppBottomSheet.show(
      context,
      title: 'Настройки сессии',
      initialHeight: 0.55,
      child: StatefulBuilder(
        builder: (context, setSheetState) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Режим старта ──
            Text('РЕЖИМ СТАРТА', style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 1,
            )),
            const SizedBox(height: 8),
            SegmentedButton<QuickStartMode>(
              segments: const [
                ButtonSegment(value: QuickStartMode.mass, label: Text('Масс'), icon: Icon(Icons.groups)),
                ButtonSegment(value: QuickStartMode.interval, label: Text('Интервал'), icon: Icon(Icons.timer)),
                ButtonSegment(value: QuickStartMode.manual, label: Text('Ручной'), icon: Icon(Icons.touch_app)),
              ],
              selected: {mode},
              onSelectionChanged: isRunning ? null : (s) {
                setSheetState(() => mode = s.first);
                ref.read(quickSessionProvider.notifier).updateSettings(mode: mode);
                setState(() {}); // refresh main screen
              },
            ),
            const SizedBox(height: 8),
            AppInfoBanner.info(
              title: mode == QuickStartMode.mass
                  ? 'Все стартуют одновременно'
                  : mode == QuickStartMode.interval
                      ? 'Автоматический старт через интервал'
                      : 'Тренер запускает каждого вручную',
            ),

            const SizedBox(height: 16),
            // ── Количество кругов ──
            Text('КОЛИЧЕСТВО КРУГОВ', style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 1,
            )),
            const SizedBox(height: 8),
            Row(children: [
              for (final n in [1, 2, 3, 4, 5])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('$n'),
                    selected: laps == n,
                    onSelected: (_) {
                      setSheetState(() => laps = n);
                      ref.read(quickSessionProvider.notifier).updateSettings(totalLaps: n);
                      setState(() {});
                    },
                  ),
                ),
            ]),

            // ── Интервал (только для interval mode) ──
            if (mode == QuickStartMode.interval) ...[
              const SizedBox(height: 16),
              Text('ИНТЕРВАЛ МЕЖДУ СТАРТАМИ', style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 1,
              )),
              const SizedBox(height: 8),
              Row(children: [
                for (final sec in [15, 30, 45, 60])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      // ignore: unnecessary_brace_in_string_interps
                      label: Text('${sec}с'),
                      selected: interval == sec,
                      onSelected: isRunning ? null : (_) {
                        setSheetState(() => interval = sec);
                        ref.read(quickSessionProvider.notifier).updateSettings(intervalSeconds: sec);
                        setState(() {});
                      },
                    ),
                  ),
              ]),
            ],

            const SizedBox(height: 16),
            // ── Группы ──
            Row(children: [
              Expanded(
                child: AppButton.small(
                  text: 'Из книги',
                  icon: Icons.folder_open,
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    _showGroupPicker();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton.smallSecondary(
                  text: 'Сохранить',
                  icon: Icons.save_alt,
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    _saveCurrentGroup();
                  },
                ),
              ),
            ]),

            // ── Новая сессия ──
            if (session.status == QuickSessionStatus.finished) ...[
              const SizedBox(height: 16),
              AppButton.danger(
                text: 'Новая сессия',
                icon: Icons.refresh,
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  _resetSession();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // Add athlete on-the-fly
  // ═══════════════════════════════════════

  void _showAddAthleteSheet() {
    final session = ref.read(quickSessionProvider);
    final nextBib = '${(session?.athletes.length ?? 0) + 1}';
    final nameCtrl = TextEditingController();
    final surnameCtrl = TextEditingController();
    final bibCtrl = TextEditingController(text: nextBib);

    AppBottomSheet.show(
      context,
      title: 'Добавить участника',
      initialHeight: 0.45,
      actions: [
        AppButton.primary(
          text: 'Добавить',
          icon: Icons.add,
          onPressed: () {
            final name = '${nameCtrl.text.trim()} ${surnameCtrl.text.trim()}'.trim();
            if (name.isEmpty) {
              AppSnackBar.info(context, 'Введите имя');
              return;
            }
            ref.read(quickSessionProvider.notifier).addAthlete(
              name: name,
              bib: bibCtrl.text.trim(),
            );
            setState(() {});
            Navigator.of(context, rootNavigator: true).pop();
          },
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: AppTextField(label: 'Имя', controller: nameCtrl, hintText: 'Алексей', autofocus: true)),
            const SizedBox(width: 12),
            Expanded(child: AppTextField(label: 'Фамилия', controller: surnameCtrl, hintText: 'Иванов')),
          ]),
          const SizedBox(height: 12),
          AppTextField(
            label: 'BIB (номер)',
            controller: bibCtrl,
            hintText: nextBib,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // Groups (coach's book)
  // ═══════════════════════════════════════

  void _showGroupPicker() {
    final groups = ref.read(savedGroupsProvider);
    if (groups.isEmpty) {
      AppSnackBar.info(context, 'Нет сохранённых групп');
      return;
    }
    final cs = Theme.of(context).colorScheme;
    AppBottomSheet.show(
      context,
      title: 'Книга тренера',
      initialHeight: 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppInfoBanner.info(title: 'Загрузите сохранённую группу', subtitle: 'Участники будут добавлены.'),
          const SizedBox(height: 12),
          ...groups.map((g) => AppUserTile(
            name: g.name,
            subtitle: '${g.members.length} участник(ов)',
            leading: CircleAvatar(
              backgroundColor: cs.primaryContainer,
              child: Icon(Icons.group, color: cs.primary, size: 20),
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
              onPressed: () {
                ref.read(savedGroupsProvider.notifier).delete(g.id);
                Navigator.of(context, rootNavigator: true).pop();
                AppSnackBar.info(context, 'Группа удалена');
              },
            ),
            onTap: () {
              for (final m in g.members) {
                ref.read(quickSessionProvider.notifier).addAthlete(name: m.name, bib: m.defaultBib);
              }
              setState(() {});
              Navigator.of(context, rootNavigator: true).pop();
              AppSnackBar.success(context, 'Группа «${g.name}» загружена');
            },
          )),
        ],
      ),
    );
  }

  void _saveCurrentGroup() {
    final session = ref.read(quickSessionProvider);
    if (session == null || session.athletes.isEmpty) {
      AppSnackBar.info(context, 'Добавьте участников');
      return;
    }
    final nameCtrl = TextEditingController();
    AppBottomSheet.show(
      context,
      title: 'Сохранить как группу',
      initialHeight: 0.35,
      actions: [
        AppButton.primary(
          text: 'Сохранить',
          icon: Icons.save,
          onPressed: () {
            final name = nameCtrl.text.trim();
            if (name.isEmpty) return;
            final group = SavedGroup(
              id: 'grp-${DateTime.now().millisecondsSinceEpoch}',
              name: name,
              members: session.athletes
                  .map((a) => SavedGroupMember(name: a.name, defaultBib: a.bib))
                  .toList(),
            );
            ref.read(savedGroupsProvider.notifier).save(group);
            Navigator.of(context, rootNavigator: true).pop();
            AppSnackBar.success(context, 'Группа «$name» сохранена');
          },
        ),
      ],
      child: AppTextField(label: 'Название группы', hintText: 'Младшая группа', controller: nameCtrl, autofocus: true),
    );
  }

  // ═══════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════

  String _fmtCountdown(Duration d) {
    if (d.isNegative) {
      final abs = d.abs();
      final m = abs.inMinutes.remainder(60).toString().padLeft(2, '0');
      final s = abs.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '+$m:$s';
    }
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ═══════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final session = ref.watch(quickSessionProvider);

    if (session == null) {
      return Scaffold(
        appBar: AppAppBar(forceBackButton: true, title: const Text('Секундомер')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isRunning = session.status == QuickSessionStatus.running;
    final isFinished = session.status == QuickSessionStatus.finished;

    return Scaffold(
      appBar: AppAppBar(
        forceBackButton: true,
        title: const Text('Секундомер'),
        actions: [
          // ⚙️ Настройки
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Настройки',
            onPressed: _showSettingsSheet,
          ),
          // Общий таймер
          if (isRunning) Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cs.errorContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              TimeFormatter.full(_elapsed),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'monospace', color: cs.error),
            ),
          ),
          // Счётчик финиша
          if (session.athletes.isNotEmpty) Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.flag, size: 14, color: cs.primary),
              const SizedBox(width: 4),
              Text('${session.finishedCount}/${session.athletes.length}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: cs.primary)),
            ]),
          ),
          // Стоп
          if (isRunning)
            IconButton(
              icon: Icon(Icons.stop_circle, color: cs.error),
              tooltip: 'Завершить',
              onPressed: () async {
                final confirm = await AppDialog.confirm(
                  context,
                  title: 'Завершить сессию?',
                  message: 'Результаты будут сохранены.',
                );
                if (confirm == true) _finishManually();
              },
            ),
          // История
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'История',
            onPressed: () => context.push('/quick-timer/history'),
          ),
        ],
        bottom: AppPillTabBar(
          controller: _tabCtrl,
          tabs: const ['Старт', 'Финиш', 'Таблица'],
          icons: const [Icons.play_arrow, Icons.flag, Icons.leaderboard],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildStartTab(session, cs, isRunning, isFinished),
          _buildFinishTab(session, cs, isRunning),
          _buildTableTab(session, cs),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // Tab 1: СТАРТ
  // ═══════════════════════════════════════
  Widget _buildStartTab(QuickSession session, ColorScheme cs, bool isRunning, bool isFinished) {
    final isMass = session.mode == QuickStartMode.mass;
    final isInterval = session.mode == QuickStartMode.interval;
    final current = session.currentStarter;
    final startedCount = session.startedCount;
    final totalCount = session.athletes.length;
    final sorted = [...session.athletes]
      ..sort((a, b) => a.startOrder.compareTo(b.startOrder));

    // Обратный отсчёт
    Duration? countdown;
    if (isInterval && current != null && session.globalStartTime != null) {
      final planned = session.plannedStartTime(current);
      if (planned != null) countdown = planned.difference(DateTime.now());
    }
    final isUrgent = countdown != null && countdown.inSeconds <= 5 && countdown.inSeconds >= 0;
    final isOverdue = countdown != null && countdown.isNegative;

    return Column(children: [
      // ── Режим / подсказка (до старта) ──
      if (totalCount > 0 && !isRunning && !isFinished)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: AppInfoBanner.info(
            title: isMass ? 'Масс-старт' : isInterval ? 'Интервальный старт' : 'Ручной старт',
            subtitle: isMass
                ? 'Все стартуют одновременно. Нажмите кнопку СТАРТ.'
                : isInterval
                    ? 'Нажмите «Старт» — первый спортсмен уйдёт. Далее автоматически каждые ${session.intervalSeconds} сек.'
                    : 'Нажимайте на спортсмена, когда он готов к старту.',
          ),
        ),

      // ── Обратный отсчёт (интервальный) ──
      if (isInterval && isRunning && current != null && countdown != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            backgroundColor: isOverdue
                ? cs.error.withValues(alpha: 0.15)
                : isUrgent
                    ? cs.errorContainer.withValues(alpha: 0.15)
                    : cs.primaryContainer.withValues(alpha: 0.1),
            borderColor: isOverdue
                ? cs.error.withValues(alpha: 0.4)
                : isUrgent
                    ? cs.error.withValues(alpha: 0.3)
                    : cs.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    isOverdue ? 'ОПОЗДАНИЕ!' : isUrgent ? 'ВНИМАНИЕ' : 'ДО СТАРТА',
                    style: TextStyle(fontSize: 11, color: isOverdue || isUrgent ? cs.error : cs.primary, fontWeight: FontWeight.w800, letterSpacing: 1.0),
                  ),
                  Text(
                    _fmtCountdown(countdown),
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, fontFamily: 'monospace', color: isOverdue || isUrgent ? cs.error : cs.primary, height: 1.1),
                  ),
                ]),
                Icon(isOverdue ? Icons.error : isUrgent ? Icons.volume_up : Icons.schedule, size: 36,
                  color: (isOverdue || isUrgent ? cs.error : cs.primary).withValues(alpha: 0.8)),
              ]),
              const SizedBox(height: 8),
              AppQueueItem(
                leading: Icon(Icons.person, color: cs.primary, size: 22),
                title: Text('${current.bib} — ${current.name}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: cs.primary)),
                subtitle: const Text('Следующий'),
                dense: true,
                backgroundColor: cs.surface.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),

      // ── Все стартовали ──
      if (totalCount > 0 && current == null && startedCount == totalCount && isRunning)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: AppInfoBanner.success(title: 'Все стартовали!', subtitle: 'Переключитесь на «Финиш».'),
        ),

      // ── Заголовок ──
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('СТАРТ-ЛИСТ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cs.onSurfaceVariant, letterSpacing: 1.2)),
          if (totalCount > 0)
            Text('$startedCount/$totalCount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cs.primary)),
        ]),
      ),

      // ── Список участников + inline кнопка добавить ──
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          // +1 для info-баннера (если пусто) или кнопки добавить
          itemCount: sorted.length + (isFinished ? 0 : 1),
          itemBuilder: (context, i) {
            // Последний элемент — кнопка добавить
            if (i == sorted.length) {
              if (totalCount == 0) {
                // Пустой стейт как inline
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: AppInfoBanner.info(
                    title: 'Добавьте участников',
                    subtitle: 'Нажмите кнопку ниже или откройте ⚙️ → «Из книги».',
                  ),
                );
              }
              // После списка — кнопка добавить
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: AppQueueItem(
                  leading: Icon(Icons.person_add, color: cs.primary.withValues(alpha: 0.7), size: 22),
                  title: Text('Добавить участника', style: TextStyle(fontSize: 14, color: cs.primary, fontWeight: FontWeight.w600)),
                  backgroundColor: cs.primary.withValues(alpha: 0.04),
                  onTap: _showAddAthleteSheet,
                ),
              );
            }

            final a = sorted[i];
            final hasStarted = isMass ? (isRunning || isFinished) : a.startTime != null;
            final isCurrent = !isMass && current?.id == a.id;
            final finished = a.isFinished(session.totalLaps);

            final color = finished ? cs.primary : hasStarted ? cs.tertiary : isCurrent ? cs.tertiary : cs.onSurfaceVariant;
            final icon = finished ? Icons.flag : hasStarted ? Icons.check_circle : isCurrent ? Icons.play_circle : Icons.hourglass_empty;
            final statusText = finished ? 'Финиш' : hasStarted ? 'На трассе' : isCurrent ? 'Текущий' : 'Ожидает';

            return AppQueueItem(
              leading: Icon(icon, color: color, size: 24),
              title: Text('${a.bib} — ${a.name.isNotEmpty ? a.name : 'BIB ${a.bib}'}',
                style: TextStyle(fontSize: 14, fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600, color: cs.onSurface)),
              subtitle: Text('#${i + 1} · $statusText', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
              trailing: !isMass && !isInterval && !hasStarted && !isFinished
                  ? Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant.withValues(alpha: 0.4))
                  : null,
              backgroundColor: isCurrent
                  ? cs.tertiaryContainer.withValues(alpha: 0.1)
                  : finished
                      ? cs.primaryContainer.withValues(alpha: 0.05)
                      : hasStarted
                          ? cs.tertiaryContainer.withValues(alpha: 0.05)
                          : null,
              onTap: !isMass && !isInterval && !hasStarted && !finished && !isFinished
                  ? () => _startIndividual(a.id)
                  : null,
              // Long-press → удалить участника (до старта)
              onLongPress: !hasStarted && !finished && !isFinished
                  ? () => _removeAthleteWithConfirm(a.id)
                  : null,
            );
          },
        ),
      ),

      // ── Кнопка СТАРТ (внизу, sticky) ──
      if (totalCount > 0 && !isRunning && !isFinished) ...[
        if (isMass)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: AppButton.danger(text: 'СТАРТ', icon: Icons.play_arrow, onPressed: _startMass),
            ),
          ),
        if (isInterval && current != null)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: AppButton.danger(text: 'СТАРТ', icon: Icons.play_arrow, onPressed: () => _startIndividual(current.id)),
            ),
          ),
        if (!isMass && !isInterval)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: AppInfoBanner.info(title: 'Нажмите на спортсмена для старта'),
            ),
          ),
      ],

      // ── Добавить первого (когда пусто, sticky внизу) ──
      if (totalCount == 0 && !isFinished)
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: AppButton.primary(text: '+ Добавить участника', icon: Icons.person_add, onPressed: _showAddAthleteSheet),
          ),
        ),

      // ── Сессия завершена ──
      if (isFinished && totalCount > 0)
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: AppButton.primary(text: 'Новая сессия', icon: Icons.refresh, onPressed: _resetSession),
          ),
        ),
    ]);
  }

  // ═══════════════════════════════════════
  // Tab 2: ФИНИШ
  // ═══════════════════════════════════════
  Widget _buildFinishTab(QuickSession session, ColorScheme cs, bool isRunning) {
    final isMass = session.mode == QuickStartMode.mass;

    if (session.athletes.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.timer_off_outlined, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('Добавьте участников на вкладке «Старт»', style: TextStyle(color: cs.onSurfaceVariant)),
        ]),
      );
    }

    return Column(children: [
      if (isMass) _buildMassTimer(cs, isRunning),
      Expanded(
        child: GridView.extent(
          maxCrossAxisExtent: 140,
          childAspectRatio: 0.85,
          padding: const EdgeInsets.all(12),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: session.athletes.map((a) {
            final finished = a.isFinished(session.totalLaps);
            final laps = a.completedLaps;
            final hasStarted = isMass ? isRunning : a.startTime != null;

            String? timeStr;
            if (finished && a.finishTime != null) {
              final start = session.effectiveStart(a);
              timeStr = TimeFormatter.compact(a.finishTime!.difference(start));
            } else if (hasStarted && laps > 0 && a.splits.isNotEmpty) {
              final start = session.effectiveStart(a);
              timeStr = TimeFormatter.compact(a.splits.last.difference(start));
            }

            final String lapInfo;
            if (finished) {
              lapInfo = timeStr ?? 'Финиш';
            } else if (!hasStarted) {
              lapInfo = 'Ожидает';
            } else if (laps > 0) {
              lapInfo = 'Круг $laps/${session.totalLaps}${timeStr != null ? '\n⏱$timeStr' : ''}';
            } else {
              lapInfo = 'На трассе';
            }

            final BibState state;
            if (finished) {
              state = BibState.finished;
            } else if (!hasStarted) {
              state = BibState.disabled;
            } else if (laps > 0) {
              state = BibState.current;
            } else {
              state = BibState.available;
            }

            return AppBibTile(
              bib: a.bib,
              name: a.name.isNotEmpty ? a.name : null,
              lapInfo: lapInfo,
              state: state,
              onTap: () {
                if (finished || !hasStarted) return;
                _recordSplit(a.id);
              },
              // Long-press → отменить последнюю отсечку
              onLongPress: (finished || laps > 0)
                  ? () => _undoSplitWithConfirm(a.id)
                  : null,
            );
          }).toList(),
        ),
      ),
    ]);
  }

  // ═══════════════════════════════════════
  // Tab 3: ТАБЛИЦА
  // ═══════════════════════════════════════
  Widget _buildTableTab(QuickSession session, ColorScheme cs) {
    final table = _buildResultTable(session);

    if (table.rows.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.leaderboard_outlined, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('Результаты появятся после старта', style: TextStyle(color: cs.onSurfaceVariant)),
        ]),
      );
    }

    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.15),
          border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.1))),
        ),
        child: Row(children: [
          AppStatCard(value: '${session.finishedCount}', label: 'Финиш', color: cs.primary, expanded: false),
          const SizedBox(width: 6),
          AppStatCard(value: '${session.athletes.length - session.finishedCount}', label: 'На трассе', color: cs.tertiary, expanded: false),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _showCards = !_showCards),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _showCards ? cs.primary.withValues(alpha: 0.12) : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _showCards ? cs.primary.withValues(alpha: 0.3) : cs.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Icon(
                _showCards ? Icons.view_agenda_outlined : Icons.table_rows_outlined,
                size: 16,
                color: _showCards ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
          ),
        ]),
      ),
      Expanded(
        child: AppResultTable(
          table: table,
          showCards: _showCards,
          onRowTap: (row) => _showAthleteDetailFromRow(session, row, cs),
        ),
      ),
    ]);
  }

  /// Построить [ResultTable] из [QuickSession].
  ResultTable _buildResultTable(QuickSession session) {
    final athletes = [...session.athletes];
    athletes.sort((a, b) {
      final lapsCompare = b.completedLaps.compareTo(a.completedLaps);
      if (lapsCompare != 0) return lapsCompare;
      if (a.splits.isNotEmpty && b.splits.isNotEmpty) {
        final aTime = a.splits.last.difference(session.effectiveStart(a));
        final bTime = b.splits.last.difference(session.effectiveStart(b));
        return aTime.compareTo(bTime);
      }
      return 0;
    });

    final leaderLapDurations = athletes.isNotEmpty
        ? athletes.first.lapDurations(session.effectiveStart(athletes.first))
        : <Duration>[];
    Duration? leaderTotalTime;
    if (athletes.isNotEmpty && athletes.first.splits.isNotEmpty) {
      leaderTotalTime = athletes.first.splits.last.difference(session.effectiveStart(athletes.first));
    }

    final columns = <ColumnDef>[
      const ColumnDef(id: 'place', label: '#', type: ColumnType.number, align: ColumnAlign.center, flex: 0.4, minWidth: 36),
      const ColumnDef(id: 'bib', label: 'BIB', type: ColumnType.text, align: ColumnAlign.center, flex: 0.5, minWidth: 40),
      const ColumnDef(id: 'name', label: 'Имя', type: ColumnType.text, flex: 1.5, minWidth: 80),
      for (var lap = 1; lap <= session.totalLaps; lap++)
        ColumnDef(id: 'lap${lap}_time', label: 'L$lap', type: ColumnType.time, align: ColumnAlign.right, flex: 0.8, minWidth: 60),
      const ColumnDef(id: 'result_time', label: 'Время', type: ColumnType.time, align: ColumnAlign.right, flex: 1.0, minWidth: 70),
      const ColumnDef(id: 'gap_leader', label: 'Δ', type: ColumnType.gap, align: ColumnAlign.right, flex: 0.7, minWidth: 55),
    ];

    final rows = <ResultRow>[];
    for (var i = 0; i < athletes.length; i++) {
      final a = athletes[i];
      final finished = a.isFinished(session.totalLaps);
      final hasStarted = a.startTime != null || session.mode == QuickStartMode.mass;
      final laps = a.completedLaps;
      final place = i + 1;
      final lapDurations = a.lapDurations(session.effectiveStart(a));
      final displayName = a.name.isNotEmpty ? a.name : 'BIB ${a.bib}';

      Duration? athleteTime;
      if (a.splits.isNotEmpty) {
        athleteTime = a.splits.last.difference(session.effectiveStart(a));
      }

      final RowType rowType;
      if (finished) {
        rowType = RowType.finished;
      } else if (!hasStarted) {
        rowType = RowType.waiting;
      } else {
        rowType = RowType.onTrack;
      }

      final cells = <String, CellValue>{};

      if (finished) {
        cells['place'] = CellValue(raw: place, display: '$place', style: place <= 3 ? CellStyle.highlight : CellStyle.normal);
      } else if (hasStarted) {
        final statusLabel = laps > 0 ? 'К$laps' : 'LIVE';
        cells['place'] = CellValue(display: statusLabel, style: CellStyle.highlight);
      } else {
        cells['place'] = const CellValue(display: '—', style: CellStyle.muted);
      }

      cells['bib'] = CellValue(raw: a.bib, display: a.bib);
      cells['name'] = CellValue(raw: displayName, display: displayName,
        style: finished ? CellStyle.bold : hasStarted ? CellStyle.normal : CellStyle.muted);

      for (var lap = 1; lap <= session.totalLaps; lap++) {
        final lapIdx = lap - 1;
        if (lapIdx < lapDurations.length) {
          final lapTime = lapDurations[lapIdx];
          var lapStyle = CellStyle.normal;
          if (i == 0 && finished) lapStyle = CellStyle.highlight;
          String lapDisplay = TimeFormatter.compact(lapTime);
          if (i > 0 && lapIdx < leaderLapDurations.length) {
            final diff = lapTime - leaderLapDurations[lapIdx];
            if (diff.inMilliseconds > 0) {
              lapDisplay = TimeFormatter.compact(lapTime);
              lapStyle = CellStyle.normal;
            }
          }
          cells['lap${lap}_time'] = CellValue(raw: lapTime, display: lapDisplay, style: lapStyle);
        } else {
          cells['lap${lap}_time'] = CellValue.na;
        }
      }

      if (athleteTime != null) {
        cells['result_time'] = CellValue(raw: athleteTime, display: TimeFormatter.compact(athleteTime), style: finished ? CellStyle.bold : CellStyle.normal);
      } else {
        cells['result_time'] = CellValue.empty;
      }

      if (leaderTotalTime != null && athleteTime != null && i > 0) {
        final gap = athleteTime - leaderTotalTime;
        if (gap.inMilliseconds > 0) {
          cells['gap_leader'] = CellValue(raw: gap, display: '+${TimeFormatter.compact(gap)}', style: CellStyle.error);
        } else {
          cells['gap_leader'] = CellValue.na;
        }
      } else {
        cells['gap_leader'] = CellValue.na;
      }

      rows.add(ResultRow(entryId: a.id, cells: cells, type: rowType));
    }

    return ResultTable(columns: columns, rows: rows);
  }

  void _showAthleteDetailFromRow(QuickSession session, ResultRow row, ColorScheme cs) {
    final a = session.athletes.firstWhere((x) => x.id == row.entryId, orElse: () => session.athletes.first);
    final sorted = [...session.athletes]..sort((x, y) {
      final lc = y.completedLaps.compareTo(x.completedLaps);
      if (lc != 0) return lc;
      if (x.splits.isNotEmpty && y.splits.isNotEmpty) {
        return x.splits.last.difference(session.effectiveStart(x)).compareTo(y.splits.last.difference(session.effectiveStart(y)));
      }
      return 0;
    });
    final place = sorted.indexOf(a) + 1;
    _showAthleteDetail(session, a, place, cs);
  }

  void _showAthleteDetail(QuickSession session, QuickAthlete a, int place, ColorScheme cs) {
    final finished = a.isFinished(session.totalLaps);
    final hasStarted = a.startTime != null || session.mode == QuickStartMode.mass;
    final displayName = a.name.isNotEmpty ? a.name : 'BIB ${a.bib}';
    final lapDurations = a.lapDurations(session.effectiveStart(a));

    String totalTime = '—';
    if (a.splits.isNotEmpty) {
      totalTime = TimeFormatter.compact(a.splits.last.difference(session.effectiveStart(a)));
    }

    AppBottomSheet.show(
      context,
      title: '$displayName (BIB ${a.bib})',
      initialHeight: 0.55,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36, alignment: Alignment.center,
            decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.15), shape: BoxShape.circle, border: Border.all(color: cs.primary.withValues(alpha: 0.3))),
            child: Text('#$place', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: cs.primary)),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(finished ? 'Финишировал' : !hasStarted ? 'Ожидает старта' : 'На трассе',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: finished ? cs.primary : cs.tertiary)),
            Text('Круг ${a.completedLaps}/${session.totalLaps}', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ]),
          const Spacer(),
          Text(totalTime, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'monospace', color: finished ? cs.primary : cs.onSurface)),
        ]),
        const SizedBox(height: 16),
        if (lapDurations.isNotEmpty) ...[
          Text('КРУГИ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: cs.onSurfaceVariant, letterSpacing: 1)),
          const SizedBox(height: 8),
          ...lapDurations.asMap().entries.map((e) {
            final lapIdx = e.key;
            final lapTime = e.value;
            final isLast = lapIdx == lapDurations.length - 1 && finished;
            Duration cumulative = Duration.zero;
            for (var j = 0; j <= lapIdx; j++) {
              cumulative += lapDurations[j];
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: AppQueueItem(
                leading: Container(
                  width: 28, height: 28, alignment: Alignment.center,
                  decoration: BoxDecoration(color: isLast ? cs.primary.withValues(alpha: 0.1) : cs.surface.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8)),
                  child: Text('L${lapIdx + 1}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: isLast ? cs.primary : cs.onSurfaceVariant)),
                ),
                title: Text(TimeFormatter.compact(lapTime), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'monospace', color: cs.onSurface)),
                subtitle: Text('Общее: ${TimeFormatter.compact(cumulative)}', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                trailing: isLast ? Icon(Icons.flag, size: 18, color: cs.primary) : null,
              ),
            );
          }),
        ] else if (hasStarted)
          AppInfoBanner.info(title: 'На трассе', subtitle: 'Ожидаем первую отсечку')
        else
          AppInfoBanner.warning(title: 'Ожидает старта'),
      ]),
    );
  }

  Widget _buildMassTimer(ColorScheme cs, bool isRunning) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.1),
        border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.15))),
      ),
      child: Column(children: [
        if (isRunning) ...[
          Text(TimeFormatter.full(_elapsed),
            style: TextStyle(fontSize: 42, fontFamily: 'monospace', fontWeight: FontWeight.w900, color: cs.error, letterSpacing: 2)),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: cs.error, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text('LIVE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cs.error)),
          ]),
        ] else
          Text('00:00.0', style: TextStyle(fontSize: 42, fontFamily: 'monospace', fontWeight: FontWeight.w900, color: cs.onSurfaceVariant.withValues(alpha: 0.3), letterSpacing: 2)),
      ]),
    );
  }
}
