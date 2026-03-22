import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: RS3 — Протесты и штрафы
class ProtestsScreen extends StatefulWidget {
  const ProtestsScreen({super.key});

  @override
  State<ProtestsScreen> createState() => _ProtestsScreenState();
}

class _ProtestsScreenState extends State<ProtestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

  final _penaltyRegistry = [
    {'code': 'V01', 'name': 'Помеха обгоняющему', 'penalty': '+15 сек'},
    {'code': 'V02', 'name': 'Фальстарт', 'penalty': '+10 сек'},
    {'code': 'V03', 'name': 'Срезка трассы', 'penalty': 'DSQ'},
    {'code': 'V04', 'name': 'Грубость с собакой', 'penalty': 'DSQ'},
    {'code': 'V05', 'name': 'Посторонняя помощь', 'penalty': '+30 сек'},
    {'code': 'V06', 'name': 'Потеря собаки', 'penalty': '+60 сек'},
    {'code': 'V07', 'name': 'Неспортивное поведение', 'penalty': 'DSQ'},
    {'code': 'V08', 'name': 'Другое (вручную)', 'penalty': 'См. правила'},
  ];

  final _athletes = [
    {'bib': '07', 'name': 'Петров А.А.', 'disc': 'Скидж. 5км'},
    {'bib': '12', 'name': 'Сидоров Б.Б.', 'disc': 'Скидж. 5км'},
    {'bib': '24', 'name': 'Иванов В.В.', 'disc': 'Скидж. 10км'},
    {'bib': '31', 'name': 'Козлов Г.Г.', 'disc': 'Нарты 15км'},
    {'bib': '42', 'name': 'Морозов Д.Д.', 'disc': 'Каникросс'},
    {'bib': '55', 'name': 'Волков Е.Е.', 'disc': 'Скидж. 5км'},
    {'bib': '63', 'name': 'Лебедев Ж.Ж.', 'disc': 'Нарты 15км'},
    {'bib': '77', 'name': 'Новиков З.З.', 'disc': 'Каникросс'},
    {'bib': '88', 'name': 'Кузнецов И.И.', 'disc': 'Скидж. 5км'},
  ];

  final _penalties = [
    {'bib': '31', 'name': 'Козлов', 'code': 'V01', 'violation': 'Помеха обгон.', 'penalty': '+15 сек', 'judge': 'Сидоров', 'time': '10:52:30'},
    {'bib': '42', 'name': 'Морозов', 'code': 'V03', 'violation': 'Срезка трассы', 'penalty': 'DSQ', 'judge': 'Петров', 'time': '10:55:12'},
  ];

  @override
  void initState() { super.initState(); _tab = TabController(length: 3, vsync: this); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final eventId = GoRouterState.of(context).pathParameters['eventId'] ?? 'evt-1';

    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Протесты и штрафы'),
        bottom: AppPillTabBar(
          controller: _tab,
          tabs: const ['Протесты', 'Штрафы', 'Реестр'],
        ),
      ),
      body: TabBarView(controller: _tab, children: [
        // ── TAB 1: Протесты ──
        ListView(padding: const EdgeInsets.all(12), children: [
          AppInfoBanner.warning(title: 'Время на подачу протестов: 18 мин'),
          const SizedBox(height: 12),
          AppCard(padding: EdgeInsets.zero, children: [
            AppCard.item(icon: Icons.add, label: 'Подать протест', onTap: () => _showSubmitProtest(context), iconColor: cs.primary),
          ]),
          const SizedBox(height: 16),
          AppSectionHeader(title: 'Активные и закрытые протесты', icon: Icons.gavel),
          const SizedBox(height: 8),
          _protestCard(context, cs, theme, 'Протест №1', 'Козлов Г.Г. (BIB 31)', 'Через: представитель Сидоров И.', 'На штраф +15с за помеху', 'На рассмотрении', BadgeType.warning, Icons.hourglass_top),
          const SizedBox(height: 8),
          _protestCard(context, cs, theme, 'Протест №2', 'Морозов Д.Д. (BIB 42)', '', 'Оспаривание DNF', 'Отклонён', BadgeType.error, Icons.cancel),
          const SizedBox(height: 8),
          _protestCard(context, cs, theme, 'Протест №3', 'Волков Е.Е. (BIB 55)', '', 'Неверная отсечка (+2с)', 'Удовлетворён', BadgeType.success, Icons.check_circle),
        ]),

        // ── TAB 2: Назначенные штрафы ──
        ListView(padding: const EdgeInsets.all(12), children: [
          AppCard(padding: EdgeInsets.zero, children: [
            AppCard.item(icon: Icons.gavel, label: 'Назначить штраф', subtitle: 'Только для главного судьи', onTap: () => _showAssignPenalty(context)),
          ]),
          const SizedBox(height: 16),

          AppSectionHeader(title: 'Заявки от маршалов', icon: Icons.inbox),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            children: [
              _marshalRequest(cs, theme, 'BIB 31 Козлов — Срезка трассы', 'Маршал CP 3км · 10:48:30\nФото приложено', '31', 'Козлов'),
              _marshalRequest(cs, theme, 'BIB 55 Волков — Помеха обгоняющему', 'Маршал CP 6км · 10:51:15', '55', 'Волков'),
            ],
          ),
          const SizedBox(height: 16),

          AppSectionHeader(title: 'Назначенные штрафы', icon: Icons.check_circle),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            children: _penalties.map((p) => ListTile(
              dense: true,
              title: Text('BIB ${p['bib']} ${p['name']} — ${p['code']} ${p['violation']}', style: theme.textTheme.titleSmall),
              subtitle: Text('${p['penalty']} · Судья: ${p['judge']} · ${p['time']}', style: theme.textTheme.bodySmall),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(icon: const Icon(Icons.edit, size: 18), tooltip: 'Изменить', onPressed: () => _showChangePenalty(context, p)),
                IconButton(icon: Icon(Icons.delete, size: 18, color: cs.error), tooltip: 'Отменить', onPressed: () => _showCancelPenalty(context, p)),
              ]),
            )).toList(),
          ),
          const SizedBox(height: 16),
          AppButton.secondary(text: 'К протоколу', icon: Icons.description, onPressed: () => context.push('/results/$eventId/protocol')),
        ]),

        // ── TAB 3: Реестр нарушений ──
        ListView(padding: const EdgeInsets.all(12), children: [
          AppInfoBanner.info(title: 'Реестр наследуется: Вид спорта → Мероприятие → Дисциплина'),
          const SizedBox(height: 12),
          AppCard(
            padding: EdgeInsets.zero,
            children: _penaltyRegistry.map((r) => ListTile(
              leading: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(6)),
                child: Text(r['code']!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFeatures: const [FontFeature.tabularFigures()], color: cs.primary)),
              ),
              title: Text(r['name']!, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
              trailing: StatusBadge(
                text: r['penalty']!,
                type: r['penalty']!.contains('DSQ') ? BadgeType.error : BadgeType.warning,
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),
          AppButton.secondary(text: 'Добавить нарушение', icon: Icons.add, onPressed: () {}),
          const SizedBox(height: 4),
          AppButton.secondary(text: 'Настроить для дисциплины', icon: Icons.settings, onPressed: () {}),
        ]),
      ]),
    );
  }

  // ─────────────────────────────────────
  // ВИДЖЕТЫ
  // ─────────────────────────────────────

  Widget _marshalRequest(ColorScheme cs, ThemeData theme, String title, String subtitle, String bib, String name) {
    return Container(
      color: cs.tertiaryContainer.withValues(alpha: 0.1),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: cs.tertiary.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(Icons.warning, color: cs.tertiary, size: 20)
        ),
        title: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
        isThreeLine: true,
        trailing: AppButton.primary(
          text: 'Штраф',
          onPressed: () => _showAssignPenaltyForBib(context, bib, name),
        ),
      ),
    );
  }

  Widget _protestCard(BuildContext ctx, ColorScheme cs, ThemeData theme, String title, String from, String via, String reason, String status, BadgeType type, IconData icon) {
    return AppCard(
      padding: EdgeInsets.zero,
      children: [
        Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: Icon(icon, color: _badgeColor(cs, type)),
            title: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            subtitle: Container(
              margin: const EdgeInsets.only(top: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: StatusBadge(text: status, type: type),
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.2)),
                    const SizedBox(height: 12),
                    Text('Подал: $from', style: theme.textTheme.bodyMedium),
                    if (via.isNotEmpty) Text(via, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8)),
                      child: Text('Причина: $reason', style: theme.textTheme.bodyMedium),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Icon(Icons.attach_file, size: 14, color: cs.primary),
                      const SizedBox(width: 4),
                      Text('1 видео приложено', style: theme.textTheme.bodySmall?.copyWith(color: cs.primary)),
                    ]),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: AppButton.primary(
                        text: 'Рассмотреть',
                        icon: Icons.gavel,
                        onPressed: () => _showVerdict(ctx, title, from),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ]
    );
  }

  Color _badgeColor(ColorScheme cs, BadgeType type) => switch (type) {
    BadgeType.success => cs.primary,
    BadgeType.error => cs.error,
    BadgeType.warning => cs.tertiary,
    _ => cs.onSurfaceVariant,
  };

  // ─────────────────────────────────────
  // МОДАЛКИ
  // ─────────────────────────────────────

  void _showSubmitProtest(BuildContext context) {
    String? selectedBib;
    String search = '';

    AppBottomSheet.show(
      context,
      title: 'Подача протеста',
      initialHeight: 0.85,
      actions: [
        AppButton.primary(text: 'Подать протест', onPressed: () {
          Navigator.of(context, rootNavigator: true).pop();
          AppSnackBar.success(context, 'Протест подан → На рассмотрении');
        }),
      ],
      child: StatefulBuilder(builder: (ctx, setS) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Заявитель *', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.all(12),
          children: [
            AppTextField(
              label: 'Поиск по BIB или фамилии',
              prefixIcon: Icons.search,
              onChanged: (v) => setS(() => search = v),
            ),
            if (search.isNotEmpty && selectedBib == null) ..._athletes
              .where((a) => a['bib']!.contains(search) || a['name']!.toLowerCase().contains(search.toLowerCase()))
              .map((a) => ListTile(
                dense: true,
                leading: CircleAvatar(radius: 14, child: Text(a['bib']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                title: Text('BIB ${a['bib']} — ${a['name']}'),
                subtitle: Text(a['disc']!),
                onTap: () => setS(() { selectedBib = a['bib']; search = ''; }),
              )),
            if (selectedBib != null) _selectedBibChip(context, selectedBib!, () => setS(() => selectedBib = null)),
          ],
        ),
        const SizedBox(height: 16),

        Text('Участники происшествия', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.all(12),
          children: [
            AppSelect<String>(
              label: 'Выберите BIB',
              value: null,
              items: _athletes.map((a) => SelectItem(value: a['bib']!, label: 'BIB ${a['bib']} — ${a['name']}')).toList(),
              onChanged: (_) {},
            ),
          ],
        ),
        const SizedBox(height: 16),

        Text('Тип протеста', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.all(12),
          children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              ChoiceChip(label: const Text('Нарушение на трассе'), selected: true, onSelected: (_) {}),
              ChoiceChip(label: const Text('Оспаривание DNF'), selected: false, onSelected: (_) {}),
              ChoiceChip(label: const Text('Оспаривание штрафа'), selected: false, onSelected: (_) {}),
              ChoiceChip(label: const Text('Неверная отсечка'), selected: false, onSelected: (_) {}),
              ChoiceChip(label: const Text('Другое'), selected: false, onSelected: (_) {}),
            ]),
          ],
        ),
        const SizedBox(height: 16),

        AppCard(
          padding: const EdgeInsets.all(12),
          children: [
            const AppTextField(label: 'Описание *', hintText: 'Подробное описание ситуации...', maxLines: 3),
            const SizedBox(height: 12),
            AppButton.secondary(text: 'Прикрепить фото / видео', icon: Icons.camera_alt, onPressed: () {}),
          ]
        ),
      ])),
    );
  }

  void _showAssignPenalty(BuildContext context) {
    String? selectedBib;
    int? selectedViolation;
    String search = '';
    final cs = Theme.of(context).colorScheme;

    AppBottomSheet.show(
      context,
      title: 'Назначить штраф',
      initialHeight: 0.85,
      actions: [
        AppButton.primary(
          text: 'Назначить штраф',
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            AppSnackBar.success(context, 'Штраф назначен → протокол пересчитан');
          },
        ),
      ],
      child: StatefulBuilder(builder: (ctx, setS) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppInfoBanner.warning(title: 'Только для роли «Судья» / «Главный судья»'),
        const SizedBox(height: 12),

        Text('Участник *', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.all(12),
          children: [
            AppTextField(
              label: 'BIB или фамилия',
              prefixIcon: Icons.search,
              onChanged: (v) => setS(() => search = v),
            ),
            if (search.isNotEmpty && selectedBib == null) ..._athletes
              .where((a) => a['bib']!.contains(search) || a['name']!.toLowerCase().contains(search.toLowerCase()))
              .map((a) => ListTile(dense: true,
                leading: CircleAvatar(radius: 14, child: Text(a['bib']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                title: Text('BIB ${a['bib']} — ${a['name']}'), subtitle: Text(a['disc']!),
                onTap: () => setS(() { selectedBib = a['bib']; search = ''; }),
              )),
            if (selectedBib != null) _selectedBibChip(context, selectedBib!, () => setS(() => selectedBib = null)),
          ]
        ),
        const SizedBox(height: 16),

        Text('Нарушение (из реестра) *', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...List.generate(_penaltyRegistry.length, (i) {
          final r = _penaltyRegistry[i];
          final sel = selectedViolation == i;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: AppCard(
              padding: EdgeInsets.zero,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: sel ? cs.tertiaryContainer.withValues(alpha: 0.3) : Colors.transparent,
                    border: Border.all(color: sel ? cs.tertiary : Colors.transparent, width: sel ? 2 : 0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Text(r['code']!, style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()], fontWeight: FontWeight.bold)),
                    title: Text(r['name']!),
                    trailing: StatusBadge(text: r['penalty']!, type: r['penalty']!.contains('DSQ') ? BadgeType.error : BadgeType.warning),
                    onTap: () => setS(() => selectedViolation = i),
                  ),
                ),
              ]
            ),
          );
        }),
        if (selectedViolation != null) ...[
          const SizedBox(height: 8),
          AppCard(padding: const EdgeInsets.all(10), children: [
            Text('Наказание: ${_penaltyRegistry[selectedViolation!]['penalty']}', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ChoiceChip(label: Text('${_penaltyRegistry[selectedViolation!]['penalty']} (реестр)'), selected: true, onSelected: (_) {}),
              ChoiceChip(label: const Text('Вручную'), selected: false, onSelected: (_) {}),
              ChoiceChip(label: const Text('Предупреждение'), selected: false, onSelected: (_) {}),
              ChoiceChip(label: const Text('DSQ'), selected: false, onSelected: (_) {}),
            ]),
          ]),
          const SizedBox(height: 8),
          const AppTextField(label: 'Комментарий', maxLines: 2),
        ],
        const SizedBox(height: 4),
        Center(child: Text('Будет записано в audit log', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant))),
      ])),
    );
  }

  void _showAssignPenaltyForBib(BuildContext context, String bib, String name) {
    AppBottomSheet.show(
      context,
      title: 'Штраф — BIB $bib $name',
      initialHeight: 0.6,
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Выберите нарушение:', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        AppCard(
          padding: EdgeInsets.zero,
          children: [
            Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _penaltyRegistry.take(5).map((r) => ListTile(
                  dense: true,
                  leading: Text(r['code']!, style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()], fontSize: 12)),
                  title: Text(r['name']!, style: const TextStyle(fontSize: 13)),
                  trailing: StatusBadge(text: r['penalty']!, type: r['penalty']!.contains('DSQ') ? BadgeType.error : BadgeType.warning),
                  onTap: () { Navigator.of(context, rootNavigator: true).pop(); AppSnackBar.success(context, '${r['code']} ${r['penalty']} → BIB $bib'); },
                )).toList(),
              ),
            ),
          ]
        ),
      ]),
    );
  }

  void _showChangePenalty(BuildContext context, Map<String, String> p) {
    AppBottomSheet.show(
      context,
      title: 'Изменить штраф — BIB ${p['bib']}',
      initialHeight: 0.7,
      actions: [
        AppButton.primary(
          text: 'Сохранить',
          onPressed: () { Navigator.of(context, rootNavigator: true).pop(); AppSnackBar.success(context, 'Штраф изменён → позиции пересчитаны'); },
        ),
      ],
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppCard(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Нарушение: ${p['code']} ${p['violation']}'),
                  const SizedBox(height: 4),
                  Text('Было: ${p['penalty']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ]
        ),
        const SizedBox(height: 16),
        const Text('Новое наказание:'),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ChoiceChip(label: const Text('+15 сек'), selected: true, onSelected: (_) {}),
          ChoiceChip(label: const Text('+10 сек'), selected: false, onSelected: (_) {}),
          ChoiceChip(label: const Text('DSQ'), selected: false, onSelected: (_) {}),
          ChoiceChip(label: const Text('Предупреждение'), selected: false, onSelected: (_) {}),
        ]),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.all(12),
          children: const [
             AppTextField(label: 'Причина изменения *', maxLines: 2),
          ]
        ),
        const SizedBox(height: 8),
        Text('Запись в audit log', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ]),
    );
  }

  void _showCancelPenalty(BuildContext context, Map<String, String> p) {
    AppDialog.confirm(
      context,
      title: 'Отменить штраф? — BIB ${p['bib']}',
      message: '${p['code']} ${p['violation']} → ${p['penalty']}\n\nПозиции будут пересчитаны. Запись в audit log.',
      confirmText: 'Да, отменить',
      isDanger: true,
      onConfirm: () => AppSnackBar.success(context, 'Штраф отменён BIB ${p['bib']} → пересчёт'),
    );
  }

  void _showVerdict(BuildContext context, String title, String from) {
    AppBottomSheet.show(
      context,
      title: 'Вердикт — $title',
      initialHeight: 0.7,
      actions: [
        AppButton.primary(
          text: 'Применить вердикт',
          onPressed: () { Navigator.of(context, rootNavigator: true).pop(); AppSnackBar.success(context, 'Вердикт применён → протокол пересчитан'); },
        ),
      ],
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppCard(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              child: Text('От: $from'),
            )
          ]
        ),
        const SizedBox(height: 16),
        Text('Решение:', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ChoiceChip(label: const Text('Отклонить'), selected: false, onSelected: (_) {}),
          ChoiceChip(label: const Text('Удовлетворить'), selected: true, onSelected: (_) {}),
          ChoiceChip(label: const Text('Изменить наказание'), selected: false, onSelected: (_) {}),
        ]),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.all(12),
          children: const [
            AppTextField(label: 'Комментарий вердикта *', maxLines: 2),
          ]
        ),
        const SizedBox(height: 8),
        AppInfoBanner.warning(title: 'Пересчёт протокола (ScoringEngine)'),
      ]),
    );
  }

  // ─────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────

  Widget _selectedBibChip(BuildContext context, String bib, VoidCallback onClear) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(6),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(6)),
      child: Row(children: [
        Icon(Icons.check_circle, color: cs.primary, size: 16),
        const SizedBox(width: 6),
        Text('BIB $bib — ${_athletes.firstWhere((a) => a['bib'] == bib)['name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const Spacer(),
        AppButton.text(text: 'Изменить', onPressed: onClear),
      ]),
    );
  }
}
