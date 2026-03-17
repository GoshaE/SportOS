import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../domain/event/config_providers.dart';
import '../../domain/event/event_config.dart' as ec show EventConfig, EventStatus, RaceDay, StartOrder;
import '../../domain/event/event_config.dart' hide TimeOfDay;
import '../../domain/timing/models.dart';

/// Screen ID: M3 — Создать мероприятие (Лёгкий Wizard — 3 шага)
///
/// Сохраняет в Config Engine при создании.
class CreateEventWizardScreen extends ConsumerStatefulWidget {
  const CreateEventWizardScreen({super.key});

  @override
  ConsumerState<CreateEventWizardScreen> createState() => _CreateEventWizardScreenState();
}

class _CreateEventWizardScreenState extends ConsumerState<CreateEventWizardScreen> {
  int _step = 0;

  static const _sports = <String, Map<String, dynamic>>{
    'sled': {'name': 'Ездовой спорт', 'icon': Icons.pets, 'desc': 'Скиджоринг, нарты, пулка'},
    'canicross': {'name': 'Каникросс', 'icon': Icons.directions_run, 'desc': 'Бег с собакой, байкджоринг, скутер'},
    'trail': {'name': 'Трейл', 'icon': Icons.terrain, 'desc': 'Трейл, ультратрейл, скайраннинг'},
    'running': {'name': 'Лёгкая атлетика', 'icon': Icons.sports, 'desc': 'Спринт, марафон, полумарафон'},
    'skiing': {'name': 'Лыжные гонки', 'icon': Icons.downhill_skiing, 'desc': 'Классика, свободный, даблполинг'},
    'cycling': {'name': 'Велоспорт', 'icon': Icons.pedal_bike, 'desc': 'Шоссе, MTB, гравел, критериум'},
    'swimming': {'name': 'Плавание', 'icon': Icons.pool, 'desc': 'Бассейн, открытая вода'},
    'triathlon': {'name': 'Триатлон', 'icon': Icons.emoji_events, 'desc': 'Спринт, олимпийский, Ironman, дуатлон'},
    'other': {'name': 'Другой вид', 'icon': Icons.add_circle_outline, 'desc': 'Кастомный вид спорта'},
  };

  final Set<String> _selectedSports = {};
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  String _organizer = 'personal';

