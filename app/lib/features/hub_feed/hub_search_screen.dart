import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: H1.1 — Поиск (с расширенными фильтрами)
class HubSearchScreen extends StatefulWidget {
  const HubSearchScreen({super.key});

  @override
  State<HubSearchScreen> createState() => _HubSearchScreenState();
}

class _HubSearchScreenState extends State<HubSearchScreen> {
  bool _filtersVisible = false;
  String? _sport;
  String? _region;
  RangeValues _dateRange = const RangeValues(1, 12);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppAppBar(
        title: AppSearchBar(
          hint: 'Мероприятия, клубы, спортсмены…',
          autofocus: true,
          padding: EdgeInsets.zero,
        ),
        actions: [
          IconButton(
            icon: Icon(_filtersVisible ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () => setState(() => _filtersVisible = !_filtersVisible),
          ),
        ],
      ),
      body: Column(children: [
        // ── Расширенные фильтры ──
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: _filtersVisible
              ? Container(
                  padding: const EdgeInsets.all(16),
                  color: cs.surfaceContainerLow,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Фильтры', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 12),
                    AppSelect<String>(
                      label: 'Вид спорта',
                      value: _sport,
                      items: ['Ездовой спорт', 'Каникросс', 'Лыжные гонки', 'Биатлон']
                          .map((e) => SelectItem(value: e, label: e))
                          .toList(),
                      onChanged: (v) => setState(() => _sport = v),
                    ),
                    const SizedBox(height: 10),
                    AppSelect<String>(
                      label: 'Регион',
                      value: _region,
                      items: ['Свердловская обл.', 'Москва', 'Санкт-Петербург', 'Новосибирская обл.', 'Татарстан']
                          .map((e) => SelectItem(value: e, label: e))
                          .toList(),
                      onChanged: (v) => setState(() => _region = v),
                    ),
                    const SizedBox(height: 10),
                    Text('Период (месяцы 2026):', style: theme.textTheme.bodySmall),
                    RangeSlider(
                      values: _dateRange,
                      min: 1, max: 12, divisions: 11,
                      labels: RangeLabels('${_dateRange.start.round()} мес', '${_dateRange.end.round()} мес'),
                      onChanged: (v) => setState(() => _dateRange = v),
                    ),
                    const SizedBox(height: 4),
                    Row(children: [
                      Expanded(child: AppButton.secondary(
                        text: 'Сбросить',
                        onPressed: () => setState(() { _sport = null; _region = null; _dateRange = const RangeValues(1, 12); }),
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: AppButton.primary(
                        text: 'Применить',
                        onPressed: () => setState(() => _filtersVisible = false),
                      )),
                    ]),
                  ]),
                )
              : const SizedBox.shrink(),
        ),

        // ── Быстрые теги ──
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            itemCount: _quickTags.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (_, i) => ActionChip(
              label: Text(_quickTags[i], style: theme.textTheme.bodySmall),
              onPressed: () {},
            ),
          ),
        ),
        Divider(height: 1, color: cs.outlineVariant.withOpacity(0.3)),

        // ── Результаты поиска ──
        Expanded(child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            _SearchResultItem(
              title: 'Чемпионат Урала 2026',
              subtitle: 'Мероприятие · 15 марта · Екатеринбург',
              icon: Icons.emoji_events,
              onTap: () => context.push('/hub/event/evt-1'),
            ),
            _SearchResultItem(
              title: 'Лесная гонка 2026',
              subtitle: 'Мероприятие · 22 апреля · Казань',
              icon: Icons.emoji_events,
              onTap: () => context.push('/hub/event/evt-2'),
            ),
            _SearchResultItem(
              title: 'Быстрые лапы',
              subtitle: 'Клуб · 25 участников · Екатеринбург',
              icon: Icons.groups,
              onTap: () => context.push('/profile/clubs'),
            ),
            _SearchResultItem(
              title: 'Петров Александр',
              subtitle: 'Спортсмен · 12 стартов · 5 подиумов',
              icon: Icons.person,
            ),
            _SearchResultItem(
              title: 'Rex',
              subtitle: 'Собака · Хаски · владелец: Петров А.',
              icon: Icons.pets,
            ),
          ],
        )),
      ]),
    );
  }
}

const _quickTags = ['🔥 Популярные', '📅 На этой неделе', '📍 Рядом со мной', '🏢 Клубы'];

// ── Search Result Item ──
class _SearchResultItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const _SearchResultItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: Icon(icon, color: cs.primary),
        title: Text(title, style: theme.textTheme.titleSmall),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
        trailing: Icon(Icons.chevron_right, size: 18, color: cs.onSurfaceVariant),
        onTap: onTap,
      ),
    );
  }
}
