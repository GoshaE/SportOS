import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../domain/timing/result_table.dart';

/// Screen ID: S1 — Управление серией/кубком
class SeriesScreen extends StatefulWidget {
  const SeriesScreen({super.key});

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  bool _showCards = false;


  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;


    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppAppBar(
          title: const Text('Кубок Сибири 2026'),
          actions: [IconButton(icon: const Icon(Icons.settings), onPressed: () {})],
          bottom: const AppPillTabBar(
            tabs: ['Этапы', 'Зачёт', 'Настройки'],
            icons: [Icons.calendar_month, Icons.leaderboard, Icons.settings],
          ),
        ),
        body: TabBarView(children: [
          // TAB 1: Этапы
          ListView(padding: const EdgeInsets.all(12), children: [
            // 1️⃣ Top Banner
            AppCard(
              padding: const EdgeInsets.all(16),
              backgroundColor: cs.surfaceContainerHighest.withOpacity(0.3),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [cs.primary, cs.tertiary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Icon(Icons.emoji_events, color: cs.onPrimary, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Кубок Сибири 2026',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, height: 1.2),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Скиджоринг и Каникросс',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _Badge(icon: Icons.map, label: '5 этапов', cs: cs),
                    const SizedBox(width: 8),
                    _Badge(icon: Icons.directions_run, label: '3 дисциплины', cs: cs),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 2️⃣ Action Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: Icon(Icons.settings, size: 16, color: cs.primary),
                  label: Text('Управлять', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: cs.primary)),
                  backgroundColor: cs.primaryContainer.withOpacity(0.3),
                  side: BorderSide(color: cs.primaryContainer),
                  shape: const StadiumBorder(),
                  onPressed: () {},
                ),
                ActionChip(
                  avatar: Icon(Icons.article, size: 16, color: cs.onSurfaceVariant),
                  label: Text('Положение', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500, color: cs.onSurfaceVariant)),
                  backgroundColor: cs.surfaceContainerHighest.withOpacity(0.5),
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                  onPressed: () {},
                ),
                ActionChip(
                  avatar: Icon(Icons.share, size: 16, color: cs.onSurfaceVariant),
                  label: Text('Поделиться', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500, color: cs.onSurfaceVariant)),
                  backgroundColor: cs.surfaceContainerHighest.withOpacity(0.5),
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3️⃣ Timeline Этапов
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _TimelineNode(isFirst: true, isLast: false, isActive: false, cs: cs),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppEventCard(
                    title: 'Этап 1 — Екатеринбург',
                    subtitle: '15 января',
                    badge: 'Завершён',
                    status: EventCardStatus.completed,
                    accentColor: cs.primary,
                    leading: CircleAvatar(backgroundColor: cs.primary.withOpacity(0.1), child: Text('1', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.primary))),
                    onTap: () => context.push('/hub/event/evt-6'),
                    mode: EventCardMode.bento,
                  ),
                ),
              ),
            ]),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _TimelineNode(isFirst: false, isLast: false, isActive: false, cs: cs),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppEventCard(
                    title: 'Этап 2 — Новосибирск',
                    subtitle: '12 февраля',
                    badge: 'Завершён',
                    status: EventCardStatus.completed,
                    accentColor: cs.primary,
                    leading: CircleAvatar(backgroundColor: cs.primary.withOpacity(0.1), child: Text('2', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.primary))),
                    onTap: () => context.push('/hub/event/evt-7'),
                    mode: EventCardMode.bento,
                  ),
                ),
              ),
            ]),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _TimelineNode(isFirst: false, isLast: false, isActive: true, cs: cs),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppEventCard(
                    title: 'Этап 3 — Красноярск',
                    subtitle: '15 марта',
                    badge: 'Предстоит',
                    status: EventCardStatus.upcoming,
                    accentColor: cs.tertiary,
                    leading: CircleAvatar(backgroundColor: cs.tertiary.withOpacity(0.1), child: Text('3', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.tertiary))),
                    onTap: () => context.push('/hub/event/evt-1'),
                    mode: EventCardMode.bento,
                  ),
                ),
              ),
            ]),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _TimelineNode(isFirst: false, isLast: false, isActive: false, cs: cs),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppEventCard(
                    title: 'Этап 4 — Омск',
                    subtitle: '19 апреля',
                    badge: 'Будущий',
                    status: EventCardStatus.draft,
                    accentColor: cs.onSurfaceVariant,
                    leading: CircleAvatar(backgroundColor: cs.onSurfaceVariant.withOpacity(0.1), child: Text('4', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurfaceVariant))),
                    mode: EventCardMode.bento,
                  ),
                ),
              ),
            ]),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _TimelineNode(isFirst: false, isLast: true, isActive: false, cs: cs),
              Expanded(
                child: AppEventCard(
                  title: 'Этап 5 — Тюмень',
                  subtitle: '3 мая',
                  badge: 'Будущий',
                  status: EventCardStatus.draft,
                  accentColor: cs.onSurfaceVariant,
                  leading: CircleAvatar(backgroundColor: cs.onSurfaceVariant.withOpacity(0.1), child: Text('5', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurfaceVariant))),
                  mode: EventCardMode.bento,
                ),
              ),
            ]),
            const SizedBox(height: 24),
            const SizedBox(height: 8),
            Column(
              children: [
                // Пакет 1: Все 5 этапов (Акцентный)
                AppCard(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: cs.tertiaryContainer.withOpacity(0.3),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: cs.tertiary, borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.star, color: cs.onTertiary, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Все 5 этапов', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              Text('Полный доступ ко всей серии', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: cs.tertiary, borderRadius: BorderRadius.circular(6)),
                          child: Text('Выгода 33%', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onTertiary, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Абонемент', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('10 000 ₽', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: cs.tertiary)),
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text('15 000 ₽', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.outline, decoration: TextDecoration.lineThrough)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        AppButton.primary(
                          text: 'Купить',
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Пакет 2: Любые 3 этапа
                AppCard(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: cs.surfaceContainerHighest.withOpacity(0.3),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.inventory_2, color: cs.primary, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Любые 3 этапа', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              Text('Гибкий выбор для профи', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)),
                          child: Text('Выгода 11%', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Стоимость', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('8 000 ₽', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text('9 000 ₽', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.outline, decoration: TextDecoration.lineThrough)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        AppButton.secondary(
                          text: 'Выбрать',
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Пакет 3: Разовый
                AppCard(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.looks_one, color: cs.onSurfaceVariant, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Разовый', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              Text('Оплата отдельного этапа', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('За этап', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                            Text('3 000 ₽', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: cs.onSurfaceVariant)),
                          ],
                        ),
                        AppButton.text(
                          text: 'Подробнее',
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ]),

          // TAB 2: Общий зачёт
          ListView(padding: const EdgeInsets.all(12), children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  ChoiceChip(label: const Text('Скиджоринг 5км'), selected: true, onSelected: (_) {}),
                  const SizedBox(width: 8),
                  ChoiceChip(label: const Text('Скиджоринг 10км'), selected: false, onSelected: (_) {}),
                  const SizedBox(width: 8),
                  ChoiceChip(label: const Text('Каникросс'), selected: false, onSelected: (_) {}),
                ],
              ),
            ),
            const Divider(height: 16),
            Container(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                Expanded(child: AppInfoBanner.info(title: 'Зачёт: лучшие 4 из 5 этапов · Очки: 1 место = 100, 2 = 80, 3 = 60, 4 = 50, 5 = 45...')),
                const SizedBox(width: 8),
                IconButton(icon: Icon(_showCards ? Icons.table_rows : Icons.view_agenda_outlined), tooltip: 'Вид таблицы', onPressed: () => setState(() => _showCards = !_showCards)),
              ]),
            ),
            Builder(builder: (context) {
              final demoData = [
                ['🥇', 'Петров А.А.', '100', '80', '—', '—', '—', '180'],
                ['🥈', 'Иванов В.В.', '80', '100', '—', '—', '—', '180'],
                ['🥉', 'Волков Е.Е.', '60', '60', '—', '—', '—', '120'],
                ['4', 'Козлов Г.Г.', '50', '50', '—', '—', '—', '100'],
                ['5', 'Сидоров Б.Б.', '45', '45', '—', '—', '—', '90'],
                ['6', 'Морозов Д.Д.', '40', 'DNF', '—', '—', '—', '40'],
              ];

              final columns = <ColumnDef>[
                const ColumnDef(id: 'place', label: '#', type: ColumnType.number, align: ColumnAlign.center, flex: 0.5, minWidth: 40),
                const ColumnDef(id: 'name', label: 'Спортсмен', type: ColumnType.text, align: ColumnAlign.left, flex: 2.0, minWidth: 140),
                const ColumnDef(id: 's1', label: 'Эт.1', type: ColumnType.number, align: ColumnAlign.center, flex: 0.6, minWidth: 44),
                const ColumnDef(id: 's2', label: 'Эт.2', type: ColumnType.number, align: ColumnAlign.center, flex: 0.6, minWidth: 44),
                const ColumnDef(id: 's3', label: 'Эт.3', type: ColumnType.number, align: ColumnAlign.center, flex: 0.6, minWidth: 44),
                const ColumnDef(id: 's4', label: 'Эт.4', type: ColumnType.number, align: ColumnAlign.center, flex: 0.6, minWidth: 44),
                const ColumnDef(id: 's5', label: 'Эт.5', type: ColumnType.number, align: ColumnAlign.center, flex: 0.6, minWidth: 44),
                const ColumnDef(id: 'total', label: 'Итого', type: ColumnType.number, align: ColumnAlign.right, flex: 0.7, minWidth: 50),
              ];

              final rows = demoData.asMap().entries.map((e) {
                final d = e.value;
                return ResultRow(
                  entryId: 'series-${e.key}',
                  cells: {
                    'place': CellValue(raw: d[0], display: d[0], style: e.key < 3 ? CellStyle.bold : CellStyle.normal),
                    'name': CellValue(raw: d[1], display: d[1], style: CellStyle.bold),
                    's1': CellValue(raw: d[2], display: d[2], style: d[2] == '100' ? CellStyle.highlight : CellStyle.normal),
                    's2': CellValue(raw: d[3], display: d[3], style: d[3] == 'DNF' ? CellStyle.error : d[3] == '100' ? CellStyle.highlight : CellStyle.normal),
                    's3': CellValue(raw: d[4], display: d[4], style: CellStyle.muted),
                    's4': CellValue(raw: d[5], display: d[5], style: CellStyle.muted),
                    's5': CellValue(raw: d[6], display: d[6], style: CellStyle.muted),
                    'total': CellValue(raw: d[7], display: d[7], style: CellStyle.bold),
                  },
                );
              }).toList();

              return AppResultTable(
                table: ResultTable(columns: columns, rows: rows),
                showCards: _showCards,
              );
            }),
            const SizedBox(height: 12),
            _buildStandingsChart(context, cs),
          ]),

          // TAB 3: Настройки серии
          ListView(padding: const EdgeInsets.all(12), children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: Text('Основная информация', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: cs.primary)),
            ),
            AppCard(
              padding: const EdgeInsets.all(16),
              children: [
                AppTextField(label: 'Название серии', hintText: 'Кубок Сибири 2026'),
                const SizedBox(height: 16),
                AppTextField(label: 'Описание', hintText: 'Описание серии...', maxLines: 3),
              ],
            ),
            const SizedBox(height: 20),
            
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: Text('Подсчёт очков и рейтинг', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: cs.primary)),
            ),
            AppCard(
              padding: const EdgeInsets.all(16),
              children: [
                AppSelect<String>(
                  label: 'Система начисления',
                  value: 'standard',
                  items: const [
                    SelectItem(value: 'standard', label: 'Стандартная (100/80/60/50...)'),
                    SelectItem(value: 'linear', label: 'Линейная (N-место+1)'),
                    SelectItem(value: 'custom', label: 'Пользовательская (Настроить)'),
                  ],
                  onChanged: (_) {},
                ),
                const SizedBox(height: 16),
                AppSelect<String>(
                  label: 'Учёт результатов',
                  value: 'best4of5',
                  items: const [
                    SelectItem(value: 'all', label: 'Сумма всех этапов'),
                    SelectItem(value: 'best4of5', label: 'Лучшие 4 из 5 (1 отбрасывается)'),
                    SelectItem(value: 'best3of5', label: 'Лучшие 3 из 5 (2 отбрасываются)'),
                  ],
                  onChanged: (_) {},
                ),
              ],
            ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: Text('Этапы (Редактирование)', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: cs.primary)),
            ),
            AppCard(
              padding: EdgeInsets.zero,
              children: [
                ReorderableListView(
                  shrinkWrap: true, 
                  physics: const NeverScrollableScrollPhysics(), 
                  onReorder: (oldIndex, newIndex) {}, 
                  children: [
                    ListTile(key: const ValueKey(1), leading: CircleAvatar(backgroundColor: cs.surfaceContainerHighest, child: const Text('1')), title: const Text('Екатеринбург', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text('15 января'), trailing: const Icon(Icons.drag_indicator, color: Colors.grey)),
                    ListTile(key: const ValueKey(2), leading: CircleAvatar(backgroundColor: cs.surfaceContainerHighest, child: const Text('2')), title: const Text('Новосибирск', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text('12 февраля'), trailing: const Icon(Icons.drag_indicator, color: Colors.grey)),
                    ListTile(key: const ValueKey(3), leading: CircleAvatar(backgroundColor: cs.surfaceContainerHighest, child: const Text('3')), title: const Text('Красноярск', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text('15 марта'), trailing: const Icon(Icons.drag_indicator, color: Colors.grey)),
                    ListTile(key: const ValueKey(4), leading: CircleAvatar(backgroundColor: cs.surfaceContainerHighest, child: const Text('4')), title: const Text('Омск', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text('19 апреля'), trailing: const Icon(Icons.drag_indicator, color: Colors.grey)),
                    ListTile(key: const ValueKey(5), leading: CircleAvatar(backgroundColor: cs.surfaceContainerHighest, child: const Text('5')), title: const Text('Тюмень', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text('3 мая'), trailing: const Icon(Icons.drag_indicator, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: AppButton.secondary(text: 'Новый этап', icon: Icons.add, onPressed: () {})),
                const SizedBox(width: 8),
                Expanded(child: AppButton.secondary(text: 'Существующий', icon: Icons.link, onPressed: () {})),
              ],
            ),
            const SizedBox(height: 24),
            AppButton.primary(
              text: 'Сохранить изменения',
              icon: Icons.save,
              onPressed: () => AppSnackBar.success(context, 'Настройки серии сохранены'),
            ),
            const SizedBox(height: 32),
          ]),
        ]),
      ),
    );
  }



  static Widget _buildStandingsChart(BuildContext context, ColorScheme cs) {
    final names = ['Петров', 'Иванов', 'Волков', 'Козлов', 'Сидоров', 'Морозов'];
    final points = [180.0, 180.0, 120.0, 100.0, 90.0, 40.0];
    final colors = [cs.primary, cs.primary, cs.tertiary, cs.secondary, cs.secondary, cs.error];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Очки по спортсменам', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface)),
              const SizedBox(height: 4),
              Text('Скиджоринг 5км · после 2 этапов', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: BarChart(BarChartData(
                  maxY: 200,
                  barGroups: List.generate(points.length, (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: points[i],
                        width: 18,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [colors[i].withOpacity(0.4), colors[i]],
                        ),
                      ),
                    ],
                  )),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true, reservedSize: 28, interval: 50,
                      getTitlesWidget: (v, meta) => SideTitleWidget(
                        meta: meta,
                        child: Text('${v.toInt()}', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10, color: cs.onSurfaceVariant)),
                      ),
                    )),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true, reservedSize: 28,
                      getTitlesWidget: (v, meta) {
                        final idx = v.toInt();
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(idx >= 0 && idx < names.length ? names[idx] : '', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9, color: cs.onSurfaceVariant)),
                        );
                      },
                    )),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true, drawVerticalLine: false, horizontalInterval: 50,
                    getDrawingHorizontalLine: (_) => FlLine(color: cs.outlineVariant.withOpacity(0.3), strokeWidth: 0.8, dashArray: [4, 4]),
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => cs.inverseSurface,
                      getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                        '${names[group.x]}: ${rod.toY.toInt()} очков',
                        Theme.of(context).textTheme.labelMedium!.copyWith(color: cs.onInverseSurface, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                )),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════
// UI Helpers
// ═══════════════════════════════════════

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme cs;

  const _Badge({required this.icon, required this.label, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _TimelineNode extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final bool isActive;
  final ColorScheme cs;

  const _TimelineNode({
    required this.isFirst,
    required this.isLast,
    required this.isActive,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 2,
              height: 24,
              color: isFirst ? Colors.transparent : cs.outlineVariant.withOpacity(0.5),
            ),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: isActive ? cs.tertiary : cs.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? cs.tertiary : cs.outlineVariant,
                  width: isActive ? 4 : 2,
                ),
              ),
            ),
            Expanded(
              child: Container(
                width: 2,
                color: isLast ? Colors.transparent : cs.outlineVariant.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
