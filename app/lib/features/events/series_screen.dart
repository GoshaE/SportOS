import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: S1 — Управление серией/кубком
class SeriesScreen extends StatefulWidget {
  const SeriesScreen({super.key});

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  bool _isTableView = false;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = MediaQuery.of(context).size.width;

    if (!_initialized) {
      _isTableView = w > 600;
      _initialized = true;
    }

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
              backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
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
                            color: cs.primary.withValues(alpha: 0.3),
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
                  backgroundColor: cs.primaryContainer.withValues(alpha: 0.3),
                  side: BorderSide(color: cs.primaryContainer),
                  shape: const StadiumBorder(),
                  onPressed: () {},
                ),
                ActionChip(
                  avatar: Icon(Icons.article, size: 16, color: cs.onSurfaceVariant),
                  label: Text('Положение', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500, color: cs.onSurfaceVariant)),
                  backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                  onPressed: () {},
                ),
                ActionChip(
                  avatar: Icon(Icons.share, size: 16, color: cs.onSurfaceVariant),
                  label: Text('Поделиться', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500, color: cs.onSurfaceVariant)),
                  backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
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
                    leading: CircleAvatar(backgroundColor: cs.primary.withValues(alpha: 0.1), child: Text('1', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.primary))),
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
                    leading: CircleAvatar(backgroundColor: cs.primary.withValues(alpha: 0.1), child: Text('2', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.primary))),
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
                    leading: CircleAvatar(backgroundColor: cs.tertiary.withValues(alpha: 0.1), child: Text('3', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.tertiary))),
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
                    leading: CircleAvatar(backgroundColor: cs.onSurfaceVariant.withValues(alpha: 0.1), child: Text('4', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurfaceVariant))),
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
                  leading: CircleAvatar(backgroundColor: cs.onSurfaceVariant.withValues(alpha: 0.1), child: Text('5', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurfaceVariant))),
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
                  backgroundColor: cs.tertiaryContainer.withValues(alpha: 0.3),
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
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: cs.tertiary, foregroundColor: cs.onTertiary),
                          onPressed: () {},
                          child: const Text('Купить'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Пакет 2: Любые 3 этапа
                AppCard(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
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
                        FilledButton.tonal(
                          onPressed: () {},
                          child: const Text('Выбрать'),
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
                        OutlinedButton(
                          onPressed: () {},
                          child: const Text('Подробнее'),
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
                IconButton(icon: Icon(_isTableView ? Icons.grid_view : Icons.table_rows), tooltip: 'Вид таблицы', onPressed: () => setState(() => _isTableView = !_isTableView)),
              ]),
            ),
            AppProtocolTable(
              itemCount: 6,
              forceTableView: _isTableView,
              headerRow: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    SizedBox(width: 40, child: Text('#', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold))),
                    SizedBox(width: 180, child: Text('Спортсмен', maxLines: 1, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 44, child: Text('Эт.1')), const SizedBox(width: 44, child: Text('Эт.2')),
                    const SizedBox(width: 44, child: Text('Эт.3')), const SizedBox(width: 44, child: Text('Эт.4')),
                    const SizedBox(width: 44, child: Text('Эт.5')),
                    const SizedBox(width: 50, child: Text('Итого')),
                  ],
                ),
              ),
              itemBuilder: (context, index, isCard) {
                final data = [
                  ['🥇', 'Петров А.А.', '100', '80', '—', '—', '—', '180'],
                  ['🥈', 'Иванов В.В.', '80', '100', '—', '—', '—', '180'],
                  ['🥉', 'Волков Е.Е.', '60', '60', '—', '—', '—', '120'],
                  ['4', 'Козлов Г.Г.', '50', '50', '—', '—', '—', '100'],
                  ['5', 'Сидоров Б.Б.', '45', '45', '—', '—', '—', '90'],
                  ['6', 'Морозов Д.Д.', '40', 'DNF', '—', '—', '—', '40'],
                ][index];
                return _standRow(context, cs, isCard, data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7]);
              },
            ),
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
                const TextField(decoration: InputDecoration(labelText: 'Название серии', border: OutlineInputBorder(), isDense: true)),
                const SizedBox(height: 16),
                const TextField(decoration: InputDecoration(labelText: 'Описание', border: OutlineInputBorder(), isDense: true), maxLines: 3),
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
                DropdownButtonFormField<String>(
                  initialValue: 'standard', 
                  decoration: const InputDecoration(labelText: 'Система начисления', border: OutlineInputBorder(), isDense: true), 
                  items: const [
                    DropdownMenuItem(value: 'standard', child: Text('Стандартная (100/80/60/50...)')),
                    DropdownMenuItem(value: 'linear', child: Text('Линейная (N-место+1)')),
                    DropdownMenuItem(value: 'custom', child: Text('Пользовательская (Настроить)')),
                  ], 
                  onChanged: (_) {}
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: 'best4of5', 
                  decoration: const InputDecoration(labelText: 'Учёт результатов', border: OutlineInputBorder(), isDense: true), 
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Сумма всех этапов')),
                    DropdownMenuItem(value: 'best4of5', child: Text('Лучшие 4 из 5 (1 отбрасывается)')),
                    DropdownMenuItem(value: 'best3of5', child: Text('Лучшие 3 из 5 (2 отбрасываются)')),
                  ], 
                  onChanged: (_) {}
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
                Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('Новый этап'))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.link), label: const Text('Существующий'))),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, 
              child: FilledButton.icon(
                onPressed: () => AppSnackBar.success(context, 'Настройки серии сохранены'),
                icon: const Icon(Icons.save), 
                label: const Text('Сохранить изменения', style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ),
            const SizedBox(height: 32),
          ]),
        ]),
      ),
    );
  }


  static Widget _standRow(BuildContext context, ColorScheme cs, bool isCard, String pos, String name, String s1, String s2, String s3, String s4, String s5, String total) {
    if (isCard) {
      final isTop3 = pos == '🥇' || pos == '🥈' || pos == '🥉';
      final posWidget = isTop3 
        ? Text(pos, style: const TextStyle(fontSize: 24))
        : Container(
            width: 32, height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: cs.surfaceContainerHighest),
            child: Text(pos, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurfaceVariant)),
          );

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AppCard(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              SizedBox(width: 40, child: posWidget),
              Expanded(child: Text(name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(12)),
                child: Text(total, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: cs.primary)),
              ),
            ]),
            const SizedBox(height: 16),
            ...[
              {'label': 'Этап 1 (Екатеринбург)', 'val': s1, 'stl': Theme.of(context).textTheme.bodyMedium?.copyWith(color: s1 == '100' ? cs.primary : cs.onSurfaceVariant, fontWeight: s1 == '100' ? FontWeight.bold : null)},
              {'label': 'Этап 2 (Новосибирск)', 'val': s2, 'stl': Theme.of(context).textTheme.bodyMedium?.copyWith(color: s2 == 'DNF' ? cs.error : s2 == '100' ? cs.primary : cs.onSurfaceVariant)},
              {'label': 'Этап 3 (Красноярск)', 'val': s3, 'stl': Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.outline)},
              {'label': 'Этап 4 (Омск)', 'val': s4, 'stl': Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.outline)},
              {'label': 'Этап 5 (Тюмень)', 'val': s5, 'stl': Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.outline)},
            ].map((field) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(field['label'] as String, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                  Text(field['val'] as String, style: field['stl'] as TextStyle),
                ],
              ),
            )),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text(pos, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold))),
          SizedBox(width: 180, child: Text(name, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
          SizedBox(width: 44, child: Text(s1, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: s1 == '100' ? cs.primary : null, fontWeight: s1 == '100' ? FontWeight.bold : null))),
          SizedBox(width: 44, child: Text(s2, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: s2 == 'DNF' ? cs.error : s2 == '100' ? cs.primary : null))),
          SizedBox(width: 44, child: Text(s3, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant))),
          SizedBox(width: 44, child: Text(s4, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant))),
          SizedBox(width: 44, child: Text(s5, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant))),
          SizedBox(width: 50, child: Text(total, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
        ],
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
                          colors: [colors[i].withValues(alpha: 0.4), colors[i]],
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
                    getDrawingHorizontalLine: (_) => FlLine(color: cs.outlineVariant.withValues(alpha: 0.3), strokeWidth: 0.8, dashArray: [4, 4]),
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => cs.inverseSurface,
                      getTooltipItem: (group, _, rod, __) => BarTooltipItem(
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
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
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
              color: isFirst ? Colors.transparent : cs.outlineVariant.withValues(alpha: 0.5),
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
                color: isLast ? Colors.transparent : cs.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
