import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import 'package:sportos_app/core/widgets/widgets.dart';
import 'package:sportos_app/domain/timing/timing.dart';

/// Посты хронометража — выбор роли.
///
/// При открытии инициализирует [RaceSession] (единое состояние гонки).
/// Все вложенные экраны (Стартёр, Финиш, Маршал, Диктор) читают из него.
class OpsTimingHubScreen extends ConsumerStatefulWidget {
  final String eventId;

  const OpsTimingHubScreen({super.key, required this.eventId});

  @override
  ConsumerState<OpsTimingHubScreen> createState() => _OpsTimingHubScreenState();
}

class _OpsTimingHubScreenState extends ConsumerState<OpsTimingHubScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureSession();
    });
  }

  void _ensureSession() {
    final session = ref.read(raceSessionProvider);
    if (session != null) return;

    // Пустая сессия — спортсмены добавляются через UI
    final raceStart = DateTime.now().add(const Duration(minutes: 2));

    final config = DisciplineConfig(
      id: 'disc-${widget.eventId}',
      name: 'Скиджоринг 6 км',
      distanceKm: 6.0,
      startType: StartType.individual,
      interval: const Duration(seconds: 30),
      firstStartTime: raceStart,
      laps: 2,
      minLapTime: const Duration(seconds: 20),
    );

    // Стартуем сессию без спортсменов
    ref.read(raceSessionProvider.notifier).startSession(config, []);
  }

  // ═══════════════════════════════════════
  // Добавление спортсмена из реестра
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
          // re-read session to see updates
          final currentSession = ref.read(raceSessionProvider);
          final currentBibs = currentSession?.startList.all.map((e) => e.bib).toSet() ?? {};

          return ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: AthleteRegistry.athletes.map((a) {
              final alreadyAdded = currentBibs.contains(a.bib);
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: alreadyAdded
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Text(
                    a.bib,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: alreadyAdded
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                title: Text(a.name, style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: alreadyAdded ? TextDecoration.lineThrough : null,
                  color: alreadyAdded ? Theme.of(context).colorScheme.outline : null,
                )),
                subtitle: Text(a.category, style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                )),
                trailing: alreadyAdded
                    ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                    : Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.onSurfaceVariant),
                onTap: alreadyAdded ? null : () {
                  ref.read(raceSessionProvider.notifier).addAthlete(
                    entryId: a.entryId,
                    bib: a.bib,
                    name: a.name,
                    category: a.category,
                  );
                  setSheetState(() {}); // обновить BottomSheet
                  setState(() {}); // обновить основной экран
                  AppSnackBar.success(context, 'BIB ${a.bib} ${a.name} — добавлен');
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

    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Посты Хронометража'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
            child: FilledButton.icon(
              onPressed: _showAddAthleteSheet,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Добавить'),
              style: FilledButton.styleFrom(textStyle: const TextStyle(fontSize: 12)),
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
            'Добавьте спортсменов из реестра для начала работы',
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
        onTap: () => context.go(route),
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
