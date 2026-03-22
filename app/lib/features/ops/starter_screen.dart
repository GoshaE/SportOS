import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import 'package:sportos_app/domain/event/event_config.dart' hide TimeOfDay;
import 'package:sportos_app/domain/event/config_providers.dart';
import 'package:sportos_app/domain/timing/timing.dart';

/// Screen ID: R1 — Стартёр (раздельный + масс-старт)
class StarterScreen extends ConsumerStatefulWidget {
  const StarterScreen({super.key});

  @override
  ConsumerState<StarterScreen> createState() => _StarterScreenState();
}

class _StarterScreenState extends ConsumerState<StarterScreen> {
  bool _isMassStart = false;
  bool _isSynced = false;
  bool _preFlightPassed = false;

  // Собственный таймер для обновления UI (500ms — плавный обратный отсчёт)
  Timer? _uiTimer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    // UI-only timer: updates elapsed display (countdown, clock).
    // Auto-start logic is handled by RaceScheduler in domain layer.
    _uiTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final session = ref.read(raceSessionProvider);
      if (session == null || !mounted) return;
      setState(() => _elapsed = session.clock.elapsed);
    });
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    super.dispose();
  }

  // ═══════════════════════════════════════
  // Actions
  // ═══════════════════════════════════════

  void _tryStart(VoidCallback onStart) {
    if (_isSynced || _preFlightPassed) {
      onStart();
    } else {
      _showPreFlightCheck(onStart);
    }
  }

  void _showPreFlightCheck(VoidCallback onProceed) {
    final cs = Theme.of(context).colorScheme;
    AppBottomSheet.show(
      context,
      title: 'Pre-Flight Check',
      initialHeight: 0.5,
      actions: [
        AppButton.primary(
          text: 'Всё готово, продолжить',
          onPressed: () {
            setState(() => _preFlightPassed = true);
            Navigator.of(context, rootNavigator: true).pop();
            onProceed();
          },
        ),
      ],
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppInfoBanner.info(title: 'Время не синхронизировано с Финишем. Рекомендуется синхронизация.'),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.all(12),
          children: [
            _checkRow(cs, 'Mesh-сеть', _isSynced, true),
            _checkRow(cs, 'Стартовый лист загружен', true, false),
            _checkRow(cs, 'GPS-координаты', true, false),
            _checkRow(cs, 'Синхронизация часов', _isSynced, true),
          ],
        ),
      ]),
    );
  }

  Widget _checkRow(ColorScheme cs, String label, bool ok, bool critical) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(ok ? Icons.check_circle : (critical ? Icons.warning : Icons.info_outline), size: 16,
          color: ok ? cs.primary : (critical ? cs.tertiary : cs.onSurfaceVariant)),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 13, color: ok ? cs.onSurface : cs.onSurfaceVariant)),
      ]),
    );
  }

  void _markStarted() async {
    final session = ref.read(raceSessionProvider);
    if (session == null) return;
    final current = session.startList.currentAthlete;
    if (current == null) return;

    // First start → confirm transition to Live
    if (!await _confirmLiveTransition()) return;

    ref.read(raceSessionProvider.notifier).markStarted(current.bib);
    if (mounted) AppSnackBar.success(context, 'BIB ${current.bib} — УШЁЛ! ✅');
  }

  void _markDns(String bib) {
    ref.read(raceSessionProvider.notifier).markDns(bib);
    AppSnackBar.info(context, 'BIB $bib — DNS');
  }

  void _showAthleteMenu(StartEntry a) {
    AppBottomSheet.show(
      context,
      title: 'BIB ${a.bib} — ${a.name}',
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (a.status == AthleteStatus.waiting || a.status == AthleteStatus.current)
          ListTile(
            leading: const Icon(Icons.block, color: Colors.red),
            title: const Text('Отметить DNS'),
            onTap: () {
              Navigator.of(context, rootNavigator: true).pop();
              _markDns(a.bib);
            },
          ),
        if (a.status == AthleteStatus.dns)
          ListTile(
            leading: const Icon(Icons.undo),
            title: const Text('Отменить DNS'),
            onTap: () {
              Navigator.of(context, rootNavigator: true).pop();
              ref.read(raceSessionProvider.notifier).undoDns(a.bib);
              AppSnackBar.info(context, 'DNS отменён для BIB ${a.bib}');
            },
          ),
        if (a.status == AthleteStatus.waiting)
          ListTile(
            leading: const Icon(Icons.flash_on, color: Colors.orange),
            title: const Text('Принудительный старт'),
            onTap: () {
              Navigator.of(context, rootNavigator: true).pop();
              ref.read(raceSessionProvider.notifier).forceStart(a.bib);
              AppSnackBar.info(context, 'BIB ${a.bib} — принудительный старт');
            },
          ),
      ]),
    );
  }

  void _showGunStart() async {
    // First start → confirm transition to Live
    if (!await _confirmLiveTransition()) return;
    if (!mounted) return;

    final confirm = await AppDialog.confirm(
      context,
      title: 'GUN START',
      message: 'Все участники стартуют одновременно.\nЭто действие нельзя отменить.',
      confirmText: 'СТАРТ!',
      isDanger: true,
    );
    if (confirm == true && mounted) {
      ref.read(raceSessionProvider.notifier).markStartedAll();
      AppSnackBar.success(context, 'GUN START! Все стартовали.');
    }
  }

  /// Check if event needs Live transition; show confirmation if first start.
  /// Returns true if we can proceed, false if user cancelled.
  Future<bool> _confirmLiveTransition() async {
    final status = ref.read(eventConfigProvider).status;
    if (status == EventStatus.inProgress) return true; // already live

    final ok = await AppDialog.confirm(
      context,
      title: 'Переход в LIVE-режим',
      message: 'Первый старт переведёт мероприятие в режим гонки.\n'
          'Регистрация будет автоматически закрыта.',
      confirmText: 'Стартовать',
    );
    if (ok != true || !mounted) return false;

    // Transition to Live + auto-close registration
    ref.read(eventConfigProvider.notifier).update(
      (c) => c.copyWith(
        status: EventStatus.inProgress,
        registrationConfig: c.registrationConfig.copyWith(isOpen: false),
      ),
    );
    return true;
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
            setState(() { _isSynced = true; _preFlightPassed = true; });
            Navigator.of(context, rootNavigator: true).pop();
            AppSnackBar.success(context, 'Часы синхронизированы! (Δ = +0.012 с)');
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

  // ═══════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════

  String _fmtElapsed(Duration d) {
    final neg = d.isNegative;
    final abs = d.abs();
    final h = abs.inHours.toString().padLeft(2, '0');
    final m = abs.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = abs.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${neg ? '-' : ''}$h:$m:$s';
  }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final session = ref.watch(raceSessionProvider);
    if (session == null) {
      return Scaffold(
        appBar: AppAppBar(forceBackButton: true, title: const Text('Стартёр')),
        body: const Center(child: Text('Нет активной сессии.\nОткройте Посты Хронометража для начала.')),
      );
    }
    final current = session.startList.currentAthlete;
    final remaining = session.startList.remaining;
    final hasAthletes = session.hasAthletes;

    // Countdown to current athlete's planned start
    Duration? countdown;
    if (current != null) {
      countdown = current.plannedStartTime.difference(session.clock.now);
    }

    // Is countdown urgent (< 10 sec)?
    final isUrgent = countdown != null && countdown.inSeconds <= 10 && countdown.inSeconds >= 0;
    // Is overdue?
    final isOverdue = countdown != null && countdown.isNegative;

    return Scaffold(
      appBar: AppAppBar(
        forceBackButton: true,
        title: const Text('Стартёр'),
        actions: [
          // Race clock
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _fmtElapsed(_elapsed),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, fontFeatures: const [FontFeature.tabularFigures()], color: cs.onSurface),
            ),
          ),
          IconButton(icon: Icon(Icons.bluetooth_connected, color: _isSynced ? cs.primary : cs.onSurfaceVariant), onPressed: () {}),
          IconButton(icon: Icon(Icons.sync_alt, color: _isSynced ? cs.primary : cs.tertiary), onPressed: _showTimeSyncWizard),
        ],
      ),
      body: Column(children: [
        // ── Предупреждение ──
        if (!_isSynced) Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          color: cs.error.withOpacity(0.15),
          child: Row(children: [
            Icon(Icons.warning_amber, size: 16, color: cs.error),
            const SizedBox(width: 6),
            Expanded(child: Text('Время не синхронизировано с Финишем', style: TextStyle(color: cs.error, fontWeight: FontWeight.bold, fontSize: 12))),
          ]),
        ),

        // ── Пустое состояние ──
        if (!hasAthletes) Expanded(
          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.people_outline, size: 64, color: cs.onSurfaceVariant.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('Нет спортсменов', style: theme.textTheme.titleMedium?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text('Добавьте спортсменов через Посты Хронометража', style: TextStyle(fontSize: 12, color: cs.outline)),
          ])),
        ),

        if (hasAthletes) ...[
          // ── Инфо-панель (Bento) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(children: [
              Expanded(
                child: AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                  backgroundColor: cs.surfaceContainerHighest.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Дисциплина', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.bold)),
                      Text(session.config.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                backgroundColor: cs.primaryContainer.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                children: [
                  Row(children: [
                    Text('Осталось:', style: TextStyle(fontSize: 11, color: cs.primary, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    Text('$remaining', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: cs.primary)),
                  ]),
                ],
              ),
            ]),
          ),

          // ── Переключатель ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: AppCard(
              padding: const EdgeInsets.all(4),
              backgroundColor: cs.surfaceContainerHighest.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              children: [
                SizedBox(
                  height: 38,
                  child: Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isMassStart = false),
                        child: Container(
                          decoration: BoxDecoration(
                            color: !_isMassStart ? cs.surface : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: !_isMassStart ? Border.all(color: cs.outlineVariant.withOpacity(0.2)) : null,
                            boxShadow: !_isMassStart ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
                          ),
                          alignment: Alignment.center,
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.timer, size: 18, color: !_isMassStart ? cs.onSurface : cs.onSurfaceVariant),
                            const SizedBox(width: 8),
                            Text('Раздельный', style: TextStyle(fontSize: 14, fontWeight: !_isMassStart ? FontWeight.w700 : FontWeight.w500, color: !_isMassStart ? cs.onSurface : cs.onSurfaceVariant)),
                          ]),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isMassStart = true),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _isMassStart ? cs.surface : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: _isMassStart ? Border.all(color: cs.outlineVariant.withOpacity(0.2)) : null,
                            boxShadow: _isMassStart ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
                          ),
                          alignment: Alignment.center,
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.groups, size: 20, color: _isMassStart ? cs.onSurface : cs.onSurfaceVariant),
                            const SizedBox(width: 8),
                            Text('Масс-старт', style: TextStyle(fontSize: 14, fontWeight: _isMassStart ? FontWeight.w700 : FontWeight.w500, color: _isMassStart ? cs.onSurface : cs.onSurfaceVariant)),
                          ]),
                        ),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),

          // ── Живой обратный отсчёт (раздельный) ──
          if (!_isMassStart && current != null && countdown != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                backgroundColor: isOverdue
                    ? cs.error.withOpacity(0.15)
                    : isUrgent
                        ? cs.errorContainer.withOpacity(0.15)
                        : cs.primaryContainer.withOpacity(0.1),
                borderColor: isOverdue
                    ? cs.error.withOpacity(0.4)
                    : isUrgent
                        ? cs.error.withOpacity(0.3)
                        : cs.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isOverdue ? 'ОПОЗДАНИЕ!' : isUrgent ? 'ВНИМАНИЕ НА СТАРТ' : 'ДО СТАРТА',
                            style: TextStyle(
                              fontSize: 11,
                              color: isOverdue || isUrgent ? cs.error : cs.primary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            _fmtCountdown(countdown),
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                              fontFeatures: const [FontFeature.tabularFigures()],
                              color: isOverdue || isUrgent ? cs.error : cs.primary,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        isOverdue ? Icons.error : isUrgent ? Icons.volume_up : Icons.schedule,
                        size: 36,
                        color: (isOverdue || isUrgent ? cs.error : cs.primary).withOpacity(0.8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: cs.surface.withOpacity(0.6), borderRadius: BorderRadius.circular(12), border: Border.all(color: cs.primary.withOpacity(0.15))),
                    child: Row(
                      children: [
                        Text('СЛЕДУЮЩИЙ:', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        const Spacer(),
                        Text('${current.bib} — ${current.name}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cs.primary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Все стартовали
          if (!_isMassStart && current == null && remaining == 0 && hasAthletes)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: AppCard(
                padding: const EdgeInsets.all(16),
                backgroundColor: cs.primaryContainer.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.check_circle, color: cs.primary, size: 28),
                    const SizedBox(width: 8),
                    Text('Все спортсмены стартовали!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.primary)),
                  ]),
                ],
              ),
            ),

          // ── Масс-старт — кнопка GUN ──
          if (_isMassStart)
            Padding(
              padding: const EdgeInsets.all(12),
              child: AppCard(
                padding: EdgeInsets.zero,
                backgroundColor: (!_isSynced && !_preFlightPassed) ? cs.tertiaryContainer.withOpacity(0.2) : cs.errorContainer.withOpacity(0.15),
                borderColor: (!_isSynced && !_preFlightPassed) ? cs.tertiary.withOpacity(0.3) : cs.error.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                children: [
                  InkWell(
                    onTap: () => _tryStart(_showGunStart),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.campaign, size: 36, color: (!_isSynced && !_preFlightPassed) ? cs.tertiary : cs.error),
                          const SizedBox(width: 12),
                          Text('GUN START', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: (!_isSynced && !_preFlightPassed) ? cs.tertiary : cs.error, letterSpacing: 1.5)),
                        ]),
                        const SizedBox(height: 8),
                        if (!_isSynced && !_preFlightPassed) Text('Требуется Pre-Flight Check', style: TextStyle(fontSize: 12, color: cs.tertiary, fontWeight: FontWeight.bold)),
                        if (_isSynced || _preFlightPassed) Text('Всем запущен таймер', style: TextStyle(fontSize: 12, color: cs.error, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),

          // ── Очередь ──
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Text('СТАРТ-ЛИСТ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cs.onSurfaceVariant, letterSpacing: 1.2)),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 8),
                  itemCount: session.startList.all.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    final a = session.startList.all[i];
                    final isCurrent = a.status == AthleteStatus.current;
                    final isStarted = a.status == AthleteStatus.started;
                    final isDns = a.status == AthleteStatus.dns;

                    String fmtTime(DateTime dt) {
                      final h = dt.hour.toString().padLeft(2, '0');
                      final m = dt.minute.toString().padLeft(2, '0');
                      final s = dt.second.toString().padLeft(2, '0');
                      return '$h:$m:$s';
                    }

                    final color = isStarted ? cs.primary : isDns ? cs.error : isCurrent ? cs.tertiary : cs.onSurfaceVariant;
                    final icon = isStarted ? Icons.check_circle : isDns ? Icons.block : isCurrent ? Icons.play_circle : Icons.hourglass_empty;
                    final statusText = isStarted ? 'Ушёл' : isDns ? 'DNS' : isCurrent ? 'Текущий' : fmtTime(a.plannedStartTime);

                    return AppCard(
                      padding: EdgeInsets.zero,
                      backgroundColor: isCurrent ? cs.tertiaryContainer.withOpacity(0.1) : isStarted ? cs.primaryContainer.withOpacity(0.05) : cs.surfaceContainerHighest.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      borderColor: isCurrent ? cs.tertiary.withOpacity(0.3) : cs.outlineVariant.withOpacity(0.1),
                      children: [
                        InkWell(
                          onTap: () => _showAthleteMenu(a),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(children: [
                              Icon(icon, color: color, size: 24),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: cs.surface.withOpacity(0.5), borderRadius: BorderRadius.circular(6)),
                                child: Text(a.bib, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: cs.onSurfaceVariant)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(a.name, style: TextStyle(fontSize: 14, fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600, color: isDns ? cs.outline : cs.onSurface, decoration: isDns ? TextDecoration.lineThrough : null)),
                                  const SizedBox(height: 2),
                                  Text(statusText, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                                ]),
                              ),
                              Icon(Icons.more_vert, size: 18, color: cs.onSurfaceVariant.withOpacity(0.5)),
                            ]),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ]),
          ),

          // ── DNS / Ушёл / Авто ──
          if (!_isMassStart)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(children: [
                  Expanded(child: SizedBox(height: 52, child: AppButton.secondary(
                    text: 'DNS',
                    onPressed: current != null ? () => _markDns(current.bib) : null,
                  ))),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: session.config.manualStart
                    ? SizedBox(height: 52, child: AppButton.primary(
                        text: !_isSynced && !_preFlightPassed ? 'ПРОВЕРКА' : 'УШЁЛ ✅',
                        onPressed: current != null ? () => _tryStart(_markStarted) : null,
                      ))
                    : Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cs.primary.withOpacity(0.2)),
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.auto_mode, size: 20, color: cs.primary),
                          const SizedBox(width: 8),
                          Text('АВТО-СТАРТ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.primary, letterSpacing: 0.5)),
                        ]),
                      ),
                  ),
                ]),
              ),
            ),
        ],
      ]),
    );
  }
}
