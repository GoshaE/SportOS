import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../../domain/event/config_providers.dart';
import '../../../domain/event/event_config.dart' hide TimeOfDay;
import '../../../domain/timing/models.dart';

/// Расписание дня — интерактивная timeline дисциплин.
///
/// Tap на бар → выбор времени старта.
class DayScheduleScreen extends ConsumerWidget {
  const DayScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(eventConfigProvider);
    final disciplines = ref.watch(disciplineConfigsProvider);
    final cs = Theme.of(context).colorScheme;

    // Group disciplines by day
    final dayMap = <int, List<DisciplineConfig>>{};
    for (final d in disciplines) {
      final day = d.dayNumber ?? 1;
      dayMap.putIfAbsent(day, () => []).add(d);
    }
    for (final list in dayMap.values) {
      list.sort((a, b) => a.firstStartTime.compareTo(b.firstStartTime));
    }

    final dayNumbers = dayMap.keys.toList()..sort();

    return DefaultTabController(
      length: dayNumbers.length,
      child: Scaffold(
        appBar: AppAppBar(
          title: const Text('Расписание'),
          bottom: dayNumbers.length > 1
              ? AppPillTabBar(tabs: dayNumbers.map((d) => 'День $d').toList())
              : null,
        ),
        body: dayNumbers.length > 1
            ? TabBarView(
                children: dayNumbers.map((dayNum) {
                  final dayDiscs = dayMap[dayNum]!;
                  final raceDay = config.days.where((d) => d.dayNumber == dayNum).firstOrNull;
                  return _DayTimeline(disciplines: dayDiscs, raceDay: raceDay, cs: cs, ref: ref);
                }).toList(),
              )
            : _DayTimeline(
                disciplines: dayMap[dayNumbers.firstOrNull ?? 1] ?? [],
                raceDay: config.days.firstOrNull,
                cs: cs,
                ref: ref,
              ),
      ),
    );
  }
}

// ─── Day Timeline Widget ───

class _DayTimeline extends StatelessWidget {
  final List<DisciplineConfig> disciplines;
  final RaceDay? raceDay;
  final ColorScheme cs;
  final WidgetRef ref;

  const _DayTimeline({required this.disciplines, this.raceDay, required this.cs, required this.ref});