  DateTime _startDate = DateTime.now().add(const Duration(days: 30));
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppAppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
        title: const Text('Новое мероприятие'),
      ),
      body: Column(children: [
        // Прогресс
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(children: List.generate(3, (i) => Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 4,
              decoration: BoxDecoration(
                color: i <= _step ? cs.primary : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ))),
        ),

        // Контент
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: [_pageNameDesc, _pageDateTime, _pageSports][_step](),
          ),
        ),

        // Кнопки
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            if (_step > 0)
              Expanded(child: AppButton.secondary(
                text: 'Назад',
                onPressed: () => setState(() => _step--),
              ))
            else
              const Spacer(),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: AppButton.primary(
              text: _step < 2 ? 'Далее' : 'Создать мероприятие',
              onPressed: _step < 2 ? () => setState(() => _step++) : _create,
            )),
          ]),
        ),
      ]),
    );
  }

  // ── Шаг 1: Название ──
  Widget _pageNameDesc() {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Как называется\nваше мероприятие?', style: theme.textTheme.headlineSmall),
      const SizedBox(height: 20),

      Text('Организатор', style: theme.textTheme.titleSmall),
      const SizedBox(height: 8),
      _orgOption('personal', Icons.person, 'Лично от меня', 'Александр Иванов'),
      const SizedBox(height: 6),
      _orgOption('club-1', Icons.pets, 'Клуб «Быстрые лапы»', 'Санкт-Петербург'),
      _orgOption('club-2', Icons.terrain, 'Клуб «Trail Ural»', 'Екатеринбург'),
      const SizedBox(height: 16),

      AppTextField(
        label: 'Название',
        controller: _nameCtrl,
        prefixIcon: Icons.emoji_events,
        hintText: 'Чемпионат Урала 2026',
      ),
      const SizedBox(height: 12),
      AppTextField(
        label: 'Описание (необязательно)',
        controller: _descCtrl,
        hintText: 'Открытые соревнования по ездовому спорту...',
        maxLines: 3,
      ),
    ]);
  }

  Widget _orgOption(String value, IconData icon, String title, String subtitle) {
    final sel = _organizer == value;
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => setState(() => _organizer = value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: sel ? cs.primary : cs.outlineVariant, width: sel ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
          color: sel ? cs.primaryContainer.withValues(alpha: 0.3) : null,
        ),
        child: Row(children: [
          Icon(icon, size: 24, color: sel ? cs.primary : cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: theme.textTheme.titleSmall?.copyWith(
              color: sel ? cs.primary : null,
            )),
            Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ])),
          Icon(sel ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            color: sel ? cs.primary : cs.outlineVariant,
          ),
        ]),
      ),
    );
  }

  // ── Шаг 2: Дата и место ──
  Widget _pageDateTime() {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Когда и где?', style: theme.textTheme.headlineSmall),
      const SizedBox(height: 20),
      Row(children: [
        Expanded(child: _dateTile('Начало', _startDate, (d) => setState(() {
          _startDate = d;
          if (_endDate.isBefore(d)) _endDate = d;
        }))),
        const SizedBox(width: 12),
        Expanded(child: _dateTile('Окончание', _endDate, (d) => setState(() => _endDate = d))),
      ]),
      const SizedBox(height: 16),
      AppTextField(label: 'Город', controller: _locationCtrl, prefixIcon: Icons.location_city, hintText: 'Екатеринбург'),
      const SizedBox(height: 12),
      AppTextField(label: 'Площадка (необязательно)', controller: _venueCtrl, prefixIcon: Icons.place, hintText: 'Парк Лесоводов, ул. Ленина 100'),
    ]);
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  Widget _dateTile(String label, DateTime date, void Function(DateTime) onPick) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now(),
          lastDate: DateTime(2030),
        );
        if (picked != null) onPick(picked);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.calendar_today, size: 18, color: cs.primary),
            const SizedBox(width: 8),
            Text(_fmtDate(date), style: theme.textTheme.titleSmall),
          ]),
        ]),
      ),
    );
  }

  // ── Шаг 3: Виды спорта ──
  Widget _pageSports() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Какие виды спорта?', style: theme.textTheme.headlineSmall),
      const SizedBox(height: 4),
      Text('Дисциплины настроите после создания', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
      const SizedBox(height: 16),
      ..._sports.entries.map((e) {
        final sel = _selectedSports.contains(e.key);
        final icon = e.value['icon'] as IconData;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => setState(() {
              if (sel) { _selectedSports.remove(e.key); } else { _selectedSports.add(e.key); }
            }),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: sel ? cs.primaryContainer.withValues(alpha: 0.3) : null,
                border: Border.all(color: sel ? cs.primary : cs.outlineVariant, width: sel ? 2 : 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Icon(icon, size: 28, color: sel ? cs.primary : cs.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.value['name'] as String, style: theme.textTheme.titleSmall?.copyWith(
                    color: sel ? cs.primary : null,
                  )),
                  Text(e.value['desc'] as String, style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  )),
                ])),
                Icon(sel ? Icons.check_circle : Icons.circle_outlined,
                  color: sel ? cs.primary : cs.outlineVariant,
                ),
              ]),
            ),
          ),
        );
      }),
      if (_selectedSports.isNotEmpty) Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text('Выбрано: ${_selectedSports.length}', style: theme.textTheme.titleSmall),
      ),
    ]);
  }

  /// Создать мероприятие и сохранить в Config Engine.
  void _create() {
    if (_selectedSports.isEmpty) {
      AppSnackBar.error(context, 'Выберите хотя бы один вид спорта');
      return;
    }
    if (_nameCtrl.text.trim().isEmpty) {
      AppSnackBar.error(context, 'Введите название мероприятия');
      return;
    }

    final eventId = 'evt-${DateTime.now().millisecondsSinceEpoch}';
    final isMultiDay = _endDate.isAfter(_startDate);

    // Создать стартовую дисциплину для каждого вида спорта
    final disciplines = <DisciplineConfig>[];
    final startTime = DateTime(_startDate.year, _startDate.month, _startDate.day, 10, 0);
    var offset = Duration.zero;

    for (final sportKey in _selectedSports) {
      final sportName = (_sports[sportKey]!['name'] as String);
      disciplines.add(DisciplineConfig(
        id: 'd-${sportKey}-${DateTime.now().millisecondsSinceEpoch}',
        name: sportName,
        distanceKm: 5.0,
        startType: StartType.individual,
        firstStartTime: startTime.add(offset),
        laps: 1,
        dayNumber: 1,
        categories: const ['М', 'Ж'],
      ));
      offset += const Duration(hours: 2);
    }

    // Сохранить в Config Engine
    ref.read(eventConfigProvider.notifier).update((c) => EventConfig(
      id: eventId,
      name: _nameCtrl.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      location: [_locationCtrl.text.trim(), _venueCtrl.text.trim()]
          .where((s) => s.isNotEmpty).join(', '),
      description: _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
      status: EventStatus.draft,
      isMultiDay: isMultiDay,
      days: [
        ec.RaceDay(
          dayNumber: 1,
          date: _startDate,
          disciplineIds: disciplines.map((d) => d.id).toList(),
          startOrder: ec.StartOrder.draw,
        ),
        if (isMultiDay)
          ec.RaceDay(
            dayNumber: 2,
            date: _endDate,
            disciplineIds: [],
            startOrder: ec.StartOrder.reverse,
          ),
      ],
    ));

    // Сохранить дисциплины
    ref.read(eventConfigProvider.notifier).setDisciplines(disciplines);

    AppSnackBar.success(context, 'Мероприятие создано! Настройте дисциплины.');
    context.go('/manage/$eventId');
  }
}
