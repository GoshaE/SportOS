import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: R3 — Маршал (с модалками R3.1–R3.3)
class MarshalScreen extends StatefulWidget {
  const MarshalScreen({super.key});

  @override
  State<MarshalScreen> createState() => _MarshalScreenState();
}

class _MarshalScreenState extends State<MarshalScreen> {
  final Set<String> _passed = {};
  final Map<String, String> _splitTimes = {};
  int _passedCount = 0;
  bool _isSynced = false;

  final List<Map<String, String>> _athletes = [
    {'bib': '07', 'name': 'Петров', 'disc': 'Скидж.'},
    {'bib': '12', 'name': 'Сидоров', 'disc': 'Скидж.'},
    {'bib': '24', 'name': 'Иванов', 'disc': 'Нарты'},
    {'bib': '31', 'name': 'Козлов', 'disc': 'Нарты'},
    {'bib': '42', 'name': 'Морозов', 'disc': 'Скидж.'},
    {'bib': '55', 'name': 'Волков', 'disc': 'Пулка'},
    {'bib': '63', 'name': 'Лебедев', 'disc': 'Скидж.'},
    {'bib': '77', 'name': 'Новиков', 'disc': 'Нарты'},
    {'bib': '88', 'name': 'Кузнецов', 'disc': 'Скидж.'},
  ];

  void _tryTogglePassed(String bib) {
    if (!mounted) return;
    if (_passed.contains(bib)) {
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
    if (_passed.contains(bib)) {
      AppDialog.confirm(context, title: 'Отменить отметку BIB $bib?', message: 'Атлет будет снова показан как "не прошёл", а время отсечки будет удалено.').then((ok) {
        if (ok == true) {
          setState(() {
            _passed.remove(bib);
            _splitTimes.remove(bib);
            _passedCount--;
          });
        }
      });
    } else {
      setState(() {
        _passed.add(bib);
        final m = (DateTime.now().minute % 60).toString().padLeft(2, '0');
        final s = (DateTime.now().second % 60).toString().padLeft(2, '0');
        _splitTimes[bib] = '00:1$m:$s';
        _passedCount++;
      });
      AppSnackBar.success(context, 'BIB $bib — отсечка: ${_splitTimes[bib]}');
    }
  }

  // R3.1 — Нарушение
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

    final sorted = List<Map<String, String>>.from(_athletes)
      ..sort((a, b) {
        final ap = _passed.contains(a['bib']);
        final bp = _passed.contains(b['bib']);
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
                  Text('$_passedCount/${_athletes.length}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: cs.primary)),
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
              final passed = _passed.contains(a['bib']);
              final time = passed && _splitTimes.containsKey(a['bib']) ? _splitTimes[a['bib']] : null;
              
              return GestureDetector(
                onLongPress: () => AppBottomSheet.show(context,
                  title: 'BIB ${a['bib']} — ${a['name']}',
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    ListTile(leading: Icon(Icons.gavel, color: cs.tertiary), title: const Text('Зафиксировать нарушение'), onTap: () { Navigator.of(context, rootNavigator: true).pop(); _showViolation(a['bib']!, a['name']!); }),
                    ListTile(leading: Icon(Icons.block, color: cs.error), title: const Text('Запрос DNF'), onTap: () { Navigator.of(context, rootNavigator: true).pop(); _showDnfRequest(a['bib']!, a['name']!); }),
                  ]),
                ),
                child: AppBibTile(
                  bib: a['bib']!,
                  name: a['name']!,
                  lapInfo: passed ? time : a['disc'],
                  state: passed ? BibState.finished : BibState.available,
                  onTap: () => _tryTogglePassed(a['bib']!),
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