  @override
  Widget build(BuildContext context) {
    if (disciplines.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.event_busy, size: 48, color: cs.outline),
        const SizedBox(height: 8),
        Text('Нет дисциплин', style: TextStyle(color: cs.outline)),
      ]));
    }

    // Calculate time range
    final earliest = disciplines.first.firstStartTime;
    final latest = disciplines.fold<DateTime>(earliest, (max, d) {
      final end = d.firstStartTime.add(d.cutoffTime ?? const Duration(hours: 2));
      return end.isAfter(max) ? end : max;
    });

    final timeRangeHours = latest.difference(earliest).inMinutes / 60.0;
    final startHour = earliest.hour;
    final totalHours = (timeRangeHours + 1).ceil().clamp(2, 24);

    const sportColors = [
      Color(0xFF1565C0), Color(0xFF2E7D32), Color(0xFFE65100),
      Color(0xFF6A1B9A), Color(0xFFC62828), Color(0xFF00838F), Color(0xFF4E342E),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ─── Day header ───
        if (raceDay != null) ...[
          Row(children: [
            Icon(Icons.calendar_today, size: 14, color: cs.primary),
            const SizedBox(width: 6),
            Text(
              _formatDate(raceDay!.date),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cs.primary),
            ),
            if (raceDay!.startTime != null) ...[
              const SizedBox(width: 12),
              Icon(Icons.schedule, size: 14, color: cs.outline),
              const SizedBox(width: 4),
              Text(
                'Старт дня с ${raceDay!.startTime!.hour.toString().padLeft(2, '0')}:${raceDay!.startTime!.minute.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 12, color: cs.outline),
              ),
            ],
          ]),
          const SizedBox(height: 4),
          Text('Нажмите на дисциплину чтобы изменить время старта',
            style: TextStyle(fontSize: 11, color: cs.outline, fontStyle: FontStyle.italic)),
          const SizedBox(height: 12),
        ],

        // ─── Time ruler ───
        _TimeRuler(startHour: startHour, totalHours: totalHours, cs: cs),
        const SizedBox(height: 4),

        // ─── Discipline bars ───
        ...disciplines.asMap().entries.map((entry) {
          final i = entry.key;
          final d = entry.value;
          final color = sportColors[i % sportColors.length];
          final startMin = d.firstStartTime.difference(earliest).inMinutes;
          final durationMin = (d.cutoffTime ?? const Duration(hours: 2)).inMinutes;
          final totalMin = totalHours * 60;

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _DisciplineBar(
              discipline: d,
              color: color,
              startFraction: startMin / totalMin,
              widthFraction: (durationMin / totalMin).clamp(0.02, 1.0),
              cs: cs,
              onTap: () => _editStartTime(context, d),
            ),
          );
        }),

        const SizedBox(height: 24),

        // ─── Summary ───
        _SummarySection(disciplines: disciplines, cs: cs),
      ],
    );
  }

  void _editStartTime(BuildContext context, DisciplineConfig d) {
    final currentTime = TimeOfDay(hour: d.firstStartTime.hour, minute: d.firstStartTime.minute);

    AppBottomSheet.show(context, title: d.name, child: StatefulBuilder(
      builder: (ctx, setModal) {
        var selectedTime = currentTime;
        final cutoffH = (d.cutoffTime?.inHours ?? 2);
        final cutoffM = (d.cutoffTime?.inMinutes.remainder(60) ?? 0);
        final endTime = TimeOfDay(
          hour: (selectedTime.hour + cutoffH + (selectedTime.minute + cutoffM) ~/ 60) % 24,
          minute: (selectedTime.minute + cutoffM) % 60,
        );

        return Column(mainAxisSize: MainAxisSize.min, children: [
          // Current time display
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Column(children: [
              Text('Старт', style: TextStyle(fontSize: 11, color: cs.outline)),
              const SizedBox(height: 4),
              InkWell(
                onTap: () async {
                  final picked = await showTimePicker(context: ctx, initialTime: selectedTime);
                  if (picked != null) setModal(() => selectedTime = picked);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: cs.onPrimaryContainer),
                  ),
                ),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Icon(Icons.arrow_forward, color: cs.outline),
            ),
            Column(children: [
              Text('Финиш (cutoff)', style: TextStyle(fontSize: 11, color: cs.outline)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant),
                ),
              ),
            ]),
          ]),
          const SizedBox(height: 12),

          // Info chips
          Wrap(spacing: 8, children: [
            Chip(
              avatar: const Icon(Icons.straighten, size: 14),
              label: Text('${d.totalDistanceKm.toStringAsFixed(1)} км'),
            ),
            Chip(
              avatar: const Icon(Icons.timer, size: 14),
              label: Text('Cutoff ${cutoffH}ч ${cutoffM.toString().padLeft(2, '0')}м'),
            ),
            Chip(
              avatar: const Icon(Icons.groups, size: 14),
              label: Text(d.maxParticipants != null ? 'Макс. ${d.maxParticipants}' :  'Без лимита'),
            ),
          ]),
          const SizedBox(height: 16),

          // Save
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: () {
              ref.read(eventConfigProvider.notifier).updateDiscipline(d.id, (old) => old.copyWith(
                firstStartTime: DateTime(
                  d.firstStartTime.year, d.firstStartTime.month, d.firstStartTime.day,
                  selectedTime.hour, selectedTime.minute,
                ),
              ));
              Navigator.pop(ctx);
              AppSnackBar.success(context, 'Время старта обновлено: ${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}');
            },
            icon: const Icon(Icons.save),
            label: const Text('Сохранить'),
          )),
          const SizedBox(height: 8),
        ]);
      },
    ));
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    const months = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// ─── Time Ruler ───

