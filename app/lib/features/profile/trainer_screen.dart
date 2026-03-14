import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: PR5 — Тренер / Воспитанники
class TrainerScreen extends StatefulWidget {
  const TrainerScreen({super.key});

  @override
  State<TrainerScreen> createState() => _TrainerScreenState();
}

class _TrainerScreenState extends State<TrainerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() { super.initState(); _tabs = TabController(length: 3, vsync: this); }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  final _athletes = [
    {'name': 'Козлов Артём', 'age': 28, 'sport': 'Скиджоринг', 'dogs': 2, 'events': 8, 'pb': '22:15', 'status': 'active', 'imageUrl': 'assets/images/avatar4.jpeg'},
    {'name': 'Орлова Наталья', 'age': 24, 'sport': 'Каникросс', 'dogs': 1, 'events': 5, 'pb': '18:42', 'status': 'active', 'imageUrl': 'assets/images/avatar5.jpeg'},
    {'name': 'Петров Дмитрий', 'age': 32, 'sport': 'Нарты', 'dogs': 4, 'events': 12, 'pb': '45:30', 'status': 'active', 'imageUrl': 'assets/images/avatar2.jpg'},
    {'name': 'Сидорова Мария', 'age': 16, 'sport': 'Каникросс', 'dogs': 1, 'events': 3, 'pb': '20:11', 'status': 'active', 'imageUrl': 'assets/images/avatar8.jpg'},
    {'name': 'Новиков Игорь', 'age': 22, 'sport': 'Скиджоринг', 'dogs': 1, 'events': 2, 'pb': '—', 'status': 'pending', 'imageUrl': 'assets/images/avatar1.jpeg'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Тренер'),
        bottom: AppPillTabBar(
          controller: _tabs,
          tabs: const ['Воспитанники', 'Результаты', 'Планы'],
        ),
      ),
      body: TabBarView(controller: _tabs, children: [
        _athletesTab(),
        _resultsTab(),
        _plansTab(),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showInviteDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Пригласить'),
      ),
    );
  }

  // ── Воспитанники ──
  Widget _athletesTab() {
    final theme = Theme.of(context);
    final active = _athletes.where((a) => a['status'] == 'active').toList();
    final pending = _athletes.where((a) => a['status'] == 'pending').toList();

    return ListView(padding: const EdgeInsets.all(12), children: [
      Row(children: [
        _stat('Всего', '${_athletes.length}', Theme.of(context).colorScheme.primary),
        _stat('Активных', '${active.length}', Theme.of(context).colorScheme.tertiary),
        _stat('Мероприятий', '30', Theme.of(context).colorScheme.secondary),
      ]),
      const SizedBox(height: 12),

      if (pending.isNotEmpty) ...[
        AppInfoBanner.warning(
          title: 'Ожидают подтверждения (${pending.length})',
          subtitle: pending.map((a) => a['name']).join(', '),
        ),
        const SizedBox(height: 4),
        ...pending.map((a) => Card(
          child: ListTile(
            leading: AppAvatar(name: a['name'] as String, imageUrl: a['imageUrl'] as String?, size: 40),
            title: Text(a['name'] as String, style: theme.textTheme.titleSmall),
            subtitle: Text('${a['sport']} · хочет стать воспитанником', style: theme.textTheme.bodySmall),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: Icon(Icons.close, color: Theme.of(context).colorScheme.error), onPressed: () {}),
              IconButton(icon: Icon(Icons.check, color: Theme.of(context).colorScheme.primary), onPressed: () {}),
            ]),
          ),
        )),
        const SizedBox(height: 12),
      ],

      AppSectionHeader(title: 'Воспитанники', icon: Icons.people),
      ...active.map((a) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: AppAvatar(name: a['name'] as String, imageUrl: a['imageUrl'] as String?, size: 40),
          title: Text(a['name'] as String, style: theme.textTheme.titleSmall),
          subtitle: Text('${a['sport']} · ${a['age']} лет · 🐕${a['dogs']}', style: theme.textTheme.bodySmall),
          trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('PB: ${a['pb']}', style: theme.textTheme.titleSmall),
            Text('${a['events']} стартов', style: theme.textTheme.bodySmall),
          ]),
          onTap: () => _showAthleteDetail(a),
        ),
      )),
    ]);
  }

  // ── Результаты ──
  Widget _resultsTab() {
    final theme = Theme.of(context);
    final results = [
      {'athlete': 'Козлов Артём', 'event': 'Чемпионат Урала 2026', 'disc': 'Скиджоринг 6км', 'place': 2, 'time': '22:15', 'date': '16.03.2026'},
      {'athlete': 'Орлова Наталья', 'event': 'Чемпионат Урала 2026', 'disc': 'Каникросс 3км', 'place': 1, 'time': '18:42', 'date': '15.03.2026'},
      {'athlete': 'Петров Дмитрий', 'event': 'Кубок Севера', 'disc': 'Нарты 4 соб. 20км', 'place': 5, 'time': '1:12:30', 'date': '02.02.2026'},
      {'athlete': 'Козлов Артём', 'event': 'Ночная гонка', 'disc': 'Скиджоринг 10км', 'place': 3, 'time': '38:45', 'date': '22.01.2026'},
      {'athlete': 'Сидорова Мария', 'event': 'Детский старт', 'disc': 'Каникросс 1км', 'place': 1, 'time': '5:30', 'date': '10.01.2026'},
    ];

    return ListView(padding: const EdgeInsets.all(12), children: [
      Card(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Text('Сезон 2025/2026', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(children: [
            _stat('Стартов', '30', Theme.of(context).colorScheme.primary),
            _stat('🥇', '5', Theme.of(context).colorScheme.tertiary),
            _stat('🥈', '8', Theme.of(context).colorScheme.outline),
            _stat('🥉', '6', Theme.of(context).colorScheme.onSurfaceVariant),
          ]),
        ]),
      )),
      const SizedBox(height: 8),
      _buildAthleteRadar(),
      const SizedBox(height: 4),
      ...results.map((r) {
        return ListTile(
          leading: AppAvatar(name: '${r['place']}', size: 40),
          title: Text(r['athlete'] as String, style: theme.textTheme.titleSmall),
          subtitle: Text('${r['event']} · ${r['disc']}', style: theme.textTheme.bodySmall),
          trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(r['time'] as String, style: theme.textTheme.titleSmall),
            Text(r['date'] as String, style: theme.textTheme.bodySmall),
          ]),
        );
      }),
    ]);
  }

  // ── Radar chart: сравнение атлетов ──
  Widget _buildAthleteRadar() {
    final style = AppChartStyle(Theme.of(context));
    final axes = ['Скорость', 'Выносл.', 'Опыт', 'PB', 'Стартов'];
    final athletes = [
      ('Козлов А.', [8.5, 7.0, 8.0, 9.0, 8.0], style.palette[0]),
      ('Орлова Н.', [9.0, 6.0, 5.0, 8.5, 5.0], style.palette[1]),
    ];

    return AppChartStyle.chartCard(
      context: context,
      title: 'Сравнение атлетов',
      subtitle: 'по ключевым метрикам (10-балльная шкала)',
      height: 220,
      chart: Column(children: [
        Expanded(
          child: RadarChart(RadarChartData(
            dataSets: athletes.map((a) => RadarDataSet(
              dataEntries: a.$2.map((v) => RadarEntry(value: v)).toList(),
              borderColor: a.$3,
              fillColor: a.$3.withValues(alpha: 0.15),
              borderWidth: 2,
              entryRadius: 3,
            )).toList(),
            radarShape: RadarShape.polygon,
            radarBorderData: BorderSide(color: style.gridColor, width: 0.5),
            tickBorderData: BorderSide(color: style.gridColor, width: 0.5),
            gridBorderData: BorderSide(color: style.gridColor, width: 0.5),
            tickCount: 3,
            ticksTextStyle: TextStyle(color: style.muted, fontSize: 8),
            titleTextStyle: TextStyle(color: style.onSurface, fontSize: 10, fontWeight: FontWeight.w600),
            getTitle: (i, _) => RadarChartTitle(text: axes[i]),
          )),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: athletes.map((a) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: a.$3, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 4),
            Text(a.$1, style: Theme.of(context).textTheme.labelSmall),
          ]),
        )).toList()),
      ]),
    );
  }

  // ── Планы ──
  Widget _plansTab() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      AppSectionHeader(title: 'Ближайшие мероприятия', icon: Icons.event),
      AppCard(children: [
        _planItem('Чемпионат Урала 2026', '15-16 марта', ['Козлов А.', 'Орлова Н.', 'Петров Д.', 'Сидорова М.'], Theme.of(context).colorScheme.primary),
        const Divider(height: 1),
        _planItem('Ночная гонка', '22 марта', ['Козлов А.', 'Орлова Н.'], Theme.of(context).colorScheme.primary),
        const Divider(height: 1),
        _planItem('Контрольный старт', '5 апреля', ['Все'], Theme.of(context).colorScheme.tertiary),
      ]),
      const SizedBox(height: 16),

      AppSectionHeader(title: 'Тренировочный план', icon: Icons.fitness_center),
      AppInfoBanner.info(
        title: 'Скоро',
        subtitle: 'Составление тренировочных планов будет доступно в следующей версии',
      ),
    ]);
  }

  Widget _planItem(String event, String date, List<String> athletes, Color color) {
    return ListTile(
      dense: true,
      leading: Container(width: 4, height: 32, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      title: Text(event, style: Theme.of(context).textTheme.titleSmall),
      subtitle: Text('$date · ${athletes.join(', ')}', style: Theme.of(context).textTheme.bodySmall),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Expanded(child: Card(child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ]),
    )));
  }

  void _showAthleteDetail(Map<String, dynamic> a) {
    AppBottomSheet.show(
      context,
      title: a['name'] as String,
      initialHeight: 0.5,
      actions: [
        AppButton.secondary(
          text: 'Открепить воспитанника',
          icon: Icons.person_remove,
          onPressed: () {},
        ),
      ],
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          AppAvatar(name: a['name'] as String, imageUrl: a['imageUrl'] as String?, size: 56),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a['name'] as String, style: Theme.of(context).textTheme.titleMedium),
            Text('${a['age']} лет · ${a['sport']}', style: Theme.of(context).textTheme.bodySmall),
          ]),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          _stat('🐕 Собак', '${a['dogs']}', Theme.of(context).colorScheme.primary),
          _stat('🏆 Стартов', '${a['events']}', Theme.of(context).colorScheme.tertiary),
          _stat('⏱ PB', a['pb'] as String, Theme.of(context).colorScheme.secondary),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.message, size: 16), label: const Text('Написать'))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.bar_chart, size: 16), label: const Text('Результаты'))),
        ]),
      ]),
    );
  }

  void _showInviteDialog() {
    AppBottomSheet.show(
      context,
      title: 'Привязать воспитанника',
      initialHeight: 0.6,
      actions: [
        AppButton.primary(
          text: 'Отправить',
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            AppSnackBar.success(context, 'Приглашение отправлено');
          },
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            padding: const EdgeInsets.all(12),
            children: const [
              AppTextField(label: 'Имя или email спортсмена', prefixIcon: Icons.search),
            ],
          ),
          const SizedBox(height: 16),
          AppInfoBanner.info(
            title: 'Инструкция',
            subtitle: 'Выбранный спортсмен получит пуш-уведомление. '
                'После его подтверждения в приложении, вы сможете просматривать его результаты и назначать тренировки.',
          ),
        ],
      ),
    );
  }
}
