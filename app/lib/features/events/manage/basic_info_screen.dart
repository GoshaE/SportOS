import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../../domain/event/config_providers.dart';
import '../../../domain/event/event_config.dart' hide TimeOfDay;

/// Screen: Основная информация мероприятия
///
/// Дата, место, описание, контакты, статус.
class BasicInfoScreen extends ConsumerStatefulWidget {
  const BasicInfoScreen({super.key});

  @override
  ConsumerState<BasicInfoScreen> createState() => _BasicInfoScreenState();
}

class _BasicInfoScreenState extends ConsumerState<BasicInfoScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _contactCtrl;
  bool _initialized = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  void _initControllers(EventConfig config) {
    if (_initialized) return;
    _nameCtrl = TextEditingController(text: config.name);
    _locationCtrl = TextEditingController(text: config.location ?? '');
    _descCtrl = TextEditingController(text: config.description ?? '');
    _contactCtrl = TextEditingController(text: config.contactInfo ?? '');
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(eventConfigProvider);
    _initControllers(config);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppAppBar(title: const Text('Основное')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // ─── Жизненный цикл ───
        _sectionTitle(cs, 'Жизненный цикл', Icons.flag),
        _LifecycleStepper(status: config.status, cs: cs),
        const SizedBox(height: 12),
        // Current status card
        AppCard(padding: EdgeInsets.zero, children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _statusColor(config.status, cs).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_statusIcon(config.status), size: 20, color: _statusColor(config.status, cs)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_statusLabel(config.status), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(_statusHint(config.status), style: TextStyle(fontSize: 12, color: cs.outline)),
                ])),
              ]),
              const SizedBox(height: 14),
              // Deadline (only for draft/registrationOpen)
              if (config.status == EventStatus.draft || config.status == EventStatus.registrationOpen) ...[
                _DeadlineRow(
                  deadline: config.registrationConfig.registrationDeadline,
                  onTap: () => _pickDeadline(context, config),
                  cs: cs,
                ),
                const SizedBox(height: 12),
              ],
              // Transition buttons
              Row(children: [
                // Back button
                if (_prevStatus(config.status) != null)
                  Expanded(child: AppButton.smallSecondary(
                    text: _prevLabel(config.status)!,
                    icon: Icons.arrow_back,
                    onPressed: () => _confirmTransition(
                      context, config.status, _prevStatus(config.status)!, isBack: true,
                    ),
                  )),
                if (_prevStatus(config.status) != null && _nextStatus(config.status) != null)
                  const SizedBox(width: 8),
                // Forward button
                if (_nextStatus(config.status) != null)
                  Expanded(child: AppButton.small(
                    text: _nextLabel(config.status)!,
                    icon: Icons.arrow_forward,
                    onPressed: () => _confirmTransition(
                      context, config.status, _nextStatus(config.status)!,
                    ),
                  )),
              ]),
            ]),
          ),
        ]),
        const SizedBox(height: 20),

        // ─── Обложка ───
        _sectionTitle(cs, 'Обложка мероприятия', Icons.image),
        InkWell(
          onTap: () => _pickImage(context),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
              image: config.logoUrl != null
                  ? DecorationImage(image: AssetImage(config.logoUrl!), fit: BoxFit.cover)
                  : null,
              color: config.logoUrl == null ? cs.surfaceContainerLow : null,
            ),
            child: config.logoUrl == null
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add_photo_alternate, size: 36, color: cs.onSurfaceVariant.withOpacity(0.4)),
                    const SizedBox(height: 6),
                    Text('Выбрать обложку', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                  ]))
                : Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Изменить', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 20),

        // ─── Название ───
        _sectionTitle(cs, 'Название', Icons.title),
        AppTextField(
          label: 'Название',
          controller: _nameCtrl,
          hintText: 'Чемпионат Урала 2026',
        ),
        const SizedBox(height: 20),

        // ─── Даты ───
        _sectionTitle(cs, 'Даты проведения', Icons.calendar_month),
        Row(children: [
          Expanded(child: _DateCard(
            label: 'Начало',
            date: config.startDate,
            color: cs.primary,
            onTap: () => _pickDate(context, config.startDate, (d) {
              ref.read(eventConfigProvider.notifier).update((c) => c.copyWith(startDate: d));
            }),
          )),
          const SizedBox(width: 12),
          Expanded(child: _DateCard(
            label: 'Окончание',
            date: config.endDate ?? config.startDate,
            color: cs.secondary,
            onTap: () => _pickDate(context, config.endDate ?? config.startDate, (d) {
              ref.read(eventConfigProvider.notifier).update((c) => c.copyWith(endDate: d));
            }),
          )),
        ]),
        const SizedBox(height: 20),

        // ─── Место ───
        _sectionTitle(cs, 'Место проведения', Icons.location_on),
        AppTextField(
          label: 'Место проведения',
          controller: _locationCtrl,
          hintText: 'Екатеринбург, озеро Шарташ',
          prefixIcon: Icons.place,
        ),
        const SizedBox(height: 20),

        // ─── Описание ───
        _sectionTitle(cs, 'Описание', Icons.description),
        AppTextField(
          label: 'Описание',
          controller: _descCtrl,
          hintText: 'Описание мероприятия для участников...',
          maxLines: 4,
        ),
        const SizedBox(height: 20),

        // ─── Контакты ───
        _sectionTitle(cs, 'Контактная информация', Icons.phone),
        AppTextField(
          label: 'Контактная информация',
          controller: _contactCtrl,
          hintText: 'Телефон, email организатора',
          prefixIcon: Icons.contact_phone,
        ),
        const SizedBox(height: 24),

        // ─── Сохранить ───
        AppButton.primary(text: 'Сохранить', icon: Icons.save, onPressed: _save),
        const SizedBox(height: 16),
      ]),
    );
  }

  static const _eventImages = [
    'assets/images/event1.jpeg',
    'assets/images/event2.jpg',
    'assets/images/event3.jpeg',
    'assets/images/event4.jpg',
    'assets/images/event5.jpg',
    'assets/images/event6.jpg',
  ];

  void _pickImage(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final current = ref.read(eventConfigProvider).logoUrl;

    AppBottomSheet.show(context, title: 'Обложка мероприятия', child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.5,
          children: _eventImages.map((path) {
            final selected = current == path;
            return GestureDetector(
              onTap: () {
                ref.read(eventConfigProvider.notifier).update((c) => c.copyWith(logoUrl: path));
                Navigator.pop(context);
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected ? cs.primary : Colors.transparent,
                    width: selected ? 2.5 : 0,
                  ),
                  image: DecorationImage(image: AssetImage(path), fit: BoxFit.cover),
                ),
                child: selected
                    ? Align(alignment: Alignment.topRight, child: Container(
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.check, size: 14, color: Colors.white),
                      ))
                    : null,
              ),
            );
          }).toList(),
        ),
        if (current != null) ...[
          const SizedBox(height: 12),
          AppButton.text(text: 'Удалить обложку', icon: Icons.delete_outline, isDanger: true, onPressed: () {
              ref.read(eventConfigProvider.notifier).update((c) => EventConfig(
                id: c.id, name: c.name, startDate: c.startDate,
                endDate: c.endDate, location: c.location, description: c.description,
                contactInfo: c.contactInfo, logoUrl: null, status: c.status,
                isMultiDay: c.isMultiDay, days: c.days, scoringMode: c.scoringMode,
                courses: c.courses, timingConfig: c.timingConfig, drawConfig: c.drawConfig,
                penaltyTemplates: c.penaltyTemplates, checklistItems: c.checklistItems,
              ));
              Navigator.pop(context);
            }),
        ],
      ],
    ));
  }

  void _save() {
    ref.read(eventConfigProvider.notifier).update((c) => c.copyWith(
      name: _nameCtrl.text.trim(),
      location: _locationCtrl.text.trim().isNotEmpty ? _locationCtrl.text.trim() : null,
      description: _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
      contactInfo: _contactCtrl.text.trim().isNotEmpty ? _contactCtrl.text.trim() : null,
    ));
    AppSnackBar.success(context, 'Информация сохранена');
  }

  Future<void> _pickDate(BuildContext context, DateTime initial, ValueChanged<DateTime> onPicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) onPicked(picked);
  }

  // ─── Lifecycle transitions ───

  EventStatus? _nextStatus(EventStatus s) => switch (s) {
    EventStatus.draft => EventStatus.registrationOpen,
    EventStatus.registrationOpen => EventStatus.registrationClosed,
    EventStatus.registrationClosed => EventStatus.inProgress,
    EventStatus.inProgress => EventStatus.completed,
    EventStatus.completed => EventStatus.archived,
    EventStatus.archived => null,
  };

  String? _nextLabel(EventStatus s) => switch (s) {
    EventStatus.draft => 'Открыть регистрацию',
    EventStatus.registrationOpen => 'Закрыть регистрацию',
    EventStatus.registrationClosed => 'Начать гонку',
    EventStatus.inProgress => 'Завершить',
    EventStatus.completed => 'В архив',
    EventStatus.archived => null,
  };

  EventStatus? _prevStatus(EventStatus s) => switch (s) {
    EventStatus.draft => null,
    EventStatus.registrationOpen => EventStatus.draft,
    EventStatus.registrationClosed => EventStatus.registrationOpen,
    EventStatus.inProgress => EventStatus.registrationClosed,
    EventStatus.completed => EventStatus.inProgress,
    EventStatus.archived => null, // irreversible
  };

  String? _prevLabel(EventStatus s) => switch (s) {
    EventStatus.draft => null,
    EventStatus.registrationOpen => 'В черновик',
    EventStatus.registrationClosed => 'Открыть регистрацию',
    EventStatus.inProgress => 'Вернуть',
    EventStatus.completed => 'Вернуть в гонку',
    EventStatus.archived => null,
  };

  Future<void> _confirmTransition(BuildContext context, EventStatus from, EventStatus to, {bool isBack = false}) async {
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isBack ? 'Вернуть этап?' : 'Перейти на следующий этап?'),
        content: Text(_transitionWarning(from, to, isBack)),
        actions: [
          AppButton.text(text: 'Отмена', onPressed: () => Navigator.pop(ctx, false)),
          AppButton.small(
            text: isBack ? 'Вернуть' : 'Подтвердить',
            onPressed: () => Navigator.pop(ctx, true),
            backgroundColor: isBack ? cs.error : cs.primary,
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(eventConfigProvider.notifier).update((c) => c.copyWith(status: to));
      if (!context.mounted) return;
      AppSnackBar.success(context, 'Статус: ${_statusLabel(to)}');
    }
  }

  String _transitionWarning(EventStatus from, EventStatus to, bool isBack) {
    if (isBack) {
      return switch (to) {
        EventStatus.draft => 'Мероприятие вернётся в черновик. Регистрация будет недоступна.',
        EventStatus.registrationOpen => 'Регистрация снова откроется для участников.',
        EventStatus.registrationClosed => 'Гонка будет остановлена. Вернуться к подготовке?',
        EventStatus.inProgress => 'Результаты будут сброшены. Гонка продолжится.',
        _ => 'Вы уверены?',
      };
    }
    return switch (to) {
      EventStatus.registrationOpen => 'Участники смогут подавать заявки.',
      EventStatus.registrationClosed => 'Регистрация закроется. Новые заявки не принимаются.',
      EventStatus.inProgress => 'Гонка начнётся. Хронометраж станет активным.',
      EventStatus.completed => 'Гонка будет завершена. Протоколы будут опубликованы.',
      EventStatus.archived => 'Мероприятие будет заархивировано. Это действие необратимо!',
      _ => 'Вы уверены?',
    };
  }

  Future<void> _pickDeadline(BuildContext context, EventConfig config) async {
    final now = DateTime.now();
    final initial = config.registrationConfig.registrationDeadline ?? config.startDate;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: DateTime(2030),
    );
    if (date == null) return;
    if (!context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    if (!context.mounted) return;
    final deadline = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    ref.read(eventConfigProvider.notifier).update((c) => c.copyWith(
      registrationConfig: c.registrationConfig.copyWith(registrationDeadline: deadline),
    ));
    if (!context.mounted) return;
    AppSnackBar.success(context, 'Дедлайн: ${_fmtDateTime(deadline)}');
  }

  String _fmtDateTime(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  // ─── Labels ───

  String _statusLabel(EventStatus s) => switch (s) {
    EventStatus.draft => 'Черновик',
    EventStatus.registrationOpen => 'Регистрация открыта',
    EventStatus.registrationClosed => 'Регистрация закрыта',
    EventStatus.inProgress => 'В процессе',
    EventStatus.completed => 'Завершено',
    EventStatus.archived => 'Архив',
  };

  String _statusHint(EventStatus s) => switch (s) {
    EventStatus.draft => 'Мероприятие не видно участникам',
    EventStatus.registrationOpen => 'Участники могут подавать заявки',
    EventStatus.registrationClosed => 'Жеребьёвка, финальная подготовка',
    EventStatus.inProgress => 'Гонка идёт, хронометраж активен',
    EventStatus.completed => 'Протоколы опубликованы',
    EventStatus.archived => 'Мероприятие в архиве',
  };

  IconData _statusIcon(EventStatus s) => switch (s) {
    EventStatus.draft => Icons.edit_note,
    EventStatus.registrationOpen => Icons.how_to_reg,
    EventStatus.registrationClosed => Icons.lock_outline,
    EventStatus.inProgress => Icons.play_circle_outline,
    EventStatus.completed => Icons.check_circle_outline,
    EventStatus.archived => Icons.archive,
  };

  Color _statusColor(EventStatus s, ColorScheme cs) => switch (s) {
    EventStatus.draft => cs.outline,
    EventStatus.registrationOpen => const Color(0xFF2E7D32),
    EventStatus.registrationClosed => const Color(0xFFE65100),
    EventStatus.inProgress => cs.primary,
    EventStatus.completed => const Color(0xFF1565C0),
    EventStatus.archived => cs.outline,
  };

  Widget _sectionTitle(ColorScheme cs, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 16, color: cs.primary),
        const SizedBox(width: 6),
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cs.primary)),
      ]),
    );
  }
}

