import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

import '../../core/widgets/widgets.dart';
import '../../domain/quick_timer/quick_timer_models.dart';
import '../../domain/quick_timer/quick_timer_providers.dart';
import '../../domain/timing/time_formatter.dart';

// ── Динамически загружаемые виджеты ──
import 'widgets/qt_start_tab.dart';
import 'widgets/qt_finish_tab.dart';
import 'widgets/qt_table_tab.dart';
import 'widgets/qt_settings_sheet.dart';
import 'widgets/qt_add_athlete_sheet.dart';

/// QT — Единый экран быстрого секундомера.
/// Точка входа: `/quick-timer`.
/// 
/// Переписан с разделением логики:
/// - Расчеты (gaps, positions) делегированы домену: `QuickResultCalculator`
/// - Интерфейс вкладок разделен: `QtStartTab`, `QtFinishTab`, `QtTableTab`
/// - Шторки (Settings, Add Athlete, Groups) вынесены в `widgets/`
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

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);

    // Авто-создание пустой сессии
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

    // Таймер для обновления шапки каждые 100 мс
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
          // Привязка нового участника "на лету" (Кнопка теперь в доступе всегда)
          if (!isFinished)
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: 'Добавить участника',
              color: cs.primary,
              onPressed: () => showQtAddAthleteSheet(context, ref),
            ),
          
          // Настройки сессии
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Настройки',
            onPressed: () => showQtSettingsSheet(context, ref, _resetSession),
          ),
          
          // Общий таймер сессии
          if (isRunning) Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cs.errorContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              TimeFormatter.full(_elapsed),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, fontFeatures: const [FontFeature.tabularFigures()], color: cs.error),
            ),
          ),
          
          // Счётчик (Финишировали/Всего)
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
          
          // Кнопка принудительного завершения
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
            
          // Архив истории
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
          QtStartTab(session: session, isRunning: isRunning, isFinished: isFinished),
          QtFinishTab(session: session, isRunning: isRunning, elapsed: _elapsed),
          QtTableTab(session: session),
        ],
      ),
    );
  }
}
