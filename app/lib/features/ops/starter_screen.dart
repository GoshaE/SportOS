import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: R1 — Стартёр (раздельный + масс-старт)
class StarterScreen extends StatefulWidget {
  const StarterScreen({super.key});

  @override
  State<StarterScreen> createState() => _StarterScreenState();
}

class _StarterScreenState extends State<StarterScreen> {
  bool _isMassStart = false;
  int _currentIndex = 1;
  bool _isSynced = false;
  bool _preFlightPassed = false;

  final List<Map<String, dynamic>> _queue = [
    {'bib': '07', 'name': 'Петров А.А.', 'time': '10:00:00', 'status': 'started'},
    {'bib': '24', 'name': 'Иванов В.В.', 'time': '10:00:30', 'status': 'current'},
    {'bib': '31', 'name': 'Козлов Г.Г.', 'time': '10:01:00', 'status': 'waiting'},
    {'bib': '42', 'name': 'Морозов Д.Д.', 'time': '10:01:30', 'status': 'waiting'},
    {'bib': '55', 'name': 'Волков Е.Е.', 'time': '10:02:00', 'status': 'waiting'},
    {'bib': '12', 'name': 'Сидоров Б.Б.', 'time': '10:02:30', 'status': 'waiting'},
    {'bib': '63', 'name': 'Лебедев Ж.Ж.', 'time': '10:03:00', 'status': 'waiting'},
    {'bib': '77', 'name': 'Новиков З.З.', 'time': '10:03:30', 'status': 'waiting'},
  ];

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
          text: 'Стартовать всё равно',
          backgroundColor: cs.tertiary,
          onPressed: () {
            setState(() => _preFlightPassed = true);
            Navigator.of(context, rootNavigator: true).pop();
            onProceed();
          },
        ),
      ],
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Проверка готовности постов перед стартом:'),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(12),
          children: [
            AppStatusRow(icon: Icons.check_circle, title: 'Финиш: Готов (Синхронизировано)', contentPadding: EdgeInsets.zero),
            const Divider(),
            AppStatusRow(icon: Icons.error, iconColor: cs.error, title: 'КП1 (Маршал): Нет связи', contentPadding: EdgeInsets.zero),
          ]
        ),
        const SizedBox(height: 12),
        AppInfoBanner.error(title: 'Время на несинхронизированных постах будет неточным.'),
      ]),
    );
  }

  void _markStarted() {
    setState(() {
      _queue[_currentIndex]['status'] = 'started';
      if (_currentIndex < _queue.length - 1) {
        _currentIndex++;
        _queue[_currentIndex]['status'] = 'current';
      }
    });
    AppSnackBar.success(context, 'Ушёл!');
  }

  void _markDns(int index) {
    setState(() => _queue[index]['status'] = 'dns');
    AppSnackBar.info(context, 'DNS — BIB ${_queue[index]['bib']}');
  }

  void _showAthleteMenu(int index) {
    final cs = Theme.of(context).colorScheme;
    final athlete = _queue[index];
    AppBottomSheet.show(context,
      title: 'BIB ${athlete['bib']} — ${athlete['name']}',
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (athlete['status'] == 'dns')
          ListTile(leading: Icon(Icons.undo, color: cs.tertiary), title: const Text('Отменить DNS'), onTap: () {
            setState(() => athlete['status'] = 'waiting');
            Navigator.of(context, rootNavigator: true).pop();
            AppSnackBar.info(context, 'DNS отменён — BIB ${athlete['bib']}');
          }),
        if (athlete['status'] == 'waiting')
          ListTile(leading: Icon(Icons.play_arrow, color: cs.primary), title: const Text('Стартовать принудительно'), onTap: () {
            setState(() => athlete['status'] = 'started');
            Navigator.of(context, rootNavigator: true).pop();
            AppSnackBar.info(context, 'Принудительный старт — BIB ${athlete['bib']} → Audit Log');
          }),
        ListTile(leading: Icon(Icons.block, color: cs.error), title: const Text('DNS'), onTap: () {
          _markDns(index);
          Navigator.of(context, rootNavigator: true).pop();
        }),
      ]),
    );
  }

  void _showGunStart() async {
    final confirm = await AppDialog.confirm(
      context,
      title: 'GUN START',
      message: 'Все участники стартуют одновременно.\nЭто действие нельзя отменить.',
      confirmText: 'СТАРТ!',
      isDanger: true,
    );
    if (confirm == true && mounted) {
      setState(() { for (var a in _queue) { a['status'] = 'started'; } });
      AppSnackBar.success(context, 'GUN START! Все стартовали.');
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final current = _currentIndex < _queue.length ? _queue[_currentIndex] : null;
    final remaining = _queue.where((a) => a['status'] == 'waiting' || a['status'] == 'current').length;

    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Стартёр'),
        actions: [
          IconButton(icon: Icon(Icons.bluetooth_connected, color: _isSynced ? cs.primary : cs.onSurfaceVariant), onPressed: () {}),
          IconButton(icon: Icon(Icons.sync_alt, color: _isSynced ? cs.primary : cs.tertiary), onPressed: _showTimeSyncWizard),
        ],
      ),
      body: Column(children: [
        // ── Предупреждение ──
        if (!_isSynced) Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          color: cs.error.withValues(alpha: 0.15),
          child: Row(children: [
            Icon(Icons.warning_amber, size: 16, color: cs.error),
            const SizedBox(width: 6),
            Expanded(child: Text('Время не синхронизировано с Финишем', style: TextStyle(color: cs.error, fontWeight: FontWeight.bold, fontSize: 12))),
          ]),
        ),

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
                    Text('Дисциплина', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.bold)),
                    const Text('Sprint 5km', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
            backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.15),
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
                          border: !_isMassStart ? Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)) : null,
                          boxShadow: !_isMassStart ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
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
                          border: _isMassStart ? Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)) : null,
                          boxShadow: _isMassStart ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
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

        // ── Обратный отсчёт (раздельный) ──
        if (!_isMassStart && current != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              backgroundColor: cs.errorContainer.withValues(alpha: 0.1),
              borderColor: cs.error.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ВНИМАНИЕ НА СТАРТ', style: TextStyle(fontSize: 11, color: cs.error, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                        Text('00:03', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, fontFamily: 'monospace', color: cs.error, height: 1.1)),
                      ],
                    ),
                    Icon(Icons.volume_up, size: 36, color: cs.error.withValues(alpha: 0.8)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: cs.surface.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12), border: Border.all(color: cs.primary.withValues(alpha: 0.15))),
                  child: Row(
                    children: [
                      Text('СЛЕДУЮЩИЙ:', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      const Spacer(),
                      Text('${current['bib']} — ${current['name']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cs.primary)),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // ── Масс-старт — кнопка GUN ──
        if (_isMassStart)
          Padding(
            padding: const EdgeInsets.all(12),
            child: AppCard(
              padding: EdgeInsets.zero,
              backgroundColor: (!_isSynced && !_preFlightPassed) ? cs.tertiaryContainer.withValues(alpha: 0.2) : cs.errorContainer.withValues(alpha: 0.15),
              borderColor: (!_isSynced && !_preFlightPassed) ? cs.tertiary.withValues(alpha: 0.3) : cs.error.withValues(alpha: 0.3),
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
                itemCount: _queue.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 6),
                itemBuilder: (context, i) {
                  final a = _queue[i];
                  final status = a['status'] as String;
                  final isCurrent = status == 'current';
                  final isStarted = status == 'started';
                  final isDns = status == 'dns';

                  final color = isStarted ? cs.primary : isDns ? cs.error : isCurrent ? cs.tertiary : cs.onSurfaceVariant;
                  final icon = isStarted ? Icons.check_circle : isDns ? Icons.block : isCurrent ? Icons.play_circle : Icons.hourglass_empty;
                  final statusText = isStarted ? 'Ушёл' : isDns ? 'DNS' : isCurrent ? 'Текущий' : a['time'];

                  return AppCard(
                    padding: EdgeInsets.zero,
                    backgroundColor: isCurrent ? cs.tertiaryContainer.withValues(alpha: 0.1) : isStarted ? cs.primaryContainer.withValues(alpha: 0.05) : cs.surfaceContainerHighest.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    borderColor: isCurrent ? cs.tertiary.withValues(alpha: 0.3) : cs.outlineVariant.withValues(alpha: 0.1),
                    children: [
                      InkWell(
                        onTap: () => _showAthleteMenu(i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(children: [
                            Icon(icon, color: color, size: 24),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: cs.surface.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(6)),
                              child: Text('${a['bib']}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: cs.onSurfaceVariant)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('${a['name']}', style: TextStyle(fontSize: 14, fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600, color: isDns ? cs.outline : cs.onSurface, decoration: isDns ? TextDecoration.lineThrough : null)),
                                const SizedBox(height: 2),
                                Text(statusText, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                              ]),
                            ),
                            Icon(Icons.more_vert, size: 18, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
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

        // ── DNS / Ушёл ──
        if (!_isMassStart)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(children: [
                Expanded(child: SizedBox(height: 52, child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.error,
                    side: BorderSide(color: cs.error.withValues(alpha: 0.3), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: current != null ? () => _markDns(_currentIndex) : null,
                  child: const Text('DNS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ))),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: SizedBox(height: 52, child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: !_isSynced && !_preFlightPassed ? cs.tertiary : cs.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: current != null ? () => _tryStart(_markStarted) : null,
                  child: Text(!_isSynced && !_preFlightPassed ? 'ПРОВЕРКА' : 'УШЁЛ ✅', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ))),
              ]),
            ),
          ),
      ]),
    );
  }
}