// ─── Date Card Widget ───

class _DateCard extends StatelessWidget {
  final String label;
  final DateTime date;
  final Color color;
  final VoidCallback onTap;

  const _DateCard({required this.label, required this.date, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const months = ['янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
    return AppCard(padding: EdgeInsets.zero, children: [
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 11, color: cs.outline)),
            const SizedBox(height: 4),
            Row(children: [
              Text('${date.day}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(width: 6),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(months[date.month - 1], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
                Text('${date.year}', style: TextStyle(fontSize: 11, color: cs.outline)),
              ]),
            ]),
          ]),
        ),
      ),
    ]);
  }
}

// ─── Lifecycle Stepper Widget ───

class _LifecycleStepper extends StatelessWidget {
  final EventStatus status;
  final ColorScheme cs;

  const _LifecycleStepper({required this.status, required this.cs});

  static const _stages = [
    (EventStatus.draft, 'Черновик', Icons.edit_note),
    (EventStatus.registrationOpen, 'Регистрация', Icons.how_to_reg),
    (EventStatus.registrationClosed, 'Закрыта', Icons.lock_outline),
    (EventStatus.inProgress, 'Гонка', Icons.play_circle_outline),
    (EventStatus.completed, 'Завершено', Icons.check_circle_outline),
    (EventStatus.archived, 'Архив', Icons.archive),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentIdx = _stages.indexWhere((s) => s.$1 == status);

    return SizedBox(
      height: 60,
      child: Row(
        children: List.generate(_stages.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final stageIdx = i ~/ 2;
            final done = stageIdx < currentIdx;
            return Expanded(child: Container(
              height: 2,
              color: done ? cs.primary : cs.outlineVariant.withOpacity(0.3),
            ));
          }
          final stageIdx = i ~/ 2;
          final (_, label, icon) = _stages[stageIdx];
          final isDone = stageIdx < currentIdx;
          final isCurrent = stageIdx == currentIdx;

          return Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrent
                    ? cs.primary
                    : isDone
                        ? cs.primary.withOpacity(0.2)
                        : cs.surfaceContainerHigh,
                border: Border.all(
                  color: isCurrent || isDone ? cs.primary : cs.outlineVariant.withOpacity(0.4),
                  width: isCurrent ? 2 : 1,
                ),
              ),
              child: Icon(
                isDone ? Icons.check : icon,
                size: 14,
                color: isCurrent ? cs.onPrimary : isDone ? cs.primary : cs.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                color: isCurrent ? cs.primary : isDone ? cs.onSurface : cs.onSurfaceVariant.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ]);
        }),
      ),
    );
  }
}