class _TimeRuler extends StatelessWidget {
  final int startHour;
  final int totalHours;
  final ColorScheme cs;

  const _TimeRuler({required this.startHour, required this.totalHours, required this.cs});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Stack(
          children: [
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Container(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),
            ),
            ...List.generate(totalHours + 1, (i) {
              final x = (i / totalHours) * width;
              final hour = (startHour + i) % 24;
              return Positioned(
                left: x - 14,
                top: 0,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    '${hour.toString().padLeft(2, '0')}:00',
                    style: TextStyle(fontSize: 9, color: cs.outline, fontWeight: FontWeight.w500),
                  ),
                  Container(width: 1, height: 6, color: cs.outlineVariant.withValues(alpha: 0.5)),
                ]),
              );
            }),
          ],
        );
      }),
    );
  }
}

// ─── Discipline Bar ───

class _DisciplineBar extends StatelessWidget {
  final DisciplineConfig discipline;
  final Color color;
  final double startFraction;
  final double widthFraction;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _DisciplineBar({
    required this.discipline,
    required this.color,
    required this.startFraction,
    required this.widthFraction,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final startTime = '${discipline.firstStartTime.hour.toString().padLeft(2, '0')}:${discipline.firstStartTime.minute.toString().padLeft(2, '0')}';
    final endTime = discipline.firstStartTime.add(discipline.cutoffTime ?? const Duration(hours: 2));
    final endStr = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

    return LayoutBuilder(builder: (context, constraints) {
      final totalWidth = constraints.maxWidth;
      final barLeft = startFraction * totalWidth;
      final barWidth = (widthFraction * totalWidth).clamp(40.0, totalWidth - barLeft);

      return SizedBox(
        height: 48,
        child: Stack(children: [
          Positioned(
            left: 0, right: 0, top: 23, bottom: 23,
            child: Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.15))),
              ),
            ),
          ),
          Positioned(
            left: barLeft,
            top: 2,
            bottom: 2,
            width: barWidth,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(8),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              discipline.name,
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '$startTime – $endStr · ${discipline.totalDistanceKm.toStringAsFixed(1)} км',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 9),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.edit, size: 12, color: Colors.white.withValues(alpha: 0.6)),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ]),
      );
    });
  }
}

// ─── Summary Section ───

class _SummarySection extends StatelessWidget {
  final List<DisciplineConfig> disciplines;
  final ColorScheme cs;

  const _SummarySection({required this.disciplines, required this.cs});

  @override
  Widget build(BuildContext context) {
    final earliest = disciplines.first.firstStartTime;
    final latest = disciplines.fold<DateTime>(earliest, (max, d) {
      final end = d.firstStartTime.add(d.cutoffTime ?? const Duration(hours: 2));
      return end.isAfter(max) ? end : max;
    });
    final totalWindow = latest.difference(earliest);
    final totalH = totalWindow.inHours;
    final totalM = totalWindow.inMinutes.remainder(60);

    return AppCard(padding: const EdgeInsets.all(14), children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _statCol(Icons.sports, '${disciplines.length}', 'Дисциплин'),
        _statCol(Icons.schedule, '${totalH}ч ${totalM}м', 'Окно'),
        _statCol(
          Icons.play_arrow,
          '${earliest.hour.toString().padLeft(2, '0')}:${earliest.minute.toString().padLeft(2, '0')}',
          'Первый старт',
        ),
        _statCol(
          Icons.flag,
          '${latest.hour.toString().padLeft(2, '0')}:${latest.minute.toString().padLeft(2, '0')}',
          'Последний финиш',
        ),
      ]),
    ]);
  }

  Widget _statCol(IconData icon, String value, String label) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 16, color: cs.primary),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: cs.onSurface)),
      Text(label, style: TextStyle(fontSize: 10, color: cs.outline)),
    ]);
  }
}
