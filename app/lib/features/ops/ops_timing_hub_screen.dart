import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import 'package:sportos_app/core/widgets/widgets.dart';
import 'package:sportos_app/domain/timing/timing.dart';
import 'package:sportos_app/domain/event/config_providers.dart';

/// Посты хронометража — выбор роли.
///
/// При открытии инициализирует [RaceSession] (единое состояние гонки)
/// с участниками из [participantsProvider] (Excel / ручной ввод).
/// Все вложенные экраны (Стартёр, Финиш, Маршал, Диктор) читают из него.
class OpsTimingHubScreen extends ConsumerStatefulWidget {
  final String eventId;

  const OpsTimingHubScreen({super.key, required this.eventId});

  @override
  ConsumerState<OpsTimingHubScreen> createState() => _OpsTimingHubScreenState();
}

class _OpsTimingHubScreenState extends ConsumerState<OpsTimingHubScreen> {
  String? _selectedDisciplineId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSession();
    });
  }

  // ═══════════════════════════════════════
  // Session initialization
  // ═══════════════════════════════════════

  /// Инициализирует сессию с участниками из participantsProvider,
  /// отфильтрованными по выбранной дисциплине.
  void _initSession() {
    final disciplines = ref.read(disciplineConfigsProvider);
    if (disciplines.isEmpty) return;

    // Если дисциплина не выбрана — берём первую
    _selectedDisciplineId ??= disciplines.first.id;
    final config = disciplines.firstWhere(
      (d) => d.id == _selectedDisciplineId,
      orElse: () => disciplines.first,
    );

    // Получаем участников для этой дисциплины
    final participants = ref.read(participantsProvider);
    final filtered = participants
        .where((p) => p.disciplineId == config.id)
        .toList();

    // Конвертируем Participant → формат для startSession
    final athletes = filtered.map((p) => (
      entryId: p.id,
      bib: p.bib,
      name: p.name,
      category: p.category,
      waveId: null as String?,
    )).toList();

    // Стартуем (или рестартуем) сессию
    ref.read(raceSessionProvider.notifier).startSession(config, athletes);
    if (mounted) setState(() {});
  }

  /// Переключить дисциплину → переинициализировать сессию.
  void _switchDiscipline(String disciplineId) {
    if (_selectedDisciplineId == disciplineId) return;
    setState(() => _selectedDisciplineId = disciplineId);
    _initSession();
  }

  // ═══════════════════════════════════════
  // Добавление спортсмена из участников
  // ═══════════════════════════════════════

  void _showAddAthleteSheet() {
    final session = ref.read(raceSessionProvider);
    if (session == null) return;

    AppBottomSheet.show(
      context,
      title: 'Добавить спортсмена',
      initialHeight: 0.7,
      child: StatefulBuilder(
        builder: (ctx, setSheetState) {
          final currentSession = ref.read(raceSessionProvider);
          final currentBibs = currentSession?.startList.all.map((e) => e.bib).toSet() ?? {};

          // Берём участников из participantsProvider для текущей дисциплины
          final participants = ref.read(participantsProvider);
          final discId = _selectedDisciplineId;
          final filtered = discId != null
              ? participants.where((p) => p.disciplineId == discId).toList()
              : participants;

          if (filtered.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.people_outline, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                Text(
                  'Нет участников для текущей дисциплины.\nДобавьте через Excel или вручную на странице Участники.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ]),
            );
          }

          return ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: filtered.map((p) {
              final alreadyAdded = currentBibs.contains(p.bib);
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: alreadyAdded
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Text(
                    p.bib,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: alreadyAdded
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                title: Text(p.name, style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: alreadyAdded ? TextDecoration.lineThrough : null,
                  color: alreadyAdded ? Theme.of(context).colorScheme.outline : null,
                )),
                subtitle: Text('${p.disciplineName}${p.category != null ? ' · ${p.category}' : ''}', style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                )),
                trailing: alreadyAdded
                    ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                    : Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.onSurfaceVariant),
                onTap: alreadyAdded ? null : () {
                  ref.read(raceSessionProvider.notifier).addAthlete(
                    entryId: p.id,
                    bib: p.bib,
                    name: p.name,
                    category: p.category,
                  );
                  setSheetState(() {}); // обновить BottomSheet
                  setState(() {}); // обновить основной экран
                  AppSnackBar.success(context, 'BIB ${p.bib} ${p.name} — добавлен');
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final session = ref.watch(raceSessionProvider);
    final eventId = widget.eventId;
    final athleteCount = session?.startList.all.length ?? 0;
    final startedCount = session?.startList.startedCount ?? 0;
    final disciplines = ref.watch(disciplineConfigsProvider);

    return Scaffold(
      appBar: AppAppBar(
        forceBackButton: true,
        title: const Text('Посты Хронометража'),
        onBackButtonPressed: () => context.go('/hub/event/$eventId'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Discipline picker ──
          if (disciplines.length > 1) ...[
            Text('Дисциплина', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: disciplines.map((d) {
                  final isSelected = d.id == _selectedDisciplineId;
                  // Count participants for this discipline
                  final count = ref.read(participantsProvider).where((p) => p.disciplineId == d.id).length;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text('${d.name} ($count)', style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                      )),
                      selected: isSelected,
                      onSelected: (_) => _switchDiscipline(d.id),
                      selectedColor: cs.primaryContainer.withValues(alpha: 0.6),
                      showCheckmark: false,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: isSelected ? cs.primary.withValues(alpha: 0.3) : cs.outlineVariant.withValues(alpha: 0.15)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Session info
          if (session != null) ...[
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              backgroundColor: cs.primaryContainer.withValues(alpha: 0.15),
              borderColor: cs.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
              children: [
                Row(children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    '${session.config.name} · $athleteCount участников · $startedCount стартовали',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cs.primary),
                  )),
                ]),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Athlete management
          _buildAthleteSection(cs, theme, session, athleteCount),

          const SizedBox(height: 12),

          Text(
            'Выберите вашу роль на текущую смену. Данные синхронизируются между всеми постами.',
            style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          _buildPostCard(
            context, cs, theme,
            title: 'Стартёр (Выпуск)',
            desc: 'Управление стартовыми интервалами, фиксация DNS, масс-старты.',
            icon: Icons.flag,
            color: cs.primary,
            route: '/ops/$eventId/timing/starter',
          ),
          _buildPostCard(
            context, cs, theme,
            title: 'Судья на Финише',
            desc: 'Фиксация точного времени финиша, работа с Мастер-Нодой.',
            icon: Icons.sports_score,
            color: cs.tertiary,
            route: '/ops/$eventId/timing/finish',
          ),
          _buildPostCard(
            context, cs, theme,
            title: 'Маршал (Чекпоинт)',
            desc: 'Фиксация сплитов (отсечек) на трассе, контроль прохождения.',
            icon: Icons.location_on,
            color: cs.secondary,
            route: '/ops/$eventId/timing/marshal',
          ),
          _buildPostCard(
            context, cs, theme,
            title: 'Диктор',
            desc: 'ТОП-5, подсказки, карточки атлетов — информация для трансляции.',
            icon: Icons.mic,
            color: cs.error,
            route: '/ops/$eventId/timing/dictator',
          ),
        ],
      ),
    );
  }

  Widget _buildAthleteSection(ColorScheme cs, ThemeData theme, RaceSessionState? session, int athleteCount) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(14),
      children: [
        Row(children: [
          Icon(Icons.people_alt, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(
            'Спортсмены ($athleteCount)',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          )),
          SizedBox(
            height: 32,
            child: AppButton.small(
              text: 'Добавить',
              onPressed: _showAddAthleteSheet,
            ),
          ),
        ]),
        if (athleteCount > 0 && session != null) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: session.startList.all.map((a) {
              final isStarted = a.status == AthleteStatus.started;
              return Chip(
                avatar: CircleAvatar(
                  backgroundColor: isStarted ? cs.primary : cs.surfaceContainerHighest,
                  child: Text(a.bib, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isStarted ? cs.onPrimary : cs.onSurfaceVariant)),
                ),
                label: Text(a.name.split(' ').first, style: const TextStyle(fontSize: 12)),
                deleteIcon: isStarted ? null : const Icon(Icons.close, size: 14),
                onDeleted: isStarted ? null : () {
                  ref.read(raceSessionProvider.notifier).removeAthlete(a.bib);
                },
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
        if (athleteCount == 0) ...[
          const SizedBox(height: 10),
          Text(
            'Участники из Excel/ручного ввода будут автоматически подгружены.\nИли добавьте вручную кнопкой "Добавить".',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ],
      ],
    );
  }

  Widget _buildPostCard(
    BuildContext context, ColorScheme cs, ThemeData theme, {
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push(route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 3),
                    Text(desc, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: cs.onSurfaceVariant, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