// ─── Deadline Row Widget ───

class _DeadlineRow extends StatelessWidget {
  final DateTime? deadline;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _DeadlineRow({required this.deadline, required this.onTap, required this.cs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpired = deadline != null && deadline!.isBefore(DateTime.now());

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isExpired
              ? cs.error.withOpacity(0.08)
              : cs.primaryContainer.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isExpired
                ? cs.error.withOpacity(0.3)
                : cs.primary.withOpacity(0.2),
          ),
        ),
        child: Row(children: [
          Icon(
            isExpired ? Icons.warning_amber : Icons.schedule,
            size: 18,
            color: isExpired ? cs.error : cs.primary,
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'Дедлайн регистрации',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant, fontSize: 11,
              ),
            ),
            Text(
              deadline != null
                  ? '${deadline!.day.toString().padLeft(2, '0')}.${deadline!.month.toString().padLeft(2, '0')}.${deadline!.year} в ${deadline!.hour.toString().padLeft(2, '0')}:${deadline!.minute.toString().padLeft(2, '0')}${isExpired ? ' (истёк)' : ''}'
                  : 'Не установлен — нажмите для настройки',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: deadline != null ? FontWeight.w600 : FontWeight.normal,
                color: isExpired ? cs.error : (deadline != null ? cs.onSurface : cs.onSurfaceVariant),
              ),
            ),
          ])),
          Icon(Icons.chevron_right, size: 18, color: cs.onSurfaceVariant),
        ]),
      ),
    );
  }
}

